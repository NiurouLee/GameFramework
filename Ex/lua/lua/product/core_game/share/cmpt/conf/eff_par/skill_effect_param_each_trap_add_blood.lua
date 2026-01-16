--[[----------------------------------------------------------------
    SkillEffectParamEachTrapAddBlood : 根据机关数量加血效果参数
--]] ----------------------------------------------------------------
require("skill_effect_param_base")


---@class TrapAddBloodParamType
local TrapAddBloodParamType = {
    CasterMaxHP = 1, --施法者最大血量
}
_enum("TrapAddBloodParamType", TrapAddBloodParamType)


---@class SkillEffectParamEachTrapAddBlood: SkillEffectParamBase
_class("SkillEffectParamEachTrapAddBlood", SkillEffectParamBase)
SkillEffectParamEachTrapAddBlood = SkillEffectParamEachTrapAddBlood

function SkillEffectParamEachTrapAddBlood:Constructor(t)
    self._trapId = t.trapId
    self._oneTrapAddValue = t.oneTrapAddValue
    self._baseAddValue = t.baseAddValue or 0
    self._addParamType = t.addParamType or TrapAddBloodParamType.CasterMaxHP
end

function SkillEffectParamEachTrapAddBlood:GetEffectType()
    return SkillEffectType.EachTrapAddBlood
end
--有机关时基础的回血量 百分比
function SkillEffectParamEachTrapAddBlood:GetBaseAddValue()
    return self._baseAddValue
end
--每个机关增加的回血量 百分比
function SkillEffectParamEachTrapAddBlood:GetOneTrapAddValue()
    return self._oneTrapAddValue
end
--根据哪个属性回血
function SkillEffectParamEachTrapAddBlood:GetAddParamType()
    return self._addParamType
end
function SkillEffectParamEachTrapAddBlood:GetTrapId()
    return self._trapId
end