--[[------------------------------------------------------------------------------------------
    ChessPetAttackSystem：棋子光灵攻击
]] --------------------------------------------------------------------------------------------
require "main_state_sys"

---@class ChessPetAttackSystem:MainStateSystem
_class("ChessPetAttackSystem", MainStateSystem)
ChessPetAttackSystem = ChessPetAttackSystem

---重载函数，返回主动技状态标识码
---@return GameStateID 状态标识
function ChessPetAttackSystem:_GetMainStateID()
    return GameStateID.ChessPetAttack
end

---主动技的施法流程比较长，未来应该可以合并一些阶段
---@param TT token 协程识别码，服务端是nil
function ChessPetAttackSystem:_OnMainStateEnter(TT)

    ---主状态机切换到ChessPetResult状态
    self._world:EventDispatcher():Dispatch(GameEventType.ChessPetAttackFinish, 1)
end
