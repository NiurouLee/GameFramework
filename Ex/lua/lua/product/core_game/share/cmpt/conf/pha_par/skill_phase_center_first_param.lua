--[[------------------------------------------------------------------------------------------
    SkillPhaseParamMultiGridEffect : 随机播放格子特效，支持有些格子不播放
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

_class("SkillPhaseCenterFirstParam", SkillPhaseParamBase)
---@class SkillPhaseCenterFirstParam: SkillPhaseParamBase
SkillPhaseCenterFirstParam = SkillPhaseCenterFirstParam

function SkillPhaseCenterFirstParam:Constructor(t)
    self._atkAnim = t.atkAnim
    self._hitAnim = t.hitAnim
    self._atkGridCenterEffectID = t.atkGridCenterEffectID or 0
    self._atkShandowCenterEffectID = t.atkShandowCenterEffectID or 0
    self._atkGridEffectID = t.atkGridEffectID
    self._centerDelay = t.centerDelay
    self._hitEffectID = t.hitEffectID
    self._finishDelayTime = t.finishDelayTime or 0
    self._centerHitDelay = t.centerHitDelay or 0
    self._distanceDelay = t.distanceDelay or 0
    self._otherGridHitDelay = t.otherGridHitDelay or 0
    self._damageStageIndex = t.damageStageIndex or 1

    self._atkGridRandomEffect = t.atkGridRandomEffect or {}
    assert("table" == type(self._atkGridRandomEffect), "atkGridRamdomEffect必须是数组")
end

function SkillPhaseCenterFirstParam:GetCacheTable()
    local t = {}
    if self._atkGridCenterEffectID and self._atkGridCenterEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._atkGridCenterEffectID].ResPath, 1}
    end
    if self._atkShandowCenterEffectID and self._atkShandowCenterEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._atkShandowCenterEffectID].ResPath, 1}
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._hitEffectID].ResPath, 1}
    end
    if self._atkGridEffectID and self._atkGridEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._atkGridEffectID].ResPath, 1}
    end
    for _, effectID in ipairs(self._atkGridRandomEffect) do
        table.insert(t, self:GenerateCacheTableElementByID(effectID))
    end
    return t
end

function SkillPhaseCenterFirstParam:GetPhaseType()
    return SkillViewPhaseType.CenterFirst
end

function SkillPhaseCenterFirstParam:GetAtkAnimation()
    return self._atkAnim
end

function SkillPhaseCenterFirstParam:GetHitAnimation()
    return self._hitAnim
end

function SkillPhaseCenterFirstParam:GetAtkCenterEffectID()
    return self._atkGridCenterEffectID
end

function SkillPhaseCenterFirstParam:GetAtkShandowCenterEffectID()
    return self._atkShandowCenterEffectID
end

function SkillPhaseCenterFirstParam:GetAtkEffectID()
    return self._atkGridEffectID
end

function SkillPhaseCenterFirstParam:GetCenterDelay()
    return self._centerDelay
end

function SkillPhaseCenterFirstParam:GetHitEffectID()
    return self._hitEffectID
end

function SkillPhaseCenterFirstParam:GetFinishDelayTime()
    return self._finishDelayTime
end

function SkillPhaseCenterFirstParam:GetCenterHitDelay()
    return self._centerHitDelay
end

function SkillPhaseCenterFirstParam:GetDistanceDelay()
    return self._distanceDelay
end

function SkillPhaseCenterFirstParam:GetOtherGridHitDelay()
    return self._otherGridHitDelay
end

function SkillPhaseCenterFirstParam:GetRandomEffectIDs()
    return self._atkGridRandomEffect
end

function SkillPhaseCenterFirstParam:GetdDmageStageIndex()
    return self._damageStageIndex
end
