---@class UIActivityEveSinsaIntrItem:UICustomWidget
_class("UIActivityEveSinsaIntrItem", UICustomWidget)
UIActivityEveSinsaIntrItem = UIActivityEveSinsaIntrItem

function UIActivityEveSinsaIntrItem:OnShow()
    ---@type UILocalizationText
    self.txtHead = self:GetUIComponent("UILocalizationText", "txtHead")
    ---@type UILocalizationText
    self.txtBody = self:GetUIComponent("UILocalizationText", "txtBody")
end

---@param head string
---@param body string
function UIActivityEveSinsaIntrItem:Flush(head, body)
    self.txtHead:SetText(head)
    self.txtBody:SetText(body)
end
