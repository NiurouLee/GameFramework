---@class UIActivityN5SimpleLevelReview:UIController
_class("UIActivityN5SimpleLevelReview", UIController)
UIActivityN5SimpleLevelReview = UIActivityN5SimpleLevelReview

function UIActivityN5SimpleLevelReview:Constructor()
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)

    ---@type UIActivityN5LineMissionManager
    self._lineMissionManager = UIActivityN5LineMissionManager:New()
    -- self._lineMissionManager = UIActivityLineMissionManager:New()
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityN5SimpleLevelReview:LoadDataOnEnter(TT, res, uiParams)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_REVIEW_N5,
        ECampaignReviewN5ComponentID.ECAMPAIGN_REVIEW_ReviewN5_LINE_MISSION,
        ECampaignReviewN5ComponentID.ECAMPAIGN_REVIEW_ReviewN5_POINT_PROGRESS
    )

    -- UIActivityEveSinsaSwitchLevelBtn:_CheckUnlockLevel() 中的 componet:ComponentIsUnLock()
    -- 需要强制更新数据
    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    if res and res:GetSucc() then
        ---@type LineMissionComponent
        self._line_component = self._campaign:GetComponent(ECampaignReviewN5ComponentID.ECAMPAIGN_REVIEW_ReviewN5_LINE_MISSION)
        --- @type LineMissionComponentInfo
        self._line_info = self._line_component:GetComponentInfo()
        local simpleOpenTime = self._line_info.m_unlock_time
        local simpleCloseTime = self._line_info.m_close_time
        local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
        --不在开放时段内
        if now < simpleOpenTime then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
            campaignModule:ShowErrorToast(res.m_result, true)
            return
        elseif now > simpleCloseTime then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
            campaignModule:ShowErrorToast(res.m_result, true)
            return
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end
function UIActivityN5SimpleLevelReview:OnShow(uiParams)
    self._isOpen = true
    if uiParams then
        if uiParams[1] then
            if uiParams[1][2] then--获胜
                self._fromMissionResult = uiParams[1][3]
            end
        end
    end
    UIActivityN5SimpleLevel.SLeval = 999 --s关枚举id
    UIActivityN5SimpleLevel.Passed = 888 --通关后文本和阴影颜色
    UIActivityN5SimpleLevel.NodeCfg = {
        [DiscoveryStageType.FightNormal] = {
            [1] = {
                normal = "n5_map_normal",
                press = "n5_map_normal1",
                lock = "n5_map_normal1",
                textColor = Color(0 / 255, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255),
                normalStar = "n5_map_touming",
                passStar = "n5_map_badge"
            }, --普通样式
            [2] = {
                normal = "n5_map_boss",
                press = "n5_map_boss1",
                lock = "n5_map_boss1",
                textColor = Color(218 / 255, 218 / 255, 218 / 255),
                textShadow = Color(218 / 255, 218 / 255, 218 / 255),
                normalStar = "n5_map_touming",
                passStar = "n5_map_badge"
            } --高难样式
        },
        [DiscoveryStageType.FightBoss] = {
            [1] = {
                normal = "n5_map_boss",
                press = "n5_map_boss1",
                lock = "n5_map_boss1",
                textColor = Color(218 / 255, 218 / 255, 218 / 255),
                textShadow = Color(218 / 255, 218 / 255, 218 / 255),
                normalStar = "n5_map_touming",
                passStar = "n5_map_badge"
            }, --普通样式
            [2] = {
                normal = "n5_map_boss",
                press = "n5_map_boss1",
                lock = "n5_map_boss1",
                textColor = Color(218 / 255, 218 / 255, 218 / 255),
                textShadow = Color(218 / 255, 218 / 255, 218 / 255),
                normalStar = "n5_map_touming",
                passStar = "n5_map_badge"
            } --高难样式
        },
        [DiscoveryStageType.Plot] = {
            [1] = {
                normal = "n5_map_plot",
                press = "n5_map_plot1",
                lock = "n5_map_plot1",
                textColor = Color(0 / 255, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255)
            }, --普通样式
            [2] = {
                normal = "n5_map_plot",
                press = "n5_map_plot1",
                lock = "n5_map_plot1",
                textColor = Color(0 / 255, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255)
            } --高难样式
        },
        [UIActivityN5SimpleLevel.SLeval] = {
            [1] = {
                normal = "n5_map_normal",
                press = "n5_map_normal1",
                lock = "n5_map_normal1",
                textColor = Color(0 / 255, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255),
                normalStar = "n5_map_touming",
                passStar = "n5_map_badge"
            }, --普通样式
            [2] = {
                normal = "n5_map_normal",
                press = "n5_map_normal1",
                lock = "n5_map_normal1",
                textColor = Color(0 / 255, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255),
                normalStar = "n5_map_touming",
                passStar = "n5_map_badge"
            } --高难样式
        }
    }

    self:AttachEvents()
    self:_GetComponents()

    local componentCfgId = self._line_component:GetComponentCfgId()
    self._lineMissionManager:Init(self._line_info, componentCfgId)

    self._lineMissionManager:Update()
    self:Flush()

    -- 进场锁定
    self._enterLockName = "UIActivityN5SimpleLevelReview_OnShow"
    self._enterLockTimeEvent = UIActivityHelper.StartLockEvent(self._enterLockName, self._enterLockTimeEvent, nil)
    local bgLoader1 = self:GetUIComponent("RawImageLoader", "bg1")
    local bgLoader2 = self:GetUIComponent("RawImageLoader", "bg2")

    local bgNames = {
        "n5_map_bg",
        "n5_map_bg2"
    }
    ---@type UIActivityN5Scroller
    self._scroller =
        UIActivityN5Scroller:New(self._contentRect, bgLoader1, bgLoader2,bgNames,self._lineMissionManager:GetScrollSpliterVec())

    self._scrollRect.onValueChanged:AddListener(
        function()
            self._scroller:OnChange()
        end
    )
    CutsceneManager.ExcuteCutsceneOut()
