---@class UIN34DispatchMain:UIController
_class("UIN34DispatchMain", UIController)
UIN34DispatchMain = UIN34DispatchMain

function UIN34DispatchMain:Constructor()
    self._cdStatus = {tick = 0, period = 30000}
    self._cdReward = {tick = 0, period = math.maxinteger}
    self._cdHideLog = {tick = 0, period = math.maxinteger}
end

function UIN34DispatchMain:LoadDataOnEnter(TT, res, uiParams)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign.New()
    self._campaign:LoadCampaignInfo(
            TT,
            res,
            ECampaignType.CAMPAIGN_TYPE_N34,
            ECampaignN34ComponentID.ECAMPAIGN_N34_DISPATCH)

    ---@type CCampaignN34
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --获取组件
    ---@type DispatchComponent
    self._dispatchComponent = self._localProcess:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_DISPATCH)

    self._localDb = UIN34DispatchLocalDb:New()
    self._localDb:ViewedLoadDB()

    self._atlasDispatch = self:GetAsset("UIN34Dispatch.spriteatlas", LoadType.SpriteAtlas)
end

function UIN34DispatchMain:OnShow(uiParams)
    self:AddEvents()
    self:UIWidget()
    self:InitCommonTopButton()
    self:CreateMission()
    self:EnterFullScreenBg(false)
    self:ShowDispatchLog(false, nil)

    self:FlushMission()
    self:FlushSelection()
    self:BreakPosition()
    self:FlushQPlayer()
    self:FlushDispatch()
end

function UIN34DispatchMain:OnHide()

end

function UIN34DispatchMain:OnUpdate(deltaTimeMS)
    self._cdStatus.tick = self._cdStatus.tick + deltaTimeMS
    if self._cdStatus.tick >= self._cdStatus.period then
        self._cdStatus.tick = 0
        self:FlushDispatch()
    end

    self._cdReward.tick = self._cdReward.tick + deltaTimeMS
    if self._cdReward.tick >= self._cdReward.period then
        self._cdReward.tick = 0
        self._cdReward.period = math.maxinteger

        local lockName = "UIN34DispatchMain:GetRewardsTask"
        self:StartSafeTask(lockName, self.GetRewardsTask, self, self._requestLock)
    end

    self._cdHideLog.tick = self._cdHideLog.tick + deltaTimeMS
    if self._cdHideLog.tick >= self._cdHideLog.period then
        self._cdHideLog.tick = 0
        self._cdHideLog.period = math.maxinteger
        self:ShowDispatchLog(false, nil)
    end
end

function UIN34DispatchMain:OnActivityCloseEvent(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN34DispatchMain:EnterFullScreenBg(isEnter)
    self._uiWidget.gameObject:SetActive(not isEnter)
    self._btnAnywhere.gameObject:SetActive(isEnter)
end

function UIN34DispatchMain:BtnAnywhereOnClick(go)
    self:EnterFullScreenBg(false)
end

function UIN34DispatchMain:BtnPlotReviewOnClick(go)
    local storyId = self._dispatchComponent:GetComponentInfo().m_first_story_id
    self:ShowDialog("UIStoryController", storyId, function()
    end)
end

function UIN34DispatchMain:BtnCommunicationOnClick(go)
    if not self:InActivityTime() then
        self._campaign:CheckErrorCode(CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED, nil, nil)
        return
    end

    self:ShowDialog("UIN34DispatchTerminalMainControlller")
end

function UIN34DispatchMain:BtnDispatchOnClick(go)
    if not self._currentNode.selected then
        ToastManager.ShowToast(StringTable.Get("str_n34_dispatch_need_selected_tips"))
        return
    end

    local lockName = "UIN34DispatchMain:DispatchTask"
    self:StartSafeTask(lockName, self.DispatchTask, self)
end

function UIN34DispatchMain:NodeOnClick(nodeWidget)
    if self._currentNode.nodeWidget ~= nodeWidget then
        local archId = nodeWidget:ID()
        local clickNode = self._dicMissions[archId]
        if clickNode.archInfo == nil then
            ToastManager.ShowToast(StringTable.Get("str_n34_dispatch_selected_locked_tips"))
        else
            ToastManager.ShowToast(StringTable.Get("str_n34_dispatch_selected_completed_tips"))
        end

        return
    end

    if self._currentNode.archInfo ~= nil then
        if self._currentNode.archInfo.status == ComDispatchStatus.DISPATCHING then
            ToastManager.ShowToast(StringTable.Get("str_n34_dispatch_selected_progress_tips"))
        elseif self._currentNode.archInfo.status == ComDispatchStatus.COMPLETE then
            ToastManager.ShowToast(StringTable.Get("str_n34_dispatch_selected_completed_tips"))
        end
    else
        for k, v in pairs(self._dicMissions) do
            if v.nodeWidget == nodeWidget then
                v.selected = not v.selected
            else
                v.selected = false
            end
        end

        self:FlushSelection()
    end
end

function UIN34DispatchMain:StartRewardTimer()
    local endTime = self._currentNode.archInfo.end_time
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = svrTimeModule:GetServerTime()

    self._cdReward.tick = 0
    self._cdReward.period = endTime * 1000 - curTime
    self._cdReward.period = self._cdReward.period + 1000
end

function UIN34DispatchMain:StartHideLogTimer(period)
    self._cdHideLog.tick = 0
    self._cdHideLog.period = period
end

function UIN34DispatchMain:InActivityTime()
    local endTime = self._dispatchComponent:GetComponentInfo().m_close_time
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    return endTime >= curTime
end

function UIN34DispatchMain:AddEvents()
    -- self:DetachAllEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)
