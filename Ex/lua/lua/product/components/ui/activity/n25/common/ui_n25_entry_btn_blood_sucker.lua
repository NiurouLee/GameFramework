--N25 入口按钮小游戏吸血鬼
---@class UIN25EntryBtnBloodSucker : UIN25EntryBtnBase
_class("UIN25EntryBtnBloodSucker", UIN25EntryBtnBase)
UIN25EntryBtnBloodSucker = UIN25EntryBtnBloodSucker

--初始化
function UIN25EntryBtnBloodSucker:OnShow(uiParams)
    self:InitWidget()
end
function UIN25EntryBtnBloodSucker:OnHide()
    self:CancelTimeEvent()
end

---@param activityConst UIActivityN25Const 
function UIN25EntryBtnBloodSucker:RefreshState(activityConst)
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

function UIN25EntryBtnBloodSucker:RefreshStateInternal()
    local c, cInfo  = self.activityConst:GetBloodSuckerComponent()
    if nil == cInfo then
        return
    end
    local red = self.activityConst:CheckGameBloodSuckerRed()
    local new = self.activityConst:CheckGameBloodSuckerNew()
    self:SetLock(true)
    self:SetNewAndRed(new, red)
   
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    local closeTime = cInfo.m_close_time
    local state = self.activityConst:GetStateGameBloodSucker()
    if state == UISummerOneEnterBtnState.NotOpen then
        local unlockTime = cInfo.m_unlock_time
        local seconds = math.floor((unlockTime - nowTimestamp))
        --local seconds = UICommonHelper.CalcLeftSeconds(closeTime)
        local timeStr = UIActivityN25Const.GetTimeString(seconds)
        local timeTips = StringTable.Get("str_n25_activity_remain_open_time", timeStr)
        self:SetLeftTime(timeTips)
    elseif state == UISummerOneEnterBtnState.Normal then
        self:SetLock(false)
        self:SetLeftTimeShow(false)
        self:CancelTimeEvent()
        -- local nowTimestamp = UICommonHelper.GetNowTimestamp()
        -- -- local seconds = math.floor((closeTime - nowTimestamp)/1000)
        -- local seconds = UICommonHelper.CalcLeftSeconds(closeTime)
        -- local timeStr = UIActivityN25Const.GetTimeString(seconds)
        -- local timeTips = StringTable.Get("str_n25_activity_remain_time", timeStr)
        -- self:SetLeftTime(timeTips)
    elseif state == UISummerOneEnterBtnState.Closed then
        -- self:SetLeftTime(StringTable.Get("str_n25_activity_end"))
        self:SetLeftTimeShow(false)
        self:CancelTimeEvent()
    end
end

function UIN25EntryBtnBloodSucker:CancelTimeEvent()
    self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end