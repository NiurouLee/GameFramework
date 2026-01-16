--[[------------------------------------------------------------------------------------------
    SkillLeaveEnterBattleFieldResult : 离场进场效果
]] --------------------------------------------------------------------------------------------

---@class SkillLeaveEnterBattleFieldResult: SkillEffectResultBase
_class("SkillLeaveEnterBattleFieldResult", SkillEffectResultBase)
SkillLeaveEnterBattleFieldResult = SkillLeaveEnterBattleFieldResult

function SkillLeaveEnterBattleFieldResult:Constructor(isLeave, pos, dir)
    ---@type boolean
    self._leave = isLeave
    ---@type Vector2
    self._pos = pos
    ---@type Vector2
    self._dir = dir

end
function SkillLeaveEnterBattleFieldResult:GetEffectType()
    return SkillEffectType.LeaveEnterBattleField
end


function SkillLeaveEnterBattleFieldResult:IsLeave()
    return self._leave
end

function SkillLeaveEnterBattleFieldResult:EnterPos()
    return self._pos
end

function SkillLeaveEnterBattleFieldResult:EnterDir()
    return self._dir
end