---@class UIN13ActionPointDetail : UIController
_class("UIN13ActionPointDetail", UIController)
UIN13ActionPointDetail = UIN13ActionPointDetail

function UIN13ActionPointDetail:_SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIN13ActionPointDetail:OnShow(uiParams)
    --self:_SetIcon("_icon", uiParams[1])--改用固定image
end

function UIN13ActionPointDetail:OnHide()
end

function UIN13ActionPointDetail:CloseBtnOnClick(go)
    self:CloseDialog()
end