end
function UIActivityN5SimpleLevelReview:OnHide()
    -- 进场锁定
    UIActivityHelper.CancelLockEvent(self._enterLockName, self._enterLockTimeEvent)

    -- 移动关卡锁定
    UIActivityHelper.CancelLockEvent(self._moveLockName, self._moveLockTimeEvent)

    if self._countdownTimer then
        GameGlobal.Timer():CancelEvent(self._countdownTimer)
        self._countdownTimer = nil
    end

    if self._pointCountdownTimer then
        GameGlobal.Timer():CancelEvent(self._pointCountdownTimer)
        self._pointCountdownTimer = nil
    end

    UIActivityN5SimpleLevelReview.SLeval = nil
    UIActivityN5SimpleLevelReview.NodeCfg = nil

    self._isOpen = false
end

--region MissionNode
function UIActivityN5SimpleLevelReview:Flush()
    self:FlushPanel()
    self:FlushNodes()
    self:FlushLines()
   -- self:RefreshCountdown()
   -- self:RefreshTryout()
end

function UIActivityN5SimpleLevelReview:Dispose()
    -- self._data = nil

    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIActivityN5SimpleLevelReview.super:Dispose()
end

function UIActivityN5SimpleLevelReview:_GetComponents()
    -- self._screenShotBg = self:GetUIComponent("RawImage", "ScreenShotBg")
    -- self._screenShotBgGo = self:GetGameObject("ScreenShotBg")
    -- self._tmpBgGo = self:GetGameObject("TmpBg")
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:_Close()
        end,
        nil,
        function()--返回主界面不播放退出动效
            --self._transition:ChangeAnim("",0)
            self:SwitchState(UIStateType.UIMain)
        end
    )
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "MapContent")
    self._mapContentRect = self:GetUIComponent("RectTransform", "MapContent")
    self._contentRect = self:GetUIComponent("RectTransform", "Content")

    ---@type UICustomWidgetPool
    self._linesPool = self:GetUIComponent("UISelectObjectPath", "Lines")
    ---@type UICustomWidgetPool
    self._normalNodesPool = self:GetUIComponent("UISelectObjectPath", "NormalNodes")
    ---@type UICustomWidgetPool
    self._bossNodesPool = self:GetUIComponent("UISelectObjectPath", "BossNodes")
    ---@type UICustomWidgetPool
    self._plotNodesPool = self:GetUIComponent("UISelectObjectPath", "PlotNodes")
    ---@type UICustomWidgetPool
    -- self._notReachNodesPool = self:GetUIComponent("UISelectObjectPath", "NotReachNodes")
    ---@type UICustomWidgetPool
    self._slevelNodesPool = self:GetUIComponent("UISelectObjectPath", "SLevelNodes")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")

  --  self._tryOutTip = self:GetGameObject("UICommonRedPoint")

    -- self._TryoutButtonGO = self:GetGameObject("TryoutButton")
    -- self._TryoutButtonCoverImgGo = self:GetGameObject("TryoutButtonCoverImg")

    --安全区宽度,没有找到框架的接口,直接从RectTransform上取
    self._safeWidth = self:GetUIComponent("RectTransform", "SafeArea").rect.size.x

    --self._transition = self:GetUIComponent("ATransitionComponent", "UIActivityN5SimpleLevelReview")
    --self._anim = self:GetUIComponent("Animation", "UIActivityN5SimpleLevelReview")
    --self._anim.enabled = true
    --self._transition:ChangeAnim("uieff_N5_SimpleLevel_In",21)--为了剧情关 点完奖励重进N5SimpleLevel时的入场出场动效 --动效处理，避免连续播放退出和进入动效，只保留进入动效
