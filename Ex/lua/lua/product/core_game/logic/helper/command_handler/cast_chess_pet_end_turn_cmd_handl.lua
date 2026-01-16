require "command_base_handler"

_class("CastChessPetEndTurnCommandHandler", CommandBaseHandler)
---@class CastChessPetEndTurnCommandHandler: CommandBaseHandler
CastChessPetEndTurnCommandHandler = CastChessPetEndTurnCommandHandler

---@param cmd CastChessPetEndTurnCommand
function CastChessPetEndTurnCommandHandler:DoHandleCommand(cmd)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type ChessTurnEndType
    local turnType = cmd:GetCmdTurnType()
    ---TODO 校验

    if turnType == ChessTurnEndType.Single then
        local turnEndEntityID = cmd:GetCmdTurnEndEntityID()
        self:_HandleEndSingleChessPetTurn(turnEndEntityID)
    elseif turnType == ChessTurnEndType.All then
        self:_HandleEndAllChessPetTurn()
    end

end

---处理单个棋子结束回合
function CastChessPetEndTurnCommandHandler:_HandleEndSingleChessPetTurn(turnEndEntityID)
    ---@type Entity
    local casterPetEntity = self._world:GetEntityByID(turnEndEntityID)
    if not casterPetEntity then
        Log.fatal("Can not find chess entity")
        return 
    end

    ---@type ChessServiceLogic
    local chessSvc = self._world:GetService("ChessLogic")
    chessSvc:FinishChessPetTurn(false,turnEndEntityID)

    local isAllChessPetTurnEnd = chessSvc:IsAllChessPetTurnFinish()
    if isAllChessPetTurnEnd then 
        ---如果全部棋子结束行动，切换到chessPetResult状态
        if self._world:RunAtServer() then 
            self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish,7)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish, 2)
        end
    else
        ---如果还有棋子未行动，客户端转到waitinput状态，服务器一直处于waitinput，不用转
        if self._world:RunAtClient() then 
            self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish, 2)
        end
    end
end

---处理全部棋子结束回合
function CastChessPetEndTurnCommandHandler:_HandleEndAllChessPetTurn()
    ---@type ChessServiceLogic
    local chessSvc = self._world:GetService("ChessLogic")
    chessSvc:FinishChessPetTurn(true)

    if self._world:RunAtServer() then 
        ---服务端是从waitinput切到chessPetResult结算
        self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish,7)
    else
        ---客户端需要根据当前状态，再切到chessPetResult结算
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        if utilDataSvc:GetCurMainStateID() == GameStateID.PreviewChessPet then
            self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish,2)
        elseif utilDataSvc:GetCurMainStateID() == GameStateID.PickUpChessPet then
            self._world:EventDispatcher():Dispatch(GameEventType.PickUpChessPetFinish,4)
        elseif utilDataSvc:GetCurMainStateID() == GameStateID.WaitInput then 
            self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish,7)
        else

        end
    end

        
end