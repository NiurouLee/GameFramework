--[[------------------------------------------------------------------------------------------
    PetTrapMove = 201, --光灵机关移动
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamPetTrapMove", SkillEffectParamBase)
---@class SkillEffectParamPetTrapMove: SkillEffectParamBase
SkillEffectParamPetTrapMove = SkillEffectParamPetTrapMove

function SkillEffectParamPetTrapMove:Constructor(t)
    self._moveStep = t.moveStep
    self._moveType = t.moveType
    self._moveParam = t.moveParam
    self._canMoveTrapLevel = t.canMoveTrapLevel
end

function SkillEffectParamPetTrapMove:GetEffectType()
    return SkillEffectType.PetTrapMove
end

function SkillEffectParamPetTrapMove:GetMoveStep()
    return self._moveStep
end

function SkillEffectParamPetTrapMove:GetMoveType()
    return self._moveType
end

function SkillEffectParamPetTrapMove:GetMoveParam()
    return self._moveParam
end

function SkillEffectParamPetTrapMove:GetCanMoveTrapLevel()
    return self._canMoveTrapLevel
end

--- @class PetTrapMoveType
local PetTrapMoveType = {
    CloseToTeam = 1, --靠近队伍
    AwayFromTeam = 2, --远离队伍
    FixedPos = 3, --固定位置
    SkillPos = 4, --可以放技能的位置
    Loop = 5, --循环固定位置
    MAX = 9 --
}
_enum("PetTrapMoveType", PetTrapMoveType)
