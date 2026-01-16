--[[
	@微信客户端 _proxy
--]]
---@class WeChatProxy
_class("WeChatProxy", Object)
WeChatProxy = WeChatProxy

-- [1] = {"m_nSpeakerID", "int"},
-- [2] = {"m_stSpeakerName", "string"},
-- [3] = {"m_vecChatData", "list<DQuestChatData_Chat>"},
-- [4] = {"m_tmRandomStart", "time"},
-- [5] = {"m_randomChat", "DQuestChatData_Chat"},

-- DQuestChatData_Talk = DQuestChatData_Talk

--  function DQuestChatData_Talk:Constructor()
--     self.m_nTalkID = 0 --对话内容ID
--     self.m_bReaded = 0 --是否已读标识
function WeChatProxy:Constructor(module)
    ---@type QuestChatModule
    self.module = module
    ---@type WeChatStateMachine
    self.stateMachine = WeChatStateMachine:New()
    -- Log.error("WeChatProxy:Constructor", Log.traceback())
    ---@type WeChatLocalStorage
    self.localStorage = WeChatLocalStorage:New(self)
    ---@type table<int, DWeChatRole>
    self.roles = {}
    local comparer = function(a, b)
        if a._heap_index > b._heap_index then
            return 1
        else
            return -1
        end
    end

    self.waitQueue = {}
    self.isConstructor = true
    self:AddListener()
end

function WeChatProxy:IsConstructor()
    return self.isConstructor
end

function WeChatProxy:SetIsConstructor(isConstructor)
    self.isConstructor = isConstructor
end

---@param serverSpeakerData DQuestChatData_Speaker
function WeChatProxy:InitLocalSpeaker(speakerId, pstId, serverSpeakerData)
    if self.localStorage then
        return self.localStorage:InitLocalSpeaker(speakerId, pstId, serverSpeakerData)
    else
        return 0
    end
end

function WeChatProxy:InitAllLocalSpeaker(pstId)
    if self.localStorage then
        return self.localStorage:InitAllLocalSpeaker(pstId)
    else
        return 0
    end
end

function WeChatProxy:SaveLocalSpeaker(speakerId, chats)
    if self.localStorage then
        self.localStorage:SaveLocalSpeaker(speakerId, chats)
    end
end

function WeChatProxy:SaveSpeakerLastTime(speakerId, time)
    if self.localStorage then
        self.localStorage:SaveSpeakerLastTime(speakerId, time)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatUpdateLastTime,speakerId)
    end
end
function WeChatProxy:GetSpeakerLastTime(speakerId)
    return self.localStorage and self.localStorage:GetSpeakerLastTime(speakerId) or 0
end

-- 释放
function WeChatProxy:Dispose()
    -- Log.error("WeChatProxy:Dispose", Log.traceback())
    if self.stateMachine then
        self.stateMachine:Dispose()
        self.stateMachine = nil
    end
    self:RemoveListener()
    self.roles = {}
    self:ResetWaitQueue()
end

function WeChatProxy:AddListener()
    self._onWeChatWaitEndState = GameHelper:GetInstance():CreateCallback(self.OnWeChatWaitEndState, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.WeChatWaitEndState, self._onWeChatWaitEndState)
end
function WeChatProxy:RemoveListener()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.WeChatWaitEndState, self._onWeChatWaitEndState)
    self._onWeChatWaitEndState = nil
end

-- 当等待动画结束需要判断等待队列是否继续播动画
-- local data = {}
-- data.speakerId =
-- data.chatId =
-- data.talkId =
function WeChatProxy:OnWeChatWaitEndState(data)
    -- requet
    self:SendTalkReaded(data.speakerId, data.chatId, data.talkId, data.triggerIndex)
end

-- 当前状态机状态
function WeChatProxy:GetCurStateType()
    return self.stateMachine:GetCurStateType()
end

-- 切换状态
function WeChatProxy:ChangeState(stateType, ...)
    self.stateMachine:ChangeState(stateType, ...)
end

function WeChatProxy:ForceChangeState(stateType, ...)
    self.stateMachine:ForceChangeState(stateType, ...)
