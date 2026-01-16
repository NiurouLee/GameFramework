---@class UIN22EntrustLevelPlayer : UICustomWidget
_class("UIN22EntrustLevelPlayer", UICustomWidget)
UIN22EntrustLevelPlayer = UIN22EntrustLevelPlayer

function UIN22EntrustLevelPlayer:PlayAnim(animName, delay, duration, callback)
    local widgetName = "_anim"
    local hideWidget = "_anim"
    UIWidgetHelper.PlayAnimationInSequence(self, widgetName, hideWidget, animName, delay, duration, callback)
end

function UIN22EntrustLevelPlayer:OnShow(uiParams)
end

function UIN22EntrustLevelPlayer:SetShow(show) -- 调试按钮需要隐藏
    self:GetGameObject():SetActive(show)
end

function UIN22EntrustLevelPlayer:SetData(component, nodeId)
    self:SetShow(true)
    local flag = self._nodeId ~= nodeId

    ---@type EntrustComponent
    self._component = component
    self._nodeId = nodeId
    self:_SetPos(nodeId)
end

function UIN22EntrustLevelPlayer:_SetPos(nodeId)
    local pos = self._component:GetEventPointPos(nodeId)

    local rect = self:GetGameObject():GetComponent("RectTransform")
    rect.anchorMax = Vector2(0, 0.5)
    rect.anchorMin = Vector2(0, 0.5)
    rect.sizeDelta = Vector2.zero
    rect.anchoredPosition = pos
end
