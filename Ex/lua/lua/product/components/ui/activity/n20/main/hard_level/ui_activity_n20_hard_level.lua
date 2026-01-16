---@class UIActivityN20HardLevel:UIController
_class("UIActivityN20HardLevel", UIController)
UIActivityN20HardLevel = UIActivityN20HardLevel

function UIActivityN20HardLevel:Constructor()
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityN20HardLevel:LoadDataOnEnter(TT, res, uiParams)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    --先取一次活动对象,这里获得的可能是缓存,所以下面还需要再强制刷新一遍,这里实际是为了取得活动id

    ---@type UIActivityN20Const
    self._activityConst = UIActivityN20Const:New()
    self._activityConst:LoadData(TT, res)

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = self._activityConst:GetCampaign()
    self._campaignID = self._campaign._id

    if res and res:GetSucc() then
        ---@type LineMissionComponent
        self._line_component = self._campaign:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_HARD)
        --- @type LineMissionComponentInfo
        self._line_info = self._line_component:GetComponentInfo()
        local simpleOpenTime = self._line_info.m_unlock_time
        local simpleCloseTime = self._line_info.m_close_time
        local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
        --不在开放时段内
        if now < simpleOpenTime then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
            self._campModule:ShowErrorToast(res.m_result, true)
            return
        elseif now > simpleCloseTime then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
            self._campModule:ShowErrorToast(res.m_result, true)
            return
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIActivityN20HardLevel:OnShow(uiParams)
    self._isNormalUI = uiParams[1] and true
    self._bgLoader = self:GetUIComponent("RawImageLoader", "bg1")
    self._levelType = 1 --1是普通关，2是困难关
    if self:HardLevelOpen() then
        self._levelType = 2
    end
    self._isOpen = true
    self._timerHolder = UITimerHolder:New()
    self._tips = self:GetGameObject("Tips")
    self._tips:SetActive(false)
    self._anim = self:GetUIComponent("Animation", "Anim")
    self:AttachEvents()
    self:InitWidget()
    self:FlushNodes()
    self:RefreshCountdown()
    self:RefreshSwitchBtnStatus(false)
    self:ChangeBg(self._levelType)
    self:CheckTips()
end

function UIActivityN20HardLevel:OnHide()
    self._isOpen = false
    self._timerHolder:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIActivityN20HardLevel.super:Dispose()
end

function UIActivityN20HardLevel:InitWidget()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            if self._isNormalUI then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.N20RefreshRedAndNew)
                self:CloseDialog()
            else
                self:SwitchState(UIStateType.UIActivityN20MainController)
            end
        end
        -- function()
        --     self._campModule:CampaignSwitchState(
        --         true,
        --         UIStateType.UIActivityN7MainController,
        --         UIStateType.UIMain,
        --         nil,
        --         self._campaign._id
        --     )
        -- end
    )
    ---@type UICustomWidgetPool
    self._nodesPool = self:GetUIComponent("UISelectObjectPath", "Nodes")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")

    --安全区宽度,没有找到框架的接口,直接从RectTransform上取
    self._safeAreaSize = self:GetUIComponent("RectTransform", "SafeArea").rect.size
    self._shot.width = self._safeAreaSize.x
    self._shot.height = self._safeAreaSize.y
end

function UIActivityN20HardLevel:RefreshCountdown()
    self._time = self:GetUIComponent("UILocalizationText", "time")
    local closeTime = self._line_info.m_close_time

    --普通关组件是否开放，倒计时到0后关闭
    self._isValid = true
    local timerName = "CountDown"

    local function countDown()
        local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
        local time = math.ceil(closeTime - now)
        local timeStr = self:GetFormatTimerStr(time)
        if self._timeString ~= timeStr then
            self._time:SetText(timeStr)
            self._timeString = timeStr
        end
        if time < 0 then
            self._isValid = false
            self._timerHolder:StopTimer(timerName)
        end
    end
    countDown()
    self._timerHolder:StartTimerInfinite(timerName, 1000, countDown)
end

