--[[------------------------------------------------------------------------------------------

]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamDamageBySelectPieceCount", SkillEffectParamBase)
---@class SkillEffectParamDamageBySelectPieceCount: SkillEffectParamBase
SkillEffectParamDamageBySelectPieceCount = SkillEffectParamDamageBySelectPieceCount

function SkillEffectParamDamageBySelectPieceCount:Constructor(t)
    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式

    self._baseValue = t.baseValue or self._percent --基础伤害提升系数
    self._changeValue = t.changeValue or 0 --每一个提升的系数
    self._pieceTypeList = t.pieceTypeList or {}
end

function SkillEffectParamDamageBySelectPieceCount:GetEffectType()
    return SkillEffectType.DamageBySelectPieceCount
end

function SkillEffectParamDamageBySelectPieceCount:GetDamageFormulaID()
    return self._formulaID
end

function SkillEffectParamDamageBySelectPieceCount:GetDamagePercent()
    return self._percent
end

function SkillEffectParamDamageBySelectPieceCount:GetBaseValue()
    return self._baseValue
end

function SkillEffectParamDamageBySelectPieceCount:GetChangeValue()
    return self._changeValue
end

function SkillEffectParamDamageBySelectPieceCount:GetPieceTypeList()
    return self._pieceTypeList
end
