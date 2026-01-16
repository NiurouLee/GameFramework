---@class UICommonReturnHelp:UICustomWidget
_class("UICommonReturnHelp", UICustomWidget)
UICommonReturnHelp = UICommonReturnHelp

function UICommonReturnHelp:Constructor()
end

function UICommonReturnHelp:OnShow(uiParams)
end

function UICommonReturnHelp:SetData(left)
    self._go = self:GetGameObject("rect")
    if self:ReturnHelpOpen() then
        self._go:SetActive(true)
        ---@type UnityEngine.RectTransform
        local layoutGroup = self:GetUIComponent("RectTransform","layoutGroup")
        if left then
            layoutGroup.pivot = Vector2(0,0.5)
            layoutGroup.anchoredPosition = Vector2(-142,0)
        else
            layoutGroup.pivot = Vector2(1,0.5)
            layoutGroup.anchoredPosition = Vector2(142,0)
        end
    else
        self._go:SetActive(false)
    end
end

function UICommonReturnHelp:ReturnHelpOpen()
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    if not campaignModule then
        return false
    end
    local isCmptOpened = false
    local campaignType = UIActivityReturnSystemHelper.GetCampaignType()
    local sampleInfo = campaignModule.m_campaign_manager:GetSampleByType(campaignType)
    if not sampleInfo then
        return false
    end
    local time_mod = GameGlobal.GameLogic():GetModule(SvrTimeModule)
    local tmNowTime = math.modf(time_mod:GetServerTime() / 1000)
    return sampleInfo.is_open and sampleInfo.end_time > tmNowTime
end

function UICommonReturnHelp:OnHide()
end

function UICommonReturnHelp:returnHelpBtnOnClick(go)
    self:ShowDialog("UISideEnterCenterController", { campaign_type = 10060, params = { true }, single_mode = true })
end
