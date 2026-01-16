--[[------------------------------------------------------------------------------------------
    PopStarWaveResultSystem：消灭星星波次结算状态
]]
--------------------------------------------------------------------------------------------

require "main_state_sys"

---@class PopStarWaveResultSystem:MainStateSystem
_class("PopStarWaveResultSystem", MainStateSystem)
PopStarWaveResultSystem = PopStarWaveResultSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarWaveResultSystem:_GetMainStateID()
    return GameStateID.PopStarWaveResult
end

---@param TT token 协程识别码，服务端是nil
function PopStarWaveResultSystem:_OnMainStateEnter(TT)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    self:_DoLogicCalc3StarProgress()

    self:_DoLogicCalcBonusObjective()

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local waveNum = battleStatCmpt:GetCurWaveIndex()
    ---通知逻辑波次结算
    self:_DoLogicNotifyWaveEnd(waveNum)
    ---通知表现波次结算
    self:_DoRenderNotifyWaveEnd(TT, waveNum)

    ---机关死亡逻辑
    self:_DoLogicTrapDie()
    ---机关死亡表现
    self:_DoRenderTrapDie(TT)

    ---战斗结算
    local victory = self:_DoLogicCheckBattleResult()
    self:_DoLogicHandleTurnBattleResult(victory)
    self:_DoRenderHandleTurnBattleResult(TT, victory)

    self:_WaitTime(TT, 200)

    ---切换状态
    self:_DoLogicSwitchState()
end

function PopStarWaveResultSystem:_DoLogicCalc3StarProgress()
    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    popStarSvc:Calculate3StarProgress()
end

---结算三星奖励是否完成
function PopStarWaveResultSystem:_DoLogicCalcBonusObjective()
    ---@type BonusCalcService
    local bonusService = self._world:GetService("BonusCalc")
    bonusService:CalcBonusObjective()
end

function PopStarWaveResultSystem:_DoLogicNotifyWaveEnd(waveNum)
    self._world:GetService("Trigger"):Notify(NTWaveTurnEnd:New(waveNum))
end

----@return boolean 战斗是否胜利
function PopStarWaveResultSystem:_DoLogicCheckBattleResult()
    local victory = false

    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local popStarNumNotEnough = battleService:HandlePopStarNumber()
    if popStarNumNotEnough then
        victory = false
    else
        victory = true
    end

    return victory
end

function PopStarWaveResultSystem:_DoLogicHandleTurnBattleResult(victory)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetBattleLevelResult(victory)
end

function PopStarWaveResultSystem:_DoLogicSwitchState()
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarWaveResultFinish, 1)
end

------------------------------------表现------------------------------------

function PopStarWaveResultSystem:_DoRenderNotifyWaveEnd(TT, waveNum)
end

function PopStarWaveResultSystem:_DoRenderHandleTurnBattleResult(TT, victory)
end
