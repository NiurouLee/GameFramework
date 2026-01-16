---@class UIActivityEveSinsaLevelAController:UIController
_class("UIActivityEveSinsaLevelAController", UIController)
UIActivityEveSinsaLevelAController = UIActivityEveSinsaLevelAController

function UIActivityEveSinsaLevelAController:_GetComponents()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CampaignSwitchState(
                true,
                UIStateType.UIActivityEveSinsaMainController,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
        end,
        nil
    )

    local exchangeRewardBtn = self:GetUIComponent("UISelectObjectPath", "_exchangeRewardBtn")
    ---@type UIActivityEveSinsaShopBtn
    self._exchangeRewardBtn = exchangeRewardBtn:SpawnObject("UIActivityEveSinsaShopBtn")
    self._exchangeRewardBtn:SetData(self._campaign)

    local secondTitle = self:GetUIComponent("UISelectObjectPath", "_secondTitle")
    ---@type UIActivityEveSinsaSecondTitle
    self._secondTitle = secondTitle:SpawnObject("UIActivityEveSinsaSecondTitle")
    self._secondTitle:SetData(self._campaign, 0)

    local petTryBtn = self:GetUIComponent("UISelectObjectPath", "PetTryBtn")
    ---@type UIActivityEveSinsaPetTryBtn
    self._petTryBtn = petTryBtn:SpawnObject("UIActivityEveSinsaPetTryBtn")
    self._petTryBtn:SetData(self._campaign)
    ------------------------------------------------------------------------------------------
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
    ---@type UICustomWidgetPool
    self._slevelNodes2Pool = self:GetUIComponent("UISelectObjectPath", "SLevelNodes2")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
    self._safeWidth = self:GetUIComponent("RectTransform", "SafeArea").rect.size.x

    self._pointCount = self:GetUIComponent("UILocalizationText", "pointCount")
    self._pointCountdown = self:GetUIComponent("UILocalizationText", "pointCountdown")
    self._pointMax = self:GetGameObject("pointMax")
    self._pointTitle = self:GetGameObject("pointTitle")
end

function UIActivityEveSinsaLevelAController:Constructor()
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)

    ---@type UIActivityLineMissionManager
    self._lineMissionManager = UIActivityLineMissionManager:New()
end

function UIActivityEveSinsaLevelAController:Dispose()
    -- self._data = nil

    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIActivityEveSinsaLevelAController.super:Dispose()
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityEveSinsaLevelAController:LoadDataOnEnter(TT, res, uiParams)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_EVERESCUEPLAN,
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_LINE_MISSION,
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_TREE_MISSION, -- 获取发散关卡倒计时用
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_MISSION_FIXTEAM,
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_ACTION_POINT
    )

    -- UIActivityEveSinsaSwitchLevelBtn:_CheckUnlockLevel() 中的 componet:ComponentIsUnLock()
    -- 需要强制更新数据
    self:_ReLoadData(TT, res)

    if res and res:GetSucc() then
        --- @type LineMissionComponent
        self._line_component =
            self._campaign:GetComponent(ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_LINE_MISSION)
        --- @type LineMissionComponentInfo
        self._line_info = self._line_component:GetComponentInfo()

        -- 活动没结束，但是关卡组件已关闭时，显示活动已关闭
        self._phase = UIActivityEveSinsaHelper.CheckTimePhase(self._campaign)
        if
            self._phase ~= EActivityEveSinsaTimePhase.EPhase_Over and
            not self._campaign:CheckComponentOpen(
                ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_LINE_MISSION -- 只检查线性关卡是否开启
            )
        then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_COMPONENT_UNLOCK
            campaignModule:ShowErrorToast(res.m_result, true)
            return
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIActivityEveSinsaLevelAController:_ReLoadData(TT, res)
    -- 强制刷新组件数据
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function UIActivityEveSinsaLevelAController:OnShow(uiParams)
    self:AttachEvents()
    self:_GetComponents()

    local componentCfgId = self._line_component:GetComponentCfgId()
    self._lineMissionManager:Init(self._line_info, componentCfgId)

    -- 特殊处理
    -- self._lineMissionManager:Update()
    local isShow, missionId = UIActivityEveSinsaHelper.CheckSpecialMissionShow(self._campaign)
    self._lineMissionManager:Update_Evesinsa(isShow, missionId)

    self:Flush()

    -- 进场锁定
    self._enterLockName = "UIActivityEveSinsaLevelAController_OnShow"
    self._enterLockTimeEvent = UIActivityHelper.StartLockEvent(self._enterLockName, self._enterLockTimeEvent, nil)
    self._isOpen = true
    self:_OpenUIRecord()
