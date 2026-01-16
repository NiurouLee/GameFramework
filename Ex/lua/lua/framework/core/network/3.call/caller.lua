--region ReplyInfo定义
---@class ReplyInfo:Object
_class("ReplyInfo", Object)

---@private
function ReplyInfo:Constructor()
    self.res = CallResultType.OtherErr
    self.msg = nil
end

---@public
function ReplyInfo:Succ()
    return self.res == CallResultType.Normal
end
--endregion

--region NetCaller定义
---@class NetCaller:Object
_class("NetCaller", Object)
local unpack = table.unpack

--region global control
function NetCaller.CreateMessage(clsid)
    return NetMessageFactory:GetInstance():CreateMessageWithId(clsid)
end
--endregion

--region base control
---@private
---@param host NetCallerLua
function NetCaller:Constructor(host)
    self.replies = {}
    self.pushHandlerMap = {}
    self.host = host
    self.host:Bind(self)
    self._serverTokenName = ""
    self.wait_tick4_report = 60 * 1000
end

---@public
---@return string
function NetCaller:Key()
    if self.host == nil then
        return
    end

    return self.host:GetKey()
end

---@private
function NetCaller:Dispose()
    if self.host == nil then
        return
    end
    self.host:Bind()
    self.host = nil
end

---@public
---@param reason string
function NetCaller:Reset(reason)
    self:ClearPushHandlers()
    if self.host == nil then
        return
    end
    self.host:Base_Reset(reason)
end

---@public
function NetCaller:Init()
    if self.host == nil then
        return
    end
    self.host:Base_Init()
end
--endregion

--region connect control
---@public
---@param desAddr NetAddrInfo
---@return bool
function NetCaller:SetLinkConn(desAddr)
    if self.host == nil then
        return nil
    end
    return self.host:SetLinkConn(desAddr)
end

---@public
---@param desAddr NetAddrInfo
---@param srcToken NetToken
---@return bool
function NetCaller:SetLink2Conn(desAddr, srcToken)
    if self.host == nil then
        return nil
    end
    self._serverTokenName = srcToken:TokenDesc()
    return self.host:SetLink2Conn(desAddr, srcToken)
end

---@public
---@param desToken NetToken
---@param proxyKey string
---@return bool
function NetCaller:SetPipe2Conn(desToken, proxyKey)
    if self.host == nil then
        return
    end
    proxyKey = proxyKey or "gateway"
    self._serverTokenName = desToken:TokenDesc()
    return self.host:SetPipe2Conn(desToken, proxyKey)
end

---@public
---@return string
function NetCaller:GetPipeProxyKey()
    if self.host == nil then
        return
    end
    return self.host:GetPipeProxyKey()
end

---@public
---@return string
function NetCaller:GetConnInfo()
    if self.host == nil then
        return nil
    end
    return self.host:GetConnInfo()
end

---链接
---@public
function NetCaller:Connect()
    if self.host == nil then
        return
    end
    self.host:Connect()
end

---断开链接
---@public
---@param reason string
function NetCaller:Disconnect(reason)
    if self.host == nil then
        return
    end
    self.host:Disconnect(reason)
end
---断开连接（底层传输连接）
---@public
---@param reason string
function NetCaller:DisconnectLink(reason)
    if self.host == nil then
        return
    end
    local callerProxy = GameGlobal.GameLogic().CallCenter:GetCallerLua(self:GetPipeProxyKey())
    if callerProxy then
        callerProxy:Disconnect(self:Key() .. " " .. reason)
    end
    self:Disconnect(reason)
end
---@return bool
function NetCaller:IsConnected()
    if self.host == nil then
        return
    end
    return self.host:IsConnected()
end

---@return uint
function NetCaller:LastSendElapsedTick()
    if self.host == nil then
        return 0
    end
    return self.host:LastSendElapsedTick()
end

---@return uint
function NetCaller:LastRecvElapsedTick()
    if self.host == nil then
        return 0
    end
    return self.host:LastRecvElapsedTick()
end
--endregion

