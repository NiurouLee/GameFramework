--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    实现战斗结束后的退局流程
**********************************************************************************************
]]
--------------------------------------------------------------------------------------------

---@class UIBattleFinishHandler : Object
_class("UIBattleFinishHandler", Object)
UIBattleFinishHandler = UIBattleFinishHandler

---这里临时把UIBattle传进来
---@param uiBattle UIBattle
function UIBattleFinishHandler:Constructor(uiBattle)
    ---@type UIBattle
    self._uiBattle = uiBattle
    self._hasHandleBattleEnd = false
    self._autoBinder = AutoEventBinder:New(GameGlobal.EventDispatcher())

    ---来源
    self._autoBinder:BindEvent(GameEventType.BattleResultFinish, self, self.OnBattleEnd)
    self._autoBinder:BindEvent(GameEventType.ShowUIResult, self, self.ShowUIResult)
    self._autoBinder:BindEvent(GameEventType.ExitCoreGame, self, self.OnExitCoreGame)
end

function UIBattleFinishHandler:Dispose()
    self._uiBattle = nil
    self._autoBinder:UnBindAllEvents()
end

---这里有个问题，BattleResultFinish事件被主状态机和UI同时使用了，导致UI这里会进两次
---如果要分离的话，需要看下流程，应该是先逻辑层battleExit，然后发UI事件。这样影响会比较大(有很多地方使用到了这个事件)
---临时在这个函数里处理下，避免处理两次
function UIBattleFinishHandler:OnBattleEnd(victory)
    if self._hasHandleBattleEnd then
        Log.fatal("---------------repeat battle end----------------")
        return
    end
    self._hasHandleBattleEnd = true

    HelperProxy:GetInstance():SetGameTimeScale(1)
    ---@type MatchModule
    local match = GameGlobal.GetModule(MatchModule)
    ---@type MatchEnterData
    local enterData = match:GetMatchEnterData()

    self._uiBattle:HandleBattleEnd(enterData, victory)

    self.rt = self._uiBattle:GetBattleResultCompleteRT()
    Log.debug("[match] UIBattle:OnBattleEnd ", enterData._match_type)
    if MatchType.MT_Mission == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetMissionCreateInfo().mission_id
        ---@type DiscoveryData
        local discoveryData = mission:GetDiscoveryData()
        ---@type DiscoveryStory
        local story = discoveryData:GetStoryByStageIdStoryType(missionID, StoryTriggerType.AfterFight)
        local isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_AfterBattle)
        local isStage1 = Cfg.cfg_global["stage_1_id"].IntValue == missionID
        local isStage1Fail = mission:GetCurMissionID() == 0
        -- if true then
        if story and victory and ((isStage1 and isStage1Fail) or not isActive) then
            Log.debug("[match] UIBattle:OnBattleEnd ShowDialog UIStoryController", enterData._match_type)
            GameGlobal.UIStateManager():ShowDialog(
                "UIStoryController",
                story.id,
                function()
                    GameGlobal.TaskManager():CoreGameStartTask(
                        function()
                            mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_AfterBattle)
                        end
                    )

                    if isStage1 then
                        GameGlobal:GetInstance():ExitCoreGame()
                        --进局
                        GameGlobal.TaskManager():StartTask(
                            function(TT)
                                ---@type GuideModule
                                local guideModule = GameGlobal.GetModule(GuideModule)
                                guideModule:DirectEnterStage2(TT)
                            end
                        )
                    else
                        self:OnBattleEndResult(victory)
                    end
                end,
                false,
                false
            )
        else
            Log.debug("[match] UIBattle:OnBattleEnd OnBattleEndResult ", enterData._match_type)
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_ExtMission == enterData._match_type then
        local extMissionModule = GameGlobal.GetModule(ExtMissionModule)
        local extTaskID = enterData:GetMissionCreateInfo().m_nExtTaskID

        local story, isActive

        local cfg_extra_mission_story = Cfg.cfg_extra_mission_story { ExtMissionTaskID = extTaskID }[1]
        if cfg_extra_mission_story then
            for i = 1, table.count(cfg_extra_mission_story.StoryID) do
                if cfg_extra_mission_story.StoryActiveType[i] == ActiveStoryType.ActiveStoryType_AfterBattle then
                    local extMissionStory = DiscoveryStory:New()
                    extMissionStory:Init(cfg_extra_mission_story.StoryID[i], cfg_extra_mission_story.StoryActiveType[i])

                    isActive =
                        extMissionModule:IsMissionStoryActive(extTaskID, ActiveStoryType.ActiveStoryType_AfterBattle)

                    story = extMissionStory
                    break
                end
            end
        end

        if story and not isActive and victory then
            GameGlobal.UIStateManager():ShowDialog(
                "UIStoryController",
                story.id,
                function()
                    GameGlobal.TaskManager():CoreGameStartTask(
                        function()
                            extMissionModule:SetMissionStoryActive(
                                self,
                                extTaskID,
                                ActiveStoryType.ActiveStoryType_AfterBattle
                            )
                        end
                    )

                    self:OnBattleEndResult(victory)
                end
            )
        else
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_ResDungeon == enterData._match_type then
        self:OnBattleEndResult(victory)
    elseif MatchType.MT_Maze == enterData._match_type then
        --self:OnBattleEndResult(result)
        if victory then
            local mazeModule = GameGlobal.GetModule(MazeModule)

            local matchEnterData = GameGlobal.GetModule(MatchModule):GetMatchEnterData()
            local mazeCreateInfo = matchEnterData:GetMazeCreateInfo()
            if
                mazeModule:IsLastLayerRoom(
                    mazeCreateInfo.maze_version,
                    mazeCreateInfo.maze_layer,
                    mazeCreateInfo.maze_room_index
                )
            then
                Log.debug("###maze - the last mission !")
                -- GameGlobal.UIStateManager():ShowDialog("UIRugueLikeLastStageTipController")
                GameGlobal.UIStateManager():ShowDialog("UIRugueLikeBattleResultController", true)
            else
                Log.debug("###maze - not the last mission !")
                local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
                local matchResult = UI_MatchResult:New()

                matchResult = gameMatchModule:GetMachResult()

                local tempRelics = matchResult.relics
                if table.count(tempRelics) > 0 then
                    GameGlobal.UIStateManager():ShowDialog("UIRugueLikeChooseCardController")
                else
                    GameGlobal.UIStateManager():ShowDialog("UIRugueLikeBattleResultController", true)
                end
            end
        else
            GameGlobal:GetInstance():ExitCoreGame()
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Maze_Enter, "mj_01")
        end
    elseif MatchType.MT_Tower == enterData._match_type then
        self:OnBattleEndResult(victory)
    elseif MatchType.MT_TalePet == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        ---@type TalePetCreateInfo
        local info = enterData:GetTalePetMissionInfo()
        local missionID = info.nId
        local story = mission:GetStoryByStageIdStoryType(missionID, StoryTriggerType.AfterFight)
        local isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_AfterBattle)
        if story and victory and not isActive then
            Log.debug("[match] UIBattle:OnBattleEnd ShowDialog UIStoryController", enterData._match_type)
            GameGlobal.UIStateManager():ShowDialog(
                "UIStoryController",
                story,
                function()
                    GameGlobal.TaskManager():CoreGameStartTask(
                        function()
                            mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_AfterBattle)
                        end
                    )
                    self:OnBattleEndResult(victory)
                end,
                false,
                false
            )
        else
            Log.debug("[match] UIBattle:OnBattleEnd OnBattleEndResult ", enterData._match_type)
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_Campaign == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetCampaignMissionInfo().nCampaignMissionId

        local story = mission:GetStoryByStageIdStoryType(missionID, StoryTriggerType.AfterFight)
        local isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_AfterBattle)

        if story and victory and not isActive then
            Log.debug("[match] UIBattle:OnBattleEnd ShowDialog UIStoryController", enterData._match_type)
            GameGlobal.UIStateManager():ShowDialog(
                "UIStoryController",
                story,
                function()
                    GameGlobal.TaskManager():CoreGameStartTask(
                        function()
                            mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_AfterBattle)
                        end
                    )
                    self:OnBattleEndResult(victory)
                end,
                false,
                false
            )
        else
            Log.debug("[match] UIBattle:OnBattleEnd OnBattleEndResult ", enterData._match_type)
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_LostArea == enterData._match_type then
        self:OnBattleEndResult(victory)
    elseif MatchType.MT_Conquest == enterData._match_type then
        self.rt = self._uiBattle:Shot()
        local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult.m_vecAwardNormal.count <= 0 and victory then
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Exit_Core_Game, nil, nil)
        else
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_WorldBoss == enterData._match_type then
        self.rt = self._uiBattle:Shot()
        local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult.m_damage <= 0 and victory then
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Exit_Core_Game, nil, nil)
        else
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_BlackFist == enterData._match_type then
        self:OnBattleEndResult(victory)
    elseif MatchType.MT_Chess == enterData._match_type then
        self.rt = self._uiBattle:Shot()
        local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()

        self:OnBattleEndResult(victory)
    elseif MatchType.MT_DifficultyMission == enterData._match_type then
        self:OnBattleEndResult(victory)
    elseif MatchType.MT_SailingMission == enterData._match_type then
        self:OnBattleEndResult(victory)
    elseif MatchType.MT_MiniMaze == enterData._match_type then
        self.rt = self._uiBattle:Shot()
        local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult.wave <= 0 and victory then
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Exit_Core_Game, nil, nil)
        else
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_PopStar == enterData._match_type then
        self.rt = self._uiBattle:Shot()
        local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult._starNum <= 0 and victory then
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Exit_Core_Game, nil, nil)
        else
            self:OnBattleEndResult(victory)
        end
    elseif MatchType.MT_EightPets == enterData._match_type then
        Log.debug("[match] UIBattle:OnBattleEnd OnBattleEndResult ", enterData._match_type)
        self:OnBattleEndResult(victory)
    elseif MatchType.MT_Season == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetSeasonMissionInfo().mission_id

        local story = mission:GetStoryByStageIdStoryType(missionID, StoryTriggerType.AfterFight)
        local isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_AfterBattle)
        local useMissionCfg = Cfg.cfg_season_mission[missionID]
        local secondMissionId = nil --同一组两种难度关卡，剧情相同，只看一份
        if useMissionCfg then
            local secondMissionCfg = nil
            local missionGroupId = useMissionCfg.GroupID
            local missionGroupCfgs = Cfg.cfg_season_mission { GroupID = missionGroupId }
            if #missionGroupCfgs > 0 then
                for index, value in ipairs(missionGroupCfgs) do
                    if value.OrderID ~= useMissionCfg.OrderID then
                        secondMissionCfg = value
                        secondMissionId = value.ID
                        break
                    end
                end
            end
        end
        if story and victory and not isActive then
            Log.debug("[match] UIBattle:OnBattleEnd ShowDialog UIStoryController", enterData._match_type)
            GameGlobal.UIStateManager():ShowDialog(
                "UIStoryController",
                story,
                function()
                    GameGlobal.TaskManager():CoreGameStartTask(
                        function()
                            mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_AfterBattle)
                            if secondMissionId then
                                mission:SetMissionStoryActive(self, secondMissionId,
                                    ActiveStoryType.ActiveStoryType_AfterBattle)
                            end
                        end
                    )
                    self:OnBattleEndResult(victory)
                end,
                false,
                false
            )
        else
            Log.debug("[match] UIBattle:OnBattleEnd OnBattleEndResult ", enterData._match_type)
            self:OnBattleEndResult(victory)
        end
    else
        Log.exception("### MatchType not implement")
    end
