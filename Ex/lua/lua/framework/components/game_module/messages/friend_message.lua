--region dc define
require "message_def"

local friendMessageDef ={
    --region friend
    CLSID_CEventGetOnlinePlayer = 27000,
    CLSID_CEventGetOnlinePlayerResult = 27001,
    CLSID_CEventGetFriendList = 27002,
    CLSID_CEventGetFriendListResult = 27003,
    CLSID_CEventGetFriendInvitationList = 27004,
    CLSID_CEventGetFriendInvitationListResult = 27005,
    CLSID_CEventGetSocialBlackList = 27006,
    CLSID_CEventGetSocialBlackListResult = 27007,
    CLSID_CEventAddFriend = 27008,
    CLSID_CEventAddFriendResult = 27009,
    CLSID_CEventProcessAddFriend = 27010,
    CLSID_CEventProcessAddFriendResult = 27011,
    CLSID_CEventUpdateSocialBlackList = 27012,
    CLSID_CEventUpdateSocialBlackListResult = 27013,
    CLSID_CEventDelFriend = 27014,
    CLSID_CEventDelFriendResult = 27015,
    CLSID_CEventUpdateIntimacy = 27016,
    CLSID_CEventUpdateIntimacyResult = 27017,
    CLSID_CEventPushUpdateFriendInvitation = 27018,
    CLSID_CEventPushUpdateFriendOtherInvitation = 27019,
    CLSID_CEventPushUpdateFriendList = 27020,
    CLSID_CEventEnterChatFriendModule = 27021,
    CLSID_CEventEnterChatFriendModuleResult = 27022,
    CLSID_CEventLeaveChatFriendModule = 27023,
    CLSID_CEventLeaveChatFriendModuleResult = 27024,
    CLSID_CEventSelectChatFriend = 27025,
    CLSID_CEventSelectChatFriendResult = 27026,
    CLSID_CEventPushClientRecvMaxMsgIdAck = 27027,
    CLSID_CEventPushHaveNewFriendMsg = 27028,
    CLSID_CEventPushHaveNewFriendMsgInner = 27029,
    CLSID_CEventSendFriendMsg = 27030,
    CLSID_CEventSendFriendMsgResult = 27031,
    CLSID_CEventPushFriendMsg = 27032,
    CLSID_CEventSearchFriend = 27033,
    CLSID_CEventSearchFriendResult = 27034,
    CLSID_CEventPushHaveNewMsg = 27035,
    CLSID_CEventOutSidePushNewMsg = 27036,
    CLSID_CEventGetPlayerDetailInfo = 27037,
    CLSID_CEventGetPlayerDetailInfoResult = 27038,
    CLSID_CEventSetFriendRemarkName = 27039,
    CLSID_CEventSetFriendRemarkNameResult = 27040,
    CLSID_CEventRefreshRecommendPlayer = 27041,
    CLSID_CEventRefreshRecommendPlayerResult = 27042,
    CLSID_CEventRefreshFriendOnlineState = 27043,
    CLSID_CEventRefreshFriendOnlineStateResult = 27044,
    CLSID_CEventBothwayFriendReq = 27045,
    CLSID_CEventBothwayFriendResult = 27046,
    --endregion
}
table.append(MessageDef, friendMessageDef)

-- 获取在线玩家列表
--region CEventGetOnlinePlayer define
---@class CEventGetOnlinePlayer:CCallRequestEvent
_class("CEventGetOnlinePlayer",CCallRequestEvent)
CEventGetOnlinePlayer = CEventGetOnlinePlayer

 function CEventGetOnlinePlayer:Constructor()
    self.page_number = 0 -- 分页数，从1开始
end
---@private
CEventGetOnlinePlayer._proto = {
    [1] = {"page_number", "int"},
}
--endregion

--region CEventGetOnlinePlayerResult define
---@class CEventGetOnlinePlayerResult:CCallReplyEvent
_class("CEventGetOnlinePlayerResult",CCallReplyEvent)
CEventGetOnlinePlayerResult = CEventGetOnlinePlayerResult

 function CEventGetOnlinePlayerResult:Constructor()
    self.ret = 0
    self.player_list = {}
