--[[------------------------------------------------------------------------------------------
    SkillEachGridAddBuffEffectParam : 范围内的每个格子给目标加一个buff
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillEffectParamEachGridAddBuff: SkillAddBuffEffectParam
_class("SkillEffectParamEachGridAddBuff", SkillAddBuffEffectParam)
SkillEffectParamEachGridAddBuff = SkillEffectParamEachGridAddBuff

function SkillEffectParamEachGridAddBuff:Constructor(t)
    self._pieceTypes = t.pieceType
end

function SkillEffectParamEachGridAddBuff:GetPieceTypes()
    return self._pieceTypes
end

function SkillEffectParamEachGridAddBuff:GetEffectType()
    return SkillEffectType.EachGridAddBuff
end
