---@class ChatDataManager:Object
_class("ChatDataManager", Object)
ChatDataManager = ChatDataManager

function ChatDataManager:Constructor()
    self._chatDatas = nil
    self._chatDataKey = nil
end

--发送消息
---@param chatFriendManager ChatFriendManager
function ChatDataManager:SendMessage(TT, chatFriendManager, friendId, messageType, message, emojiId)
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type chat_message_info
    local res, msgInfo = socialModule:SendFriendMsg(TT, friendId, messageType, message, emojiId)

    if res:GetSucc() then
        local chatData = ChatData:New(msgInfo.msg_id,
                                      msgInfo.friend_msg_type,
                                      msgInfo.chat_message,
                                      msgInfo.emoji_id,
                                      true,
                                      msgInfo.chat_time)

        self:AddChatData(friendId, chatData)
        self:ReceiveMessage(friendId)
    elseif res:GetResult() == SocialErrorCode.SOCIAL_CHAT_PEER_NOT_FRIEND then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ChatFriendNotYourFriend, friendId)
    else
        chatFriendManager:HandleErrorMsgCode(res:GetResult())
    end
end

--接受消息
function ChatDataManager:ReceiveMessage(friendId)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ReceiveChatMessage, friendId, true)
end

--添加消息数据
---@param chatData ChatData
function ChatDataManager:AddChatData(friendId, chatData)
    if self._chatDatas[friendId] == nil then
        self._chatDatas[friendId] = {}
    end
    local hasContain = false
    local chatCount = #self._chatDatas[friendId]
    for i = 1, chatCount do
        ---@type ChatData
        local tempChatData = self._chatDatas[friendId][i]
        if tempChatData:GetId() == chatData:GetId() then
            hasContain = true
            break
        end
    end
    if not hasContain then
        self._chatDatas[friendId][#self._chatDatas[friendId] + 1] = chatData
        self:_RefreshChatDataTimeStatus()
    end
end

--删除聊天记录
function ChatDataManager:DeleteChatData(friendId)
    if not friendId or not self._chatDatas[friendId] then
        return
    end
    self._chatDatas[friendId] = nil
end

--获取聊天记录
function ChatDataManager:GetChatData(friendId)
    if not self._chatDatas or not friendId then
        return nil
    end
    local success = self:_RemoveChatData(friendId)
    if success then
        self:_RefreshChatDataTimeStatus()
    end
    return self._chatDatas[friendId]
end

---@param chatFriendManager ChatFriendManager
function ChatDataManager:RequestChatData(TT, chatFriendManager, friendId)
    --请求未读的聊天数据
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type AsyncRequestRes
    local res, msgList = socialModule:SelectChatFriend(TT, friendId)
    if res:GetSucc() then
        if msgList then
            for i = #msgList, 1, -1 do
                ---@type chat_message_info
                local chatInfo = msgList[i]
                local chatData = ChatData:New(chatInfo.msg_id,
                                              chatInfo.friend_msg_type,
                                              chatInfo.chat_message,
                                              chatInfo.emoji_id,
                                              false,
                                              chatInfo.chat_time)
                self:AddChatData(friendId, chatData)
            end
        end
        chatFriendManager:ResetFriendUnReadMessageStatus(friendId)
    else
        chatFriendManager:HandleErrorMsgCode(res:GetResult())
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateUnReadMessageStatus)

    self:SaveAllChatDatas()

    self:PushCurStoreMaxMsgId(friendId)

    return self:GetChatData(friendId)
end