end

function UIN34DispatchMain:UIWidget()
    self._uiWidget = self:GetUIComponent("RectTransform", "uiWidget")
    self._btnAnywhere = self:GetUIComponent("RectTransform", "btnAnywhere")
    ---@type UICustomWidgetPool
    self._ltBtn = self:GetUIComponent("UISelectObjectPath", "ltBtn")
    self._lineContent = self:GetUIComponent("UISelectObjectPath", "lineContent")
    self._nodeContent = self:GetUIComponent("UISelectObjectPath", "nodeContent")
    self._selectedFrame = self:GetUIComponent("RectTransform", "selectedFrame")
    self._rootPlayer = self:GetUIComponent("RectTransform", "rootPlayer")
    self._dispatchStatusText = self:GetUIComponent("UILocalizationText", "dispatchStatusText")
    self._dispatchTime = self:GetUIComponent("UILocalizationText", "txtTime")
    self._btnDispatch = self:GetUIComponent("RectTransform", "btnDispatch")
    self._uiTime = self:GetUIComponent("RectTransform", "uiTime")
    self._redDispatch = self:View():GetUIComponent("UISelectObjectPath", "redDispatch")
    self._redDispatchSpawn = nil
    self._dispatchLog = self:GetUIComponent("RectTransform", "dispatchLog")
    self._dispatchLogText = self:GetUIComponent("UILocalizationText", "dispatchLogText")
end

function UIN34DispatchMain:InitCommonTopButton()
    self._backBtns = self._ltBtn:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(function()
        ---@type CampaignModule
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        campaignModule:CampaignSwitchState(true, UIStateType.UIActivityN34MainController, UIStateType.UIMain, nil, self._campaign._id)
    end, nil, function()
        self:SwitchState(UIStateType.UIMain)
    end, false, nil, false, function()
        self:EnterFullScreenBg(true)
    end)
end

