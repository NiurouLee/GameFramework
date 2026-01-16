--[[
    DamageOnTargetDistance = 126, --造成伤害，根据目标的距离圈数提升伤害系数,初始从范围的中心点开始找，找下一个是从上一个选中的位置选
]]
require("calc_base")

---@class SkillEffectCalc_DamageOnTargetDistance: SkillEffectCalc_Base
_class("SkillEffectCalc_DamageOnTargetDistance", SkillEffectCalc_Base)
SkillEffectCalc_DamageOnTargetDistance = SkillEffectCalc_DamageOnTargetDistance

function SkillEffectCalc_DamageOnTargetDistance:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageOnTargetDistance:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    self._curPos = nil
    self._gridRingNum = 0

    --不使用技能范围算出来的技能目标，技能效果内重新计算技能目标
    -- local targets = skillEffectCalcParam:GetTargetEntityIDs()

    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    --可能是点选
    local centerPos = skillEffectCalcParam:GetCenterPos()

    ---@type SkillDamageOnTargetDistanceEffectParam
    local skillDamageParam = skillEffectCalcParam.skillEffectParam
    local targetCount = skillDamageParam:GetTargetCount()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    local fullScreenCalc = SkillScopeCalculator_FullScreen:New(skillCalculater)

    ---@type SkillScopeResult
    local platformScopeResult =
        fullScreenCalc:CalcRange(
        SkillScopeType.FullScreen,
        1, -- bExcludeSelf
        centerPos,
        attacker:BodyArea():GetArea(),
        attacker:GetGridDirection(),
        SkillTargetType.Board,
        centerPos
    )

    local targetSelector = self._world:GetSkillScopeTargetSelector()
    local targetArray =
        targetSelector:DoSelectSkillTarget(
        attacker,
        SkillTargetType.NearestMonsterOneByOne,
        platformScopeResult,
        nil,
        {targetCount}
    )

    for _, targetID in ipairs(targetArray) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.appendArray(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageOnTargetDistance:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillDamageOnTargetDistanceEffectParam
    local skillDamageParam = skillEffectCalcParam.skillEffectParam
    -------在做表现的时候 考虑这个效果是否需要空结果，

    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    if defender == nil then
        Log.notice("CalculationForeachTarget defender is null ", defenderEntityID)
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, nil) ---伤害这里返回的TargetID == -1，非常坑�?
        return {skillResult}
    end
    --------

    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local modifySkillIncreaseType = skillDamageParam:GetSkillIncreaseType()
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
    local baseValue = skillDamageParam:GetBaseValue()
    local changeValue = skillDamageParam:GetChangeValue()

    --上一次的伤害结果
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    if skillEffectCalcParam.skillRange == nil then
        skillEffectCalcParam.skillRange = {skillEffectCalcParam.gridPos}
    end

    ---@type FormulaService
    local formulaService = self._world:GetService("Formula")
    local attackPos = skillEffectCalcParam.attackPos
    local gridPos = skillEffectCalcParam.gridPos

    --计算圈数
    if not self._curPos then
        self._curPos = attackPos
    end
    local targetPos = defender:GetGridPosition()

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local currentRingNum = utilCalcSvc:GetGridRingNum(self._curPos, targetPos)
    self._gridRingNum = self._gridRingNum + currentRingNum

    --下次的起点是本次的目标点
    self._curPos = targetPos

    local damageParam = baseValue + (self._gridRingNum * changeValue)

    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    buffLogicSvc:ChangeSkillIncrease(attacker, self, modifySkillIncreaseType, damageParam)

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local nTotalDamage, listDamageInfo =
        effectCalcSvc:ComputeSkillDamage(
        attacker,
        attackPos,
        defender,
        gridPos,
        skillEffectCalcParam.skillID,
        skillDamageParam,
        SkillEffectType.Damage,
        damageStageIndex
    )

    buffLogicSvc:RemoveSkillIncrease(attacker, self, modifySkillIncreaseType)

    local skillResult =
        effectCalcSvc:NewSkillDamageEffectResult(
        gridPos,
        defenderEntityID,
        nTotalDamage,
        listDamageInfo,
        damageStageIndex
    )

    local skillResultList = {}
    table.insert(skillResultList, skillResult)

    return skillResultList
end
