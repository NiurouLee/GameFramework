---@class UIN26Line:UIController
_class("UIN26Line", UIController)
UIN26Line = UIN26Line

function UIN26Line:Constructor()
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
end

--- @param res AsyncRequestRes 异步请求结果
function UIN26Line:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N26
    self._componentId_LineMission = ECampaignN26ComponentID.ECAMPAIGN_N26_LINE_MISSION
    self._componentId_LineMissionFixteam = ECampaignN26ComponentID.ECAMPAIGN_N26_FIRST_MEET

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
            TT,
            res,
            self._campaignType,
            self._componentId_LineMission,
            self._componentId_LineMissionFixteam
    )

    --强制请求
    --请求完了再获取就一定是最新的了
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
    self._campaignID = self._campaign._id

    if res and res:GetSucc() then
        ---@type LineMissionComponent
        self._line_component = self._campaign:GetComponent(self._componentId_LineMission)
        --- @type LineMissionComponentInfo
        self._line_info = self._line_component:GetComponentInfo()

        if not self._campaign:CheckComponentOpen(self._componentId_LineMission) then
            res.m_result = self._campaign:CheckComponentOpenClientError(self._componentId_LineMission)
            self._campModule:ShowErrorToast(res.m_result, true)
            return
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIN26Line:OnShow(uiParams)
    local spine, bgm = self:GetSpineAndBgm()
    if bgm then
        AudioHelperController.PlayBGM(bgm, AudioConstValue.BGMCrossFadeTime)
    end

    self:InitWidget()
    self:InitCommonTopButton()
    self:_Refresh()

    -- 进场锁定
    local lockName = "UIN26Line.Enter"
    self:Lock(lockName)
    self._timerHolder = UITimerHolder:New()
    self._timerHolder:StartTimer(
            lockName,
            500,
            function()
                self:UnLock(lockName)
            end
    )

    self._isOpen = true
    self:AttachEvents()

    if true then
        return
    end

    N25Data.SetPrefsLine()
end

function UIN26Line:OnHide()
    self._isOpen = false
    self._timerHolder:Dispose()
    self._scroller:Dispose()

    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end

    self:DetachEvents()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN26ActivityMainRedStatusRefresh)

    if true then
        return
    end

    UIN26Line.super:Dispose()
end

function UIN26Line:InitCommonTopButton()
    local fnHelpTest = function()
    end

    fnHelpTest = nil

    self._backBtns = self._ltBtn:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(function()
        ---@type CampaignModule
        self._campModule:CampaignSwitchState(true, UIStateType.UIActivityN26MainController, UIStateType.UIMain, nil, self._campaign._id)
    end, fnHelpTest, function()
        self:SwitchState(UIStateType.UIMain)
    end, false, nil, function()
        self:EnterFullScreenBg(true)
    end)
end

function UIN26Line:InitWidget()
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "MapContent")
    self._mapContentRect = self:GetUIComponent("RectTransform", "MapContent")
    self._contentRect = self:GetUIComponent("RectTransform", "Content")

    ---@type UICustomWidgetPool
    self._ltBtn = self:GetUIComponent("UISelectObjectPath", "ltBtn")
    self._txtRemainingTime = self:GetUIComponent("UILocalizationText", "remainingTime")
    ---@type UICustomWidgetPool
    self._linesPool = self:GetUIComponent("UISelectObjectPath", "Lines")
    self._nodesPool = self:GetUIComponent("UISelectObjectPath", "Nodes")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")

    self._atlas = self:GetAsset("UIN26Line.spriteatlas", LoadType.SpriteAtlas)

    --安全区宽度,没有找到框架的接口,直接从RectTransform上取
    self._safeAreaSize = self:GetUIComponent("RectTransform", "SafeArea").rect.size
    self._shot.width = self._safeAreaSize.x
    self._shot.height = self._safeAreaSize.y
end

function UIN26Line:OnUpdate()
    self:RefreshTime()
end

function UIN26Line:_Refresh()
    self:FlushNodes()
    self:_SetTryoutBtn()
    self:_SetExchangeBtn()
    self:RefreshTime()
end

function UIN26Line:RefreshTime()
    local endTime = self._line_component:GetComponentInfo().m_close_time
    --- @type SvrTimeModule
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local str = self:GetFormatTimerStr(endTime - curTime, "FDFCFB")
    self._txtRemainingTime:SetText(str)
end

