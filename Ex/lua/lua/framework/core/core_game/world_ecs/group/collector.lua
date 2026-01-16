require "delegate_event"
require "group"
--------------------------------------------------------------------------------------------
--[[------------------------------------------------------------------------------------------
    组内entity变化的收集
]]
---@class Collector:Object
_class("Collector", Object)
Collector = Collector

function Collector:Constructor(groups, groupEvents)
    ---@type Group
    self._groups = groups
    self._groupEvents = groupEvents
    self.collectedEntities = SortedDictionary:New()

    if #groups ~= #groupEvents then
        error("groups.Length != groupEvents.Length")
    end
end

function Collector:Activate()
    --两个长度一致
    for i = 1, #self._groups do
        local group = self._groups[i]
        local groupEvent = self._groupEvents[i]
        local addEntityFunc = self.addEntity
        if groupEvent == "Added" then
            group.Ev_OnEntityAdded:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityAdded:AddEvent(self, addEntityFunc)
        elseif groupEvent == "Removed" then
            group.Ev_OnEntityRemoved:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityRemoved:AddEvent(self, addEntityFunc)
        elseif groupEvent == "AddedOrRemoved" then
            group.Ev_OnEntityAdded:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityAdded:AddEvent(self, addEntityFunc)
            group.Ev_OnEntityRemoved:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityRemoved:AddEvent(self, addEntityFunc)
        else
            error("invalid groupEvent")
        end
    end
end

function Collector:Deactivate()
    local groups = self._groups
    for i = 1, #groups do
        local group = groups[i]
        local addEntityFunc = self.addEntity
        group.Ev_OnEntityAdded:RemoveEvent(self, addEntityFunc)
        group.Ev_OnEntityRemoved:RemoveEvent(self, addEntityFunc)
    end
    self:ClearCollectedEntities()
end

function Collector:ClearCollectedEntities()
    local collectedEntities = self.collectedEntities
    for i = 1, collectedEntities:Size() do
        local entity = collectedEntities:GetAt(i)
        if entity.Release then
            entity:Release(self)
        end
    end
    self.collectedEntities:Clear()
end

---@param entity Entity
function Collector:addEntity(group, entity, index, component)
    local collectedEntities = self.collectedEntities
    local e_index = entity:GetID()
    local find_e = collectedEntities:Find(e_index)
    if find_e ~= nil then
        return
    end

    collectedEntities:Insert(e_index, entity)
    if entity.Retain then
        entity:Retain(self)
    end
end

function Collector:ToString()
end
