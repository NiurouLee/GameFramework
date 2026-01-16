--[[------------------------------------------------------------------------------------------
    SkillPhaseAbsorbPieceParam : 技能吸收格子阶段
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

_class("SkillPhaseAbsorbPieceParam", SkillPhaseParamBase)
---@class SkillPhaseAbsorbPieceParam
SkillPhaseAbsorbPieceParam = SkillPhaseAbsorbPieceParam

---@class AbsorbPiecePlayType
local AbsorbPiecePlayType= {
	Normal=1,---按照与施法者距离一圈圈播放
}
_enum("AbsorbPiecePlayType",AbsorbPiecePlayType)

function SkillPhaseAbsorbPieceParam:Constructor(t)
	self._scopeDelay = t.scopeDelay      ---每一圈的间隔
	self._changeDelay  = t.changeDelay   ---经过时间后 变成格子消失状态
	self._displayDelay = t.displayDelay  ---经过时间过 由格子消失状态变出格子
	self._gridEffectID = t.gridEffectID
	self._gridPlayType = t.gridPlayType
end

function SkillPhaseAbsorbPieceParam:GetCacheTable()
	local t
	if self._gridEffectID ~= 0 then
		t = {
			{Cfg.cfg_effect[self._gridEffectID].ResPath, 1},
		}
	end
	return t
end

function SkillPhaseAbsorbPieceParam:GetPhaseType()
	return  SkillViewPhaseType.AbsorbPieceAnimation
end

function SkillPhaseAbsorbPieceParam:GetScopeDelay()
	return self._scopeDelay
end

function SkillPhaseAbsorbPieceParam:GetGridPlayType()
	return self._gridPlayType
end

function SkillPhaseAbsorbPieceParam:GetChangeDelay()
	return self._changeDelay
end

--吸收格子延时,延时时间到后真正执行吸收格子逻辑
function SkillPhaseAbsorbPieceParam:GetDisPlayDelay()
	return self._displayDelay
end

function SkillPhaseAbsorbPieceParam:GetGridEffectID()
	return self._gridEffectID
end