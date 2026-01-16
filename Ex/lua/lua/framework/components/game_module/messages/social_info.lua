--region dc define

--- @class SocialErrorCode
local SocialErrorCode = {
    SOCIAL_SUCC = 0, --	成功 												通用消息
    SOCIAL_FAILED = 1, --	失败 												通用消息
    SOCIAL_ERROR_SYSTEM = 10, -- 系统异常 											异常消息
    SOCIAL_ERROR_SYSTEM_RMI = 11, -- 服务通信异常											异常消息
    SOCIAL_ERROR_DB = 12, -- DB异常												异常消息
    SOCIAL_ERROR_PARAM = 100, -- 参数错误												异常消息
    SOCIAL_ERROR_DUPLICATE = 200, -- 重复加关系											异常消息
    SOCIAL_ERROR_SELF_COUNT_MAX = 201, -- 自己的好友数量已达上限								申请添加好友或通过添加好友申请
    SOCIAL_ERROR_PEER_COUNT_MAX = 202, -- 对方的好友数量已达上限								申请添加好友或通过添加好友申请
    SOCIAL_ERROR_SELF = 203, -- 不能和自己建立关系									申请添加好友或通过添加好友申请
    SOCIAL_ERROR_NULL_SOC = 204, -- 没有建立关系											异常消息
    SOCIAL_ERROR_INVITATION_COUNT_MAX = 301, -- 今日邀请次数已达上限									申请添加好友	
    SOCIAL_ERROR_INVITATION_SELF = 302, -- 不能邀请自己											申请添加好友
    SOCIAL_ERROR_DUPLICATE_BLACK = 400, -- 重复加黑名单											
    SOCIAL_ERROR_SELF_IN_BLACK = 401, -- 在自己的黑名单中										
    SOCIAL_ERROR_PEER_IN_BLACK = 402, -- 在对方的黑名单中										
    SOCIAL_ERROR_IN_PEER_INV_LIST = 403, -- 已经向该玩家发送过申请								申请添加好友
    SOCIAL_ERROR_ALREAD_PEER_FRIEND = 404, -- 你已经是对方的好友(系统直接将对方加为你的好友)		服务器内部消息
    SOCIAL_CHAT_ERROR_PARAM = 501, -- 参数不正确											异常消息
    SOCIAL_CHAT_ERROR_S2SRMI_FAIL = 502, -- S2S的RMI调用失败 									异常消息
    SOCIAL_CHAT_ERROR_CHANNEL_NOT_FOUND = 503, -- 找不到频道											无视
    SOCIAL_CHAT_ERROR_NOT_IN_CHANNEL = 504, -- 不在频道中											无视
    SOCIAL_CHAT_ERROR_NOT_PERMISSION_LOW_LEVEL = 505, -- 等级太低，没有使用聊天频道的权限						无视
    SOCIAL_CHAT_ERROR_FREQUENCY_LIMIT = 506, -- 发送频率过快											发送消息
    SOCIAL_CHAT_ERROR_LENGTH_LIMIT = 507, -- 聊天长度超出限制150字节								发送消息 
    SOCIAL_CHAT_ERROR_PLAYER_STATISICS_GET_FAIL = 508, -- 无法获取玩家统计										无视
    SOCIAL_CHAT_ERROR_PLAYER_GET_INFO_FAIL = 509, -- 无法获取玩家信息										无视
    SOCIAL_CHAT_ERROR_PLAYER_REFUSE_RECEIVE = 510, -- 对方拒绝接收聊天信息									无视
    SOCIAL_CHAT_NOT_FRIEND = 511, -- 对方不是你的好友										发送消息
    SOCIAL_CHAT_PEER_NOT_FRIEND = 512, -- 你不是对方的好友										发送消息
    SOCIAL_CHAT_SEND_TARGET_ERROR = 513, -- 选择聊天对象与服务端聊天对象不一致					发送消息
    SOCIAL_CHAT_IS_EMPTY = 514, -- 发送消息不能为空										发送消息
    SOCIAL_SEARCH_PSTID_INVALID = 515, -- 玩家不存在											
    SOCIAL_CHAT_ERROR_TIME_OUT = 516, -- 发送网络超时
    SOCIAL_CHAT_SEND_TYPE_ERROR = 517, -- 发送消息类型错误											 发送消息
    SOCIAL_CHAT_EMOJI_NUM_ERROR = 518, -- 表情类消息id必须大于0									 发送消息
    SOCIAL_REMARK_LIMIT = 519, -- 名字最大长度不能超过14个字符(英文14个中文7个)			 好友备注
    SOCIAL_REMARK_DIRTY = 520, -- 备注含有敏感字											 好友备注
    SOCIAL_REMARK_SPE = 521, -- 备注含有特殊字符											 好友备注 		
    SOCIAL_REMARK_INVALID = 522, -- 名字含有其他国家的文字 只能是中文 韩文 日文 数字 英文字母 好友备注
    SOCIAL_BLACK_LIST_LIMIT = 523, -- 黑名单已经满了											 黑名单
    SOCIAL_INVITATION_MUTUAL_SUCCESS = 524, -- 成功相互添加上好友 你已经是他的好友 他也是你的好友		 发送好友申请
}
_enum("SocialErrorCode", SocialErrorCode)