--region session control
---会话是否拥有使用权限
---@return boolean
function NetCaller:HasAuth()
    if self.host == nil then
        return nil
    end
    return self.host:HasAuth()
end

---会话获得使用权限
function NetCaller:GainAuth()
    if self.host == nil then
        return nil
    end
    self.host:GainAuth()
end

---会话失去使用权限
function NetCaller:LostAuth()
    if self.host == nil then
        return
    end
    self.host:LostAuth()
end

function NetCaller:Alive()
    if self.host == nil then
        return
    end
    self.host:Alive()
end

---会话获得消息往返平均延时（ms）
---数据来自最近10s结果（alive->ack），默认alive频率1次/20s，使用此接口的场景（如局内）需要保证alive达到一定频率（如1次/s）
---@return float
function NetCaller:GetAvgDelay()
    if self.host == nil then
        return 0.0
    end
    return self.host:GetAvgDelay()
end
--endregion

--region push control
---@public
---@param msg CPushEvent 请求发送的协议
function NetCaller:Push(msg)
    if self.host == nil then
        return
    end
    Log.debug("[net] NetCaller: Send", msg._className, self._serverTokenName)
    self.host:Push(msg)
end

function NetCaller:HandlePush(msg)
    local type = msg:GetType()
    local handle = self.pushHandlerMap[type]
    if handle then
        handle.func(unpack(handle.args, 1, table.maxn(handle.args)), msg)
        Log.debug("[net] NetCaller: recv", msg._className, self._serverTokenName)
    else
        Log.warn("can not find pushHandle for " .. type._className .. " in caller " .. self:Key())
    end
end

function NetCaller:OnDispatch(eventType, clsid, result)
    local event = GetEnumKey("GameEventType", eventType)
    if not event then
        Log.fatal("unknown EventType", eventType)
        return
    end
    local id = GetEnumKey("MessageDef", clsid)
    if not id then
        Log.fatal("unknown MessageDef", clsid)
        return
    end
    if result then
        Log.debug("[net] NetCaller: " .. event .. " clsid " .. id .. " result " .. result, self._serverTokenName)
    else
        Log.debug("[net] NetCaller: " .. event .. " clsid " .. id, self._serverTokenName)
    end
    GameGlobal.EventDispatcher():Dispatch(eventType, clsid, result)
end

function NetCaller:RegisterPushHandler(type, cb, ...)
    if cb ~= nil then
        self.pushHandlerMap[type] = {func = cb, args = {...}}
    else
        self.pushHandlerMap[type] = nil
    end
end

function NetCaller:UnRegisterPushHandler(type)
    self.pushHandlerMap[type] = nil
end

function NetCaller:HasRegisterPushHandler(type)
    return self.pushHandlerMap[type] ~= nil
end

function NetCaller:ClearPushHandlers()
    table.clear(self.pushHandlerMap)
end
--endregion

--region call(request/reply) control
---协程方式向服务器发送消息
---@public
---@param TT  TT 协程函数标识
---@param request CCallRequestEvent 请求发送的协议
---@param sync bool true: 同步; false: 异步
---@param timeout uint 超时时间（ms）
---@return ReplyInfo 返回信息
function NetCaller:Call(TT, request, sync, timeout)
    if self.host == nil then
        return nil
    end
    Log.debug("[net] NetCaller: Send", request._className, self._serverTokenName)

    local id = GetCurTaskId()
    local reply = ReplyInfo:New()
    self.replies[id] = reply
    self.host:Call(request, id, sync, timeout)
    SUSPEND(TT)
    self.host:CallRecovered()
    self.replies[id] = nil
    return reply
end

---@return boolean
---@param id int
function NetCaller:RetryCall(id)
    if self.host == nil then
        return nil
    end
    return self.host:RetryCall(id)
end

function NetCaller:ResetCallTimeout()
    if self.host == nil then
        return nil
    end
    return self.host:ResetCallTimeout()
end

---@param reason CallResultType
function NetCaller:ResetCall(reason)
    if self.host == nil then
        return nil
    end
    self.host:ResetCall(reason)
