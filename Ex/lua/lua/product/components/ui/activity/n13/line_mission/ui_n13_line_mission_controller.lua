---@class UIN13LineMissionController:UIController
_class("UIN13LineMissionController", UIController)
UIN13LineMissionController = UIN13LineMissionController
-------------------initial-------------------
function UIN13LineMissionController:Constructor()
    self._missionModule = self:GetModule(MissionModule)
    self._campModule = GameGlobal.GetModule(CampaignModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
end
--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN13LineMissionController:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N13
    self._componentId_LineMission = ECampaignN13ComponentID.ECAMPAIGN_N13_LINE_MISSION
    self._componentId_LineMissionFixteam = ECampaignN13ComponentID.ECAMPAIGN_N13_LEVEL_FIXTEAM

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

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

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
    ---@type CCampaignN13
    self._process = self._campModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N13)
end
function UIN13LineMissionController:OnShow(uiParams)
    self:_OnValue(uiParams)
    self:_AttachEvents()
    self:_GetComponents()
    self:_Refresh()
    self:_OnShow()
end
function UIN13LineMissionController:_OnValue(uiParams)
    self._timerHolder = UITimerHolder:New()

    UIN13LineMissionController.SLeval = 999 --s关枚举id
    UIN13LineMissionController.Passed = 888 --通关后文本和阴影颜色
    UIN13LineMissionController.NodeCfg = {
        [DiscoveryStageType.FightNormal] = {
            [1] = {
                normal = "n13_xxg_btn01",
                press = "n13_xxg_btn02",
                lock = "",
                textColor = Color(10 / 255, 11 / 255, 12 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255),
                normalStar = "",
                passStar = "n13_xxg_icon01"
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        },
        [DiscoveryStageType.FightBoss] = {
            [1] = {
                normal = "n13_xxg_btn03",
                press = "n13_xxg_btn04",
                lock = "",
                textColor = Color(239 / 255, 64 / 255, 64 / 255),
                textShadow = Color(255 / 255, 255 / 255, 255 / 255),
                normalStar = "",
                passStar = "n13_xxg_icon02"
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(238 / 255, 0 / 255, 34 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        },
        [DiscoveryStageType.Plot] = {
            [1] = {
                normal = "n13_xxg_btn09", -- TODO 按钮背景修改
                press = "n13_xxg_btn10",
                lock = "",
                textColor = Color(10 / 255, 11 / 255, 12 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255)
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255)
            } --高难样式
        },
        [UIN13LineMissionController.SLeval] = {
            [1] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(22 / 255, 42 / 255, 61 / 255),
                normalStar = "",
                passStar = ""
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(22 / 255, 42 / 255, 61 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        }
    }
end
function UIN13LineMissionController:_OnShow()
    self:_SetPetTryout_red(
        self._campaign:CheckComponentOpen(self._componentId_LineMissionFixteam) and
            self._process:GetFixMissionRedDot(self._componentId_LineMissionFixteam)
    )
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
function UIN13LineMissionController:_SetRemainingTime(widgetName, descId, endTime, tickCallback, stopCallback)
    if not self._txt_desc then
        self._txt_desc = self:GetUIComponent("UILocalizationText", "_txt_desc")
    end
    local str = "str_n13_line_mission_remaining_time"
    local remainTime = 0
    local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    local endtime = endTime
    remainTime = endtime - curtime
    self._txt_desc:SetText(StringTable.Get(str, N13ToolFunctions.GetRemainTime(remainTime)))
end
function UIN13LineMissionController:_GetComponents()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CampaignSwitchState(
                true,
                UIStateType.UIN13MainController,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
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

    self._pressup = self:GetUIComponent("RawImage", "_pressup")
    self._pressdown = self:GetUIComponent("RawImage", "_pressdown")

    self._BtnBg = {}
    self._BtnBg[self._pressup.name] = self._pressup
    self._BtnBg[self._pressdown.name] = self._pressdown
    self._pressdown.enabled = false

    UIEventTriggerListener.Get(self._pressup.gameObject).onDown = function(go)
        local rawimage = self._BtnBg[go.name]
        rawimage.enabled = false
        local rawimage = self._BtnBg[self._pressdown.name]
        rawimage.enabled = true
    end
    UIEventTriggerListener.Get(self._pressup.gameObject).onUp = function(go)
        local rawimage = self._BtnBg[go.name]
        rawimage.enabled = true
        local rawimage = self._BtnBg[self._pressdown.name]
        rawimage.enabled = false
        self:TryoutBtnOnClick()
    end
end

function UIN13LineMissionController:OnHide()
    UIN13LineMissionController.SLeval = nil
    UIN13LineMissionController.NodeCfg = nil
    self._timerHolder:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIN13LineMissionController.super:Dispose()
    self._scroller:Dispose()
end
function UIN13LineMissionController:_Refresh()
    self:FlushNodes()
    self:_SetTimeInfo()
end
function UIN13LineMissionController:_SetTimeInfo()
    local endTime = self._line_component:GetComponentInfo().m_close_time
    self:_SetRemainingTime("_remainingTimePool", nil, endTime)
end
function UIN13LineMissionController:_SetPetTryout_red(isshow)
    local pettry_red = self:GetGameObject("_pettry_red")
    pettry_red:SetActive(isshow)
end
function UIN13LineMissionController:FlushNodes()
    local cmpID = self._line_component:GetComponentCfgId()
    local extra_cfg = Cfg.cfg_component_line_mission_extra {ComponentID = cmpID}
    local extra_width = extra_cfg[1].MarginRight
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

    self._nodesPool:SpawnObjects("UIN13LineMissionMapNode", levelCount)
    local nodes = self._nodesPool:GetAllSpawnList()
    self._linesPool:SpawnObjects("UIN13LineMissionMapLine", lineCount)
    ---@type table<number,UIN13LineMissionMapLine>
    local lines = self._linesPool:GetAllSpawnList()

    local nodeIdx, lineIdx = 1, 1
    for missionID, cfg in pairs(showMission) do
        ---@type UIN13LineMissionMapNode
        local uiNode = nodes[nodeIdx]
        uiNode:SetData(
            cfg,
            self._line_info.m_pass_mission_info[missionID],
            function(stageId, isStory, worldPos)
                self:_onNodeClick(stageId, isStory, worldPos)
            end
        )
        nodeIdx = nodeIdx + 1

        if cfg.WayPointType ~= 4 and cfg.NeedMissionId ~= 0 then
            local n1 = showMission[cfg.NeedMissionId]
            local n2 = cfg
            ---@type UIN13LineMissionMapLine
            local line = lines[lineIdx]
            line:Flush(Vector2(n2.MapPosX, n2.MapPosY), Vector2(n1.MapPosX, n1.MapPosY))
            lineIdx = lineIdx + 1
        end
    end

    local right = -99999999
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
    self._scroller =
        UILevelScroller:New(
        self._contentRect,
        bgLoader1,
        bgLoader2,
        {
            "n13_xxg_bj01",
            "n13_xxg_bj01",
            "n13_xxg_bj01"
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
function UIN13LineMissionController:_onNodeClick(stageId, isStory, worldPos)
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
        local _moveTime = 0.5
        self._tweener = self._contentRect:DOAnchorPosX(targetPos, _moveTime)
        -- 移动关卡锁定
        local moveLockName = "UIActivityLineMissionController_MoveToStage"
        self:Lock(moveLockName)
        self._timerHolder:StartTimer(
            moveLockName,
            _moveTime * 1000,
            function()
                self:UnLock(moveLockName)
                self:_EnterStage(stageId, worldPos) -- 移动后，进入关卡
            end
        )
    else
        self:_EnterStage(stageId, worldPos) -- 直接进入关卡
    end
end
function UIN13LineMissionController:_EnterStage(stageId, worldPos)
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
    self:ShowDialog(
        "UIActivityLevelStage",
        stageId,
        self._line_info.m_pass_mission_info[stageId],
        self._line_component,
        rt,
        offset,
        self._safeAreaSize.x,
        self._safeAreaSize.y,
        scale,
        autoFightShow,
        pointComponent, --行动点组件
        true
    )
end
function UIN13LineMissionController:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        -- self:SwitchState(UIStateType.UIN13LineMissionController)
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
                            self:SwitchState(UIStateType.UIN13LineMissionController)
                        end
                    )
                else
                    self:SwitchState(UIStateType.UIN13LineMissionController)
                end
            end
        end,
        self
    )
end
function UIN13LineMissionController:_CheckSerialAutoFightShow(stageType, stageId)
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
-------------------AttachEvent-------------------
function UIN13LineMissionController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end
function UIN13LineMissionController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end
-------------------btn-------------------
---光灵初见
function UIN13LineMissionController:TryoutBtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    local componentId = self._componentId_LineMissionFixteam
    local component = self._campaign:GetComponent(componentId)
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
