--[[------------------------------------------------------------------------------------------
    SkillEffectConvertAndDamageByLinkLineParam : 根据连线格子转色和攻击技能效果参数
]]
--------------------------------------------------------------------------------------------
require("skill_effect_param_base")

---@class SkillEffectConvertAndDamageByLinkLineParam: SkillEffectParamBase
_class("SkillEffectConvertAndDamageByLinkLineParam", SkillEffectParamBase)
SkillEffectConvertAndDamageByLinkLineParam = SkillEffectConvertAndDamageByLinkLineParam

function SkillEffectConvertAndDamageByLinkLineParam:Constructor(t)
    self._convertCount = t.convertCount
    self._convertType = t.convertType
    self._percent = t.percent
    self._formulaID = t.formulaID
    self._canLinkMonster = t.canLinkMonster or 0
end

function SkillEffectConvertAndDamageByLinkLineParam:GetEffectType()
    return SkillEffectType.ConvertAndDamageByLinkLine
end

function SkillEffectConvertAndDamageByLinkLineParam:GetConvertCount()
    return self._convertCount
end

function SkillEffectConvertAndDamageByLinkLineParam:GetConvertType()
    return self._convertType
end

function SkillEffectConvertAndDamageByLinkLineParam:GetPercent()
    return self._percent
end

function SkillEffectConvertAndDamageByLinkLineParam:GetFormulaID()
    return self._formulaID
end

function SkillEffectConvertAndDamageByLinkLineParam:IsCanLinkMonster()
    return self._canLinkMonster == 1
end
