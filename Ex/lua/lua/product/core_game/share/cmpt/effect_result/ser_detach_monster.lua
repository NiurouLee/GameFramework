require("skill_effect_result_base")

_class("SkillEffectDetachMonsterResult", SkillEffectResultBase)
---@class SkillEffectDetachMonsterResult: SkillEffectResultBase
SkillEffectDetachMonsterResult = SkillEffectDetachMonsterResult

function SkillEffectDetachMonsterResult:Constructor(newPos, targetID)
    self._casterNewPos = newPos
    self._targetID = targetID --脱离目标ID
    self._removeBuffSeqArray = {}
end

function SkillEffectDetachMonsterResult:GetEffectType()
    return SkillEffectType.DetachMonster
end

function SkillEffectDetachMonsterResult:GetCasterNewPos()
    return self._casterNewPos
end

function SkillEffectDetachMonsterResult:GetTargetID()
    return self._targetID
end

function SkillEffectDetachMonsterResult:AddRemoveBuffSeq(buffSeq)
    self._removeBuffSeqArray[#self._removeBuffSeqArray + 1] = buffSeq
end

function SkillEffectDetachMonsterResult:GetRemoveBuffSeqArray()
    return self._removeBuffSeqArray
end
