_class("DecreaseSanByScopeCalculator", Object)
---@class DecreaseSanByScopeCalculator : Object
DecreaseSanByScopeCalculator = DecreaseSanByScopeCalculator

---
---@param world MainWorld
function DecreaseSanByScopeCalculator:Constructor(world)
    self._world = world
end

---
---@param casterEntity Entity
---@param skillEffectParam SkillEffectParam_DecreaseSanByScope
---@param finalScopeFilterParam SkillScopeFilterParam
---@return table
function DecreaseSanByScopeCalculator:Calculate(casterEntity, skillEffectParam, finalScopeFilterParam)
    ---@type GeneralEffectCalculator
    local generalCalc = GeneralEffectCalculator:New(self._world)
    ---@type SkillScopeResult 这个为啥插件解释不出来??
    local skillScopeResult = generalCalc:_CalcSkillEffectScopeResult(casterEntity, skillEffectParam, finalScopeFilterParam)
    local attackRange = skillScopeResult:GetAttackRange()

    local sanPerGrid = skillEffectParam:GetSanPerGrid()
    local decreaseSan = sanPerGrid * (#attackRange)

    local range = {}
    for _, v in ipairs(attackRange) do
        table.insert(range, v)
    end
    local result = SkillEffectResult_DecreaseSanByScope:New(casterEntity:GetID(), range, decreaseSan)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    skillEffectResultContainer:AddEffectResult(result)

    return {result}
end
