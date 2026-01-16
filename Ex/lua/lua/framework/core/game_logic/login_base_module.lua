---模块状态类型
---@class ModuleStateType
local ModuleStateType = {
    Unset = "Unset",
    RetryResetDuring = "RetryResetDuring",
    ResetDuring = "ResetDuring"
}
_enum("ModuleStateType", ModuleStateType)

---@class LoginBaseModule:GameModule
_class("LoginBaseModule", GameModule)
LoginBaseModule = LoginBaseModule

function LoginBaseModule:Constructor()
    self.svrId = 0 -- 登录服id
    self.isLogin = false -- 是否已登录
    self.curTaskId = 0 -- 当前任务Id
    self.retryTimer = nil -- 重试定时器
    self.retryDelayCD = 2 * 1000 -- 重试延迟CD（ms）
    self.retryTimeout = 8 * 1000 -- 重试超时时间（ms）
    self.startRetryTime = 0 -- 开始重试时间
    self.lastRetryTime = 0 -- 上次重试时间
    self.stateType = ModuleStateType.Unset -- 弱网触发状态
    self.fastCheckTimer = nil -- 快速检测定时器
    self.fastCheckTimelong = self.retryTimeout / 2 -- 快速检测过长时间
    self.fastCheckTimeout = self.retryTimeout -- 快速检测超时时间
    self.isBusy = false
end

function LoginBaseModule:Init()
    LoginBaseModule.super.Init(self)
    self.caller:RegisterPushHandler(CEventSvrPushLogout, self.HandleLogout, self)
    self.caller:RegisterPushHandler(CEventSvrPushNotification, self.HandleNotification, self)

    self:AttachEvent(GameEventType.ConnectDone, self.OnConnectDone)
    self:AttachEvent(GameEventType.ConnectFail, self.OnConnectFailed)
    self:AttachEvent(GameEventType.ConnectClose, self.OnConnectClosed)
    self:AttachEvent(GameEventType.CallBegin, self.OnCallBegin)
    self:AttachEvent(GameEventType.CallEnd, self.OnCallEnd)
    self:AttachEvent(GameEventType.CallTimelong, self.OnCallTimelong)
    self:AttachEvent(GameEventType.CallTimeout, self.OnCallTimeout)

    self.isLogin = false
end
---模块销毁
---@public
function LoginBaseModule:Dispose()
    self.isLogin = false
    self:StopFastCheck()
    self:CancelRetryTimer()

    self.caller:UnRegisterPushHandler(CEventSvrPushLogout)
    self.caller:UnRegisterPushHandler(CEventSvrPushNotification)
    LoginBaseModule.super.Dispose(self)
end

---模块更新
---@public
---@param curTime int
function LoginBaseModule:Update(curTime)
    LoginBaseModule.super.Update(self, curTime)
end

---模块关键字
---@public
---@return string
function LoginBaseModule:Key()
    return self.caller and self.caller:Key() or "<disposed module>"
end

---模块是否已登录
---@public
---@return boolean
function LoginBaseModule:IsLogin()
    return self.isLogin
end

---重置
---@public
---@param reason string
function LoginBaseModule:Reset(reason)
    Log.debug(self:Key(), " Reset, reason: ", reason, Log.traceback())
    self.stateType = ModuleStateType.Unset
    self.isLogin = false
    self:StopFastCheck()
    self:CancelRetryTimer()
    self:Logout(reason)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.LoginReset)
    self.caller:ResetCall(CallResultType.CallReset)
    self.caller:Disconnect(reason)
    GameGlobal.GameLogic():GoBack()
end

---重试
---@public
---@param reason string
function LoginBaseModule:Retry(reason)
    Log.debug(self:Key(), " Retry, reason: ", reason, Log.traceback())
    self.stateType = ModuleStateType.Unset
    local delayTime = self.lastRetryTime + self.retryDelayCD - GameGlobal:GetInstance():GetCurrentRealTime()
    if self.caller:IsCallTimeout() then
        -- 存在同步调用超时，则重置同步调用超时状态，立即重试
        self.caller:ResetCallTimeout()
        --self:StartRetryProc(40, reason)
        delayTime = 40
    elseif self.caller:HasSyncCall() then
        -- 存在同步调用（但未超时），则立即重试
        --self:StartRetryProc(40, reason)
        delayTime = 40
    elseif self.caller:IsConnected() then
        -- 存在连接，则立即重试
        --self:StartRetryProc(40, reason)
        delayTime = 40
    elseif delayTime <= 0 then
        -- 无需冷却，则立即重试
        --self:StartRetryProc(40, reason)
        delayTime = 40
    end
    -- 如果是立即重试，需要通过定时保证异步触发，避免因未Update使GetCurrentRealTime无法更新导致死循环
    self:StartRetryProc(delayTime, reason)
