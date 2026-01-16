--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    实现退局的流程，从UIBattle里拆分出来
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class UILeaveMatchHandler : Object
_class("UILeaveMatchHandler", Object)
UILeaveMatchHandler = UILeaveMatchHandler

---这里临时把UIBattle传进来
---@param uiBattle UIBattle
function UILeaveMatchHandler:Constructor(uiBattle)
    ---@type UIBattle
    self._uiBattle = uiBattle

    self._autoBinder = AutoEventBinder:New(GameGlobal.EventDispatcher())

    ---来源有两个 1.从设置界面的退出按钮 2.作弊被服务器踢出对局
    self._autoBinder:BindEvent(GameEventType.MatchClosed, self, self._OnMatchClosed)
    ---秘境重置
    self._autoBinder:BindEvent(GameEventType.MazeReset, self._OnMazeReset)
end

function UILeaveMatchHandler:Dispose()
    self._uiBattle = nil
    self._autoBinder:UnBindAllEvents()
end

function UILeaveMatchHandler:_OnMatchClosed()
    Log.fatal("UILeaveMatchHandler-------------------MatchClosed")

    --UI转菊花
    GameGlobal.UIStateManager():Lock("battle-quit")
    GameGlobal.UIStateManager():ShowBusy(true)
    GameGlobal:GetInstance():StopCoreGame()
    GameGlobal.TaskManager():KillCoreGameTasks()
    GameGlobal.TaskManager():StartTask(self._LeaveMatch, self)
end

---处理离开对局的协程，切换UIState
function UILeaveMatchHandler:_LeaveMatch(TT)
    local matchModule = GameGlobal.GetModule(MatchModule)
    local enterData = matchModule:GetMatchEnterData()
    local res = GameGlobal.GetModule(GameMatchModule):LeaveMatch(TT)
    if not res:GetSucc() then
        Log.fatal("离开对局失败")
        return
    end
    GameGlobal:GetInstance():ExitCoreGame()

    --停止转菊花
    GameGlobal.UIStateManager():ShowBusy(false)
    GameGlobal.UIStateManager():UnLock("battle-quit")

    local matchType = enterData:GetMatchType()
    if matchType == MatchType.MT_Mission then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery, nil, enterData:GetLevelID())
    elseif matchType == MatchType.MT_DifficultyMission then
        self:HandleLeaveMatchFor_CampDiff(TT, enterData)
    elseif matchType == MatchType.MT_ExtMission then
        self:HandleLeaveMatchFor_ExtMission(TT, enterData)
    elseif matchType == MatchType.MT_ResDungeon then
        GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Res_Exit, "UI")
    elseif matchType == MatchType.MT_Maze then
        GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Maze_Enter, "mj_01")
    elseif matchType == MatchType.MT_Tower then
        self:HandleLeaveMatchFor_Tower(TT, enterData)
    elseif matchType == MatchType.MT_TalePet then
        self:HandleLeaveMatchFor_TalePet(TT, enterData)
    elseif matchType == MatchType.MT_Campaign then
        self:HandleLeaveMatchFor_Campaign(TT, enterData)
    elseif matchType == MatchType.MT_BlackFist then
        self:HandleLeaveMatchFor_BlackFist(TT, enterData)
    elseif matchType == MatchType.MT_Chess then
        self:HandleLeaveMatchFor_Chess(TT, enterData)
    elseif matchType == MatchType.MT_SailingMission then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UISailingChapter)
    elseif matchType == MatchType.MT_PopStar then
        self:HandleLeaveMatchFor_PopStar(TT, enterData)
    elseif matchType == MatchType.MT_EightPets then
        self:HandleLeaveMatchFor_EightPets(TT, enterData)
    elseif matchType == MatchType.MT_Season then
        self:HandleLeaveMatchFor_Season(TT, enterData)
    end
    matchModule:ClearMatchEnterData()
end

---处理离开番外对局的UIState切换
---@param TT token 协程码
---@param enterData MatchEnterData 进局信息
function UILeaveMatchHandler:HandleLeaveMatchFor_ExtMission(TT, enterData)
    local missionInfo = enterData:GetMissionCreateInfo()
    if missionInfo then
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

        GameGlobal.UIStateManager():SwitchState(UIStateType.UIExtraMissionStage, missionInfo.m_nExtMissionID, stageid)
    end
end