function UIN26Line:GetFormatTimerStr(time, txtColor)
    local id =
    {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107"
    }

    local timeStr = nil
    if time < 0 then
        return StringTable.Get(id.over)
    end

    if txtColor == nil then
        txtColor = "fb81cc"
    end

    local labelColor = string.format("<color=#%s>", txtColor)
    local day, hour, min, second = UIActivityHelper.Time2Str(time)
    if day > 0 and hour > 0 then
        timeStr = labelColor .. day .. "</color>" .. StringTable.Get(id.day) ..
                labelColor .. hour .. "</color>" .. StringTable.Get(id.hour)
    elseif day > 0 then
        timeStr = labelColor .. day .. "</color>" .. StringTable.Get(id.day)
    elseif hour > 0 and min > 0 then
        timeStr = labelColor .. hour .. "</color>" .. StringTable.Get(id.hour) ..
                labelColor .. min .. "</color>" .. StringTable.Get(id.min)
    elseif hour > 0 then
        timeStr = labelColor .. hour .. "</color>" .. StringTable.Get(id.hour)
    elseif min > 0 then
        timeStr = labelColor .. min .. "</color>" .. StringTable.Get(id.min)
    else
        timeStr = labelColor .. StringTable.Get(id.zero) .. "</color>"
    end

    return timeStr
end

function UIN26Line:_SetTryoutBtn()
    local componentId = self._componentId_LineMissionFixteam
    local obj = self:_SpawnObject("tryoutBtn", "UIActivityCommonComponentEnterLock")

    obj:SetRed("red", function()
        return self._campaign:CheckComponentRed(self._localProcess, ECampaignN26ComponentID.ECAMPAIGN_N26_FIRST_MEET)
    end)

    local component = self._campaign:GetComponent(componentId)
    obj:SetData(self._campaign, componentId, function()
        self:ShowDialog("UIActivityPetTryController", self._campaignType, componentId, function(mid)
            return component:IsPassCamMissionID(mid)
        end, function(missionid)
            ---@type TeamsContext
            local ctx = self._missionModule:TeamCtx()
            local missionComponent = self._campaign:GetComponent(componentId)
            local param =
            {
                missionid,
                missionComponent:GetCampaignMissionComponentId(),
                missionComponent:GetCampaignMissionParamKeyMap()
            }
            ctx:Init(TeamOpenerType.Campaign, param)
            ctx:ShowDialogUITeams(false)
        end)
    end)
end

function UIN26Line:_SetExchangeBtn()
    local componentId = ECampaignN26ComponentID.ECAMPAIGN_N26_SHOP
    local obj = self:_SpawnObject("exchangeBtn", "UIActivityCommonComponentEnter")
    obj:SetRed("red", function()
        return self._campaign:CheckComponentOpen(componentId) and self._campaign:CheckComponentRed(componentId)
    end)

    ---@type ExchangeItemComponent
    local component = self._campaign:GetComponent(componentId)
    local icon, count = component:GetCostItemIconText()
    if icon then
        obj:SetIcon("icon", icon)
    end

    obj:SetText("text", count)
    obj:SetText("txtNumbg", string.format("%.7d", count))

    obj:SetData(self._campaign, function()
        ClientCampaignShop.OpenCampaignShop(self._campaign._type, self._campaign._id, function()
            local uiParams = {}
            uiParams[1] = self._activityConst
            self._campaign._campaign_module:CampaignSwitchState(
                    true,
                    UIStateType.UIN26Line,
                    UIStateType.UIMain,
                    uiParams,
                    self._campaign._id,
                    componentId
            )
        end, self._activityConst)
    end)

    local lockTr = obj:GetUIComponent("RectTransform", "lock")
    lockTr.gameObject:SetActive(false)
end

function UIN26Line.GetItemCountStr(count, preColor, countColor)
    local dight = 0
    local tmpCount = count
    if tmpCount < 0 then
        tmpCount = -tmpCount
    end
    while tmpCount > 0 do
        tmpCount = math.floor(tmpCount / 10)
        dight = dight + 1
    end

    local pre = ""
    if count >= 0 then
        for i = 1, 7 - dight do
            pre = pre .. "0"
        end
    else
        for i = 1, 7 - dight - 1 do
            pre = pre .. "0"
        end
    end

    if count > 0 then
        return string.format("<color=" .. preColor .. ">%s</color><color=" .. countColor .. ">%s</color>", pre, count)
    elseif count == 0 then
        return string.format("<color=" .. preColor .. ">%s</color>", pre)
    else
        return string.format("<color=" .. preColor .. ">%s</color><color=" .. countColor .. ">%s</color>", pre, count)
    end