function UIN34DispatchMain:CreateMission()
    local componentID = self._dispatchComponent:GetComponentCfgId()
    local allCfg = Cfg.cfg_component_dispatch_arch{ComponentID = componentID}

    ---@type DispatchComponentInfo
    local componentInfo = self._dispatchComponent:GetComponentInfo()
    local dispatchInfo = componentInfo.dispatch_infos

    self._missions = {}
    self._dicMissions = {}
    for k, v in pairs(allCfg) do
        local level =
        {
            structName = "UIN34DispatchMain::Level",
            cfgMission = v,
            archInfo = dispatchInfo[v.ID],
            selected = false,
            nodeWidget = nil,
            lineWidget = nil,
            order = nil,
        }

        self._dicMissions[v.ID] = level
        table.insert(self._missions, level)
    end

    local order = 1000
    local missionCount = #self._missions
    local theHeadNode = self._missions[missionCount]
    local loopNode = theHeadNode
    while loopNode ~= nil do
        loopNode.order = order
        order = order - 1

        local idPre = loopNode.cfgMission.PreArchitectureId
        loopNode = self._dicMissions[idPre]
    end

    local loopNode = theHeadNode
    order = loopNode.order
    while loopNode ~= nil do
        local loopNodeID = loopNode.cfgMission.ID
        loopNode = nil

        for k, v in pairs(self._dicMissions) do
            if v.cfgMission.PreArchitectureId == loopNodeID then
                order = order + 1
                v.order = order
                loopNode = v
                break
            end
        end
    end

    table.sort(self._missions, function(a, b)
        return a.order < b.order
    end)

    self._widgetNodes = self._nodeContent:SpawnObjects("UIN34DispatchNode", missionCount)
    self._widgetLines = self._lineContent:SpawnObjects("UIN34DispatchLine", missionCount + 1)
    for k, v in pairs(self._missions) do
        local uiWidget = self._widgetNodes[k]
        v.nodeWidget = uiWidget

        local view = uiWidget:View()
        local anchoredPosition = Vector2(v.cfgMission.NodePosX, v.cfgMission.NodePosY)
        self:NormalizeNode(view.transform, anchoredPosition)
        uiWidget:SetData(self._atlasDispatch, v)

        local uiWidget = self._widgetLines[k]
        v.lineWidget = uiWidget

        local view = uiWidget:View()
        local anchoredPosition = Vector2(v.cfgMission.LinePosX, v.cfgMission.LinePosY)
        self:NormalizeNode(view.transform, anchoredPosition)
        uiWidget:SetData(self._atlasDispatch, v.cfgMission)
    end

    self._widgetLines[missionCount]:SetTail(true)

    self._selectedFrame:SetParent(self._nodeContent:Engine().transform, false)
    self:NormalizeNode(self._selectedFrame, Vector2.zero)

    local theFirstLine = self._widgetLines[missionCount + 1]
    if theFirstLine ~= nil then
        local view = theFirstLine:View()
        local anchoredPosition = Vector2(802, 331)
        self:NormalizeNode(view.transform, anchoredPosition)

        local cfgMission =
        {
            LineSizeW = 128,
            LineSizeH = 178,
            LineImage = nil,
        }
        theFirstLine:SetData(self._atlasDispatch, cfgMission)
    end
end

function UIN34DispatchMain:NormalizeNode(rt, anchoredPosition)
    rt.pivot = Vector2.one * 0.5
    rt.localScale = Vector3.one
    rt.anchorMin = Vector2(0.5, 1)
    rt.anchorMax = Vector2(0.5, 1)
    rt.sizeDelta = Vector3.one * 100
    rt.anchoredPosition = anchoredPosition
end

function UIN34DispatchMain:GetAtlasDispatch()
    return self._atlasDispatch
end

function UIN34DispatchMain:FlushMission()
    for k, v in pairs(self._dicMissions) do
        v.nodeWidget:FlushStatus()
    end
end

function UIN34DispatchMain:FlushSelection()
    local selectedNode = nil
    for k, v in pairs(self._dicMissions) do
        if v.selected then
            selectedNode = v
            break
        end
    end

    if selectedNode == nil then
        self._selectedFrame.gameObject:SetActive(false)
    else
        self._selectedFrame.gameObject:SetActive(true)
        self._selectedFrame.anchoredPosition = selectedNode.nodeWidget:View().transform.anchoredPosition
    end
end

function UIN34DispatchMain:BreakPosition()
    local currentNode = nil
    local completedNode = nil
    for k, v in pairs(self._missions) do
        local archInfo = v.archInfo
        if archInfo == nil then
            currentNode = v
            break
        elseif archInfo.status == ComDispatchStatus.DISPATCHING then
            currentNode = v
            break
        elseif archInfo.status == ComDispatchStatus.COMPLETE then
            completedNode = v
        end
    end

    self._currentNode = currentNode

    -- lookup client db
    if completedNode ~= nil then
        if self._localDb:IsViewed(completedNode.cfgMission.ID) then
            self._currentNode = currentNode
        else
            self._currentNode = completedNode
        end
    end

    ---@type DispatchArchInfo
    local archInfo = self._currentNode.archInfo
    local viewedDialogue = self._localDb:IsViewed(self._currentNode.cfgMission.ID)

    if archInfo == nil then
        return
    elseif archInfo.status == ComDispatchStatus.DISPATCHING then
        local svrTimeModule = self:GetModule(SvrTimeModule)
        local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
        if curTime >= archInfo.end_time then
            -- 派遣完成：派遣完成弹窗（服务器正在派遣 + 时间）
            local lockName = "UIN34DispatchMain:GetRewardsTask"
            self:StartSafeTask(lockName, self.GetRewardsTask, self)
        else
            -- 派遣中：派遣中 + 弹行动日志（服务器正在派遣）
            self:StartRewardTimer()
            self:PopupDispatchLog()
        end
    elseif archInfo.status == ComDispatchStatus.COMPLETE and not viewedDialogue then
        -- 通讯日志：重新查看通讯日志（服务器奖励已领取 + 客户端未查看通讯日志）
        local archId = self._currentNode.cfgMission.ID
        local lockName = "UIN34DispatchMain:OpenDialogueTask"
        self:StartSafeTask(lockName, self.OpenDialogueTask, self, archId)
    end
