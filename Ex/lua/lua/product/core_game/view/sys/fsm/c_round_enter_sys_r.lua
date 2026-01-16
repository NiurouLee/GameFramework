--[[------------------------------------------------------------------------------------------
    RoundEnterSystem_Render：客户端实现的回合开始表现
]] --------------------------------------------------------------------------------------------

require "round_enter_system"

---@class RoundEnterSystem_Render:RoundEnterSystem
_class("RoundEnterSystem_Render", RoundEnterSystem)
RoundEnterSystem_Render = RoundEnterSystem_Render

function RoundEnterSystem_Render:_DoRenderShowPetTurnTips(TT)
    --播放边缘闪烁动画
    ---@type RenderEntityService
    local renderEntitySvc = self._world:GetService("RenderEntity")
    --renderEntitySvc:ShowBoardOutline(true)
    if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        renderEntitySvc:ShowUITurnTips(true)
    else
        renderEntitySvc:ShowUITurnTips(false)
    end
end

function RoundEnterSystem_Render:_DoRenderShowPetUI(TT, curWaveRound)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateRoundCount, curWaveRound)

    ---@type RenderBattleService
    local renderBattleService = self.world:GetService("RenderBattle")
    renderBattleService:ShowUIPetInfo(TT)

    self:_DoRenderGuidePlayer(TT)
end

function RoundEnterSystem_Render:_DoRenderPlayerTurnBuff(TT, teamEntity, formerTeamOrder)
    if teamEntity == nil then
        return
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local gsmState = utilDataSvc:GetCurMainStateID()

    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    playBuffService:RefreshLockHPView(TT, gsmState)

    playBuffService:PlayPlayerTurnBuff(TT, teamEntity, formerTeamOrder, false)

    ---@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    renderBattleService:ChangeTeamLeaderRender(TT, teamEntity)

    ---引导
    self:_DoRenderGuideBuffEnd(TT)
end

function RoundEnterSystem_Render:_DoRenderChessTurnBuff(TT)
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    --playBuffService:RefreshLockHPView(TT, gsmState)
    playBuffService:PlayChessTurnBuff(TT)
end

function RoundEnterSystem_Render:_DoRenderGuidePlayer(TT)
    -- 新手引导触发 玩家行动
    local guideService = self._world:GetService("Guide")

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")

    local guideTaskId = guideService:Trigger(GameEventType.GuideRound, GuideRoundTurn.PlayerTurn)

    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
end

function RoundEnterSystem_Render:_DoRenderUpdatePetPower(TT, tNotifyArray)
    if not tNotifyArray or (#tNotifyArray == 0) then
        return
    end
    ---@type PlayBuffService
    local playbfsvc = self._world:GetService("PlayBuff")
    for _, notify in ipairs(tNotifyArray) do
        playbfsvc:PlayBuffView(TT, notify)
    end
end

---表现玩家行动前机关AI
function RoundEnterSystem_Render:_DoRenderTrapBeforePlayer(TT)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end

    playAISvc:DoCommonRountine(TT)
end

---播放重置棋子行动状态的表现
function RoundEnterSystem_Render:_DoRenderResetChessPetFinishState(TT)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPetRender)

    for i, v in ipairs(group:GetEntities()) do
        chessSvcRender:ShowChessPetCanMoveEffect(v:GetID())
    end

    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.FinishTurnOnly)
end
---模块
function RoundEnterSystem_Render:_DoRenderFeatureOnRoundEnter(TT)
    ---@type FeatureServiceRender
    local featureSvcRender = self._world:GetService("FeatureRender")
    if featureSvcRender then
        featureSvcRender:DoFeatureOnRoundEnter(TT)
    end
end

function RoundEnterSystem_Render:_DoRenderSaveRoundBeginPlayerPos(TT, teamEntity)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTSaveRoundBeginPlayerPosEnd:New(teamEntity))
end

function RoundEnterSystem_Render:_DoRenderPunishmentRoundEnter(TT, damageInfo, isWarnRound)
    ---MSG49015：空惩罚回合预警
    if isWarnRound then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateOutOfRoundPunish)

        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideOutOfRoundPunishWarn, true)
        YIELD(TT, 2000)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideOutOfRoundPunishWarn, false)
        return
    end

    if not damageInfo then
        return
    end

    --Animation控制的特效，这么做可以不用推断特效的完成时间
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideOutOfRoundDamageWarning, false)
    YIELD(TT)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideOutOfRoundDamageWarning, true)

    --需求没有明确提出对黑拳赛的要求
    ---@type Entity
    local eTeam = self._world:Player():GetLocalTeamEntity()
    ---@type PlayDamageService
    local rsvcPlayDamage = self._world:GetService("PlayDamage")
    local taskID = rsvcPlayDamage:AsyncUpdateHPAndDisplayDamage(eTeam, damageInfo)
    while not TaskHelper:GetInstance():IsTaskFinished(taskID) do
        YIELD(TT)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateOutOfRoundPunish)
end

function RoundEnterSystem_Render:_DoRenderRefreshMonsterAntiActiveSkill(TT)
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, e:GetID())
    end
end

function RoundEnterSystem_Render:_DoRenderGuideBuffEnd(TT)
    -- 新手引导触发 回合内Buff结束
    local guideService = self._world:GetService("Guide")
    local guideTaskId = guideService:Trigger(GameEventType.GuideRound, GuideRoundTurn.BuffEnd)

    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
end