end
---@private
CEventGetOnlinePlayerResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"player_list", "list<role_simple_info>"},
}
--endregion

-- 获取好友列表
--region CEventGetFriendList define
---@class CEventGetFriendList:CCallRequestEvent
_class("CEventGetFriendList",CCallRequestEvent)
CEventGetFriendList = CEventGetFriendList

 function CEventGetFriendList:Constructor()
end
---@private
CEventGetFriendList._proto = {
}
--endregion

--region CEventGetFriendListResult define
---@class CEventGetFriendListResult:CCallReplyEvent
_class("CEventGetFriendListResult",CCallReplyEvent)
CEventGetFriendListResult = CEventGetFriendListResult

 function CEventGetFriendListResult:Constructor()
    self.ret = 0
    self.friend_list = {}
end
---@private
CEventGetFriendListResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"friend_list", "map<int64,social_info_mobile>"},
}
--endregion

-- 获取加我为好友的申请列表
--region CEventGetFriendInvitationList define
---@class CEventGetFriendInvitationList:CCallRequestEvent
_class("CEventGetFriendInvitationList",CCallRequestEvent)
CEventGetFriendInvitationList = CEventGetFriendInvitationList

 function CEventGetFriendInvitationList:Constructor()
end
---@private
CEventGetFriendInvitationList._proto = {
}
--endregion

--region CEventGetFriendInvitationListResult define
---@class CEventGetFriendInvitationListResult:CCallReplyEvent
_class("CEventGetFriendInvitationListResult",CCallReplyEvent)
CEventGetFriendInvitationListResult = CEventGetFriendInvitationListResult

 function CEventGetFriendInvitationListResult:Constructor()
    self.ret = 0
    self.invitation_list = {} -- 加我为好友的申请列表
end
---@private
CEventGetFriendInvitationListResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"invitation_list", "list<social_invitation_info_mobile>"},
}
--endregion

-- 获取关系黑名单列表
--region CEventGetSocialBlackList define
---@class CEventGetSocialBlackList:CCallRequestEvent
_class("CEventGetSocialBlackList",CCallRequestEvent)
CEventGetSocialBlackList = CEventGetSocialBlackList

 function CEventGetSocialBlackList:Constructor()
end
---@private
CEventGetSocialBlackList._proto = {
}
--endregion

--region CEventGetSocialBlackListResult define
---@class CEventGetSocialBlackListResult:CCallReplyEvent
_class("CEventGetSocialBlackListResult",CCallReplyEvent)
CEventGetSocialBlackListResult = CEventGetSocialBlackListResult

 function CEventGetSocialBlackListResult:Constructor()
    self.ret = 0
    self.black_list = {}
end
---@private
CEventGetSocialBlackListResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"black_list", "map<int64,social_player_info>"},
}
--endregion

-- 邀请加好友
--region CEventAddFriend define
---@class CEventAddFriend:CCallRequestEvent
_class("CEventAddFriend",CCallRequestEvent)
CEventAddFriend = CEventAddFriend

 function CEventAddFriend:Constructor()
    self.send_invt = send_invitation:New()
end
---@private
CEventAddFriend._proto = {
    [1] = {"send_invt", "send_invitation"},
}
--endregion

--region CEventAddFriendResult define
---@class CEventAddFriendResult:CCallReplyEvent
_class("CEventAddFriendResult",CCallReplyEvent)
CEventAddFriendResult = CEventAddFriendResult

 function CEventAddFriendResult:Constructor()
    self.ret = 0
end
---@private
CEventAddFriendResult._proto = {
    [1] = {"ret", "int"},
}
--endregion

-- 处理好友邀请
--region CEventProcessAddFriend define
---@class CEventProcessAddFriend:CCallRequestEvent
_class("CEventProcessAddFriend",CCallRequestEvent)
CEventProcessAddFriend = CEventProcessAddFriend

 function CEventProcessAddFriend:Constructor()
    self.proc_invt = process_invitation:New()