end

function UIBattleFinishHandler:OnBattleEndResult(victory)
    ---@type MatchEnterData
    local matchEnterData = GameGlobal.GetModule(MatchModule):GetMatchEnterData()
    if victory then
        ---取队
        --pet数据来自petmodule
        ---@type JoinedPlayerInfo
        local localPlayerInfo = matchEnterData:GetLocalPlayerInfo()
        if localPlayerInfo and localPlayerInfo.pet_list[1] then
            local petID = localPlayerInfo.pet_list[1].pet_pstid
            if petID ~= FormationPetPlaceType.FormationPetPlaceType_None then
                Log.debug("[match] UIBattle:OnBattleEndResult ShowResultUI")
                self:ShowResultUI()
            else
                Log.error("[match] UIBattle:OnBattleEndResult error petid")
            end
        else
            self:ShowResultUI()
        end
    else
        local type = Cfg.cfg_level_failed_revive[matchEnterData._match_type]
        if type and type.ReviveDialog and type.ReviveDialog == 1 then
            Log.debug("[match] UIBattle:OnBattleEndResult ShowDialog UIBattleResultRevive")
            GameGlobal.UIStateManager():ShowDialog("UIBattleResultRevive")
        else
            Log.debug("[match] UIBattle:OnBattleEndResult Dispatch CancelReborn")
            GameGlobal.EventDispatcher():Dispatch(GameEventType.CancelReborn)
        end
    end
    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = GameGlobal.GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)