end
--按分组获取
function WeChatProxy:GetSortedGroup()
    ---@type table<int,DWeChatRoleGroup>
    local groups = {}
    for key, value in pairs(self.roles) do
        local petid = value:GetSpeakerId()
        local cfg_pet = Cfg.cfg_pet[petid]
        local ketid
        if cfg_pet then
            local binderID = cfg_pet.BinderPetID
            if binderID then
                ketid = binderID
            else
                ketid = petid
            end
        else
            ketid = petid
        end

        if not groups[ketid] then
            groups[ketid] = DWeChatRoleGroup:New()
        end
        value:SetGroupID(ketid)
        groups[ketid]:AddRole(value)
    end
    --组内排序
    for key, value in pairs(groups) do
        if value:RoleCount() > 1 then
            local roleList = value:RoleList()
            table.sort(roleList,function(a,b)
                local petid_a = a:GetSpeakerId()
                local petid_b = b:GetSpeakerId()
                local cfg_a = Cfg.cfg_pet[petid_a]
                local cfg_b = Cfg.cfg_pet[petid_b]
                local binderPetIdx_a = cfg_a.BinderIndex
                local binderPetIdx_b = cfg_b.BinderIndex
                return binderPetIdx_a<binderPetIdx_b
            end)
        end
    end
    return self:SortGroup(groups)
