--[[------------------------------------------------------------------------------------------
    SkillModifyBuffValueResult : 技能改buff值结果
]] --------------------------------------------------------------------------------------------
require("skill_effect_result_base")
---@class SkillModifyBuffValueResult: SkillEffectResultBase
_class("SkillModifyBuffValueResult", SkillEffectResultBase)
SkillModifyBuffValueResult = SkillModifyBuffValueResult

function SkillModifyBuffValueResult:Constructor(entityId, buffseq, layer)
    self._entityID = entityId
    self._buffSeq = buffseq
    self._buffLayer = layer
end

function SkillModifyBuffValueResult:GetEntityID()
    return self._entityID
end

function SkillModifyBuffValueResult:GetBuffSeq()
    return self._buffSeq
end

function SkillModifyBuffValueResult:GetBuffLayer()
    return self._buffLayer
end

function SkillModifyBuffValueResult:GetEffectType()
    return SkillEffectType.ModifyBuffValue
end
