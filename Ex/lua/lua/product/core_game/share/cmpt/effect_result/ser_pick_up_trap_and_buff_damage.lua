--[[
    ----------------------------------------------------------------
    SkillEffectPickUpTrapAndBuffDamageResult 
    ---目前只是给表现传递点选的机关buff层数
    ----------------------------------------------------------------
]]
require("skill_effect_result_base")

_class("SkillEffectPickUpTrapAndBuffDamageResult", SkillEffectResultBase)
---@class SkillEffectPickUpTrapAndBuffDamageResult: SkillEffectResultBase
SkillEffectPickUpTrapAndBuffDamageResult = SkillEffectPickUpTrapAndBuffDamageResult

function SkillEffectPickUpTrapAndBuffDamageResult:GetEffectType()
    return SkillEffectType.PickUpTrapAndBuffDamage
end
function SkillEffectPickUpTrapAndBuffDamageResult:Constructor(buffLayer)
    self._tarTrapBuffLayer = buffLayer
end
function SkillEffectPickUpTrapAndBuffDamageResult:GetTarBuffLayer()
    return self._tarTrapBuffLayer
end