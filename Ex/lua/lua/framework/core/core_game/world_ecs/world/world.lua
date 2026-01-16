--[[-------------------------------------------
    require可能有顺序依赖，修改得小心
]] ---------------------------------------------

--避免循环require；之后其他文件不能require这些
require "world_creation_context"
require "entity"
require "matcher"
require "group"
---------------------------------------------

--[[-------------------------------------------
    构造和析构
]]
_class("World", Object)
---@class World:Object
World = World

---@param contextInfo WorldCreationContext
function World:Constructor(contextInfo)
    self._contextInfo = contextInfo

    self._totalComponents = contextInfo:WCC_EntityTotalComponents()
    self._entityCreationIndex = contextInfo.WCC_StartCreationIndex
    self._entityCreationProto = contextInfo.WCC_EntityCreationProto
    self._entityIdThreshold = contextInfo.WCC_EntityIdThreshold --逻辑和渲染实体id阈值
    self._startEntityIdLogic = contextInfo.WCC_StartEntityIdLogic
    self._startEntityIdRender = contextInfo.WCC_StartEntityIdRender

    --key: creationIndex, value: entity
    self._entities = SortedDictionary:New()

    --key: Matcher, value: group
    self._groups = {}
    self._groupsForIndex = {}
    for i = 1, self._totalComponents do
        self._groupsForIndex[i] = false
    end

    self.Ev_OnEntityCreated = DelegateEvent:New()
    self.Ev_OnEntityWillBeDestroyed = DelegateEvent:New()
    self.Ev_OnEntityDestroyed = DelegateEvent:New()
    self.Ev_OnGroupCreated = DelegateEvent:New()
    self.Ev_OnGroupCleared = DelegateEvent:New()
end

function World:Dispose()
    -- 清理事件
    self.Ev_OnEntityCreated = nil
    self.Ev_OnEntityWillBeDestroyed = nil
    self.Ev_OnEntityDestroyed = nil
    self.Ev_OnGroupCreated = nil
    self.Ev_OnGroupCleared = nil
end
---------------------------------------------

--[[-------------------------------------------
    IWorld
]]
---@return Entity
function World:CreateEntity()
    local entity = self._entityCreationProto:New()
    local creationIndex = self._entityCreationIndex
    self._entityCreationIndex = creationIndex + 1
    entity:Initialize(creationIndex, self._contextInfo)
    entity:Retain(self)
    entity.Ev_OnComponentAdded:AddEvent(self, self.updateGroupsComponentAddedOrRemoved)
    entity.Ev_OnComponentRemoved:AddEvent(self, self.updateGroupsComponentAddedOrRemoved)
    entity.Ev_OnComponentReplaced:AddEvent(self, self.updateGroupsComponentReplaced)
    entity.Ev_OnEntityReleased:AddEvent(self, self.onEntityReleased)

    if self.Ev_OnEntityCreated then
        self.Ev_OnEntityCreated(self, entity)
    end
    entity:SetOwnerWorld(self)
    return entity
end

--Destroys the entity, removes all its components
---@param entity Entity
function World:DestroyEntity(entity)
    self._entities:Remove(entity:GetID()) --GetCreationIndex

    if self.Ev_OnEntityWillBeDestroyed ~= nil then
        self.Ev_OnEntityWillBeDestroyed(self, entity)
    end

    entity:Destroy()

    if self.Ev_OnEntityDestroyed ~= nil then
        self.Ev_OnEntityDestroyed(self, entity)
    end

    if entity._retainCount == 1 then
        entity.Ev_OnEntityReleased:RemoveEvent(self, self.onEntityReleased)
        entity:Release(self)
        entity:RemoveAllOnEntityReleasedHandlers()
    else
        entity:Release(self)
    end
end
---@param matcher Matcher
---@return table<number,Entity>
function World:GetGroupEntities(matcher)
    ---@type Group
    local group = self:GetGroup(matcher)
    if group then
        return group:GetEntities()
    end
end

---@param matcher Matcher
---@return Group
function World:GetGroup(matcher)
    if matcher == nil then
        Log.fatal("World:GetGroup matcher == nil")
        return nil
    end

    ---@type Group
    local group = self._groups[matcher]
    if not group then
        group = Group:New(matcher)
        --group:Constructor(matcher)
        for i = 1, self._entities:Size() do
            local e = self._entities:GetAt(i)
            group:HandleEntity(e)
        end

        self._groups[matcher] = group

        local indices = matcher.indices
        for index, _ in pairs(indices) do
            if not self._groupsForIndex[index] then
                local list = ArrayList:New()
                self._groupsForIndex[index] = list
            end
            self._groupsForIndex[index]:PushBack(group)
        end

        if self.Ev_OnGroupCreated then
            self.Ev_OnGroupCreated(self, group)
        end
    end

    return group
end

function World:updateGroupsComponentAddedOrRemoved(entity, index, component)
    local groups = self._groupsForIndex[index]
    if groups then
        --后面Cache一下？
        local events = {}
        --收集Component变化后，受影响相关Group的Event
        for i = 1, groups:Size() do
            ---@type Group
            local g = groups:GetAt(i)
            events[#events + 1] = g:HandleEntity(entity, true)
        end
        --Event通知
        for i = 1, #events do
            local groupChangedEvent = events[i]
            if groupChangedEvent then
                groupChangedEvent(groups:GetAt(i), entity, index, component)
            end
        end
    end
end

function World:updateGroupsComponentReplaced(entity, index, previousComponent, newComponent)
    local groups = self._groupsForIndex[index]
    if groups then
        for i = 1, groups:Size() do
            ---@type Group
            local g = groups:GetAt(i)
            g:UpdateEntity(entity, index, previousComponent, newComponent)
        end
    end
end

---@param entity Entity
function World:onEntityReleased(entity)
    entity.RemoveAllOnEntityReleasedHandlers()
end

---@param entity Entity
---@param entityConfigId number EntityConfigIDConst或EntityConfigIDRender
---设置实体ID。EntityConfigIDRender实体ID会在WorldCreationContext.WCC_EntityIdThreshold之后
function World:SetEntityIdByEntityConfigId(entity, entityConfigId)
    local id = 0
    if entityConfigId > EntityConfigIDConstLength then
        id = self._startEntityIdRender + self._entityIdThreshold
        self._startEntityIdRender = self._startEntityIdRender + 1
    else
        id = self._startEntityIdLogic
        self._startEntityIdLogic = self._startEntityIdLogic + 1
    end
    entity:SetID(id)
    self._entities:Insert(id, entity)
end
