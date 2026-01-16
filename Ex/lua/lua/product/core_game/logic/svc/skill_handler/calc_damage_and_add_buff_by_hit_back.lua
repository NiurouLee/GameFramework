--[[
    DamageAndAddBuffByHitBack = 177, --根据击退结果造成伤害和添加buff
]]
---@class SkillEffectCalc_DamageAndAddBuffByHitBack: Object
_class("SkillEffectCalc_DamageAndAddBuffByHitBack", Object)
SkillEffectCalc_DamageAndAddBuffByHitBack = SkillEffectCalc_DamageAndAddBuffByHitBack

function SkillEffectCalc_DamageAndAddBuffByHitBack:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type SkillScopeTargetSelector
    self._skillScopeTargetSelector = self._world:GetSkillScopeTargetSelector()
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageAndAddBuffByHitBack:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type SkillEffectDamageAndAddBuffByHitBackParam
    local param = skillEffectCalcParam.skillEffectParam
    local isTransmitDamage = param:IsTransmitDamage()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()

    local resultArray = {}
    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        ---@type SkillHitBackEffectResult
        local hitBackRes = skillEffectResultContainer:GetEffectResultByTargetID(SkillEffectType.HitBack, targetID)
        if hitBackRes and hitBackRes:GetIsBlocked() then
            local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
            if #result > 0 then
                table.appendArray(resultArray, result)
            end

            --阻挡击退的怪需要击晕及伤害
            local blockMonsterID = hitBackRes:GetBlockMonsterID()
            ---@type Entity
            local blockMonsterEntity = self._world:GetEntityByID(blockMonsterID)
            if isTransmitDamage and blockMonsterEntity
                and self._skillScopeTargetSelector:SelectConditionFilter(blockMonsterEntity)
            then
                local result = self:_CalculateSingleTarget(skillEffectCalcParam, blockMonsterID)
                if #result > 0 then
                    table.appendArray(resultArray, result)
                end
            end
        end
    end

    return resultArray
end

function SkillEffectCalc_DamageAndAddBuffByHitBack:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    local resultArray = {}
    ---@type SkillDamageEffectResult
    local damageRes = self:CalcDamageResult(skillEffectCalcParam, targetID)
    if damageRes then
        table.insert(resultArray, damageRes)
    end

    local canAddBuff = false
    for _, damageInfo in ipairs(damageRes:GetDamageInfoArray()) do
        canAddBuff = canAddBuff or (damageInfo:GetDamageValue() > 0)
    end
    if canAddBuff then
        ---@type SkillAddBuffEffectResult
        local addBuffRes = self:CalcAddBuffResult(skillEffectCalcParam, targetID)
        if addBuffRes then
            table.insert(resultArray, addBuffRes)
        end
    end

    return resultArray
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetID number
---@return SkillDamageEffectResult
function SkillEffectCalc_DamageAndAddBuffByHitBack:CalcDamageResult(skillEffectCalcParam, targetID)
    local skillID = skillEffectCalcParam:GetSkillID()
    ---@type SkillEffectDamageAndAddBuffByHitBackParam
    local param = skillEffectCalcParam.skillEffectParam
    local percent = param:GetPercent()
    local curFormulaID = param:GetFormulaID()
    local damageStageIndex = param:GetSkillEffectDamageStageIndex()

    --攻击者和被击者
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterPos = casterEntity:GetGridPosition()
    ---@type Entity
    local defenderEntity = self._world:GetEntityByID(targetID)
    local defenderPos = defenderEntity:GetGridPosition()

    --伤害参数
    local skillDamageParam = SkillDamageEffectParam:New(
        {
            percent = percent,
            formulaID = curFormulaID,
            damageStageIndex = damageStageIndex
        }
    )

    local nTotalDamage, listDamageInfo = self._skillEffectService:ComputeSkillDamage(
        casterEntity,
        casterPos,
        defenderEntity,
        defenderPos,
        skillID,
        skillDamageParam,
        SkillEffectType.DamageAndAddBuffByHitBack,
        damageStageIndex
    )

    local damageRes = self._skillEffectService:NewSkillDamageEffectResult(
        defenderPos,
        targetID,
        nTotalDamage,
        listDamageInfo,
        damageStageIndex
    )

    return damageRes
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetID number
---@return SkillBuffEffectResult
function SkillEffectCalc_DamageAndAddBuffByHitBack:CalcAddBuffResult(skillEffectCalcParam, targetID)
    local skillID = skillEffectCalcParam:GetSkillID()
    local attackRange = skillEffectCalcParam:GetSkillRange()
    ---@type SkillEffectDamageAndAddBuffByHitBackParam
    local param = skillEffectCalcParam.skillEffectParam
    local buffID = param:GetBuffID()

    --攻击者和被击者
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type Entity
    local defenderEntity = self._world:GetEntityByID(targetID)

    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type SkillBuffEffectResult
    local buffResult = SkillBuffEffectResult:New(targetID)

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
        end
        triggerSvc:Notify(NTEachAddBuffEnd:New(skillID, casterEntity, defenderEntity, attackRange, buffID, seqID))
    end

    return buffResult
end
