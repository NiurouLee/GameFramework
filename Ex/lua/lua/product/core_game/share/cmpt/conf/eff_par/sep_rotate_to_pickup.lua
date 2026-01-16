require("skill_damage_effect_param")

---@class SkillEffectParamRotateToPickup : SkillEffectParamBase
_class("SkillEffectParamRotateToPickup", SkillEffectParamBase)
SkillEffectParamRotateToPickup = SkillEffectParamRotateToPickup

function SkillEffectParamRotateToPickup:GetEffectType() return SkillEffectType.RotateToPickup end

function SkillEffectParamRotateToPickup:Constructor(t)
    self._pickupIndex = t.pickupIndex or 1
    self._useOriDir = t.useOriDir or false
end

function SkillEffectParamRotateToPickup:GetPickupIndex() return self._pickupIndex end
function SkillEffectParamRotateToPickup:IsUseOriDir() 
    return self._useOriDir 
end