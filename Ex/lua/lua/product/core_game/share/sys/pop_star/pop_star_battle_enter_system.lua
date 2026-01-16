--[[------------------------------------------------------------------------------------------
    PopStarPopStarBattleEnterSystem：消灭星星主状态机进入战场的流程
]]
--------------------------------------------------------------------------------------------

require "main_state_sys"

---@class PopStarBattleEnterSystem:MainStateSystem
_class("PopStarBattleEnterSystem", MainStateSystem)
PopStarBattleEnterSystem = PopStarBattleEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarBattleEnterSystem:_GetMainStateID()
    return GameStateID.PopStarBattleEnter
end

---@param TT token 协程识别码，服务端是nil
function PopStarBattleEnterSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---初始化BattleState组件
    self:_DoLogicInitBattleState()

    ---客户端执行表现部分
    self:_DoRenderShowBattleEnter(TT, teamEntity)

    ---客户端执行的棋盘展示函数
    local type, dir = self:_DoLogicGetPieceRefreshType()
    self:_DoRenderShowBoard(TT, type, dir)

    ---组装feature的逻辑
    self:_DoLogicAssembleFeature()

    ---组装feature的表现
    self:_DoRenderAssembleFeature(TT)

    ---切换主状态机状态
    self:_DoLogicSwitchMainFsmState()
end

---初始化BattleState
function PopStarBattleEnterSystem:_DoLogicInitBattleState()
    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type Star3CalcService
    local star3CalcSvc = self._world:GetService("Star3Calc")
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    ---@type LevelConfigData
    local levelConfigData = configSvc:GetLevelConfigData()
    local roundCount = levelConfigData:GetLevelRoundCount()
    battleStatCmpt:InitLevelRound(roundCount)
    battleStatCmpt:SetTotalWaveCount(levelConfigData:GetWaveCount())

    ---初始化三星进度
    local threeStarConditions = configSvc:GetPopStar3StarCondition(self._world.BW_WorldInfo.missionID)
    for _, conditionID in ipairs(threeStarConditions) do
        local ret = star3CalcSvc:BeZeroProgress(conditionID)
        battleStatCmpt:UpdateA3StarProgress(conditionID, ret)
    end
    battleStatCmpt._matchResult = {}
end

---格子刷新类型
function PopStarBattleEnterSystem:_DoLogicGetPieceRefreshType()
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    return affixSvc:ReplacePieceRefreshType()
end

---逻辑组装feature
function PopStarBattleEnterSystem:_DoLogicAssembleFeature()
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if featureLogicSvc then
        if featureLogicSvc:CanEnableFeature() then
            featureLogicSvc:DoInitFeatureList()
        end
    end
end

---切换主状态
function PopStarBattleEnterSystem:_DoLogicSwitchMainFsmState()
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarBattleEnterFinish, 1)
end

------------------------------------表现接口----------------------------------

---客户端的表现函数
function PopStarBattleEnterSystem:_DoRenderShowBattleEnter(TT, teamEntity)
end

---客户端重写此表现方法
function PopStarBattleEnterSystem:_DoRenderShowBoard(TT)
end

---组装feature的表现
function PopStarBattleEnterSystem:_DoRenderAssembleFeature(TT)
end
