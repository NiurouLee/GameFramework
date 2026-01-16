---@class UIChatController:UIController
_class("UIChatController", UIController)
UIChatController = UIChatController

local UIChatPanelType = {
    RecentFriend = 1,
    FriendList = 2,
    AddFirend = 3
}

---@class UIChatPanelType:UIChatPanelType
_enum("UIChatPanelType", UIChatPanelType)

function UIChatController:LoadDataOnEnter(TT, res, uiParams)
    ---@type ChatFriendManager
    self._chatFriendManager = ChatFriendManager:New()
    ---@type SocialModule
    self._socialModule = GameGlobal.GetModule(SocialModule)
    --发送进入聊天消息
    ---@type AsyncRequestRes
    self._socialModule:EnterChatFriendModule(TT)
    --请求好友列表
    self._chatFriendManager:RequestFriendList(TT)
    --请求黑名单数据
    self._chatFriendManager:RequestBlackListData(TT)
    --请求聊天记录
    self._chatFriendManager:GetAllChatDatas()
    
end

function UIChatController:OnShow(uiParams)
    self:AttachEvent(GameEventType.UpdateUnReadMessageStatus, self._UpdateUnReadMessageStatus)
    self:AttachEvent(GameEventType.InModuleFriendNotifyNewMsg, self._ReceiveNewMessage)
    self:AttachEvent(GameEventType.UpdateFriendInvitation, self._UpdateHaveNewFriendRequestStatus)
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    if socialModule.chatInputCache then
        self.chatInputCache = socialModule.chatInputCache
    else
        socialModule.chatInputCache = {}
        self.chatInputCache = socialModule.chatInputCache
    end
    self:_GetComponents()
    self:_Init()
    self:_UpdateHaveNewFriendRequestStatus()
end

--获取组件
function UIChatController:_GetComponents()
    self._recentListUnReadMessageGo = self:GetGameObject("RecentListUnReadMessage")
    self._friendListUnReadMessageGo = self:GetGameObject("FriendListUnReadMessage")
    self._haveNewFriendRequestGo = self:GetGameObject("HaveNewFriendRequest")
    self._recentFriendPanelGo = self:GetGameObject("RecentFriendPanel")
    self._friendListPanelGo = self:GetGameObject("FriendListPanel")
    self._addFriendPanelGo = self:GetGameObject("AddFriendPanel")
    self._recentBtnSelectedGo = self:GetGameObject("RecentBtnSelected")
    self._friendBtnSelectedGo = self:GetGameObject("FriendBtnSelected")
    self._addFriendBtnSelectedGo = self:GetGameObject("AddFriendBtnSelected")

    ---@type ATransitionComponent
    self._transition = self:GetUIComponent("ATransitionComponent", "TransitionComponent")
    self._transition.enabled = true

    local backBtns = self:GetUIComponent("UISelectObjectPath", "BackBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:_Close()
        end
        , nil
        , 
        function()
            self._transition.enabled = false
            self:SwitchState(UIStateType.UIMain)
        end
    )

    local recentFriendPanel = self:GetUIComponent("UISelectObjectPath", "RecentFriendPanel")
    ---@type UIChatRecentFriendListPanel
    self._recentFriendPanel = recentFriendPanel:SpawnObject("UIChatRecentFriendListPanel")

    local friendListPanel = self:GetUIComponent("UISelectObjectPath", "FriendListPanel")
    ---@type UIChatFriendListPanel
    self._friendListPanel = friendListPanel:SpawnObject("UIChatFriendListPanel")

    local addFriendPanel = self:GetUIComponent("UISelectObjectPath", "AddFriendPanel")
    ---@type UIChatAddFriendPanel
    self._addFriendPanel = addFriendPanel:SpawnObject("UIChatAddFriendPanel")
end

function UIChatController:_UpdateUnReadMessageStatus()
    local hasUnReadMessage = self._chatFriendManager:HasUnReadMessage()
    self._recentListUnReadMessageGo:SetActive(hasUnReadMessage)
    self._friendListUnReadMessageGo:SetActive(false)
end

