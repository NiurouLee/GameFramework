--[[------------------------------------------------------------------------------------------
    SkillEffectPopStarParam : 技能消灭星星效果参数
]]
--------------------------------------------------------------------------------------------
require("skill_effect_param_base")

_class("SkillEffectPopStarParam", SkillEffectParamBase)
---@class SkillEffectPopStarParam: SkillEffectParamBase
SkillEffectPopStarParam = SkillEffectPopStarParam

function SkillEffectPopStarParam:Constructor(t)
    ---消除格子的属性列表
    self._pieceTypeList = t.pieceTypeList

    ---消除数量，与随机消除数量互斥
    self._popCount = t.popCount

    ---是否从技能范围内随机对应属性的格子进行消除
    self._random = t.random or false

    ---随机消除数量，闭区间{ min = 6, max = 10 }
    self._countRandomTab = t.countRandom
end

function SkillEffectPopStarParam:GetEffectType()
    return SkillEffectType.PopStar
end

function SkillEffectPopStarParam:GetPieceTypeList()
    return self._pieceTypeList
end

function SkillEffectPopStarParam:GetPopCount()
    return self._popCount
end

function SkillEffectPopStarParam:NeedRandom()
    return self._random
end

function SkillEffectPopStarParam:GetCountRandomTab()
    return self._countRandomTab
end
