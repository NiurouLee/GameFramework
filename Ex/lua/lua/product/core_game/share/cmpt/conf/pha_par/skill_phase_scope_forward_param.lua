--[[------------------------------------------------------------------------------------------
    SkillPhaseSquareRingParam : 技能方环形效果
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
_class("SkillPhaseScopeForwardParam", SkillPhaseParamBase)
---@class SkillPhaseScopeForwardParam: Object
SkillPhaseScopeForwardParam = SkillPhaseScopeForwardParam

function SkillPhaseScopeForwardParam:Constructor(t)
    self._gridEffectID = t.gridEffectID
    self._gridIntervalTime = t.gridIntervalTime
    self._bestConvertTime = t.bestConvertTime
    self._finishDelayTime = t.finishDelayTime
    self._hasDamage = t.hasDamage
    self._hasConvert = t.hasConvert
    self._hitAnimationName = t.hitAnimationName
    self._hitEffectID = t.hitEffectID
    self._gridEffectDirection = t.gridEffectDirection
    self._backward = t.backward
    self._backwardByPickNum = t.backwardByPickNum
end

---@param skillConfigData SkillConfigData
function SkillPhaseScopeForwardParam:GetCacheTable(skillConfigData)
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

function SkillPhaseScopeForwardParam:GetPhaseType()
    return SkillViewPhaseType.ScopeForward
end

function SkillPhaseScopeForwardParam:GetGridEffectID()
    return self._gridEffectID
end

function SkillPhaseScopeForwardParam:GetGridIntervalTime()
    return self._gridIntervalTime
end

function SkillPhaseScopeForwardParam:GetBestEffectTime()
    return self._bestConvertTime
end

---@return number
function SkillPhaseScopeForwardParam:GetFinishDelayTime()
    return self._finishDelayTime
end

---@return boolean
function SkillPhaseScopeForwardParam:HasDamage()
    if self._hasDamage then
        return self._hasDamage == 1
    else
        return false
    end
end

---@return boolean
function SkillPhaseScopeForwardParam:HasConvert()
    if self._hasConvert then
        return self._hasConvert == 1
    else
        return false
    end
end

function SkillPhaseScopeForwardParam:GetGridEffectTime()
    return self._gridEffectTime
end

function SkillPhaseScopeForwardParam:GetHitAnimationName()
    return self._hitAnimationName
end

function SkillPhaseScopeForwardParam:GetHitEffectID()
    return self._hitEffectID
end

function SkillPhaseScopeForwardParam:GetEffectDirection()
    return self._gridEffectDirection
end
---@return boolean
function SkillPhaseScopeForwardParam:IsBackward(pickNum)
    if self._backward then
        return self._backward == 1
    elseif self._backwardByPickNum then
        if pickNum then
            if self._backwardByPickNum == pickNum then
                return true
            end
        end
    end
    return false
end