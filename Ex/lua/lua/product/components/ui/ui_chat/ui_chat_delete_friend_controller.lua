---@class UIChatDeleteFriendController:UIController
_class("UIChatDeleteFriendController", UIController)
UIChatDeleteFriendController = UIChatDeleteFriendController

function UIChatDeleteFriendController:OnShow(uiParams)
    ---@type ChatFriendData
    self._friendData = uiParams[1]
    ---@type ChatFriendManager
    self._chatFriendManager = uiParams[2]
    self:_GetComponents()
    self:_Init()
end

--获取组件
function UIChatDeleteFriendController:_GetComponents()
    self._name = self:GetUIComponent("UILocalizationText", "Name")
end

---初始化
function UIChatDeleteFriendController:_Init()
    self._name.text = StringTable.Get("str_chat_delete_friend_confirm", self._friendData:GetName())
end

-- =========================================== 按钮点击事件 =======================================

function UIChatDeleteFriendController:ConfirmBtnOnClick(go)
    self:Lock("ConfirmBtnOnClick")
    GameGlobal.TaskManager():StartTask(self._DeleteFriend, self)
end

function UIChatDeleteFriendController:_DeleteFriend(TT)
    self._chatFriendManager:DeleteFriend(TT, self._friendData:GetFriendId())
    self:UnLock("ConfirmBtnOnClick")
    self:CloseDialog()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeFriendInfoSuccess)
end

function UIChatDeleteFriendController:CancelBtnOnClick(go)
    self:CloseDialog()
end

-- ================================================================================================
