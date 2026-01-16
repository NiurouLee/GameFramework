---@class UIActivityDoubleDropContent : UISideEnterCenterContentBase
require("ui_side_enter_center_content_base")
_class("UIActivityDoubleDropContent", UISideEnterCenterContentBase)
UIActivityDoubleDropContent = UIActivityDoubleDropContent

function UIActivityDoubleDropContent:DoInit(cfg)
    self._titleLabel = self:GetUIComponent("UILocalizationText", "_txtTitle")
    self._titleLabel2 = self:GetUIComponent("UILocalizationText", "_txtTitle2")
    self._timeLabel = self:GetUIComponent("UILocalizationText", "Time")
    
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)

    self._campaignType = ECampaignType.CAMPAIGN_TYPE_HAVESTTIME
    self._componentId = ECampaignRewardDoubleComponentID.ECAMPAIGN_REWARD_DOUBLE
    
    ---@type UIActivityCampaign
    self._campaign = self._data
end

function UIActivityDoubleDropContent:DoShow()
    -- 清除 new
    self:StartTask(function(TT)
        self._campaign:ClearCampaignNew(TT)
    end)

    --获取组件
    ---@type RewardDoubleComponent
    self._rewardDoubleComponent = self._campaign:GetComponent(self._componentId)
    ---@type RewardDoubleComponentInfo
    self._rewardDoubleComponentInfo = self._campaign:GetComponentInfo(self._componentId)

    ---------------------------------------------------

    -- --配置
    local cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
    --标题数据
    self._name = ""
    if cfg_campaign then
        self._name = StringTable.Get(cfg_campaign.CampaignName)
        self._subName = StringTable.Get(cfg_campaign.CampaignSubtitle)
    end

    self._endTime = 0
    if self._rewardDoubleComponentInfo then
        self._endTime = self._rewardDoubleComponentInfo.m_close_time
    end

    self:_Init()
end

function UIActivityDoubleDropContent:DoHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self._init = false
end

function UIActivityDoubleDropContent:DoDestroy()
end

-----------------------------------------------------------------------------------

function UIActivityDoubleDropContent:_Init()
    if self._init then
        return
    end
    self._init = true

    local en = not UIActivityZhHelper.IsZh()
    self:GetGameObject("_subTitleImg"):SetActive(not en)

    self._titleLabel:SetText(self._name)
    self._titleLabel2:SetText(self._name)
    self:RefreshRemainTime()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self._timerHandler =
    GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:RefreshRemainTime()
        end
    )
end

function UIActivityDoubleDropContent:RefreshRemainTime()
    if not self._rewardDoubleComponent then
        self:ActivityEnd()
        return
    end

    if not self._rewardDoubleComponent:ComponentIsOpen() then
        self:ActivityEnd()
        return
    end

    if self._endTime == nil then
        self:ActivityEnd()
        return
    end

    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._endTime - nowTime)
    if seconds < 0 then
        seconds = 0
    end
    if seconds == 0 then --2：停留期
        self:ActivityEnd()
        return
    end

    local timeStr = ""
    -- 剩余时间超过24小时，显示N天XX小时。
    -- 剩余时间超过1分钟，显示N小时XX分钟。
    -- 剩余时间小于1分数，显示＜1分钟。
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_activity_double_drop_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_activity_double_drop_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_activity_double_drop_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_activity_double_drop_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_activity_double_drop_less_minus")
        end
    end

    self._timeLabel:SetText(timeStr)
end

function UIActivityDoubleDropContent:ActivityEnd()
    self:CloseDialog()
end

function UIActivityDoubleDropContent:CloseBtnOnClick(go)
    self:CloseDialog(true)
end