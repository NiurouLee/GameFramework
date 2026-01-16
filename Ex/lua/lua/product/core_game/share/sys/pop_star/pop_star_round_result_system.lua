--[[------------------------------------------------------------------------------------------
    PopStarRoundResultSystem：消灭星星回合结算状态
]]
--------------------------------------------------------------------------------------------

require "main_state_sys"

---@class PopStarRoundResultSystem:MainStateSystem
_class("PopStarRoundResultSystem", MainStateSystem)
PopStarRoundResultSystem = PopStarRoundResultSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarRoundResultSystem:_GetMainStateID()
    return GameStateID.PopStarRoundResult
end

---@param TT token 协程识别码，服务端是nil
function PopStarRoundResultSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    -- 战斗已经结束时，直接进入波次结束流程
    if self:_IsBattleEnd() then
        self._world:EventDispatcher():Dispatch(GameEventType.PopStarRoundResultFinish, 2)
        return
    end

    ---机关行为
    self:_DoLogicTrapRoundResult()

    ---表现
    self:_DoRenderTrapAction(TT)

    ---机关回合结算
    local traps = self:_DoLogicCalcTrapState()
    self:_DoRenderTrapState(TT, traps)

    ---通知逻辑回合结算
    self:_DoLogicNotifyRoundTurnEnd(teamEntity)

    ---通知表现回合结算
    self:_DoRenderNotifyRoundTurnEnd(TT, teamEntity)

    ---进入下一个回合
    self:_DoLogicUpdateBattleState(teamEntity)

    local isBattleEnd = self:_IsBattleEnd()
    ---表现回合结算
    self:_DoRenderShowRoundEnd(TT, isBattleEnd)

    self:_ClearShareSkillResult()

    ---离开回合结算状态，前后端一致
    self:_DoLogicSwitchState(teamEntity)
end

function PopStarRoundResultSystem:_DoLogicTrapRoundResult()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:TrapActionRoundResult()
end

function PopStarRoundResultSystem:_DoLogicCalcTrapState()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    return trapServiceLogic:CalcTrapState(TrapDestroyType.DestroyAtRoundResult)
end

function PopStarRoundResultSystem:_DoLogicNotifyRoundTurnEnd(teamEntity)
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    triggerSvc:Notify(NTRoundTurnEnd:New(teamEntity))
end

---更新battleStat统计信息
function PopStarRoundResultSystem:_DoLogicUpdateBattleState(teamEntity)
    ---@type BuffLogicService
    local buffService = self._world:GetService("BuffLogic")
    if buffService:DoGuideLockRoundCount(teamEntity) then
        self._world:BattleStat():MoveToNextRound(0)
    else
        ---进入下一个回合
        self._world:BattleStat():MoveToNextRound()
    end
    self._world:GetDataLogger():AddDataLog("OnRoundEnd")
end

function PopStarRoundResultSystem:_ClearShareSkillResult()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    boardEntity:ReplaceShareSkillResult()
end

function PopStarRoundResultSystem:_DoLogicSwitchState(teamEntity)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local leftRoundCount = battleStatCmpt:GetCurWaveRound()

    ---@type BattleService
    local battleService = self._world:GetService("Battle")

    if battleService:IsWavePreEnd(teamEntity) or leftRoundCount == 0 then
        self._world:EventDispatcher():Dispatch(GameEventType.PopStarRoundResultFinish, 2)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.PopStarRoundResultFinish, 1)
    end
end

--------------------------------表现接口--------------------------

function PopStarRoundResultSystem:_DoRenderTrapAction(TT)
end

function PopStarRoundResultSystem:_DoRenderTrapState(TT, traps)
end

function PopStarRoundResultSystem:_DoRenderNotifyRoundTurnEnd(TT)
end

function PopStarRoundResultSystem:_DoRenderShowRoundEnd(TT, isBattleEnd)
end