end
---@private
CEventProcessAddFriend._proto = {
    [1] = {"proc_invt", "process_invitation"},
}
--endregion

--region CEventProcessAddFriendResult define
---@class CEventProcessAddFriendResult:CCallReplyEvent
_class("CEventProcessAddFriendResult",CCallReplyEvent)
CEventProcessAddFriendResult = CEventProcessAddFriendResult

 function CEventProcessAddFriendResult:Constructor()
    self.ret = 0
end
---@private
CEventProcessAddFriendResult._proto = {
    [1] = {"ret", "int"},
}
--endregion

-- 更新黑名单
--region CEventUpdateSocialBlackList define
---@class CEventUpdateSocialBlackList:CCallRequestEvent
_class("CEventUpdateSocialBlackList",CCallRequestEvent)
CEventUpdateSocialBlackList = CEventUpdateSocialBlackList

 function CEventUpdateSocialBlackList:Constructor()
    self.black_pstid = 0
    self.is_del = false -- true 移除黑名单 false 加入黑名单
end
---@private
CEventUpdateSocialBlackList._proto = {
    [1] = {"black_pstid", "int64"},
    [2] = {"is_del", "bool"},
}
--endregion

--region CEventUpdateSocialBlackListResult define
---@class CEventUpdateSocialBlackListResult:CCallReplyEvent
_class("CEventUpdateSocialBlackListResult",CCallReplyEvent)
CEventUpdateSocialBlackListResult = CEventUpdateSocialBlackListResult

 function CEventUpdateSocialBlackListResult:Constructor()
    self.ret = 0
    self.player_info = social_player_info:New()
end
---@private
CEventUpdateSocialBlackListResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"player_info", "social_player_info"},
}
--endregion

-- 删除好友
--region CEventDelFriend define
---@class CEventDelFriend:CCallRequestEvent
_class("CEventDelFriend",CCallRequestEvent)
CEventDelFriend = CEventDelFriend

 function CEventDelFriend:Constructor()
    self.peer_pstid = 0
end
---@private
CEventDelFriend._proto = {
    [1] = {"peer_pstid", "int64"},
}
--endregion

--region CEventDelFriendResult define
---@class CEventDelFriendResult:CCallReplyEvent
_class("CEventDelFriendResult",CCallReplyEvent)
CEventDelFriendResult = CEventDelFriendResult

 function CEventDelFriendResult:Constructor()
    self.ret = 0
end
---@private
CEventDelFriendResult._proto = {
    [1] = {"ret", "int"},
}
--endregion

-- 亲密度增加
--region CEventUpdateIntimacy define
---@class CEventUpdateIntimacy:CCallRequestEvent
_class("CEventUpdateIntimacy",CCallRequestEvent)
CEventUpdateIntimacy = CEventUpdateIntimacy

 function CEventUpdateIntimacy:Constructor()
    self.friend_pstid = 0
    self.change_value = 0
end
---@private
CEventUpdateIntimacy._proto = {
    [1] = {"friend_pstid", "int64"},
    [2] = {"change_value", "int"},
}
--endregion

--region CEventUpdateIntimacyResult define
---@class CEventUpdateIntimacyResult:CCallReplyEvent
_class("CEventUpdateIntimacyResult",CCallReplyEvent)
CEventUpdateIntimacyResult = CEventUpdateIntimacyResult

 function CEventUpdateIntimacyResult:Constructor()
    self.ret = 0
end
---@private
CEventUpdateIntimacyResult._proto = {
    [1] = {"ret", "int"},
}
--endregion

-- 推送有新的好友申请
--region CEventPushUpdateFriendInvitation define
---@class CEventPushUpdateFriendInvitation:CSvrPushEvent
_class("CEventPushUpdateFriendInvitation",CSvrPushEvent)
CEventPushUpdateFriendInvitation = CEventPushUpdateFriendInvitation

 function CEventPushUpdateFriendInvitation:Constructor()
    self.bHaveNewInvitation = false