end
function LoginBaseModule:StartRetryProc(delayTime, reason)
    Log.debug(self:Key(), " Retry after: ", delayTime)
    self.retryTimer =
        GameGlobal.RealTimer():AddEvent(
        delayTime,
        self.RetryProc,
        self,
        "reason: " .. reason .. ", before: " .. tostring(delayTime)
    )
end
---取消定时重试
---@private
function LoginBaseModule:CancelRetryTimer()
    if self.retryTimer == nil then
        return
    end
    Log.debug(self:Key(), " CancelRetryTimer", Log.traceback())
    GameGlobal.RealTimer():CancelEvent(self.retryTimer)
    self.retryTimer = nil
end

---重试（立即执行）
---@private
---@param reason string
function LoginBaseModule:RetryProc(reason)
    Log.debug(self:Key(), " RetryProc, reason: ", reason, Log.traceback())
    self:CancelRetryTimer()
    if self.caller:HasAuth() then
        Log.warn(self:Key(), " has auth, need not retry")
        return
    end
    self.lastRetryTime = GameGlobal:GetInstance():GetCurrentRealTime()
    if self.curTaskId == 0 then
        -- 不存在登录/重试任务
        local timeout = self.retryTimeout -- 设置默认重试超时时间
        if self.fastCheckTimer then
            -- 快速检测需要重新计算超时时间
            local elapsed = self.caller:LastRecvElapsedTick()
            if elapsed >= self.fastCheckTimeout then
                -- 快速检测已超时如果还需要重试按保守时间重试一次
                timeout = self.fastCheckTimelong
            elseif self.fastCheckTimelong >= self.fastCheckTimeout - elapsed then
                -- 快速检测未超时但不足一次保守重试时间按剩余时间重试
                timeout = self.fastCheckTimeout - elapsed
            else
                -- 快速检测未超时且剩余时间充裕时按保守时间重试一次
                timeout = self.fastCheckTimelong
            end
        end
        GameGlobal.TaskManager():StartTask(self.RetryTask, self, timeout) -- 新建重试任务
    else
        -- 存在登录/重试任务
        GameGlobal.EventDispatcher():Dispatch(GameEventType.NetWorkRetryStart)
        self.caller:RetryCall(self.curTaskId) -- 再次重发请求缓存
    end
end

---重试（后台任务）
---@private
---@param timeout uint 超时时间（ms）
function LoginBaseModule:RetryTask(TT, timeout)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.NetWorkRetryStart)
    self.startRetryTime = self.lastRetryTime
    Log.debug(self:Key(), " RetryTask, timeout: ", timeout, Log.traceback())
    local res = self:Login(TT, self.svrId, true, timeout)
    self:CancelRetryTimer()
    if res:GetSucc() then -- 调用完成（回复正常）
        Log.debug(self:Key(), " retry done")
    elseif res:GetCallSucc() then -- 调用完成（回复错误）
        Log.fatal(self:Key(), " retry failed, msg: ", tostring(res:GetResult()))
    elseif self:IsLogin() then -- 调用超时（网络异常但已登录）
        Log.fatal(self:Key(), " retry failed, call: ", tostring(res:GetCallErr()))
        GameGlobal.GameLogic().NetworkMonitor:CallRetryReset(self, "call login timeout")
    else -- 调用超时（无网且未登录）
        self.caller:ResetCall(CallResultType.CallTimeout)
    end
    self.startRetryTime = 0
    GameGlobal.EventDispatcher():Dispatch(GameEventType.NetWorkRetryEnd)
end

---登录（用户任务接口）
---@public
---@param TT TaskToken 协程函数标识
---@param svrId int 登录服id
---@param silent bool 是否静默登录
---@param timeout uint 超时时间（ms）
---@return AsyncRequestRes 异步请求结果
function LoginBaseModule:Login(TT, svrId, silent, timeout)
    return AsyncRequestRes:New()
