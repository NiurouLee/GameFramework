--[[
    ----------------------------------------------------------------
    SkillEffectResultPetSacrificeSuperGridTraps 
    ----------------------------------------------------------------
]]
require("skill_effect_result_base")

_class("SkillEffectResultPetSacrificeSuperGridTraps", SkillEffectResultBase)
---@class SkillEffectResultPetSacrificeSuperGridTraps: SkillEffectResultBase
SkillEffectResultPetSacrificeSuperGridTraps = SkillEffectResultPetSacrificeSuperGridTraps

function SkillEffectResultPetSacrificeSuperGridTraps:GetEffectType()
    return SkillEffectType.PetSacrificeSuperGridTraps
end
function SkillEffectResultPetSacrificeSuperGridTraps:Constructor(trapIDs)
    self._trapIDs = trapIDs
end
--点击的地方没有强化格子也要播表现
function SkillEffectResultPetSacrificeSuperGridTraps:SetExtraGrids(gridPosList)
    self._extraGirds = gridPosList
end

function SkillEffectResultPetSacrificeSuperGridTraps:GetTrapIDs()
    return self._trapIDs
end
function SkillEffectResultPetSacrificeSuperGridTraps:GetExtraGrids()
    return self._extraGirds
end