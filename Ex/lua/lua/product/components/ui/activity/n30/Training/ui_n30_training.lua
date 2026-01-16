require("ui_side_enter_center_content_base")

---@class UIN30Training : UISideEnterCenterContentBase
_class("UIN30Training", UISideEnterCenterContentBase)
UIN30Training = UIN30Training

function UIN30Training:DoInit(params)
    self._campaignType = params and params.campaign_type
    self._componentIds = params and params.component_ids or {}
    self._campaignId = params and params.campaign_id

    self._campaignType = ECampaignType.CAMPAIGN_TYPE_LINE_MISSION
    self._componentId_LineMission = ECampaignLineMissionComponentID.ECAMPAIGN_LINE_MISSION

    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
    ---@type UIActivityCampaign
    self._campaign = self._data
end

function UIN30Training:DoShow()
    -- 清除 new
    self:StartTask(function(TT)
        self._campaign:ClearCampaignNew(TT)
    end)
    self._atlas = self:GetAsset("UIN30.spriteatlas", LoadType.SpriteAtlas)

    if not self._campaign:CheckComponentOpen(ECampaignLineMissionComponentID.ECAMPAIGN_LINE_MISSION) then
        local result = self._campaign:CheckComponentOpenClientError(ECampaignLineMissionComponentID.ECAMPAIGN_LINE_MISSION)
        self._campaign:CheckErrorCode(result)
        return
    end

    --普通线性关
    ---@type LineMissionComponent
    local line_component = self._campaign:GetComponent(ECampaignLineMissionComponentID.ECAMPAIGN_LINE_MISSION)
    ---@type LineMissionComponentInfo
    local line_info = self._campaign:GetComponentInfo(ECampaignLineMissionComponentID.ECAMPAIGN_LINE_MISSION)

    ---@type LineMissionComponent
    self._line_component = line_component
    ---@type LineMissionComponentInfo
    self._line_info = line_info

    self:InitWidget()
    self:_Refresh()

    -- 进场锁定
    -- local lockName = "UIN30Training.Enter"
    -- self:Lock(lockName)
    self._timerHolder = UITimerHolder:New()
    self:RefreshCountdown()
    -- self._timerHolder:StartTimer(
    --     lockName,
    --     500,
    --     function()
    --         self:UnLock(lockName)
    --     end
    -- )
    self._anim:Play("uieff_UIN30Training_in")
    self._isOpen = true
    self:AttachEvents()
end

function UIN30Training:DoHide()
    self._isOpen = false
    self._timerHolder:Dispose()

    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end

    self:DetachEvents()

    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN28ActivityMainRedStatusRefresh)
end

function UIN30Training:DoDestroy()
end

-----------------------------------------------------------------------------------

function UIN30Training:InitWidget()
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "MapContent")
    self._mapContentRect = self:GetUIComponent("RectTransform", "MapContent")
    self._contentRect = self:GetUIComponent("RectTransform", "Content")

    ---@type UICustomWidgetPool
    --self._ltBtn = self:GetUIComponent("UISelectObjectPath", "ltBtn")
    self._txtRemainingTime = self:GetUIComponent("UILocalizationText", "remainingTime")
    ---@type UICustomWidgetPool
    self._linesPool = self:GetUIComponent("UISelectObjectPath", "Lines")
    self._nodesPool = self:GetUIComponent("UISelectObjectPath", "Nodes")

    self._viewpotSize = self:GetUIComponent("RectTransform", "Viewport").rect.size
    self._anim = self:GetUIComponent("Animation","anim")
    
end

-- function UIN30Training:OnUpdate()
--     self:RefreshTime()
-- end

function UIN30Training:_Refresh()
    self:FlushNodes()
    self:RefreshTime()
end

function UIN30Training:RefreshCountdown()
   
    local timerName = "CountDown"
    local function countDown()
        local endTime = self._line_info.m_close_time
        --- @type SvrTimeModule
        local svrTimeModule = self:GetModule(SvrTimeModule)
        local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
        local str = self:GetFormatTimerStr(endTime - curTime,"D6D895")
        local str2 = StringTable.Get("str_n30_train_activity_remain_time")
        --self._txtRemainingTime:SetText(str2..str)
        if self._timeString ~= str2..str then
            self._txtRemainingTime:SetText(str2..str)
            self._timeString = str2..str
        end
        if endTime - curTime < 0 then
            self._txtRemainingTime:SetText(str)
            self._timerHolder:StopTimer(timerName)
        end
    end
    countDown()
    self._timerHolder:StartTimerInfinite(timerName, 1000, countDown)
end

function UIN30Training:RefreshTime()
    local endTime = self._line_info.m_close_time
    --- @type SvrTimeModule
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local str = self:GetFormatTimerStr(endTime - curTime,"D6D895")
    local str2 = StringTable.Get("str_n30_train_activity_remain_time")
    self._txtRemainingTime:SetText(str2..str)
end

function UIN30Training:GetFormatTimerStr(time, txtColor)
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

function UIN30Training:IntroOnClick()
    self:ShowDialog("UIIntroLoader", "UIN30TrainingIntro")
end

function UIN30Training.GetItemCountStr(count, preColor, countColor)
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

