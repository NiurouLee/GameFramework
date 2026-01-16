---@class UIActivityValentineEndController:UIController
_class("UIActivityValentineEndController", UIController)
UIActivityValentineEndController = UIActivityValentineEndController

function UIActivityValentineEndController:Constructor()
end

function UIActivityValentineEndController:LoadDataOnEnter(TT, res, uiParams)
    res:SetSucc(true)
    ---@type ActivityValentineData
    self._activityData = ActivityValentineData:New()
    self._activityData:LoadData(TT, res)

    local camapign = self._activityData:GetCampaign()
    local isOpen = camapign:CheckCampaignOpen()
    if not isOpen then
        ToastManager.ShowToast(StringTable.Get("str_n27_valentine_y_offline"))
    end
end

function UIActivityValentineEndController:OnShow()
    self:_GetComponent()

    self:_SetCampainTime()
    self:CheckMailRed()
end

function UIActivityValentineEndController:OnHide()
end

function UIActivityValentineEndController:_GetComponent()
    self._redObj = self:GetGameObject("red")
end

--设置活动结束时间
function UIActivityValentineEndController:_SetCampainTime()
    local mailCompInfo = self._activityData:GetMailComponentInfo()
    local endTime = mailCompInfo.m_close_time
    local descId = "str_n27_valentine_y_campaign_cowndown"
    local timeStr = {
            ["day"] = "str_activity_common_day",
            ["hour"] = "str_activity_common_hour",
            ["min"] = "str_activity_common_minute",
            ["zero"] = "str_activity_common_less_minute",
            ["over"] = "str_activity_common_less_minute" -- 超时后还显示小于 1 分钟
        }
    self:_SetRemainingTime("remainingTimePool", descId, endTime, timeStr)
end

function UIActivityValentineEndController:_SetRemainingTime(widgetName, descId, endTime, timeStr)
    ---@type UICustomWidgetPool
    local sop = self:GetUIComponent("UISelectObjectPath", widgetName)
    ---@type UIActivityCommonRemainingTime
    local obj = sop:SpawnObject("UIActivityCommonRemainingTime")

    -- 设置自定义时间文字
    obj:SetCustomTimeStr(timeStr)
    obj:SetExtraRollingText()
    obj:SetAdvanceText(descId)
    obj:SetData(endTime, nil, nil)
end

--检查信箱红点
function UIActivityValentineEndController:CheckMailRed()
    local haveRed = self._activityData:GetMailRed()
    if haveRed then
        self._redObj:SetActive(true)
    else
        self._redObj:SetActive(false)
    end
end
----------------OnClick------------------
function UIActivityValentineEndController:IntroBtnOnClick()
    self:ShowDialog("UIIntroLoader", "UIActivityValentineIntro", MaskType.MT_BlurMask)
end

function UIActivityValentineEndController:MailBoxBtnOnClick()
    if self._activityData:CheckMailIsOver() then
        ToastManager.ShowToast(StringTable.Get("str_n27_valentine_y_offline"))
        self:SwitchState(UIStateType.UIMain)
        return
    end
    self:ShowDialog("UIActivityValentineMailboxController")
end

function UIActivityValentineEndController:BackBtnOnClick()
    self:CloseDialog()
end