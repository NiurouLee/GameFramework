--[[------------------------------------------------------------------------------------------
    SkillPhaseAttackAnimationParam : 技能攻击动画阶段
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseAttackAnimationParam: SkillPhaseParamBase
_class("SkillPhaseAttackAnimationParam", SkillPhaseParamBase)
SkillPhaseAttackAnimationParam = SkillPhaseAttackAnimationParam

function SkillPhaseAttackAnimationParam:Constructor(t)
    self._hitAnimation = t.onHitAnimation
    self._castTotalTime = t.castTotalTime
    self._longCastTotalTime = t.longCastTotalTime
    self._hpDelayTime = t.hpDelayTime
    self._nDamageIndex = t.damageIndex or 1
    --正向普攻
    self._castAnimation = t.castAnimation
    self._castLongAnimation = t.castLongAnimation
    self._castEffectID = t.castEffectID
    self._hitEffectID = t.hitEffectID

    --正常一个普攻就算多个伤害也是一个爆点
    self._hitPointDelay = t.hitPointDelay
    self._longHitPointDelay = t.longHitPointDelay
    self._atkEffectDelay = t.atkEffectDelay or 0
    self._longAtkEffectDelay = t.longAtkEffectDelay or 0

    --有的普攻有2下伤害，2下combo，2个爆点(渡)      目前不支持斜向
    self._hitPointDelaySecond = t.hitPointDelaySecond
    self._longHitPointDelaySecond = t.longHitPointDelaySecond

    --斜向普攻
    self._slantCastAnimation = t.slantCastAnimation
    self._slantCastLongAnimation = t.slantCastLongAnimation
    self._slantCastEffectID = t.slantCastEffectID
    self._slantHitEffectID = t.slantHitEffectID

    self._slantHitPointDelay = t.slantHitPointDelay
    self._slantLongHitPointDelay = t.slantLongHitPointDelay
    self._slantAtkEffectDelay = t.slantAtkEffectDelay or 0
    self._slantLongAtkEffectDelay = t.slantLongAtkEffectDelay or 0

    self._usePermanentEffectPlayAnim = t.usePermanentEffectPlayAnim
    self._permanentEffSpecialAnimRoot = t.permanentEffSpecialAnimRoot--特效 anim组件不在Root
end

function SkillPhaseAttackAnimationParam:GetPhaseType()
    return SkillViewPhaseType.AttackAnimation
end

function SkillPhaseAttackAnimationParam:GetCastEffectID(isSlantAttack)
    if isSlantAttack then
        return self._slantCastEffectID
    end

    return self._castEffectID
end

function SkillPhaseAttackAnimationParam:GetSlantCastEffectID()
    return self._slantCastEffectID
end

function SkillPhaseAttackAnimationParam:GetAnimationName(isFinalAttack, isSlantAttack)
    if isSlantAttack then
        if isFinalAttack and self._slantCastLongAnimation then
            return self._slantCastLongAnimation
        else
            return self._slantCastAnimation
        end
    end

    if isFinalAttack and self._castLongAnimation then
        return self._castLongAnimation
    else
        return self._castAnimation
    end
end

function SkillPhaseAttackAnimationParam:GetHitPointDelay(isFinalAttack, isSlantAttack)
    if isSlantAttack then
        if isFinalAttack and self._slantLongHitPointDelay then
            return self._slantLongHitPointDelay
        else
            return self._slantHitPointDelay
        end
    end

    if isFinalAttack and self._longHitPointDelay then
        return self._longHitPointDelay
    else
        return self._hitPointDelay
    end
end

--第二个爆点
function SkillPhaseAttackAnimationParam:GetHitPointDelaySecond(isFinalAttack)
    if isFinalAttack and self._longHitPointDelaySecond then
        return self._longHitPointDelaySecond
    else
        return self._hitPointDelaySecond
    end
end

function SkillPhaseAttackAnimationParam:GetHitAnimation()
    return self._hitAnimation
end

function SkillPhaseAttackAnimationParam:GetHitEffectID(isSlantAttack)
    if isSlantAttack then
        return self._slantHitEffectID
    end

    return self._hitEffectID
end

function SkillPhaseAttackAnimationParam:GetCastTotalTime(isFinalAttack)
    if isFinalAttack and self._longCastTotalTime then
        return self._longCastTotalTime
    else
        return self._castTotalTime
    end
end

function SkillPhaseAttackAnimationParam:GetCacheTable()
    local t = {}
    if self._castEffectID and self._castEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._castEffectID].ResPath, 1})
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, 1})
    end
    if self._slantCastEffectID and self._slantCastEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._slantCastEffectID].ResPath, 1})
    end
    if self._slantHitEffectID and self._slantHitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._slantHitEffectID].ResPath, 1})
    end
    return t
end

function SkillPhaseAttackAnimationParam:GetHPDelay()
    return self._hpDelayTime
end

function SkillPhaseAttackAnimationParam:GetHitEffectDelay(isFinalAttack, isSlantAttack)
    if isSlantAttack then
        if isFinalAttack and self._slantLongAtkEffectDelay then
            return self._slantLongAtkEffectDelay
        else
            return self._slantAtkEffectDelay
        end
    end

    if isFinalAttack and self._longAtkEffectDelay then
        return self._longAtkEffectDelay
    else
        return self._atkEffectDelay
    end
end

function SkillPhaseAttackAnimationParam:GetDamageIndex()
    return self._nDamageIndex
end
function SkillPhaseAttackAnimationParam:IsUsePermanentEffectPlayAnim()
    return self._usePermanentEffectPlayAnim
end
function SkillPhaseAttackAnimationParam:GetPermanentEffSpecialAnimRoot()
    return self._permanentEffSpecialAnimRoot
end