end
---@private
CEventPushUpdateFriendInvitation._proto = {
    [1] = {"bHaveNewInvitation", "bool"},
}
--endregion

--region CEventPushUpdateFriendOtherInvitation define
---@class CEventPushUpdateFriendOtherInvitation:CSvrPushEvent
_class("CEventPushUpdateFriendOtherInvitation",CSvrPushEvent)
CEventPushUpdateFriendOtherInvitation = CEventPushUpdateFriendOtherInvitation

 function CEventPushUpdateFriendOtherInvitation:Constructor()
    self.receiver_pstid = 0
    self.simple_info = role_simple_info:New()
    self.is_del = false
    self.is_pass = false
end
---@private
CEventPushUpdateFriendOtherInvitation._proto = {
    [1] = {"receiver_pstid", "int64"},
    [2] = {"simple_info", "role_simple_info"},
    [3] = {"is_del", "bool"},
    [4] = {"is_pass", "bool"},
}
--endregion

-- 刷新好友数据
--region CEventPushUpdateFriendList define
---@class CEventPushUpdateFriendList:CSvrPushEvent
_class("CEventPushUpdateFriendList",CSvrPushEvent)
CEventPushUpdateFriendList = CEventPushUpdateFriendList

 function CEventPushUpdateFriendList:Constructor()
    self.update_info = social_info_mobile:New() -- 删除好友时 服务端只返回simple_info的pstid
    self.update_type = 0 -- UpdateFriendInfoType 0 为更新好友信息 1为添加新好友 2 为删除老好友
end
---@private
CEventPushUpdateFriendList._proto = {
    [1] = {"update_info", "social_info_mobile"},
    [2] = {"update_type", "int"},
}
--endregion

-- 进入好友功能
--region CEventEnterChatFriendModule define
---@class CEventEnterChatFriendModule:CCallRequestEvent
_class("CEventEnterChatFriendModule",CCallRequestEvent)
CEventEnterChatFriendModule = CEventEnterChatFriendModule

 function CEventEnterChatFriendModule:Constructor()
end
---@private
CEventEnterChatFriendModule._proto = {
}
--endregion

--region CEventEnterChatFriendModuleResult define
---@class CEventEnterChatFriendModuleResult:CCallReplyEvent
_class("CEventEnterChatFriendModuleResult",CCallReplyEvent)
CEventEnterChatFriendModuleResult = CEventEnterChatFriendModuleResult

 function CEventEnterChatFriendModuleResult:Constructor()
    self.ret = 0
    self.friend_list = {}
    self.bHaveInvitation = false
    self.bIsGotInvitationList = false -- 是否查看过过好友申请列表
end
---@private
CEventEnterChatFriendModuleResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"friend_list", "map<int64,social_info_mobile>"},
    [3] = {"bHaveInvitation", "bool"},
    [4] = {"bIsGotInvitationList", "bool"},
}
--endregion

-- 离开好友功能
--region CEventLeaveChatFriendModule define
---@class CEventLeaveChatFriendModule:CCallRequestEvent
_class("CEventLeaveChatFriendModule",CCallRequestEvent)
CEventLeaveChatFriendModule = CEventLeaveChatFriendModule

 function CEventLeaveChatFriendModule:Constructor()
end
---@private
CEventLeaveChatFriendModule._proto = {
}
--endregion

--region CEventLeaveChatFriendModuleResult define
---@class CEventLeaveChatFriendModuleResult:CCallReplyEvent
_class("CEventLeaveChatFriendModuleResult",CCallReplyEvent)
CEventLeaveChatFriendModuleResult = CEventLeaveChatFriendModuleResult

 function CEventLeaveChatFriendModuleResult:Constructor()
    self.ret = 0
end
---@private
CEventLeaveChatFriendModuleResult._proto = {
    [1] = {"ret", "int"},
}
--endregion

-- 选择聊天好友
--region CEventSelectChatFriend define
---@class CEventSelectChatFriend:CCallRequestEvent
_class("CEventSelectChatFriend",CCallRequestEvent)
CEventSelectChatFriend = CEventSelectChatFriend

 function CEventSelectChatFriend:Constructor()
    self.select_friend = 0
