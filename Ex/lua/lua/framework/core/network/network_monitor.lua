---弱网监控器
---@class NetworkMonitor:Object
_class("NetworkMonitor", Object)

function NetworkMonitor:Constructor()
    --Log.debug("NetworkMonitor:Constructor")
    -- 目标页缓存
    ---@type UIStateType
    self.page = UIStateType.Invalid
end

function NetworkMonitor:Dispose()
    Log.debug("NetworkMonitor:Dispose")
    self:Choose(false, GameGlobal.GameLogic():GetModule(LoginModule), "NetworkMonitor:Dispose", Log.traceback())
    -- 目标页缓存
    ---@type UIStateType
    self.page = UIStateType.Invalid
end

---进行选择
---@private
---@param choose bool true: 选择重试; false: 选择重置
---@param module LoginBaseModule 触发模块
---@param reason string 触发原因
---@return UIStateType 返回页
function NetworkMonitor:Choose(choose, module, reason)
    if module == nil then
        return self.page
    end
    GameGlobal.UAReportForceGuideEvent("ReConnect", {}, true)
    if choose then
        Log.debug(module:Key(), " choose retry, reason: ", reason)
        self:GoBack(UIStateType.Invalid)
    else
        Log.debug(module:Key(), " choose reset, reason: ", reason)
        -- 触发模块需要重置
        module.stateType = ModuleStateType.ResetDuring
    end
    ---@type LoginBaseModule
    local moduleMain = GameGlobal.GameLogic():GetModule(LoginModule)
    if moduleMain == nil then
    elseif moduleMain.stateType == ModuleStateType.ResetDuring then
        -- 主模块需要重置，进行全模块重置：子模块(s)重置+主模块重置
        Log.debug(moduleMain:Key(), " need reset, reset all", Log.traceback())
        GameGlobal.GameLogic():ForModules(
            function(m)
                if m and m:IsChildOf("LoginBaseModule") then
                    ---@type LoginBaseModule
                    local moduleOth = m
                    if moduleOth ~= moduleMain then
                        -- 通知子模块重置
                        moduleOth:Reset(reason)
                    end
                end
            end
        )
        -- 通知主模块重置
        moduleMain:Reset(reason)
    elseif moduleMain.stateType == ModuleStateType.RetryResetDuring then
        -- 主模块允许重试，进行全模块重试：主模块重试+子模块检查(s)
        Log.debug(moduleMain:Key(), " can retry, retry all", Log.traceback())
        moduleMain:Retry(reason)
        GameGlobal.GameLogic():ForModules(
            function(m)
                if m and m:IsChildOf("LoginBaseModule") then
                    ---@type LoginBaseModule
                    local moduleOth = m
                    if moduleOth == moduleMain then
                    elseif moduleOth.stateType == ModuleStateType.RetryResetDuring then
                        -- 子模块允许重试，通知重试
                        moduleOth:Retry(reason)
                    elseif moduleOth.stateType == ModuleStateType.ResetDuring then
                        -- 子模块需要重置，通知重置
                        moduleOth:Reset(reason)
                    end
                end
            end
        )
    else
        -- 主模块正常，进行子模块(s)检查
        Log.debug(moduleMain:Key(), " normal, retry all")
        GameGlobal.GameLogic():ForModules(
            function(m)
                if m and m:IsChildOf("LoginBaseModule") then
                    ---@type LoginBaseModule
                    local moduleOth = m
                    if moduleOth == moduleMain then
                    elseif moduleOth.stateType == ModuleStateType.RetryResetDuring then
                        -- 子模块允许重试，通知重试
                        moduleOth:Retry(reason)
                    elseif moduleOth.stateType == ModuleStateType.ResetDuring then
                        -- 子模块需要重置，通知重置
                        moduleOth:Reset(reason)
                    end
                end
            end
        )
    end
    ---@type UIStateType
    local page = self.page
    self.page = UIStateType.Invalid
    return page
end

