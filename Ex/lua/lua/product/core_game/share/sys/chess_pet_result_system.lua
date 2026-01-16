--[[------------------------------------------------------------------------------------------
    ChessPetResultSystem：棋子光灵行动结算
]] --------------------------------------------------------------------------------------------
require "main_state_sys"

---@class ChessPetResultSystem:MainStateSystem
_class("ChessPetResultSystem", MainStateSystem)
ChessPetResultSystem = ChessPetResultSystem

---重载函数，返回主动技状态标识码
---@return GameStateID 状态标识
function ChessPetResultSystem:_GetMainStateID()
    return GameStateID.ChessPetResult
end

---主动技的施法流程比较长，未来应该可以合并一些阶段
---@param TT token 协程识别码，服务端是nil
function ChessPetResultSystem:_OnMainStateEnter(TT)
    --怪物死亡
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)

    --棋子死亡
    self:_DoLogicChessPetDead()
    self:_DoRenderChessPetDead(TT)

    ---@type ChessServiceLogic
    local chessSvc = self._world:GetService("ChessLogic")
    local isAllChessPetTurnEnd = chessSvc:IsAllChessPetTurnFinish()

    local isWaveEnded = self:IsBattleEnded() -- self:_IsBattleEnd()会设置逻辑数值！！！
    self:_DoRenderHandleChessPetResult(TT, isAllChessPetTurnEnd, isWaveEnded)

    ---检查战斗是否结束，切到结算
    if self:_IsBattleEnd() then
        self._world:EventDispatcher():Dispatch(GameEventType.ChessPetResultFinish, 3)
    else
        ---玩家还可以操作的话，切换到WaitInput状态，否则切到MonsterTurn状态
        if isAllChessPetTurnEnd then
            self._world:EventDispatcher():Dispatch(GameEventType.ChessPetResultFinish, 2)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.ChessPetResultFinish, 1)
        end
    end

end

-----------------------------------------------------------

---处理表现
function ChessPetResultSystem:_DoRenderHandleChessPetResult(TT, isAllChessPetTurnEnd, isWaveEnded)
end
