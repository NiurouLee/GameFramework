---@class WeChatLocalStorage:Object
_class("WeChatLocalStorage", Object)
WeChatLocalStorage = WeChatLocalStorage

function WeChatLocalStorage:Constructor(weChatProxy)
    ---@type WeChatProxy
    self.weChatProxy = weChatProxy
    self.roleInit = {}
end

function WeChatLocalStorage:Dispose()
    self.weChatProxy = nil
end

function WeChatLocalStorage:_GetChatKey(speakerId, pstId)
    if not self.pstId then
        self.pstId = pstId
    end
    if not self.pstId or self.pstId <= 0 then
        self.pstId = GameGlobal.GetModule(RoleModule):GetPstId()
    end
    return "WeChat" .. "|" .. self.pstId .. "|" .. speakerId
end

function WeChatLocalStorage:_GetTimeKey(speakerId)
    if not self.pstId or self.pstId <= 0 then
        self.pstId = GameGlobal.GetModule(RoleModule):GetPstId()
    end
    return "WeChatTime" .. "|" .. self.pstId .. "|" .. speakerId
end
function WeChatLocalStorage:SaveSpeakerLastTime(speakerId, time)
    local key = self:_GetTimeKey(speakerId)
    LocalDB.SetInt(key, time)
end
function WeChatLocalStorage:GetSpeakerLastTime(speakerId)
    local key = self:_GetTimeKey(speakerId)
    return LocalDB.GetInt(key, 0)
end

function WeChatLocalStorage:SaveLocalSpeaker(speakerId, chats)
    local key = self:_GetChatKey(speakerId)
    LocalDB.Delete(key)
    local str = LocalDB.GetString(key)
    for _, chat in ipairs(chats) do
        str = str .. chat.chatId .. "," .. chat.triggerIndex .. ","
        for index, talk in ipairs(chat.talks) do
            if talk.talkType == WeChatTalkType.Start then
            elseif index < #chat.talks then
                str = str .. talk.talkId .. ","
            elseif index == #chat.talks then
                str = str .. talk.talkId
            end
        end
        str = str .. "|"
    end
    LocalDB.SetString(key, str)
end
---@param serverSpeakerData DQuestChatData_Speaker
function WeChatLocalStorage:InitLocalSpeaker(speakerId, pstId, serverSpeakerData)
    if self.roleInit[speakerId] then
        return 0
    end
    self.roleInit[speakerId] = true
    local key = self:_GetChatKey(speakerId, pstId)
    local str = LocalDB.GetString(key)
    if string.isnullorempty(str) then
        return self.weChatProxy:SendSpeakerHistory(speakerId)
    else
        -- construct speaker
        local speaker = {}
        speaker.m_vecChatData = {}
        speaker.m_nSpeakerID = speakerId
        local a = string.split(str, "|")
        for i = 1, table.count(a) do
            if not string.isnullorempty(a[i]) then
                local b = string.split(a[i], ",")
                local chat = {}
                chat.m_vecTalkData = {}
                for j = 1, table.count(b) do
                    if not string.isnullorempty(b[j]) then
                        if j == 1 then
                            --聊天内容
                            local chatId = tonumber(b[1])
                            chat.m_nCount = tonumber(b[2])
                            chat.m_nChatID = chatId --对话ID
                            chat.m_nStatus = QuestChatStatus.E_ChatState_Completed --状态
                        elseif j == 2 then
                        else
                            local talk = {}
                            talk.m_nTalkID = tonumber(b[j]) --对话内容ID
                            talk.m_bReaded = true --是否已读标识
                            table.insert(chat.m_vecTalkData, talk)
                        end
                    end
                end
                table.insert(speaker.m_vecChatData, chat)
            end
        end
        --如果配置chatid都不存在，则这个人不加进来
        local inner = false
        for key, value in pairs(speaker.m_vecChatData) do
            local chatid = value.m_nChatID
            if Cfg.cfg_quest_chat[chatid] then
                inner = true
                break
            end
        end
        if inner then
            self.weChatProxy:UpdateRole(speakerId, speaker, true)
        end
    end

    ---对于换设备可能导致的情况需要特殊处理
    local lastTalk = self.weChatProxy:GetLastTalk(speakerId)

    ---配置有修改导致终端数据不正常 只报错不卡死
    if not lastTalk then
        Log.fatal("[WeChat] WeChatLocalStorage:InitLocalSpeaker can not find local talk by speakerID:"..speakerId)
        return 0
    end

    ---1 服务器已完成当前对话 但设备上没有完成，需要拉取当前角色历史来覆盖本地数据
    ---2 服务器未完成当前对话 设备上也未完成 并且两个对话id不一致，需要拉取当前角色历史来覆盖本地数据
    if #serverSpeakerData.m_vecChatData == 0 then
        if not lastTalk.isEnd then
            return self.weChatProxy:SendSpeakerHistory(speakerId)
        end
    else
        ---@type DQuestChatData_Chat
        local serverLastChatData = serverSpeakerData.m_vecChatData[1]
        if not lastTalk.isEnd and lastTalk.chatId ~= serverLastChatData.m_nChatID then
            return self.weChatProxy:SendSpeakerHistory(speakerId)
        end
    end

    return 0
end

function WeChatLocalStorage:InitAllLocalSpeaker(pstId)
    local i = LocalDB.GetInt("WeChatAllHistory" .. pstId, 0)
    if i <= 0 then
        LocalDB.SetInt("WeChatAllHistory" .. pstId, 1)
        return self.weChatProxy:SendSpeakerAllHistory()
    else
        return 0
    end
end
function WeChatLocalStorage:ClearLocalSpeaker(speakerId)
end
