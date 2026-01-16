--[[------------------------------------------------------------------------------------------
    CircleFlyMultipleEffect = 81, --星灵头顶环形飞多个弹道特效到目标点 （焚霜座连锁技）
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
_class("SkillPhaseCircleFlyMultipleEffectParam", SkillPhaseParamBase)
---@class SkillPhaseCircleFlyMultipleEffectParam: Object
SkillPhaseCircleFlyMultipleEffectParam = SkillPhaseCircleFlyMultipleEffectParam

function SkillPhaseCircleFlyMultipleEffectParam:Constructor(t)
    self._radius = t.radius --以人所在的格子为中心 创建特效的半径
    self._high = t.high --飞行弹道的高度
    self._angle = t.angle --限制2个格子特效的最小角度
    self._gridEffectID = t.gridEffectID --格子特效
    self._flyEffectID = t.flyEffectID --飞行的弹道特效
    self._hitEffectID = t.hitEffectID --怪物被击特效
    self._waitFlyTime = t.waitFlyTime --从格子特效开始播放 到飞行弹道中间等待的时间
    self._flyTime = t.flyTime --飞行弹道特效的飞行时间
end

function SkillPhaseCircleFlyMultipleEffectParam:GetCacheTable()
    local t = {}
    if self._gridEffectID and self._gridEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._gridEffectID].ResPath, 3})
    end
    if self._flyEffectID and self._flyEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._flyEffectID].ResPath, 3})
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, 3})
    end
    return t
end

function SkillPhaseCircleFlyMultipleEffectParam:GetPhaseType()
    return SkillViewPhaseType.CircleFlyMultipleEffect
end

function SkillPhaseCircleFlyMultipleEffectParam:GetRadius()
    return self._radius
end
function SkillPhaseCircleFlyMultipleEffectParam:GetHigh()
    return self._high
end
function SkillPhaseCircleFlyMultipleEffectParam:GetAngle()
    return self._angle
end
function SkillPhaseCircleFlyMultipleEffectParam:GetGridEffectID()
    return self._gridEffectID
end
function SkillPhaseCircleFlyMultipleEffectParam:GetFlyEffectID()
    return self._flyEffectID
end
function SkillPhaseCircleFlyMultipleEffectParam:GetHitEffectID()
    return self._hitEffectID
end
function SkillPhaseCircleFlyMultipleEffectParam:GetWaitFlyTime()
    return self._waitFlyTime
end
function SkillPhaseCircleFlyMultipleEffectParam:GetFlyTime()
    return self._flyTime
end
