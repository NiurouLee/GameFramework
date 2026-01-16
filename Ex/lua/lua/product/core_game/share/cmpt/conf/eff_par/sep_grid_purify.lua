require("skill_damage_effect_param")

_class("SkillEffectParam_GridPurify", SkillEffectParamBase)
---@class SkillEffectParam_GridPurify: SkillEffectParamBase
SkillEffectParam_GridPurify = SkillEffectParam_GridPurify

function SkillEffectParam_GridPurify:Constructor(t)
    self._purifyRate = tonumber(t.purifyRate)
    -- self._purifyMax = tonumber(t.purifyMax)
    self._trapID = tonumber(t.trapID)
    self._trapMax = tonumber(t.trapMax)
end

function SkillEffectParam_GridPurify:GetEffectType() return SkillEffectType.GridPurify end

function SkillEffectParam_GridPurify:GetPurifyRate() return self._purifyRate end
-- function SkillEffectParam_GridPurify:GetPurifyMax() return self._purifyMax end
function SkillEffectParam_GridPurify:GetTrapID() return self._trapID end
function SkillEffectParam_GridPurify:GetTrapMax() return self._trapMax end