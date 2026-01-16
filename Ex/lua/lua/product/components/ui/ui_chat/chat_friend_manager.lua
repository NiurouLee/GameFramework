---@class ChatFriendManager:Object
_class("ChatFriendManager", Object)
ChatFriendManager = ChatFriendManager

function ChatFriendManager:Constructor()
    self._friendList = {}
    self._recentChatList = {}
    self._blackList = {}
    ---@type ChatDataManager
    self._chatDataManager = ChatDataManager:New()
    ---@type ChatFriendData
    self._currentSelectedChatFriendId = nil
end

function ChatFriendManager:ResetFriendUnReadMessageStatus(friendId)
    for i = 1, #self._friendList do
        ---@type ChatFriendData
        local friendData = self._friendList[i]
        if friendData:GetFriendId() == friendId then
            friendData:ResetUnReadMessageStatus()
            break
        end
    end
    for i = 1, #self._recentChatList do
        ---@type ChatFriendData
        local friendData = self._recentChatList[i]
        if friendData:GetFriendId() == friendId then
            friendData:ResetUnReadMessageStatus()
            break
        end
    end
end

--请求好友列表
function ChatFriendManager:RequestFriendList(TT)
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type map<TPersistID, social_info_mobile>
    local friendList = socialModule:GetFriendList(TT) or {}  --如果断线或网络异常会导致返回nil 这里做容错处理 避免客户端后续逻辑报错

    self._friendList = {}

    for pstId, data in pairs(friendList) do
        ---@type social_player_info
        local simpleInfo = data.simple_info -- 好友基础信息
        local createTime = simpleInfo.create_time -- 创建时间
        local unReadMsgNum = data.un_read_msg_num -- 未读消息数量
        local endMsgTime = data.end_msg_time -- 最后一条的未读消息时间

        local hasNewMessage = false
        if unReadMsgNum > 0 then
            hasNewMessage = true
        end

        local chatFriendData =
            ChatFriendData:New(
            simpleInfo.pstid,
            simpleInfo.head,
            simpleInfo.head_bg,
            simpleInfo.frame_id,
            simpleInfo.level,
            simpleInfo.nick,
            hasNewMessage,
            simpleInfo.is_online,
            createTime,
            endMsgTime,
            simpleInfo.last_logout_time,
            simpleInfo.remark_name,
            simpleInfo.help_pet,
            simpleInfo.world_boss_info,
            simpleInfo.homeland_info
        )
        self._friendList[#self._friendList + 1] = chatFriendData
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateUnReadMessageStatus)
end

--获取好友列表
function ChatFriendManager:GetFriendList(sort)
    if sort then
        table.sort(
            self._friendList,
            function(a, b)
                local aPriority = 0
                local bPriority = 0
                if a:IsOnline() and not b:IsOnline() then
                    aPriority = 10
                elseif not a:IsOnline() and b:IsOnline() then
                    bPriority = 10
                end

                local aLevel = a:GetLevel()
                local bLevel = b:GetLevel()

                if aLevel ~= bLevel then
                    if aLevel > bLevel then
                        aPriority = aPriority + 1
                    elseif aLevel < bLevel then
                        bPriority = bPriority + 1
                    end
                end

                if aPriority ~= bPriority then
                    return aPriority > bPriority
                end

                return a:GetFriendId() > b:GetFriendId()
            end
        )
    end
    return self._friendList
end

