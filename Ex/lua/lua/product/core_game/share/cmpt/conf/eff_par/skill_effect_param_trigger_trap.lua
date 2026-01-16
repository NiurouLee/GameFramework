--[[------------------------------------------------------------------------------------------
    TriggerTrap = 138, -- 触发机关的触发技能
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamTriggerTrap", SkillEffectParamBase)
---@class SkillEffectParamTriggerTrap: SkillEffectParamBase
SkillEffectParamTriggerTrap = SkillEffectParamTriggerTrap

function SkillEffectParamTriggerTrap:Constructor(t)
    self._trapID = {}
    if t.trapID then
        for _, id in ipairs(t.trapID) do
            self._trapID[id] = true
        end
    end

    self._trapType = t.trapType

    self._triggerType = t.triggerType or SkillEffectTriggerTrapType.Range
end

function SkillEffectParamTriggerTrap:GetEffectType()
    return SkillEffectType.TriggerTrap
end

function SkillEffectParamTriggerTrap:GetTrapID()
    return self._trapID
end

function SkillEffectParamTriggerTrap:IsTriggerTrap(trapID, trapType)
    return self._trapID[trapID] or trapType == self._trapType
end

---@return SkillEffectTriggerTrapType
function SkillEffectParamTriggerTrap:GetTriggerType()
    return self._triggerType
end

--触发机关的类型
---@class SkillEffectTriggerTrapType
local SkillEffectTriggerTrapType = {
    Self = 1, ---自己
    Range = 2 ---范围内指定机关
}
_enum("SkillEffectTriggerTrapType", SkillEffectTriggerTrapType)
