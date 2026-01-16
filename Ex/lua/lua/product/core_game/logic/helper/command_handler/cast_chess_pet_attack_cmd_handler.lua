require "command_base_handler"

_class("CastChessPetAttackCommandHandler", CommandBaseHandler)
---@class CastChessPetAttackCommandHandler: CommandBaseHandler
CastChessPetAttackCommandHandler = CastChessPetAttackCommandHandler

---@param cmd CastChessPetAttackCommand
function CastChessPetAttackCommandHandler:DoHandleCommand(cmd)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local casterEntityID = cmd:GetCmdCasterEntityID()
    local targetEntityIDList = cmd:GetCmdTargetEntityIDList()
    local chessPath = cmd:GetCmdChessPath()
    local pickUpPos = cmd:GetCmdPickUpResult()

    ---@type Entity
    local casterPetEntity = self._world:GetEntityByID(casterEntityID)
    if not casterPetEntity then
        Log.fatal("Can not find chess entity")
        return
    end

    ---@type ChessServiceLogic
    local chessSvc = self._world:GetService("ChessLogic")
    chessSvc:FinishChessPetTurn(false, casterEntityID)

    ---TODO 校验

    ---数据存在逻辑组件中
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    local logicChessPathComponent = boardEntity:LogicChessPath()
    logicChessPathComponent:SetLogicChessPath(chessPath)
    logicChessPathComponent:SetLogicChessPetEntityID(casterPetEntity:GetID())
    logicChessPathComponent:SetLogicPickUpPos(pickUpPos)

    --通知主状态机，输入结束，可以切到下个状态（棋子光灵攻击）
    if self._world:RunAtServer() then
        self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 9)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.PickUpChessPetFinish, 3)
    end
end
