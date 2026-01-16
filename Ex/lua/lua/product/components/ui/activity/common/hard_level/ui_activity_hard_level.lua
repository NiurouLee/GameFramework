---@class UIActivityHardLevel : Object
_class("UIActivityHardLevel", Object)
UIActivityHardLevel = UIActivityHardLevel
function UIActivityHardLevel:Constructor(controller)
    ---@type UIController
    self._controller = controller
    ---@type MissionModule
    self._missionModule = GameGlobal.GetModule(MissionModule)
    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
    self._go = self._controller:GetGameObject("Hard")
    self._time = self._controller:GetUIComponent("UILocalizationText", "HardTime")
    self._timerHolder = UITimerHolder:New()
    ---@type UICustomWidgetPool
    self._nodesPool = self._controller:GetUIComponent("UISelectObjectPath", "HardNodes")
    self:OnInit()
end

function UIActivityHardLevel:Destroy()
    self._timerHolder:Dispose()
end

function UIActivityHardLevel:SetData(campaign, component, componentInfo)
    ---@type UIActivityCampaign
    self._campaign = campaign
    ---@type LineMissionComponent
    self._levelHardComponent = component
    ---@type LineMissionComponentInfo
    self._levelHardCompInfo = componentInfo
    self:RefreshCountdown()
    self:FlushNodes()
end

function UIActivityHardLevel:SetActive(status, playAnim)
    self._go:SetActive(status)
    if status and playAnim then
        self:FlushNodes()
    end
end

function UIActivityHardLevel:RefreshCountdown()
    local closeTime = self._levelHardCompInfo.m_close_time
    --普通关组件是否开放，倒计时到0后关闭
    self._isValid = true
    local timerName = "CountDown"

    local function countDown()
        local now = GameGlobal.GetModule(SvrTimeModule):GetServerTime() / 1000
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

function UIActivityHardLevel:GetFormatTimerStr(time, id)
    local default_id = {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107"
    }
    id = id or default_id

    local timeStr = ""
    if time < 0 then
        timeStr = StringTable.Get(id.over)
        return timeStr
    end
    
    local day = math.floor(time / 3600 / 24)
    if day > 0 then
        time = time - day * 3600 * 24
        local hour = math.floor(time / 3600)
        timeStr = day .. StringTable.Get(id.day)
        if hour > 0 then
            timeStr = timeStr .. hour .. StringTable.Get(id.hour)
        end
    else
        if time >= 60 then
            local hour = math.floor(time / 3600)
            time = time - hour * 3600
            if hour > 0 then
                timeStr = hour.. StringTable.Get(id.hour)
            end
            local minus = math.floor(time / 60)
            if minus > 0 then
                timeStr = timeStr .. minus.. StringTable.Get(id.min)
            end
        else
            timeStr = StringTable.Get(id.zero)
        end
    end

    return StringTable.Get(self:GetTimeDownString(), timeStr)
end

function UIActivityHardLevel:FlushNodes()
    self._controller:StartTask(self.CreateItems, self)
end


function UIActivityHardLevel:CreateItems(TT)
    self._controller:Lock("UIActivityN27HardLevel_CreateItems")

    local cmpID = self._levelHardComponent:GetComponentCfgId()
    local missionCfgs = Cfg.cfg_component_line_mission {ComponentID = cmpID}
    local count = table.count(missionCfgs)
    local nodeName = self:GetLevelNodeName()
    self._nodesPool:SpawnObjects(nodeName, count)
    local nodes = self._nodesPool:GetAllSpawnList()
    for i = 1, #nodes do
        nodes[i]:SetVisible(false)
    end
    local index = 1
    for _, cfg in ipairs(missionCfgs) do
        ---@type UIActivityNHardLevelNode
        local uiNode = nodes[index]
        index = index + 1
        local isOpen = false
        local hasPass = self._levelHardCompInfo.m_pass_mission_info[cfg.CampaignMissionId] ~= nil
        if cfg.NeedMissionId and cfg.NeedMissionId ~= 0 then
            if self._levelHardCompInfo.m_pass_mission_info[cfg.NeedMissionId] ~= nil then
                isOpen = true
            end
        else
            isOpen = true
        end

        uiNode:SetData(cfg, isOpen, hasPass,
            function(stageId, isStory, worldPos)
                self:OnNodeClick(stageId, isStory, worldPos)
            end)
        self:NodePlayAnimationInterval(TT)
    end
    self._controller:UnLock("UIActivityN27HardLevel_CreateItems")
end

function UIActivityHardLevel:OnNodeClick(stageId, isStory, worldPos)
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

        self._controller:ShowDialog(
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

    self:EnterStage(stageId, worldPos)
end

function UIActivityHardLevel:EnterStage(stageId, worldPos)
    local autoFightShow = false
    self._controller:ShowDialog(
        "UIActivityLevelStageNew",
        stageId,
        self._levelHardCompInfo.m_pass_mission_info[stageId],
        self._levelHardComponent,
        autoFightShow,
        nil,
        nil,
        nil,
        nil,
        nil,
        false,
        true
    )
end

function UIActivityHardLevel:PlotEndCallback(stageId)
    local isActive = self._levelHardComponent:IsPassCamMissionID(stageId)
    if isActive then --已激活的就不再发激活消息
        return
    end

    self._controller:StartTask(
        function(TT)
            self._levelHardComponent:SetMissionStoryActive(TT, stageId, ActiveStoryType.ActiveStoryType_BeforeBattle)

            local res = AsyncRequestRes:New()
            local award = self._levelHardComponent:HandleCompleteStoryMission(TT, res, stageId)
            if not res:GetSucc() then
                self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
            else
                if table.count(award) ~= 0 then
                    self._controller:ShowDialog(
                        "UIGetItemController",
                        award,
                        function()
                            self:FlushNodes()
                        end
                    )
                else
                    self:FlushNodes()
                end
            end
        end,
        self
    )
end

function UIActivityHardLevel:OnInit()
end

function UIActivityHardLevel:GetTimeDownString()
    return ""
end

function UIActivityHardLevel:NodePlayAnimationInterval(TT)

end

function UIActivityHardLevel:GetLevelNodeName()
    return "UIActivityN29NHardLevelNode"
end
