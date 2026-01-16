--[[------------------------------------------------------------------------------------------
    ForEachEffectCalculator :按照效果执行技能计算
]] --------------------------------------------------------------------------------------------

---@class ForEachEffectCalculator: Object
_class("ForEachEffectCalculator", Object)
ForEachEffectCalculator = ForEachEffectCalculator

---@param world MainWorld
function ForEachEffectCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillEffectCalcService
    self._skillEffectCalcService = self._world:GetService("SkillEffectCalc")

    ---@type SkillLogicService
    self._skillLogicService = self._world:GetService("SkillLogic")

    ---微丝大招
    ---@type SerialKillerEffectCalculator
    self._serialKillerEffect = SerialKillerEffectCalculator:New(world)

    ---刑拘娘
    ---@type SkillRandAttackCalculator
    self._randAttackCalculator = SkillRandAttackCalculator:New(world)

    ---伊芙 高频伤害
    ---@type HighFrequencyDamageCalculator
    self._highFrequencyDamageCalculator = HighFrequencyDamageCalculator:New(world)

    ---国服伊芙 高频伤害
    ---@type HighFrequencyDamage2Calculator
    self._highFrequencyDamage2Calculator = HighFrequencyDamage2Calculator:New(world)

    -- 强制位移
    ---@type ForceMovementCalculator
    self._forceMovementCalculator = ForceMovementCalculator:New(world)

    -- 净化格子
    ---@type GridPurifyCalculator
    self._gridPurifyCalculator = GridPurifyCalculator:New(world)

    ---@type DegressiveDirectionalDamageCalculator
    self._degressiveDirectionalDamageCalculator = DegressiveDirectionalDamageCalculator:New(world)

    ---@type DamageByReflectDistanceCalculator
    self._damageByReflectDistance = DamageByReflectDistanceCalculator:New(world)

    ---@type ChangePetTeamOrderCalculator
    self._changePetTeamOrderCalculator = ChangePetTeamOrderCalculator:New(world)
    ---@type SwapPetTeamOrderCalculator
    self._swapPetTeamOrderCalculator = SwapPetTeamOrderCalculator:New(world)

    ---@type ShuffleTeamOrderCalculator
    self._shuffleTeamOrderCalculator = ShuffleTeamOrderCalculator:New(world)

    ---@type DecreaseSanByScopeCalculator
    self._decreaseSanByScopeCalc = DecreaseSanByScopeCalculator:New(world)

    ---@type SingleGridFullDamageCalculator
    self._singleGridFullDamageCalculator = SingleGridFullDamageCalculator:New(world)

    ---@type SkillEffectCalc_DamageCanRepeat
    self._damageCanRepeatCalculator = SkillEffectCalc_DamageCanRepeat:New(world)
	
    ---@type RandomCountDamageSameHalfCalculator
    self._randomCountDamageSameHalfCalculator = RandomCountDamageSameHalfCalculator:New(world)

    ---@type NightKingTeleportPathDamageCalculator
    self._nightKingTeleportPathDamageCalculator = NightKingTeleportPathDamageCalculator:New(world)

    ---@type SkillEffectCalc_TankRushPerGrid
    self._tankRushPerGridCalculator = SkillEffectCalc_TankRushPerGrid:New(world)

    ---通用技能效果计算器
    ---@type GeneralEffectCalculator
    self._generalEffectCalculator = GeneralEffectCalculator:New(world)

    ---逻辑效果执行器
    ---@type SkillEffectLogicExecutor
    self._skillEffectLogicExecutor = SkillEffectLogicExecutor:New(world)
end

