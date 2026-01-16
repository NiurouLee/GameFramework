--[[------------------------------------------------------------------------------------------
    NormalAttackOnlyAnimation = 91, ---普攻只做动画表演
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseNormalAttackOnlyAnimationParam: SkillPhaseParamBase
_class("SkillPhaseNormalAttackOnlyAnimationParam", SkillPhaseParamBase)
SkillPhaseNormalAttackOnlyAnimationParam = SkillPhaseNormalAttackOnlyAnimationParam
---
---@type SkillCommonParam
function SkillPhaseNormalAttackOnlyAnimationParam:Constructor(t)
    self._castTotalTime = t.castTotalTime
    self._longCastTotalTime = t.longCastTotalTime
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

    --普攻双击，第二次重新计算普攻，如果第二次普攻造成伤害，需要在动画普攻里表现
    self._normalDoubleHitEffectID = t.normalDoubleHitEffectID
    self._normalDoubleHitAnimation = t.normalDoubleHitAnimation
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetPhaseType()
    return SkillViewPhaseType.NormalAttackOnlyAnimation
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetCastEffectID()
    return self._castEffectID
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetAnimationName(isFinalAttack)
    if isFinalAttack and self._castLongAnimation then
        return self._castLongAnimation
    else
        return self._castAnimation
    end
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetHitPointDelay(isFinalAttack)
    if isFinalAttack and self._longHitPointDelay then
        return self._longHitPointDelay
    else
        return self._hitPointDelay
    end
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetCastTotalTime(isFinalAttack)
    if isFinalAttack and self._longCastTotalTime then
        return self._longCastTotalTime
    else
        return self._castTotalTime
    end
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetCacheTable()
    local t = {}
    if self._castEffectID and self._castEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._castEffectID].ResPath, 1})
    end

    return t
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetHitEffectDelay(isFinalAttack)
    if isFinalAttack and self._longAtkEffectDelay then
        return self._longAtkEffectDelay
    else
        return self._atkEffectDelay
    end
end
---
function SkillPhaseNormalAttackOnlyAnimationParam:GetDamageIndex()
    return self._nDamageIndex
end

function SkillPhaseNormalAttackOnlyAnimationParam:GetNormalDoubleHitEffectID()
    return self._normalDoubleHitEffectID
end

function SkillPhaseNormalAttackOnlyAnimationParam:GetNormalDoubleHitAnimation()
    return self._normalDoubleHitAnimation
end