end

function UIN26Line:FlushNodes()
    local cmpID = self._line_component:GetComponentCfgId()
    local extra_cfg = Cfg.cfg_component_line_mission_extra {ComponentID = cmpID}
    local extra_width = 600
    if extra_cfg then
        extra_width = extra_cfg[1].MarginRight
    end
    local missionCfgs_temp = Cfg.cfg_component_line_mission {ComponentID = cmpID}
    --所有配置,以id为索引
    local missionCfgs = {}
    for _, cfg in pairs(missionCfgs_temp) do
        missionCfgs[cfg.CampaignMissionId] = cfg
    end

    --所有关卡的解锁关系
    local unlockInfo = {}
    local firstMissionID = nil
    for _, cfg in pairs(missionCfgs) do
        if unlockInfo[cfg.NeedMissionId] == nil then
            unlockInfo[cfg.NeedMissionId] = {}
        end
        unlockInfo[cfg.NeedMissionId][cfg.CampaignMissionId] = cfg
        if cfg.NeedMissionId == 0 then
            firstMissionID = cfg.CampaignMissionId
        end
    end


    local pass_mission_info = self._line_info.m_pass_mission_info

    local showMission = {}
    local levelCount, lineCount = 0, 0
    if next(pass_mission_info) then
        for missionID, passInfo in pairs(pass_mission_info) do
            if not showMission[missionID] then
                showMission[missionID] = missionCfgs[missionID]
                levelCount = levelCount + 1
            end
            if unlockInfo[missionID] then
                for id, cfg in pairs(unlockInfo[missionID]) do
                    if not showMission[id] then
                        showMission[id] = missionCfgs[id]
                        levelCount = levelCount + 1
                    end
                    --S关和第1关不需要连线
                    if cfg.WayPointType ~= 4 and cfg.NeedMissionId ~= 0 then
                        lineCount = lineCount + 1
                    end
                end
            end
        end
    else
        --没有通关信息则显示第一关
        showMission[firstMissionID] = missionCfgs[firstMissionID]
        levelCount = 1
    end

    self._nodesPool:SpawnObjects("UIN26LineMapNode", levelCount)
    self._linesPool:SpawnObjects("UIN26LineMapLine", lineCount)

    ---@type table<number,UIN26LineMapNode>
    local nodes = self._nodesPool:GetAllSpawnList()
    ---@type table<number,UIN26LineMapLine>
    local lines = self._linesPool:GetAllSpawnList()

    local nodeIdx, lineIdx = 1, 1
    for missionID, cfg in pairs(showMission) do
        ---@type UIN26LineMapNode
        local uiNode = nodes[nodeIdx]
        uiNode:SetAtlas(self._atlas)
        uiNode:SetData(
                cfg,
                self._line_info.m_pass_mission_info[missionID],
                function(stageId, isStory, worldPos)
                    self:OnNodeClick(stageId, isStory, worldPos)
                end
        )
        nodeIdx = nodeIdx + 1

        if cfg.WayPointType ~= 4 and cfg.NeedMissionId ~= 0 then
            local n1 = showMission[cfg.NeedMissionId]
            local n2 = cfg
            ---@type UIN26LineMapLine
            local line = lines[lineIdx]
            line:SetAtlas(self._atlas)
            line:Flush(Vector2(n2.MapPosX, n2.MapPosY), Vector2(n1.MapPosX, n1.MapPosY))
            lineIdx = lineIdx + 1
        end
    end

    local right = -1111111111111111
    for _, cfg in pairs(showMission) do
        right = math.max(right, cfg.MapPosX)
    end
    --滚动列表总宽度=最右边路点+右边距
    local width = math.abs(right + extra_width)
    width = math.max(self._safeAreaSize.x, width)
    self._contentRect.sizeDelta = Vector2(width, self._contentRect.sizeDelta.y)
    self._contentRect.anchoredPosition = Vector2(self._safeAreaSize.x - width, 0)

    --背景滚动
    local posx = {}
    for _, cfg in pairs(missionCfgs) do
        posx[#posx + 1] = cfg.MapPosX
    end
    table.sort(posx) --所有路点横坐标从左到右排序
    local sp1, sp2 = 6, 12
    local bgLoader1 = self:GetUIComponent("RawImageLoader", "bg1")
    local bgLoader2 = self:GetUIComponent("RawImageLoader", "bg2")
    --28个路点分成3段,有两个分割点,可能会经常改动
    ---@type UILevelScroller
    self._scroller = UILevelScroller:New(
            self._contentRect,
            bgLoader1,
            bgLoader2,
            { "n26_xxg_bg01", "n26_xxg_bg02", "n26_xxg_bg03" },
            { posx[sp1], posx[sp1+1], posx[sp2], posx[sp2+1] }
    )
    self._scrollRect.onValueChanged:AddListener(function()
        self._scroller:OnChange()
    end)
    self._allMissionCfgs = missionCfgs
end

function UIN26Line:OnNodeClick(stageId, isStory, worldPos)
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

    --战斗关
    local pos = self._allMissionCfgs[stageId].MapPosX
    local curPos = self._contentRect.anchoredPosition.x
    local areaWidth = 408
    local halfScreen = self._safeAreaSize.x / 2
    local targetPos = nil
    local left, right = -curPos + areaWidth, -curPos + self._safeAreaSize.x - areaWidth
    if pos < left then
        targetPos = curPos + left - pos
    elseif pos > right then
        targetPos = curPos + right - pos
    end
    self._scrollRect:StopMovement()
    if self._tweener then
        self._tweener:Kill()
        self._tweener = nil
    end
    if targetPos then
        local moveTime = 0.5
        self._tweener = self._contentRect:DOAnchorPosX(targetPos, moveTime)
        -- 移动关卡锁定
        local moveLockName = "UIN26Line.MoveToStage"
        self:Lock(moveLockName)
        self._timerHolder:StartTimer(
                moveLockName,
                moveTime * 1000,
                function()
                    self:UnLock(moveLockName)
                    self:_EnterStage(stageId, worldPos) -- 移动后，进入关卡
                end
        )
    else
        self:_EnterStage(stageId, worldPos) -- 直接进入关卡
    end
end

function UIN26Line:_EnterStage(stageId, worldPos)
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    self._shot:CleanRenderTexture()
    -- local rt = self._shot:RefreshBlurTexture()
    -- local scale = 1.3
    -- local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    -- local screenPos = camera:WorldToScreenPoint(worldPos)
    -- local offset = -(Vector2(screenPos.x, screenPos.y) - Vector2(UnityEngine.Screen.width, UnityEngine.Screen.height) / 2)
    local missionCfg = Cfg.cfg_campaign_mission[stageId]
    local autoFightShow = self:_CheckSerialAutoFightShow(missionCfg.Type, stageId)
    local pointComponent = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_ACTION_POINT, 1)
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
    --     pointComponent --行动点组件
    -- )

    self:ShowDialog(
            "UIActivityLevelStageNew",
            stageId,
            self._line_info.m_pass_mission_info[stageId],
            self._line_component,
            autoFightShow,
            pointComponent  --行动点组件
    )