function UIActivityN20HardLevel:GetFormatTimerStr(time, id)
    local default_id = {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107"
    }
    id = id or default_id

    local timeStr = StringTable.Get(id.over)
    if time < 0 then
        return timeStr
    end
    local day, hour, min, second = UIActivityHelper.Time2Str(time)
    if day > 0 then
        timeStr =
            "<color=#9fafee><size=34>" ..
            day ..
                "</size></color>" ..
                    StringTable.Get(id.day) ..
                        " " .. "<color=#9fafee><size=34>" .. hour .. "</size></color>" .. StringTable.Get(id.hour)
    elseif hour > 0 then
        timeStr =
            "<color=#9fafee><size=34>" ..
            hour ..
                "</size></color>" ..
                    StringTable.Get(id.hour) ..
                        " " .. "<color=#9fafee><size=34>" .. min .. "</size></color>" .. StringTable.Get(id.min)
    elseif min > 0 then
        timeStr = "<color=#9fafee><size=34>" .. min .. "</size></color>" .. StringTable.Get(id.min)
    else
        timeStr = StringTable.Get(id.zero)
    end
    return StringTable.Get("str_n20_level_remain_time_tips", timeStr)
end

function UIActivityN20HardLevel:FlushNodes()
    local cmpID = self._line_component:GetComponentCfgId()
    local missionCfgs_temp = Cfg.cfg_component_line_mission {ComponentID = cmpID}
    --所有配置,以id为索引
    local missionCfgs = {}
    for _, cfg in pairs(missionCfgs_temp) do
        if self._levelType == cfg.CustomParams[1][1] then
            missionCfgs[cfg.CampaignMissionId] = cfg
        end
    end

    local showMission = {}
    local levelCount = 0
    --所有关卡的解锁关系
    local firstMissionID = nil
    for _, cfg in pairs(missionCfgs) do
        showMission[cfg.CampaignMissionId] = cfg
        levelCount = levelCount + 1
        if cfg.NeedMissionId == 0 then
            firstMissionID = cfg.CampaignMissionId
        end
    end

    if not firstMissionID then
        firstMissionID = self:GetHeadMissionId(self._levelType)
    end

    if table.count(showMission) <= 0 then
        showMission[firstMissionID] = missionCfgs[firstMissionID]
        levelCount = 1
    end

    local missions = {}
    missions[#missions + 1] = showMission[firstMissionID]
    showMission[firstMissionID] = nil
    local preMissionId = firstMissionID
    local count = table.count(showMission)
    while count > 0 do
        for k, v in pairs(showMission) do
            if preMissionId == v.NeedMissionId or v.NeedMissionId then
                missions[#missions + 1] = v
                showMission[k] = nil
                break
            end
        end
        count = count - 1
    end
    self:StartTask(self.CreateItems, self, missions, levelCount)
end

function UIActivityN20HardLevel:CreateItems(TT, missions, levelCount)
    self:Lock("UIActivityN20HardLevel_CreateItems")
    self._nodesPool:SpawnObjects("UIActivityN20NHardLevelNode", levelCount)
    local nodes = self._nodesPool:GetAllSpawnList()
    for i = 1, #nodes do
        nodes[i]:SetVisible(false)
    end
    for i = 1, #nodes do
        ---@type UIActivityN20NHardLevelNode
        local uiNode = nodes[i]
        local mission = missions[i]
        local isOpen = false
        local hasPass = self._line_info.m_pass_mission_info[mission.CampaignMissionId] ~= nil
        if mission.NeedMissionId and mission.NeedMissionId ~= 0 then
            if self._line_info.m_pass_mission_info[mission.NeedMissionId] ~= nil then
                isOpen = true
            end
        else
            isOpen = true
        end

        uiNode:SetData(mission, isOpen, hasPass,
            function(stageId, isStory, worldPos)
                self:_onNodeClick(stageId, isStory, worldPos)
            end)
        YIELD(TT)
    end
    self:UnLock("UIActivityN20HardLevel_CreateItems")
end

function UIActivityN20HardLevel:GetHeadMissionId(levelType)
    local cmpID = self._line_component:GetComponentCfgId()
    local missionCfgs_temp = Cfg.cfg_component_line_mission {ComponentID = cmpID}
    --所有配置,以id为索引
    local missionCfgs = {}
    local otherMissionCfgs = {}
    for _, cfg in pairs(missionCfgs_temp) do
        if levelType == cfg.CustomParams[1][1] then
            missionCfgs[cfg.CampaignMissionId] = cfg
        else
            otherMissionCfgs[cfg.CampaignMissionId] = cfg
        end
    end
    
    for _, v in pairs(missionCfgs) do
        for k, _ in pairs(otherMissionCfgs) do
            if v.NeedMissionId == k then
                return v.CampaignMissionId
            end
        end
    end
end

function UIActivityN20HardLevel:_onNodeClick(stageId, isStory, worldPos)
    if isStory then
        --剧情关
        local missionCfg = Cfg.cfg_campaign_mission[stageId]
        local titleId = StringTable.Get(missionCfg.Title)
        local titleName = StringTable.Get(missionCfg.Name)
        local storyId = self._missionModule:GetStoryByStageIdStoryType(stageId, StoryTriggerType.Node)
        if not storyId then
            Log.exception("配置错误,找不到剧情,关卡id:", stageId)
            return
        end

        self:ShowDialog(
            "UIActivityPlotEnter",
            titleId,
            titleName,
            storyId,
            function()
                self:PlotEndCallback(stageId)
            end
        )
        return
    end

    self:_EnterStage(stageId, worldPos)
end

function UIActivityN20HardLevel:_EnterStage(stageId, worldPos)
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    self._shot:CleanRenderTexture()
    local rt = self._shot:RefreshBlurTexture()
    local scale = 1.3
    local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local screenPos = camera:WorldToScreenPoint(worldPos)
    local offset =
        -(Vector2(screenPos.x, screenPos.y) - Vector2(UnityEngine.Screen.width, UnityEngine.Screen.height) / 2)
    local missionCfg = Cfg.cfg_campaign_mission[stageId]
    local autoFightShow = false --self:_CheckSerialAutoFightShow(missionCfg.Type, stageId)
    -- self:ShowDialog(
    --     "UIActivityLevelStage",
    --     stageId,
    --     self._line_info.m_pass_mission_info[stageId],
    --     self._line_component,
    --     rt,
    --     offset,
    --     self._safeAreaSize.x,
    --     self._safeAreaSize.y,
    --     scale,
    --     autoFightShow,
    --     nil--行动点组件
    -- )
    self:ShowDialog(
        "UIActivityLevelStageNew",
        stageId,
        self._line_info.m_pass_mission_info[stageId],
        self._line_component,
        autoFightShow,
        nil
        --行动点组件
    )
end

function UIActivityN20HardLevel:_CheckSerialAutoFightShow(stageType, stageId)
    local autoFightShow = false
    if stageType == DiscoveryStageType.Plot then
        autoFightShow = false
    else
        local missionCfg = Cfg.cfg_campaign_mission[stageId]
        if missionCfg then
            local enableParam = missionCfg.EnableSerialAutoFight
            if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_DISABLE then
                autoFightShow = false
            elseif
                enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_ENABLE or
                    enableParam ==
                        CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_NEED_UNLOCK
             then
                autoFightShow = true
            end
        end
    end
    return autoFightShow
end

function UIActivityN20HardLevel:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

function UIActivityN20HardLevel:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        -- self:SwitchState(UIStateType.UIActivityN20HardLevel)
        return
    end

    self:StartTask(
        function(TT)
            self._line_component:SetMissionStoryActive(TT, stageId, ActiveStoryType.ActiveStoryType_BeforeBattle)

            local res = AsyncRequestRes:New()
            local award = self._line_component:HandleCompleteStoryMission(TT, res, stageId)
            if not res:GetSucc() then
                self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
            else
                if table.count(award) ~= 0 then
                    self:ShowDialog(
                        "UIGetItemController",
                        award,
                        function()
                            self:SwitchState(UIStateType.UIActivityN20HardLevel)
                        end
                    )
                else
                    self:SwitchState(UIStateType.UIActivityN20HardLevel)
                end
            end
        end,
        self
    )
end
function UIActivityN20HardLevel:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIActivityN20HardLevel:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityN20HardLevel:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end

--endregion

--region help
function UIActivityN20HardLevel:_ShowUIGetItemController(rewards)
    self:ShowDialog(
        "UIGetItemController",
        rewards,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        end
    )
end
--endregion

function UIActivityN20HardLevel:NormalLevelOnClick()
    if self._levelType == 1 then
        return
    end
    self._levelType = 1
    self:RefreshSwitchBtnStatus(true)
    self:FlushNodes()
    self:ChangeBg(self._levelType)
end

function UIActivityN20HardLevel:HardLevelOnClick()
    if self._levelType == 2 then
        return
    end
    if not self:HardLevelOpen() then
        ToastManager.ShowToast(StringTable.Get("str_n20_hard_level_unopen"))
        return
    end
    self._levelType = 2
    self:RefreshSwitchBtnStatus(true)
    self:FlushNodes()
    self:ChangeBg(self._levelType)
end

function UIActivityN20HardLevel:RefreshSwitchBtnStatus(play)
    local normalTran = self:GetUIComponent("Transform", "NormalLevel")
    local hardTran = self:GetUIComponent("Transform", "HardLevel")
    local hardSelected = self:GetGameObject("HardLevelSelected")
    local hardUnSelected = self:GetGameObject("HardLevelUnSelected")
    local hardLevelLock = self:GetGameObject("HardLevelLock")
    local normalUnSelected = self:GetGameObject("NormalLevelUnSelected")
    local normallSelected = self:GetGameObject("NormalLevelSelected")
    
    if self._levelType == 1 then
        normalUnSelected:SetActive(false)
        hardUnSelected:SetActive(true)
        if play then
            self._anim:Play("uieffanim_N20HardLevel_03")
        else
            normalTran.localScale = Vector3(1, 1, 1)
            hardTran.localScale = Vector3(0.8, 0.8, 0.8)
            normallSelected:SetActive(true)
            hardSelected:SetActive(false)
        end
    else
        normalUnSelected:SetActive(true)
        hardUnSelected:SetActive(false)
        if play then
            self._anim:Play("uieffanim_N20HardLevel_02")
        else
            normalTran.localScale = Vector3(0.8, 0.8, 0.8)
            hardTran.localScale = Vector3(1, 1, 1)
            normallSelected:SetActive(false)
            hardSelected:SetActive(true)
        end
    end
    hardLevelLock:SetActive(not self:HardLevelOpen())
end

function UIActivityN20HardLevel:HardLevelOpen()
    local cmpID = self._line_component:GetComponentCfgId()
    local missionCfgs_temp = Cfg.cfg_component_line_mission {ComponentID = cmpID}
    local missionCfgs = {}
    for _, cfg in pairs(missionCfgs_temp) do
        if 1 == cfg.CustomParams[1][1] then
            missionCfgs[cfg.CampaignMissionId] = true
        end
    end

    if next(self._line_info.m_pass_mission_info) then
        for missionID, _ in pairs(self._line_info.m_pass_mission_info) do
            if missionCfgs[missionID] then
                missionCfgs[missionID] = nil
            end
        end
    end

    if table.count(missionCfgs) > 0 then
        return false
    end

    return true
end

function UIActivityN20HardLevel:ChangeBg(levelType)
    local normal = self:GetGameObject("Normal")
    local hard = self:GetGameObject("Hard")
    if levelType == 1 then
        self._bgLoader:LoadImage("n20_kng_bg1")
        normal:SetActive(true)
        hard:SetActive(false)
    else
        self._bgLoader:LoadImage("n20_kng_bg2")
        normal:SetActive(false)
        hard:SetActive(true)
    end
end

function UIActivityN20HardLevel:BtnCloseOnClick()
    self._anim:Play("uieffanim_N20HardLevel_Tips_out")
end

function UIActivityN20HardLevel:CheckTips()
    if self:IsShowHardLevelTips() == false then
        return
    end
    self._tips:SetActive(true)
    self._anim:Play("uieffanim_N20HardLevel_Tips_in")
    UnityEngine.PlayerPrefs.SetInt(self:GetPlayerPrefsKey(), 1)
end

function UIActivityN20HardLevel:GetPlayerPrefsKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "ACTIVITY_N20_HARD_LEVEL_SHOW_TIPS_FLAG"
    return key
end

function UIActivityN20HardLevel:IsShowHardLevelTips()
    if not self:HardLevelOpen() then
        return false
    end
    local key = self:GetPlayerPrefsKey()
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end