---处理离开爬塔对局的UIState切换
---@param TT token 协程码
---@param enterData MatchEnterData 进局信息
function UILeaveMatchHandler:HandleLeaveMatchFor_Tower(TT, enterData)
    ---@type TowerCreateInfo
    local towerData = enterData:GetTowerInfo()
    local cfg = Cfg.cfg_tower_detail[towerData.nId]
    if cfg == nil then
        Log.fatal("尖塔关卡id错误：", towerData.nId)
    end
    GameGlobal.UIStateManager():SwitchState(UIStateType.UITowerLayer, cfg.Type)
end

---处理离开试炼对局的UIState切换
---@param TT token 协程码
---@param enterData MatchEnterData 进局信息
function UILeaveMatchHandler:HandleLeaveMatchFor_TalePet(TT, enterData)
    ---@type TalePetModule
    local talePetModule = GameGlobal.GetModule(TalePetModule)
    ---@type UITalePetModule
    local uiTalePetModule = talePetModule:GetUIModule(TalePetModule)
    ---@type TalePetCreateInfo
    local info = enterData:GetTalePetMissionInfo()
    uiTalePetModule:BattleExist(info.nId)
end

---处理离开活动对局的UIState切换
---@param TT token 协程码
---@param enterData MatchEnterData 进局信息
function UILeaveMatchHandler:HandleLeaveMatchFor_Campaign(TT, enterData)
    --判断是普通活动结算还是战术卡带结算，战术卡带结算load到风船
    local isSwitchCard = false
    if GameGlobal.GetModule(AircraftModule):IsAircraftCartridgeMission(enterData:GetCampaignMissionInfo().nMissionComId) then
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
        self._uiBattle:ShotBattleResult()
        local rt = nil
        if self._uiBattle._battleResultRt then
            rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
            YIELD(TT)
            UnityEngine.Graphics.Blit(self._uiBattle._battleResultRt, rt)
        end
        campaignModule:ExitBattle(campaignMissionInfo, false, rt)
    end

    GameGlobal.UIStateManager():ShowBusy(false)
end

---处理离开黑拳赛对局的UIState切换
---@param TT token 协程码
---@param enterData MatchEnterData 进局信息
function UILeaveMatchHandler:HandleLeaveMatchFor_BlackFist(TT, enterData)
    --判断是普通活动结算还是战术卡带结算，战术卡带结算load到风船
    local isSwitchCard = false
    if GameGlobal.GetModule(AircraftModule):IsAircraftCartridgeMission(enterData:GetBlackFistInfo().component_id) then
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
end

---处理离开战棋对局的UIState切换
---@param TT token 协程码
---@param enterData MatchEnterData 进局信息
function UILeaveMatchHandler:HandleLeaveMatchFor_Chess(TT, enterData)
    --判断是普通活动结算还是战术卡带结算，战术卡带结算load到风船
    local isSwitchCard = false
    if GameGlobal.GetModule(AircraftModule):IsAircraftCartridgeMission(enterData:GetChessInfo().component_id) then
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
    elseif enterData:GetChessInfo().component_id == ECampaignMissionComponentId.ECampaignMissionComponentId_ChessMission then
        ---@type CampaignModule
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        -- 获取活动 以及本窗口需要的组件
        ---@type UIActivityCampaign
        local camp = UIActivityCampaign:New()
        camp:LoadCampaignInfo_Local(ECampaignType.CAMPAIGN_TYPE_N29)
        campaignModule:CampaignSwitchState(
            true,
            UIStateType.UIN29ChessController,
            UIStateType.UIMain,
            {UIStateType.UIN29ChessController},
            camp._id,
            ECampaignN29ComponentID.ECAMPAIGN_N29_CHESS
        )
    else
        self:ChessLeave()
    end
end

function UILeaveMatchHandler:BlackFistLeave()
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

---这个目前没有实现
function UILeaveMatchHandler:ChessLeave()
    -- local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- local blackFightData = campaignModule:GetN7BlackFightData()
    -- local c = blackFightData:GetComponentBlackFight()
    -- if (not c) or (not c:ComponentIsOpen()) then
    --     self:SwitchState(UIStateType.UIMain)
    -- else
    --     local diff = blackFightData.curDifficulty
    --     self:SwitchState(UIStateType.UIN7LevelDetailsController, blackFightData.curDifficulty)
    -- end
end