end

function UIN34DispatchMain:FlushQPlayer()

end

function UIN34DispatchMain:FlushDispatch()
    local theStatus = ComDispatchStatus.COMPLETE

    local archInfo = self._currentNode.archInfo
    if archInfo == nil then
        theStatus = ComDispatchStatus.COMPLETE
    else
        theStatus = archInfo.status
    end

    self._uiTime.gameObject:SetActive(theStatus == ComDispatchStatus.DISPATCHING)
    self._btnDispatch.gameObject:SetActive(theStatus == ComDispatchStatus.COMPLETE)

    local showRedPoint = false
    if theStatus == ComDispatchStatus.COMPLETE then
        self._dispatchStatusText:SetText(StringTable.Get("str_n34_dispatch_wait_btn_status"))

        local count = #self._missions
        local theLastNode = self._missions[count]
        showRedPoint = self._currentNode ~= theLastNode
    elseif theStatus == ComDispatchStatus.DISPATCHING then
        local svrTimeModule = self:GetModule(SvrTimeModule)
        local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
        local deltaTime = math.max(archInfo.end_time - curTime, 0)
        local timerStr = self:GetFormatTimerStr(deltaTime, "FFF004")

        self._dispatchStatusText:SetText(StringTable.Get("str_n34_dispatch_progress_btn_status"))
        self._dispatchTime:SetText(StringTable.Get("str_n34_dispatch_progress_btn", timerStr))
    end

    if self._redDispatchSpawn == nil then
        self._redDispatchSpawn = self._redDispatch:SpawnOneObject("ManualLoad0")
    end

    self._redDispatchSpawn:SetActive(showRedPoint)
end

function UIN34DispatchMain:GetFormatTimerStr(deltaTime, txtColor)
    local id =
    {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107",
        ["clrFormat"] = "<color=#%s>%s</color>"
    }

    if txtColor == nil then
        txtColor = "FFF004"
    end

    local day = 0
    local hour = 0
    local min = 0
    local second = 0
    if deltaTime >= 0 then
        day, hour, min, second = UIActivityHelper.Time2Str(deltaTime)
    end

    local timeStr = nil
    if day > 0 and hour > 0 then
        timeStr = string.format(id.clrFormat, txtColor, day) .. StringTable.Get(id.day)
        timeStr = timeStr .. string.format(id.clrFormat, txtColor, hour) .. StringTable.Get(id.hour)
    elseif day > 0 then
        timeStr = string.format(id.clrFormat, txtColor, day) .. StringTable.Get(id.day)
    elseif hour > 0 and min > 0 then
        timeStr = string.format(id.clrFormat, txtColor, hour) .. StringTable.Get(id.hour)
        timeStr = timeStr .. string.format(id.clrFormat, txtColor, min) .. StringTable.Get(id.min)
    elseif hour > 0 then
        timeStr = string.format(id.clrFormat, txtColor, hour) .. StringTable.Get(id.hour)
    elseif min > 0 then
        timeStr = string.format(id.clrFormat, txtColor, min) .. StringTable.Get(id.min)
    else
        timeStr = string.format(id.clrFormat, txtColor, StringTable.Get(id.zero))
    end

    return timeStr
end

