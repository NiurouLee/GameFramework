require("skill_effect_param_base")

_class("SkillEffectParam_StickerLeave", SkillEffectParamBase)
---@class SkillEffectParam_StickerLeave: SkillEffectParamBase
SkillEffectParam_StickerLeave = SkillEffectParam_StickerLeave

function SkillEffectParam_StickerLeave:Constructor(t)
    self._convertColor = t.convertColor --离开贴纸的时候普通格子转色
end

function SkillEffectParam_StickerLeave:GetEffectType()
    return SkillEffectType.StickerLeave
end

function SkillEffectParam_StickerLeave:GetConvertColor()
    return self._convertColor
end
