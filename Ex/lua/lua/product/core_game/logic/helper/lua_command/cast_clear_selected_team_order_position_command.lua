-- _class("CastClearSelectedTeamOrderPositionCommand", IEntityCommand)

_class("CastClearSelectedTeamOrderPositionCommand", IEntityCommand)
---@class CastClearSelectedTeamOrderPositionCommand : IEntityCommand
CastClearSelectedTeamOrderPositionCommand = CastClearSelectedTeamOrderPositionCommand

CastClearSelectedTeamOrderPositionCommand.CommandType = "CastClearSelectedTeamOrderPosition"

function CastClearSelectedTeamOrderPositionCommand:Constructor()
    self._targetPos = -1
    self._casterPstID = -1
end

function CastClearSelectedTeamOrderPositionCommand:GetCommandType()
    return CastClearSelectedTeamOrderPositionCommand.CommandType
end

function CastClearSelectedTeamOrderPositionCommand:GetExecStateID()
    return 0
end

function CastClearSelectedTeamOrderPositionCommand:IsExecExcluded()
    return 0
end

function CastClearSelectedTeamOrderPositionCommand:DependRoundCount()
    return true
end

function CastClearSelectedTeamOrderPositionCommand:ToNetMessage()
    ---@type CEventCastClearSelectedTeamOrderPositionCommand
    local msg = CEventCastClearSelectedTeamOrderPositionCommand:New()
    msg.EntityID = self.EntityID
    msg.RoundCount = self.RoundCount
    msg.ClientWaitInput = self.ClientWaitInput
    msg.IsAutoFight = self.IsAutoFight
    msg.CmdIndex = self.CmdIndex

    msg.targetPos = self._targetPos
    msg.casterPstID = self._casterPstID
    return msg
end
---@param msg CEventCastClearSelectedTeamOrderPositionCommand
function CastClearSelectedTeamOrderPositionCommand:FromNetMessage(msg)
    self.EntityID = msg.EntityID
    self.RoundCount = msg.RoundCount
    self.ClientWaitInput = msg.ClientWaitInput
    self.IsAutoFight = msg.IsAutoFight
    self.CmdIndex = msg.CmdIndex

    self._targetPos = msg.targetPos
    self._casterPstID = msg.casterPstID
end

--region arguments gets
function CastClearSelectedTeamOrderPositionCommand:GetCasterPstID()
    return self._casterPstID
end

--endregion

--region helper
function CastClearSelectedTeamOrderPositionCommand.GenerateCommand(teamEntityID, casterPetPstID)
    local cmd = CastClearSelectedTeamOrderPositionCommand:New()

    --cmd.EntityID = teamEntityID
    cmd._casterPstID = casterPetPstID

    return cmd
end
--endregion
