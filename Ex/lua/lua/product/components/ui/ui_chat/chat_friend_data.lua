_class("ChatFriendPetData", Object)
---@class ChatFriendPetData:Object
ChatFriendPetData = ChatFriendPetData

---@param helpPetInfo role_help_pet_info
function ChatFriendPetData:Constructor(playerPstId, helpPetInfo)
    self.ElementSpriteName = {
        [ElementType.ElementType_Blue] = "bing_color",
        [ElementType.ElementType_Red] = "huo_color",
        [ElementType.ElementType_Green] = "sen_color",
        [ElementType.ElementType_Yellow] = "lei_color"
    }
    if not helpPetInfo then
        return
    end
    self._petTemplateId = helpPetInfo.pet_template_id
    self._level = helpPetInfo.level
    self._awake = helpPetInfo.awake
    self._grade = helpPetInfo.grade
    self._equipLevel = helpPetInfo.equip_level
    self._equipRefineLevel = helpPetInfo.equip_refine_level
    self._skinId = helpPetInfo.skin_id
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    ---@type DHelpPet_PetData
    self._helpPetInfo = roleModule:GetHelpPetData(playerPstId, EnumHelpSourceType.E_HelpSource_Friend, helpPetInfo)
    self:_ParseConfig()
end

---@param friendPetData ChatFriendPetData
function ChatFriendPetData:Init(friendPetData)
    self._petTemplateId = friendPetData:GetPetTemplateId()
    self._level = friendPetData:GetLevel()
    self._awake = friendPetData:GetAwake()
    self._grade = friendPetData:GetGrade()
    self._equipLevel = friendPetData:GetEquipLevel()
    self._equipRefineLevel = friendPetData:GetEquipRefineLevel()
    self._skinId = friendPetData:GetSkinId()
    ---@type DHelpPet_PetData
    self._helpPetInfo = friendPetData:GetHelpPetData()
    self:_ParseConfig()
end

function ChatFriendPetData:_ParseConfig()
    if not self._petTemplateId then
        return
    end
    local cfg_pet = Cfg.cfg_pet[self._petTemplateId]
    if not cfg_pet then
        return
    end
    self._firstElement = cfg_pet.FirstElement
    self._secondElement = 0 --大于0表示存在第二属性
    if self._grade >= cfg_pet.Element2NeedGrade then
        self._secondElement = cfg_pet.SecondElement
    end
    self._head =
        HelperProxy:GetInstance():GetPetHead(
        self._petTemplateId,
        self._grade,
        self._skinId,
        PetSkinEffectPath.HEAD_ICON_CHAT_FIREND
    )
end

function ChatFriendPetData:GetPetTemplateId()
    return self._petTemplateId
end

function ChatFriendPetData:GetLevel()
    return self._level
end

function ChatFriendPetData:GetAwake()
    return self._awake
end

function ChatFriendPetData:GetGrade()
    return self._grade
end

function ChatFriendPetData:GetEquipLevel()
    return self._equipLevel
end
function ChatFriendPetData:GetEquipRefineLevel()
    return self._equipRefineLevel
end
function ChatFriendPetData:GetSkinId()
    return self._skinId
end

function ChatFriendPetData:GetFirstElement()
    return self._firstElement
end

function ChatFriendPetData:GetFirstElementName()
    if self._firstElement ~= nil and self._firstElement ~= 0 then --存在副属性
        return self.ElementSpriteName[self._firstElement]
    end
    return nil
end

function ChatFriendPetData:GetSecondElement()
    return self._secondElement
end

function ChatFriendPetData:GetSecondElementName()
    if self._secondElement ~= nil and self._secondElement ~= 0 then --存在副属性
        return self.ElementSpriteName[self._secondElement]
    end
    return nil
end

function ChatFriendPetData:GetHeadIcon()
    return self._head
end

function ChatFriendPetData:GetHelpPetData()
    return self._helpPetInfo
end

