---@class UIWidgetPopStarStageInfoItem : UICustomWidget
_class("UIWidgetPopStarStageInfoItem", UICustomWidget)
UIWidgetPopStarStageInfoItem = UIWidgetPopStarStageInfoItem

function UIWidgetPopStarStageInfoItem:OnShow()
    ---@type UILocalizationText
    self._txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
end

function UIWidgetPopStarStageInfoItem:OnHide()
end

function UIWidgetPopStarStageInfoItem:Init(desc)
    self._txtDesc:SetText(StringTable.Get(desc))
end