function ChatDataManager:PushCurStoreMaxMsgId(senderPstId)
    if not self._chatDatas[senderPstId] then
        return
    end
    if #self._chatDatas[senderPstId] <= 0 then
        return
    end
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type ChatData
    local chatData = self._chatDatas[senderPstId][#self._chatDatas[senderPstId]]
     --告诉服务器我已经保存了消息
     socialModule:PushCurStoreMaxMsgId(senderPstId, chatData:GetId())
end

--删除多余的聊天数据
function ChatDataManager:_RemoveChatData(friendId)
    if not self._chatDatas[friendId] then
        return
    end
    local chatCount = #self._chatDatas[friendId]
    local maxCount = Cfg.cfg_friend_global[1].client_save_max_msg_count
    if chatCount <= maxCount then
        return false
    end
    local moreCount = chatCount - maxCount
    for i = moreCount, 1, -1 do
        table.remove(self._chatDatas[friendId], i)
    end
    return true
end

--获取所有的聊天记录
function ChatDataManager:GetAllChatDatas(TT, friendList)
    self._chatDatas = {}
    --读取本地数据
    self:_ReadLocalChatDatas(friendList)
    self:_ReadServerChatDatas(TT)
end

--读取本地数据
function ChatDataManager:_ReadLocalChatDatas(friendList)
    local chatDataKey = self:_GetChatDataKey()
    local localChatDatasStr = UnityEngine.PlayerPrefs.GetString(chatDataKey)
    if not localChatDatasStr or localChatDatasStr == "" then
        return
    end

    local func = load("return" .. localChatDatasStr)
    if func == nil then
        localChatDatasStr = string.gsub(localChatDatasStr, "\\", "\\\\")
        localChatDatasStr = string.gsub(localChatDatasStr, "\r\n", "")
        func = load("return" .. localChatDatasStr)
    end
    
    local chatDataTable = {}
    if func ~= nil then
        chatDataTable = func()
    end
    
    local isContainFriendIdFunc = 
            function(friendDatas, friendId)
                if not friendDatas then
                    return false
                end
                for k, v in pairs(friendDatas) do
                    if friendId == v:GetFriendId() then
                        return true
                    end
                end
                return false
            end

    for friendId, chatDatas in pairs(chatDataTable) do
        if isContainFriendIdFunc(friendList, friendId) then
            if self._chatDatas[friendId] == nil then
                self._chatDatas[friendId] = {}
            end
            for i = 1, #chatDatas do
                local data = chatDatas[i]
                local chatData = ChatData:New(data._id, data._messageType, data._message, data._emojiId, data._isSelf, data._date)
                self._chatDatas[friendId][#self._chatDatas[friendId] + 1] = chatData
            end
        end
    end
    self:_RefreshChatDataTimeStatus()
end

function ChatDataManager:_RefreshChatDataTimeStatus()
    for friendId, chatDatas in pairs(self._chatDatas) do
        local firstData = nil
        for i = 1, #chatDatas do
            ---@type ChatData
            local chatData = chatDatas[i]
            if i == 1 then
                chatData:SetShowTimeStatus(true)
                firstData = chatData
            else
                ---@type ChatData
                local preChatData = chatDatas[i - 1]
                local isSameDay = SameDay(preChatData:GetDate(), chatData:GetDate())
                if isSameDay then
                    local preDate = _time(firstData:GetDate())
                    local curDate = _time(chatData:GetDate())
                    local preMin = preDate.min
                    local curMin = curDate.min
                    local min = (curDate.hour - preDate.hour) * 60 + curMin - preMin
                    if min >= 30 then
                        chatData:SetShowTimeStatus(true)
                        firstData = chatData
                    else
                        chatData:SetShowTimeStatus(false)
                    end
                else
                    chatData:SetShowTimeStatus(true)
                    firstData = chatData
                end
            end
        end
    end
end

--读取服务器数据
function ChatDataManager:_ReadServerChatDatas(TT)

end

--保存所有的聊天记录
---@param chatDatas ChatData[]
function ChatDataManager:SaveAllChatDatas()
    local chatDataKey = self:_GetChatDataKey()
    if not self._chatDatas or table.count(self._chatDatas) <= 0 then
        UnityEngine.PlayerPrefs.DeleteKey(chatDataKey)
        return
    end

    for k, v in pairs(self._chatDatas) do
        for i = 1, #v do
            v[i]:EncodeMessage()
        end
    end
    local chatDatasStr = echo_not_escape(self._chatDatas)
    for k, v in pairs(self._chatDatas) do
        for i = 1, #v do
            v[i]:DecodeMessage()
        end
    end
    UnityEngine.PlayerPrefs.SetString(chatDataKey, chatDatasStr)
end

function ChatDataManager:_GetChatDataKey()
    if self._chatDataKey then
        return self._chatDataKey
    end
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local chatDataKey = "CHAT_DATA_KEY_1VERSION" .. pstId
    self._chatDataKey = chatDataKey
    return chatDataKey
end
