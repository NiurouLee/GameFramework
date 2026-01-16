---@class UIActivityN20NormalLevel:UIController
_class("UIActivityN20NormalLevel", UIController)
UIActivityN20NormalLevel = UIActivityN20NormalLevel

function UIActivityN20NormalLevel:Constructor()
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityN20NormalLevel:LoadDataOnEnter(TT, res, uiParams)
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
        self._line_component = self._campaign:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_COMMON)
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

function UIActivityN20NormalLevel:OnShow(uiParams)
    self:AttachEvent(GameEventType.N20RefreshShopBtnStatus, self.ForceRefresh)
    self._isNormalUI = uiParams[1] and true
    self._shopIconLoader = self:GetUIComponent("RawImageLoader", "ShopIcon")
    self._shopCountLabel = self:GetUIComponent("UILocalizationText", "ShopCount")
    self._shopRed = self:GetGameObject("ShopRed")
    self._isOpen = true
    self._timerHolder = UITimerHolder:New()

    UIActivityN20NormalLevel.SLeval = 999 --s关枚举id
    UIActivityN20NormalLevel.Passed = 888 --通关后文本和阴影颜色
    UIActivityN20NormalLevel.NodeCfg = {
        [DiscoveryStageType.FightNormal] = {
            [1] = {
                normal = "n20_xxg_norm",
                press = "n20_xxg_norm",
                lock = "n20_xxg_norm",
                textColor = Color(0 / 0, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255, 10 / 255),
                normalStar = "n20_xxg_star1",
                passStar = "n20_xxg_star2"
            }
        },
        [DiscoveryStageType.FightBoss] = {
            [1] = {
                normal = "n20_xxg_boss",
                press = "n20_xxg_boss",
                lock = "n20_xxg_boss",
                textColor = Color(246 / 255, 246 / 255, 246 / 255),
                textShadow = Color(255 / 255, 255 / 255, 255 / 255, 10 / 255),
                normalStar = "n20_xxg_star1",
                passStar = "n20_xxg_star2"
            }
        },
        [DiscoveryStageType.Plot] = {
            [1] = {
                normal = "n20_xxg_plot",
                press = "n20_xxg_plot",
                lock = "n20_xxg_plot",
                textColor = Color(0 / 0, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255, 10 / 255)
            }
        },
        [UIActivityN20NormalLevel.SLeval] = {
            [1] = {
                normal = "n20_xxg_knot",
                press = "n20_xxg_knot",
                lock = "n20_xxg_knot",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(255 / 255, 255 / 255, 255 / 255, 10 / 255),
                normalStar = "n20_xxg_star1",
                passStar = "n20_xxg_star2"
            }
        }
    }

    self:AttachEvents()
    self:InitWidget()

    local componentCfgId = self._line_component:GetComponentCfgId()

    self:FlushNodes()
    self:RefreshCountdown()
    self:RefreshTryout()

    -- 进场锁定
    local lockName = "UINP7Level_OnShow"
    self:Lock(lockName)
    self._timerHolder:StartTimer(
        lockName,
        500,
        function()
            self:UnLock(lockName)
        end
    )

    self:InitUI()
end

function UIActivityN20NormalLevel:OnHide()
    self:DetachEvent(GameEventType.N20RefreshShopBtnStatus, self.ForceRefresh)
    UIActivityN20NormalLevel.SLeval = nil
    UIActivityN20NormalLevel.NodeCfg = nil
    self._isOpen = false
    self._timerHolder:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIActivityN20NormalLevel.super:Dispose()
    self._scroller:Dispose()
end

function UIActivityN20NormalLevel:ForceRefresh()
    self:StartTask(self.ReloadData, self)
end

function UIActivityN20NormalLevel:ReloadData(TT)
    self:Lock("UIActivityN20NormalLevel_ReloadData")
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._activityConst:LoadData(TT, res)
    self:InitUI()
    self:UnLock("UIActivityN20NormalLevel_ReloadData")
end

function UIActivityN20NormalLevel:InitWidget()
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
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "MapContent")
    self._mapContentRect = self:GetUIComponent("RectTransform", "MapContent")
    self._contentRect = self:GetUIComponent("RectTransform", "Content")

    ---@type UICustomWidgetPool
    self._linesPool = self:GetUIComponent("UISelectObjectPath", "Lines")
    self._nodesPool = self:GetUIComponent("UISelectObjectPath", "Nodes")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")

    self._tryOutTip = self:GetGameObject("RedPoint")

    --安全区宽度,没有找到框架的接口,直接从RectTransform上取
    self._safeAreaSize = self:GetUIComponent("RectTransform", "SafeArea").rect.size
    self._shot.width = self._safeAreaSize.x
    self._shot.height = self._safeAreaSize.y
end

function UIActivityN20NormalLevel:RefreshCountdown()
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

