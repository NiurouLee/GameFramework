--[[------------------------------------------------------------------------------------------
   BattleSyncCommand 战斗同步命令，服务器下发给客户端用
]] --------------------------------------------------------------------------------------------
require "entity_commands"

---@class BattleSyncCommand:IEntityCommand
_class("BattleSyncCommand", IEntityCommand)
BattleSyncCommand = BattleSyncCommand

function BattleSyncCommand:Constructor()
    self._commandType = "BattleSync"
    self._syncLog = nil
end

function BattleSyncCommand:GetCommandType()
    return self._commandType
end

function BattleSyncCommand:GetExecStateID()
    return 0
end

function BattleSyncCommand:IsExecExcluded()
    return 0
end

function BattleSyncCommand:DependRoundCount()
    return false
end


function BattleSyncCommand:GetCmdSyncLog()
    return self._syncLog
end

function BattleSyncCommand:SetCmdSyncLog(data)
    self._syncLog = data
end

function BattleSyncCommand:ToNetMessage()
    ---@type CEventLuaCommand
    local msg = CEventLuaCommand:New()
    msg.cmd = echo(self)
    return msg
end

function BattleSyncCommand:FromNetMessage(msg)
    ---@type BattleSyncCommand
    local cmd = ohce(msg.cmd)
    self._syncLog = cmd:GetCmdSyncLog()
end