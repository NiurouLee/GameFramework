--region NetMessageFactory定义
---@class NetMessageFactory:Singleton
------@field GetInstance NetMessageFactory
_class("NetMessageFactory", Singleton)
NetMessageFactory = NetMessageFactory

---@private
function NetMessageFactory:Constructor()
    self.msgObjs = {}
end

---注册
---@public
---@param msg LuaAppEvent
function NetMessageFactory:RegisterMessage(msg)
    if self.msgObjs[msg.clsid] then
        Log.fatal("NetMessageFactory:RegisterMessage duplicated clsid class ", msg._className, " clsid ",msg.clsid)
    end
    self.msgObjs[msg.clsid] = msg
end

function NetMessageFactory:RegisterEvents()
    Log.debug("RegisterEvents")
    for k, v in pairs(self.msgObjs) do
        NetCallerLua.RegisterEvents(v.clsid, v:EventType(), v:Encrypt(), v:Reliable(), v._className)
    end
end

---创建消息
---@public
---@param clsid int 消息id
function NetMessageFactory:CreateMessageWithId(clsid)
    local msg = self.msgObjs[clsid]
    if msg then
        return msg:New()
    else
        Log.fatal("unknown message with clsid: ", clsid)
    end
end

---创建消息
---@public
---@generic T : LuaAppEvent
---@param type T 协议类型
---@return T 协议
function NetMessageFactory:CreateMessage(type, ...)
    return type:New()
end
--endregion
