---@class UICreditsItem:UICustomWidget
_class("UICreditsItem", UICustomWidget)
UICreditsItem = UICreditsItem

function UICreditsItem:OnShow()
    ---@type UILocalizationText
    self.txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    ---@type UnityEngine.UI.GridLayoutGroup
    self.glg = self:GetUIComponent("GridLayoutGroup", "names")
    ---@type UICustomWidgetPool
    self.pool = self:GetUIComponent("UISelectObjectPath", "names")
end

function UICreditsItem:OnHide()
end
