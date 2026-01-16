--[[------------------------------------------------------------------------------------------
    SkillDelayHitBackEffectResult : 统一结算类型击退效果结果
]] --------------------------------------------------------------------------------------------
require "skill_effect_result_base"

---@class SkillDelayHitBackEffectResult:SkillEffectResultBase
_class("SkillDelayHitBackEffectResult", SkillEffectResultBase)
SkillDelayHitBackEffectResult = SkillDelayHitBackEffectResult

function SkillDelayHitBackEffectResult:Constructor(
    casterEntityID,
    victimID,
    distance,
    dirType,
    asterPos,
    gridPos,
    targetLocationCenter,
    targetBodyArea)
    self._casterID = casterEntityID
    self._victimID = victimID
    --表里配置的击退距离
    self._distance = distance
    self._dirType = dirType
    self._casterPos = asterPos
    self._gridPos = gridPos
    self._targetLocationCenter = targetLocationCenter
    self._targetBodyArea = targetBodyArea
    if asterPos then
        self._attackDistance = math.abs(asterPos.y - gridPos.y) + math.abs(asterPos.x - gridPos.x)
    end
end

function SkillDelayHitBackEffectResult:GetEffectType()
    return SkillEffectType.HitBack
end

---施法者的ID
function SkillDelayHitBackEffectResult:GetCasterEntityID()
    return self._casterID
end

---施法者坐标
function SkillDelayHitBackEffectResult:GetCasterPos()
    return self._casterPos
end

---被击点坐标
function SkillDelayHitBackEffectResult:GetGridPos()
    return self._gridPos
end

---被击者的逻辑坐标
function SkillDelayHitBackEffectResult:GetTargetLocationCenter()
    return self._targetLocationCenter
end

---被击者的身形
function SkillDelayHitBackEffectResult:GetTargetBodyArea()
    return self._targetBodyArea
end

---从发力点到受力点的距离
function SkillDelayHitBackEffectResult:GetAttackDistance()
    return self._attackDistance
end

---被击退者的ID
function SkillDelayHitBackEffectResult:GetTargetID()
    return self._victimID
end

---击退的距离
function SkillDelayHitBackEffectResult:GetHitbackDistance()
    return self._distance
end

---击退的方向
function SkillDelayHitBackEffectResult:GetHitbackDirType()
    return self._dirType
end

---设置击退的方向
---当设置8方向的时候，还需要根据目标位置重置一个具体的方向
function SkillDelayHitBackEffectResult:SetHitbackDirType(newHitbackDirType)
    self._dirType = newHitbackDirType
end

function SkillDelayHitBackEffectResult:GetCalcType()
    return HitBackCalcType.Delay
end
