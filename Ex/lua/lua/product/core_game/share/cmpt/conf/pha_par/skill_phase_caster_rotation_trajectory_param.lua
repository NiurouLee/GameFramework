--[[------------------------------------------------------------------------------------------
    CasterRotationTrajectory = 97, --施法者转圈发射弹道，会将逻辑结果根据表现动作排序（凯雅连锁）
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---
_class("SkillPhaseCasterRotationTrajectoryParam", SkillPhaseParamBase)
---@class SkillPhaseCasterRotationTrajectoryParam: SkillPhaseParamBase
SkillPhaseCasterRotationTrajectoryParam = SkillPhaseCasterRotationTrajectoryParam
--
function SkillPhaseCasterRotationTrajectoryParam:Constructor(t)
    self._effectID = t.effectID

    self._fireEffectID = t.fireEffectID --开火特效
    self._spawnHigh = t.spawnHigh --产生特效的位置高度
    self._spawnRadius = t.spawnRadius --产生特效的位置半径

    self._rotationTime = t.rotationTime --旋转一圈的时间

    -- self._spawnIntervalTime = t.spawnIntervalTime --产生的间隔时间
    --间隔是根据角度计算的

    self._flyOneTime = t.flyOneTime --飞行距离1的时间

    self._destroyBulletDelay = t.destroyBulletDelay --子弹到达Hit点后等待一个时间后再删除
    self._disableRoot = t.disableRoot --关闭的节点

    self._turnToTarget = t.turnToTarget --只执行一次
    self._hitAnimName = t.hitAnimName --每次伤害都执行
    self._hitEffectID = t.hitEffectID --每次伤害都执行

    self._cacheEffectCount = t.cacheEffectCount or 1
end
--
function SkillPhaseCasterRotationTrajectoryParam:GetCacheTable()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, self._cacheEffectCount})
    end
    if self._fireEffectID and self._fireEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._fireEffectID].ResPath, self._cacheEffectCount})
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, self._cacheEffectCount})
    end
    return t
end
--
function SkillPhaseCasterRotationTrajectoryParam:GetPhaseType()
    return SkillViewPhaseType.CasterRotationTrajectory
end
--
function SkillPhaseCasterRotationTrajectoryParam:GetEffectID()
    return self._effectID
end
function SkillPhaseCasterRotationTrajectoryParam:GetFireEffectID()
    return self._fireEffectID
end
--产生特效的位置高度
function SkillPhaseCasterRotationTrajectoryParam:GetSpawnHigh()
    return self._spawnHigh
end
--产生特效的位置半径
function SkillPhaseCasterRotationTrajectoryParam:GetSpawnRadius()
    return self._spawnRadius
end
--旋转一圈的时间
function SkillPhaseCasterRotationTrajectoryParam:GetRotationTime()
    return self._rotationTime
end
--飞行距离1的时间
function SkillPhaseCasterRotationTrajectoryParam:GetFlyOneTime()
    return self._flyOneTime
end
--子弹到达Hit点后等待一个时间后再删除
function SkillPhaseCasterRotationTrajectoryParam:GetdestroyBulletDelay()
    return self._destroyBulletDelay
end
--关闭的节点
function SkillPhaseCasterRotationTrajectoryParam:GetDisableRoot()
    return self._disableRoot
end
--
function SkillPhaseCasterRotationTrajectoryParam:GetTurnToTarget()
    return self._turnToTarget
end
--
function SkillPhaseCasterRotationTrajectoryParam:GetHitAnimName()
    return self._hitAnimName
end
--
function SkillPhaseCasterRotationTrajectoryParam:GetHitEffectID()
    return self._hitEffectID
end