function UIN34DispatchMain:PopupDispatchLog()
    local archInfo = self._currentNode.archInfo
    local allCfg = Cfg.cfg_mission_dispatch_log{BuildingId = archInfo.arch_id}
    local sortList = {}
    for k, v in pairs(allCfg) do
        table.insert(sortList, v)
    end

    table.sort(sortList, function(a, b)
        return a.DispatchTime < b.DispatchTime
    end)

    local endTime = self._currentNode.archInfo.end_time
    local dispatchPeriod = self._currentNode.cfgMission.DispatchTime
    local startTime = endTime - dispatchPeriod
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local cfgPopup = nil
    for k, v in pairs(sortList) do
        if curTime >= startTime + v.DispatchTime then
            cfgPopup = v
        else
            break
        end
    end

    if cfgPopup ~= nil then
        self:ShowDispatchLog(true, StringTable.Get(cfgPopup.ChatId))
        self:StartHideLogTimer(cfgPopup.DisplayPeriod * 1000)
    end
end

function UIN34DispatchMain:ShowDispatchLog(inVisible, logMessage)
    self._dispatchLog.gameObject:SetActive(inVisible)

    if inVisible then
        self._dispatchLogText:SetText(logMessage)
    end
end

function UIN34DispatchMain:DispatchTask(TT, lockName)
    self:Lock(lockName)

    local res = AsyncRequestRes:New()
    res:SetSucc(true)

    local archId = self._currentNode.cfgMission.ID
    self._dispatchComponent:HandleDispatch(TT, res, archId)
    if not res:GetSucc() then
        self._campaign:CheckErrorCode(res:GetResult(), nil, nil)
    else
        ---@type DispatchComponentInfo
        local componentInfo = self._dispatchComponent:GetComponentInfo()
        local dispatchInfo = componentInfo.dispatch_infos
        local archInfo = dispatchInfo[archId]

        self._currentNode.selected = false
        self._currentNode.archInfo = archInfo
        self:FlushMission()
        self:FlushSelection()
        self:FlushQPlayer()
        self:FlushDispatch()
        self:StartRewardTimer()
    end

    self:UnLock(lockName)
end

function UIN34DispatchMain:GetRewardsTask(TT, lockName)
    self:Lock(lockName)

    local res = AsyncRequestRes:New()
    res:SetSucc(true)

    local archId = self._currentNode.cfgMission.ID
    self._dispatchComponent:HandleGetDispatchRewards(TT, res, archId)
    if not res:GetSucc() then
        self._campaign:CheckErrorCode(res:GetResult(), nil, nil)
    else
        ---@type DispatchComponentInfo
        local componentInfo = self._dispatchComponent:GetComponentInfo()
        local dispatchInfo = componentInfo.dispatch_infos
        local newArchInfo = dispatchInfo[archId]

        self:GetRewardsSuccess(TT, lockName, newArchInfo)
    end

    self:UnLock(lockName)
end

function UIN34DispatchMain:GetRewardsTask_TestCase(TT)
    local lockName = "UIN34DispatchMain:GetRewardsTask"
    self:Lock(lockName)

    local archInfo = self._currentNode.archInfo
    local newArchInfo = DispatchArchInfo:New()
    newArchInfo.arch_id = archInfo.arch_id
    newArchInfo.end_time = archInfo.end_time
    newArchInfo.status = ComDispatchStatus.COMPLETE

    self:GetRewardsSuccess(TT, lockName, newArchInfo)

    self:UnLock(lockName)
end

function UIN34DispatchMain:GetRewardsSuccess(TT, lockName, newArchInfo)
    local archId = newArchInfo.arch_id
    local uiName = "UIN34DispatchComplete"
    local uiStateManager = GameGlobal.UIStateManager()
    self:ShowDialog(uiName, archId)

    -- ensure visible
    while not uiStateManager:IsShow(uiName) do
        YIELD(TT)
    end

    YIELD(TT, 1000)

    self._currentNode.archInfo = newArchInfo

    self:FlushMission()
    self:FlushQPlayer()
    self:FlushDispatch()

    self:UnLock(lockName)
    while uiStateManager:IsShow(uiName) do
        YIELD(TT)
    end
    self:Lock(lockName)

    YIELD(TT, 500)

    local lockName = "UIN34DispatchMain:OpenDialogueTask"
    self:StartSafeTask(lockName, self.OpenDialogueTask, self, archId)
end

