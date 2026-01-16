--[[------------------------------------------------------------------------------------------
    测试游戏世界
]]--------------------------------------------------------------------------------------------
require "base_world"

---@class TestWorld:BaseWorld
_class( "TestWorld", BaseWorld )

-- As This:
--//////////////////////////////////////////////////////////

-- 业务初始化 CreateSystems
function TestWorld:Internal_CreateSystems()
    local systems = Systems:New()
    self.BW_Systems = systems

    systems:Add(InitializeWorldSystem:New(self))
    systems:Add(UnityInputSystem:New(self))
    systems:Add(CommandSendSystem:New(self))
    systems:Add(CommandReceiveSystem:New(self))
    systems:Add(MovementSystem:New(self))
    systems:Add(SpawnSystem:New(self))
    systems:Add(MainFSMSystem:New(self))
end

--UniqueComponents 初始化
function TestWorld:Internal_CreateComponents()
    self:AddSpawnMng(
        FixedPointsSpawnMng:New({
            [1] = Vector3(-1,0,-4), 
            [2] = Vector3(1,0,-4), 
            [3] = Vector3(0,0,-4),
        })
    )
end

-- 服务初始化 CollectServices
function TestWorld:Internal_CreateServices()
    self.BW_Services = {
        Resource = UnityResourceService:New(),
        Network = DummyNetworkService:New(self)
    }
end

---@return Entity
function TestWorld:GetEntityByID(entityID)
    --待处理 这里暂定ID == creationIndex
    return self._entities:Find(entityID)
end

---@param cmds ArrayList
function TestWorld:WorldHandleCommands(command_list)
    for i = 1, command_list:Size() do
        local cmd = command_list:GetAt(i)
        local e = self:GetEntityByID(cmd.EntityID)
        e:ReceiveCommand(cmd)
    end
end



