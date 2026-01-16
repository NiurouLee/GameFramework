--[[------------------------------------------------------------------------------------------
    SkillPhaseParamScopeForwardByDistance : 以施法者为中心向外展开格子效果
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
_class("SkillPhaseParamScopeForwardByDistance", SkillPhaseParamBase)
---@class SkillPhaseParamScopeForwardByDistance: SkillPhaseParamBase
SkillPhaseParamScopeForwardByDistance = SkillPhaseParamScopeForwardByDistance

function SkillPhaseParamScopeForwardByDistance:Constructor(t)
    self._gridEffectID = t.gridEffectID
    self._intervalTime = t.intervalTime
    self._hitEffectID = t.hitEffectID
    self._gridEffectDirection = t.gridEffectDirection
    self._scopeHorizontalOrVertical = t.scopeHorizontalOrVertical
    self._hitAnimationName = t.hitAnimName
    self._quadrantDiagonal = t.quadrantDiagonal --在4象限中的特效是否是斜的
end

function SkillPhaseParamScopeForwardByDistance:GetCacheTable()
    local t = {}
    if self._gridEffectID and self._gridEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._gridEffectID].ResPath, 1}
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._hitEffectID].ResPath, 1}
    end
    return t
end

function SkillPhaseParamScopeForwardByDistance:GetPhaseType()
    return SkillViewPhaseType.ScopeForwardByDistance
end

function SkillPhaseParamScopeForwardByDistance:GetEffectIntervalTime()
    return self._intervalTime
end

function SkillPhaseParamScopeForwardByDistance:GetGridEffectDirection()
    return self._gridEffectDirection
end

function SkillPhaseParamScopeForwardByDistance:GetGridEffectID()
    return self._gridEffectID
end

function SkillPhaseParamScopeForwardByDistance:GetHitEffectID()
    return self._hitEffectID
end

function SkillPhaseParamScopeForwardByDistance:GetScopeType()
    return self._scopeHorizontalOrVertical
end

function SkillPhaseParamScopeForwardByDistance:GetHitAnimationName()
    return self._hitAnimationName
end

function SkillPhaseParamScopeForwardByDistance:GetQuadrantDiagonal()
    return self._quadrantDiagonal
end