end
function WeChatProxy:SortGroup(groups)
    --组外排序
    local array = table.toArray(groups)
    table.sort(array,function(a,b)
        ---@type DWeChatRole[]
        local list_a = a:RoleList()
        local list_b = b:RoleList()

        local weight_a = 0
        local weight_b = 0

        for _, value in pairs(list_a) do
            local chats = value:GetChats()
            local lastChat = chats[#chats]
            if lastChat then
                local talks = lastChat.talks
                local lastTalk = talks[#talks]
                if lastTalk then
                    local isEnd = lastTalk.isEnd
                    if not isEnd then
                        weight_a = weight_a + 1000
                        break
                    else
                        local readed = lastTalk.readed
                        if not readed then
                            weight_a = weight_b + 1000
                        end
                    end
                end
            end
        end
        for _, value in pairs(list_b) do
            local chats = value:GetChats()
            local lastChat = chats[#chats]
            if lastChat then
                local talks = lastChat.talks
                local lastTalk = talks[#talks]
                if lastTalk then
                    local isEnd = lastTalk.isEnd
                    if not isEnd then
                        weight_b = weight_b + 1000
                        break
                    else
                        local readed = lastTalk.readed
                        if not readed then
                            weight_b = weight_b + 1000
                        end
                    end
                end
            end
        end

        local time_a
        if #list_a > 1 then
            --取最大的
            local tmp_time_a
            for i = 1, #list_a do
                local tmp_a = self:GetSpeakerLastTime(list_a[i]:GetSpeakerId())
                if not tmp_time_a then
                    tmp_time_a = tmp_a
                else
                    if tmp_a>tmp_time_a then
                        tmp_time_a = tmp_a
                    end
                end
            end
            time_a = tmp_time_a
        else
            time_a = self:GetSpeakerLastTime(list_a[1]:GetSpeakerId())
        end
        local time_b
        if #list_b > 1 then
            --取最大的
            local tmp_time_b
            for i = 1, #list_b do
                local tmp_b = self:GetSpeakerLastTime(list_b[i]:GetSpeakerId())
                if not tmp_time_b then
                    tmp_time_b = tmp_b
                else
                    if tmp_b>tmp_time_b then
                        tmp_time_b = tmp_b
                    end
                end
            end
            time_b = tmp_time_b
        else
            time_b = self:GetSpeakerLastTime(list_b[1]:GetSpeakerId())
        end

        if time_a>time_b then
            weight_a = weight_a+100
        else
            weight_b = weight_b+100
        end

        return weight_a>weight_b
    end)
    return array
end
-- 获取所有角色
function WeChatProxy:GetRoles()
    local array = table.toArray(self.roles)
    table.sort(
        array,
        function(a, b)
            return self:GetSpeakerLastTime(a:GetSpeakerId()) > self:GetSpeakerLastTime(b:GetSpeakerId())
        end
    )
    return array
end

-- 获取第一个选中的BBKing
function WeChatProxy:GetFirstSpeakerId()
    local roles = self:GetRoles()
    if roles and table.count(roles)>0 then
        local role = roles[1]
        local speakerid = roles[1]:GetSpeakerId()
        local cfg_pet = Cfg.cfg_pet[speakerid]
        local gid
        local sid = speakerid
        if cfg_pet and cfg_pet.BinderPetID then
            gid = cfg_pet.BinderPetID
        else
            gid = speakerid
        end
        return gid,speakerid
    end
end
function WeChatProxy:GetRole(speakerId)
    return self.roles[speakerId]
end

function WeChatProxy:GetTalks(speakerId)
    return self.roles[speakerId] and self.roles[speakerId]:GetTalks() or {}
end
function WeChatProxy:GetTalk(speakerId, chatId,talkId, triggerIndex)
    return self.roles[speakerId] and self.roles[speakerId]:GetTalk(chatId,talkId, triggerIndex) or {}
end

-- 目前给localstorage用
function WeChatProxy:UpdateRole(speakerId, serverChatData, fromStorage)
    ---@type DWeChatRole
    local role = self:GetRole(speakerId)
    if not role then
        --服务器可能存在老数据，防御处理
        if Cfg.cfg_quest_chat_speaker[speakerId] then
            self:AddRole(speakerId, serverChatData, fromStorage)
        end
    else
        role:Decode(serverChatData.m_vecChatData, fromStorage)
    end
end

-- 添加一个新角色
function WeChatProxy:AddRole(speakerId, serverChatDatas, fromStorage)
    if not self.roles[speakerId] then
        self.roles[speakerId] = DWeChatRole:New(serverChatDatas, self, fromStorage)
        -- Log.error(" WeChatProxy:AddRole add role", speakerId)
        if not fromStorage then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatUpdateRole,speakerId)
            self:SaveSpeakerLastTime(speakerId, os.time())
        end
    -- Log.error("is already add role", speakerId)
    end
end

function WeChatProxy:UpdateChat(speakerId, serverChatData)
    ---@type DWeChatRole
    local role = self:GetRole(speakerId)
    if role then
        role:UpdateChat(serverChatData)
    end
end

function WeChatProxy:AddChat(speakerId, serverChatData)
    local role = self:GetRole(speakerId)
    if role then
        self:SaveSpeakerLastTime(speakerId, os.time())

        self._saveRole = role
        self._saveSpeakerId = speakerId
        self._serverChatData = serverChatData

        local waitTime = 0
        if GameGlobal.UIStateManager():IsShow("UIWeChatController") then
            waitTime = 5000
        end
        if self._event then
            GameGlobal.Timer():CancelEvent(self._event)
            self._event = nil
        end
        self._event = GameGlobal.Timer():AddEvent(waitTime,function()
            self:UpdateSaveData()
        end)
    end
end
function WeChatProxy:CancelSaveData()
    self:UpdateSaveData()
    if self._event then
        GameGlobal.Timer():CancelEvent(self._event)
        self._event = nil
    end
end
function WeChatProxy:UpdateSaveData()
    if self._saveRole and self._saveSpeakerId and self._serverChatData then
        --强刷--------------------------------
        self._saveRole:UpdateChat(self._serverChatData)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatWaitState, {speakerId = self._saveSpeakerId})
        --防止切换后继续刷
        if self.curSpeakerId == self._saveSpeakerId then
            local chatId = self._serverChatData.m_nChatID
            local triggerIndex = self._serverChatData.m_nCount
            for _, serverTalkData in ipairs(self._serverChatData.m_vecTalkData) do
                self:UpdateTalkState(self._saveSpeakerId, chatId, triggerIndex, serverTalkData, true)
            end
        end
        self._saveRole = nil
        self._saveSpeakerId = nil
        self._serverChatData = nil
    end
end
--需要展示动画
---@type DQuestChatData_Talk serverTalkData
function WeChatProxy:AddTalk(speakerId, chatId, status, triggerIndex, serverTalkData, needWait)
    if self.roles[speakerId] then
        self.roles[speakerId]:AddTalk(chatId, triggerIndex, serverTalkData, true)
        local serverChatData = {}
        serverChatData.m_nStatus = status
        serverChatData.m_nCount = triggerIndex
        self.roles[speakerId]:UpdateChatState(chatId, serverChatData)
        self:UpdateTalkState(speakerId, chatId, triggerIndex, serverTalkData, needWait)
    end
end

function WeChatProxy:StopTimer()
    if self.timer then
        GameGlobal.Timer():CancelEvent(self.timer)
        self.timer = nil
    end
end
function WeChatProxy:UpdateTalkState(speakerId, chatId, triggerIndex, serverTalkData, needWait)
    local data = {}
    data.speakerId = speakerId
    data.chatId = chatId
    data.talkId = serverTalkData.m_nTalkID
    data.triggerIndex = triggerIndex
    if needWait then
        local cfg = Cfg.cfg_quest_talk[serverTalkData.m_nTalkID]
        if cfg.IsMainActorWord == 1 then -- 回复的还是主角说的话 刷一下列表
            self:SetInitState(speakerId)
        else
            table.insert(self.waitQueue, data)
            if self:GetCurStateType() == WeChatState.AddAnswer then
                self:ChangeState(WeChatState.Wait, data)
            else
                self:ChangeState(WeChatState.Wait, data)
            end
        end
    else
        self:ChangeState(WeChatState.AddAnswer, data)
    end
end

-- 设置已读
function WeChatProxy:SetTalkReaded(speakerId, chatId, talkId, triggerIndex)
    ---@type DWeChatRole
    local role = self:GetRole(speakerId)
    if role then
        role:SetTalkReaded(chatId,talkId, triggerIndex)
    end
end

-- 重置等待队列
function WeChatProxy:ResetWaitQueue()
    self:StopTimer()
    self.waitQueue = {}
end

function WeChatProxy:GetLastTalk(speakerId)
    if self.roles[speakerId] then
        return self.roles[speakerId]:GetLastTalk()
    end
    return nil
end

-- 检查普通状态或者回复状态
function WeChatProxy:SetInitState(speakerId, force)
    self.curSpeakerId = speakerId
    self:ResetWaitQueue()
    local talk = self:GetLastTalk(speakerId)
    local role = self:GetRole(speakerId)

    if talk and talk.options then
        -- else
        -- end
        -- if role:GetUnReadCount() <= 0 then
        self:ForceChangeState(WeChatState.Reply, speakerId)
    else
        self:ForceChangeState(WeChatState.Normal, speakerId)
    end
end

----------------------------------To Server-------------------------
--回复
function WeChatProxy:Reply(speakerId, index)
    local talk = self:GetLastTalk(speakerId)
    if not talk.options then
        return
    end

    local option = talk.options[index]
    -- 发送点击选项协议
    TaskManager:GetInstance():StartTask(
        function(TT)
            -- 回复 -- 回包会调用self:AddTalk()
            GameGlobal.UIStateManager():Lock("WeChatProxy:Reply")
            local result = self.module:Request_UpdateChatAnswer(TT, speakerId, talk.chatId, talk.talkId, option.talkId)
            if result:GetSucc() then
            end
            GameGlobal.UIStateManager():UnLock("WeChatProxy:Reply")
        end
    )
end

-- 设置单个已读
function WeChatProxy:SendTalkReaded(speakerId, chatId, talkId, triggerIndex, onlySend, noCheck)
    local send = false
    if not noCheck then
        -- 代表不是线
        if talkId then
            local talk = self:GetTalk(speakerId,chatId, talkId, triggerIndex)
            if talk.talkType == WeChatTalkType.Start then
                -- voice不判断
            elseif talk.talkType == WeChatTalkType.Voice then
            elseif talk.readed == false then
                send = true
            end
        end
    else
        send = true
    end
    if send then
        TaskManager:GetInstance():StartTask(
            function(TT)
                -- 发送单条talk已读
                local result = self.module:Request_SetTalkReaded(TT, speakerId, chatId, talkId, triggerIndex)
                if result:GetSucc() then
                    --在刚发送完回复后等待消息时，切换了终端对话角色，会强制结束等待状态并发送已读，
                    --此时当前speakerid已经不是发送已读的speakerid了 不能直接切换状态
                    if not onlySend and self.curSpeakerId == speakerId then
                        table.remove(self.waitQueue, 1)
                        local nextData = self.waitQueue[1]
                        if nextData then
                            self:ForceChangeState(WeChatState.Wait, nextData) -- 如果队列中
                        else
                            self:SetInitState(speakerId)
                        end
                    else
                        GameGlobal.EventDispatcher():Dispatch(
                            GameEventType.WeChatReaded,
                            speakerId,
                            chatId,
                            talkId,
                            triggerIndex
                        )
                    end
                end
            end
        )
    end
end

-- 打开聊天时候设置所有已读
function WeChatProxy:SendAllTalkReaded(speakerId)
    ---@type DWeChatRole
    local role = self:GetRole(speakerId)
    if role then
        local talks = role:GetTalks()
        for index, talk in ipairs(talks) do
            self:SendTalkReaded(speakerId, talk.chatId, talk.talkId, talk.triggerIndex, true)
        end
    end
end

function WeChatProxy:SendAndCheckTalkReaded(speakerId)
    -- body
end

--读取本地如果没有key获取所有配置
function WeChatProxy:SendSpeakerHistory(speakerId)
    return TaskManager:GetInstance():StartTask(
        function(TT)
            local result = self.module:Request_SpeakerHistory(TT, speakerId)
            if result:GetSucc() then
            end
        end
    )
end

--读取本地如果没有key获取所有配置
function WeChatProxy:SendSpeakerAllHistory()
    return TaskManager:GetInstance():StartTask(
        function(TT)
            local result = self.module:Request_AllHistory(TT)
            if result:GetSucc() then
            end
        end
    )
end

-- 主界面红点 请求协议判断
function WeChatProxy:HasRed()
    for index, role in pairs(self.roles) do
        if role:HasRed() then
            return true
        end
    end
    return false
end

function WeChatProxy:GetUnReadCount()
    local maxCount = 0
    for index, role in pairs(self.roles) do
        local count = role:GetUnReadCount()
        maxCount = maxCount + count
    end
    return maxCount
end

function WeChatProxy:GetUnReadChats()
    local tbl = {}
    for index, role in pairs(self.roles) do
        local chats = role:GetUnReadChats()
        table.appendArray(tbl, chats)
    end
    return tbl
end

function WeChatProxy:_DoEscape(strContent)
    if string.isnullorempty(self.roleName) then
        self.roleName = GameGlobal.GetModule(RoleModule):GetName()
    end
    strContent = string.gsub(strContent, "PlayerName", self.roleName) -- GameGlobal.GetModule("RoleModule").m_char_info.nick) 不知何时可用
    return strContent
end

-- 随机抽三条 不够则返回
function WeChatProxy:GetRandomUnReadChats()
    local chats = self:GetUnReadChats()
    local txtChats = {}
    for index, chatId in ipairs(chats) do
        local tipWord = Cfg.cfg_quest_chat[chatId].TipWord
        -- 无此字段不随机不展示
        if tipWord then
            -- local txt = self:_DoEscape(StringTable.Get(tipWord))
            local chat = Cfg.cfg_quest_chat[chatId]
            if chat then
                local speakerId = chat.SpeakerID
                if speakerId then
                    --[[
                        old
                        local pet = Cfg.cfg_pet[speakerId]
                        if pet then
                            local head = pet.Head
                            table.insert(txtChats, head)
                        end
                        ]]
                    --觉醒换立绘--lxs--
                    local cfg_quest_chat_speaker = Cfg.cfg_quest_chat_speaker[speakerId]
                    if not cfg_quest_chat_speaker then
                        Log.fatal("###[WeChatProxy] cfg_quest_chat_speaker is nil ! id --> ", speakerId)
                        return
                    end
                    local picName
                    if cfg_quest_chat_speaker.SpeakerType == 1 then
                        if cfg_quest_chat_speaker.TemplateID and cfg_quest_chat_speaker.TemplateID ~= 0 then
                            local petid = cfg_quest_chat_speaker.TemplateID
                            ---@type PetModule
                            local petModule = GameGlobal.GetModule(PetModule)
                            ---@type MatchPet
                            local matchPet = petModule:GetPetByTemplateId(petid)
                            if matchPet then
                                picName = matchPet:GetPetHead(PetSkinEffectPath.HEAD_ICON_WE_CHAT)
                            end
                        end
                    end
                    if not picName then
                        picName = HelperProxy:GetInstance():GetPetHead(speakerId,0,0,PetSkinEffectPath.HEAD_ICON_WE_CHAT)
                    end
                    table.insert(txtChats, picName)
                -----------------------------
                end
            end
        end
        -- end
    end
    local randomChats = {}
    if #txtChats > 3 then
        local tb = {}
        math.randomseed(os.time())
        local rand = math.random
        for i = 1, 6 do
            local x = rand(1, 10)
            tb[i] = x --生成的数直接放入表中
        end

        table.remove(tb, 1) --移除第一项
        local ran
        for index, value in ipairs(tb) do
            table.insert(randomChats, txtChats[value])
        end
    else
        randomChats = txtChats
    end
    return randomChats
end

---返回是否在历史上成功过
function WeChatProxy:IsChatInHistory(nSpeakerID, nChatID)
    local role = self.roles[nSpeakerID]
    if nil == role then
        return false
    end
    local chats = role:GetChats()
    ---@param value DWeChatRole
    for key, value in pairs(chats) do
        if value.chatId == nChatID then
            if value.state then
                if
                    value.state >= QuestChatStatus.E_ChatState_Completed and
                        value.state <= QuestChatStatus.E_ChatState_Taken
                 then
                    return true
                end
            else
                return false
            end
        end
    end
    return false
end

function WeChatProxy:UpdateRoleName(speakerId, name)
    local role = self:GetRole(speakerId)
    if role then
        role:UpdateName(name)
    end
end

function WeChatProxy:EndCurWaitStat()
    if WeChatState.Wait ~= self:GetCurStateType() then
        return
    end
    local waitData = self.waitQueue[1]
    self:ChangeState(WeChatState.WaitEnd, waitData)
    table.remove(self.waitQueue, 1)
end
