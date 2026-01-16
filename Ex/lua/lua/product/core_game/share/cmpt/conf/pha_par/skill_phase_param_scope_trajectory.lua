require "skill_phase_param_base"
_class("SkillPhaseParamScopeTrajectory", SkillPhaseParamBase)
---@class SkillPhaseParamScopeTrajectory: SkillPhaseParamBase
SkillPhaseParamScopeTrajectory = SkillPhaseParamScopeTrajectory

function SkillPhaseParamScopeTrajectory:Constructor(t)
    self._scopeHorizontalOrVertical = t.scopeHorizontalOrVertical == 1

    -- 以下参数按ScopeTrajectory的时间轴顺序排列
    -- 角色两侧的伤害表现延时 (两侧目标不会被弹道覆盖，要单独做)
    self._sidesDamageDelay = t.sidesDamageDelay or 0

    -- 创建弹道的延时 (注意：这是从该phase开始的延时时间)
    self._trajectoryCreateDelay = t.trajectoryCreateDelay or 0

    -- 弹道创建参数
    self._trajectoryEffectID = t.trajectoryEffectID
    self._trajectoryEffectOffset = t.trajectoryEffectOffset
    self._trajectoryTime = t.trajectoryTime ---特效飞行时间: 单格飞行时间,
    self._totalTime = t.totalTime ---飞行总时间： 如果为nil则总时间使用“弹道长度*单格飞行时间"作为飞行时长

    self._trajectoryFollowingEffectID = t.trajectoryFollowingEffectID -- 弹道上附加的效果id
    self._trajectoryFinishEffectID = t.trajectoryFinishEffectID -- 弹道消失时出现的效果id
    self._trajectoryFinishEffectTime = t.trajectoryFinishEffectTime -- 弹道消失后fx的效果持续时间

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

    self._beginDelayTime = t.beginDelayTime
    self._finishDelayTime = t.finishDelayTime
    self._tailDismissDelay = t.tailDismissDelay

    self._sidesEffectID = t.sidesEffectID
    self._sidesEffectDelayMS = t.sidesEffectDelayMS

    self._trajectoryFlightEndOffset = t.trajectoryFlightEndOffset or 0
end

function SkillPhaseParamScopeTrajectory:GetTrajectoryFlightEndOffset()
    return self._trajectoryFlightEndOffset
end

function SkillPhaseParamScopeTrajectory:GetScopeHorizontalOrVertical()
    return self._scopeHorizontalOrVertical
end

function SkillPhaseParamScopeTrajectory:GetCacheTable()
    local listID = {}
    self:AddEffectIDToListID(listID, self._trajectoryEffectID)
    self:AddEffectIDToListID(listID, self._targetEffectID)
    self:AddEffectIDToListID(listID, self._hitEffectID)
    self:AddEffectIDToListID(listID, self._sidesEffectID)
    -- self:AddEffectIDToListID(listID, self._trajectoryFollowingEffectID)
    -- self:AddEffectIDToListID(listID, self._trajectoryFinishEffectID)
    return self:GetCacheTableFromListID(listID)
end

function SkillPhaseParamScopeTrajectory:GetPhaseType()
    return SkillViewPhaseType.ScopeTrajectory
end
--------------------------------
function SkillPhaseParamScopeTrajectory:GetTrajectoryEffectID()
    return self._trajectoryEffectID
end
function SkillPhaseParamScopeTrajectory:GetTrajectoryEffectOffset()
    return self._trajectoryEffectOffset
end
function SkillPhaseParamScopeTrajectory:GetTrajectoryTime()
    return self._trajectoryTime
end
function SkillPhaseParamScopeTrajectory:GetTotalTime()
    return self._totalTime
end
--------------------------------
function SkillPhaseParamScopeTrajectory:GetTargetWaitTime()
    return self._targetWaitTime
end
function SkillPhaseParamScopeTrajectory:GetTargetEffectID()
    return self._targetEffectID
end
function SkillPhaseParamScopeTrajectory:GetTargetDelayTime()
    return self._targetDelayTime
end
--------------------------------
function SkillPhaseParamScopeTrajectory:GetHitAnimation()
    return self._hitAnimationName
end
function SkillPhaseParamScopeTrajectory:GetHitEffectID()
    return self._hitEffectID
end
function SkillPhaseParamScopeTrajectory:GetHitEffectTime()
    return self._hitEffectTime
end
function SkillPhaseParamScopeTrajectory:GetDamageIndex()
    return self._damageIndex
end
function SkillPhaseParamScopeTrajectory:IsClearBodyNow()
    if self._clearBodyNow and self._clearBodyNow > 0 then
        return true
    end
    return false
end
--------------------------------
function SkillPhaseParamScopeTrajectory:GetFinishDelayTime()
    return self._finishDelayTime
end

function SkillPhaseParamScopeTrajectory:GetBeginDelayTime()
    return self._beginDelayTime
end
function SkillPhaseParamScopeTrajectory:GetTrajectoryFollowingEffectID()
    return self._trajectoryFollowingEffectID
end
function SkillPhaseParamScopeTrajectory:GetTrajectoryFinishEffectID()
    return self._trajectoryFinishEffectID
end
function SkillPhaseParamScopeTrajectory:GetTrajectoryFinishEffectTime()
    return self._trajectoryFinishEffectTime
end

function SkillPhaseParamScopeTrajectory:GetTailDismissDelay()
    return self._tailDismissDelay
end

function SkillPhaseParamScopeTrajectory:GetSidesDamageDelay() return self._sidesDamageDelay end
function SkillPhaseParamScopeTrajectory:GetTrajectoryCreateDelay() return self._trajectoryCreateDelay end

function SkillPhaseParamScopeTrajectory:GetSidesEffectID()
    return self._sidesEffectID
end

function SkillPhaseParamScopeTrajectory:SidesEffectDelay()
    return self._sidesEffectDelayMS
end