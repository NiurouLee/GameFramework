--[[------------------------------------------------------------------------------------------
    SkillPhaseParam_Trajectory : 弹道特效，给定起点和终点
]] --------------------------------------------------------------------------------------------

require "skill_phase_param_base"


--- @class SkillPhaseParam_TrajectoryType
local SkillPhaseParam_TrajectoryType = {
    Line = 1,   ---支线弹道
    Parabola = 2,   ---抛物线
    Laser = 3,  ---激光 2020-03-10未实现
}
_enum("SkillPhaseParam_TrajectoryType", SkillPhaseParam_TrajectoryType)
----------------------------------------------------------------
--- @class SkillPhaseParam_PointType
local SkillPhaseParam_PointType = {
    UserParam   = 0,    ---使用自定义坐标
    CasterPos   = 1,    ---使用发起人坐标
    CasterX     = 2,    ---使用发起人的X坐标，Y坐标自定义
    CasterY     = 3,    ---使用发起人的Y坐标，X坐标自定义
    TargetPos   = 11,   ---使用目标人坐标
    TargetX     = 12,   ---使用目标人的X坐标，Y坐标自定义
    TargetY     = 13,   ---使用目标人的Y坐标，X坐标自定义
}
_enum("SkillPhaseParam_PointType", SkillPhaseParam_PointType)
----------------------------------------------------------------
_class("SkillPhaseParam_Trajectory", SkillPhaseParamBase)
---@class SkillPhaseParam_Trajectory
SkillPhaseParam_Trajectory = SkillPhaseParam_Trajectory

function SkillPhaseParam_Trajectory:Constructor(t)
    ---弹道类型
    self._trajectoryType = t.trajectoryType
    self._trajectoryEffectID = t.trajectoryEffectID
    self._trajectoryEffectOffset = t.trajectoryEffectOffset
    self._trajectoryTime = t.trajectoryTime     ---特效飞行时间: 单格飞行时间, 
    self._totalTime = t.totalTime;              ---飞行总时间： 如果为nil则总时间使用“弹道长度*单格飞行时间"作为飞行时长

    self._casterType = t.casterType
    self._casterParam = t.casterParam
    self._targetType = t.targetType
    self._targetParam = t.targetParam
    ---命中特效
    self._targetWaitTime = t.targetWaitTime
	self._targetEffectID = t.targetEffectID
    self._targetDelayTime = t.targetDelayTime or 0
    ---受击
    self._hitAnimationName = t.hitAnimationName
    self._hitEffectID = t.hitEffectID
    self._hitEffectTime = t.hitEffectTime
    self._clearBodyNow = t.clearBodyNow
    self._damageIndex = t.damageIndex or 1

    self._finishDelayTime = t.finishDelayTime
end

function SkillPhaseParam_Trajectory:GetCacheTable()
    local listID = {}
    self:AddEffectIDToListID(listID, self._trajectoryEffectID)
    self:AddEffectIDToListID(listID, self._targetEffectID)
    self:AddEffectIDToListID(listID, self._hitEffectID)
    return self:GetCacheTableFromListID(listID)
end

function SkillPhaseParam_Trajectory:GetPhaseType()
    return SkillViewPhaseType.Trajectory
end
--------------------------------
function SkillPhaseParam_Trajectory:GetTrajectoryType()
    return self._trajectoryType
end
function SkillPhaseParam_Trajectory:GetTrajectoryEffectID()
    return self._trajectoryEffectID
end
function SkillPhaseParam_Trajectory:GetTrajectoryEffectOffset()
    return self._trajectoryEffectOffset
end
function SkillPhaseParam_Trajectory:GetTrajectoryTime()
    return self._trajectoryTime
end
function SkillPhaseParam_Trajectory:GetTotalTime()
    return self._totalTime
end
--------------------------------
function SkillPhaseParam_Trajectory:GetCasterType()
    return self._casterType
end
function SkillPhaseParam_Trajectory:GetCasterParam()
    return self._casterParam
end
function SkillPhaseParam_Trajectory:GetTargetType()
    return self._targetType
end
function SkillPhaseParam_Trajectory:GetTargetParam()
    return self._targetParam
end
--------------------------------
function SkillPhaseParam_Trajectory:GetTargetWaitTime()
	return self._targetWaitTime
end
function SkillPhaseParam_Trajectory:GetTargetEffectID()
	return self._targetEffectID
end
function SkillPhaseParam_Trajectory:GetTargetDelayTime()
    return self._targetDelayTime
end
--------------------------------
function SkillPhaseParam_Trajectory:GetHitAnimation()
    return self._hitAnimationName
end
function SkillPhaseParam_Trajectory:GetHitEffectID()
    return self._hitEffectID
end
function SkillPhaseParam_Trajectory:GetHitEffectTime()
    return self._hitEffectTime
end
function SkillPhaseParam_Trajectory:GetDamageIndex()
    return self._damageIndex
end
function SkillPhaseParam_Trajectory:IsClearBodyNow()
    if self._clearBodyNow and self._clearBodyNow > 0 then
        return true
    end
    return false
end
--------------------------------
function SkillPhaseParam_Trajectory:GetFinishDelayTime()
    return self._finishDelayTime
end
