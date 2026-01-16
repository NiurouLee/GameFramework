---@class UISummerActivityTwoLevelBossItem : UICustomWidget
_class("UISummerActivityTwoLevelBossItem", UICustomWidget)
UISummerActivityTwoLevelBossItem = UISummerActivityTwoLevelBossItem

function UISummerActivityTwoLevelBossItem:OnShow()
    self._tipsLabel = self:GetUIComponent("UILocalizationText", "Tips")
    self._tipsGo = self:GetGameObject("Tips")
    self._lockGo = self:GetGameObject("Lock")
    self._nameLabel = self:GetUIComponent("UILocalizationText", "Name")
    self._scoreGo = self:GetGameObject("Score")
    self._scoreLabel = self:GetUIComponent("UILocalizationText", "Score")
    self._timerGo = self:GetGameObject("Timer")
    self._timerLabel = self:GetUIComponent("UILocalizationText", "Timer")
    self._redGo = self:GetGameObject("Red")
    self._iconImg = self:GetUIComponent("RawImageLoader", "Icon")
    self._iconGo = self:GetGameObject("Icon")
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    self._timerHandler = nil
end

function UISummerActivityTwoLevelBossItem:OnHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
end

---@param levelData UISummerActivityTwoLevelData
function UISummerActivityTwoLevelBossItem:Refresh(levelData)
    ---@type UISummerActivityTwoLevelData
    self._levelData = levelData
    local status = self._levelData:GetStatus()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self._iconImg:LoadImage(UISummerActivityTwoConst.EntryIcon)
    if status == UISummerActivityTwoLevelStatus.UnOpen then  --未解锁
        self._lockGo:SetActive(true)
        self._redGo:SetActive(false)
        self._scoreGo:SetActive(false)
        self._iconGo:SetActive(false)
        self._tipsGo:SetActive(true)
        self._scoreLabel.text = 0
        self._nameLabel:SetText(self._levelData:GetName())
        self._tipsLabel:SetText(StringTable.Get("str_summer_activity_two_level_un_open_tips"))
        if levelData:IsPreLevelCondition() then --前置管卡解锁
            self._timerGo:SetActive(false)
        else
            self._timerGo:SetActive(true)
            self._timerLabel.text = StringTable.Get("str_summer_activity_two_boss_level_unopen_time_tips", self:RefreshRemainTime())
            self._timerHandler = GameGlobal.Timer():AddEventTimes(10, TimerTriggerCount.Infinite,
                                                function()
                                                    self._timerLabel.text = StringTable.Get("str_summer_activity_two_boss_level_unopen_time_tips", self:RefreshRemainTime())
                                                end
                                            )
        end
    elseif status == UISummerActivityTwoLevelStatus.UnComplete then --未通关
        self._lockGo:SetActive(false)
        self._redGo:SetActive(true)
        self._timerGo:SetActive(false)
        self._nameLabel:SetText(self._levelData:GetName())
        self._scoreGo:SetActive(false)
        self._iconGo:SetActive(false)
        self._tipsGo:SetActive(true)
        self._tipsLabel:SetText(StringTable.Get("str_summer_activity_two_level_unstart"))
        self._scoreLabel.text = 0
    elseif status == UISummerActivityTwoLevelStatus.Complete then --已经通关
        self._lockGo:SetActive(false)
        self._redGo:SetActive(false)
        self._timerGo:SetActive(false)
        self._nameLabel:SetText(self._levelData:GetName())
        self._scoreGo:SetActive(true)
        self._iconGo:SetActive(true)
        self._tipsGo:SetActive(false)
        self._scoreLabel.text = self._levelData:GetMaxScore()
    end
end

function UISummerActivityTwoLevelBossItem:BtnOnClick()
    if self._levelData:GetStatus() == UISummerActivityTwoLevelStatus.UnOpen then
        if self._levelData:IsPreLevelCondition() then
            ToastManager.ShowToast(StringTable.Get("str_summer_activity_two_level_unlock_tips"))
        else
            local remainTimeStr = self:RefreshRemainTime()
            ToastManager.ShowToast(StringTable.Get("str_summer_activity_two_normal_level_unopen_tips", remainTimeStr))
        end
        return
    end
    self:ShowDialog("UISummerActivityTwoLevelDetail", self._levelData)
end

function UISummerActivityTwoLevelBossItem:BtnMaskOnClick()
    self:BtnOnClick()
end

function UISummerActivityTwoLevelBossItem:RefreshRemainTime()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._levelData:GetTimes() - nowTime)
    if seconds < 0 then
        seconds = 0
        self._levelData:CalStatus()
        self:Refresh(self._levelData)
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
        timeStr = StringTable.Get("str_summer_activity_two_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_summer_activity_two_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_summer_activity_two_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_summer_activity_two_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_summer_activity_two_less_minus")
        end
    end

    return timeStr
end