end
---@private
CEventSelectChatFriend._proto = {
    [1] = {"select_friend", "int64"},
}
--endregion

-- 选择聊天好友并返回该好友的离线信息
--region CEventSelectChatFriendResult define
---@class CEventSelectChatFriendResult:CCallReplyEvent
_class("CEventSelectChatFriendResult",CCallReplyEvent)
CEventSelectChatFriendResult = CEventSelectChatFriendResult

 function CEventSelectChatFriendResult:Constructor()
    self.ret = 0
    self.sender_pstid = 0 -- 发送者的id
    self.msg_list = {} -- 消息列表
end
---@private
CEventSelectChatFriendResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"sender_pstid", "int64"},
    [3] = {"msg_list", "list<chat_message_info>"},
}
--endregion

-- 客户端推送收到并且已经存储上的的最大消息id
--region CEventPushClientRecvMaxMsgIdAck define
---@class CEventPushClientRecvMaxMsgIdAck:CCliPushEvent
_class("CEventPushClientRecvMaxMsgIdAck",CCliPushEvent)
CEventPushClientRecvMaxMsgIdAck = CEventPushClientRecvMaxMsgIdAck

 function CEventPushClientRecvMaxMsgIdAck:Constructor()
    self.sender_pstid = 0 -- 发送者id
    self.recv_msg_max_id = 0 -- 收到发送者最大消息id
end
---@private
CEventPushClientRecvMaxMsgIdAck._proto = {
    [1] = {"sender_pstid", "int64"},
    [2] = {"recv_msg_max_id", "uint64"},
}
--endregion

-- 好友模块外告诉客户端有新消息
--region CEventPushHaveNewFriendMsg define
---@class CEventPushHaveNewFriendMsg:CSvrPushEvent
_class("CEventPushHaveNewFriendMsg",CSvrPushEvent)
CEventPushHaveNewFriendMsg = CEventPushHaveNewFriendMsg

 function CEventPushHaveNewFriendMsg:Constructor()
end
---@private
CEventPushHaveNewFriendMsg._proto = {
}
--endregion

-- 好友模块内告诉客户端有新消息
--region CEventPushHaveNewFriendMsgInner define
---@class CEventPushHaveNewFriendMsgInner:CSvrPushEvent
_class("CEventPushHaveNewFriendMsgInner",CSvrPushEvent)
CEventPushHaveNewFriendMsgInner = CEventPushHaveNewFriendMsgInner

 function CEventPushHaveNewFriendMsgInner:Constructor()
    self.msg_player_list = {} -- 有新消息的好友列表
end
---@private
CEventPushHaveNewFriendMsgInner._proto = {
    [1] = {"msg_player_list", "list<int64>"},
}
--endregion

-- 发送好友消息
--region CEventSendFriendMsg define
---@class CEventSendFriendMsg:CCallRequestEvent
_class("CEventSendFriendMsg",CCallRequestEvent)
CEventSendFriendMsg = CEventSendFriendMsg

 function CEventSendFriendMsg:Constructor()
    self.select_friend = 0
    self.send_message = ""
    self.friend_msg_type = FRIEND_CHAT_MSG_TYPE.FRIEND_CHAT_MSG_TYPE_STR
    self.emoji_id = 0
end
---@private
CEventSendFriendMsg._proto = {
    [1] = {"select_friend", "int64"},
    [2] = {"send_message", "string"},
    [3] = {"friend_msg_type", "short"},
    [4] = {"emoji_id", "short"},
}
--endregion

--region CEventSendFriendMsgResult define
---@class CEventSendFriendMsgResult:CCallReplyEvent
_class("CEventSendFriendMsgResult",CCallReplyEvent)
CEventSendFriendMsgResult = CEventSendFriendMsgResult

 function CEventSendFriendMsgResult:Constructor()
    self.ret = 0 -- 
    self.send_msg = chat_message_info:New() -- 发送成功后返回的消息
