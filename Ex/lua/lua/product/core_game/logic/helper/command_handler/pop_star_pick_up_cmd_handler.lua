require "command_base_handler"

---@class PopStarPickUpCommandHandler: CommandBaseHandler
_class("PopStarPickUpCommandHandler", CommandBaseHandler)
PopStarPickUpCommandHandler = PopStarPickUpCommandHandler

---@param cmd PopStarPickUpCommand
function PopStarPickUpCommandHandler:DoHandleCommand(cmd)
    Log.notice("Handle PopStarPickUpCommand")

    local gridPos = cmd:GetCmdPickUpPos()

    ---校验
    local isValid = self:CheckPickUpPosValid(gridPos)
    if not isValid then
        return
    end

    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    local connectPieces = popStarSvc:CalculatePopStarConnectPieces(gridPos)
    if connectPieces and #connectPieces == 0 then
        return
    end

    popStarSvc:SetPopConnectPieces(connectPieces)

    --切到格子刷新
    self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 1)
end

function PopStarPickUpCommandHandler:CheckPickUpPosValid(gridPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local isValid = utilDataSvc:IsValidPiecePos(gridPos)

    if not isValid then
        Log.fatal("PopStarPickUpCommand Invalid pos error, pick pos: ", Vector2.Pos2Index(gridPos))
        return false
    end

    return true
end
