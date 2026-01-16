---@class UIActivityEveSinsaSecondTitle_Review:UICustomWidget
_class("UIActivityEveSinsaSecondTitle_Review", UICustomWidget)
UIActivityEveSinsaSecondTitle_Review = UIActivityEveSinsaSecondTitle_Review

function UIActivityEveSinsaSecondTitle_Review:_GetComponents()
    ---@type UILocalizationText
    self._titleText = self:GetUIComponent("UILocalizationText", "_titleText")

    ---@type UILocalizationText
    self._remainingText = self:GetUIComponent("UILocalizationText", "_remainingText")
end

function UIActivityEveSinsaSecondTitle_Review:OnShow()
    self._isOpen = true
    self:_GetComponents()
end

function UIActivityEveSinsaSecondTitle_Review:OnHide()
    self._isOpen = false
    self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end

function UIActivityEveSinsaSecondTitle_Review:SetData(campaign, type)
    self._campaign = campaign
    -- type [0] = 关卡A， [1] = 关卡B
    self._type = type

    self:_SetTitle()
    -- self:_SetTimer()
end

function UIActivityEveSinsaSecondTitle_Review:_SetTitle()
    local id = "str_activity_evesinsa_main_levelabtn"
    if self._type == 1 then
        id = "str_activity_evesinsa_main_levelbbtn"
    end

    self._titleText:SetText(StringTable.Get(id))
end

function UIActivityEveSinsaSecondTitle_Review:_SetTimer()
    -- 开启倒计时
    self._timeEvent =
        UIActivityHelper.StartTimerEvent(
        self._timeEvent,
        function()
            return self:_SetRemainingTimer() -- 返回 stopSign 在首次回调时停止继续创建计时器
        end
    )
end

function UIActivityEveSinsaSecondTitle_Review:_SetRemainingTimer()
    if self._isOpen then
        local uiText = self._remainingText
        local formatStr = "<color=#%s>%s</color>"
        local colorStr = "FFFFFF"

        --- @type SvrTimeModule
        local svrTimeModule = self:GetModule(SvrTimeModule)
        local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
        local endTime = UIActivityEveSinsaHelper.GetPhaseEndTime(self._campaign, EActivityEveSinsaTimePhase.EPhase_Tree) -- 树形关卡关闭时间
        local stamp = endTime - curTime

        local timeStr = UIActivityHelper.GetFormatTimerStr(stamp)
        local showStr = string.format(formatStr, colorStr, timeStr)
        uiText:SetText(showStr)

        if stamp <= 0 then
            self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
            return true -- 返回 stopSign 在首次回调时停止继续创建计时器
        end
    end
end
