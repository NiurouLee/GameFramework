--[[----------------------------------------------------------------
    2020-07-09 于昌弘扩展原SkillEffectParam_ResetGridElement，支持对范围内筛选
    SkillEffectParam_ResetSelectGridElement : 重置所有选中的格子
--]] ----------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillEffectParam_ResetSelectGridElement:SkillEffectParam_ResetGridElement
_class("SkillEffectParam_ResetSelectGridElement", SkillEffectParam_ResetGridElement)
SkillEffectParam_ResetSelectGridElement = SkillEffectParam_ResetSelectGridElement

function SkillEffectParam_ResetSelectGridElement:Constructor(t)
    --筛选条件，比如selectCondition={srcElement={3，4}}，表示将属性为3、4的格子筛选出来
    self._selectCondition = t.selectCondition
end

function SkillEffectParam_ResetSelectGridElement:GetEffectType()
    return SkillEffectType.ResetSelectGridElement
end

function SkillEffectParam_ResetSelectGridElement:GetSelectConditionSrcElement()
    if self._selectCondition~=nil then
        return self._selectCondition["srcElement"]
    end
end