--获取最近聊天列表
function ChatFriendManager:GetRecentChatList()
    local friendList = self:GetFriendList(false)
    self._recentChatList = {}
    for i = 1, #friendList do
        ---@type ChatFriendData
        local friendData = friendList[i]
        local chatDatas = self._chatDataManager:GetChatData(friendData:GetFriendId())
        if chatDatas and table.count(chatDatas) > 0 then
            local recentFriendData = ChatFriendData:New()
            recentFriendData:Init(friendData)
            self._recentChatList[#self._recentChatList + 1] = recentFriendData
            if recentFriendData:GetFriendId() == self._currentSelectedChatFriendId then
                recentFriendData:SetSelectedStatus(true)
            end
        else
            if friendData:HasNewMessage() then
                local recentFriendData = ChatFriendData:New()
                recentFriendData:Init(friendData)
                self._recentChatList[#self._recentChatList + 1] = recentFriendData
                if recentFriendData:GetFriendId() == self._currentSelectedChatFriendId then
                    recentFriendData:SetSelectedStatus(true)
                end
            end
        end
    end
    --排序
    table.sort(
        self._recentChatList,
        function(a, b)
            local aChatData = self._chatDataManager:GetChatData(a:GetFriendId())
            local aTime = 0
            if aChatData and #aChatData > 0 then
                ---@type ChatData
                local chatData = aChatData[#aChatData]
                aTime = chatData:GetDate()
            end
            if a:HasNewMessage() then
                aTime = a:GetRecentMsgTime()
            end

            local bChatData = self._chatDataManager:GetChatData(b:GetFriendId())
            local bTime = 0
            if bChatData and #bChatData > 0 then
                ---@type ChatData
                local chatData = bChatData[#bChatData]
                bTime = chatData:GetDate()
            end
            if b:HasNewMessage() then
                bTime = b:GetRecentMsgTime()
            end

            local aPriority = 0
            local bPriority = 0

            if a:HasNewMessage() and not b:HasNewMessage() then
                aPriority = 10
            elseif not a:HasNewMessage() and b:HasNewMessage() then
                bPriority = 10
            end

            if aTime ~= bTime then
                if aTime > bTime then
                    aPriority = aPriority + 1
                elseif aTime < bTime then
                    bPriority = bPriority + 1
                end
            end

            if aPriority ~= bPriority then
                return aPriority > bPriority
            end

            return a:GetFriendId() > b:GetFriendId()
        end
    )

    if self._needAddRecentFriendId and self:IsMyFriend(self._needAddRecentFriendId) then
        ---@type ChatFriendData
        local friendData = self:GetRecentChatFriendDataById(self._needAddRecentFriendId)
        if not friendData then
            friendData = self:GetFriendDataById(self._needAddRecentFriendId)
            ---@type ChatFriendData
            local recentFriendData = ChatFriendData:New()
            recentFriendData:Init(friendData)
            table.insert(self._recentChatList, 1, recentFriendData)
            if recentFriendData:GetFriendId() == self._currentSelectedChatFriendId then
                recentFriendData:SetSelectedStatus(true)
            end
        end
    end
    return self._recentChatList
end

function ChatFriendManager:GetFriendDataById(friendId)
    if not friendId then
        return nil
    end
    local friendList = self:GetFriendList(false)
    if not friendList then
        return nil
    end
    for i = 1, #friendList do
        ---@type ChatFriendData
        local friendData = friendList[i]
        if friendData:GetFriendId() == friendId then
            return friendData
        end
    end
    return nil
end

--获取聊天记录
function ChatFriendManager:RequestChatData(TT, friendId)
    return self._chatDataManager:RequestChatData(TT, self, friendId)
end

function ChatFriendManager:AddChatData(friendId, chatData)
    self._chatDataManager:AddChatData(friendId, chatData)
end

--保存所以聊天记录
function ChatFriendManager:SaveAllChatDatas()
    self._chatDataManager:SaveAllChatDatas()
end

--获取所有的聊天记录
---@return ChatData[]
function ChatFriendManager:GetAllChatDatas(TT)
    local friendList = self:GetFriendList(false)
    self._chatDataManager:GetAllChatDatas(TT, friendList)
end

--发送消息
function ChatFriendManager:SendMessage(TT, friendId, messageType, message, emojiId)
    self._chatDataManager:SendMessage(TT, self, friendId, messageType, message, emojiId)
end

--删除好友
function ChatFriendManager:DeleteFriend(TT, friendId)
    --发送消息
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type AsyncRequestRes
    local res = socialModule:DelFriend(TT, friendId)
    if res:GetSucc() then
        self._chatDataManager:DeleteChatData(friendId)
        self:_DeleteFriendFromList(friendId)
    else
        self:HandleErrorMsgCode(res:GetResult())
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateUnReadMessageStatus)
end

function ChatFriendManager:_DeleteFriendFromList(friendId)
    if friendId == self._currentSelectedChatFriendId then
        self._currentSelectedChatFriendId = nil
    end
    for k, friendData in pairs(self._friendList) do
        if friendData:GetFriendId() == friendId then
            table.remove(self._friendList, k)
            break
        end
    end
    for k, friendData in pairs(self._recentChatList) do
        if friendData:GetFriendId() == friendId then
            table.remove(self._recentChatList, k)
            break
        end
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DeleteFriendUI, friendId)
end

--设置选中的聊天记录好友
function ChatFriendManager:SelectRecentFriend(friendDataId)
    ---@type ChatFriendData
    local friendData = self:GetRecentChatFriendDataById(self._currentSelectedChatFriendId)
    if friendData then
        friendData:SetSelectedStatus(false)
    end
    self._currentSelectedChatFriendId = friendDataId
    ---@type ChatFriendData
    friendData = self:GetRecentChatFriendDataById(self._currentSelectedChatFriendId)
    if friendData then
        friendData:SetSelectedStatus(true)
    end
end

function ChatFriendManager:GetRecentChatFriendDataById(friendId)
    if not friendId then
        return
    end
    if not self._recentChatList then
        return
    end
    for i = 1, #self._recentChatList do
        ---@type ChatFriendData
        local friendData = self._recentChatList[i]
        if friendData:GetFriendId() == friendId then
            return friendData
        end
    end
    return nil
end

--取消选择聊天记录好友
function ChatFriendManager:CancelSelectRecentFriend(TT)
    ---@type ChatFriendData
    local friendData = self:GetRecentChatFriendDataById(self._currentSelectedChatFriendId)
    if friendData then
        friendData:SetSelectedStatus(false)
    end
    self._currentSelectedChatFriendId = nil
end

--获取当前选中的聊天记录好友
function ChatFriendManager:GetSelectRecentFriend()
    return self._currentSelectedChatFriendId
end

function ChatFriendManager:UpdateSelectFriend()
    if self._recentChatList and self._currentSelectedChatFriendId then
        local friendId = self._currentSelectedChatFriendId
        local find = false
        for k, friendData in pairs(self._recentChatList) do
            if friendData:GetFriendId() == friendId then
                find = true
                break
            end
        end
        if find == false then
            self._currentSelectedChatFriendId = nil
        end
    end
    if self._cacheCurrentSelectRecentFriendId then
        self._currentSelectedChatFriendId = self._cacheCurrentSelectRecentFriendId
        ---@type ChatFriendData
        local friendData = self:GetRecentChatFriendDataById(self._currentSelectedChatFriendId)
        if friendData then
            friendData:SetSelectedStatus(true)
        end
    end
    self._cacheCurrentSelectRecentFriendId = nil
end

function ChatFriendManager:CacheCurrentSelectRecentFriend(friendId)
    self._cacheCurrentSelectRecentFriendId = friendId
    self._needAddRecentFriendId = friendId
end

function ChatFriendManager:ClearCacheCurrentSelectRecentFriend()
    self._cacheCurrentSelectRecentFriendId = nil
    self._needAddRecentFriendId = nil
end

function ChatFriendManager:HasUnReadMessage()
    if not self._friendList then
        return false
    end
    for i = 1, #self._friendList do
        if self._friendList[i]:HasNewMessage() then
            return true
        end
    end

    return false
end

function ChatFriendManager:GetMaxFriendCount()
    local friendCfg = Cfg.cfg_friend_global[1]
    if not friendCfg then
        return 50
    end
    if friendCfg.limit_count then
        return friendCfg.limit_count
    end
    return 50
end

function ChatFriendManager:GetMaxAddFriendRequestCount()
    local friendCfg = Cfg.cfg_friend_global[1]
    if not friendCfg then
        return 15
    end
    if friendCfg.invitation_friend_count then
        return friendCfg.invitation_friend_count
    end
    return 15
end

function ChatFriendManager:GetMaxBlackListCount()
    local friendCfg = Cfg.cfg_friend_global[1]
    if not friendCfg then
        return 50
    end
    if friendCfg.black_list_count then
        return friendCfg.black_list_count
    end
    return 50
end

--请求黑名单数据
function ChatFriendManager:RequestBlackListData(TT)
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type AsyncRequestRes
    local res, tempBlackList = socialModule:HandleGetSocialBlackList(TT)
    if not res:GetSucc() then
        return
    end
    ---@type map<TPersistID,social_player_info>
    local blackList = tempBlackList
    for k, v in pairs(blackList) do
        self:_AddBlackListData(v)
    end
end

---@param playerInfo social_player_info
function ChatFriendManager:_AddBlackListData(playerInfo)
    ---@type ChatFriendData
    local chatFriendData =
        ChatFriendData:New(
        playerInfo.pstid,
        playerInfo.head,
        playerInfo.head_bg,
        playerInfo.frame_id,
        playerInfo.level,
        playerInfo.nick,
        false,
        playerInfo.is_online,
        playerInfo.create_time,
        0,
        playerInfo.last_logout_time,
        playerInfo.remark_name,
        playerInfo.help_pet,
        playerInfo.world_boss_info,
        playerInfo.homeland_info
    )
    self._blackList[#self._blackList + 1] = chatFriendData
end

function ChatFriendManager:GetBlackListData(TT)
    return self._blackList
end

function ChatFriendManager:HandleBlackOperate(TT, friendId, isDel)
    if not isDel then
        local count = #self._blackList
        if count >= self:GetMaxBlackListCount() then
            ToastManager.ShowToast(StringTable.Get("str_chat_blacklist_count_is_max"))
            return false
        end
    end
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type AsyncRequestRes
    local res, playerInfo = socialModule:HandleBlackOperate(TT, friendId, isDel)
    if not res:GetSucc() then
        local retCode = res:GetResult()
        self:HandleErrorMsgCode(retCode)
        return false
    end
    if isDel then
        for i = 1, #self._blackList do
            ---@type ChatFriendData
            local friendData = self._blackList[i]
            if friendData:GetFriendId() == friendId then
                table.remove(self._blackList, i)
                break
            end
        end
    else
        self:_AddBlackListData(playerInfo)
    end
    return true
end

function ChatFriendManager:IsMyFriend(friendId)
    if not friendId then
        return false
    end
    local friendList = self:GetFriendList(false)
    if not friendList then
        return false
    end
    for i = 1, #friendList do
        ---@type ChatFriendData
        local friendData = friendList[i]
        if friendData:GetFriendId() == friendId then
            return true
        end
    end
    return false
end

function ChatFriendManager:IsInBlackList(friendId)
    if not self._blackList then
        return false
    end
    for i = 1, #self._blackList do
        ---@type ChatFriendData
        local friendData = self._blackList[i]
        if friendData:GetFriendId() == friendId then
            return true
        end
    end
    return false
end

function ChatFriendManager:GetSuggestFriendList(TT, isRefresh)
    ---@type SocialModule
    local socialModule = GameGlobal.GetModule(SocialModule)
    ---@type AsyncRequestRes
    local res, tempSuggestList = socialModule:HandleRefreshRecommendPlayer(TT, isRefresh)
    if not res:GetSucc() then
        self:HandleErrorMsgCode(res:GetResult())
        return {}
    end
    local suggestFriendList = {}
    ---@type vector<social_recommend>
    local dataList = tempSuggestList
    if not dataList then
        return suggestFriendList
    end

    for i = 1, #dataList do
        ---@type social_recommend
        local suggestFriendData = dataList[i]
        ---@type social_player_info
        local playerInfo = suggestFriendData.recommend_info
        ---@type ChatFriendData
        local chatFriendData =
            ChatFriendData:New(
            playerInfo.pstid,
            playerInfo.head,
            playerInfo.head_bg,
            playerInfo.frame_id,
            playerInfo.level,
            playerInfo.nick,
            false,
            playerInfo.is_online,
            playerInfo.create_time,
            0,
            playerInfo.last_logout_time,
            playerInfo.remark_name,
            playerInfo.help_pet,
            playerInfo.world_boss_info,
            playerInfo.homeland_info
        )
        suggestFriendList[#suggestFriendList + 1] = chatFriendData
        chatFriendData:SetSuggestSource(suggestFriendData.nRecommendType)
    end
    return suggestFriendList
end

function ChatFriendManager:HandleErrorMsgCode(errorCode)
    if errorCode == nil then
        return
    end
    local errorMsg = ""
    if errorCode == SocialErrorCode.SOCIAL_ERROR_SYSTEM then -- 系统异常(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_system_exception")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_SYSTEM_RMI then -- 服务通信异常(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_service_chat_exception")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_DB then -- DB异常(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_db_exception")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_PARAM then -- 参数错误(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_param_error")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_DUPLICATE then -- 重复加关系(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_already_peeer_friend")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_NULL_SOC then -- 没有建立关系(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_null_soc")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_SELF_COUNT_MAX then -- 自己的好友数量已达上限(申请添加好友或通过添加好友申请)
        errorMsg = StringTable.Get("str_chat_error_code_self_count_max")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_PEER_COUNT_MAX then -- 对方的好友数量已达上限(申请添加好友或通过添加好友申请)
        errorMsg = StringTable.Get("str_chat_error_code_peer_count_max")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_SELF then -- 不能和自己建立关系(申请添加好友或通过添加好友申请)
        errorMsg = StringTable.Get("str_chat_error_code_self")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_INVITATION_COUNT_MAX then -- 今日邀请次数已达上限(申请添加好友)
        errorMsg = StringTable.Get("str_chat_error_code_invitation_count_max")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_INVITATION_SELF then -- 不能邀请自己(申请添加好友)
        errorMsg = StringTable.Get("str_chat_error_code_invitation_self")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_DUPLICATE_BLACK then -- 重复加黑名单(黑名单)
        errorMsg = StringTable.Get("str_chat_error_code_player_in_self_black")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_SELF_IN_BLACK then -- 在自己的黑名单中(黑名单)
        errorMsg = StringTable.Get("str_chat_error_code_player_in_self_black")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_PEER_IN_BLACK then -- 在对方的黑名单中(黑名单)
        errorMsg = StringTable.Get("str_chat_error_code_in_peer_blacklist")
    elseif errorCode == SocialErrorCode.SOCIAL_BLACK_LIST_LIMIT then -- 黑名单已经满了(黑名单)
        errorMsg = StringTable.Get("str_chat_error_code_black_list_limit")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_IN_PEER_INV_LIST then -- 已经向该玩家发送过申请(申请添加好友)
        errorMsg = StringTable.Get("str_chat_error_code_in_peer_inv_list")
    elseif errorCode == SocialErrorCode.SOCIAL_ERROR_ALREAD_PEER_FRIEND then -- 你已经是对方的好友(系统直接将对方加为你的好友)服务器内部消息
        errorMsg = StringTable.Get("str_chat_error_code_already_peeer_friend")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_PARAM then -- 参数不正确(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_chat_error_param")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_S2SRMI_FAIL then -- S2S的RMI调用失败(异常消息)
        errorMsg = StringTable.Get("str_chat_error_code_s2srmi_fail")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_CHANNEL_NOT_FOUND then -- 找不到频道
        errorMsg = StringTable.Get("str_chat_error_code_channel_not_found")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_NOT_IN_CHANNEL then -- 不在频道中
        errorMsg = StringTable.Get("str_chat_error_code_not_in_channel")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_NOT_PERMISSION_LOW_LEVEL then -- 等级太低，没有使用聊天频道的权限
        errorMsg = StringTable.Get("str_chat_error_code_not_permission_low_level")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_FREQUENCY_LIMIT then -- 发送频率过快(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_frequency_limit")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_LENGTH_LIMIT then -- 聊天长度超出限制150字节(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_length_limit")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_PLAYER_STATISICS_GET_FAIL then -- 无法获取玩家统计
        errorMsg = StringTable.Get("str_chat_error_code_player_statisics_get_fail")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_PLAYER_GET_INFO_FAIL then -- 无法获取玩家信息
        errorMsg = StringTable.Get("str_chat_error_code_player_get_info_fail")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_PLAYER_REFUSE_RECEIVE then -- 对方拒绝接收聊天信息
        errorMsg = StringTable.Get("str_chat_error_code_player_refuse_receive")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_NOT_FRIEND then -- 对方不是你的好友(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_not_friend")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_PEER_NOT_FRIEND then -- 你不是对方的好友(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_peer_not_friend")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_SEND_TARGET_ERROR then -- 选择聊天对象与服务端聊天对象不一致(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_send_target_error")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_IS_EMPTY then -- 发送消息不能为空(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_is_empty")
    elseif errorCode == SocialErrorCode.SOCIAL_SEARCH_PSTID_INVALID then --玩家不存在
        errorMsg = StringTable.Get("str_chat_error_search_pstid_invalid")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_ERROR_TIME_OUT then --发送超时(发送消息)
        errorMsg = StringTable.Get("str_chat_error_time_out")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_SEND_TYPE_ERROR then -- 发送消息类型错误(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_send_type_error")
    elseif errorCode == SocialErrorCode.SOCIAL_CHAT_EMOJI_NUM_ERROR then -- 表情类消息id必须大于0(发送消息)
        errorMsg = StringTable.Get("str_chat_error_code_emoji_num_error")
    elseif errorCode == SocialErrorCode.SOCIAL_REMARK_LIMIT then -- 名字最大长度不能超过14个字符(英文14个中文7个)(好友备注)
        errorMsg = StringTable.Get("str_chat_set_name_tolong")
    elseif errorCode == SocialErrorCode.SOCIAL_REMARK_DIRTY then -- 备注含有敏感字(好友备注)
        errorMsg = StringTable.Get("str_chat_error_code_remark_dirty")
    elseif errorCode == SocialErrorCode.SOCIAL_REMARK_SPE then -- 备注含有特殊字符(好友备注)
        errorMsg = StringTable.Get("str_chat_error_code_remark_spe")
    elseif errorCode == SocialErrorCode.SOCIAL_REMARK_INVALID then -- 名字含有其他国家的文字 只能是中文 韩文 日文 数字 英文字母(好友备注)
        errorMsg = StringTable.Get("str_chat_error_coed_remark_invalid")
    end
    if errorMsg and errorMsg ~= "" then
        ToastManager.ShowToast(errorMsg)
    end
    Log.error(errorCode)
end

function ChatFriendManager:Request(friendList, blackList, chatDatas, cb)
    GameGlobal.TaskManager():StartTask(function(chatFriendManager, TT)
        local lockName = "ChatFriendManager:Request"
        GameGlobal.UIStateManager():Lock(lockName)

        --请求好友列表
        if friendList then
            chatFriendManager:RequestFriendList(TT)
        end

        --请求黑名单数据
        if blackList then
            chatFriendManager:RequestBlackListData(TT)
        end

        --请求聊天记录
        if chatDatas then
            chatFriendManager:GetAllChatDatas()
        end

        GameGlobal.UIStateManager():UnLock(lockName)

        if cb then
            cb(chatFriendManager)
        end
    end, self)
end
