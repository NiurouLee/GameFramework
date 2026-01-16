---@class UIPayLawContentController:UIController
_class("UIPayLawContentController", UIController)
UIPayLawContentController = UIPayLawContentController

function UIPayLawContentController:OnShow(uiParams)
    self._contentLabel = self:GetUIComponent("UILocalizationText", "Content")
    self._titleLabel = self:GetUIComponent("UILocalizationText", "Title")
    self._contentType = uiParams[1]
    local tips = ""
    local title = ""
    if self._contentType == 1 then --特商法
        tips = StringTable.Get("str_pay_law_content_des1")
        title = StringTable.Get("str_pay_law_content_title1")
    elseif self._contentType == 2 then --资金结算法
        tips = StringTable.Get("str_pay_law_content_des2")
        title = StringTable.Get("str_pay_law_content_title2")
    elseif self._contentType == 3 then --限时充值返利
        tips = StringTable.Get("str_pay_limited_time_recharge_content")
        title = StringTable.Get("str_pay_limited_time_recharge_title")
    end
    self._contentLabel:SetText(tips)
    self._titleLabel:SetText(title)
    self._confirmBtn = self:GetGameObject("ConfirmBtn")
    self._confirmClick = self:GetGameObject("ConfirmClick")
    local confirmBtn = UIEventTriggerListener.Get(self._confirmBtn)
    confirmBtn.onDown = function(go)
        self._confirmClick:SetActive(true)
    end
    confirmBtn.onUp = function(go)
        self._confirmClick:SetActive(false)
        self:CloseDialog()
    end
end

function UIPayLawContentController:ConfirmBtnOnClick()
end
