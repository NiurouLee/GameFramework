--[[------------------------------------------------------------------------------------------
    AddMoveScopeRecordCmpt = 192, --仲胥 给点选位置的机关/怪增加记录移动范围的组件，并记录点选位置对机关/怪中心位置的偏移
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParam_AddMoveScopeRecordCmpt", SkillEffectParamBase)
---@class SkillEffectParam_AddMoveScopeRecordCmpt: SkillEffectParamBase
SkillEffectParam_AddMoveScopeRecordCmpt = SkillEffectParam_AddMoveScopeRecordCmpt

function SkillEffectParam_AddMoveScopeRecordCmpt:Constructor(t)
    self._bSetOff = t.setOff and (t.setOff ==  1) or false
end

function SkillEffectParam_AddMoveScopeRecordCmpt:GetEffectType()
    return SkillEffectType.AddMoveScopeRecordCmpt
end