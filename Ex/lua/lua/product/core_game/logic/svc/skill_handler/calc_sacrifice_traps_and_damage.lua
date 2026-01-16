--[[
    SacrificeTrapsAndDamage = 72, -- 吸收范围内特定的机关，根据吸收数量造成伤害
]]
---@class SkillEffectCalc_SacrificeTrapsAndDamage: Object
_class("SkillEffectCalc_SacrificeTrapsAndDamage", Object)
SkillEffectCalc_SacrificeTrapsAndDamage = SkillEffectCalc_SacrificeTrapsAndDamage

function SkillEffectCalc_SacrificeTrapsAndDamage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SacrificeTrapsAndDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SacrificeTrapsAndDamage:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    ---@type SkillEffectSacrificeTrapsAndDamageParam
    local param = skillEffectCalcParam.skillEffectParam

    local trapID = param:GetTrapID()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    ---@type table<number, Entity>
    local traps = {}
    for _, pos in ipairs(skillEffectCalcParam.skillRange) do
        ---@type table<integer, Entity>
        local entities = utilSvc:GetTrapsAtPos(pos)
        for _, entity in ipairs(entities) do
            local trapComponent = entity:Trap()
            if trapID[trapComponent:GetTrapID()] then
                table.insert(traps, entity:GetID())
            end
        end
    end

    local trapCount = #traps

    local basePercent = param:GetBasePercent()
    local addVal = param:GetAddValue()
    local addPercent = addVal * trapCount

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    ---@type CalcDamageService
    local svcCalcDamage = self._world:GetService("CalcDamage")
    local defenderEntity = self._world:GetEntityByID(targetID)
    -- ---@type DamageInfo
    -- local damageInfo =
    --     svcCalcDamage:DoCalcDamage(
    --     casterEntity,
    --     defenderEntity,
    --     {
    --         percent = basePercent,
    --         addPercent = addPercent,
    --         formulaID = 100,
    --         skillID = skillEffectCalcParam.skillID
    --     }
    -- )
    local curFormulaID = param:GetSacrificeFormulaID()
    if curFormulaID == nil then
        curFormulaID = 100
    end

    local skillDamageParam =
    SkillDamageEffectParam:New(
            {
                percent = {basePercent},
                addPercent = addPercent,
                formulaID = curFormulaID,
                damageStageIndex = 1
            }
    )

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local targetType = skillEffectCalcParam.skillEffectParam:GetDamageTargetType()

    ---@type SkillScopeResult
    local damageScopeResult =
    scopeCalculator:ComputeScopeRange(
            skillEffectCalcParam.skillEffectParam:GetDamageScopeType(),
            skillEffectCalcParam.skillEffectParam:GetDamageScopeParam(),
            casterEntity:GetGridPosition(),
            casterEntity:BodyArea():GetArea(),
            casterEntity:GridLocation():GetGridDir(),
            targetType
    )

    local targetArray = utilScopeSvc:SelectSkillTarget(casterEntity, targetType, damageScopeResult, skillEffectCalcParam.skillID)

    local target = self:_TransTargetData(targetArray)
    local damageTarget = self._world:GetEntityByID(target)

    if not damageTarget then
        return
    end

    local nTotalDamage, listDamageInfo =
    self._skillEffectService:ComputeSkillDamage(
            casterEntity,
            casterEntity:GetGridPosition(),
            damageTarget,
            damageTarget:GetGridPosition(),
            skillEffectCalcParam.skillID,
            skillDamageParam,
            SkillEffectType.SacrificeTrapsAndDamage,
            1
    )
    ---@type DamageInfo
    local damageInfo = listDamageInfo[1]

    local damageInfoArray = {damageInfo}

    local serDamage =
    self._skillEffectService:NewSkillDamageEffectResult(
            skillEffectCalcParam.gridPos,
            target,
            damageInfo:GetDamageValue(),
            damageInfoArray
    )

    return SkillEffectSacrificeTrapsAndDamageResult:New(traps, {serDamage})
end

---临时措施，支持AI技能释放操作，同时兼容旧代码 --2019-11-29韩玉信添加
function SkillEffectCalc_SacrificeTrapsAndDamage:_TransTargetData(targetData)
    local nReturn = 0
    if type(targetData) == "number" then
        nReturn = targetData
    elseif type(targetData) == "table" then
        nReturn = targetData[1]
    end
    return nReturn
end
