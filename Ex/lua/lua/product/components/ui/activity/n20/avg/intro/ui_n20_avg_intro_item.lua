---@class UIN20AVGIntroItem:UICustomWidget
_class("UIN20AVGIntroItem", UICustomWidget)
UIN20AVGIntroItem = UIN20AVGIntroItem

function UIN20AVGIntroItem:OnShow()
    ---@type UILocalizationText
    self.txtHead = self:GetUIComponent("UILocalizationText", "txtHead")
    ---@type UILocalizationText
    self.txtBody = self:GetUIComponent("UILocalizationText", "txtBody")
end

---@param head string
---@param body string
function UIN20AVGIntroItem:Flush(head, body)
    self.txtHead:SetText(head)
    self.txtBody:SetText(body)
end
