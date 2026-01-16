---@class SkillEffectCalcSuicide: Object
_class("SkillEffectCalcSuicide", Object)
SkillEffectCalcSuicide = SkillEffectCalcSuicide

function SkillEffectCalcSuicide:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
    ---@type MonsterShowLogicService
    self._monsterShowLogic = self._world:GetService("MonsterShowLogic")
end
---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcSuicide:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.appendArray(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcSuicide:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillEffectParamSuicide
    local skillSuicideParam = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    if defender == nil then
        Log.notice("CalculationForeachTarget defender is null ", defenderEntityID)
        local skillResult = SkillSuicideEffectResult:New(-1)
        return skillResult
    end
    local skillResultList = {}

    if defender:HasMonsterID() then
        defender:Attributes():Modify("HP", 0)
        self._monsterShowLogic:AddMonsterDeadMark(defender)
        Log.debug("SkillEffectCalcSuicide ModifyHP =0 defender=", defender:GetID())

        skillResultList[#skillResultList + 1] = SkillSuicideEffectResult:New(defenderEntityID)
    elseif defender:HasChessPet() then
        defender:Attributes():Modify("HP", 0)
        ---@type ChessServiceLogic
        local chessSvc = self._world:GetService("ChessLogic")
        chessSvc:AddChessPetDeadMark(defender)
        Log.debug("SkillEffectCalcSuicide ModifyHP =0 defender=", defender:GetID())
        skillResultList[#skillResultList + 1] = SkillSuicideEffectResult:New(defenderEntityID)
    end

    return skillResultList
end