--- @class SocialChatErrorCode
local SocialChatErrorCode = {
    SOCIAL_CHAT_SUCCESS = 0,
    SOCIAL_CHAT_FAILED = 1,
}
_enum("SocialChatErrorCode", SocialChatErrorCode)

-- 关系类型
--- @class SocialType
local SocialType = {
    SOCIAL_TYPE_NONE = 0, -- 未定义
    SOCIAL_TYPE_SELF = 1, -- 自己
    SOCIAL_TYPE_STRANGER = 100, -- 陌生人
    SOCIAL_TYPE_FRIEND = 1000, -- 好友
    SOCIAL_TYPE_LOVER = 2000, -- 情侣
}
_enum("SocialType", SocialType)

-- 邀请类型
--- @class InvitationType
local InvitationType = {
    INVAITATION_TYPE_NONE = 0, -- 未定义
    INVAITATION_TYPE_FRIEND = 1, -- 好友邀请
    INVAITATION_TYPE_LOVER = 2, -- 伴侣邀请
}
_enum("InvitationType", InvitationType)

-- 更新好友数据类型
--- @class UpdateFriendInfoType
local UpdateFriendInfoType = {
    UpdateFriendInfoType_Update = 0, -- 更新现有好友数据
    UpdateFriendInfoType_Add = 1, -- 添加新好友
    UpdateFriendInfoType_Del = 2, -- 删除老好友
}
_enum("UpdateFriendInfoType", UpdateFriendInfoType)

-- 推荐好友类型
--- @class SocialRecommendType
local SocialRecommendType = {
    SocialRecommendType_Common = 0, -- 共同好友
    SocialRecommendType_Help = 1, -- 7天内使用过这个人的助战星灵
    SocialRecommendType_Niubility = 2, -- 此玩家设置了至少3个达到觉醒2的助战光灵
    SocialRecommendType_Random = 3, -- 随机推荐
    SocialRecommendType_Count = 4,
}
_enum("SocialRecommendType", SocialRecommendType)

--世界BOSS相关信息
--region role_world_boss_info define
---@class role_world_boss_info:Object
_class("role_world_boss_info",Object)
role_world_boss_info = role_world_boss_info

 function role_world_boss_info:Constructor()
    self.dan_head_switch = true --默认打开
    self.dan = 0 --段位
    self.grading = 0 --名次
end
--region dc custom role_world_boss_info
--endregion dc custom role_world_boss_info
---@private
role_world_boss_info._proto = {
    [1] = {"dan_head_switch", "bool"},
    [2] = {"dan", "int"},
    [3] = {"grading", "int"},
}
--endregion

-- 社交玩家简易信息
--region social_player_info define
---@class social_player_info:Object
_class("social_player_info",Object)
social_player_info = social_player_info

 function social_player_info:Constructor()
    self.pstid = 0 -- 玩家ID
    self.nick = "" -- 昵称
    self.head = 0 -- 玩家头像
    self.head_bg = 0 -- 玩家头像背景
    self.level = 0 -- 玩家等级
    self.is_online = false -- 是否在线
    self.create_time = 0 -- 玩家创建时间
    self.last_logout_time = 0 -- 上次下线时间
    self.remark_name = "" -- 玩家备注信息
    self.help_pet = {} -- 助战星灵
    self.frame_id = 0 -- 玩家头像框
    self.world_boss_info = role_world_boss_info:New() -- 玩家的世界boss头像信息
    self.peak_score = 0 -- 巅峰rank积分
    self.homeland_info = HomelandSimpleInfo:New() -- 家园
    self.difficulty_mission = 0 --主线困难关新增当前杯数
    self.sailing_mission = 0 --大航海当前关
    self.title_used = 0 --使用中的称号ID 
    self.fifure_used = 0 --使用中的纹饰ID
    self.medal_placement = medal_placement_info:New() --好友勋章摆放信息
end
--region dc custom social_player_info
--endregion dc custom social_player_info
---@private
social_player_info._proto = {
    [1] = {"pstid", "int64"},
    [2] = {"nick", "string"},
    [3] = {"head", "int"},
    [4] = {"head_bg", "int"},
    [5] = {"level", "int"},
    [6] = {"is_online", "bool"},
    [7] = {"create_time", "time"},
    [8] = {"last_logout_time", "time"},
    [9] = {"remark_name", "string"},
    [10] = {"help_pet", "list<role_help_pet_info>"},
    [11] = {"frame_id", "int"},
    [12] = {"world_boss_info", "role_world_boss_info"},
    [13] = {"peak_score", "int64"},
    [14] = {"homeland_info", "HomelandSimpleInfo"},
    [15] = {"difficulty_mission", "int"},
    [16] = {"sailing_mission", "int"},
    [17] = {"title_used", "int"},
    [18] = {"fifure_used", "int"},
    [19] = {"medal_placement", "medal_placement_info"},
}
--endregion

