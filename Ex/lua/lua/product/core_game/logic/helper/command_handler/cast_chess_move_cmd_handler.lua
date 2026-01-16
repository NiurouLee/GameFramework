require "command_base_handler"

_class("CastChessMoveCommandHandler", CommandBaseHandler)
---@class CastChessMoveCommandHandler: CommandBaseHandler
CastChessMoveCommandHandler = CastChessMoveCommandHandler

---@param cmd CastChessMoveCommand
function CastChessMoveCommandHandler:DoHandleCommand(cmd)
    Log.notice("Handle CastChessMoveCommand")

    local casterEntityID = cmd:GetCmdCasterEntityID()
    local chessPath = cmd:GetCmdChessPath()
    ---@type Entity
    local chessEntity = self._world:GetEntityByID(casterEntityID)
    if not chessEntity then
        Log.fatal("Can not find chess entity")
        return 
    end

    ---@type ChessServiceLogic
    local chessSvc = self._world:GetService("ChessLogic")
    chessSvc:FinishChessPetTurn(false,casterEntityID)

    ---TODO 校验

    ---数据存在逻辑组件中
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()

    ---设置逻辑计算需要的chesspath数据
    ---@type LogicChessPathComponent
    -- local logicChessPathComponent = chessEntity:LogicChessPath()
    local logicChessPathComponent = boardEntity:LogicChessPath()
    logicChessPathComponent:SetLogicChessPath(chessPath)
    logicChessPathComponent:SetLogicChessPetEntityID(chessEntity:GetID())

    -- ---通知表现层，划线队列更新
    -- ---@type L2RService
    -- local svc = self._world:GetService("L2R")
    -- svc:L2RChessPathData(chessEntity)

    --通知主状态机，输入结束，可以切到下个状态（棋子光灵移动）
    if self._world:RunAtServer() then 
        self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 8)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.PickUpChessPetFinish, 1)
    end
end
