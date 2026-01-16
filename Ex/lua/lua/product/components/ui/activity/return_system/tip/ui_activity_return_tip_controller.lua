---@class UIActivityReturnSystemTipController:UIController
_class("UIActivityReturnSystemTipController", UIController)
UIActivityReturnSystemTipController = UIActivityReturnSystemTipController

function UIActivityReturnSystemTipController:LoadDataOnEnter(TT, res, uiParams)
    -- self._campaignType = ECampaignType.CAMPAIGN_TYPE_BACK_PHASE_II
    ---@type UIActivityCampaign
    self._campaign = UIActivityReturnSystemHelper.LoadDataOnEnter(TT, res)
end

function UIActivityReturnSystemTipController:OnShow()
    self._timeText = self:GetUIComponent("UILocalizationText","TimeText")
    self:SetTime()
end

function UIActivityReturnSystemTipController:SetTime()
    --- @type Power2ItemComponent
    local component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "shop", 2)
    ---@type Power2ItemComponentInfo
    local power2ItemInfo = component:GetComponentInfo()
    
    local time = power2ItemInfo.m_close_time
    local endTime = time
    local descId = "str_return_system_tip_time"
    self:_SetRemainingTime("remainingTimePool", descId, endTime)
end

function UIActivityReturnSystemTipController:_SetRemainingTime(widgetName, descId, endTime)
    ---@type UICustomWidgetPool
    local sop = self:GetUIComponent("UISelectObjectPath", widgetName)
    ---@type UIActivityCommonRemainingTime
    local obj = sop:SpawnObject("UIActivityCommonRemainingTime")

    -- 设置自定义时间文字
    obj:SetCustomTimeStr(
        {
            ["day"] = "str_activity_common_day",
            ["hour"] = "str_activity_common_hour",
            ["min"] = "str_activity_common_minute",
            ["zero"] = "str_activity_common_less_minute",
            ["over"] = "str_activity_common_less_minute" -- 超时后还显示小于 1 分钟
        }
    )
    obj:SetExtraRollingText()
    obj:SetAdvanceText(descId)
    obj:SetData(endTime, nil, nil)
end

function UIActivityReturnSystemTipController:OnHide()
end

function UIActivityReturnSystemTipController:BGOnClick()
    self:CloseDialog()
end