---选择重试/重置（断网）
---@public
---@param module LoginBaseModule 触发模块
---@param reason string 触发原因
function NetworkMonitor:ConnectRetryReset(module, reason)
    if module == nil or module.stateType ~= ModuleStateType.Unset then
        return
    end
    Log.debug(module:Key(), " ConnectRetryReset, reason: ", reason, Log.traceback())
    -- 切换模块状态：选择重试/重置中
    module.stateType = ModuleStateType.RetryResetDuring
    -- 触发断网选择弹窗（抢占），等待选择
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.AskPopupReset,
        StringTable.Get("str_login_ask_login_connect_timeout_text"),
        function()
            -- 选择重试
            UIGlobalModule:GoBackCallback(
                function()
                    return self:Choose(true, module, reason)
                end
            )
        end,
        function()
            -- 选择重置
            UIGlobalModule:GoBackCallback(
                function()
                    return self:Choose(false, module, reason)
                end
            )
        end
    )

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ConnectReset, reason)
end

---选择重试/重置（同步调用超时）
---@public
---@param module LoginBaseModule 触发模块
---@param reason string 触发原因
function NetworkMonitor:CallRetryReset(module, reason)
    if module == nil or module.stateType ~= ModuleStateType.Unset then
        return
    end
    Log.debug(module:Key(), " CallRetryReset, reason: ", reason, Log.traceback())
    -- 切换模块状态：选择重试/重置中
    module.stateType = ModuleStateType.RetryResetDuring
    -- 触发同步调用超时选择弹窗（抢占），等待选择
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.AskPopupReset,
        StringTable.Get("str_login_ask_login_request_timeout_text"),
        function()
            -- 选择重试
            UIGlobalModule:GoBackCallback(
                function()
                    return self:Choose(true, module, reason)
                end
            )
        end,
        function()
            -- 选择重置
            UIGlobalModule:GoBackCallback(
                function()
                    return self:Choose(false, module, reason)
                end
            )
        end
    )
end

---通知重置（登出）
---@public
---@param module LoginBaseModule 触发模块
---@param reason string 触发原因
---@param popup bool 是否弹窗（默认true）
---@param errcode int 错误原因
function NetworkMonitor:LogoutReset(module, reason, popup, errcode, ...)
    UIGlobalModule:SetCSUICameraStatus(true)
    if module == nil or module.stateType == ModuleStateType.ResetDuring then
        return
    end
    Log.debug(module:Key(), " LogoutReset, reason: ", reason, Log.traceback())

    local retrys = true
    local tips = "str_login_ask_login_connect_timeout_text"
    if (errcode == MOBILE_LOGOUT_ERROR.MOBILE_LOGOUT_MULTI_LOGIN) then
        if IsPc() then
            -- body
            tips = "str_login_mobile_logout_multi_login_dmm"
        else
            tips = "str_login_mobile_logout_multi_login"
        end
        retrys = false
    elseif (errcode == MOBILE_LOGOUT_ERROR.MOBILE_LOGOUT_SERVER_KICK) then
        tips = "str_login_mobile_logout_server_kick"
        retrys = false
    elseif (errcode == MOBILE_LOGIN_ERROR.MOBILE_LOGIN_NO_PLAYER) then
        tips = "str_login_mobile_longtime_leave"
    elseif (errcode == MOBILE_LOGOUT_ERROR.MOBILE_LOGOUT_MATCH_ERROR) then
        tips = "str_login_match_error"
    elseif (errcode == MOBILE_LOGOUT_ERROR.MOBILE_LOGOUT_LOADDATA) then
        tips = "str_login_load_data_error"
        popup = true
    elseif (errcode == MOBILE_LOGOUT_ERROR.MOBILE_LOGOUT_PLAYER_LOGOUT) then
        popup = false
    end

    if IsPc() == false then 
            -- 切换模块状态：通知重置中
        module.stateType = ModuleStateType.ResetDuring
        -- 直接重置
        UIGlobalModule:GoBackCallback(
            function()
                return self:Choose(false, module, reason)
            end,
            ...
    )
    end

    if popup == nil and true or popup then
        -- 触发登出重置通知弹窗（抢占），等待确认
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.PopupReset,
            StringTable.Get(tips),
            function()
                if IsPc() then
                    --pc 直接退出游戏；
                    EngineGameHelper.QuitApp()
                else
                    if retrys == true then
                        -- 确认重试（复查）
                        UIGlobalModule:GoBackCallback(
                            function()
                                return self:Choose(true, GameGlobal.GameLogic():GetModule(LoginModule), reason)
                            end
                        )
                    end 
                end
               
            end
        )
    end
end

---选择返回页
---@public
---@param page UIStateType 目标页
function NetworkMonitor:GoBack(page)
    Log.debug("[net] NetworkMonitor:GoBack ", page, Log.traceback())
    self.page = page
end
