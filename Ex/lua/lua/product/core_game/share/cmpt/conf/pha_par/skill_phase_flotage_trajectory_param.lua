--[[------------------------------------------------------------------------------------------
    FlotageTrajectory = 90, -- 先浮力上升，再轨迹攻击目标（贾尔斯连锁技）
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---
_class("SkillPhaseFlotageTrajectoryParam", SkillPhaseParamBase)
---@class SkillPhaseFlotageTrajectoryParam: SkillPhaseParamBase
SkillPhaseFlotageTrajectoryParam = SkillPhaseFlotageTrajectoryParam
--
function SkillPhaseFlotageTrajectoryParam:Constructor(t)
    self._efffectID = t.effectID

    self._spawnRadiusMin = t.spawnRadiusMin --产生的位置偏移最小半径
    self._spawnRadiusMax = t.spawnRadiusMax --产生的位置偏移最小半径

    self._offsetPosX = t.offsetPosX or 0 --出生固定偏移的坐标，基于施法者root
    self._offsetPosY = t.offsetPosY or 0
    self._offsetPosZ = t.offsetPosZ or 0

    self._firstPosX = t.firstPosX --为了导弹的朝向做的 初始第一个飞的朝向点
    self._firstPosY = t.firstPosY
    self._firstPosZ = t.firstPosZ
    self._firstPosRandom = t.firstPosRandom

    self._spawnIntervalTime = t.spawnIntervalTime --产生的间隔时间

    self._upSpeed = t.upSpeed --爬升速度

    --扰动偏移
    local upShakeDisX = t.upShakeDisX
    local upShakeDisY = t.upShakeDisY
    local upShakeDisZ = t.upShakeDisZ
    self._upShakeDis = Vector3(upShakeDisX, upShakeDisY, upShakeDisZ)
    -- self._upShakeDis = t.upShakeDis --爬升扰动强度

    self._upShakeDertaTimeMin = t.upShakeDertaTimeMin --爬升扰动间隔时间最小
    self._upShakeDertaTimeMax = t.upShakeDertaTimeMax --爬升扰动间隔时间最大

    self._fireTimeMin = t.fireTimeMin --开火时间
    self._fireTimeMax = t.fireTimeMax --开火时间

    self._flyTime = t.flyTime --飞行时间
    self._flyRandomDis = t.flyRandomDis --飞行中随机点的距离
    self._flyRandomPointCount = t.flyRandomPointCount --飞行中随机的点数量

    self._destroyBulletDelay = t.destroyBulletDelay --子弹到达Hit点后等待一个时间后再删除
    self._targetHit = t.targetHit --目标的被击点，默认Hit点，可以指定挂点
    self._targetHitOffsetMin = t.targetHitOffsetMin --目标偏移坐标
    self._targetHitOffsetMax = t.targetHitOffsetMax --目标偏移坐标
    self._turnToTarget = t.turnToTarget --只执行一次
    self._hitAnimName = t.hitAnimName --每次伤害都执行
    self._hitEffectID = t.hitEffectID --每次伤害都执行

    --
    self._hitPointDelay = t.hitPointDelay or 0 --爆点延迟，这个值会控制飞行时间

    self._fireEffectID = t.fireEffectID --开火特效
    self._disableRoot = t.disableRoot --关闭的节点

    self._summonTrapWithHit = t.summonTrapWithHit --在爆点的时候播放召唤机关
    self._summonTrapEffectID = t.summonTrapEffectID
    self._summonTrapDirToTarget = t.summonTrapDirToTarget

    self._needLookAt = t.needLookAt --弹道中间需要朝向

    self._hitSoundID = t.hitSoundID or 0 --每次伤害都执行
end
--
function SkillPhaseFlotageTrajectoryParam:GetCacheTable()
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
function SkillPhaseFlotageTrajectoryParam:GetPhaseType()
    return SkillViewPhaseType.FlotageTrajectory
end
--
function SkillPhaseFlotageTrajectoryParam:GetEffectID()
    return self._efffectID
end
--产生的位置偏移
function SkillPhaseFlotageTrajectoryParam:GetSpawnRadiusMin()
    return self._spawnRadiusMin
end
--产生时的随机方向偏移
function SkillPhaseFlotageTrajectoryParam:GetSpawnRadiusMax()
    return self._spawnRadiusMax
end
--产生的间隔时间
function SkillPhaseFlotageTrajectoryParam:GetSpawnIntervalTime()
    return self._spawnIntervalTime
end
--
function SkillPhaseFlotageTrajectoryParam:GetSpawnOffsetPos()
    return Vector3(self._offsetPosX, self._offsetPosY, self._offsetPosZ)
end
---
function SkillPhaseFlotageTrajectoryParam:GetPathFirstPos()
    if not self._firstPosX then
        return nil
    end
    return Vector3(self._firstPosX, self._firstPosY, self._firstPosZ)
end
function SkillPhaseFlotageTrajectoryParam:GetFirstPosRandom()
    return self._firstPosRandom
end

--爬升速度/路径就换成时间
function SkillPhaseFlotageTrajectoryParam:GetUpSpeed()
    return self._upSpeed
end
--爬升高度
function SkillPhaseFlotageTrajectoryParam:GetUpShakeDis()
    return self._upShakeDis
end
--爬升扰动时间最小
function SkillPhaseFlotageTrajectoryParam:GetUpShakeDertaTimeMin()
    return self._upShakeDertaTimeMin
end
--爬升扰动
function SkillPhaseFlotageTrajectoryParam:GetUpShakeDertaTimeMax()
    return self._upShakeDertaTimeMax
end
--开火时间
function SkillPhaseFlotageTrajectoryParam:GetFireTimeMin()
    return self._fireTimeMin
end
--开火时间
function SkillPhaseFlotageTrajectoryParam:GetFireTimeMax()
    return self._fireTimeMax
end
--飞行时间
function SkillPhaseFlotageTrajectoryParam:GetFlyTime()
    return self._flyTime
end
--飞行中随机的点距离
function SkillPhaseFlotageTrajectoryParam:GetFlyRandomDis()
    return self._flyRandomDis
end
--飞行中随机的点数量
function SkillPhaseFlotageTrajectoryParam:GetFlyRandomPointCount()
    return self._flyRandomPointCount
end
--子弹到达Hit点后等待一个时间后再删除
function SkillPhaseFlotageTrajectoryParam:GetdestroyBulletDelay()
    return self._destroyBulletDelay
end
--目标的被击点，默认Hit点，可以指定挂点
function SkillPhaseFlotageTrajectoryParam:GetTargetHit()
    return self._targetHit
end
--目标偏移坐标
function SkillPhaseFlotageTrajectoryParam:GetTargetHitOffsetMin()
    return self._targetHitOffsetMin
end
--目标偏移坐标
function SkillPhaseFlotageTrajectoryParam:GetTargetHitOffsetMax()
    return self._targetHitOffsetMax
end
--
function SkillPhaseFlotageTrajectoryParam:GetTurnToTarget()
    return self._turnToTarget
end
--
function SkillPhaseFlotageTrajectoryParam:GetHitAnimName()
    return self._hitAnimName
end
--
function SkillPhaseFlotageTrajectoryParam:GetHitEffectID()
    return self._hitEffectID
end
--
function SkillPhaseFlotageTrajectoryParam:GetHitPointDelay()
    return self._hitPointDelay
end

function SkillPhaseFlotageTrajectoryParam:GetFireEffectID()
    return self._fireEffectID
end

function SkillPhaseFlotageTrajectoryParam:GetDisableRoot()
    return self._disableRoot
end

function SkillPhaseFlotageTrajectoryParam:GetSummonTrapWithHit()
    return self._summonTrapWithHit
end

function SkillPhaseFlotageTrajectoryParam:GetSummonTrapEffectID()
    return self._summonTrapEffectID
end

function SkillPhaseFlotageTrajectoryParam:GetSummonTrapDirToTarget()
    return self._summonTrapDirToTarget
end

function SkillPhaseFlotageTrajectoryParam:GetNeedLookAt()
    return self._needLookAt
end

function SkillPhaseFlotageTrajectoryParam:GetHitSoundID()
    return self._hitSoundID
end

------------------------------------------------------------------------------------------