-- 推送给客户端的好友列表
--region social_info_mobile define
---@class social_info_mobile:Object
_class("social_info_mobile",Object)
social_info_mobile = social_info_mobile

 function social_info_mobile:Constructor()
    self.simple_info = social_player_info:New() -- 好友基础信息
    self.create_time = 0 -- 好友关系创建时间
    self.un_read_msg_num = 0 -- 未读消息数量
    self.end_msg_time = 0 -- 最后一条的未读消息时间
end
--region dc custom social_info_mobile
--endregion dc custom social_info_mobile
---@private
social_info_mobile._proto = {
    [1] = {"simple_info", "social_player_info"},
    [2] = {"create_time", "time"},
    [3] = {"un_read_msg_num", "int"},
    [4] = {"end_msg_time", "time"},
}
--endregion

-- 推荐结构
--region social_recommend define
---@class social_recommend:Object
_class("social_recommend",Object)
social_recommend = social_recommend

 function social_recommend:Constructor()
    self.nRecommendType = 0 -- 推荐类型 SocialRecommendType
    self.recommend_info = social_player_info:New() -- 推荐信息
end
--region dc custom social_recommend
--endregion dc custom social_recommend
---@private
social_recommend._proto = {
    [1] = {"nRecommendType", "int"},
    [2] = {"recommend_info", "social_player_info"},
}
--endregion

-- 好友详情信息
--region social_player_detail_info define
---@class social_player_detail_info:Object
_class("social_player_detail_info",Object)
social_player_detail_info = social_player_detail_info

 function social_player_detail_info:Constructor()
    self.simple_info = social_player_info:New()
    self.role_sign_text = "" -- 玩家签名
    self.fight_info = role_fight_info:New() -- 玩家战斗信息	
end
--region dc custom social_player_detail_info
--endregion dc custom social_player_detail_info
---@private
social_player_detail_info._proto = {
    [1] = {"simple_info", "social_player_info"},
    [2] = {"role_sign_text", "string"},
    [3] = {"fight_info", "role_fight_info"},
}
--endregion

-- 邀请结构发给客户端的
--region social_invitation_info_mobile define
---@class social_invitation_info_mobile:Object
_class("social_invitation_info_mobile",Object)
social_invitation_info_mobile = social_invitation_info_mobile

 function social_invitation_info_mobile:Constructor()
    self.sender_info = social_player_info:New() -- 申请人的基础信息
    self.create_time = 0 -- 创建时间
end
--region dc custom social_invitation_info_mobile
--endregion dc custom social_invitation_info_mobile
---@private
social_invitation_info_mobile._proto = {
    [1] = {"sender_info", "social_player_info"},
    [2] = {"create_time", "time"},
}
--endregion

--region send_invitation define
---@class send_invitation:Object
_class("send_invitation",Object)
send_invitation = send_invitation

 function send_invitation:Constructor()
    self.receiver_pstid = 0 -- 接收邀请的ID
    self.invitation_type = 0 -- 邀请类型
end
--region dc custom send_invitation
--endregion dc custom send_invitation
---@private
send_invitation._proto = {
    [1] = {"receiver_pstid", "int64"},
    [2] = {"invitation_type", "int"},
}
--endregion

--region process_invitation define
---@class process_invitation:Object
_class("process_invitation",Object)
process_invitation = process_invitation

 function process_invitation:Constructor()
    self.sender_pstid = 0 -- 发送邀请的玩家pstid
    self.is_pass = false -- true为同意，false为拒绝
end
--region dc custom process_invitation
--endregion dc custom process_invitation
---@private
process_invitation._proto = {
    [1] = {"sender_pstid", "int64"},
    [2] = {"is_pass", "bool"},
}
--endregion

-- 黑名单结构
--region social_black_info define
---@class social_black_info:Object
_class("social_black_info",Object)
social_black_info = social_black_info

 function social_black_info:Constructor()
    self.self_pstid = 0 -- 自己的ID
    self.black_pstid = 0 -- 对方的ID
    self.create_time = 0 -- 创建时间
end
--region dc custom social_black_info
--endregion dc custom social_black_info
---@private
social_black_info._proto = {
    [1] = {"self_pstid", "int64"},
    [2] = {"black_pstid", "int64"},
    [3] = {"create_time", "time"},
}
--endregion

-- 好友消息数据
--region social_msg_mobile define
---@class social_msg_mobile:Object
_class("social_msg_mobile",Object)
social_msg_mobile = social_msg_mobile

 function social_msg_mobile:Constructor()
    self.chat_time = 0 -- 发送时间
    self.chat_message = "" -- 内容
end
--region dc custom social_msg_mobile
--endregion dc custom social_msg_mobile
---@private
social_msg_mobile._proto = {
    [1] = {"chat_time", "time"},
    [2] = {"chat_message", "string"},
}
--endregion

--endregion dc define
