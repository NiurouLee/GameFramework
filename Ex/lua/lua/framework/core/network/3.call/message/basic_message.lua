--region LuaAppEvent定义
---@class LuaAppEvent:Object
---@field clsid integer
_class("LuaAppEvent", Object)
LuaAppEvent = LuaAppEvent
LuaEventType = LuaEventType
---@return LuaEventType
function LuaAppEvent:EventType()
end
---@return bool
function LuaAppEvent:Encrypt()
end
---@return bool
function LuaAppEvent:Reliable()
end
--endregion

--region CPushEvent定义
---@class CPushEvent:LuaAppEvent
_class("CPushEvent", LuaAppEvent)
CPushEvent = CPushEvent
---@return LuaEventType
function CPushEvent:EventType()
    return LuaEventType.LMT_PushEvent
end
---@return bool
function CPushEvent:Encrypt()
    return true
end
---@return bool
function CPushEvent:Reliable()
    return true
end
--endregion

--region CCallEvent定义
---@class CCallEvent:LuaAppEvent
_class("CCallEvent", LuaAppEvent)
CCallEvent = CCallEvent
---@return bool
function CCallEvent:Encrypt()
    return true
end
---@return bool
function CCallEvent:Reliable()
    return true
end
function CCallEvent:Constructor()
    self.flag = 0
end
--endregion

--region CCallRequestEvent定义
---@class CCallRequestEvent:CCallEvent
_class("CCallRequestEvent", CCallEvent)
CCallRequestEvent = CCallRequestEvent
---@return LuaEventType
function CCallRequestEvent:EventType()
    return LuaEventType.LMT_CallRequestEvent
end
--endregion

--region CCallReplyEvent定义
---@class CCallReplyEvent:CCallEvent
_class("CCallReplyEvent", CCallEvent)
CCallReplyEvent = CCallReplyEvent
---@return LuaEventType
function CCallReplyEvent:EventType()
    return LuaEventType.LMT_CallReplyEvent
end
--endregion

--region CSvrPushEvent定义
---@class CSvrPushEvent:CPushEvent
_class("CSvrPushEvent", CPushEvent)
CSvrPushEvent = CSvrPushEvent
---@return LuaEventType
function CSvrPushEvent:EventType()
    return LuaEventType.LMT_SvrPushEvent
end
---@return bool
function CSvrPushEvent:Reliable()
    return true
end
--endregion

--region CCliPushEvent定义
---@class CCliPushEvent:CPushEvent
_class("CCliPushEvent", CPushEvent)
CCliPushEvent = CCliPushEvent
---@return LuaEventType
function CCliPushEvent:EventType()
    return LuaEventType.LMT_CliPushEvent
end
---@return bool
function CCliPushEvent:Reliable()
    return true
end
--endregion

--region CMatchPushEvent定义
---@class CMatchPushEvent:CPushEvent
_class("CMatchPushEvent", CPushEvent)
CMatchPushEvent = CMatchPushEvent
---@return LuaEventType
function CMatchPushEvent:EventType()
    return LuaEventType.LMT_MatchPushEvent
end
---@return bool
function CMatchPushEvent:Encrypt()
    return true
end
---@return bool
function CMatchPushEvent:Reliable()
    return true
end
--endregion
