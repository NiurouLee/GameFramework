--[[
    FrontExtendDegressiveDamage = 114, ---选取的第一个点为中心，选取第二个点作为方向，直线到版边。中间如果遇到指定机关，根据规则做扩展范围，扩展格子伤害递减（普律玛主动技）
]]
require("calc_base")

---@class SkillEffectCalc_FrontExtendDegressiveDamage: SkillEffectCalc_Base
_class("SkillEffectCalc_FrontExtendDegressiveDamage", SkillEffectCalc_Base)
SkillEffectCalc_FrontExtendDegressiveDamage = SkillEffectCalc_FrontExtendDegressiveDamage

function SkillEffectCalc_FrontExtendDegressiveDamage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_FrontExtendDegressiveDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    self._results = {}

    self._skillEffectCalcParam = skillEffectCalcParam

    ---@type SkillEffectParamFrontExtendDegressiveDamage
    local skillDamageParam = skillEffectCalcParam.skillEffectParam
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local centerPos = scopeResult:GetCenterPos()
    local effectParam = skillDamageParam:GetEffectParam()

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    local scopeCalc = SkillScopeCalculator_PickUpFrontExtendWithDamage:New(skillCalculater)

    local calcDamageFunction = function(gridPos, targetIDArray, addDamagePercent)
        return self:_CalculateWithPosAndTarget(gridPos, targetIDArray, addDamagePercent)
    end

    --技能效果中重新计算范围（根据是否真实造成伤害）
    ---@type SkillScopeResult
    local calcScopeResult =
        scopeCalc:CalcRange(
        SkillScopeType.PickUpFrontExtendWithDamage,
        effectParam,
        centerPos,
        casterEntity:BodyArea():GetArea(),
        casterEntity:GetGridDirection(),
        SkillTargetType.MonsterTrap,
        centerPos,
        casterEntity,
        calcDamageFunction
    )

    --为了可以表现出结果，如果没有伤害结果，则做一个空targetID的结果进来
    if table.count(self._results) == 0 then
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, nil) ---伤害这里返回的TargetID == -1，非常坑�?
        table.insert(self._results, skillResult)
    end

    --把重新计算的范围结果中的特殊范围结果赋值给技能结果。为了在技能表现中的上下文中取
    --需要注意的是，每次伤害结果算出来的
    for _, result in ipairs(self._results) do
        result:SetSpecialScopeResultList(calcScopeResult:GetSpecialScopeResult())
    end

    return self._results
end

function SkillEffectCalc_FrontExtendDegressiveDamage:_CalculateWithPosAndTarget(gridPos, targetIDArray, addDamagePercent)
    local results = {}
    -- local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targetIDArray) do
        local result = self:_CalculateSingleTarget(gridPos, targetID, addDamagePercent)
        if result then
            table.appendArray(results, result)
        end
    end
    return results
end

function SkillEffectCalc_FrontExtendDegressiveDamage:_CalculateSingleTarget(gridPos, defenderEntityID, addDamagePercent)
    ---@type SkillEffectParamFrontExtendDegressiveDamage
    local skillDamageParam = self._skillEffectCalcParam.skillEffectParam
    local baseDamagePercent = skillDamageParam:GetBaseDamagePercent()

    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    if defender == nil then
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, nil) ---伤害这里返回的TargetID == -1，非常坑�?
        return {skillResult}
    end

    ---@type Entity
    local attacker = self._world:GetEntityByID(self._skillEffectCalcParam.casterEntityID)
    local attackPos = self._skillEffectCalcParam.attackPos
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local skillResultList = {}

    --本次伤害系数=基础系数+范围增加的系数
    local damagePercent = baseDamagePercent + addDamagePercent
    skillDamageParam:SetDamagePercent({damagePercent})
    --

    local nTotalDamage, listDamageInfo =
        effectCalcSvc:ComputeSkillDamage(
        attacker,
        attackPos,
        defender,
        gridPos,
        self._skillEffectCalcParam.skillID,
        skillDamageParam,
        SkillEffectType.Damage,
        damageStageIndex
    )

    local skillResult =
        effectCalcSvc:NewSkillDamageEffectResult(
        gridPos,
        defenderEntityID,
        nTotalDamage,
        listDamageInfo,
        damageStageIndex
    )

    table.insert(skillResultList, skillResult)
    table.insert(self._results, skillResult)

    return skillResultList
end
