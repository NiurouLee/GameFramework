---@class UIXH1SimpleLevelReview:UIController
_class("UIXH1SimpleLevelReview", UIController)
UIXH1SimpleLevelReview = UIXH1SimpleLevelReview

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIXH1SimpleLevelReview:LoadDataOnEnter(TT, res, uiParams)
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
    ---@type UIXH1LineMissionManagerReview
    self._lineMissionManager = UIXH1LineMissionManagerReview:New()

    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res,
        ECampaignType.CAMPAIGN_TYPE_REVIEW_N3,
        ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_LINE_MISSION)

    --强制请求
    --请求完了再获取就一定是最新的了
    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    if res and res:GetSucc() then
        ---@type LineMissionComponent
        self._line_component = self._campaign:GetComponent(ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_LINE_MISSION)
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

function UIXH1SimpleLevelReview:OnShow(uiParams)
    UIXH1SimpleLevelReview.SLeval = 999 --s关枚举id
    UIXH1SimpleLevelReview.Passed = 888 --通关后文本和阴影颜色
    UIXH1SimpleLevelReview.NodeCfg = {
        [DiscoveryStageType.FightNormal] = {
            [1] = {
                normal = "summer_ludian_btn1",
                press = "summer_ludian_btn3",
                lock = "summer_ludian_btn4",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255),
                normalStar = "summer_ludian_icon1",
                passStar = "summer_ludian_icon2"
            }, --普通样式
            [2] = {
                normal = "summer_ludian_btn17",
                press = "summer_ludian_btn18-1",
                lock = "summer_ludian_btn18-2",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255),
                normalStar = "summer_ludian_icon1-2",
                passStar = "summer_ludian_icon2"
            } --高难样式
        },
        [DiscoveryStageType.FightBoss] = {
            [1] = {
                normal = "summer_ludian_btn13",
                press = "summer_ludian_btn15",
                lock = "summer_ludian_btn16",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(238 / 255, 0 / 255, 34 / 255),
                normalStar = "summer_ludian_icon1",
                passStar = "summer_ludian_icon2"
            }, --普通样式
            [2] = {
                normal = "summer_ludian_btn23",
                press = "summer_ludian_btn25",
                lock = "summer_ludian_btn26",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(238 / 255, 0 / 255, 34 / 255),
                normalStar = "summer_ludian_icon1-3",
                passStar = "summer_ludian_icon2"
            } --高难样式
        },
        [DiscoveryStageType.Plot] = {
            [1] = {
                normal = "summer_ludian_btn5",
                press = "summer_ludian_btn7",
                lock = "summer_ludian_btn8",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255)
            }, --普通样式
            [2] = {
                normal = "summer_ludian_btn19",
                press = "summer_ludian_btn20-1",
                lock = "summer_ludian_btn20-2",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255)
            } --高难样式
        },
        [UIXH1SimpleLevelReview.SLeval] = {
            [1] = {
                normal = "summer_ludian_btn9",
                press = "summer_ludian_btn11",
                lock = "summer_ludian_btn12",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(22 / 255, 42 / 255, 61 / 255),
                normalStar = "summer_ludian_icon1-2",
                passStar = "summer_ludian_icon2"
            }, --普通样式
            [2] = {
                normal = "summer_ludian_btn21",
                press = "summer_ludian_btn22-1",
                lock = "summer_ludian_btn22-2",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(22 / 255, 42 / 255, 61 / 255),
                normalStar = "summer_ludian_icon1",
                passStar = "summer_ludian_icon2"
            } --高难样式
        }
    }

    self:_GetComponents()

    local componentCfgId = self._line_component:GetComponetCfgId(self._line_info.m_campaign_id, self._line_info.m_component_id)
    self._lineMissionManager:Init(self._line_info, componentCfgId)

    self._lineMissionManager:Update()
    self:Flush()

    -- 进场锁定
    self._enterLockName = "UIXH1SimpleLevel_OnShow"
    self._enterLockTimeEvent = UIActivityHelper.StartLockEvent(self._enterLockName, self._enterLockTimeEvent, nil)
    local bgLoader1 = self:GetUIComponent("RawImageLoader", "bg1")
    local bgLoader2 = self:GetUIComponent("RawImageLoader", "bg2")
    ---@type UIXH1Scroller
    self._scroller =
        UIXH1Scroller:New(self._contentRect, bgLoader1, bgLoader2, self._lineMissionManager:GetScrollSpliter())

    self._scrollRect.onValueChanged:AddListener(
        function()
            self._scroller:OnChange()
        end
    )
end