function UILeaveMatchHandler:_OnMazeReset()
    Log.error("---------- maze reset and match closed --------------")
    GameGlobal.UIStateManager():ShowDialog(
        "UIRugueLikeResetMsgBoxController",
        StringTable.Get("str_maze_tips_reset"),
        function()
            self:_OnMatchClosed()
        end
    )
end

function UILeaveMatchHandler:HandleLeaveMatchFor_CampDiff(TT, enterData)
    local info = enterData:GetDifficultyMissionInfo()
    local nodeid = info.parent_mission_id
    local cfg = Cfg.cfg_difficulty_parent_mission[nodeid]
    local isCampaign = cfg.ComponentID and cfg.ComponentID ~= 0 --配置里关联了活动组件,则视为活动困难关

    if isCampaign then
        --活动困难关
        ---@type CampaignMissionCreateInfo
        local campaignMissionInfo = CampaignMissionCreateInfo:New() --为了走活动统一的退局逻辑，这里new一个实例
        --正常情况下这个字段对应cfg_campaign_mission,活动高难关横跨两种对局类型,退局时需要用到父节点id,这里借用nCampaignMissionId字段保存
        campaignMissionInfo.nCampaignMissionId = info.parent_mission_id
        campaignMissionInfo.nMissionComId = EDifficultyMissionComponentId.EDifficultyMissionComponentId_Campaign
        campaignMissionInfo.CampaignMissionParams = {
            [ECampaignMissionParamKey.ECampaignMissionParamKey_ComCfgId] = info.campaign_component_cfg_id
        }
        ---@type CampaignModule
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        local rt = nil
        campaignModule:ExitBattle(campaignMissionInfo, self.isWin, rt) --走通用的活动退局
    else
        local module = GameGlobal.GetModule(MissionModule)
        local data = module:GetDiscoveryData()
        data:UpdatePosByEnter(9, nodeid)
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery)
    end
end

function UILeaveMatchHandler:HandleLeaveMatchFor_PopStar(TT, enterData)
    ---@type PopStarMissionCreateInfo
    local missionInfo = enterData._client_create_info.popstar_mission_info[1]
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    local campID, comID, comType = campaignModule:ParseCampaignMissionParams(missionInfo.CampaignMissionParams)
    local campConfig = Cfg.cfg_campaign[campID]
    local campType = campConfig.CampaignType
    local param = { campaign_type = campType }
    GameGlobal.UIStateManager():SwitchState(UIStateType.UISideEnterCenter, param)
end

function UILeaveMatchHandler:HandleLeaveMatchFor_EightPets(TT, enterData)
    ---@type EightPetsMissionCreateInfo
    local eightPetsMissionInfo = enterData:GetEightPetsMissionInfo()
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    self._uiBattle:ShotBattleResult()
    local rt = nil
    if self._uiBattle._battleResultRt then
        rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
        YIELD(TT)
        UnityEngine.Graphics.Blit(self._uiBattle._battleResultRt, rt)
    end

    ---@type CampaignMissionCreateInfo
    local campaignMissionInfo = CampaignMissionCreateInfo:New()
    campaignMissionInfo.nCampaignMissionId = eightPetsMissionInfo.mission_id
    campaignMissionInfo.nMissionComId = eightPetsMissionInfo.component_id
    campaignMissionInfo.CampaignMissionParams = eightPetsMissionInfo.CampaignMissionParams
    campaignModule:ExitBattle(campaignMissionInfo, false, rt)

    GameGlobal.UIStateManager():ShowBusy(false)
end

---处理离开赛季对局的UIState切换
---@param TT token 协程码
---@param enterData MatchEnterData 进局信息
function UILeaveMatchHandler:HandleLeaveMatchFor_Season(TT, enterData)
    ---@type SeasonMissionCreateInfo
    local seasonMissionInfo = enterData:GetSeasonMissionInfo()
    ---@type SeasonModule
    local seasonModule = GameGlobal.GetModule(SeasonModule)
    self._uiBattle:ShotBattleResult()
    local rt = nil
    if self._uiBattle._battleResultRt then
        rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
        YIELD(TT)
        UnityEngine.Graphics.Blit(self._uiBattle._battleResultRt, rt)
    end
    seasonModule:ExitBattle(seasonMissionInfo, false, rt)

    GameGlobal.UIStateManager():ShowBusy(false)
end