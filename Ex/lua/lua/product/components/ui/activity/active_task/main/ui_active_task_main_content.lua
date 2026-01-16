require "ui_side_enter_center_content_base"

---@class UIActiveTaskMainContent:UISideEnterCenterContentBase
_class("UIActiveTaskMainContent", UISideEnterCenterContentBase)
UIActiveTaskMainContent = UIActiveTaskMainContent

function UIActiveTaskMainContent:Constructor()
end

function UIActiveTaskMainContent:DoInit(params)
    self._campaignType = params and params.campaign_type
    self._componentIds = params and params.component_ids or {}
    self._campaignId = params and params.campaign_id

    self._campaign = self._data
end

--显示
function UIActiveTaskMainContent:DoShow(params)
     --检查活动是否开启
     if not self._campaign:CheckComponentOpen(ECampaignVigQuestComponentID.ECAMPAIGN_VIGQUEST_TURNCARD) then
        local result = self._campaign:CheckComponentOpenClientError(ECampaignVigQuestComponentID.ECAMPAIGN_VIGQUEST_TURNCARD)
        self._campaign:CheckErrorCode(result)
        return
    end
    ---@type ActiveTaskData
    self._activeTaskData = ActiveTaskData:New()
    self._activeTaskData:SetCampaign(self._campaign)
    self._activeTaskCfg = self._activeTaskData:GetActiveTaskCfg()
    
    self:_GetComponent()
    self:AddListener()

    local isNew = self._campaign:CheckCampaignNew()
    if isNew then
        --清除new
        self:StartTask(function(TT)
            self._campaign:ClearCampaignNew(TT)
        end,self)
    end
    self._flipTab:Open()
    self._state = EUIActiveTaskMainContentState.FLIP
    self._flipSelectedObj:SetActive(true)
    self._missionSelectedObj:SetActive(false)
    self._intro:SetText(StringTable.Get(self._activeTaskCfg.FilpIntro))
end

--显示其他Tab之前,隐藏
function UIActiveTaskMainContent:DoHide()
    self._activeTaskData = nil
    self:RemoveListener()
    self._timerHolder:Dispose()
end

function UIActiveTaskMainContent:AddListener()
    self._refreshActiveTaskRedCallback = GameHelper:GetInstance():CreateCallback(self.CheckRed, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.RefreshActiveTaskRed, self._refreshActiveTaskRedCallback)
end

function UIActiveTaskMainContent:RemoveListener()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.RefreshActiveTaskRed, self._refreshActiveTaskRedCallback)
end


--关闭界面,销毁Tab
function UIActiveTaskMainContent:DoDestroy()
    
end

function UIActiveTaskMainContent:_GetComponent()
    self._diffTime = self:GetUIComponent("UILocalizationText","DiffTime")
    self._flipTabContent = self:GetUIComponent("UISelectObjectPath","flipTabContent")
    self._missionTabContent = self:GetUIComponent("UISelectObjectPath","missionTabContent")
    self._intro = self:GetUIComponent("UILocalizationText","intro")

    self._flipSelectedObj = self:GetGameObject("flipSelected")
    self._flipRedObj = self:GetGameObject("flipRed")
    self._missionSelectedObj = self:GetGameObject("missionSelected")
    self._missionRedObj = self:GetGameObject("missionRed")
    self._flipTabContentObj = self:GetGameObject("flipTabContent")
    self._missionTabContentObj = self:GetGameObject("missionTabContent")
    self._timerHolder = UITimerHolder:New()

    self:InitComponent()
    self:RefreshCountdown()
end

--初始化信息
function UIActiveTaskMainContent:InitComponent()
    self._flipTab = self._flipTabContent:SpawnObject("UIActiveTaskFlipTab")
    self._missionTab = self._missionTabContent:SpawnObject("UIActiveTaskMissionTab")
    self._flipTab:Close()
    self._missionTab:Close()

    self._flipTab:SetData(self._activeTaskData,self)
    self._missionTab:SetData(self._activeTaskData,self)
    self:CheckRed()
end

