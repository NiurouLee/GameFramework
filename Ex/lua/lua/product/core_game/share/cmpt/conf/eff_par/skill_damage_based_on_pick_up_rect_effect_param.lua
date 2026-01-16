--[[------------------------------------------------------------------------------------------
    SkillDamageBasedOnPickUpRectEffectParam : 技能伤害效果参数
]] --------------------------------------------------------------------------------------------

require("skill_effect_param_base")

_class("SkillDamageBasedOnPickUpRectEffectParam", SkillEffectParamBase)
---@class SkillDamageBasedOnPickUpRectEffectParam: SkillEffectParamBase
SkillDamageBasedOnPickUpRectEffectParam = SkillDamageBasedOnPickUpRectEffectParam

function SkillDamageBasedOnPickUpRectEffectParam:Constructor(t)
    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式
    self._multiple = t.multiple or 1 -- 策划配置的系数

    --点选范围计算，范围的长和宽
    self._rectX = 1
    self._rectY = 1
end

function SkillDamageBasedOnPickUpRectEffectParam:GetEffectType()
    return SkillEffectType.DamageBasedOnPickUpRect
end

function SkillDamageBasedOnPickUpRectEffectParam:GetMultiple()
    return self._multiple
end

---获取百分比列表
function SkillDamageBasedOnPickUpRectEffectParam:GetDamagePercent()
    local damageEffectParam = self._multiple / (self._rectX + self._rectY) * self._percent[1]
    return {damageEffectParam}

    -- return self._percent
end

---获取伤害计算公式ID
function SkillDamageBasedOnPickUpRectEffectParam:GetDamageFormulaID()
    return self._formulaID
end

function SkillDamageBasedOnPickUpRectEffectParam:SetSkillRangeRectParam(rectX, rectY)
    self._rectX = rectX
    self._rectY = rectY
end
