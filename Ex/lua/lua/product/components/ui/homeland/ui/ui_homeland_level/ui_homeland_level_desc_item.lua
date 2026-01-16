---@class UIHomelandLevelDescItem:UICustomWidget
_class("UIHomelandLevelDescItem", UICustomWidget)
UIHomelandLevelDescItem = UIHomelandLevelDescItem

function UIHomelandLevelDescItem:Constructor()
end

function UIHomelandLevelDescItem:OnShow()
    ---@type UILocalizationText
    self.txt = self:GetUIComponent("UILocalizationText", "txt")
end

function UIHomelandLevelDescItem:Flush(desc)
    self.txt:SetText(desc)
end