function UIActiveTaskMainContent:RefreshCountdown()
    local closeTime = self._activeTaskData:GetCampaignEndTime()
    local timerName = "CountDown"

    local function countDown()
        local now = GameGlobal.GetModule(SvrTimeModule):GetServerTime() / 1000
        local time = math.ceil(closeTime - now)
        local timeStr = self:GetFormatTimerStr(time)
        if self._timeString ~= timeStr then
            self._diffTime:SetText(timeStr)
            self._timeString = timeStr
        end
        if time < 0 then
            self._timerHolder:StopTimer(timerName)
        end
    end
    countDown()
    self._timerHolder:StartTimerInfinite(timerName, 1000, countDown)
end

function UIActiveTaskMainContent:GetFormatTimerStr(time, id)
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
        timeStr = day .. StringTable.Get(id.day) .. hour .. StringTable.Get(id.hour)
    elseif hour > 0 then
        timeStr = hour .. StringTable.Get(id.hour) .. min .. StringTable.Get(id.min)
    elseif min > 0 then
        timeStr = min .. StringTable.Get(id.min)
    else
        timeStr = StringTable.Get(id.zero)
    end
    return StringTable.Get(self:GetTimeDownString(), timeStr)
end

function UIActiveTaskMainContent:GetTimeDownString()
    return "str_n27_level_remain_time_tips"
end

--检查红点
function UIActiveTaskMainContent:CheckRed()
    local flipRed = self:_CheckFlipRed()
    local missionRed = self:_CheckMissionRed()
    self._flipRedObj:SetActive(flipRed)
    self._missionRedObj:SetActive(missionRed)
end

--检查翻牌红点
function UIActiveTaskMainContent:_CheckFlipRed()
    return self._activeTaskData:CheckFlipRed()
end

--检查任务红点
function UIActiveTaskMainContent:_CheckMissionRed()
    return self._activeTaskData:CheckMissionRed()
end

function UIActiveTaskMainContent:FlipBtnOnClick()
    local isOver = self._activeTaskData:CheckFlipIsOver()
    if isOver then
        return
    end

    if self._state == EUIActiveTaskMainContentState.FLIP then
        return
    end
    self._state = EUIActiveTaskMainContentState.FLIP
    GameGlobal.TaskManager():StartTask(self._FlipClick,self)
end

function UIActiveTaskMainContent:_FlipClick(TT)
    GameGlobal.UIStateManager():Lock("UIActiveTaskMainContent_FlipClick")
    self._missionTab:Close(true)
    self._missionSelectedObj:SetActive(false)
    self._flipSelectedObj:SetActive(true)
    YIELD(TT,333)
    self._flipTab:Open()
    self._intro:SetText(StringTable.Get(self._activeTaskCfg.FilpIntro))
    GameGlobal.UIStateManager():UnLock("UIActiveTaskMainContent_FlipClick")
    self:CheckRed()
end

function UIActiveTaskMainContent:MissionBtnOnClick()
    local isOver = self._activeTaskData:CheckFlipIsOver()
    if isOver then
        return
    end

    if self._state == EUIActiveTaskMainContentState.MISSION then
        return
    end
    self._state = EUIActiveTaskMainContentState.MISSION
    GameGlobal.TaskManager():StartTask(self._MissionClick,self)
end

function UIActiveTaskMainContent:_MissionClick(TT)
    GameGlobal.UIStateManager():Lock("UIActiveTaskMainContent_MissionClick")
    self._flipTab:Close(true)
    self._flipSelectedObj:SetActive(false)
    YIELD(TT,333)
    self._missionTab:Open()
    self._activeTaskData:CancelDailyTaskRed()
    self._missionSelectedObj:SetActive(true)
    self._intro:SetText(StringTable.Get(self._activeTaskCfg.MissionIntro))
    GameGlobal.UIStateManager():UnLock("UIActiveTaskMainContent_MissionClick")
    self:CheckRed()
end


--- @class EUIActiveTaskMainContentState
local EUIActiveTaskMainContentState = {
    FLIP = 1, --翻牌
    MISSION = 2, --任务
}
_enum("EUIActiveTaskMainContentState", EUIActiveTaskMainContentState)