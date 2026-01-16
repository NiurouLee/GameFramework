---@class UIN7LevelReview:UIController
_class("UIN7LevelReview", UIController)
UIN7LevelReview = UIN7LevelReview

function UIN7LevelReview:Constructor()
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN7DataReview()
    self.CampaignTypeN7Review = ECampaignType.CAMPAIGN_TYPE_REVIEW_N7
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN7LevelReview:LoadDataOnEnter(TT, res, uiParams)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, self.CampaignTypeN7Review, self.data.componentIdLine)

    --强制请求，请求完了再获取就一定是最新的了
    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    self._campaignID = self._campaign._id

    if res and res:GetSucc() then
        ---@type LineMissionComponent
        self._line_component = self._campaign:GetComponent(self.data.componentIdLine)
        --- @type LineMissionComponentInfo
        self._line_info = self._line_component:GetComponentInfo()
        local simpleOpenTime = self._line_info.m_unlock_time
        local simpleCloseTime = self._line_info.m_close_time
        local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
        --不在开放时段内
        if now < simpleOpenTime then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
            self.mCampaign:ShowErrorToast(res.m_result, true)
            return
        elseif now > simpleCloseTime then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
            self.mCampaign:ShowErrorToast(res.m_result, true)
            return
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        self.mCampaign:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIN7LevelReview:OnShow(uiParams)
    self._isOpen = true
    self._timerHolder = UITimerHolder:New()

    UIN7Level.SLeval = 999 --s关枚举id
    UIN7Level.Passed = 888 --通关后文本和阴影颜色
    UIN7Level.NodeCfg = {
        [DiscoveryStageType.FightNormal] = {
            [1] = {
                normal = "n7_map_stage",
                press = "n7_map_click",
                lock = "n7_map_stage",
                textColor = Color(0 / 0, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255, 10 / 255),
                normalStar = "n7_map_blank",
                passStar = "n7_map_badge"
            }
        },
        [DiscoveryStageType.FightBoss] = {
            [1] = {
                normal = "n7_map_boss",
                press = "n7_map_click",
                lock = "n7_map_boss",
                textColor = Color(246 / 255, 246 / 255, 246 / 255),
                textShadow = Color(255 / 255, 255 / 255, 255 / 255, 10 / 255),
                normalStar = "n7_map_blank",
                passStar = "n7_map_badge"
            }
        },
        [DiscoveryStageType.Plot] = {
            [1] = {
                normal = "n7_map_plot",
                press = "n7_map_click",
                lock = "n7_map_plot",
                textColor = Color(0 / 0, 0 / 255, 0 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255, 10 / 255)
            }
        },
        [UIN7Level.SLeval] = {
            [1] = {
                normal = "n7_map_boss",
                press = "n7_map_click",
                lock = "n7_map_boss",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(255 / 255, 255 / 255, 255 / 255, 10 / 255),
                normalStar = "n7_map_blank",
                passStar = "n7_map_badge"
            }
        }
    }

    self:AttachEvents()
    self:InitWidget()

    local componentCfgId = self._line_component:GetComponentCfgId()

    self:FlushNodes()

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
end

function UIN7LevelReview:OnHide()
    UIN7Level.SLeval = nil
    UIN7Level.NodeCfg = nil
    self._isOpen = false
    self._timerHolder:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIN7Level.super:Dispose()
    self._scroller:Dispose()
end

function UIN7LevelReview:InitWidget()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self.mCampaign:CampaignSwitchState(
                true,
                UIStateType.UIN7MainReview,
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
end

function UIN7LevelReview:FlushNodes()
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

    self._nodesPool:SpawnObjects("UIN7LevelNode", levelCount)
    local nodes = self._nodesPool:GetAllSpawnList()
    self._linesPool:SpawnObjects("UIN7LevelLine", lineCount)
    ---@type table<number,UIN7LevelLine>
    local lines = self._linesPool:GetAllSpawnList()

    local nodeIdx, lineIdx = 1, 1
    for missionID, cfg in pairs(showMission) do
        ---@type UIN7LevelNode
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
            ---@type UIN7LevelLine
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
            "n7_map_bg1",
            "n7_map_bg2",
            "n7_map_bg3"
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

function UIN7LevelReview:OnNodeClick(stageId, isStory, worldPos)
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
        local moveLockName = "UINP6Level_MoveToStage"
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

function UIN7LevelReview:_EnterStage(stageId, worldPos)
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
    self:ShowDialog(
        "UIActivityLevelStageNew",
        stageId,
        self._line_info.m_pass_mission_info[stageId],
        self._line_component,
        autoFightShow,
        nil
    )
end

function UIN7LevelReview:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIN7LevelReview:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

function UIN7LevelReview:PlotEndCallback(stageId)
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        -- self:SwitchState(UIStateType.UIN7LevelReview)
        return
    end

    self:StartTask(
        function(TT)
            self._line_component:SetMissionStoryActive(TT, stageId, ActiveStoryType.ActiveStoryType_BeforeBattle)

            local res = AsyncRequestRes:New()
            local award = self._line_component:HandleCompleteStoryMission(TT, res, stageId)
            if not res:GetSucc() then
                self.mCampaign:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
            else
                if table.count(award) ~= 0 then
                    self:ShowDialog(
                        "UIGetItemController",
                        award,
                        function()
                            self:SwitchState(UIStateType.UIN7LevelReview)
                        end
                    )
                else
                    self:SwitchState(UIStateType.UIN7LevelReview)
                end
            end
        end,
        self
    )
end
function UIN7LevelReview:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIN7LevelReview:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN7LevelReview:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end

--endregion

--region help
function UIN7LevelReview:_ShowUIGetItemController(rewards)
    self:ShowDialog(
        "UIGetItemController",
        rewards,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        end
    )
end
--endregion
