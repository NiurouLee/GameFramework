--[[------------------------------------------------------------------------------------------
    SkillPhaseAOEDamageParam : 对所有目标的单体伤害
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseAOEDamageParam: Object
_class("SkillPhaseAOEDamageParam", SkillPhaseParamBase)
SkillPhaseAOEDamageParam = SkillPhaseAOEDamageParam

---@type SkillCommonParam
function SkillPhaseAOEDamageParam:Constructor(t)
    ---对每个目标的施法特效ID
    self._casterEffectID = t.casterEffectID
    ---爆点延迟
    self._hitPointDelay = t.hitPointDelay
    --AOE间隔
    self._intervalTime = t.intervalTime
    --被击特效ID
    self._hitEffectID = t.hitEffectID
    ---被击动画
    self._hitAnimName = t.hitAnimName
end

function SkillPhaseAOEDamageParam:GetCacheTable()
    local t = {}
    if self._casterEffectID and self._casterEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._casterEffectID].ResPath, 1})
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, 1})
    end
    return t
end

function SkillPhaseAOEDamageParam:GetPhaseType()
    return SkillViewPhaseType.AOEDamage
end

function SkillPhaseAOEDamageParam:GetSkillCastEffectID()
    return self._casterEffectID
end

function SkillPhaseAOEDamageParam:GetSkillHitPointDelay()
    return self._hitPointDelay
end

function SkillPhaseAOEDamageParam:GetSkillAOEInterval()
    return self._intervalTime
end

function SkillPhaseAOEDamageParam:GetSkillHitEffectID()
    return self._hitEffectID
end

function SkillPhaseAOEDamageParam:GetSkillHitAnimName()
    return self._hitAnimName
end