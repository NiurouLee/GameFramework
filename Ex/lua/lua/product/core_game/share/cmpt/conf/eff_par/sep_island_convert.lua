require("skill_damage_effect_param")

---@class SkillEffectParamIslandConvert : SkillDamageEffectParam
_class("SkillEffectParamIslandConvert", SkillDamageEffectParam)
SkillEffectParamIslandConvert = SkillEffectParamIslandConvert

function SkillEffectParamIslandConvert:Constructor(t)
    self._islandPattern = t.pattern

end

function SkillEffectParamIslandConvert:GetEffectType() return SkillEffectType.IslandConvert end
function SkillEffectParamIslandConvert:GetPattern() return self._islandPattern end