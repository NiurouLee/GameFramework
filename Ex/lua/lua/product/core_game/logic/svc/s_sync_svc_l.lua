--[[------------------------------------------------------------------------------------------
    ServerSyncLogicService ：服务端处理同步校验相关的服务对象 
]] --------------------------------------------------------------------------------------------
require "sync_svc_l"
---@class ServerSyncLogicService:SyncLogicService
_class("ServerSyncLogicService", SyncLogicService)
ServerSyncLogicService = ServerSyncLogicService

function ServerSyncLogicService:ServerSendSyncCommand()
    ---@type BattleSyncCommand
    local cmd = BattleSyncCommand:New()
    cmd:SetCmdSyncLog(self._world:GetSyncLogger():LocalLog())
    self._world:Player():SendCommand(cmd)
end
