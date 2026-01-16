require("skill_effect_result_base")

--region 单个目标受强制位移影响时的结果
_class("SkillEffectResult_ForceMovement_MoveResult", Object)
---@class SkillEffectResult_ForceMovement_MoveResult : Object
SkillEffectResult_ForceMovement_MoveResult = SkillEffectResult_ForceMovement_MoveResult

function SkillEffectResult_ForceMovement_MoveResult:Constructor(targetID, v2OldPos, v2NewPos, triggeredTrapIDs)
    self.targetID = targetID
    self.v2OldPos = v2OldPos
    self.v2NewPos = v2NewPos
    self.triggeredTrapIDs = triggeredTrapIDs

    self.isMoved = (v2OldPos ~= v2NewPos)
end
--endregion

_class("SkillEffectResult_ForceMovement", SkillEffectResultBase)
---@class SkillEffectResult_ForceMovement: SkillEffectResultBase
SkillEffectResult_ForceMovement = SkillEffectResult_ForceMovement

function SkillEffectResult_ForceMovement:Constructor()
    ---@type SkillEffectResult_ForceMovement_MoveResult[]
    self._moveResult = {}
end

function SkillEffectResult_ForceMovement:GetEffectType()
    return SkillEffectType.ForceMovement
end

function SkillEffectResult_ForceMovement:AppendMoveResult(targetID, v2OldPos, v2NewPos, triggeredTrapIDs)
    table.insert(self._moveResult, SkillEffectResult_ForceMovement_MoveResult:New(
        targetID, v2OldPos, v2NewPos, triggeredTrapIDs
    ))
end

---@return SkillEffectResult_ForceMovement_MoveResult[]
function SkillEffectResult_ForceMovement:GetMoveResult()
    return self._moveResult
end