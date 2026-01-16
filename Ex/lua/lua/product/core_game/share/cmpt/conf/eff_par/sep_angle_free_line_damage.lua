require("skill_damage_effect_param")

---@class SkillEffectParamAngleFreeDamage : SkillDamageEffectParam
_class("SkillEffectParamAngleFreeDamage", SkillDamageEffectParam)
SkillEffectParamAngleFreeDamage = SkillEffectParamAngleFreeDamage

function SkillEffectParamAngleFreeDamage:Constructor(t)
    self._pickupIndex = t.pickupIndex
end

function SkillEffectParamAngleFreeDamage:GetPickupIndex() return self._pickupIndex end
function SkillEffectParamAngleFreeDamage:GetEffectType() return SkillEffectType.AngleFreeLineDamage end