end
---@private
CEventSendFriendMsgResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"send_msg", "chat_message_info"},
}
--endregion

-- 推送好友消息
--region CEventPushFriendMsg define
---@class CEventPushFriendMsg:CSvrPushEvent
_class("CEventPushFriendMsg",CSvrPushEvent)
CEventPushFriendMsg = CEventPushFriendMsg

 function CEventPushFriendMsg:Constructor()
    self.sender_pstid = 0 -- 发送者的id
    self.msg_list = {} -- 消息列表
end
---@private
CEventPushFriendMsg._proto = {
    [1] = {"sender_pstid", "int64"},
    [2] = {"msg_list", "list<chat_message_info>"},
}
--endregion

-- 搜索好友
--region CEventSearchFriend define
---@class CEventSearchFriend:CCallRequestEvent
_class("CEventSearchFriend",CCallRequestEvent)
CEventSearchFriend = CEventSearchFriend

 function CEventSearchFriend:Constructor()
    self.search_pstid_list = {}
end
---@private
CEventSearchFriend._proto = {
    [1] = {"search_pstid_list", "list<int64>"},
}
--endregion

--region CEventSearchFriendResult define
---@class CEventSearchFriendResult:CCallReplyEvent
_class("CEventSearchFriendResult",CCallReplyEvent)
CEventSearchFriendResult = CEventSearchFriendResult

 function CEventSearchFriendResult:Constructor()
    self.ret = 0 -- 
    self.player_info_list = {}
end
---@private
CEventSearchFriendResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"player_info_list", "list<social_player_info>"},
}
--endregion

-- 模块内推送通知有新消息
--region CEventPushHaveNewMsg define
---@class CEventPushHaveNewMsg:CSvrPushEvent
_class("CEventPushHaveNewMsg",CSvrPushEvent)
CEventPushHaveNewMsg = CEventPushHaveNewMsg

 function CEventPushHaveNewMsg:Constructor()
    self.sender_pstid = 0 -- 发信者pstid
    self.send_time = 0
end
---@private
CEventPushHaveNewMsg._proto = {
    [1] = {"sender_pstid", "int64"},
    [2] = {"send_time", "time"},
}
--endregion

-- 模块外推送有新消息
--region CEventOutSidePushNewMsg define
---@class CEventOutSidePushNewMsg:CSvrPushEvent
_class("CEventOutSidePushNewMsg",CSvrPushEvent)
CEventOutSidePushNewMsg = CEventOutSidePushNewMsg

 function CEventOutSidePushNewMsg:Constructor()
end
---@private
CEventOutSidePushNewMsg._proto = {
}
--endregion

-- 获取玩家详情信息
--region CEventGetPlayerDetailInfo define
---@class CEventGetPlayerDetailInfo:CCallRequestEvent
_class("CEventGetPlayerDetailInfo",CCallRequestEvent)
CEventGetPlayerDetailInfo = CEventGetPlayerDetailInfo

 function CEventGetPlayerDetailInfo:Constructor()
    self.pst_id = 0
end
---@private
CEventGetPlayerDetailInfo._proto = {
    [1] = {"pst_id", "int64"},
}
--endregion

--region CEventGetPlayerDetailInfoResult define
---@class CEventGetPlayerDetailInfoResult:CCallReplyEvent
_class("CEventGetPlayerDetailInfoResult",CCallReplyEvent)
CEventGetPlayerDetailInfoResult = CEventGetPlayerDetailInfoResult

 function CEventGetPlayerDetailInfoResult:Constructor()
    self.ret = 0
    self.m_social_info = social_player_detail_info:New()
end
---@private
CEventGetPlayerDetailInfoResult._proto = {
    [1] = {"ret", "int"},
    [2] = {"m_social_info", "social_player_detail_info"},
}
--endregion

-- 设置好友备注 通过腾讯IEG检测 
--region CEventSetFriendRemarkName define
---@class CEventSetFriendRemarkName:CCallRequestEvent
_class("CEventSetFriendRemarkName",CCallRequestEvent)
CEventSetFriendRemarkName = CEventSetFriendRemarkName

 function CEventSetFriendRemarkName:Constructor()
    self.pst_id = 0
    self.remark_name = "" -- 备注名
