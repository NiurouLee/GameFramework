--[[------------------------------------------------------------------------------------------
    SummonOnFixPosLimit = 131, ---根据配置的X个固定点，依次召唤Y个机关；若场上机关大于上限Z，则销毁最先召唤的
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamSummonOnFixPosLimit", SkillEffectParamBase)
---@class SkillEffectParamSummonOnFixPosLimit: SkillEffectParamBase
SkillEffectParamSummonOnFixPosLimit = SkillEffectParamSummonOnFixPosLimit

function SkillEffectParamSummonOnFixPosLimit:Constructor(t)
    self._trapID = t.trapID --召唤的机关ID

    --配置的X个固定点
    self._posList = {}
    for i, v in ipairs(t.pos) do
        table.insert(self._posList, Vector2(v[1], v[2]))
    end

    self._summonCount = t.summonCount --单次召唤数量
    self._limitCount = t.limitCount --场上总数量限制

    self._ignoreBlock = t.ignoreBlock or false
end

function SkillEffectParamSummonOnFixPosLimit:GetEffectType()
    return SkillEffectType.SummonOnFixPosLimit
end

function SkillEffectParamSummonOnFixPosLimit:GetTrapID()
    return self._trapID
end

function SkillEffectParamSummonOnFixPosLimit:IgnoreBlock()
    return self._ignoreBlock
end

function SkillEffectParamSummonOnFixPosLimit:GetLimitCount()
    return self._limitCount
end

function SkillEffectParamSummonOnFixPosLimit:GetSummonCount()
    return self._summonCount
end

function SkillEffectParamSummonOnFixPosLimit:GetFixPosList()
    return self._posList
end
