--region NetCallerDefault
---@class NetCallerDefault:NetCaller
---@field super NetCaller
_class("NetCallerDefault", NetCaller)
NetCallerDefault = NetCallerDefault

function NetCallerDefault:HandleConnectDone()
    NetCallerDefault.super.HandleConnectDone(self)
    self:GainAuth()
end

function NetCallerDefault:HandleConnectFailed(reason)
    NetCallerDefault.super.HandleConnectFailed(self, reason)
    self:ResetCall(CallResultType.ConnectFailed)
end

function NetCallerDefault:HandleConnectClosed(reason)
    NetCallerDefault.super.HandleConnectClosed(self, reason)
    self:LostAuth()
    self:ResetCall(CallResultType.ConnectClosed)
end

---@param msg NetMessage
function NetCallerDefault:HandleReceiveDone(msg)
    NetCallerDefault.super.HandleReceiveDone(self, msg)
end

---@param msg NetMessage
function NetCallerDefault:HandleCallBegin(msg)
    NetCallerDefault.super.HandleCallBegin(self, msg)
end

---@param msg NetMessage
function NetCallerDefault:HandleCallEnd(msg)
    NetCallerDefault.super.HandleCallEnd(self, msg)
end

---@param msg NetMessage
function NetCallerDefault:HandleCallTimelong(msg)
    NetCallerDefault.super.HandleCallTimelong(self, msg)
end

function NetCallerDefault:HandleCallTimeout()
    NetCallerDefault.super.HandleCallTimeout(self)
    self:ResetCall(CallResultType.CallTimeout)
    self:Disconnect(self:Key() .. " call timeout")
end