_class("ChatFriendData", Object)
---@class ChatFriendData:Object
ChatFriendData = ChatFriendData

function ChatFriendData:Constructor(
    friendId,
    headIcon,
    headBg,
    headFrame,
    level,
    name,
    hasNewMessage,
    isOnline,
    createDate,
    recentMsgTime,
    lastLogOutTime,
    remarkName,
    helpPet,
    world_boss_info,
    homeland_info,
    difficulty_mission,
    sailing_mission,
    title_used,
    fifure_used)
    self._friendId = friendId
    self._headIcon = headIcon
    self._headBg = headBg
    self._headFrame = headFrame
    self._level = level
    self._name = name
    self._hasNewMessage = hasNewMessage
    self._isOnLine = isOnline
    self._createDate = createDate
    self._recentMsgTime = recentMsgTime
    self._isSelected = false
    self._lastOnlineTime = lastLogOutTime
    self._remarkName = remarkName
    self._petDataList = {}
    if helpPet then
        for i = 1, #helpPet do
            local pet = ChatFriendPetData:New(self._friendId, helpPet[i])
            self._petDataList[#self._petDataList + 1] = pet
        end
    end
    self._worldBossInfo = world_boss_info
    self._homeland_info = homeland_info
    self._difficulty_mission = difficulty_mission
    self._sailing_mission = sailing_mission
    self._title_used = title_used
    self._fifure_used = fifure_used
end

---@param friendData ChatFriendData
function ChatFriendData:Init(friendData)
    self._friendId = friendData:GetFriendId()
    self._headIcon = friendData:GetHeadIcon()
    self._headBg = friendData:GetHeadBg()
    self._headFrame = friendData:GetHeadFrame()
    self._level = friendData:GetLevel()
    self._name = friendData:GetName()
    self._hasNewMessage = friendData:HasNewMessage()
    self._isOnLine = friendData:IsOnline()
    self._createDate = friendData:GetCreateDate()
    self._recentMsgTime = friendData:GetRecentMsgTime()
    self._lastOnlineTime = friendData:GetLastOnLineTime()
    self._remarkName = friendData:GetRemarkName()
    self._petDataList = {}
    local petDataList = friendData:GetPetDataList()
    if petDataList then
        for i = 1, #petDataList do
            local chatFriendPetData = ChatFriendPetData:New()
            chatFriendPetData:Init(petDataList[i])
            self._petDataList[#self._petDataList + 1] = chatFriendPetData
        end
    end
    self._worldBossInfo = friendData:GetWorldBossInfo()
end

function ChatFriendData:GetPetDataList()
    return self._petDataList
end

--获取好友Id
function ChatFriendData:GetFriendId()
    return self._friendId
end

--获取头像
function ChatFriendData:GetHeadIcon()
    return self._headIcon
end

--获取头像背景
function ChatFriendData:GetHeadBg()
    return self._headBg
end

function ChatFriendData:GetHeadFrame()
    return self._headFrame
end
function ChatFriendData:GetHeadIconName()
    local cfg_head = Cfg.cfg_role_head_image[self._headIcon]
    if not cfg_head then
        cfg_head = Cfg.cfg_role_head_image[1]
    end
    if not cfg_head then
        return "", ""
    end
    return cfg_head.Icon, cfg_head.Tag
end

function ChatFriendData:GetHeadBgName()
    local cfg_head_bg = Cfg.cfg_player_head_bg[self._headBg]
    if not cfg_head_bg then
        local bid = HelperProxy:GetInstance():GetHeadBgDefaultID()

        cfg_head_bg = Cfg.cfg_player_head_bg[bid]
    end
    return cfg_head_bg.Icon
end

function ChatFriendData:GetHeadFrameName()
    local cfg_head_frame = Cfg.cfg_role_head_frame[self._headFrame]
    if not cfg_head_frame then
        local id = HelperProxy:GetInstance():GetHeadFrameDefaultID()
        cfg_head_frame = Cfg.cfg_role_head_frame[id]
    end
    return cfg_head_frame.Icon
end

--获取等级
function ChatFriendData:GetLevel()
    return self._level
end

--获取真实名称
function ChatFriendData:GetOriginalName()
    return self._name
end

--获取备注名称
function ChatFriendData:GetRemarkName()
    return self._remarkName
end

--获取名称
function ChatFriendData:GetName()
    if string.isnullorempty(self._remarkName) then
        return self._name
    end
    return self._remarkName
end
--获取头像徽章信息
function ChatFriendData:GetWorldBossInfo()
    return self._worldBossInfo
end
--重置未读消息
function ChatFriendData:ResetUnReadMessageStatus()
    self._hasNewMessage = false
    self._recentMsgTime = 0
end

--是否有新消息
function ChatFriendData:HasNewMessage()
    return self._hasNewMessage
end

--获取最近的消息时间
function ChatFriendData:GetRecentMsgTime()
    return self._recentMsgTime
end

--是否在线
function ChatFriendData:IsOnline()
    return self._isOnLine
end

--上次在线的时间
function ChatFriendData:GetLastOnLineTime()
    return self._lastOnlineTime
end

function ChatFriendData:GetLastOnlineStatusStr()
    -- “在线”“N分钟前”“N小时前”“N天前”,最多显示到“3天前”，不会显示更久的离线时间。
    if self._isOnLine then
        return StringTable.Get("str_chat_online")
    else
        local seconds = self:_GetServerTime() - self._lastOnlineTime
        --一分钟之内显示一分钟前
        if seconds <= 60 then --1分钟之内特殊处理
            return StringTable.Get("str_chat_minus_ago", 1)
        end

        --一小时之内，显示分钟
        if seconds < 3600 then
            local min = math.floor(seconds / 60)
            return StringTable.Get("str_chat_minus_ago", min)
        end

        --一天之内，显示小时
        if seconds < 86400 then
            local hour = math.floor(seconds / 3600)
            return StringTable.Get("str_chat_hour_ago", hour)
        end

        --三天之内，显示天
        if seconds < 259200 then
            local day = math.floor(seconds / 86400)
            return StringTable.Get("str_chat_day_ago", day)
        end

        --大于三天显示三天前
        return StringTable.Get("str_chat_day_ago", 3)
    end
end

function ChatFriendData:_GetServerTime()
    local time_mod = GameGlobal.GameLogic():GetModule(SvrTimeModule)
    local tmSecond, nMilliSecond = math.modf(time_mod:GetServerTime() / 1000)
    return tmSecond
end

--获取降星日期
function ChatFriendData:GetCreateDate()
    return self._createDate
end

function ChatFriendData:GetCreateDateStr()
    return TimeToDate(self._createDate, "day")
end

--获取需要显示的好友Id
function ChatFriendData:GetShowFriendId()
    ---@type LoginModule
    local loginModule = GameGlobal.GetModule(LoginModule)
    if not self._friendId then
        return ""
    end
    return loginModule:GetShowIdByPstId(self._friendId)
end

--是否是选中状态
function ChatFriendData:IsSelected()
    return self._isSelected
end

--设置选中状态
function ChatFriendData:SetSelectedStatus(status)
    self._isSelected = status
end

function ChatFriendData:SetSuggestSource(suggestSource)
    self._suggestSource = suggestSource
end

function ChatFriendData:GetSuggestSource()
    if self._suggestSource == SocialRecommendType.SocialRecommendType_Common then --有共同的好友
        return StringTable.Get("str_chat_suggest_source_has_same_friend")
    elseif self._suggestSource == SocialRecommendType.SocialRecommendType_Help then --使用过他的助战
        return StringTable.Get("str_chat_suggest_source_used_help_pet")
    end
    return ""
end

---@return HomelandSimpleInfo
function ChatFriendData:GetHomelandInfo()
    return self._homeland_info
end