end

---登出（本端推送）
---@private
---@param reason string
function LoginBaseModule:Logout(reason)
    if not self.caller:IsConnected() then
        return
    end
    Log.debug(self:Key(), " Logout, reason: ", reason, Log.traceback())
    local msg = NetMessageFactory:GetInstance():CreateMessage(CEventCliPushLogout)
    self:Push(msg)
end

---处理登出（对端推送）
---@private
---@param msg CEventSvrPushLogout
function LoginBaseModule:HandleLogout(msg)
    Log.debug(self:Key(), " HandleLogout, err: ", tostring(msg.m_err), " reason: ", msg.m_reason, Log.traceback())

    GameGlobal.GameLogic():BackToLogin(
        false,
        self,
        "server logout, err: " .. tostring(msg.m_err) .. " reason: " .. msg.m_reason,
        self:IsLogin(),
        msg.m_err,
        Log.traceback()
    )
end

---处理服务器推送消息
---@private
---@param msg CEventSvrPushNotification
function LoginBaseModule:HandleNotification(msg)
    Log.debug(
        self:Key(),
        " HandleNotification, notification_type: ",
        tostring(msg.m_notification_type),
        Log.traceback()
    )

    GameGlobal.EventDispatcher():Dispatch(GameEventType.PushNotification, msg.m_notification_type, msg.m_hot_update_res_ver)
end

---开始断网快速检测
---@protected
---@param interval uint 检测间隔时间（ms，<反馈过长时间）
---@param timelong uint 反馈过长时间（ms，<=反馈超时时间，超时前反馈过长会自动重建基础连接）
---@param timeout uint 反馈超时时间（ms，<=宿主后台检测无包超时时间：60s）
function LoginBaseModule:StartFastCheck(interval, timelong, timeout)
    if not self.caller:HasAuth() then
        return
    end
    self:StopFastCheck()
    self.fastCheckTimelong = timelong
    self.fastCheckTimeout = timeout
    local lastSendElapsedTick = self.caller:LastSendElapsedTick()
    local lastRecvElapsedTick = self.caller:LastRecvElapsedTick()
    Log.debug(
        self:Key(),
        " StartFastCheck, send elapsed: ",
        lastSendElapsedTick,
        ", recv elapsed: ",
        lastRecvElapsedTick,
        ", interval: ",
        interval,
        ", timelong: ",
        timelong,
        ", timeout: ",
        timeout,
        Log.traceback()
    )
    if lastRecvElapsedTick >= timelong and lastSendElapsedTick < timelong then -- 距上次接收时间过长 且 发送没受阻塞（防止没有及时检测导致反馈过长，比如同步加载导致延迟触发定时器）
        -- 断开基础连接（超时一般因基础连接异常导致，后续连接断开回调会通知处理）
        self.caller:DisconnectLink("fast check timelong")
        return
    end
    if lastSendElapsedTick >= interval then -- 距上次发送时间够长
        -- 继续检测
        self.caller:Alive()
    end
    -- 重置定时器（当前时间+间隔时间）
    self.fastCheckTimer =
        GameGlobal.RealTimer():AddEvent(interval, self.StartFastCheck, self, interval, timelong, timeout)
end

---停止断网快速检测
---@protected
function LoginBaseModule:StopFastCheck()
    if self.fastCheckTimer == nil then
        return
    end
    --Log.debug(self:Key(), " StopFastCheck")
    GameGlobal.RealTimer():CancelEvent(self.fastCheckTimer)
    self.fastCheckTimer = nil
    self.fastCheckTimelong = self.retryTimeout / 2
    self.fastCheckTimeout = self.retryTimeout
end

---通知快速检测失败
---@protected
function LoginBaseModule:OnFastCheckFailed(reason)
    Log.debug(self:Key(), " OnFastCheckFailed, reason: ", reason, Log.traceback())
    if self.caller:LastRecvElapsedTick() < self.fastCheckTimeout then
        -- 允许重试，则按自定义策略自动重试（弱网自动重连）
        self:Retry(reason)
    else
        -- 不符合上述条件，则通知用户选择连接重试/重置
        GameGlobal.GameLogic().NetworkMonitor:ConnectRetryReset(self, reason)
    end