function UIN34DispatchMain:OpenDialogueTask(TT, lockName, archId)
    self:Lock(lockName)

    local uiDialogueOpen = "UIN34DispatchDialogueOpen"
    local uiTerminalMain = "UIN34DispatchTerminalMainControlller"
    local uiStateManager = GameGlobal.UIStateManager()

    local openTerminal = false
    self:ShowDialog(uiDialogueOpen, archId, function()
        openTerminal = true
    end)

    -- ensure visible
    while not uiStateManager:IsShow(uiDialogueOpen) do
        YIELD(TT)
    end

    self:UnLock(lockName)
    while uiStateManager:IsShow(uiDialogueOpen) do
        YIELD(TT)

        if openTerminal then
            break
        end
    end

    self:Lock(lockName)
    self:ShowDialog(uiTerminalMain, UIN34DispatchType.OpenDialogue, archId)

    -- ensure visible
    while not uiStateManager:IsShow(uiTerminalMain) do
        YIELD(TT)
    end

    YIELD(TT, 50)
    uiStateManager:CloseDialog(uiDialogueOpen)

    self:UnLock(lockName)
    while uiStateManager:IsShow(uiTerminalMain) do
        YIELD(TT)
    end


    self:Lock(lockName)

    self._localDb:ViewedLoadDB()
    if self._localDb:IsViewed(archId) then
        local findCurrentNode = false
        for k, v in pairs(self._missions) do
            if self._currentNode == v then
                findCurrentNode = true
            elseif findCurrentNode then
                self._currentNode = v
                break
            end
        end
    end

    self:UnLock(lockName)
end



---@class UIN34DispatchNode:UICustomWidget
_class("UIN34DispatchNode", UICustomWidget)
UIN34DispatchNode = UIN34DispatchNode

function UIN34DispatchNode:Constructor()

end

function UIN34DispatchNode:OnShow()
    self._uiNormal = self:GetUIComponent("Image", "uiNormal")
    self._uiProgress = self:GetUIComponent("RectTransform", "uiProgress")
    self._uiCompleted = self:GetUIComponent("RectTransform", "uiCompleted")
end

function UIN34DispatchNode:OnHide()

end

function UIN34DispatchNode:BtnOnClick(go)
    self:RootUIOwner():NodeOnClick(self)
end

function UIN34DispatchNode:BtnNormalOnClick(go)
    self:RootUIOwner():NodeOnClick(self)
end

function UIN34DispatchNode:SetData(atlasDispatch, data)
    self._atlasDispatch = atlasDispatch
    self._data = data

    self:FlushNormal()
end

function UIN34DispatchNode:ID()
    return self._data.cfgMission.ID
end

function UIN34DispatchNode:FlushNormal()
    local cfgMission = self._data.cfgMission
    self._uiNormal.transform.sizeDelta = Vector2(cfgMission.NodeSizeW, cfgMission.NodeSizeH)

    if cfgMission.NodeImage ~= nil then
        self._uiNormal.sprite = self._atlasDispatch:GetSprite(cfgMission.NodeImage)
    end
end

function UIN34DispatchNode:FlushStatus()
    self._uiProgress.gameObject:SetActive(false)
    self._uiCompleted.gameObject:SetActive(false)

    local archInfo = self._data.archInfo
    if archInfo ~= nil then
        self._uiCompleted.gameObject:SetActive(archInfo.status == ComDispatchStatus.COMPLETE)
    end
end


---@class UIN34DispatchLine:UICustomWidget
_class("UIN34DispatchLine", UICustomWidget)
UIN34DispatchLine = UIN34DispatchLine

function UIN34DispatchLine:Constructor()
    self._isTail = false
end

function UIN34DispatchLine:OnShow()
    self._imgRoot = self:GetUIComponent("Image", "imgRoot")
    self._animation = self:GetUIComponent("Animation", "animation")
end

function UIN34DispatchLine:SetData(atlasDispatch, cfgMission)
    self._atlasDispatch = atlasDispatch
    self._cfgMission = cfgMission

    self:Flush()
end

function UIN34DispatchLine:Flush()
    local cfgMission = self._cfgMission
    self._imgRoot.transform.sizeDelta = Vector2(cfgMission.LineSizeW, cfgMission.LineSizeH)

    if cfgMission.LineImage ~= nil then
        self._imgRoot.sprite = self._atlasDispatch:GetSprite(cfgMission.LineImage)
    end
end

function UIN34DispatchLine:OnHide()

end

function UIN34DispatchLine:SetTail()
    self._isTail = true
end
