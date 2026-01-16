--[[------------------------------------------------------------------------------------------
    ConvertWithTrapRecord = 112, --使用机关记录的颜色转色，不通知buff转色
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillEffectParamConvertWithTrapRecord: SkillAddBuffEffectParam
_class("SkillEffectParamConvertWithTrapRecord", SkillAddBuffEffectParam)
SkillEffectParamConvertWithTrapRecord = SkillEffectParamConvertWithTrapRecord

function SkillEffectParamConvertWithTrapRecord:Constructor(t)
end

function SkillEffectParamConvertWithTrapRecord:GetEffectType()
    return SkillEffectType.ConvertWithTrapRecord
end
