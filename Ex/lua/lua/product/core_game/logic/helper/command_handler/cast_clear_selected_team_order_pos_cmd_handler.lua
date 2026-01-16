require("command_base_handler")

---@class CastClearSelectedTeamOrderPositionCommandHandler : CommandBaseHandler
_class("CastClearSelectedTeamOrderPositionCommandHandler", CommandBaseHandler)
CastClearSelectedTeamOrderPositionCommandHandler = CastClearSelectedTeamOrderPositionCommandHandler

---@param cmd CastSelectTeamOrderPositionCommand
function CastClearSelectedTeamOrderPositionCommandHandler:DoHandleCommand(cmd)
    local teamEntityID = cmd:GetEntityID()
    local casterPstID = cmd:GetCasterPstID()
    --local teamEntity = self._world:GetEntityByID(teamEntityID)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local cTeam = teamEntity:Team()
    local eCaster = cTeam:GetPetEntityByPetPstID(casterPstID)
    if not eCaster then
        Log.error("invalid pet pstid? ", tostring(casterPstID))
        return
    end

    cTeam:ClearSelectedTeamOrderPosition()
end
