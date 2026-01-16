--[[------------------------------------------------------------------------------------------

]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamSummonFourAreaMonsterOnBoardEdge", SkillEffectParam_SummonEverything)
---@class SkillEffectParamSummonFourAreaMonsterOnBoardEdge: SkillEffectParam_SummonEverything
SkillEffectParamSummonFourAreaMonsterOnBoardEdge = SkillEffectParamSummonFourAreaMonsterOnBoardEdge

function SkillEffectParamSummonFourAreaMonsterOnBoardEdge:Constructor(t)
    self._summonID = {}
    if type(t.summonID) == "number" then
        self._summonID[#self._summonID + 1] = t.summonID
    elseif type(t.summonID) == "table" then
        self._summonID = t.summonID
    end

    self._summonCount = t.summonCount or 1 --召唤的数量，不配默认1
end

function SkillEffectParamSummonFourAreaMonsterOnBoardEdge:GetEffectType()
    return SkillEffectType.SummonFourAreaMonsterOnBoardEdge
end

---获取召唤目标类型ID
function SkillEffectParamSummonFourAreaMonsterOnBoardEdge:GetSummonList()
    return self._summonID
end

function SkillEffectParamSummonFourAreaMonsterOnBoardEdge:GetSummonCount()
    return self._summonCount
end
