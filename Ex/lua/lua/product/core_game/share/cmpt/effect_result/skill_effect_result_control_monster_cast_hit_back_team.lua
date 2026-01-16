require("skill_effect_result_base")

_class("SkillEffectResultControlMonsterCastHitBackTeam", SkillEffectResultBase)
---@class SkillEffectResultControlMonsterCastHitBackTeam: SkillEffectResultBase
SkillEffectResultControlMonsterCastHitBackTeam = SkillEffectResultControlMonsterCastHitBackTeam

function SkillEffectResultControlMonsterCastHitBackTeam:Constructor(entityID, posStart, posMiddle, posEnd, dir)
    self._entityID = entityID
    self._posStart = posStart
    self._posMiddle = posMiddle
    self._posEnd = posEnd
    self._dir = dir
end

function SkillEffectResultControlMonsterCastHitBackTeam:GetEffectType()
    return SkillEffectType.ControlMonsterCastHitBackTeam
end

function SkillEffectResultControlMonsterCastHitBackTeam:GetCasterEntityID()
    return self._entityID
end

function SkillEffectResultControlMonsterCastHitBackTeam:GetPosStart()
    return self._posStart
end

function SkillEffectResultControlMonsterCastHitBackTeam:GetPosMiddle()
    return self._posMiddle
end

function SkillEffectResultControlMonsterCastHitBackTeam:GetPosEnd()
    return self._posEnd
end

function SkillEffectResultControlMonsterCastHitBackTeam:GetDir()
    return self._dir
end
