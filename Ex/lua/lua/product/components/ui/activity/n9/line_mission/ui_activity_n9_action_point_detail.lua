---@class UIActivityN9ActionPointDetail : UIController
_class("UIActivityN9ActionPointDetail", UIController)
UIActivityN9ActionPointDetail = UIActivityN9ActionPointDetail

function UIActivityN9ActionPointDetail:_SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIActivityN9ActionPointDetail:OnShow(uiParams)
    --self:_SetIcon("_icon", uiParams[1])--改用固定image
end

function UIActivityN9ActionPointDetail:OnHide()
end

function UIActivityN9ActionPointDetail:CloseBtnOnClick(go)
    self:CloseDialog()
end
