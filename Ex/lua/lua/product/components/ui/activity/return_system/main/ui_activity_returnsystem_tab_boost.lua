---@class UIActivityReturnSystemTabBoost:UICustomWidget
_class("UIActivityReturnSystemTabBoost", UICustomWidget)
UIActivityReturnSystemTabBoost = UIActivityReturnSystemTabBoost

function UIActivityReturnSystemTabBoost:OnShow(uiParams)
    ---@type UILocalizationText
    self.txtDropTimes = self:GetUIComponent("UILocalizationText", "txtDropTimes")
    self.btnFight = self:GetGameObject("btnFight")
end

function UIActivityReturnSystemTabBoost:OnHide()
    self:CancelTimerEventDropTimes()
end

function UIActivityReturnSystemTabBoost:SetData(campaign, remainingTimeCallback, tipsCallback, isBoostIntro)
    self._campaign = campaign
    ---@type ResHelpComponent
    self._component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "boost", 1)
    
    self.remainingTimeCallback = remainingTimeCallback
    self:Flush()

    if isBoostIntro then
        self.btnFight:SetActive(false)
    else
        self._component:CloseTodayRedPoint()
    end
end

function UIActivityReturnSystemTabBoost:Flush()
    local curTimes, maxTimex = self._component:GetBoostTimes()
    local leftTimes = maxTimex - curTimes
    local str = StringTable.Get("str_return_system_extra_drop_times", leftTimes, maxTimex)
    self.txtDropTimes:SetText(str)
    --
    local RegisterTimeEvent = function(seconds)
        self:CancelTimerEventDropTimes()
        self.te =
            GameGlobal.Timer():AddEvent(
            seconds * 1000,
            function()
                self:Flush()
            end
        )
    end
    local resetTime = self._component:GetNextTimestamp()
    local leftSeconds = UICommonHelper.CalcLeftSeconds(resetTime)
    RegisterTimeEvent(leftSeconds)
    if self.remainingTimeCallback then
        self.remainingTimeCallback(resetTime)
    end
end

function UIActivityReturnSystemTabBoost:CancelTimerEventDropTimes()
    if self.te then
        GameGlobal.Timer():CancelEvent(self.te)
    end
end

function UIActivityReturnSystemTabBoost:btnFightOnClick(go)
    local curTimes, maxTimex = self._component:GetBoostTimes()
    if curTimes >= maxTimex then
        ToastManager.ShowToast(StringTable.Get("str_return_system_extra_drop_times_not_enough"))
        return
    end
    --获取跳转配置，打开界面，默认配置资源本主界面，走通用跳转
    ---@type UIJumpModule
    local uiJumpModule = GameGlobal.GetUIModule(QuestModule)
    local jumpID = UIJumpType.UI_JumpResDungeon
    local jumpParam = nil
    uiJumpModule:SetJumpUIData(jumpID, jumpParam)
    uiJumpModule:Jump()

    -- --获取功能解锁的数据
    -- local module = GameGlobal.GetModule(RoleModule)
    -- local isLock = not module:CheckModuleUnlock(GameModuleID.MD_ResDungeon)
    -- if isLock then
    --     ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
    --     return
    -- end
    -- GameGlobal.UIStateManager():ShowDialog("UIResEntryController")
end
