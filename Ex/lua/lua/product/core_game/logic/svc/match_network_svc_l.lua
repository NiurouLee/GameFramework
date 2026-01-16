---@class MatchNetworkService:INetworkService
_class("MatchNetworkService", INetworkService)

function MatchNetworkService:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type WorldRunPostion
    self._runningPosition = self._world:GetRunningPosition()
    if self._runningPosition == WorldRunPostion.AtClient then
        ---@type MatchModule
        self._matchModule = GameGlobal.GetModule(MatchModule)
        self._checkCommand = false
    else
        ---@type ServerWorld
        local serverWorld = self._world
        self._coreGameLogic = serverWorld:GetCoreGameLogic()
        self._checkCommand = true
    end
end

--客户端接收消息队列
---@param ev CMatchPushEvent
function MatchNetworkService:ReceiveMessage(ev)
    --Log.error(ev.cmd)
    --服务器需要检查命令字符串是合法的table
    if self._checkCommand and not is_table_string(ev.cmd) then
        Log.error('command is not echo table! ',ev.cmd)
        return
    end
    
    --合法的table可能无法table_to_class，需要保护执行
    local ok, cmd =
        xpcall(
        ohce,
        function()
            Log.error("command invalid! ", ev.cmd)
        end,
        ev.cmd
    )

    if ok then
        local commands = ArrayList:New()
        commands:PushBack(cmd)
        self._world:WorldHandleCommands(commands)
    end
end

function MatchNetworkService:ClientHandleCommands(commands)
    self._world:WorldHandleCommands(commands)
end

--发消息
function MatchNetworkService:SendMessage(msg)
    if self._runningPosition == WorldRunPostion.AtClient then
        self._matchModule:Push(msg)
    else
        local playerPstID = self._world.BW_WorldInfo:GetPlayerPstID()
        self._coreGameLogic:SendEvent(msg, playerPstID)
    end
end

--发送消息队列
---@param commands ArrayList
function MatchNetworkService:SendCommandsMessage(commands)
    if commands:Size() == 0 then
        return
    end

    if self._runningPosition == WorldRunPostion.AtClient then
        self:ClientHandleCommands(commands)
    end

    ---发给server
    for i = 1, commands:Size() do
        local cmd = commands:GetAt(i)
        local msg = cmd:ToNetMessage()
        self:SendMessage(msg)
    end
end
