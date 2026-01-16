--[[------------------------------------------------------------------------------------------
    CircularTrajectory = 92, --在指定挂点的环形范围内，根据伤害结果创建特效
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---
_class("SkillPhaseCircularTrajectoryParam", SkillPhaseParamBase)
---@class SkillPhaseCircularTrajectoryParam: SkillPhaseParamBase
SkillPhaseCircularTrajectoryParam = SkillPhaseCircularTrajectoryParam
--
function SkillPhaseCircularTrajectoryParam:Constructor(t)
    self._efffectID = t.effectID

    self._spawnCenterBone = t.spawnCenterBone --施法者的被击点，默认Hit点，可以指定挂点
    self._spawnRadiusMin = t.spawnRadiusMin --产生的位置偏移最小半径
    self._spawnRadiusMax = t.spawnRadiusMax --产生的位置偏移最小半径

    self._spawnIntervalTime = t.spawnIntervalTime --产生的间隔时间

    self._waitFireTime = t.waitFireTime --开火时间
    self._flyTime = t.flyTime --飞行时间

    self._destroyBulletDelay = t.destroyBulletDelay --子弹到达Hit点后等待一个时间后再删除
    self._targetHit = t.targetHit --目标的被击点，默认Hit点，可以指定挂点
    self._turnToTarget = t.turnToTarget --只执行一次
    self._hitAnimName = t.hitAnimName --每次伤害都执行
    self._hitEffectID = t.hitEffectID --每次伤害都执行

    --有一只箭的时候的坐标
    self._oneArrowOffsetX = t.oneArrowOffsetX or 0
    self._oneArrowOffsetY = t.oneArrowOffsetY or 0
    self._oneArrowOffsetZ = t.oneArrowOffsetZ or 0
end
--
function SkillPhaseCircularTrajectoryParam:GetCacheTable()
    local t = {}
    if self._efffectID and self._efffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._efffectID].ResPath, 5})
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, 5})
    end
    return t
end
--
function SkillPhaseCircularTrajectoryParam:GetPhaseType()
    return SkillViewPhaseType.CircularTrajectory
end
--
function SkillPhaseCircularTrajectoryParam:GetEffectID()
    return self._efffectID
end
--
function SkillPhaseCircularTrajectoryParam:GetSpawnCenterBone()
    return self._spawnCenterBone
end
--产生的位置偏移
function SkillPhaseCircularTrajectoryParam:GetSpawnRadiusMin()
    return self._spawnRadiusMin
end
--产生时的随机方向偏移
function SkillPhaseCircularTrajectoryParam:GetSpawnRadiusMax()
    return self._spawnRadiusMax
end
--产生的间隔时间
function SkillPhaseCircularTrajectoryParam:GetSpawnIntervalTime()
    return self._spawnIntervalTime
end

--开火时间
function SkillPhaseCircularTrajectoryParam:GetWaitFireTime()
    return self._waitFireTime
end
--飞行时间
function SkillPhaseCircularTrajectoryParam:GetFlyTime()
    return self._flyTime
end

--子弹到达Hit点后等待一个时间后再删除
function SkillPhaseCircularTrajectoryParam:GetdestroyBulletDelay()
    return self._destroyBulletDelay
end
--目标的被击点，默认Hit点，可以指定挂点
function SkillPhaseCircularTrajectoryParam:GetTargetHit()
    return self._targetHit
end
--
function SkillPhaseCircularTrajectoryParam:GetTurnToTarget()
    return self._turnToTarget
end
--
function SkillPhaseCircularTrajectoryParam:GetHitAnimName()
    return self._hitAnimName
end
--
function SkillPhaseCircularTrajectoryParam:GetHitEffectID()
    return self._hitEffectID
end
--
function SkillPhaseCircularTrajectoryParam:GetOneArrowOffset()
    return Vector3(self._oneArrowOffsetX, self._oneArrowOffsetY, self._oneArrowOffsetZ)
end
