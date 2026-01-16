--N25 入口按钮困难关
---@class UIN25EntryBtnHardLevel : UIN25EntryBtnBase
_class("UIN25EntryBtnHardLevel", UIN25EntryBtnBase)
UIN25EntryBtnHardLevel = UIN25EntryBtnHardLevel

--初始化
function UIN25EntryBtnHardLevel:OnShow(uiParams)
    self:InitWidget()
end
function UIN25EntryBtnHardLevel:OnHide()
    self:CancelTimeEvent()
end

---@param activityConst UIActivityN25Const 
function UIN25EntryBtnHardLevel:RefreshState(activityConst)
    self.activityConst = activityConst
    self:RefreshStateInternal()

     -- 开启倒计时
     self._timeEvent = UIActivityHelper.StartTimerEvent(
        self._timeEvent,
        function()
            self:RefreshStateInternal()
        end
    )
end

function UIN25EntryBtnHardLevel:RefreshStateInternal()
    local c, cInfo  = self.activityConst:GetHardComponent()
    if nil == cInfo then
        return
    end
    local red = self.activityConst:CheckRedHard()
    local new = self.activityConst:CheckNewHard()
    self:SetLock(true)
    self:SetNewAndRed(new, red)
   
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    local state = self.activityConst:GetStateHard()
    if state == UISummerOneEnterBtnState.NotOpen then
        local unlockTime = cInfo.m_unlock_time
        local seconds = math.floor((unlockTime - nowTimestamp))
        -- local seconds = math.floor((unlockTime - nowTimestamp)/1000)
        -- local seconds = UICommonHelper.CalcLeftSeconds(closeTime)
        local timeStr = UIActivityN25Const.GetTimeString(seconds)
        local timeTips = StringTable.Get("str_n25_activity_remain_open_time", timeStr)
        self:SetLeftTime(timeTips)
    elseif state == UISummerOneEnterBtnState.Normal then
        self:SetLock(false)
        self:SetLeftTimeShow(false)
        -- local nowTimestamp = UICommonHelper.GetNowTimestamp()
        -- local closeTime = cInfo.m_close_time
        -- local seconds = UICommonHelper.CalcLeftSeconds(closeTime)
        -- --local seconds = math.floor((closeTime - nowTimestamp)/1000)
        -- local timeStr = UIActivityN25Const.GetTimeString(seconds)
        -- local timeTips = StringTable.Get("str_n25_activity_remain_time", timeStr)
        -- self:SetLeftTime(timeTips)
    elseif state == UISummerOneEnterBtnState.Locked then
        self:SetLeftTimeShow(true)
        self:SetLeftTime(StringTable.Get("str_n25_hardlevel_locktip"))
        self:CancelTimeEvent()
    elseif state == UISummerOneEnterBtnState.Closed then
        self:SetLeftTimeShow(true)
        self:SetLeftTime(StringTable.Get("str_n25_activity_end"))
        self:CancelTimeEvent()
    end
end

function UIN25EntryBtnHardLevel:CancelTimeEvent()
    self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end