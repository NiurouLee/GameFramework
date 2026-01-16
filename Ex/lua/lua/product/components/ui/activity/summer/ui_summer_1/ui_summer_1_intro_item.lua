---@class UISummer1IntroItem:UICustomWidget
_class("UISummer1IntroItem", UICustomWidget)
UISummer1IntroItem = UISummer1IntroItem

function UISummer1IntroItem:OnShow()
    ---@type UILocalizationText
    self.txtHead = self:GetUIComponent("UILocalizationText", "txtHead")
    ---@type UILocalizationText
    self.txtBody = self:GetUIComponent("UILocalizationText", "txtBody")
end

---@param head string
---@param body string
function UISummer1IntroItem:Flush(head, body)
    self.txtHead:SetText(head)
    self.txtBody:SetText(body)
end
