--[[------------------------------------------------------------------------------------------
    ChessPetMoveSystem：棋盘光灵移动
]] --------------------------------------------------------------------------------------------
require "main_state_sys"

---@class ChessPetMoveSystem:MainStateSystem
_class("ChessPetMoveSystem", MainStateSystem)
ChessPetMoveSystem = ChessPetMoveSystem

---重载函数，返回主动技状态标识码
---@return GameStateID 状态标识
function ChessPetMoveSystem:_GetMainStateID()
    return GameStateID.ChessPetMove
end

---主动技的施法流程比较长，未来应该可以合并一些阶段
---@param TT token 协程识别码，服务端是nil
function ChessPetMoveSystem:_OnMainStateEnter(TT)
    ---计算
    self:_DoLogicChessPetMove()

    ---通知表现层
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RChessPathData()

    self:_DoRenderChessPetMove(TT)

    ---主状态机切换到ChessPetResult状态
    self._world:EventDispatcher():Dispatch(GameEventType.ChessPetMoveFinish, 1)
end

function ChessPetMoveSystem:_DoLogicChessPetMove()
    ---@type ChessServiceLogic
    local chessLogic = self._world:GetService("ChessLogic")
    chessLogic:DoChessPetPathMove()
end

--------------------------------------表现接口-----------------------------------------

function ChessPetMoveSystem:_DoRenderChessPetMove(TT)
end