end

function UIBattleFinishHandler:ShowResultUI()
    local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
    local matchResult = gameMatchModule:GetMachResult()
    ---@type RoleAsset[]
    local normalRewards = matchResult.m_vecAwardNormal
    ---@type RoleAsset[]
    local starRewards = matchResult.m_vecAwardPerfect
    ---@type RoleAsset[]
    local fstRewards = matchResult.m_vecFirstPassAward
    local dropPets = {}
    if normalRewards then
        for i, v in ipairs(normalRewards) do
            if self:IsDropPet(v.assetid) then
                table.insert(dropPets, v)
            end
        end
    end
    if starRewards then
        for i, v in ipairs(starRewards) do
            if self:IsDropPet(v.assetid) then
                table.insert(dropPets, v)
            end
        end
    end
    if fstRewards then
        for i, v in ipairs(fstRewards) do
            if self:IsDropPet(v.assetid) then
                table.insert(dropPets, v)
            end
        end
    end
    if dropPets and table.count(dropPets) > 0 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIPetObtain",
            dropPets,
            function()
                self:ShowUIResult(true)
            end
        )
    else
        self:ShowUIResult(true)
    end
end

---@param isWin bool 胜败
function UIBattleFinishHandler:ShowUIResult(isWin)
    ---@type MissionModule
    local missionModule = GameGlobal.GetModule(MissionModule)
    if missionModule:GetCurMissionID() == 0 then
        Log.debug("[match] UIBattle:ShowUIResult OnExitCoreGame")
        self:OnExitCoreGame()
    else
        local petData = nil
        ---@type MatchEnterData
        local matchEnterData = GameGlobal.GetModule(MatchModule):GetMatchEnterData()
        ---@type JoinedPlayerInfo
        local localPlayerInfo = matchEnterData:GetLocalPlayerInfo()
        self.isWin = isWin
        GameGlobal.UIStateManager():ShowDialog(
            "UIBattleResultComplete",
            isWin,
            localPlayerInfo.pet_list,
            self.rt,
            self.autoParam
        )
        Log.debug("[match] UIBattle:ShowUIResult UIBattleResultComplete")
    end
