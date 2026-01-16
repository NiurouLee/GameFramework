---@class UIN28AVGIntroItem:UICustomWidget
_class("UIN28AVGIntroItem", UICustomWidget)
UIN28AVGIntroItem = UIN28AVGIntroItem

function UIN28AVGIntroItem:OnShow()
    ---@type UILocalizationText
    self.txtHead = self:GetUIComponent("UILocalizationText", "txtHead")
    ---@type UILocalizationText
    self.txtBody = self:GetUIComponent("UILocalizationText", "txtBody")
end

---@param head string
---@param body string
function UIN28AVGIntroItem:Flush(head, body)
    self.txtHead:SetText(head)
    self.txtBody:SetText(body)
end