end
---@private
CEventSetFriendRemarkName._proto = {
    [1] = {"pst_id", "int64"},
    [2] = {"remark_name", "string"},
}
--endregion

--region CEventSetFriendRemarkNameResult define
---@class CEventSetFriendRemarkNameResult:CCallReplyEvent
_class("CEventSetFriendRemarkNameResult",CCallReplyEvent)
CEventSetFriendRemarkNameResult = CEventSetFriendRemarkNameResult

 function CEventSetFriendRemarkNameResult:Constructor()
    self.ret = 0
end
---@private
CEventSetFriendRemarkNameResult._proto = {
    [1] = {"ret", "int"},
}
--endregion

-- 获取推荐好友
--region CEventRefreshRecommendPlayer define
---@class CEventRefreshRecommendPlayer:CCallRequestEvent
_class("CEventRefreshRecommendPlayer",CCallRequestEvent)
CEventRefreshRecommendPlayer = CEventRefreshRecommendPlayer

 function CEventRefreshRecommendPlayer:Constructor()
    self.bRefresh = false -- true刷新服务端会重新计算 false不刷新获取与上次同样的列表
end
---@private
CEventRefreshRecommendPlayer._proto = {
    [1] = {"bRefresh", "bool"},
}
--endregion

--region CEventRefreshRecommendPlayerResult define
---@class CEventRefreshRecommendPlayerResult:CCallReplyEvent
_class("CEventRefreshRecommendPlayerResult",CCallReplyEvent)
CEventRefreshRecommendPlayerResult = CEventRefreshRecommendPlayerResult

 function CEventRefreshRecommendPlayerResult:Constructor()
    self.rec_vec = {} -- 索引为 SocialRecommendType 客户端lua需要 + 1
end
---@private
CEventRefreshRecommendPlayerResult._proto = {
    [2] = {"rec_vec", "list<social_recommend>"},
}
--endregion

-- 刷新好友在线状态
--region CEventRefreshFriendOnlineState define
---@class CEventRefreshFriendOnlineState:CCallRequestEvent
_class("CEventRefreshFriendOnlineState",CCallRequestEvent)
CEventRefreshFriendOnlineState = CEventRefreshFriendOnlineState

 function CEventRefreshFriendOnlineState:Constructor()
end
---@private
CEventRefreshFriendOnlineState._proto = {
}
--endregion

--region CEventRefreshFriendOnlineStateResult define
---@class CEventRefreshFriendOnlineStateResult:CCallReplyEvent
_class("CEventRefreshFriendOnlineStateResult",CCallReplyEvent)
CEventRefreshFriendOnlineStateResult = CEventRefreshFriendOnlineStateResult

 function CEventRefreshFriendOnlineStateResult:Constructor()
    self.update_friend_list = {} -- 发生变更的好友数据
end
---@private
CEventRefreshFriendOnlineStateResult._proto = {
    [1] = {"update_friend_list", "list<social_info_mobile>"},
}
--endregion

--获取是否是双向好友
--region CEventBothwayFriendReq define
---@class CEventBothwayFriendReq:CCallRequestEvent
_class("CEventBothwayFriendReq",CCallRequestEvent)
CEventBothwayFriendReq = CEventBothwayFriendReq

 function CEventBothwayFriendReq:Constructor()
    self.pst_id = 0
end
---@private
CEventBothwayFriendReq._proto = {
    [1] = {"pst_id", "int64"},
}
--endregion

--region CEventBothwayFriendResult define
---@class CEventBothwayFriendResult:CCallReplyEvent
_class("CEventBothwayFriendResult",CCallReplyEvent)
CEventBothwayFriendResult = CEventBothwayFriendResult

 function CEventBothwayFriendResult:Constructor()
    self.ret = 0
end
---@private
CEventBothwayFriendResult._proto = {
    [1] = {"ret", "int"},
}
--endregion

--endregion dc define
