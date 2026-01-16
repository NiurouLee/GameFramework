--[[----------------------------------------------------------------
    SkillEffectParamEachGridAddBlood : 根据格子数量加血效果参数
--]] ----------------------------------------------------------------
require("skill_effect_param_base")

---@class SkillEffectParamEachGridAddBlood: SkillEffectParamBase
_class("SkillEffectParamEachGridAddBlood", SkillEffectParamBase)
SkillEffectParamEachGridAddBlood = SkillEffectParamEachGridAddBlood

function SkillEffectParamEachGridAddBlood:Constructor(t)
    self._baseAddValue = t.baseAddValue
    self._baseAddType = t.baseAddType
    self._onePieceAddValue = t.addValue
    self._onePieceAddType = t.addType

    --强化格子额外恢复参数
    self._enhanceGridRecoverValue = t.enhanceGridAddValue
end

function SkillEffectParamEachGridAddBlood:GetEffectType()
    return SkillEffectType.EachGridAddBlood
end

--增加的基础血量，可能是增加的真实值也可能是百分比
function SkillEffectParamEachGridAddBlood:GetBaseAddValue()
    return self._baseAddValue
end

--基础血量增加的类型
function SkillEffectParamEachGridAddBlood:GetBaseAddType()
    return self._baseAddType
end

--一个方块增加的血量的值，可能是增加的真实值也可能是百分比
function SkillEffectParamEachGridAddBlood:GetOnePieceAddValue()
    return self._onePieceAddValue
end

--单个格子增加血量的类型
function SkillEffectParamEachGridAddBlood:GetOnePieceAddType()
    return self._onePieceAddType
end

function SkillEffectParamEachGridAddBlood:GetEnhanceGridRecoverValue()
    return self._enhanceGridRecoverValue
end
