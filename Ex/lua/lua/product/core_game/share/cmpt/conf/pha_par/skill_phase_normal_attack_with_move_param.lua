--[[------------------------------------------------------------------------------------------
    NormalAttackWithMove = 93, ---普攻在移动过程中
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseNormalAttackWithMoveParam: SkillPhaseParamBase
_class("SkillPhaseNormalAttackWithMoveParam", SkillPhaseParamBase)
SkillPhaseNormalAttackWithMoveParam = SkillPhaseNormalAttackWithMoveParam
---
---@type SkillCommonParam
function SkillPhaseNormalAttackWithMoveParam:Constructor(t)
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
end
---
function SkillPhaseNormalAttackWithMoveParam:GetPhaseType()
    return SkillViewPhaseType.NormalAttackWithMove
end
---
function SkillPhaseNormalAttackWithMoveParam:GetCastEffectID()
    return self._castEffectID
end
---
function SkillPhaseNormalAttackWithMoveParam:GetAnimationName(isFinalAttack)
    if isFinalAttack and self._castLongAnimation then
        return self._castLongAnimation
    else
        return self._castAnimation
    end
end
---
function SkillPhaseNormalAttackWithMoveParam:GetHitPointDelay(isFinalAttack)
    if isFinalAttack and self._longHitPointDelay then
        return self._longHitPointDelay
    else
        return self._hitPointDelay
    end
end
---
function SkillPhaseNormalAttackWithMoveParam:GetCastTotalTime(isFinalAttack)
    if isFinalAttack and self._longCastTotalTime then
        return self._longCastTotalTime
    else
        return self._castTotalTime
    end
end
---
function SkillPhaseNormalAttackWithMoveParam:GetCacheTable()
    local t = {}
    if self._castEffectID and self._castEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._castEffectID].ResPath, 1})
    end

    return t
end
---
function SkillPhaseNormalAttackWithMoveParam:GetHitEffectDelay(isFinalAttack)
    if isFinalAttack and self._longAtkEffectDelay then
        return self._longAtkEffectDelay
    else
        return self._atkEffectDelay
    end
end
---
function SkillPhaseNormalAttackWithMoveParam:GetDamageIndex()
    return self._nDamageIndex
end