end

---通知连接完成
---@protected
function LoginBaseModule:OnConnectDone(caller)
    if caller ~= self.caller then
        return
    end
    self:Retry("connect done") -- 建立基础连接成功（立即重试登录建立逻辑连接）
end

---通知连接失败
---@protected
function LoginBaseModule:OnConnectFailed(caller, reason)
    if caller ~= self.caller then
        return
    end
    if self.caller:IsCallTimeout() then
        -- 存在同步调用超时，则相关回调会通知处理
    elseif not self:IsLogin() then
        -- 未登录，则自动重置所有调用（因建立连接失败）
        self.caller:ResetCall(CallResultType.ConnectFailed)
    elseif self.fastCheckTimer then
        -- 启用快速检测，则按自定义失败策略处理
        self:OnFastCheckFailed(reason)
    elseif self.caller:HasSyncCall() then
        -- 存在同步调用（用户主动调用），则按自定义策略重试（直至成功或调用超时）
        self:Retry(reason)
    elseif
        self.startRetryTime == 0 or
            GameGlobal:GetInstance():GetCurrentRealTime() - self.startRetryTime < self.retryTimeout
     then
        -- 允许重试，则按自定义策略自动重试（弱网自动重连）
        self:Retry(reason)
    else
        -- 不符合上述条件，则通知用户选择连接重试/重置
        GameGlobal.GameLogic().NetworkMonitor:ConnectRetryReset(self, reason)
    end
end

---通知连接断开
---@protected
function LoginBaseModule:OnConnectClosed(caller, reason)
    if caller ~= self.caller then
        return
    end
    self.caller:LostAuth() -- 标识连接已失信
    if self.caller:IsCallTimeout() then
        -- 存在同步调用超时，则相关回调会通知处理
    elseif not self:IsLogin() then
        -- 未登录，则自动重置所有调用（因既有连接断开）
        self.caller:ResetCall(CallResultType.ConnectClosed)
    elseif self.fastCheckTimer then
        -- 启用快速检测，则按自定义失败策略处理
        self:OnFastCheckFailed(reason)
    elseif self.caller:HasSyncCall() then
        -- 存在同步调用（用户主动调用），则按自定义策略重试（直至成功或调用超时）
        self:Retry(reason)
    elseif
        self.startRetryTime == 0 or
            GameGlobal:GetInstance():GetCurrentRealTime() - self.startRetryTime < self.retryTimeout
     then
        -- 允许重试，则按自定义策略自动重试（弱网自动重连）
        self:Retry(reason)
    else
        -- 不符合上述条件，则通知用户选择连接重试/重置
        GameGlobal.GameLogic().NetworkMonitor:ConnectRetryReset(self, reason)
    end
end

---通知同步调用开始
---@protected
function LoginBaseModule:OnCallBegin(caller, msg)
    if caller ~= self.caller then
        return
    end
end

---通知同步调用完成
---@protected
function LoginBaseModule:OnCallEnd(caller, msg)
    if caller ~= self.caller then
        return
    end
    if (self.isBusy) then
        GameGlobal.UIStateManager():ShowBusy(false)
        self.isBusy = false
    end
end

---通知同步调用繁忙（>500ms）
---@protected
function LoginBaseModule:OnCallTimelong(caller, msg)
    if caller ~= self.caller then
        return
    end
    if (self.isBusy == false) then
        self.isBusy = true
        GameGlobal.UIStateManager():ShowBusy(true)
    end
end

---通知同步调用超时
---@protected
function LoginBaseModule:OnCallTimeout(caller)
    if caller ~= self.caller then
        return
    end
    self.isBusy = false
    GameGlobal.UIStateManager():ShowBusy(false)
    self.caller:DisconnectLink("call timeout") -- 断开基础连接（超时一般因基础连接异常导致，后续可重建所有相关逻辑连接）
    if not self:IsLogin() then
        -- 未登录，则无需再恢复调用（因既有同步调用超时）
        self.caller:ResetCall(CallResultType.CallTimeout)
    else
        -- 不符合上述条件，则通知用户选择调用重试/重置
        GameGlobal.GameLogic().NetworkMonitor:CallRetryReset(self, "call timeout")
    end
end
