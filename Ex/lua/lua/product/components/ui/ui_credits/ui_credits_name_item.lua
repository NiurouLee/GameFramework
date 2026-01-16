---@class UICreditsNameItem:UICustomWidget
_class("UICreditsNameItem", UICustomWidget)
UICreditsNameItem = UICreditsNameItem

function UICreditsNameItem:OnShow()
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
end

function UICreditsNameItem:OnHide()
end
