--[[
    SplashDamageAndAddBuff = 190, --以技能目标为溅射中心，造成溅射伤害并附加buff，技能空放时使用配置的施法者偏移位置作为溅射中心
]]
require("calc_base")

---@class SkillEffectCalc_SplashDamageAndAddBuff : SkillEffectCalc_Base
_class("SkillEffectCalc_SplashDamageAndAddBuff", SkillEffectCalc_Base)
SkillEffectCalc_SplashDamageAndAddBuff = SkillEffectCalc_SplashDamageAndAddBuff

function SkillEffectCalc_SplashDamageAndAddBuff:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectCalcSvc = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@return SkillEffectSplashDamageAndAddBuffResult[]
function SkillEffectCalc_SplashDamageAndAddBuff:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
    if targetIDs and #(targetIDs) == 1 and targetIDs[1] == -1 then
        -- 空放只计算溅射伤害
        local result = self:_CalculateNoTarget(skillEffectCalcParam)
        if result then
            table.appendArray(results, result)
        end
    else
        for _, targetID in ipairs(targetIDs) do
            local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
            if result then
                table.appendArray(results, result)
            end
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@return SkillEffectSplashDamageAndAddBuffResult[]
function SkillEffectCalc_SplashDamageAndAddBuff:_CalculateNoTarget(skillEffectCalcParam)
    local casterID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local caster = self._world:GetEntityByID(casterID)
    local casterPos = caster:GetGridPosition()
    local casterDir = caster:GetGridDirection()

    ---@type SkillEffectParamSplashDamageAndAddBuff
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local offset = param:GetSplashOffset()
    local splashCenterPos = casterPos + casterDir * offset

    return self:_CalculateDamageAndAddBuff(skillEffectCalcParam, splashCenterPos)
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetID number
---@return SkillEffectSplashDamageAndAddBuffResult[]
function SkillEffectCalc_SplashDamageAndAddBuff:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    ---@type Entity
    local defender = self._world:GetEntityByID(targetID)
    local splashCenterPos = defender:GetGridPosition()

    return self:_CalculateDamageAndAddBuff(skillEffectCalcParam, splashCenterPos)
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param centerPos Vector2
---@return SkillEffectSplashDamageAndAddBuffResult[]
function SkillEffectCalc_SplashDamageAndAddBuff:_CalculateDamageAndAddBuff(skillEffectCalcParam, centerPos)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local calcScope = utilScopeSvc:GetSkillScopeCalc()

    ---@type SkillEffectParamSplashDamageAndAddBuff
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local targetType = param:GetSplashTargetType()
    local scopeType = param:GetSplashScopeType()
    local scopeParam = param:GetSplashScopeParam()
    local parser = SkillScopeParamParser:New()
    scopeParam = parser:ParseScopeParam(scopeType, scopeParam)

    ---@type Entity
    local caster = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local casterBodyArea = caster:BodyArea():GetArea()
    local casterDirection = caster:GetGridDirection()
    local casterPos = caster:GetGridDirection()

    --计算溅射范围
    local splashScopeResult = calcScope:ComputeScopeRange(
        scopeType,
        scopeParam,
        centerPos,
        casterBodyArea,
        casterDirection,
        targetType,
        casterPos,
        caster
    )

    --用溅射范围获取目标
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    local targetArray = targetSelector:DoSelectSkillTarget(caster, targetType, splashScopeResult)
    --去重并排除施法者自身
    table.unique(targetArray)
    table.removev(targetArray, caster:GetID())

    local attackRange = splashScopeResult:GetAttackRange()
    table.removev(attackRange, centerPos)

    --计算溅射伤害结果
    ---@type SkillDamageEffectResult[]
    local damageResults = self:_CalculateDamageResult(skillEffectCalcParam, attackRange, targetArray)

    --计算附加Buff结果
    ---@type SkillBuffEffectResult[]
    local buffResults = self:_CalculateAddBuffResult(skillEffectCalcParam, targetArray)

    return { SkillEffectSplashDamageAndAddBuffResult:New(centerPos, damageResults, buffResults) }
end

