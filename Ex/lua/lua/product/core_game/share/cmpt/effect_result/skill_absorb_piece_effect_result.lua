--[[------------------------------------------------------------------------------------------
    SkillAbsorbPieceEffectResult : 技能加buff结果
]] --------------------------------------------------------------------------------------------
require('skill_effect_result_base')
_class("SkillAbsorbPieceEffectResult", SkillEffectResultBase)
---@class SkillAbsorbPieceEffectResult:SkillEffectResultBase
SkillAbsorbPieceEffectResult = SkillAbsorbPieceEffectResult

function SkillAbsorbPieceEffectResult:Constructor()
    ---@type Vector2[]
    self._targetAbsorbPieceList = {}
	self._newPieceList ={}
end

function SkillAbsorbPieceEffectResult:GetEffectType()
    return SkillEffectType.AbsorbPiece
end

function SkillAbsorbPieceEffectResult:GetAbsorbPieceList()
    return self._targetAbsorbPieceList
end
---@param pieceList Vector2[]
function SkillAbsorbPieceEffectResult:SetAbsorbPieceList(pieceList)
    self._targetAbsorbPieceList = pieceList
end

function SkillAbsorbPieceEffectResult:SetNewPieceList(newPieceList)
	self._newPieceList = newPieceList
end

function SkillAbsorbPieceEffectResult:GetNewPieceList()
	return self._newPieceList
end