_class("UIChatQuickMsgItem", UICustomWidget)
---@class UIChatQuickMsgItem : UICustomWidget
UIChatQuickMsgItem = UIChatQuickMsgItem

function UIChatQuickMsgItem:OnShow(uiParam)
    self._msgLabel = self:GetUIComponent("UILocalizationText", "MsgInfo")
end

---@param uiChatRecentFriendListPanel UIChatRecentFriendListPanel
function UIChatQuickMsgItem:Refresh(quickMsgData, uiChatRecentFriendListPanel)
    self._msg = quickMsgData.msg
    self._msgLabel.text = self._msg
    ---@type UIChatRecentFriendListPanel
    self._uiChatRecentFriendListPanel = uiChatRecentFriendListPanel
end

function UIChatQuickMsgItem:SendOnClick(go)
    self._uiChatRecentFriendListPanel:SendQuickMessage(self._msg)
end
