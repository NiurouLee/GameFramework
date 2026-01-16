--[[------------------------------------------------------------------------------------------
NormalAttackForAddBlood = 85, ---普攻加血
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseNormalAttackForAddBloodParam: Object
_class("SkillPhaseNormalAttackForAddBloodParam", SkillPhaseParamBase)
SkillPhaseNormalAttackForAddBloodParam = SkillPhaseNormalAttackForAddBloodParam

---@type SkillCommonParam
function SkillPhaseNormalAttackForAddBloodParam:Constructor(t)
    self._castTotalTime = t.castTotalTime
    self._longCastTotalTime = t.longCastTotalTime
    self._hpDelayTime = t.hpDelayTime
    self._nDamageIndex = t.damageIndex or 1
    --正向普攻
    self._castAnimation = t.castAnimation
    self._castLongAnimation = t.castLongAnimation
    self._castEffectID = t.castEffectID

    --正常一个普攻就算多个伤害也是一个爆点
    self._hitPointDelay = t.hitPointDelay
    self._longHitPointDelay = t.longHitPointDelay
    self._atkEffectDelay = t.atkEffectDelay or 0
    self._longAtkEffectDelay = t.longAtkEffectDelay or 0

    --普攻双击，第二次重新计算普攻，如果第二次普攻造成伤害，需要在加血普攻里表现
    self._normalDoubleHitEffectID = t.normalDoubleHitEffectID
    self._normalDoubleHitAnimation = t.normalDoubleHitAnimation
end

function SkillPhaseNormalAttackForAddBloodParam:GetPhaseType()
    return SkillViewPhaseType.NormalAttackForAddBlood
end

function SkillPhaseNormalAttackForAddBloodParam:GetCastEffectID()
    return self._castEffectID
end

function SkillPhaseNormalAttackForAddBloodParam:GetAnimationName(isFinalAttack)
    if isFinalAttack and self._castLongAnimation then
        return self._castLongAnimation
    else
        return self._castAnimation
    end
end

function SkillPhaseNormalAttackForAddBloodParam:GetHitPointDelay(isFinalAttack)
    if isFinalAttack and self._longHitPointDelay then
        return self._longHitPointDelay
    else
        return self._hitPointDelay
    end
end

function SkillPhaseNormalAttackForAddBloodParam:GetCastTotalTime(isFinalAttack)
    if isFinalAttack and self._longCastTotalTime then
        return self._longCastTotalTime
    else
        return self._castTotalTime
    end
end

function SkillPhaseNormalAttackForAddBloodParam:GetCacheTable()
    local t = {}
    if self._castEffectID and self._castEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._castEffectID].ResPath, 1})
    end

    return t
end

function SkillPhaseNormalAttackForAddBloodParam:GetHPDelay()
    return self._hpDelayTime
end

function SkillPhaseNormalAttackForAddBloodParam:GetHitEffectDelay(isFinalAttack)
    if isFinalAttack and self._longAtkEffectDelay then
        return self._longAtkEffectDelay
    else
        return self._atkEffectDelay
    end
end

function SkillPhaseNormalAttackForAddBloodParam:GetDamageIndex()
    return self._nDamageIndex
end

function SkillPhaseNormalAttackForAddBloodParam:GetNormalDoubleHitEffectID()
    return self._normalDoubleHitEffectID
end

function SkillPhaseNormalAttackForAddBloodParam:GetNormalDoubleHitAnimation()
    return self._normalDoubleHitAnimation
end
