--[[------------------------------------------------------------------------------------------
    SkillPhaseTrainHitBackParam : 技能火车击退
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
_class("SkillPhaseTrainHitBackParam", SkillPhaseParamBase)
---@class SkillPhaseTrainHitBackParam: Object
SkillPhaseTrainHitBackParam = SkillPhaseTrainHitBackParam

function SkillPhaseTrainHitBackParam:Constructor(t)
	self._hitAnimationName = t.hitAnimationName
	self._hitFirstEffectID = t.hitFirstEffectID
	self._hitRepeatEffectID = t.hitRepeatEffectID



	self._hideList= t.hideList
	self._showList=t.showList

	self._multiMonsterHitDelayTime = t.multiMonsterHitDelayTime

	self._casterInTrainHigh = t.casterInTrainHigh
	self._hitBackSpeed = t.hitBackSpeed

	--self._hideEffectDelayTime1 = t.hideEffectDelayTime1
	--self._hideEffectID1 = t.hideEffectID1
	--self._hideAnimationDelayTime1 = t.hideAnimationDelayTime1
	--self._showEffectDelayTime1 = t.showEffectDelayTime1
	--self._showEffectID1= t.showEffectID1
	--self._hideEffectID2 = t.hideEffectID2
	--self._hideEffectDelayTime2 = t.hideEffectDelayTime2
	--self._showEffectDelayTime2 = t.showEffectDelayTime2
	--self._showEffectID2= t.showEffectID2

	self._hideAnimationName = t.hideAnimationName


	self._showAnimationName = t.showAnimationName
	self._trainEffectID = t.trainEffectID
	self._boardCenterPos = Vector2(t.boardCenterPos[1],t.boardCenterPos[2])
	self._trainEffectDelay = t.trainEffectDelay

	self._finishDelayTime = t.finishDelayTime
end

function SkillPhaseTrainHitBackParam:GetCacheTable()
	local t = {}
	t[#t + 1] = {Cfg.cfg_effect[self._hitFirstEffectID].ResPath, 1}
	t[#t + 1] = {Cfg.cfg_effect[self._hitRepeatEffectID].ResPath, 1}
	t[#t + 1] = {Cfg.cfg_effect[self._trainEffectID].ResPath, 1}
	
	--t[#t + 1] = {Cfg.cfg_effect[self._hideEffectID].ResPath, 1}
	--t[#t + 1] = {Cfg.cfg_effect[self._showEffectID].ResPath, 1}

	return t
end

function SkillPhaseTrainHitBackParam:GetPhaseType()
	return SkillViewPhaseType.TrainHitBack
end

function SkillPhaseTrainHitBackParam:GetHitRepeatEffectIntervalTime()
	return self._hitRepeatEffectIntervalTime
end

function SkillPhaseTrainHitBackParam:GetHitAnimationName()
	return self._hitAnimation
end

function SkillPhaseTrainHitBackParam:GetHitFirstEffectID()
	return self._hitFirstEffectID
end
function SkillPhaseTrainHitBackParam:GetHitRepeatEffectID()
	return self._hitRepeatEffectID
end

function SkillPhaseTrainHitBackParam:GetHideEffectID()
	return self._hideEffectID
end

function SkillPhaseTrainHitBackParam:GetShowEffectID()
	return self._showEffectID
end

function SkillPhaseTrainHitBackParam:GetHideAnimationName()
	return self._hideAnimationName
end

function SkillPhaseTrainHitBackParam:GetShowAnimationName()
	return self._showAnimationName
end

function SkillPhaseTrainHitBackParam:GetTrainEffectID()
	return self._trainEffectID
end

function SkillPhaseTrainHitBackParam:GetBoardCenterPos()
	return self._boardCenterPos
end

function SkillPhaseTrainHitBackParam:GetHideParam(hideIndex)
	return self._hideList[hideIndex]
end

function SkillPhaseTrainHitBackParam:GetShowParam(showIndex)
	return self._showList[showIndex]
end

function SkillPhaseTrainHitBackParam:GetMultiMonsterHitDelayTime()
	return self._multiMonsterHitDelayTime
end

function SkillPhaseTrainHitBackParam:GetCasterInTrainHigh()
	return self._casterInTrainHigh
end

function SkillPhaseTrainHitBackParam:GetHitBackSpeed()
	return self._hitBackSpeed
end

function SkillPhaseTrainHitBackParam:GetTrainEffectDelay()
	return self._trainEffectDelay
end

function SkillPhaseTrainHitBackParam:GetFinishDelayTime()
	return self._finishDelayTime
end