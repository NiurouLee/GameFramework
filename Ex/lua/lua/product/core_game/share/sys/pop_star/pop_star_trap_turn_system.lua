--[[------------------------------------------------------------------------------------------
    PopStarTrapTurnSystem 消灭星星模式处理机关AI
]]
--------------------------------------------------------------------------------------------

require "main_state_sys"

_class("PopStarTrapTurnSystem", MainStateSystem)
---@class PopStarTrapTurnSystem:MainStateSystem
PopStarTrapTurnSystem = PopStarTrapTurnSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarTrapTurnSystem:_GetMainStateID()
    return GameStateID.PopStarTrapTurn
end

---@param TT token 协程识别码，服务端是nil
function PopStarTrapTurnSystem:_OnMainStateEnter(TT)
    ---判断机关生命周期
    local calcStateTraps = self:_DoLogicCalcTrapState()
    ---显示机关生命周期
    self:_DoRenderTrapState(TT, calcStateTraps)

    ---计算怪物行动前机关AI
    self:_DoLogicTrapBeforeMonster()
    ---表现怪物行动前机关AI
    self:_DoRenderTrapBeforeMonster(TT)

    ---符文等逻辑计算
    self:_DoLogicTrapAfterMonster()
    ---符文等的表现
    self:_DoRenderTrapAfterMonster(TT)
    ---符文表现特效刷新
    self:_UpdateTrapGridRound(TT)

    self:_DoLogicChangeGameState()
end

-----------------------------逻辑接口------------------------------

function PopStarTrapTurnSystem:_DoLogicCalcTrapState()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    return trapServiceLogic:CalcTrapState(TrapDestroyType.DestroyByRound)
end

function PopStarTrapTurnSystem:_DoLogicChangeGameState()
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarTrapTurnFinish, 1)
end

function PopStarTrapTurnSystem:_DoLogicTrapBeforeMonster()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:StartBeforeMainAI()
end

function PopStarTrapTurnSystem:_DoLogicTrapAfterMonster()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:TrapActionAfterAI()
end

------------------------------表现接口-------------------------------------
function PopStarTrapTurnSystem:_DoRenderTrapState(TT, calcStateTraps)
end

function PopStarTrapTurnSystem:_DoRenderTrapBeforeMonster(TT)
end

function PopStarTrapTurnSystem:_DoRenderTrapAfterMonster(TT)
end

function PopStarTrapTurnSystem:_UpdateTrapGridRound(TT)
end
