---@class UIN20MiniGameWayLine : UICustomWidget
_class("UIN20MiniGameWayLine", UICustomWidget)
UIN20MiniGameWayLine = UIN20MiniGameWayLine
function UIN20MiniGameWayLine:OnShow(uiParams)
    self:_GetComponents()
end
function UIN20MiniGameWayLine:_GetComponents()
    ---@type UnityEngine.UI.Image
    --self._line = self:GetUIComponent("Image", "Line")
end
function UIN20MiniGameWayLine:SetData(state)
end
