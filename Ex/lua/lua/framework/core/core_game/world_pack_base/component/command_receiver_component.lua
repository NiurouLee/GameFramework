--[[******************************************************************************************
    Entity 命令接收处理组件
    职责：
    持有命令调度分发处理的策略
--******************************************************************************************]] --

---@class IEntityCommandDispatcher:Object
_class("IEntityCommandDispatcher", Object)
IEntityCommandDispatcher = IEntityCommandDispatcher

function IEntityCommandDispatcher:BindOwner(owner)
end
function IEntityCommandDispatcher:UnBindOwner()
end
function IEntityCommandDispatcher:HandleCommand(cmd)
end
 --------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    CommandReceiverComponent
]] ---@class CommandReceiverComponent:Object
_class("CommandReceiverComponent", Object)
CommandReceiverComponent = CommandReceiverComponent

function CommandReceiverComponent:Constructor(dispatcher)
    self.ReceiveQueue = ArrayList:New()
    ---@type PlayerCommandDispatcher
    self.Dispatcher = dispatcher
end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////
---@param owner Entity
function CommandReceiverComponent:WEC_PostInitialize(owner)
    self.Dispatcher:BindOwner(owner)
end

function CommandReceiverComponent:WEC_PostRemoved()
    self.Dispatcher:UnBindOwner()
    self.Dispatcher = nil
    self.ReceiveQueue:Clear()
end

-- This:
--//////////////////////////////////////////////////////////
--分发消息处理
function CommandReceiverComponent:Dispatch()
    for i = 1, self.ReceiveQueue:Size() do
        local cmd = self.ReceiveQueue:GetAt(i)
        --print("CommandReceiverComponent:Dispatch type=", cmd.CommandType, " enttiid=",cmd.EntityID)
        self.Dispatcher:HandleCommand(cmd)
    end
    self.ReceiveQueue:Clear()
end
 --------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] ---@return CommandReceiverComponent
function Entity:CommandReceiver()
    return self:GetComponent(self.WEComponentsEnum.CommandReceiver)
end

function Entity:HasCommandReceiver()
    return self:HasComponent(self.WEComponentsEnum.CommandReceiver)
end

function Entity:AddCommandReceiver(dispatcher)
    local index = self.WEComponentsEnum.CommandReceiver
    local component = CommandReceiverComponent:New(dispatcher)
    self:AddComponent(index, component)
end

function Entity:ReceiveCommand(cmd)
    if not self:HasCommandReceiver() then
        Log.fatal("Entity:ReceiveCommand must have CommandReceiverComponent!")
        return
    end
    if cmd:GetCommandType() ~= "BattleSync" then
        if self:GetOwnerWorld() and self:GetOwnerWorld():IsDevelopEnv() then
            Log.info("[LuaCommand] recieve command ", echo_one_line(ELogLevel.Info,cmd))
        end
    end

    local index = self.WEComponentsEnum.CommandReceiver
    local component = self:CommandReceiver()
    component.ReceiveQueue:PushBack(cmd)
    self:ReplaceComponent(index, component)
end
