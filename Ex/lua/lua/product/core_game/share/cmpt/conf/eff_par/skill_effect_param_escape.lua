--[[----------------------------------------------------------------
    2020-04-33 韩玉信添加
    SkillEffectParam_Escape : 瞬移
--]] ----------------------------------------------------------------

----------------------------------------------------------------
require "skill_damage_effect_param"

----------------------------------------------------------------
---@class SkillEffectParam_Escape: SkillEffectParamBase
_class("SkillEffectParam_Escape", SkillEffectParamBase)
SkillEffectParam_Escape = SkillEffectParam_Escape

function SkillEffectParam_Escape:Constructor(t)
    self._escapeType = t.escapeType or 1 --默认是技能目标
    self._escapeParam = t.escapeParam
end

function SkillEffectParam_Escape:GetEffectType()
    return SkillEffectType.Escape
end

function SkillEffectParam_Escape:GetEscapeType()
    return self._escapeType
end

function SkillEffectParam_Escape:GetEscapeParam()
    return self._escapeParam
end

----------------------------------------------------------------

---@class EscapeType
local EscapeType = {
    SkillTarget = 1, --技能目标，不是立刻逃脱，等待指定时机再释放技能
    Chess = 2, --棋子逃脱，立刻逃脱
    MAX = 9
}
_enum("EscapeType", EscapeType)