end

function UIBattleFinishHandler:OnExitCoreGame(params)
    -- MSG9891
    -- GameGlobal.UIStateManager():ShowBusy(true)

    GameGlobal:GetInstance():ExitCoreGame()
    ---@type MatchModule
    local matchModule = GameGlobal.GetModule(MatchModule)
    if matchModule then
        local enterData = matchModule:GetMatchEnterData()
        if enterData then
            ------------------- 新手引导 关卡结束触发（回到关卡界面的时候触发） ↓---------
            local guideModule = GameGlobal.GetModule(GuideModule)
            local triggerGuide = false
            -- 失败不触发
            if not NOGUIDE and self.isWin == true then
                local levelId = enterData:GetLevelID()
                GameGlobal.EventDispatcher():Dispatch(
                    GameEventType.GuideLevelFinish,
                    levelId,
                    function(trigger)
                        triggerGuide = trigger
                    end
                )
                ------------------- 新手引导 关卡结束触发（回到关卡界面的时候触发） ↓---------
            end
            if not triggerGuide then
                local matchType = enterData:GetMatchType()
                if MatchType.MT_ExtMission == matchType then
                    local matchModule = GameGlobal.GetModule(MatchModule)
                    local enterData = matchModule:GetMatchEnterData()
                    local missionInfo = enterData:GetMissionCreateInfo()

                    local extMissionModule = GameGlobal.GetModule(ExtMissionModule)

                    local stageid

                    --- @type EnumExtMissionState
                    local extState = extMissionModule:UI_GetExtMissionState(missionInfo.m_nExtMissionID)
                    local cfg_ext_mission = Cfg.cfg_extra_mission[missionInfo.m_nExtMissionID]
                    if cfg_ext_mission then
                        local stagelist = cfg_ext_mission.ExtTaskList
                        if extState == EnumExtMissionState.Down then
                            stageid = stagelist[1]
                        else
                            for i = 1, #stagelist do
                                stageid = stagelist[i]
                                local star = extMissionModule:UI_GetExtTaskState(missionInfo.m_nExtMissionID, stageid)
                                if star <= 0 then
                                    break
                                end
                            end
                        end
                    else
                        stageid = missionInfo.m_nExtTaskID
                    end

                    Log.debug("[match] UIBattle:OnExitCoreGame SwitchState UIExtraMission")
                    GameGlobal.UIStateManager():SwitchState(
                        UIStateType.UIExtraMissionStage,
                        missionInfo.m_nExtMissionID,
                        stageid
                    )

                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_ResDungeon == matchType then
                    local module = GameGlobal.GetModule(ResDungeonModule)
                    local clientResInstance = module:GetClientResInstance()
                    local instanceId = module:GetEnterInstanceId()
                    local mainType = clientResInstance:GetMainTypeByInstanceId(instanceId)
                    Log.debug("[match] UIBattle:OnExitCoreGame SwitchState UIResDetailController")
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UIResDetailController, mainType)

                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_Maze == matchType then
                    Log.debug("[match] UIBattle:OnExitCoreGame StartLoading Maze_Enter")
                    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Maze_Enter, "mj_01")
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_Tower == matchType then
                    ---@type TowerCreateInfo
                    local towerData = enterData:GetTowerInfo()
                    local cfg = Cfg.cfg_tower_detail[towerData.nId]
                    if cfg == nil then
                        Log.fatal("尖塔关卡id错误：", towerData.nId)
                    end
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UITowerLayer, cfg.Type)
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_TalePet == matchType then
                    ---@type TalePetModule
                    local talePetModule = GameGlobal.GetModule(TalePetModule)
                    ---@type UITalePetModule
                    local uiTalePetModule = talePetModule:GetUIModule(TalePetModule)
                    ---@type TalePetCreateInfo
                    local info = enterData:GetTalePetMissionInfo()
                    uiTalePetModule:BattleExist(info.nId)
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_Campaign == matchType then
                    --判断是普通活动结算还是战术卡带结算，战术卡带结算load到风船
                    local isSwitchCard = false
                    if
                        GameGlobal.GetModule(AircraftModule):IsAircraftCartridgeMission(
                            enterData:GetCampaignMissionInfo().nMissionComId
                        )
                    then
                        isSwitchCard = true
                    end

                    if isSwitchCard then
                        Log.debug("###[UIBattle] 战术卡带退局load到风船")
                        --load到风船
                        local handler = LoadingHandlerName.Aircraft_Enter
                        --需要延迟一帧等当前loading结束
                        GameGlobal.TaskManager():StartTask(
                            function()
                                YIELD(TT)
                                if GameGlobal.UIStateManager():IsShow("UICommonLoading") then
                                    GameGlobal.UIStateManager():CloseDialog("UICommonLoading")
                                end
                                --战术室
                                GameGlobal.LoadingManager():StartLoading(
                                    handler,
                                    "fc_ui",
                                    OpenAircraftParamType.Spaceid,
                                    16,
                                    "UIAircraftTactic"
                                --其实没用，但不能为空
                                )
                            end
                        )
                    else
                        ---@type CampaignMissionCreateInfo
                        local campaignMissionInfo = enterData:GetCampaignMissionInfo()
                        ---@type CampaignModule
                        local campaignModule = GameGlobal.GetModule(CampaignModule)
                        local rt = nil
                        if params then
                            rt = params[1]
                        end
                        campaignModule:ExitBattle(campaignMissionInfo, self.isWin, rt)
                    end

                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_LostArea == matchType then
                    --迷失之地结算返回关卡界面
                    ---@type UILostLandModule
                    local uiLostLandModule = GameGlobal.GetUIModule(LostAreaModule)
                    local resetTime = uiLostLandModule:GetResetTime()
                    local svrTimerModule = GameGlobal.GetModule(SvrTimeModule)
                    local nowTime = svrTimerModule:GetServerTime() * 0.001
                    if nowTime > resetTime then
                        -- 重置
                        uiLostLandModule:SetResetData(true)
                    end
                    uiLostLandModule:SwitchState()
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_Conquest == matchType then
                    local ac = UIActivityCampaign:New()
                    ac:LoadCampaignInfo_Local(ECampaignType.CAMPAIGN_TYPE_N5)
                    if ac._id < 0 then
                        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
                    else
                        local campaignModule = GameGlobal.GetModule(CampaignModule)
                        campaignModule:CampaignSwitchState(
                            true,
                            UIStateType.UIActivityN5BattleField,
                            UIStateType.UIMain,
                            nil,
                            ac._id,
                            ECampaignN5ComponentID.ECAMPAIGN_N5_BATTLEFIELD
                        )
                    end
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_BlackFist == matchType then
                    --判断是普通活动结算还是战术卡带结算，战术卡带结算load到风船
                    local isSwitchCard = false
                    if
                        GameGlobal.GetModule(AircraftModule):IsAircraftCartridgeMission(
                            enterData:GetBlackFistInfo().component_id
                        )
                    then
                        isSwitchCard = true
                    end
                    if isSwitchCard then
                        Log.debug("###[UIBattle] 战术卡带退局load到风船")
                        --load到风船
                        local handler = LoadingHandlerName.Aircraft_Enter
                        --需要延迟一帧等当前loading结束
                        GameGlobal.TaskManager():StartTask(
                            function()
                                YIELD(TT)
                                if GameGlobal.UIStateManager():IsShow("UICommonLoading") then
                                    GameGlobal.UIStateManager():CloseDialog("UICommonLoading")
                                end
                                --战术室
                                GameGlobal.LoadingManager():StartLoading(
                                    handler,
                                    "fc_ui",
                                    OpenAircraftParamType.Spaceid,
                                    16,
                                    "UIAircraftTactic"
                                --其实没用，但不能为空
                                )
                            end
                        )
                    elseif
                        enterData:GetBlackFistInfo().component_id ==
                        ECampaignMissionComponentId.ECampaignMissionComponentId_SimulatorBlackfist
                    then
                        ---@type CampaignModule
                        local campaignModule = GameGlobal.GetModule(CampaignModule)
                        -- 获取活动 以及本窗口需要的组件
                        ---@type UIActivityCampaign
                        local camp = UIActivityCampaign:New()
                        camp:LoadCampaignInfo_Local(ECampaignType.CAMPAIGN_TYPE_N8)
                        campaignModule:CampaignSwitchState(
                            true,
                            UIStateType.UIActivityN8BattleSimulatorController,
                            UIStateType.UIMain,
                            nil,
                            camp._id,
                            ECampaignN8ComponentID.ECAMPAIGN_N8_COMBAT_SIMULATOR
                        )
                    else
                        self:BlackFistLeave()
                    end
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_WorldBoss == matchType then
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UIWorldBoss)
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_Chess == matchType then
                    self:ChessExit()
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_DifficultyMission == matchType then
                    local matchModule = GameGlobal.GetModule(MatchModule)
                    local enterData = matchModule:GetMatchEnterData()
                    ---@type DifficultyMissionCreateInfo
                    local info = enterData:GetDifficultyMissionInfo()
                    local cfg = Cfg.cfg_difficulty_parent_mission[info.parent_mission_id]
                    local isCampaign = cfg.ComponentID and cfg.ComponentID ~= 0 --配置里关联了活动组件,则视为活动困难关
                    if isCampaign then
                        --活动困难关
                        ---@type CampaignMissionCreateInfo
                        local campaignMissionInfo = CampaignMissionCreateInfo:New() --为了走活动统一的退局逻辑，这里new一个实例
                        --正常情况下这个字段对应cfg_campaign_mission,活动高难关横跨两种对局类型,退局时需要用到父节点id,这里借用nCampaignMissionId字段保存
                        campaignMissionInfo.nCampaignMissionId = info.parent_mission_id
                        campaignMissionInfo.nMissionComId =
                            EDifficultyMissionComponentId.EDifficultyMissionComponentId_Campaign
                        campaignMissionInfo.CampaignMissionParams = {
                            [ECampaignMissionParamKey.ECampaignMissionParamKey_ComCfgId] = info.campaign_component_cfg_id
                        }
                        ---@type CampaignModule
                        local campaignModule = GameGlobal.GetModule(CampaignModule)
                        local rt = nil
                        if params then
                            rt = params[1]
                        end
                        campaignModule:ExitBattle(campaignMissionInfo, self.isWin, rt) --走通用的活动退局
                    else
                        --主线困难关
                        local nodeid = info.parent_mission_id
                        local module = GameGlobal.GetModule(MissionModule)
                        local data = module:GetDiscoveryData()
                        data:UpdatePosByEnter(9, nodeid)
                        GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery)
                    end
                elseif MatchType.MT_SailingMission == matchType then
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UISailingChapter)
                elseif MatchType.MT_MiniMaze == matchType then
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UIN25VampireLevel)
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif matchType == MatchType.MT_PopStar then
                    ---@type PopStarMissionCreateInfo
                    local missionInfo = enterData._client_create_info.popstar_mission_info[1]
                    ---@type CampaignModule
                    local campaignModule = GameGlobal.GetModule(CampaignModule)
                    local campID, comID, comType = campaignModule:ParseCampaignMissionParams(missionInfo
                        .CampaignMissionParams)
                    local campConfig = Cfg.cfg_campaign[campID]
                    local campType = campConfig.CampaignType
                    local param = { campaign_type = campType }
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UISideEnterCenter, param)
                elseif matchType == MatchType.MT_EightPets then
                    ---@type EightPetsMissionCreateInfo
                    local eightPetsMissionInfo = enterData:GetEightPetsMissionInfo()
                    ---@type CampaignModule
                    local campaignModule = GameGlobal.GetModule(CampaignModule)
                    local rt = nil
                    if params then
                        rt = params[1]
                    end

                    ---@type CampaignMissionCreateInfo
                    local campaignMissionInfo = CampaignMissionCreateInfo:New()
                    campaignMissionInfo.nCampaignMissionId = eightPetsMissionInfo.mission_id
                    campaignMissionInfo.nMissionComId = eightPetsMissionInfo.component_id
                    campaignMissionInfo.CampaignMissionParams = eightPetsMissionInfo.CampaignMissionParams
                    campaignModule:ExitBattle(campaignMissionInfo, self.isWin, rt)
                    GameGlobal.UIStateManager():ShowBusy(false)
                elseif MatchType.MT_Season == matchType then
                    Log.debug("[match] UIBattle:OnExitCoreGame SwitchState UISeason")
                    local seasonModule = self:GetModule(SeasonModule)
                    seasonModule:ExitBattle(nil, false)
                else
                    Log.debug("[match] UIBattle:OnExitCoreGame SwitchState UIDiscovery")
                    local module = GameGlobal.GetModule(MissionModule)
                    local data = module:GetDiscoveryData()
                    data:UpdatePosByEnter(4)
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery)
                end
            else
                GameGlobal.UIStateManager():ShowBusy(false)
            end
        else
            Log.error("[match] UIBattle:OnExitCoreGame error enterdata")
            GameGlobal.UIStateManager():ShowBusy(false)
        end

        matchModule:ClearMatchEnterData()
    end
end

function UIBattleFinishHandler:IsDropPet(roleAssetID)
    return roleAssetID >= RoleAssetID.RoleAssetPetBegin and roleAssetID <= RoleAssetID.RoleAssetPetEnd
end

function UIBattleFinishHandler:BlackFistLeave()
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    local blackFightData = campaignModule:GetN7BlackFightData()
    local c = blackFightData:GetComponentBlackFight()
    if (not c) or (not c:ComponentIsOpen()) then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
    else
        local diff = blackFightData.curDifficulty
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIN7LevelDetailsController, blackFightData.curDifficulty)
    end
end

function UIBattleFinishHandler:ChessExit()
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type CCampaignN29
    local process = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N29)
    ---@type ChessComponent
    local component = process:GetComponent(ECampaignN29ComponentID.ECAMPAIGN_N29_CHESS)
    if component:ComponentIsOpen() then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIN29ChessController, UIStateType
            .UIActivityN29MainController)
    else
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
    end
end