end

function UIActivityEveSinsaLevelAController:_OpenUIRecord()
    local loginModule = self:GetModule(LoginModule)
    local campaignModule = self:GetModule(CampaignModule)
    local data = campaignModule:GetEveSinsaNewFlagRedPoint()
    if data:P1SStageUnLock() then
        if LocalDB.GetInt("ACTIVITY_EVE_SINA_P1S_NEWFLAG" .. loginModule:GetRoleShowID(), 0) <= 0 then
            LocalDB.SetInt("ACTIVITY_EVE_SINA_P1S_NEWFLAG" .. loginModule:GetRoleShowID(), 1)
        end
    end
end

function UIActivityEveSinsaLevelAController:OnHide()
    self._isOpen = false
    -- 进场锁定
    UIActivityHelper.CancelLockEvent(self._enterLockName, self._enterLockTimeEvent)

    -- 移动关卡锁定
    UIActivityHelper.CancelLockEvent(self._moveLockName, self._moveLockTimeEvent)

    self:RemoveEvents()

    if self._pointCountdownTimer then
        GameGlobal.Timer():CancelEvent(self._pointCountdownTimer)
        self._pointCountdownTimer = nil
    end
end

--region MissionNode
function UIActivityEveSinsaLevelAController:Flush()
    self:FlushPanel()
    self:FlushNodes()
    self:FlushLines()
    self:RefreshPoint()
end

function UIActivityEveSinsaLevelAController:FlushPanel()
    -- Set Width
    local totalWidth = self._lineMissionManager:GetTotalWidth()
    self._contentRect.sizeDelta = Vector2(totalWidth, self._contentRect.sizeDelta.y)

    -- Set Scroll
    local curMission = self._line_info.m_cur_mission
    local scrollPos = self._lineMissionManager:GetScrollPos(curMission)
    if scrollPos then
        self._contentRect.anchoredPosition = scrollPos
    end
end

