--[[------------------------------------------------------------------------------------------
    ClientChessPetResultSystem_Render：客户端实现主动技状态的表现部分
]] --------------------------------------------------------------------------------------------

require "chess_pet_result_system"

---@class ClientChessPetResultSystem_Render:ChessPetResultSystem
_class("ClientChessPetResultSystem_Render", ChessPetResultSystem)
ClientChessPetResultSystem_Render = ClientChessPetResultSystem_Render

---重写结算表现函数
function ClientChessPetResultSystem_Render:_DoRenderHandleChessPetResult(TT, isAllChessPetTurnEnd, isWaveEnded)
    ---全部棋子行动结束后，隐藏UI
    if isAllChessPetTurnEnd then
        self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.HideAll)
    end
    --打开UI碰撞
    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateBlockRaycast, not isWaveEnded)
end
