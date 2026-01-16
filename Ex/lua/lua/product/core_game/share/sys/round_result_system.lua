--[[------------------------------------------------------------------------------------------
    RoundResultSystem：回合结算状态
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class RoundResultSystem:MainStateSystem
_class("RoundResultSystem", MainStateSystem)
RoundResultSystem = RoundResultSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function RoundResultSystem:_GetMainStateID()
    return GameStateID.RoundResult
end

---@param TT token 协程识别码，服务端是nil
function RoundResultSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    --极光时刻关闭
    self:_DoLogicCloseAuroraTime()
    self:_DoRenderCloseAuroraTime(TT)

    -- 战斗已经结束时，直接进入波次结束流程
    if self:_IsBattleEnd() then
        self._world:EventDispatcher():Dispatch(GameEventType.RoundResultFinish, 2)
        return
    end

 
    ---机关行为
    self:_DoLogicTrapRoundResult()

    ---表现
    self:_DoRenderTrapAction(TT)

    --黑拳赛模式下机关回合结算
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local traps = self:_DoLogicCalcTrapState()
        self:_DoRenderTrapState(TT, traps)
    else
        local traps = self:_DoLogicCalcTrapStateNonFightClub()
        self:_DoRenderCalcTrapStateNonFightClub(TT, traps)
    end

    self:_UpdateTrapGridRound(TT)

    ---通知逻辑回合结算
    self:_DoLogicNotifyRoundTurnEnd(teamEntity)

    ---通知表现回合结算
    self:_DoRenderNotifyRoundTurnEnd(TT, teamEntity)

    ---进入下一个回合
    self:_DoLogicUpdateBattleState(teamEntity)

    ---因复数胜利条件的表现需求，在每次进入WaitInput前增加了表现刷新触发
    self:_DoRenderRefreshCombinedWaveInfoOnRoundResult(TT)

    local battleCalcResult = self:_IsBattleEnd()
    ---表现回合结算
    self:_DoRenderShowRoundEnd(TT, battleCalcResult)

    ---波次内刷怪
    local traps, monsters = self:_DoLogicSpawnInWaveMonsters(MonsterWaveInternalTime.RoundResult)

    ---波次内刷怪表现
    self:_DoRenderInWave(TT, traps, monsters)

    self:_ClearShareSkillResult()
    ---离开回合结算状态，前后端一致
    self:_DoLogicGotoNextState(teamEntity)
end



function RoundResultSystem:_DoLogicNotifyRoundTurnEnd(teamEntity)
    local svc=self._world:GetService("Trigger")
    svc:Notify(NTRoundTurnEnd:New(teamEntity))
    svc:Notify(NTEnemyTurnEnd:New(teamEntity))
end

---更新battleStat统计信息
function RoundResultSystem:_DoLogicUpdateBattleState(teamEntity)
    ---@type BuffLogicService
    local buffService = self._world:GetService("BuffLogic")
    if buffService:DoGuideLockRoundCount(teamEntity) then
        self._world:BattleStat():MoveToNextRound(0)
    else
        if self._world:MatchType() == MatchType.MT_BlackFist then --黑拳赛模式
            if self._world:GetGameTurn() == GameTurnType.RemotePlayerTurn then
                ---敌方回合结束，切换到我方回合，并进入下一个回合
                self._world:ChangeGameTurn()
                self._world:BattleStat():MoveToNextRound()
            else
                --我方回合结束，切换到敌方回合，不进入下个回合
                self._world:ChangeGameTurn()
            end
        else --正常模式
            ---进入下一个回合
            self._world:BattleStat():MoveToNextRound()
        end
    end
    self._world:GetDataLogger():AddDataLog("OnRoundEnd")
end

---由于trap的这个结算函数未来会做逻辑表现分离，所以临时这么写
function RoundResultSystem:_DoLogicTrapRoundResult()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:TrapActionRoundResult()
end

---离开回合结算状态
function RoundResultSystem:_DoLogicGotoNextState(teamEntity)
    local mazeNoLight = false
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Maze then
        mazeNoLight = self._world:GetService("Maze"):GetLightCount() == 0
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    local leftRoundCount = battleStatCmpt:GetCurWaveRound()

    ---@type BattleService
    local battleService = self._world:GetService("Battle")

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()

    if battleService:IsWavePreEnd(teamEntity) or mazeNoLight or (leftRoundCount == 0 and levelConfigData:GetOutOfRoundType() == 0) then
        self._world:EventDispatcher():Dispatch(GameEventType.RoundResultFinish, 2)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.RoundResultFinish, 1)
    end
end

function RoundResultSystem:_DoLogicCalcTrapState()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    return trapServiceLogic:CalcTrapState(TrapDestroyType.DestroyByRound)
end

--一个黑拳赛特殊处理为啥占标准函数命名啊
function RoundResultSystem:_DoLogicCalcTrapStateNonFightClub()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    return trapServiceLogic:CalcTrapState(TrapDestroyType.DestroyAtRoundResult)
end

function RoundResultSystem:_ClearShareSkillResult()
    ---@type Entity
    local boardEntity =self._world:GetBoardEntity()
    boardEntity:ReplaceShareSkillResult()
end

--------------------------------表现接口--------------------------
function RoundResultSystem:_DoRenderShowRoundEnd(TT, battleCalcResult)
end

function RoundResultSystem:_DoRenderNotifyRoundTurnEnd(TT)
end

function RoundResultSystem:_DoRenderInWave(TT, traps, monsters)
end

function RoundResultSystem:_DoRenderTrapAction(TT)
end

function RoundResultSystem:_DoRenderTrapState(TT)
end

function RoundResultSystem:_DoRenderRefreshCombinedWaveInfoOnRoundResult(TT)
end

function RoundResultSystem:_DoRenderCalcTrapStateNonFightClub(TT, calcStateTraps)

end

function RoundResultSystem:_UpdateTrapGridRound(TT)
end