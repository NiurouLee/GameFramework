--[[------------------------------------------------------------------------------------------
    SummonChessSoldier = 83, --召唤国际象棋兵
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseSummonChessSoldierParam: Object
_class("SkillPhaseSummonChessSoldierParam", SkillPhaseParamBase)
SkillPhaseSummonChessSoldierParam = SkillPhaseSummonChessSoldierParam

---@type SkillCommonParam
function SkillPhaseSummonChessSoldierParam:Constructor(t)
    ---特效ID
    self._birthEffectID = t.birthEffectID
    ---召唤多久后
    self._turnWaitTime = t.turnWaitTime
    -- --AOE间隔
    -- self._intervalTime = t.intervalTime
    -- --被击特效ID
    -- self._hitEffectID = t.hitEffectID
    -- ---被击动画
    -- self._hitAnimName = t.hitAnimName
end

function SkillPhaseSummonChessSoldierParam:GetCacheTable()
    local t = {}
    if self._birthEffectID and self._birthEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._birthEffectID].ResPath, 1})
    end
    return t
end

function SkillPhaseSummonChessSoldierParam:GetPhaseType()
    return SkillViewPhaseType.SummonChessSoldier
end

function SkillPhaseSummonChessSoldierParam:GetBirthEffectID()
    return self._birthEffectID
end

function SkillPhaseSummonChessSoldierParam:GetTurnWaitTime()
    return self._turnWaitTime
end