end

---@private
---@param id int taskid
---@param resultType CallResultType 返回类型
---@param replyMessage CCallReplyEvent 返回信息
function NetCaller:HandleCallDone(id, resultType, replyMessage)
    if (replyMessage ~= nil) then
        Log.debug("[net] NetCaller: Recv ", replyMessage._className, self._serverTokenName)
    end
    ---@type ReplyInfo
    local reply = self.replies[id]
    if reply then
        reply.res = resultType
        reply.msg = replyMessage
    end
    if TaskManager:GetInstance():FindTask(id) == nil then
        Log.error("not find task ", id)
    elseif RESUME(TT, id) then
        if self.host == nil then
            return nil
        end
        self.host:CallRecovering()
    end
end

---@return boolean
function NetCaller:IsCallTimeout()
    if self.host == nil then
        return nil
    end
    return self.host:IsCallTimeout()
end

---@return boolean
function NetCaller:IsCallTimelong()
    if self.host == nil then
        return nil
    end
    return self.host:IsCallTimelong()
end

---是否有同步请求
---@return boolean
function NetCaller:HasSyncCall()
    if self.host == nil then
        return nil
    end
    return self.host:HasSyncCall()
end
--endregion

--region notifier
function NetCaller:HandleConnectDone()
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleConnectDone()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ConnectDone, self)
end

function NetCaller:HandleConnectFailed(reason)
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleConnectFailed(reason)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ConnectFail, self, reason)
end

function NetCaller:HandleConnectClosed(reason)
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleConnectClosed(reason)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ConnectClose, self, reason)
end

---@param msg NetMessage
function NetCaller:HandleReceiveDone(msg)
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleReceiveDone(msg)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ReceiveMessage, self, msg)
end

---@param msg NetMessage
function NetCaller:HandleCallBegin(msg)
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleCallBegin(msg)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CallBegin, self, msg)
end

---@param msg NetMessage
function NetCaller:HandleCallEnd(msg)
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleCallEnd(msg)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CallEnd, self, msg)
end

---@param msg NetMessage
function NetCaller:HandleCallTimelong(msg)
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleCallTimelong(msg)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CallTimelong, self, msg)
end

function NetCaller:HandleCallTimeout()
    if self.host == nil then
        return nil
    end
    self.host:Base_HandleCallTimeout()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CallTimeout, self)
end
--endregion

-- 最后绑定
---@private
---@param NetCaller NetCaller
NetCallerLua.BindStaticFunc(NetCaller)
--endregion

---@return BaseUtil.NetworkReportDataDc
function NetCaller:GetReportData()
    if self.host == nil then
        return nil
    end

    return self.host:GetReportData()
end

---@param cfg NetworkCfgInfo
function NetCaller:UpdateNetworkCfgInfo(cfg)
    if self.host == nil then
        return
    end

    Log.debug(
        "CEventSvrNetworkCfgPush:",
        tostring(cfg.max_wait_tick4_send),
        tostring(cfg.max_wait_tick4_recv),
        tostring(cfg.max_wait_tick4_connect),
        tostring(cfg.max_wait_tick4_calltimelong),
        tostring(cfg.resend_delay_cd),
        tostring(cfg.wait_tick4_report),
        cfg.network_cfg_ver
    )
    local infoDc = BaseUtil.NetworkCfgInfoDc:New()
    infoDc.network_cfg_ver = cfg.network_cfg_ver
    infoDc.max_wait_tick4_send = cfg.max_wait_tick4_send
    infoDc.max_wait_tick4_recv = cfg.max_wait_tick4_recv
    infoDc.max_wait_tick4_connect = cfg.max_wait_tick4_connect
    infoDc.max_wait_tick4_calltimelong = cfg.max_wait_tick4_calltimelong
    infoDc.resend_delay_cd = cfg.resend_delay_cd
    infoDc.wait_tick4_report = cfg.wait_tick4_report
    self.wait_tick4_report = cfg.wait_tick4_report
    self.host:UpdateNetworkCfgInfo(infoDc)
end
