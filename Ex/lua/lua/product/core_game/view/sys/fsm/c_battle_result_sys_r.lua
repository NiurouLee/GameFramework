--[[------------------------------------------------------------------------------------------
    ClientBattleResultSystem_Render：客户端实现的战斗结算表现
]] --------------------------------------------------------------------------------------------

require "battle_result_system"

---@class ClientBattleResultSystem_Render:BattleResultSystem
_class("ClientBattleResultSystem_Render", BattleResultSystem)
ClientBattleResultSystem_Render = ClientBattleResultSystem_Render

function ClientBattleResultSystem_Render:_DoLogicBattleResult()
    ---@type RenderBattleService
    local battleSvcRender = self._world:GetService("RenderBattle")
    battleSvcRender:NotifyUIBattleGameOver(self.battleMatchResult)
end

function ClientBattleResultSystem_Render:_DoRenderShowExit(TT, victory, defeatType)
    --胜利相关的buff
    local playbuff = self._world:GetService("PlayBuff")
    playbuff:PlayBuffView(TT, NTGameOver:New(victory, defeatType))

    --离开出口
    self:PlayExitLevelView(TT,victory)

    --关闭UIBattle界面点击
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnSetGraphicRaycaster, false)

    ---只有战斗胜利判断是否弹Banner
    if victory == 1 then
        ---@type InnerStoryService
        local innerStoryService = self._world:GetService("InnerStory")
        if innerStoryService:CheckStoryBanner(StoryShowType.AfterAllMonsterDeadBeginExitGame) then
            InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
        end

        ---@type GuideServiceRender
        local guideService = self._world:GetService("Guide")
        guideService:Trigger(GameEventType.GuideBattleFinish)
        guideService:YieldComplete()

        ---@type CutsceneServiceRender
        local cutsceneSvc = self._world:GetService("Cutscene")
        ---现在只有胜利时播放，如果需要失败播放，需要在param里增加播放时机
        cutsceneSvc:PlayRealTimeCutscene(TT, StoryShowType.AfterAllMonsterDeadBeginExitGame)
    end
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if victory ~= 0 and not utilData:PlayerIsDead(teamEntity) then
        --资源副本 胜利黑屏以前  需要播放胜利动画
        local enterData = GameGlobal.GetModule(MatchModule):GetMatchEnterData()
        local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
        local victoryTaskIDs = {}
        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        for _, trapEntity in ipairs(trapGroup:GetEntities()) do
            ---@type TrapRenderComponent
            local trapCmpt = trapEntity:TrapRender()
            if not trapEntity:HasDeadFlag() then
                local skillId = trapCmpt:GetVictorySkillID()
                if skillId and skillId > 0 and victory == 1 then
                    local taskId = playSkillService:PlaySkillView(trapEntity, skillId)
                    table.insert(victoryTaskIDs, taskId)
                end
            end
        end
        while TaskHelper:GetInstance():IsAllTaskFinished(victoryTaskIDs) == false do
            YIELD(TT)
        end

        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowTransitionEffect)
        YIELD(TT, 1000)
    end

    --还原在battle enter调用的SpawnPieceServiceRender:_OnClipBoard 里设置的裁切棋盘参数
    UnityEngine.Shader.DisableKeyword("_CELL_CLIP")
end

function ClientBattleResultSystem_Render:PlayExitLevelView(TT,victory)
    if victory ~= 1 then--只有胜利时播表现
        return
    end
    ---@type Entity
    local viewDataEntity = self._world:GetRenderBoardEntity()
    ---@type WaveDataComponent
    local waveDataCmpt = viewDataEntity:WaveData()

    if waveDataCmpt:IsExitWave() then
        local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
        ---@type Entity[]
        local traps = trapGroup:GetEntities()
        local eExitTrap = nil
        for _, e in ipairs(traps) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            if trapRenderCmpt and trapRenderCmpt:GetTrapID() == BattleConst.ExitTrapID then
                eExitTrap = e
                break
            end
        end
        if not eExitTrap then
            Log.fatal("### [PlayExitLevelView] no exit trap in this level")
            return
        end

        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        local waitTaskID = playSkillService:PlaySkillView(eExitTrap, BattleConst.ExitViewSkillID)

        while not TaskHelper:GetInstance():IsAllTaskFinished({waitTaskID}) do
            YIELD(TT)
        end
    end
end
