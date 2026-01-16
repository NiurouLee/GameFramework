--[[------------------------------------------------------------------------------------------
    SummonMeantimeLimit = 117, ---限制同时存在数量的召唤，当新的召唤成功后，如果同时存在的数量超过了限制，销毁最先召唤的。
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamSummonMeantimeLimit", SkillEffectParamBase)
---@class SkillEffectParamSummonMeantimeLimit: SkillEffectParamBase
SkillEffectParamSummonMeantimeLimit = SkillEffectParamSummonMeantimeLimit

function SkillEffectParamSummonMeantimeLimit:Constructor(t)
    self._trapID = t.trapID
    self._limitCount = t.limitCount --数量限制
    self._trapDieSkillID = t.trapDieSkillID --机关超出上限的时候，需要执行的技能

    self._ignoreBlock = t.ignoreBlock or false
    self._overlapFlag = t.overlapFlag or 1 --机关是否可重叠（同一位置召唤同一ID机关），默认可重复召唤
    self._absPosArray = t.absPos or {}
    self._replaceAttr = t.replaceAttr or {}
    ---@type number[]
    self._checkTrapID = t.checkTrapID or { self._trapID }
end

function SkillEffectParamSummonMeantimeLimit:GetEffectType()
    return SkillEffectType.SummonMeantimeLimit
end

function SkillEffectParamSummonMeantimeLimit:GetTrapID()
    return self._trapID
end

function SkillEffectParamSummonMeantimeLimit:IgnoreBlock()
    return self._ignoreBlock
end
---@return number[]
function SkillEffectParamSummonMeantimeLimit:GetCheckTrapID()
    return self._checkTrapID
end
function SkillEffectParamSummonMeantimeLimit:GetLimitCount()
    return self._limitCount
end

function SkillEffectParamSummonMeantimeLimit:GetTrapDieSkillID()
    return self._trapDieSkillID
end
---@return boolean
function SkillEffectParamSummonMeantimeLimit:IsTrapOverlap()
    return self._overlapFlag == 1
end
function SkillEffectParamSummonMeantimeLimit:GetAbsPosArray()
    return self._absPosArray
end
function SkillEffectParamSummonMeantimeLimit:GetReplaceAttr()
    return self._replaceAttr
end