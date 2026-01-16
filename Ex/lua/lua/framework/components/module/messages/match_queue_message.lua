--region dc define
require "message_def"

local match_queueMessageDef ={
    --region match_queue
    CLSID_CEventRequestQuickJoinMatch = 12000,
    CLSID_CEventReplyQuickJoinMatch = 12001,
    CLSID_CEventRequestCancelQuickJoinMatch = 12002,
    CLSID_CEventReplyCancelQuickJoinMatch = 12003,
    CLSID_CEventPushMatchingSuccess = 12004,
    --endregion
}
table.append(MessageDef, match_queueMessageDef)

--region CEventRequestQuickJoinMatch define
---@class CEventRequestQuickJoinMatch:CCallRequestEvent
_class("CEventRequestQuickJoinMatch",CCallRequestEvent)
CEventRequestQuickJoinMatch = CEventRequestQuickJoinMatch

 function CEventRequestQuickJoinMatch:Constructor()
    self.m_match_type = 0
    self.m_level_id = 0
end
---@private
CEventRequestQuickJoinMatch._proto = {
    [1] = {"m_match_type", "int"},
    [2] = {"m_level_id", "int"},
}
--endregion

--region CEventReplyQuickJoinMatch define
---@class CEventReplyQuickJoinMatch:CCallReplyEvent
_class("CEventReplyQuickJoinMatch",CCallReplyEvent)
CEventReplyQuickJoinMatch = CEventReplyQuickJoinMatch

 function CEventReplyQuickJoinMatch:Constructor()
    self.m_ret = 0
end
---@private
CEventReplyQuickJoinMatch._proto = {
    [1] = {"m_ret", "int"},
}
--endregion

--region CEventRequestCancelQuickJoinMatch define
---@class CEventRequestCancelQuickJoinMatch:CCallRequestEvent
_class("CEventRequestCancelQuickJoinMatch",CCallRequestEvent)
CEventRequestCancelQuickJoinMatch = CEventRequestCancelQuickJoinMatch

 function CEventRequestCancelQuickJoinMatch:Constructor()
end
---@private
CEventRequestCancelQuickJoinMatch._proto = {
}
--endregion

--region CEventReplyCancelQuickJoinMatch define
---@class CEventReplyCancelQuickJoinMatch:CCallReplyEvent
_class("CEventReplyCancelQuickJoinMatch",CCallReplyEvent)
CEventReplyCancelQuickJoinMatch = CEventReplyCancelQuickJoinMatch

 function CEventReplyCancelQuickJoinMatch:Constructor()
    self.m_ret = 0
end
---@private
CEventReplyCancelQuickJoinMatch._proto = {
    [1] = {"m_ret", "int"},
}
--endregion

--region CEventPushMatchingSuccess define
---@class CEventPushMatchingSuccess:CSvrPushEvent
_class("CEventPushMatchingSuccess",CSvrPushEvent)
CEventPushMatchingSuccess = CEventPushMatchingSuccess

 function CEventPushMatchingSuccess:Constructor()
    self.m_match_to_enter = GroupToken:New()
    self.m_vkey = 0
    self.m_server_ip = ""
    self.m_server_port = 0
end
---@private
CEventPushMatchingSuccess._proto = {
    [1] = {"m_match_to_enter", "GroupToken"},
    [2] = {"m_vkey", "int"},
    [3] = {"m_server_ip", "string"},
    [4] = {"m_server_port", "short"},
}
--endregion

--endregion dc define