function UIActivityN20NormalLevel:GetFormatTimerStr(time, id)
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
        timeStr = "<color=#f7d771>" .. day .. "</color>" .. StringTable.Get(id.day) .. "<color=#f7d771>" .. hour .. "</color>" .. StringTable.Get(id.hour)
    elseif hour > 0 then
        timeStr = "<color=#f7d771>" .. hour .. "</color>" .. StringTable.Get(id.hour) .. "<color=#f7d771>" .. min .. "</color>" .. StringTable.Get(id.min)
    elseif min > 0 then
        timeStr = "<color=#f7d771>" .. min .. "</color>" .. StringTable.Get(id.min)
    else
        timeStr = "<color=#f7d771>" .. StringTable.Get(id.zero) .. "</color>"
    end
    return StringTable.Get("str_n20_level_remain_time_tips", timeStr)
end

function UIActivityN20NormalLevel:RefreshTryout()
    ---@type LineMissionComponent
    local cmp = self._campaign:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_FIXTEAM)
    --- @type LineMissionComponentInfo
    local cmpInfo = cmp:GetComponentInfo()
    local passInfo = cmpInfo.m_pass_mission_info or {}
    self._isTryoutLevelPass = function(mid)
        return passInfo[mid] ~= nil
    end
    local tryOutRed = self._campaign:CheckComponentRed(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_FIXTEAM)
    self._tryOutTip:SetActive(tryOutRed)
end

function UIActivityN20NormalLevel:FlushNodes()
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
            if not showMission[missionID] and missionCfgs[missionID] then
                showMission[missionID] = missionCfgs[missionID]
                levelCount = levelCount + 1
            end
            if unlockInfo[missionID] then
                for id, cfg in pairs(unlockInfo[missionID]) do
                    if not showMission[id] and missionCfgs[missionID] then
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

    if table.count(showMission) <= 0 then
        showMission[firstMissionID] = missionCfgs[firstMissionID]
        levelCount = 1
    end

    self._nodesPool:SpawnObjects("UIActivityN20NormalLevelNode", levelCount)
    local nodes = self._nodesPool:GetAllSpawnList()
    self._linesPool:SpawnObjects("UIActivityN20NormalLevelLine", lineCount)
    ---@type table<number,UIActivityN20NormalLevelNode>
    local lines = self._linesPool:GetAllSpawnList()

    local nodeIdx, lineIdx = 1, 1
    for missionID, cfg in pairs(showMission) do
        ---@type UIActivityN20NormalLevelNode
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
            ---@type UIActivityN20NormalLevelNode
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
    local sp1, sp2 = 4, 8
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
            "n20_xxg_bg1",
            "n20_xxg_bg1",
            "n20_xxg_bg1"
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

function UIActivityN20NormalLevel:_onNodeClick(stageId, isStory, worldPos)
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
        local moveLockName = "UINP6Level_MoveToStage"
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

function UIActivityN20NormalLevel:_EnterStage(stageId, worldPos)
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

function UIActivityN20NormalLevel:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIActivityN20NormalLevel:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

function UIActivityN20NormalLevel:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        -- self:SwitchState(UIStateType.UIActivityN20NormalLevel)
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
                            self:SwitchState(UIStateType.UIActivityN20NormalLevel)
                        end
                    )
                else
                    self:SwitchState(UIStateType.UIActivityN20NormalLevel)
                end
            end
        end,
        self
    )
end
function UIActivityN20NormalLevel:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIActivityN20NormalLevel:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityN20NormalLevel:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end

--endregion

--region help
function UIActivityN20NormalLevel:_ShowUIGetItemController(rewards)
    self:ShowDialog(
        "UIGetItemController",
        rewards,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        end
    )
end
--endregion

function UIActivityN20NormalLevel:TryoutButtonOnClick()
    if not self._isValid then
        ToastManager.ShowToast(StringTable.Get("str_activity_error_110"))
        return
    end
    self:ShowDialog(
        "UIActivityPetTryController",
        ECampaignType.CAMPAIGN_TYPE_N20,
        ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_FIXTEAM,
        self._isTryoutLevelPass,
        function(missionid)
            ---@type TeamsContext
            local ctx = self._missionModule:TeamCtx()
            local localProcess = self._campaign:GetLocalProcess()
            local missionComponent = localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_FIXTEAM)
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

function UIActivityN20NormalLevel:InitUI()
    self:RefreshShopRedAndNew()
    ---@type ExchangeItemComponent
    local shopCom, _ = self._activityConst:GetShopComponent()
    local icon, count = shopCom:GetCostItemIconText()
    self._shopIconLoader:LoadImage(icon)
    self._shopCountLabel:SetText(UIActivityN20MainController.GetItemCountStr(count, "#8D8D8D", "#ffd146"))
end

--商店红点和NEW
function UIActivityN20NormalLevel:RefreshShopRedAndNew()
    if self._activityConst:IsShowShopNew() then
        self._shopRed:SetActive(true)
        return
    end
    self._shopRed:SetActive(false)
end

function UIActivityN20NormalLevel:ShopOnClick()
    if not self._activityConst:IsShopEnable() then
        ToastManager.ShowToast(StringTable.Get("str_n20_activity_end"))
        return
    end

    self._activityConst:ClearShopNew()
    self:RefreshShopRedAndNew()
    self:ShowDialog("UIActivityN20Shop")
end
