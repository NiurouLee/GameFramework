---@class UIN25Line:UIController
_class("UIN25Line", UIController)
UIN25Line = UIN25Line

function UIN25Line:Constructor()
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
end

--- @param res AsyncRequestRes 异步请求结果
function UIN25Line:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N25
    self._componentId_LineMission = ECampaignN25ComponentID.ECAMPAIGN_N25_LINE_MISSION
    self._componentId_LineMissionFixteam = ECampaignN25ComponentID.ECAMPAIGN_N25_FIRST_MEET

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

        ---@type CCampaignN25
        self._localProcess = self._campaign:GetLocalProcess()
         ---@type LineMissionComponentInfo
        self._fixTeamCompInfo = self._localProcess:GetComponentInfo(ECampaignN25ComponentID.ECAMPAIGN_N25_FIRST_MEET)


        if not self._campaign:CheckComponentOpen(self._componentId_LineMission) then
            res.m_result = self._campaign:CheckComponentOpenClientError(self._componentId_LineMission)
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:ShowErrorToast(res.m_result, true)
            return
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIN25Line:CheckRedTryPet()
    local red = self._campaign:CheckComponentRed(self._localProcess, ECampaignN25ComponentID.ECAMPAIGN_N25_FIRST_MEET)
    return red
end

function UIN25Line:OnShow(uiParams)
    local spine, bgm = self:GetSpineAndBgm()
    if bgm then
        AudioHelperController.PlayBGM(bgm, AudioConstValue.BGMCrossFadeTime)
    end
    
    N25Data.SetPrefsLine()
    self._remainingTimeLabel = self:GetUIComponent("UILocalizationText", "remainingTime")
    self._isOpen = true
    self._timerHolder = UITimerHolder:New()
    self._camera = GameGlobal.UIStateManager():GetControllerCamera("UIN25Line")

    UIN25Line.SLeval = 111111 --s关枚举id
    UIN25Line.Passed = 888 --通关后文本和阴影颜色
    UIN25Line.NodeCfg = {
        [DiscoveryStageType.FightNormal] = {
            [1] = {
                normal = "n25_xxg_spot01",
                press = "",
                lock = "",
                textColor = Color(65 / 255, 40 / 255, 17 / 255), -- 不使用
                textShadow = Color(0 / 255, 0 / 255, 0 / 255), -- 不使用
                normalStar = "",
                passStar = "n25_xxg_star01"
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(241 / 255, 255 / 255, 117 / 255),
                textShadow = Color(111 / 255, 52 / 255, 25 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        },
        [DiscoveryStageType.FightBoss] = {
            [1] = {
                normal = "n25_xxg_spot03",
                press = "",
                lock = "",
                textColor = Color.New(212 / 255, 148 / 255, 91 / 255), -- 不使用
                textShadow = Color.New(255 / 255, 255 / 255, 255 / 255), -- 不使用
                normalStar = "",
                passStar = "n25_xxg_star01"
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color.New(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color.New(238 / 255, 0 / 255, 34 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        },
        [DiscoveryStageType.Plot] = {
            [1] = {
                normal = "n25_xxg_spot02",
                press = "",
                lock = "",
                textColor = Color.New(65 / 255, 40 / 255, 17 / 255), -- 不使用
                textShadow = Color.New(0 / 255, 0 / 255, 0 / 255) -- 不使用
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color.New(241 / 255, 255 / 255, 117 / 255),
                textShadow = Color.New(111 / 255, 52 / 255, 25 / 255)
            } --高难样式
        },
        [UIN25Line.SLeval] = {
            [1] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color.New(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color.New(22 / 255, 42 / 255, 61 / 255),
                normalStar = "",
                passStar = ""
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color.New(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color.New(22 / 255, 42 / 255, 61 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        }
    }

    self:AttachEvents()
    self:InitWidget()

    self:_Refresh()

    -- 进场锁定
    local lockName = "UIActivity_LineMissionController_Enter"
    self:Lock(lockName)
    self._timerHolder:StartTimer(
        lockName,
        500,
        function()
            self:UnLock(lockName)
        end
    )
end

function UIN25Line:OnHide()
    UIN25Line.SLeval = nil
    UIN25Line.NodeCfg = nil
    self._isOpen = false
    self._timerHolder:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIN25Line.super:Dispose()
    self._scroller:Dispose()
    self:DetachEvents()
end

function UIN25Line:InitWidget()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    ---@type UICommonTopButton
    self.backBtns = backBtns:SpawnObject("UICommonTopButton")
    self.backBtns:SetData(
        function()
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CampaignSwitchState(true, UIStateType.UIActivityN25MainController, UIStateType.UIMain, nil, self._campaign._id)
        end
    )
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "MapContent")
    self._mapContentRect = self:GetUIComponent("RectTransform", "MapContent")
    self._contentRect = self:GetUIComponent("RectTransform", "Content")

    ---@type UICustomWidgetPool
    self._linesPool = self:GetUIComponent("UISelectObjectPath", "Lines")
    self._nodesPool = self:GetUIComponent("UISelectObjectPath", "Nodes")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")

    --安全区宽度,没有找到框架的接口,直接从RectTransform上取
    self._safeAreaSize = self:GetUIComponent("RectTransform", "SafeArea").rect.size
    self._shot.width = self._safeAreaSize.x
    self._shot.height = self._safeAreaSize.y

    --倒计时背景宽度计算
    self._leftPosRt = self:GetUIComponent("RectTransform", "leftPos")
    self._rightPosRt = self:GetUIComponent("RectTransform", "rightPos");
    self._timeBgRt = self:GetUIComponent("RectTransform", "timeBg")
end

function UIN25Line:OnUpdate()
    self:RefreshTime()
end

function UIN25Line:_Refresh()
    self:FlushNodes()
    self:_SetTryoutBtn()
    self:_SetExchangeBtn()
    self:RefreshTime()
end

function UIN25Line:RefreshTime()
    local endTime = self._line_component:GetComponentInfo().m_close_time
    --- @type SvrTimeModule
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local str = self:GetFormatTimerStr(endTime - curTime)
    self._remainingTimeLabel:SetText(str)
    local screenL = UnityEngine.RectTransformUtility.WorldToScreenPoint(self._camera, self._leftPosRt.position)
    local screenR = UnityEngine.RectTransformUtility.WorldToScreenPoint(self._camera, self._rightPosRt.position)
    local res, posL = UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self._timeBgRt, screenL, self._camera, nil)
    local res, posR = UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self._timeBgRt, screenR, self._camera, nil)
    local sz =  self._timeBgRt.sizeDelta
    sz.x = posR.x - posL.x + 10
    self._timeBgRt.sizeDelta = sz

    if curTime > endTime and not self.lineEnd then
        self.lineEnd = true
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        campaignModule:CampaignSwitchState(true, UIStateType.UIActivityN25MainController, UIStateType.UIMain, nil, self._campaign._id)
    end
    
end

function UIN25Line:GetFormatTimerStr(time)
    local id = {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107"
    }

    local timeStr = StringTable.Get(id.over)
    if time < 0 then
        return timeStr
    end
    local day, hour, min, second = UIActivityHelper.Time2Str(time)
    if day > 0 then
        timeStr =
            "<color=#fb81cc>" ..
            day ..
                "</color>" ..
                    StringTable.Get(id.day) .. "<color=#fb81cc>" .. hour .. "</color>" .. StringTable.Get(id.hour)
    elseif hour > 0 then
        timeStr =
            "<color=#fb81cc>" ..
            hour ..
                "</color>" ..
                    StringTable.Get(id.hour) .. "<color=#fb81cc>" .. min .. "</color>" .. StringTable.Get(id.min)
    elseif min > 0 then
        timeStr = "<color=#fb81cc>" .. min .. "</color>" .. StringTable.Get(id.min)
    else
        timeStr = "<color=#fb81cc>" .. StringTable.Get(id.zero) .. "</color>"
    end
    return timeStr
end

function UIN25Line:_SetTryoutBtn()
    local componentId = self._componentId_LineMissionFixteam
   -- local redDotModule = GameGlobal.GetModule(RedDotModule)
    local obj = self:_SpawnObject("tryoutBtn", "UIActivityCommonComponentEnterLock")

    obj:SetRed(
        "red",
        function()
            return self:CheckRedTryPet()
            --return redDotModule:_RequestRedDotStatus4N11(RedDotType.RDT_N11_FIXLINEMISSION) --TODO
        end
    )

    local component = self._campaign:GetComponent(componentId)
    obj:SetData(
        self._campaign,
        componentId,
        function()
            self:ShowDialog(
                "UIActivityPetTryController",
                self._campaignType,
                componentId,
                function(mid)
                    return component:IsPassCamMissionID(mid)
                end,
                function(missionid)
                    ---@type TeamsContext
                    local ctx = self._missionModule:TeamCtx()
                    local missionComponent = self._campaign:GetComponent(componentId)
                    local param = {
                        missionid,
                        missionComponent:GetCampaignMissionComponentId(),
                        missionComponent:GetCampaignMissionParamKeyMap()
                    }
                    ctx:Init(TeamOpenerType.Campaign, param)
                    ctx:ShowDialogUITeams(false)
                end
            )
        end
    )
end

function UIN25Line:_SetExchangeBtn()
    local componentId = ECampaignN25ComponentID.ECAMPAIGN_N25_SHOP
    local obj = self:_SpawnObject("exchangeBtn", "UIActivityCommonComponentEnter")
    obj:SetRed(
        "red",
        function()
            return self._campaign:CheckComponentOpen(componentId) and self._campaign:CheckComponentRed(componentId)
        end
    )

    ---@type ExchangeItemComponent
    local component = self._campaign:GetComponent(componentId)
    local icon, count = component:GetCostItemIconText()
    if icon then
        obj:SetIcon("icon", icon)
    end
    local preZero = UIActivityHelper.GetZeroStrFrontNum(7, count)
    local fmtStr = UIActivityN20MainController.GetItemCountStr(count, "#847D7D", "#ffe671")
    obj:SetText("text", fmtStr)
    obj:SetText("txtNumbg", UIActivityN20MainController.GetItemCountStr(count, "#312E1B", "#312E1B"))
    obj:SetData(
        self._campaign,
        function()
            ClientCampaignShop.OpenCampaignShop(
                self._campaign._type,
                self._campaign._id,
                function()
                    local uiParams = {}
                    uiParams[1] = self._activityConst
                    self._campaign._campaign_module:CampaignSwitchState(
                        true, 
                        UIStateType.UIN25Line,
                        UIStateType.UIMain,
                        uiParams,
                        self._campaign._id,
                        componentId
                    )
                end,
                self._activityConst
            )
        end
    )
end

function UIN25Line.GetItemCountStr(count, preColor, countColor)
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

function UIN25Line:FlushNodes()
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
    local showMission = {}
    local levelCount, lineCount = 0, 0
    if next(self._line_info.m_pass_mission_info) then
        for missionID, passInfo in pairs(self._line_info.m_pass_mission_info) do
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

    self._nodesPool:SpawnObjects("UIN25LineMapNode", levelCount)
    local nodes = self._nodesPool:GetAllSpawnList()
    self._linesPool:SpawnObjects("UIN25LineMapLine", lineCount)
    ---@type table<number,UIN25LineMapLine>
    local lines = self._linesPool:GetAllSpawnList()
    local nodeIdx, lineIdx = 1, 1
    for missionID, cfg in pairs(showMission) do
        ---@type UIN25LineMapNode
        local uiNode = nodes[nodeIdx]
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
            ---@type UIN25LineMapLine
            local line = lines[lineIdx]
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
    local sp1, sp2 = 8, 12
    local bgLoader1 = self:GetUIComponent("RawImageLoader", "bg1")
    local bgLoader2 = self:GetUIComponent("RawImageLoader", "bg2")
    --28个路点分成3段,有两个分割点,可能会经常改动
    ---@type UILevelScroller
    self._scroller =
        UILevelScroller:New(
        self._contentRect,
        bgLoader1,
        bgLoader2,
        {
            "n25_xxg_bg01",
            "n25_xxg_bg02",
            "n25_xxg_bg03"
        },
        {
            posx[sp1],
            posx[sp1 + 1],
            posx[sp2],
            posx[sp2 + 1]
        }
    )
    self._scrollRect.onValueChanged:AddListener(
        function()
            self._scroller:OnChange()
        end
    )
    self._allMissionCfgs = missionCfgs
end

function UIN25Line:OnNodeClick(stageId, isStory, worldPos)
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
        local moveLockName = "UIActivityLineMissionController_MoveToStage"
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

function UIN25Line:_EnterStage(stageId, worldPos)
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    self._shot:CleanRenderTexture()
    local rt = self._shot:RefreshBlurTexture()
    local scale = 1.3
    local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local screenPos = camera:WorldToScreenPoint(worldPos)
    local offset =
        -(Vector2(screenPos.x, screenPos.y) - Vector2(UnityEngine.Screen.width, UnityEngine.Screen.height) / 2)
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
        pointComponent
        --行动点组件
    )
end

function UIN25Line:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        -- self:SwitchState(UIStateType.UIN25Line)
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
                            self:SwitchState(UIStateType.UIN25Line, self._activityConst)
                        end
                    )
                else
                    self:SwitchState(UIStateType.UIN25Line, self._activityConst)
                end
            end
        end,
        self
    )
end

function UIN25Line:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIN25Line:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

--region AttachEvent
function UIN25Line:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIN25Line:DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIN25Line:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN25Line:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end
--endregion

--region Helper
function UIN25Line:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIN25Line:_SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIN25Line:_SetText(widgetName, str)
    widgetName = widgetName or "text"

    ---@type UILocalizationText
    local obj = self:GetUIComponent("UILocalizationText", widgetName)
    obj:SetText(str)
end
--endregion

---@return string, number
function UIN25Line:GetSpineAndBgm()
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