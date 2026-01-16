--[[
    ----------------------------------------------------------------
    SkillEffectResult_EddyTransport EddyTransport技能结果
    ----------------------------------------------------------------
]]
require("skill_effect_result_teleport")

_class("SkillEffectResult_EddyTransport", SkillEffectResult_Teleport)
---@class SkillEffectResult_EddyTransport: SkillEffectResult_Teleport
SkillEffectResult_EddyTransport = SkillEffectResult_EddyTransport

-- function SkillEffectResult_EddyTransport:Constructor(nTargetID, posOld, colorOld, posNew, colorNew, dirNew)
-- end

function SkillEffectResult_EddyTransport:GetEffectType()
    return SkillEffectType.EddyTransport
end

