--[[------------------------------------------------------------------------------------------
 MultiStageDamage = 80, -- 将一个伤害拆成多段伤害表现
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
_class("SkillPhaseMultiStageDamageParam", SkillPhaseParamBase)
---@class SkillPhaseMultiStageDamageParam: Object
SkillPhaseMultiStageDamageParam = SkillPhaseMultiStageDamageParam

function SkillPhaseMultiStageDamageParam:Constructor(t)
    self._turnToTarget = t.turnToTarget --只执行一次
    self._hitAnimName = t.hitAnimName --每次伤害都执行
    self._hitEffectID = t.hitEffectID --每次伤害都执行
    self._deathClear = false --拒绝死亡清理
    self._stageCount = t.stageCount --有几个阶段
    self._intervalTime = t.intervalTime or 300 --间隔时间
    self._random = t.random or 0 --是否伤害随机，默认不随机
    self._randomPercent = t.randomPercent or 10 --随机数值在区间内的10%，取值范围0~100
end

function SkillPhaseMultiStageDamageParam:GetCacheTable()
    local t = {}
    local gridFxCacheElement = self:GenerateCacheTableElementByID(self._hitEffectID)
    table.insert(t, gridFxCacheElement)
    return t
end

function SkillPhaseMultiStageDamageParam:GetPhaseType()
    return SkillViewPhaseType.MultiStageDamage
end

function SkillPhaseMultiStageDamageParam:GetTurnToTarget()
    return self._turnToTarget
end

function SkillPhaseMultiStageDamageParam:GetHitAnimName()
    return self._hitAnimName
end

function SkillPhaseMultiStageDamageParam:GetHitEffectID()
    return self._hitEffectID
end

function SkillPhaseMultiStageDamageParam:GetStageCount()
    return self._stageCount
end

function SkillPhaseMultiStageDamageParam:GetIntervalTime()
    return self._intervalTime
end

function SkillPhaseMultiStageDamageParam:GetRandom()
    return self._random
end

function SkillPhaseMultiStageDamageParam:GetRandomPercent()
    return self._randomPercent
end
