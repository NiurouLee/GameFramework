--[[
    GatherThrowDamage = 137, --鬼王技能：聚集范围内的指定类型怪和光灵，然后将光灵瞬移到指定范围内随机位置并造成伤害，杀死指定类型怪
]]
---@class SkillEffectCalc_GatherThrowDamage: Object
_class("SkillEffectCalc_GatherThrowDamage", Object)
SkillEffectCalc_GatherThrowDamage = SkillEffectCalc_GatherThrowDamage

function SkillEffectCalc_GatherThrowDamage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_GatherThrowDamage:DoSkillEffectCalculator(skillEffectCalcParam)
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
function SkillEffectCalc_GatherThrowDamage:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    ---@type SkillEffectParam_GatherThrowDamage
    local param = skillEffectCalcParam.skillEffectParam
    local defenderEntity = self._world:GetEntityByID(targetID)
    if not defenderEntity then
        return
    end

    local monsterClassIdDic = param:GetMonsterClassIdDic()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    ---@type table<number, Entity>
    local monsterList = {}
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    for _, pos in ipairs(skillEffectCalcParam.skillRange) do
        local entity = utilSvc:GetMonsterAtPos(pos)
        if entity then
            --for _, entity in ipairs(entities) do
                local nMonsterID = entity:MonsterID():GetMonsterID()
                local nMonsterClassID = monsterConfigData:GetMonsterClassID(nMonsterID)
                if monsterClassIdDic[nMonsterClassID] then
                    table.insert(monsterList, entity:GetID())
                end
            --end
        end
    end

    local monsterCount = #monsterList

    local basePercent = param:GetBasePercent()
    local addVal = param:GetAddValue()
    local addPercent = addVal * monsterCount

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    ---@type CalcDamageService
    local svcCalcDamage = self._world:GetService("CalcDamage")
    --瞬移
    local teamEntity = defenderEntity
    if defenderEntity:HasPet() then
        teamEntity = defenderEntity:Pet():GetOwnerTeamEntity()
    end
    local transTarEntityIds = {teamEntity:GetID()}
    ---@type SkillScopeResult
    -- local teleportScopeResult =
    --     scopeCalculator:ComputeScopeRange(
    --         param:GetTeleportScopeType(),
    --         param:GeteleportScopeParam(),
    --         casterEntity:GetGridPosition(),
    --         casterEntity:BodyArea():GetArea(),
    --         casterEntity:GridLocation():GetGridDir(),
    --         param:GetTeleportScopeTargetType()
    --     )
    --瞬移目标
    local transEffCalcParam = SkillEffectCalcParam:New(
        targetID,--skillEffectCalcParam.casterEntityID,--瞬移实现中是对释放者执行
        transTarEntityIds,
        param:GetTeleportParam(),
        skillEffectCalcParam:GetSkillID(),
        param:GetTeleportScope()
    )
    ---@type SkillEffectResult_Teleport[]
    local teleportResultList = self._skillEffectService:CalcSkillEffectByType(transEffCalcParam)
    local damagePos = defenderEntity:GetGridPosition()
    local teleKillMonster = {}
    if #teleportResultList > 0 then
        ---@type SkillEffectResult_Teleport
        local teleportInfo = teleportResultList[1]

        damagePos = teleportInfo:GetPosNew()

        local entity = utilSvc:GetMonsterAtPos(damagePos)
        if entity then
            local nMonsterID = entity:MonsterID():GetMonsterID()
            local nMonsterClassID = monsterConfigData:GetMonsterClassID(nMonsterID)
            if monsterClassIdDic[nMonsterClassID] then
                table.insert(teleKillMonster, entity:GetID())
            end
        end
    end
    
    --伤害
    local curFormulaID = param:GetThrowDamageFormulaID()
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

    local nTotalDamage, listDamageInfo =
        self._skillEffectService:ComputeSkillDamage(
            casterEntity,
            casterEntity:GetGridPosition(),
            defenderEntity,
            damagePos,--defenderEntity:GetGridPosition(),
            skillEffectCalcParam.skillID,
            skillDamageParam,
            SkillEffectType.GatherThrowDamage,
            1
        )
    ---@type DamageInfo
    local damageInfo = listDamageInfo[1]
    local targetArray = {targetID}
    local target = self:_TransTargetData(targetArray)
    local damageInfoArray = {damageInfo}

    local serDamage =
        self._skillEffectService:NewSkillDamageEffectResult(
            damagePos,--skillEffectCalcParam.gridPos,
            target,
            damageInfo:GetDamageValue(),
            damageInfoArray
        )

    return SkillEffectGatherThrowDamageResult:New(targetID,monsterList,teleportResultList, {serDamage},teleKillMonster)
end

---临时措施，支持AI技能释放操作，同时兼容旧代码 --2019-11-29韩玉信添加
function SkillEffectCalc_GatherThrowDamage:_TransTargetData(targetData)
    local nReturn = 0
    if type(targetData) == "number" then
        nReturn = targetData
    elseif type(targetData) == "table" then
        nReturn = targetData[1]
    end
    return nReturn
end