function UIChatController:_ReceiveNewMessage()
    if self._currentPanelType == UIChatPanelType.RecentFriend then
        local hasUnReadMessage = self._chatFriendManager:HasUnReadMessage()
        self._recentListUnReadMessageGo:SetActive(hasUnReadMessage)
        self._friendListUnReadMessageGo:SetActive(false)
    else
        self._recentListUnReadMessageGo:SetActive(true)
        self._friendListUnReadMessageGo:SetActive(false)
    end
end

function UIChatController:_UpdateHaveNewFriendRequestStatus()
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    self._haveNewFriendRequestGo:SetActive(socialModule:HaveNewInvitation())
end

---初始化
function UIChatController:_Init()
    self._currentPanelType = nil
    self:_SwitchPanel(UIChatPanelType.RecentFriend)
end

---切换面板
function UIChatController:_SwitchPanel(panelType)
    if self._currentPanelType == panelType then
        return
    end
    GameGlobal.TaskManager():StartTask(self._SwitchPanelCoro, self, panelType)
end

function UIChatController:_SwitchPanelCoro(TT, panelType)
    self._chatFriendManager:CancelSelectRecentFriend(TT)
    self._recentFriendPanelGo:SetActive(false)
    self._friendListPanelGo:SetActive(false)
    self._addFriendPanelGo:SetActive(false)
    self._recentBtnSelectedGo:SetActive(false)
    self._friendBtnSelectedGo:SetActive(false)
    self._addFriendBtnSelectedGo:SetActive(false)
    if self._currentPanelType then
        if self._currentPanelType == UIChatPanelType.RecentFriend then
            self._recentFriendPanel:Exist()
        elseif self._currentPanelType ==  UIChatPanelType.FriendList then
            self._friendListPanel:Exist()
        end
    end
    self._currentPanelType = panelType
    if panelType == UIChatPanelType.RecentFriend then
        self._recentFriendPanelGo:SetActive(true)
        self._recentBtnSelectedGo:SetActive(true)
        self._recentFriendPanel:Init(self)
    elseif panelType == UIChatPanelType.FriendList then
        self._friendListPanelGo:SetActive(true)
        self._friendBtnSelectedGo:SetActive(true)
        self._friendListPanel:Init(self)
        self._chatFriendManager:ClearCacheCurrentSelectRecentFriend()
    elseif panelType == UIChatPanelType.AddFirend then
        self._addFriendPanelGo:SetActive(true)
        self._addFriendBtnSelectedGo:SetActive(true)
        self._addFriendPanel:Init(self)
        self._chatFriendManager:ClearCacheCurrentSelectRecentFriend()
    end
end

function UIChatController:GetChatFriendManager()
    return self._chatFriendManager
end

function UIChatController:GetCurrentPanelType()
    return self._currentPanelType
end

function UIChatController:_Close()
    self:CloseDialog()
end

function UIChatController:OnHide()
    self:DetachEvent(GameEventType.UpdateUnReadMessageStatus, self._UpdateUnReadMessageStatus)
    self:DetachEvent(GameEventType.InModuleFriendNotifyNewMsg, self._ReceiveNewMessage)
    self:DetachEvent(GameEventType.UpdateFriendInvitation, self._UpdateHaveNewFriendRequestStatus)
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.ModuleFriendNotifyNewMsg)
    self._chatFriendManager:SaveAllChatDatas()
    --发送离开聊天消息
    GameGlobal.TaskManager():StartTask(self._SendLeaveChatFriend, self)
end

--发送离开好友聊天消息
function UIChatController:_SendLeaveChatFriend(TT)
    ---@type AsyncRequestRes
    local res = self._socialModule:LeaveChatFriendModule(TT)
end

-- =========================================== 按钮点击事件 =======================================

---最近联系人按钮点击事件
function UIChatController:RecentBtnOnClick(go)
    self:_SwitchPanel(UIChatPanelType.RecentFriend)
end

---好友列表按钮点击事件
function UIChatController:FriendBtnOnClick(go)
    self:_SwitchPanel(UIChatPanelType.FriendList)
end

---添加好友按钮点击事件
function UIChatController:AddFriendBtnOnClick(go)
    self:_SwitchPanel(UIChatPanelType.AddFirend)
end

-- ================================================================================================