function SkillEffectCalc_SplashDamageAndAddBuff:_GetTargetAreaMap(targetArray)
    local targetGridAreaMap = {}
    for _, targetEntityID in ipairs(targetArray) do
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        if targetEntity then
            local targetCenterPos = targetEntity:GetGridPosition()
            local bodyAreaComponent = targetEntity:BodyArea()
            if bodyAreaComponent then
                local bodyAreaArray = bodyAreaComponent:GetArea()
                for _, areaPos in ipairs(bodyAreaArray) do
                    local absAreaPos = (areaPos + targetCenterPos)
                    if not targetGridAreaMap[absAreaPos.x] then
                        targetGridAreaMap[absAreaPos.x] = {}
                    end
                    targetGridAreaMap[absAreaPos.x][absAreaPos.y] = targetEntityID
                end
            else
                if not targetGridAreaMap[targetCenterPos.x] then
                    targetGridAreaMap[targetCenterPos.x] = {}
                end
                targetGridAreaMap[targetCenterPos.x][targetCenterPos.y] = targetEntityID
            end
        end
    end
    return targetGridAreaMap
end

---@param param SkillEffectCalcParam
---@param attackRange Vector2[]
---@param targetArray number[]
---@return SkillDamageEffectResult[]
function SkillEffectCalc_SplashDamageAndAddBuff:_CalculateDamageResult(param, attackRange, targetArray)
    ---@type SkillDamageEffectResult[]
    local resultArray = {}

    ---@type SkillEffectParamSplashDamageAndAddBuff
    local skillDamageParam = param:GetSkillEffectParam()
    local skillID = param:GetSkillID()
    ---@type Entity
    local caster = self._world:GetEntityByID(param:GetCasterEntityID())
    local attackPos = caster:GetGridPosition()
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

    --获取目标占格
    local targetGridAreaMap = self:_GetTargetAreaMap(targetArray)
    --根据溅射范围计算伤害
    for _, damagePos in ipairs(attackRange) do
        if (targetGridAreaMap[damagePos.x]) and (targetGridAreaMap[damagePos.x][damagePos.y]) then
            local defenderEntityID = (targetGridAreaMap[damagePos.x][damagePos.y])
            ---@type Entity
            local defender = self._world:GetEntityByID(defenderEntityID)

            local nTotalDamage, listDamageInfo = self._skillEffectCalcSvc:ComputeSkillDamage(
                caster,
                attackPos,
                defender,
                damagePos,
                skillID,
                skillDamageParam,
                SkillEffectType.SplashDamageAndAddBuff,
                damageStageIndex
            )

            local skillResult = self._skillEffectCalcSvc:NewSkillDamageEffectResult(
                damagePos,
                defenderEntityID,
                nTotalDamage,
                listDamageInfo,
                damageStageIndex
            )
            table.insert(resultArray, skillResult)
        end
    end

    return resultArray
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetArray number[]
---@return SkillBuffEffectResult[]
function SkillEffectCalc_SplashDamageAndAddBuff:_CalculateAddBuffResult(skillEffectCalcParam, targetArray)
    local skillID = skillEffectCalcParam:GetSkillID()
    local attackRange = skillEffectCalcParam:GetSkillRange()
    ---@type SkillEffectParamSplashDamageAndAddBuff
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local buffID = param:GetBuffID()

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")

    ---@type SkillBuffEffectResult
    local buffResultArray = {}
    for _, targetID in ipairs(targetArray) do
        ---@type Entity
        local defenderEntity = self._world:GetEntityByID(targetID)

        ---@type SkillBuffEffectResult
        local buffResult = SkillBuffEffectResult:New(defenderEntity:GetID())

        local cfgNewBuff = Cfg.cfg_buff[buffID]
        if cfgNewBuff then
            triggerSvc:Notify(NTEachAddBuffStart:New(skillID, casterEntity, defenderEntity, attackRange))
            local buff = buffLogicService:AddBuff(
                buffID,
                defenderEntity,
                { casterEntity = casterEntity }
            )
            local seqID
            if buff then
                seqID = buff:BuffSeq()
                buffResult:AddBuffResult(seqID)
                table.insert(buffResultArray, buffResult)
            end
            triggerSvc:Notify(NTEachAddBuffEnd:New(skillID, casterEntity, defenderEntity, attackRange, buffID, seqID))
        end
    end

    return buffResultArray
end