end
function UIActivityN5SimpleLevelReview:_Close()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N5CloseDoor)
    CutsceneManager.ExcuteCutsceneIn(UIStateType.UIActivityN5,
        function ()
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CampaignSwitchState(
                true,
                UIStateType.UIN5MainController_Review,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
        end
    )
end

-- function UIActivityN5SimpleLevelReview:RefreshCountdown()
--     self._time = self:GetUIComponent("UILocalizationText", "time")
--     local closeTime = self._line_info.m_close_time

--     --普通关组件是否开放，倒计时到0后关闭
--     self._isValid = true

--     local function countDown()
--         local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
--         local time = math.ceil(closeTime - now)
--         local timeStr = self:_GetRemainTime(time)
--         --UIActivityHelper.GetFormatTimerStr(time)
--         local showStr = StringTable.Get("str_n5_line_mission_ramaining_time", self:_GetRemainTime(time))
--         if self._timeString ~= showStr then
--             --self._time:RefreshText(showStr)
--             self._time:SetText(showStr)
--             self._timeString = showStr
--         end

--         if time < 0 and self._countdownTimer then
--             GameGlobal.Timer():CancelEvent(self._countdownTimer)
--             self._countdownTimer = nil
--             self._isValid = false
--         end
--     end
--     countDown()
--     if self._countdownTimer then
--         GameGlobal.Timer():CancelEvent(self._countdownTimer)
--         self._countdownTimer = nil
--     end
--     self._countdownTimer = GameGlobal.Timer():AddEventTimes(1000, TimerTriggerCount.Infinite, countDown)
-- end

-- function UIActivityN5SimpleLevelReview:_GetRemainTime(time)
--     local day, hour, minute
--     day = math.floor(time / 86400)
--     hour = math.floor(time / 3600) % 24
--     minute = math.floor(time / 60) % 60
--     local timestring = ""
--     if day > 0 then
--         timestring =
--             "<color=#E03D22>" ..
--             day ..
--                 "</color>" ..
--                     StringTable.Get("str_activity_common_day") ..
--                         "<color=#E03D22>" .. hour .. "</color>" .. StringTable.Get("str_activity_common_hour")
--     elseif hour > 0 then
--         timestring =
--             "<color=#E03D22>" ..
--             hour ..
--                 "</color>" ..
--                     StringTable.Get("str_activity_common_hour") ..
--                         "<color=#E03D22>" .. minute .. "</color>" .. StringTable.Get("str_activity_common_minute")
--     elseif minute > 0 then
--         timestring = "<color=#E03D22>" .. minute .. "</color>" .. StringTable.Get("str_activity_common_minute")
--     else
--         timestring = StringTable.Get("str_activity_common_less_minute")
--     end
--     return string.format(StringTable.Get("str_activity_common_over"), timestring)
-- end

-- function UIActivityN5SimpleLevelReview:RefreshTryout()
--     ---@type LineMissionComponent
--     local cmp = self._campaign:GetComponent(ECampaignN5ComponentID.ECAMPAIGN_N5_LINE_MISSION_FIXTEAM)
--     --- @type LineMissionComponentInfo
--     local cmpInfo = cmp:GetComponentInfo()

--     local cmpID = cmp:GetComponentCfgId()
--     local newConfig = {}
--     local missionCfgs = Cfg.cfg_component_line_mission {ComponentID = cmpID}
--     for _, v in ipairs(missionCfgs) do
--         newConfig[v.CampaignMissionId] = v
--     end
--     local passInfo = cmpInfo.m_pass_mission_info or {}
--     self._isTryoutLevelPass = function(mid)
--         return passInfo[mid] ~= nil
--     end
--     local allPass = true
--     for id, value in pairs(newConfig) do
--         if not self._isTryoutLevelPass(id) then
--             allPass = false
--             break
--         end
--     end
--     self._tryOutTip:SetActive(not allPass)
-- end

function UIActivityN5SimpleLevelReview:FlushPanel()
    -- Set Width
    local totalWidth = self._lineMissionManager:GetTotalWidth()
    self._contentRect.sizeDelta = Vector2(totalWidth, self._contentRect.sizeDelta.y)
    self._contentRect.anchoredPosition = Vector2(self._safeWidth / 2 - totalWidth, 0)

    -- Set Scroll
    -- local curMission = self._line_info.m_cur_mission
    -- local scrollPos = self._lineMissionManager:GetScrollPos(curMission)
    -- if scrollPos then
    --     self._contentRect.anchoredPosition = scrollPos
    -- end
end

---只刷当前章节路点
function UIActivityN5SimpleLevelReview:FlushNodes()
    local normalNodeCount, bossNodeCount, plotNodeCount, slevelNodeCount = 0, 0, 0, 0
    local normalNodeIndex, bossNodeIndex, plotNodeIndex, slevelNodeIndex = 1, 1, 1, 1

    ---@type table<number, UIActivityMissionNodeInfo>
    local missionNodes = self._lineMissionManager:GetNodes()
    for i, node in pairs(missionNodes) do
        if node.isSLevel then
            slevelNodeCount = slevelNodeCount + 1
        elseif node.type == DiscoveryStageType.FightNormal then
            normalNodeCount = normalNodeCount + 1
        elseif node.type == DiscoveryStageType.FightBoss then
            bossNodeCount = bossNodeCount + 1
        else
            plotNodeCount = plotNodeCount + 1
        end
    end

    self._normalNodesPool:SpawnObjects("UIActivityN5MissionNode", normalNodeCount)
    self._bossNodesPool:SpawnObjects("UIActivityN5MissionNode", bossNodeCount)
    self._plotNodesPool:SpawnObjects("UIActivityN5MissionNode", plotNodeCount)
    self._slevelNodesPool:SpawnObjects("UIActivityN5MissionNode", slevelNodeCount)

    local normalNodes = self._normalNodesPool:GetAllSpawnList()
    local bossNodes = self._bossNodesPool:GetAllSpawnList()
    local plotNodes = self._plotNodesPool:GetAllSpawnList()
    local slevelNodes = self._slevelNodesPool:GetAllSpawnList()

    self._uiMapNodes = {}
    for i, node in pairs(missionNodes) do
        -- -@type UIActivityMissionNode
        ---@type UIActivityN5MissionNode
        local uiNode = nil
        if node.isSLevel then
            uiNode = slevelNodes[slevelNodeIndex]
            slevelNodeIndex = slevelNodeIndex + 1
        elseif node.type == DiscoveryStageType.FightNormal then
            uiNode = normalNodes[normalNodeIndex]
            normalNodeIndex = normalNodeIndex + 1
        elseif node.type == DiscoveryStageType.FightBoss then
            uiNode = bossNodes[bossNodeIndex]
            bossNodeIndex = bossNodeIndex + 1
        else
            uiNode = plotNodes[plotNodeIndex]
            plotNodeIndex = plotNodeIndex + 1
        end

        -- uiNode:Init(node, self._data.showUIStage)
        uiNode:SetData(
            node,
            function(stageId, needScroll, trans)
                self:_MoveToStage(stageId, needScroll, trans)
            end,
            self._fromMissionResult
        )

        self._uiMapNodes[#self._uiMapNodes + 1] = uiNode
    end
    self._fromMissionResult = nil
end

function UIActivityN5SimpleLevelReview:FlushLines()
    local lines = self._lineMissionManager:GetLines()
    local len = table.count(lines)
    if not lines or len <= 0 then
        return
    end
    -- self._linesShadowPool:SpawnObjects("UIMapPathItem", len)
    self._linesPool:SpawnObjects("UIActivityN5MissionLine", len)
    ---@type table<number,UIActivityN5MissionLine>
    local spawnLines = self._linesPool:GetAllSpawnList()
    local i = 1
    for k, v in ipairs(lines) do
        local sNode = v[1]
        local eNode = v[2]
        spawnLines[i]:Flush(sNode, eNode, false)
        i = i + 1
    end
end
--endregion

--region EntryStage
function UIActivityN5SimpleLevelReview:ShotTest()
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local shotRect = self:GetUIComponent("RectTransform", "screenShot")
    self._width = shotRect.rect.width
    self._height = shotRect.rect.height

    local LeftTop = self:GetGameObject("LeftTop")
    local LeftBottom = self:GetGameObject("LeftBottom")
    local RightTop = self:GetGameObject("RightTop")
    local RightBottom = self:GetGameObject("RightBottom")

    LeftTop:SetActive(false)
    LeftBottom:SetActive(false)
    RightTop:SetActive(false)
    RightBottom:SetActive(false)

    self._shot.width = self._width
    self._shot.height = self._height
    self._shot.blurTimes = 0

    self._shot:CleanRenderTexture()
    self._rt = self._shot:RefreshBlurTexture()

    LeftTop:SetActive(true)
    LeftBottom:SetActive(true)
    RightTop:SetActive(true)
    RightBottom:SetActive(true)
end

function UIActivityN5SimpleLevelReview:_CalcShotOffset(trans)
    local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local screenPos = camera:WorldToScreenPoint(trans.position)
    return -(Vector2(screenPos.x, screenPos.y) - Vector2(UnityEngine.Screen.width, UnityEngine.Screen.height) / 2)
    -- -- 计算截图中被选中节点显示在中心所需要的位移
    -- local mapX = self._mapContentRect.rect.x -- 得到屏幕区域的 x （1920宽，居中就是 -960）
    -- local contentX = self._contentRect.anchoredPosition.x -- 得到滑动区域目前位置
    -- local contentWidth = self._contentRect.rect.width -- 滑动区域宽度

    -- local extraCfg = self._lineMissionManager:GetLineExtraConfig()
    -- local nodeLeft = extraCfg._NodeWidthLeft -- 节点 tip 的宽度
    -- local nodeRight = extraCfg._NodeWidthRight

    -- local offsetScroll = contentX - mapX -- 滑动列表滑动时产生的位移
    -- local offsetCenter = mapX + contentWidth / 2 -- 滑动区域中心点和屏幕中心点的位移
    -- local offsetNodeWidth = (nodeLeft + nodeRight) / 2 - nodeLeft -- 使节点 tip 在屏幕中心

    -- -- 节点位置最终在屏幕的位置
    -- local finalPosX = -(nodeX + offsetScroll + offsetCenter + offsetNodeWidth)
    -- local finalPosY = -nodeY
    -- return Vector2(finalPosX, finalPosY)
end

function UIActivityN5SimpleLevelReview:_MoveToStage(stageId, needScroll, trans)
    -- Set Scroll
    local pos = self._lineMissionManager:GetScrollPos(stageId).x
    local curPos = self._contentRect.anchoredPosition.x
    local areaWidth = 408
    local halfScreen = self._safeWidth / 2
    local targetPos = nil
    if needScroll then
        if curPos < pos - (halfScreen - areaWidth) then
            targetPos = pos - (halfScreen - areaWidth)
        elseif curPos > pos + (halfScreen - areaWidth) then
            targetPos = pos + (halfScreen - areaWidth)
        end
    end
    if targetPos then
        self._scrollRect:StopMovement()
        if self._tweener then
            self._tweener:Kill()
        end
        local moveTime = 0.5
        self._tweener = self._contentRect:DOAnchorPosX(targetPos, moveTime)

        -- 移动关卡锁定
        self._moveLockName = "UIActivityN5SimpleLevelReview_MoveToStage"
        self._moveLockTimeEvent =
            UIActivityHelper.StartLockEvent(
            self._moveLockName,
            self._moveLockTimeEvent,
            function()
                self:_EnterStage(stageId, trans) -- 移动后，进入关卡
            end,
            moveTime * 1000
        )
    else
        self:_EnterStage(stageId, trans) --直接进入
    end
end

function UIActivityN5SimpleLevelReview:_EnterStage(stageId, trans)
    local nodes = self._lineMissionManager:GetNodes()
    local node = nodes[stageId]

    local stageType = node.type
    if stageType == DiscoveryStageType.Plot then
        self:CloseUIStage()

        local titleId = StringTable.Get(node.title)
        local titleName = StringTable.Get(node.name)
        local storyId = self._missionModule:GetStoryByStageIdStoryType(stageId, StoryTriggerType.Node)

        self:ShowDialog(
            "UIActivityPlotEnter",
            titleId,
            titleName,
            storyId,
            function()
                self:PlotEndCallback(stageId)
            end
        )
    else
       -- self:ShotTest()
        local passInfo = self._line_info.m_pass_mission_info[stageId]
        --local extraCfg = self._lineMissionManager:GetLineExtraConfig()
        --local scale = extraCfg._Scale
        --local offset = self:_CalcShotOffset(trans)
       -- local autoFightShow = self:_CheckSerialAutoFightShow(stageType, stageId)

        self:ShowDialog(
            "UIActivityLevelStageNew",
            stageId,
            passInfo,
            self._line_component,        
            false,
            nil, --行动点组件
            true, --隐藏顶条
            true --隐藏体力图标
        )
    end
end

function UIActivityN5SimpleLevelReview:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIActivityN5SimpleLevelReview:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

function UIActivityN5SimpleLevelReview:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        return
    end

    self:StartTask(
        function(TT)
            self._line_component:SetMissionStoryActive(TT, stageId, ActiveStoryType.ActiveStoryType_BeforeBattle)

            local res = AsyncRequestRes:New()
            local award = self._line_component:HandleCompleteStoryMission(TT, res, stageId)
            if not res:GetSucc() then
                local campaignModule = self:GetModule(CampaignModule)
                campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
            else
                if table.count(award) ~= 0 then
                    self:ShowDialog(
                        "UIGetItemController",
                        award,
                        function()
                            --self._anim.enabled = true --动效处理，避免连续播放退出和进入动效，只保留进入动效
                            --self._transition:ChangeAnim("",0)
                            self:SwitchState(UIStateType.UIActivityN5SimpleLevelReview)
                        end
                    )
                else
                    --self._anim.enabled = true--动效处理，避免连续播放退出和进入动效，只保留进入动效
                    --self._transition:ChangeAnim("",0)
                    self:SwitchState(UIStateType.UIActivityN5SimpleLevelReview)
                end
            end
        end,
        self
    )
end

function UIActivityN5SimpleLevelReview:CloseUIStage()
    if GameGlobal.UIStateManager():IsShow("UIActivityN5Stage") then
        GameGlobal.UIStateManager():CloseDialog("UIActivityN5Stage")
    end
end
--endregion

--region Event
function UIActivityN5SimpleLevelReview:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    --self:AttachEvent(GameEventType.CampaignShopEnter, self._OnCampaignShopEnter)
    --self:AttachEvent(GameEventType.ActivityShopBuySuccess, self.RefreshShopCount)
end

function UIActivityN5SimpleLevelReview:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityN5SimpleLevelReview:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end

function UIActivityN5SimpleLevelReview:_OnCampaignShopEnter()
    self:CloseDialog()
end
--endregion

--region help
function UIActivityN5SimpleLevelReview:_ShowUIGetItemController(rewards)
    self:ShowDialog(
        "UIGetItemController",
        rewards,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        end
    )
end
--endregion