end

function UIN26Line:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        -- self:SwitchState(UIStateType.UIN26Line)
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
                                    self:SwitchState(UIStateType.UIN26Line, self._activityConst)
                                end
                        )
                    else
                        self:SwitchState(UIStateType.UIN26Line, self._activityConst)
                    end
                end
            end,
            self
    )
end

function UIN26Line:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIN26Line:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

--region AttachEvent
function UIN26Line:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIN26Line:DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIN26Line:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN26Line:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end
--endregion

--region Helper
function UIN26Line:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIN26Line:_SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIN26Line:_SetText(widgetName, str)
    widgetName = widgetName or "text"

    ---@type UILocalizationText
    local obj = self:GetUIComponent("UILocalizationText", widgetName)
    obj:SetText(str)
end
--endregion

---@return string, number
function UIN26Line:GetSpineAndBgm()
    local cfg = Cfg.cfg_n25_const[1]
    if self._line_info and cfg then
        ---@type MissionModule
        local missionModule = GameGlobal.GetModule(MissionModule)
        ---@type cam_mission_info[]
        local passInfo = self._line_info.m_pass_mission_info
        for _, info in pairs(passInfo) do
            local storyId = missionModule:GetStoryByStageIdStoryType(info.mission_id, StoryTriggerType.Node)
            if storyId == cfg.StoryID then
                return cfg.Spine2, cfg.Bgm2
            end
        end
        return cfg.Spine1, cfg.Bgm1
    end
    return nil, nil
end