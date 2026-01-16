--[[------------------------------------------------------------------------------------------
    SphereTrajectoryMultiStageDamage = 81, -- 球型轨迹随机多段攻击目标（渡主动技）
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
_class("SkillPhaseSphereTrajectoryMultiStageDamageParam", SkillPhaseParamBase)
---@class SkillPhaseSphereTrajectoryMultiStageDamageParam: Object
SkillPhaseSphereTrajectoryMultiStageDamageParam = SkillPhaseSphereTrajectoryMultiStageDamageParam

function SkillPhaseSphereTrajectoryMultiStageDamageParam:Constructor(t)
    self._eftID = t.effectID
    self._trajectoryCount = t.trajectoryCount --最少弹道数量
    self._sphereRadius = t.sphereRadius or 5 --球的半径
    -- self.block = t.block or 1 --是否阻塞 默认阻塞
    self._startWait = t.startWait or 0
    self._moveSpeed = t.moveSpeed --移动速度
    self._rotateSpeed = t.rotateSpeed --旋转速度

    --被击相关
    self._turnToTarget = t.turnToTarget --只执行一次
    self._hitAnimName = t.hitAnimName --每次伤害都执行
    self._hitEffectID = t.hitEffectID --每次伤害都执行
    self._hitSoundID = t.hitSoundID or 0 --每次伤害都执行
    self._intervalTime = t.intervalTime or 300 --间隔时间
    self._random = t.random or 0 --是否伤害随机，默认不随机
    self._randomPercent = t.randomPercent or 10 --随机数值在区间内的10%，取值范围0~100
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetCacheTable()
    local t = {}
    --目前缓存了1个,但是用的时候基本都是10个以上
    if self._eftID and self._eftID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._eftID].ResPath, 1})
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, 1})
    end
    return t
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetPhaseType()
    return SkillViewPhaseType.SphereTrajectoryMultiStageDamage
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetEftID()
    return self._eftID
end
function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetTrajectoryCount()
    return self._trajectoryCount
end
function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetSphereRadius()
    return self._sphereRadius
end
function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetStartWait()
    return self._startWait
end
function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetMoveSpeed()
    return self._moveSpeed
end
function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetRotateSpeed()
    return self._rotateSpeed
end

--
function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetTurnToTarget()
    return self._turnToTarget
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetHitAnimName()
    return self._hitAnimName
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetHitEffectID()
    return self._hitEffectID
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetHitSoundID()
    return self._hitSoundID
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetIntervalTime()
    return self._intervalTime
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetRandom()
    return self._random
end

function SkillPhaseSphereTrajectoryMultiStageDamageParam:GetRandomPercent()
    return self._randomPercent
end
