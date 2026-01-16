--[[
    LeaveEnterBattleField = 7, --离开进入战场 
]]
---@class SkillEffectCalc_LeaveEnterBattleField: Object
_class("SkillEffectCalc_LeaveEnterBattleField", Object)
SkillEffectCalc_LeaveEnterBattleField = SkillEffectCalc_LeaveEnterBattleField

function SkillEffectCalc_LeaveEnterBattleField:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_LeaveEnterBattleField:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillLeaveEnterBattleFieldEffectParam
    local param = skillEffectCalcParam.skillEffectParam
    return SkillLeaveEnterBattleFieldResult:New(param:IsLeave(), param:EnterPos(), param:EnterDir())
end
