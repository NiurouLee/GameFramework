--[[------------------------------------------------------------------------------------------
    SkillPhaseScopePushOrPullParam : 露比主动技表现 参数
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
_class("SkillPhaseScopePushOrPullParam", SkillPhaseParamBase)
---@class SkillPhaseScopePushOrPullParam: Object
SkillPhaseScopePushOrPullParam = SkillPhaseScopePushOrPullParam

function SkillPhaseScopePushOrPullParam:Constructor(t)
    self._bornEffectID = t.bornEffectID
    self._moveEffectID = t.moveEffectID
    self._disappearEffectID = t.disappearEffectID
    self._disappearEffectTime = t.disappearEffectTime
    self._bornEffectDelayTime = t.bornEffectDelayTime
    self._moveEffectDelayTime = t.moveEffectDelayTime
    self._moveEffectFlyOneGirdMs = t.moveEffectFlyOneGirdMs
    self._hasDamage = t.hasDamage
    self._hasConvert = t.hasConvert
    self._hitAnimationName = t.hitAnimationName
    self._hitEffectID = t.hitEffectID
    self._gridEffectDirection = t.gridEffectDirection
end

---@param skillConfigData SkillConfigData
function SkillPhaseScopePushOrPullParam:GetCacheTable(skillConfigData)
    ---@type SkillScopeType
    local skillScopeType = skillConfigData:GetSkillScopeType()
    local skillScopeParam = skillConfigData:GetSkillScopeParam()
    local cacheNum = self:_CalcScopeRangeGridNum(skillScopeType,skillScopeParam)

    local t = {}
    if self._gridEffectID and self._gridEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._gridEffectID].ResPath, cacheNum}
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._hitEffectID].ResPath, cacheNum}
    end
    return t
end

function SkillPhaseScopePushOrPullParam:GetPhaseType()
    return SkillViewPhaseType.ScopePushOrPull
end

function SkillPhaseScopePushOrPullParam:GetBornEffectID()
    return self._bornEffectID
end

function SkillPhaseScopePushOrPullParam:GetMoveEffectID()
    return self._moveEffectID
end

function SkillPhaseScopePushOrPullParam:GetDisappearEffectID()
    return self._disappearEffectID
end
function SkillPhaseScopePushOrPullParam:GetDisappearEffectTime()
    return self._disappearEffectTime
end

function SkillPhaseScopePushOrPullParam:GetBornEffectDelayTime()
    return self._bornEffectDelayTime
end
function SkillPhaseScopePushOrPullParam:GetMoveEffectDelayTime()
    return self._moveEffectDelayTime
end
function SkillPhaseScopePushOrPullParam:GetEffectFlyOneGridMs()
    return self._moveEffectFlyOneGirdMs
end

---@return boolean
function SkillPhaseScopePushOrPullParam:HasDamage()
    if self._hasDamage then
        return self._hasDamage == 1
    else
        return false
    end
end

---@return boolean
function SkillPhaseScopePushOrPullParam:HasConvert()
    if self._hasConvert then
        return self._hasConvert == 1
    else
        return false
    end
end

function SkillPhaseScopePushOrPullParam:GetHitAnimationName()
    return self._hitAnimationName
end

function SkillPhaseScopePushOrPullParam:GetHitEffectID()
    return self._hitEffectID
end

function SkillPhaseScopePushOrPullParam:GetEffectDirection()
    return self._gridEffectDirection
end
