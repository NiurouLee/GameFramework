_class("DataTrapTriggerSkill", Object)
---@class DataTrapTriggerSkill : Object
DataTrapTriggerSkill = DataTrapTriggerSkill

function DataTrapTriggerSkill:Constructor()
    ---@type Entity
    self._trapEntity = nil
    ---@type Entity
    self._triggerEntity = nil
    ---@type SkillEffectResultContainer
    self._resultContainer = nil
end

function DataTrapTriggerSkill:SetTrapEntity(e)
    self._trapEntity = e
    return self
end

function DataTrapTriggerSkill:GetTrapEntity()
    return self._trapEntity
end

function DataTrapTriggerSkill:SetTriggerEntity(e)
    self._triggerEntity = e
    return self
end

function DataTrapTriggerSkill:GetTriggerEntity()
    return self._triggerEntity
end

function DataTrapTriggerSkill:SetResultContainer(container)
    self._resultContainer = container
    return self
end

function DataTrapTriggerSkill:GetResultContainer()
    return self._resultContainer
end
