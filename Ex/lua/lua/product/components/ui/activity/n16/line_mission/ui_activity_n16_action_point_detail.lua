---@class UIActivityN16ActionPointDetail : UIController
_class("UIActivityN16ActionPointDetail", UIController)
UIActivityN16ActionPointDetail = UIActivityN16ActionPointDetail

function UIActivityN16ActionPointDetail:_SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIActivityN16ActionPointDetail:OnShow(uiParams)
    --self:_SetIcon("_icon", uiParams[1])--改用固定image
end

function UIActivityN16ActionPointDetail:OnHide()
end

function UIActivityN16ActionPointDetail:CloseBtnOnClick(go)
    self:CloseDialog()
end
