require "command_base_handler"

_class("MirageForceCloseCommandHandler", CommandBaseHandler)
---@class MirageForceCloseCommandHandler: CommandBaseHandler
MirageForceCloseCommandHandler = MirageForceCloseCommandHandler

---@param cmd MirageForceCloseCommand
function MirageForceCloseCommandHandler:DoHandleCommand(cmd)
    Log.notice("Handle MirageForceCloseCommand")

    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    mirageSvc:SetMirageForceClose(true)

    ---@type GameFSMComponent
    local gameFsmCmpt = self._world:GameFSM()
    local gameFsmStateID = gameFsmCmpt:CurStateID()
    if gameFsmStateID == GameStateID.MirageWaitInput then
        self._world:EventDispatcher():Dispatch(GameEventType.MirageWaitInputFinish, 2)
    end
end
