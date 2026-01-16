---@class LuaEventType : System.Enum
---@field value__ int
---@field LMT_PushEvent LuaEventType
---@field LMT_SvrPushEvent LuaEventType
---@field LMT_CliPushEvent LuaEventType
---@field LMT_CallRequestEvent LuaEventType
---@field LMT_CallReplyEvent LuaEventType
---@field LMT_MatchPushEvent LuaEventType
local m = {}
LuaEventType = m
return m