function UIN30Training:FlushNodes()
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
    self._allMissionCfgs = missionCfgs
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
    local lastMissionID = firstMissionID
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

    --显示未解锁下一关
    local flag = true
    while flag do
        lastMissionID = self:_GetLastMissionID(lastMissionID)
        if not showMission[lastMissionID] then
            flag = false
        end
    end
    if (not (lastMissionID == 0)) and lastMissionID then
        levelCount = levelCount + 1
        lineCount = lineCount + 1
        showMission[lastMissionID] = missionCfgs[lastMissionID]
    end

    self._nodesPool:SpawnObjects("UIN30TrainingNode", levelCount)
    local nodes = self._nodesPool:GetAllSpawnList()
    self._linesPool:SpawnObjects("UIN30TrainingLine", lineCount)
    local lines = self._linesPool:GetAllSpawnList()

    local nodeIdx, lineIdx = 1, 1
    for missionID, cfg in pairs(showMission) do
        ---@type UIN15ChessMapNode
        local uiNode = nodes[nodeIdx]
        local last = false
        local func = nil
        if lastMissionID == missionID then
            last = true
        else
            
            last = false
            func = function(stageId, isStory)
                self:OnNodeClick(stageId, isStory)
                end
        end
        local last2 = false
        if (not (lastMissionID == 0)) and lastMissionID then
            if missionCfgs[lastMissionID].NeedMissionId ==  missionID and missionID ~= firstMissionID then
                last2 = true
            end
        end
        uiNode:SetData(
                cfg,
                self._line_info.m_pass_mission_info[missionID],
                func,
                last,
                last2
            )
        nodeIdx = nodeIdx + 1
        
        if cfg.WayPointType ~= 4 and cfg.NeedMissionId ~= 0 then
            local n1 = showMission[cfg.NeedMissionId]
            local n2 = cfg
            ---@type UIN30TrainingMapLine
            local line = lines[lineIdx]
            line:SetAtlas(self._atlas)
            line:Flush(Vector2(n2.MapPosX, n2.MapPosY), Vector2(n1.MapPosX, n1.MapPosY))
            lineIdx = lineIdx + 1
        end
        -- if cfg.NeedMissionId ~= 0 then
        --     local n1 = showMission[cfg.NeedMissionId]
        --     local n2 = cfg
        --     ---@type UIN15ChessMapLine
        --     local line = lines[lineIdx]
        --     line:Flush(Vector2(n2.MapPosX, n2.MapPosY), Vector2(n1.MapPosX, n1.MapPosY))
        --     lineIdx = lineIdx + 1
        -- end
    end

    local right = -1111111111111111
    for _, cfg in pairs(showMission) do
        right = math.max(right, cfg.MapPosX)
    end
    --滚动列表总宽度=最右边路点+右边距
    local width = math.abs(right + extra_width)
    width = math.max(self._viewpotSize.x, width)
    self._contentRect.sizeDelta = Vector2(width, self._contentRect.sizeDelta.y)
    self._contentRect.anchoredPosition = Vector2(self._viewpotSize.x - width, 0)
end

function UIN30Training:_GetLastMissionID(missionID)
    for id, cfg in pairs(self._allMissionCfgs) do
        if cfg.NeedMissionId == missionID then
            return id
        end
    end
    return nil
end

function UIN30Training:CheckTime()

    local simpleCloseTime = self._line_info.m_close_time
    local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
    --线性关活动结束
    if now > simpleCloseTime then
        return false
    end
    return true
end

function UIN30Training:OnNodeClick(stageId, isStory)
    local open = self:CheckTime()
    if not open then
        local result = self._campaign:CheckComponentOpenClientError(ECampaignLineMissionComponentID.ECAMPAIGN_LINE_MISSION) 
        self._campaign:CheckErrorCode(result)
        --local lockName = "UIN30Training"
        -- self:StartTask(function(TT)
        --     self:Lock(lockName)
        --     ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        --     YIELD(TT, 1000)
        --     self:UnLock(lockName)
        --     self:DoHide()
        -- end)
        return
    end

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
    local halfScreen = self._viewpotSize.x / 2
    local targetPos = nil
    local left, right = -curPos + areaWidth, -curPos + self._viewpotSize.x - areaWidth
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
    -- if targetPos then
    --     local moveTime = 0.5
    --     self._tweener = self._contentRect:DOAnchorPosX(targetPos, moveTime)
    --     -- 移动关卡锁定
    --     local moveLockName = "UIN30Training.MoveToStage"
    --     self:Lock(moveLockName)
    --     self._timerHolder:StartTimer(
    --             moveLockName,
    --             moveTime * 1000,
    --             function()
    --                 self:UnLock(moveLockName)
    --                 self:_EnterStage(stageId) -- 移动后，进入关卡
    --             end
    --     )
    -- else
        self:_EnterStage(stageId) -- 直接进入关卡
    -- end
end

function UIN30Training:_EnterStage(stageId)
    
    local missionCfg = Cfg.cfg_campaign_mission[stageId]
    local autoFightShow = self:_CheckSerialAutoFightShow(missionCfg.Type, stageId)
    local pointComponent = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_ACTION_POINT, 1)
    
    self:ShowDialog(
            "UIActivityLevelStageNew",
            stageId,
            self._line_info.m_pass_mission_info[stageId],
            self._line_component,
            autoFightShow,
            pointComponent  --行动点组件
    )
end

function UIN30Training:PlotEndCallback(stageId)
    self:_Refresh()
    local isActive = self._line_component:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        -- self:SwitchState(UIStateType.UIN30Training)
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
                            award
                            -- function()
                            --     self:SwitchState(UIStateType.UIN30Training)
                            -- end
                        )
                    else
                        --self:SwitchState(UIStateType.UIN30Training)
                    end
                end
            end,
    self)
end

function UIN30Training:_CheckSerialAutoFightShow(stageType, stageId)
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

function UIN30Training:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

--region AttachEvent
function UIN30Training:AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIN30Training:DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIN30Training:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN30Training:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:_Refresh()
    end
end
--endregion

--region Helper
function UIN30Training:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIN30Training:_SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIN30Training:_SetText(widgetName, str)
    widgetName = widgetName or "text"

    ---@type UILocalizationText
    local obj = self:GetUIComponent("UILocalizationText", widgetName)
    obj:SetText(str)
end
--endregion
