_class("DataTrapAppearSkill", Object)
---@class DataTrapAppearSkill : Object
DataTrapAppearSkill = DataTrapAppearSkill

function DataTrapAppearSkill:Constructor()
    ---@type Entity
    self._trapEntity = nil
    ---@type SkillEffectResultContainer
    self._resultContainer = nil
end

function DataTrapAppearSkill:SetTrapEntity(e)
    self._trapEntity = e
    return self
end

function DataTrapAppearSkill:GetTrapEntity()
    return self._trapEntity
end

function DataTrapAppearSkill:SetResultContainer(container)
    self._resultContainer = container
    return self
end

function DataTrapAppearSkill:GetResultContainer()
    return self._resultContainer
end
