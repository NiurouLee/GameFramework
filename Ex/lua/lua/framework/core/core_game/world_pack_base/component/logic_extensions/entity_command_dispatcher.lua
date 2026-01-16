
--[[******************************************************************************************
    CommandReceiver Dispatcher Extensions

    职责：定制Entity收到命令后的分发策略，项目可以按需特化

--******************************************************************************************]]--


--[[------------------------------------------------------------------------------------------
    分发器示例： 组件按接口处理Command
]]--------------------------------------------------------------------------------------------

---@class EntityCommandSimpleDispatcher:IEntityCommandDispatcher
_class( "EntityCommandSimpleDispatcher", IEntityCommandDispatcher )
EntityCommandSimpleDispatcher = EntityCommandSimpleDispatcher


function EntityCommandSimpleDispatcher:Constructor()
    self.OnHandleCommand = DelegateEvent:New()
    self.owner = nil
end


function EntityCommandSimpleDispatcher:HandleCommand(cmd)
    --Log.debug("EntityCommandSimpleDispatcher:HandleCommand")
    self.OnHandleCommand(cmd)
end


---@param owner Entity
function EntityCommandSimpleDispatcher:BindOwner(owner)
    --假设组件拥有消息处理的
    self.owner = owner
    for i=1, owner._components:Size() do
        local cmpt = owner._components:GetAt(i)
        if cmpt.HandleCommand then
            self.OnHandleCommand:AddEvent(cmpt, cmpt.HandleCommand)
        end
    end
    owner.Ev_OnComponentAdded:AddEvent(self, self._onComponentAdded)
    owner.Ev_OnComponentRemoved:AddEvent(self, self._onComponentRemoved)
    owner.Ev_OnComponentReplaced:AddEvent(self, self._onComponentReplaced)
end


function EntityCommandSimpleDispatcher:UnBindOwner()
    local owner = self.owner
    owner.Ev_OnComponentAdded:RemoveEvent(self, self._onComponentAdded)
    owner.Ev_OnComponentRemoved:RemoveEvent(self, self._onComponentRemoved)
    owner.Ev_OnComponentReplaced:RemoveEvent(self, self._onComponentReplaced)
    self.owner = nil
    self.OnHandleCommand:Clear()
end


function EntityCommandSimpleDispatcher:_onComponentAdded(entity, index, component)
    if component.HandleCommand then
        self.OnHandleCommand:AddEvent(component, component.HandleCommand)
    end
end


function EntityCommandSimpleDispatcher:_onComponentRemoved(entity, index, component)
    if component.HandleCommand then
        self.OnHandleCommand:RemoveEvent(component, component.HandleCommand)
    end
end

function EntityCommandSimpleDispatcher:_onComponentReplaced(entity, index, previousComponent, newComponent)
    if previousComponent ~= newComponent then
        if previousComponent.HandleCommand then
            self.OnHandleCommand:RemoveEvent(previousComponent, previousComponent.HandleCommand)
        end

        if newComponent.HandleCommand then
            self.OnHandleCommand:AddEvent(newComponent, newComponent.HandleCommand)
        end
    end
end