---只刷当前章节路点
function UIActivityEveSinsaLevelAController:FlushNodes()
    -- 特殊处理
    local isSpecial, missionId = UIActivityEveSinsaHelper.CheckSpecialMissionShow(self._campaign)

    local normalNodeCount, bossNodeCount, plotNodeCount, slevelNodeCount = 0, 0, 0, 0
    local normalNodeIndex, bossNodeIndex, plotNodeIndex, slevelNodeIndex = 1, 1, 1, 1

    local slevelNode2Count, slevelNode2Index = 0, 1

    ---@type table<number, UIActivityMissionNodeInfo>
    local missionNodes = self._lineMissionManager:GetNodes()
    for i, node in pairs(missionNodes) do
        if node.isSLevel and isSpecial and missionId == node.campaignMissionId then -- 特殊处理
            slevelNode2Count = slevelNode2Count + 1
        elseif node.isSLevel then
            slevelNodeCount = slevelNodeCount + 1
        elseif node.type == DiscoveryStageType.FightNormal then
            normalNodeCount = normalNodeCount + 1
        elseif node.type == DiscoveryStageType.FightBoss then
            bossNodeCount = bossNodeCount + 1
        else
            plotNodeCount = plotNodeCount + 1
        end
    end

    self._normalNodesPool:SpawnObjects("UIActivityMissionNode", normalNodeCount)
    self._bossNodesPool:SpawnObjects("UIActivityMissionNode", bossNodeCount)
    self._plotNodesPool:SpawnObjects("UIActivityMissionNode", plotNodeCount)
    self._slevelNodesPool:SpawnObjects("UIActivityMissionNode", slevelNodeCount)
    self._slevelNodes2Pool:SpawnObjects("UIActivityMissionNode", slevelNode2Count)

    ---@type UIActivityMissionNode[]
    local normalNodes = self._normalNodesPool:GetAllSpawnList()
    ---@type UIActivityMissionNode[]
    local bossNodes = self._bossNodesPool:GetAllSpawnList()
    ---@type UIActivityMissionNode[]
    local plotNodes = self._plotNodesPool:GetAllSpawnList()
    ---@type UIActivityMissionNode[]
    local slevelNodes = self._slevelNodesPool:GetAllSpawnList()
    ---@type UIActivityMissionNode[]
    local slevelNodes2 = self._slevelNodes2Pool:GetAllSpawnList()

    self._uiMapNodes = {}
    for i, node in pairs(missionNodes) do
        local uiNode = nil
        if node.isSLevel and isSpecial and missionId == node.campaignMissionId then -- 特殊处理
            uiNode = slevelNodes2[slevelNode2Index]
            slevelNode2Index = slevelNode2Index + 1
        elseif node.isSLevel then
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

        if node.isSLevel and isSpecial and missionId == node.campaignMissionId then -- 特殊处理
            uiNode:SetData(
                node,
                function(stageId, needScroll, trans)
                    -- 通关【归家之人】全部关卡后解锁
                    ToastManager.ShowToast(StringTable.Get("str_activity_evesinsa_slevel_lock"))
                end
            )
        else
            uiNode:SetData(
                node,
                function(stageId, needScroll, trans)
                    self:_MoveToStage(stageId, needScroll, trans)
                end
            )
        end

        self._uiMapNodes[#self._uiMapNodes + 1] = uiNode
    end
end

function UIActivityEveSinsaLevelAController:FlushLines()
    local lines = self._lineMissionManager:GetLines()
    local len = table.count(lines)
    if not lines or len <= 0 then
        return
    end
    -- self._linesShadowPool:SpawnObjects("UIMapPathItem", len)
    self._linesPool:SpawnObjects("UIActivityMissionLine", len)
    ---@type UIActivityMissionLine[]
    -- local spawnLinesShadows = self._linesShadowPool:GetAllSpawnList()
    ---@type UIActivityMissionLine[]
    local spawnLines = self._linesPool:GetAllSpawnList()
    local i = 1
    for k, v in ipairs(lines) do
        local sNode = v[1]
        local eNode = v[2]
        -- spawnLinesShadows[i]:Flush(sNode, eNode, true)
        spawnLines[i]:Flush(sNode, eNode, false)
        i = i + 1
    end
end

function UIActivityEveSinsaLevelAController:RefreshPoint()
    ---@type ActionPointComponent
    local cmp = self._campaign:GetComponent(ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_ACTION_POINT)
    if cmp == nil or not cmp:ComponentIsOpen() then
        Log.exception("严重错误,行动点组件已关闭!")
    end
    local cmpID = cmp:GetComponentCfgId()
    local pointCfg = cmp:GetActionPointConfig()
    local itemCfg = Cfg.cfg_item[pointCfg.ItemID]
    local count = self:GetModule(ItemModule):GetItemCount(pointCfg.ItemID)
    self._pointCount:SetText(count .. "/" .. pointCfg.RegainMax)
    if count < pointCfg.RegainMax then
        self._pointCountdown.gameObject:SetActive(true)
        self._pointTitle:SetActive(true)
        self._pointMax:SetActive(false)

        local closeTime = cmp:GetRegainEndTime()
        local countDown = function()
            local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
            local time = math.ceil(closeTime - now)
            local timeStr = HelperProxy:GetInstance():FormatTime(time)
            self._pointCountdown:SetText(timeStr)
            if time <= 0 then
                self:StartTask(self.PowerTimeUp, self)
            end
        end
        countDown()
        if self._pointCountdownTimer then
            GameGlobal.Timer():CancelEvent(self._pointCountdownTimer)
            self._pointCountdownTimer = nil
        end
        self._pointCountdownTimer = GameGlobal.Timer():AddEventTimes(1000, TimerTriggerCount.Infinite, countDown)
    else
        self._pointCountdown:SetText("MAX")
        self._pointCountdown.gameObject:SetActive(false)
        self._pointTitle:SetActive(false)
        self._pointMax:SetActive(true)
    end
end

function UIActivityEveSinsaLevelAController:PowerTimeUp(TT)
    if self._pointCountdownTimer then
        GameGlobal.Timer():CancelEvent(self._pointCountdownTimer)
        self._pointCountdownTimer = nil
    end
    local res = AsyncRequestRes:New()
    res:SetSucc(false)
    self:_ReLoadData(TT, res, self._campaign._id)
    if res:GetSucc() and self._isOpen then
        self:RefreshPoint()
    end
end

--endregion

--region EntryStage
function UIActivityEveSinsaLevelAController:ShotTest()
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

function UIActivityEveSinsaLevelAController:_CalcShotOffset(trans)
    local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local screenPos = camera:WorldToScreenPoint(trans.position)
    return -(Vector2(screenPos.x, screenPos.y) - Vector2(UnityEngine.Screen.width, UnityEngine.Screen.height) / 2)
end

function UIActivityEveSinsaLevelAController:_MoveToStage(stageId, needScroll, trans)
    -- Set Scroll
    -- local scrollPos = self._lineMissionManager:GetScrollPos(stageId)
    -- if scrollPos then
    --     self._scrollRect:StopMovement()
    --     if self._tweener then
    --         self._tweener:Kill()
    --     end
    --     local _moveTime = 0.5
    --     self._tweener = self._contentRect:DOAnchorPosX(scrollPos.x, _moveTime)

    --     -- 移动关卡锁定
    --     self._moveLockName = "UIActivityEveSinsaLevelAController_MoveToStage"
    --     self._moveLockTimeEvent =
    --         UIActivityHelper.StartLockEvent(
    --         self._moveLockName,
    --         self._moveLockTimeEvent,
    --         function()
    --             self:_EnterStage(stageId) -- 移动后，进入关卡
    --         end,
    --         _moveTime * 1000
    --     )
    -- end

    -- Set Scroll
    local pos = self._lineMissionManager:GetScrollPos(stageId).x
    local curPos = self._contentRect.anchoredPosition.x
    local areaWidth = 408  --通过截图缩放为1.3算出来的边缘位置
    self._nodeOffset = 175 --路点位置相对于中心点的偏移
    local halfScreen = self._safeWidth / 2
    local targetPos = nil
    if needScroll then
        if curPos < pos - (halfScreen - areaWidth) + self._nodeOffset then
            targetPos = pos - (halfScreen - areaWidth) + self._nodeOffset
        elseif curPos > pos + (halfScreen - areaWidth) + self._nodeOffset then
            targetPos = pos + (halfScreen - areaWidth) + self._nodeOffset
        end
    end
    if targetPos then
        self._scrollRect:StopMovement()
        if self._tweener then
            self._tweener:Kill()
        end
        local _moveTime = 0.5
        self._tweener = self._contentRect:DOAnchorPosX(targetPos, _moveTime)

        -- 移动关卡锁定
        self._moveLockName = "UIXH1SimpleLevel_MoveToStage"
        self._moveLockTimeEvent =
            UIActivityHelper.StartLockEvent(
                self._moveLockName,
                self._moveLockTimeEvent,
                function()
                    self:_EnterStage(stageId, trans) -- 移动后，进入关卡
                end,
                _moveTime * 1000
            )
    else
        self:_EnterStage(stageId, trans) --直接进入
    end
end

function UIActivityEveSinsaLevelAController:_EnterStage(stageId, trans)
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
        self:ShotTest()
        local passInfo = self._line_info.m_pass_mission_info[stageId]
        local extraCfg = self._lineMissionManager:GetLineExtraConfig()
        local scale = extraCfg._Scale
        local offset = self:_CalcShotOffset(trans)
        offset.x = offset.x + self._nodeOffset
        local autoFightShow = self:_CheckSerialAutoFightShow(stageType, stageId)

        self:ShowDialog(
            "UIActivityLevelStage",
            stageId,
            passInfo,
            self._line_component,
            self._rt,
            offset,
            self._width,
            self._height,
            scale,
            autoFightShow,
            self._campaign:GetComponent(ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_ACTION_POINT)
        )
    end
end

function UIActivityEveSinsaLevelAController:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIActivityEveSinsaLevelAController:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

function UIActivityEveSinsaLevelAController:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        self:SwitchState(UIStateType.UIActivityEveSinsaLevelAController)
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
                            self:SwitchState(UIStateType.UIActivityEveSinsaLevelAController)
                        end
                    )
                else
                    self:SwitchState(UIStateType.UIActivityEveSinsaLevelAController)
                end
            end
        end,
        self
    )
end

function UIActivityEveSinsaLevelAController:CloseUIStage()
    if GameGlobal.UIStateManager():IsShow("UIActivityStage") then
        GameGlobal.UIStateManager():CloseDialog("UIActivityStage")
    end
end

--endregion

--region Event
function UIActivityEveSinsaLevelAController:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIActivityEveSinsaLevelAController:RemoveEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIActivityEveSinsaLevelAController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityEveSinsaLevelAController:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end

--endregion

--region help
function UIActivityEveSinsaLevelAController:_ShowUIGetItemController(rewards)
    self:ShowDialog(
        "UIGetItemController",
        rewards,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        end
    )
end

--endregion
function UIActivityEveSinsaLevelAController:pointOnClick()
    self:ShowDialog("UIEvePointDetail")
end
