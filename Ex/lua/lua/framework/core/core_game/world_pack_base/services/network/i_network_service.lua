--[[------------------------------------------------------------------------------------------
    NetworkService
]]--------------------------------------------------------------------------------------------
---@class INetworkService:Object
_class( "INetworkService", Object )
INetworkService = INetworkService

function INetworkService:ReceiveMessage(recMsg)
    error("Need Override INetworkService:ReceiveMessage")
end

function INetworkService:SendMessage(sendMsg)
    error("Need Override INetworkService:SendMessage")
end

---@param commands ArrayList
function INetworkService:SendCommandsMessage(commands)
    error("Need Override INetworkService:SendCommandsMessage")
end

--[[-------------------------------------------
    单机还是网络
]]--------------------------------------------- 
---@class NetworkMode
NetworkMode = {
    StandAlone = 1, ---此模式下会使用DummyServer
    Networks = 2    
}
_enum("NetworkMode", NetworkMode)
