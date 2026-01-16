---@class UITopTipsContext:UICustomWidget
_class("UITopTipsContext", UICustomWidget)
UITopTipsContext = UITopTipsContext

function UITopTipsContext:OnShow(uiParams)
    self._rect = self:GetUIComponent("RectTransform", "rect")
end
function UITopTipsContext:OnHide()
end
function UITopTipsContext:SetData(enum, go)
    self:Lock("UITopTips")

    self._rect.position = go:GetComponent("Transform").position
    local anchoredPosition = self._rect.anchoredPosition
    self:StartTask(
        function(TT)
            YIELD(TT, 50)
            self:ShowDialog("UITopTipsController", enum, anchoredPosition)
        end,
        self
    )
end