---遍历当前施法技能里的每个技能效果，计算技能结果，并修改逻辑数据（应用执行）
---@param casterEntity Entity 施法者
function ForEachEffectCalculator:DoSkillEffectCalculate(casterEntity)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---当前施放的技能
    local skillID = skillEffectResultContainer:GetSkillID()
    ---技能配置数据
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, casterEntity)
    skillID = skillConfigData:GetID()

    local scopeFilterParam = skillConfigData:GetScopeFilterParam()
    ---当前施放技能的所有效果
    ---@type ConfigDecorationService
    local svcCfgDeco = self._world:GetService("ConfigDecoration")
    local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(casterEntity:GetID(), skillID)
    -- local skillEffectArray = skillConfigData:GetSkillEffect()
    for _, v in ipairs(skillEffectArray) do
        ---@type SkillEffectParamBase
        local skillEffectParam = v
        ---@type SkillEffectType
        local skillEffectType = skillEffectParam:GetEffectType()
        local effectScopeFilterParam = skillEffectParam:GetScopeFilterParam()
        local finalScopeFilterParam = effectScopeFilterParam:IsDefault() and scopeFilterParam or effectScopeFilterParam
        if skillEffectType == SkillEffectType.SerialKiller then
            ---@type SkillSerialKillerResult
            local result = self._serialKillerEffect:DoSerialKillerCalc(casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, {result})
        elseif skillEffectType == SkillEffectType.RandAttack then
            ---@type SkillEffectResult_RandAttack
            local result = self._randAttackCalculator:DoRandAttack(skillID, casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, {result})
        elseif skillEffectType == SkillEffectType.HighFrequencyDamage then
            ---@type SkillEffectHighFrequencyDamageResult
            local result = self._highFrequencyDamageCalculator:Calculate(casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, {result})
        elseif skillEffectType == SkillEffectType.HighFrequencyDamage2 then
            ---@type SkillEffectHighFrequencyDamageResult
            local result = self._highFrequencyDamage2Calculator:Calculate(casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, {result})
        elseif skillEffectType == SkillEffectType.ForceMovement then
            self._forceMovementCalculator:Calculate(casterEntity, skillEffectParam)
        elseif skillEffectType == SkillEffectType.GridPurify then
            self._gridPurifyCalculator:Calculate(casterEntity, skillEffectParam)
        elseif skillEffectType == SkillEffectType.DegressiveDirectionalDamage then
            local tResults = self._degressiveDirectionalDamageCalculator:Calculate(casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, tResults)
        elseif skillEffectType == SkillEffectType.DamageReflectDistance then
            local tResults = self._damageByReflectDistance:Calculate(casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, tResults)
        elseif skillEffectType == SkillEffectType.ChangePetTeamOrder then
            local results = self._changePetTeamOrderCalculator:Calculate(casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, results)
        elseif skillEffectType == SkillEffectType.ShufflePetTeamOrder then
            self._shuffleTeamOrderCalculator:Calculate(casterEntity, skillEffectParam)
        elseif skillEffectType == SkillEffectType.SwapPetTeamOrder then
            local results = self._swapPetTeamOrderCalculator:Calculate(casterEntity, skillEffectParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, results)
        elseif skillEffectType == SkillEffectType.DecreaseSanByScope then
            local results = self._decreaseSanByScopeCalc:Calculate(casterEntity, skillEffectParam, finalScopeFilterParam)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, results)
        elseif skillEffectType == SkillEffectType.SingleGridFullDamage then
            local results = self._singleGridFullDamageCalculator:Calculate(casterEntity, skillEffectParam, finalScopeFilterParam, skillID)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, results)
        elseif skillEffectType == SkillEffectType.DamageTargetCanRepeat then
            local results = self._damageCanRepeatCalculator:CalculateEffect(casterEntity, skillEffectParam,skillID)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, results)
        elseif skillEffectType == SkillEffectType.RandomCountDamageSameHalf then
            local results = self._randomCountDamageSameHalfCalculator:Calculate(casterEntity, skillEffectParam,skillID)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, results)
        elseif skillEffectType == SkillEffectType.NightKingTeleportPathDamage then
            local results = self._nightKingTeleportPathDamageCalculator:Calculate(casterEntity, skillEffectParam,skillID)
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, results)
        else
            local resultArray =
                self._generalEffectCalculator:DoGeneralEffectCalc(casterEntity, skillEffectParam, finalScopeFilterParam)
            ---每个效果执行完后，都需要应用到逻辑对象里，因为后续技能效果可能需要依赖前面的技能效果
            self._skillEffectLogicExecutor:ApplySkillEffect(casterEntity, skillEffectParam, resultArray)
        end
    end

    self:_BattleStat_SkillHitPlayer(casterEntity, skillID)
end

-- 这段代码写得没有那么直白，因为直白起来重复代码太多了……
local statSkillEffectType = {
    SkillEffectType.Damage,
    SkillEffectType.HitBack,
    SkillEffectType.AddBuff,
}

---@param casterEntity Entity
function ForEachEffectCalculator:_BattleStat_SkillHitPlayer(casterEntity, skillID)
    ---@type SkillEffectResultContainer
    local container = casterEntity:SkillContext():GetResultContainer()
    for _, effectType in ipairs(statSkillEffectType) do
        local tResult = container:GetEffectResultByArrayAll(effectType)
        if not tResult then
            goto CONTINUE
        end

        for __, result in ipairs(tResult) do
            local e = self:_GetDefenderFromSkillResult(result)
            if (e) and (self:_IsEntityPlayer(e)) then
                self._world:BattleStat():AddPlayerSkillHitCount(skillID)
                return
            end
        end

        ::CONTINUE::
    end
end

function ForEachEffectCalculator:_IsEntityPlayer(e)
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    if e:HasTeam() then
        if eLocalTeam:GetID() == e:GetID() then
            return true
        end
    elseif e:HasPet() then
        local eTeam = e:Pet():GetOwnerTeamEntity()
        if eTeam:GetID() == eLocalTeam:GetID() then
            return true
        end
    end

    return false
end

function ForEachEffectCalculator:_GetDefenderFromSkillResult(result)
    if SkillDamageEffectResult:IsInstanceOfType(result) then
        local eid = result:GetTargetID()
        if (not eid) or (eid <= 0) then
            return
        end

        return self._world:GetEntityByID(result:GetTargetID())
    elseif SkillHitBackEffectResult:IsInstanceOfType(result) then
        local eid = result:GetTargetID()
        if (not eid) or (eid <= 0) then
            return
        end

        return self._world:GetEntityByID(result:GetTargetID())
    elseif SkillBuffEffectResult:IsInstanceOfType(result) then
        local eid = result:GetEntityID()
        if (not eid) or (eid <= 0) then
            return
        end

        return self._world:GetEntityByID(result:GetTargetID())
    end
end