function UIXH1SimpleLevelReview:OnHide()
    -- 进场锁定
    UIActivityHelper.CancelLockEvent(self._enterLockName, self._enterLockTimeEvent)
    -- 移动关卡锁定
    UIActivityHelper.CancelLockEvent(self._moveLockName, self._moveLockTimeEvent)
    UIXH1SimpleLevelReview.SLeval = nil
    UIXH1SimpleLevelReview.NodeCfg = nil
end

--region MissionNode
function UIXH1SimpleLevelReview:Flush()
    self:FlushPanel()
    self:FlushNodes()
    self:FlushLines()
end

function UIXH1SimpleLevelReview:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIXH1SimpleLevelReview.super:Dispose()
end

function UIXH1SimpleLevelReview:_GetComponents()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:SwitchState(UIStateType.UISummer1Review)
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
    self._safeWidth = self:GetUIComponent("RectTransform", "SafeArea").rect.size.x
end

function UIXH1SimpleLevelReview:FlushPanel()
    -- Set Width
    local totalWidth = self._lineMissionManager:GetTotalWidth()
    self._contentRect.sizeDelta = Vector2(totalWidth, self._contentRect.sizeDelta.y)
    self._contentRect.anchoredPosition = Vector2(self._safeWidth / 2 - totalWidth, 0)
end

---只刷当前章节路点
function UIXH1SimpleLevelReview:FlushNodes()
    ---@type table<number, UIActivityMissionNodeInfo>
    local missionNodes = self._lineMissionManager:GetNodes()
    local count = table.count(missionNodes)
    self._nodesPool:SpawnObjects("UIXH1MissionNodeReview", count)
    local nodes = self._nodesPool:GetAllSpawnList()
    self._uiMapNodes = {}
    local idx = 1
    for i, node in pairs(missionNodes) do
        ---@type UIXH1MissionNodeReview
        local uiNode = nodes[idx]
        uiNode:SetData(
            node,
            function(stageId, needScroll, trans)
                self:_MoveToStage(stageId, needScroll, trans)
            end
        )
        self._uiMapNodes[idx] = uiNode
        idx = idx + 1
    end
end

function UIXH1SimpleLevelReview:FlushLines()
    local lines = self._lineMissionManager:GetLines()
    local len = table.count(lines)
    if not lines or len <= 0 then
        return
    end
    -- self._linesShadowPool:SpawnObjects("UIMapPathItem", len)
    self._linesPool:SpawnObjects("UIXH1MissionLine", len)
    ---@type table<number,UIXH1MissionLine>
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
function UIXH1SimpleLevelReview:ShotTest()
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local shotRect = self:GetUIComponent("RectTransform", "screenShot")
    self._width = shotRect.rect.width
    self._height = shotRect.rect.height

    local LeftTop = self:GetGameObject("LeftTop")

    LeftTop:SetActive(false)

    self._shot.width = self._width
    self._shot.height = self._height
    self._shot.blurTimes = 0

    self._shot:CleanRenderTexture()
    self._rt = self._shot:RefreshBlurTexture()

    LeftTop:SetActive(true)
end

function UIXH1SimpleLevelReview:_CalcShotOffset(trans)
    local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local screenPos = camera:WorldToScreenPoint(trans.position)
    return -(Vector2(screenPos.x, screenPos.y) - Vector2(UnityEngine.Screen.width, UnityEngine.Screen.height) / 2)
end

function UIXH1SimpleLevelReview:_MoveToStage(stageId, needScroll, trans)
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

function UIXH1SimpleLevelReview:_EnterStage(stageId, trans)
    local nodes = self._lineMissionManager:GetNodes()
    local node = nodes[stageId]

    local stageType = node.type
    if stageType == DiscoveryStageType.Plot then
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
        local autoFightShow = self:_CheckSerialAutoFightShow(stageType, stageId)

        self:ShowDialog(
            "UIActivityLevelStageNew",
            stageId,
            self._line_info.m_pass_mission_info[stageId],
            self._line_component,
            autoFightShow,
            nil)
    end
end

function UIXH1SimpleLevelReview:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIXH1SimpleLevelReview:PlotEndCallback(stageId)
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
                self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
            else
                if table.count(award) ~= 0 then
                    self:ShowDialog(
                        "UIGetItemController",
                        award,
                        function()
                            self:SwitchState(UIStateType.UIXH1SimpleLevelReview)
                        end
                    )
                else
                    self:SwitchState(UIStateType.UIXH1SimpleLevelReview)
                end
            end
        end,
        self
    )
end
--endregion
