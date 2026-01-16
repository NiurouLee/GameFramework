--[[------------------------------------------------------------------------------------------
    Transposition = 94, --互换位置
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseTranspositionParam: SkillPhaseParamBase
_class("SkillPhaseTranspositionParam", SkillPhaseParamBase)
SkillPhaseTranspositionParam = SkillPhaseTranspositionParam
---
---@type SkillCommonParam
function SkillPhaseTranspositionParam:Constructor(t)
    self._anim1 = t.anim1
    self._anim2 = t.anim2

    self._materialAnim1 = t.materialAnim1
    self._materialAnim2 = t.materialAnim2

    self._mainEffectID1 = t.mainEffectID1
    self._mainEffectID2 = t.mainEffectID2

    self._flyEffectID = t.flyEffectID

    self._delayFlyTime = t.delayFlyTime
    self._oneGridFlyTime = t.oneGridFlyTime
    self._finishTime = t.finishTime

    ---是否使用SuperEntity，默认不用 [KZY:SkillHolder去Self]
    self._useSuper = t.useSuper or false
end
---
function SkillPhaseTranspositionParam:GetPhaseType()
    return SkillViewPhaseType.Transposition
end

function SkillPhaseTranspositionParam:GetFlyEffectID()
    return self._flyEffectID
end
function SkillPhaseTranspositionParam:GetMainEffectID1()
    return self._mainEffectID1
end
function SkillPhaseTranspositionParam:GetMainEffectID2()
    return self._mainEffectID2
end
function SkillPhaseTranspositionParam:GetAnim1()
    return self._anim1
end
function SkillPhaseTranspositionParam:GetAnim2()
    return self._anim2
end
function SkillPhaseTranspositionParam:GetMaterialAnim1()
    return self._materialAnim1
end
function SkillPhaseTranspositionParam:GetMaterialAnim2()
    return self._materialAnim2
end
function SkillPhaseTranspositionParam:GetDelayFlyTime()
    return self._delayFlyTime
end
function SkillPhaseTranspositionParam:GetOneGridFlyTime()
    return self._oneGridFlyTime
end
function SkillPhaseTranspositionParam:GetFinishTime()
    return self._finishTime
end

function SkillPhaseTranspositionParam:IsUseSuper()
    return self._useSuper
end

function SkillPhaseTranspositionParam:GetCacheTable()
    local t = {}

    if self._mainEffectID1 and self._mainEffectID1 > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._mainEffectID1].ResPath, 2}
    end
    if self._mainEffectID2 and self._mainEffectID2 > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._mainEffectID2].ResPath, 2}
    end
    if self._flyEffectID and self._flyEffectID > 0 then
        t[#t + 1] = {Cfg.cfg_effect[self._flyEffectID].ResPath, 2}
    end
    return t
end
