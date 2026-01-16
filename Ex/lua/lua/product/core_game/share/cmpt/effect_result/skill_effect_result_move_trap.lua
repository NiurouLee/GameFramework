require("skill_effect_result_base")

_class("SkillEffectResultMoveTrap", SkillEffectResultBase)
---@class SkillEffectResultMoveTrap: SkillEffectResultBase
SkillEffectResultMoveTrap = SkillEffectResultMoveTrap

function SkillEffectResultMoveTrap:Constructor(entityID, posOld, posNew, replaceTrapEntityID)
    self._entityID = entityID

    self._posOld = posOld
    self._posNew = posNew

    self._replaceTrapEntityID = replaceTrapEntityID
end

function SkillEffectResultMoveTrap:GetEffectType()
    return SkillEffectType.MoveTrap
end

function SkillEffectResultMoveTrap:GetEntityID()
    return self._entityID
end

function SkillEffectResultMoveTrap:GetPosOld()
    return self._posOld
end

function SkillEffectResultMoveTrap:GetPosNew()
    return self._posNew
end

--获取被顶掉的机关EntityID
function SkillEffectResultMoveTrap:GetReplaceTrapEntityID()
    return self._replaceTrapEntityID
end
