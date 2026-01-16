---@class LoginRes
require "dns_process"
_enum(
    "LoginRes",
    {
        Success = 0,
        GetServerFailed = 1,
        MobileLoginFailed = 2,
        ChooseRoleFailed = 3,
        CreateRoleFailed = 4,
        ServerMaintaining = 5
    }
)
---@class LoginProcess:LoginProcess
_class("LoginProcess", Object)
LoginProcess = LoginProcess

local dns = nil

function LoginProcess:LoginTask(TT, openID, address)
    if dns == nil then
        dns = DnsProcess:New()
    end

    local bulletin = GameGlobal.GetModule(BulletinModule)
    local getServerSucceed = false
    local res = nil
    for k, vt in ipairs(address) do
        local ips = dns:AnalysisIP(TT, vt.ip)

        if ips == nil or ips == "" then
            Log.debug("[login] ", "AnalysisIP is empty ,use ", vt.ip)
            ips = vt.ip
        end
        Log.debug("[login] ", "bulletin ip ", ips, " port ", vt.port, " openid ", openID)
        res = self:GetServerInfo(TT, ips, vt.port)
        if res == LoginRes.Success then
            getServerSucceed = true
            break
        elseif res == LoginRes.ServerMaintaining then
            break
        end
    end
    if not getServerSucceed then
        return res
    end
    --bulletin.current_gateway.ip = serverIP
    self:ConnectGatewayAndGame(TT, bulletin.current_gateway, bulletin.current_server)
    return self:LoginGame(TT)
end
function LoginProcess:_ToastErrorMessage(stMsgID, nErrorCode)
    local nLoginStep = Enum_Login_Step.E_Login_Step_RequestGetDefaultServerInfo
    ToastManager.ShowToast(
        StringTable.Get(stMsgID) .. "[" .. tostring(nLoginStep) .. ", " .. tostring(nErrorCode) .. "]"
    )
end
function LoginProcess:GetServerInfo(TT, ip, port)
    -- 先连接bulletin
    GameGlobal.GameLogic().CallCenter:GetCallerLua("bulletin"):SetLinkConn(NetAddrInfo.New2(ip, port))
    ---@type BulletinModule
    local bulletin = GameGlobal.GetModule(BulletinModule)
    --编辑器里连接gm
    if EDITOR then
        local gmproxy = GameGlobal.GetModule(GMProxyModule)
        gmproxy:Connect(ip, 31000)
    end
    -- 拉默认服务器信息
    local bulletin_res = bulletin:GetDefaultServerInfo(TT)
    if not bulletin_res:GetSucc() then
        YIELD(TT)
        bulletin.caller:Disconnect("normal")
        local nDefaultServerResult = bulletin_res:GetResult()
        if nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_SUCCEED then ---成功
        elseif nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_NO_GATEWAY then ---获取gateway失败
            self:_ToastErrorMessage("str_login_server_no_gateway", nDefaultServerResult)
        elseif nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_NO_LOGIN_STATUS then ---获得login status失败
            self:_ToastErrorMessage("str_login_need_retry", nDefaultServerResult)
        elseif (nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_ERR_BY_LOGIN_STATUS) then ---通过login status获取server失败
            self:_ToastErrorMessage("str_login_need_retry", nDefaultServerResult)
        elseif (nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_ERR_BY_BALANCE) then ---获取均衡负载server失败
            self:_ToastErrorMessage("str_login_need_retry", nDefaultServerResult)
        elseif (nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_ERR_BY_AVAIL) then ---获取可用server失败
            self:_ToastErrorMessage("str_login_need_retry", nDefaultServerResult)
        elseif (nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_ERR_BY_RECOMMEND) then ---获得推荐server失败
            self:_ToastErrorMessage("str_login_need_retry", nDefaultServerResult)
        elseif nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_ERR_MainTain then ---服务器维护中
            Log.error("[login] ", "server is maintain")
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.Ok,
                StringTable.Get("str_login_maintain_white_title"),
                StringTable.Get("str_login_maintain")
            )

            Log.error(
                "[login] ",
                "Get default server failed str_login_getserverinfo_error",
                StringTable.Get("str_login_getserverinfo_error")
            )
            --ToastManager.ShowToast(StringTable.Get("str_login_getserverinfo_error"))
            return LoginRes.ServerMaintaining
        elseif nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_ERR_BY_ZONE_FERQ then ---当前时间段获取server的客户端太多了
            self:_ToastErrorMessage("str_login_getbalance_game_error", nDefaultServerResult)
        elseif nDefaultServerResult == GET_DEFAULT_SERVER_CODE.GET_DEFAULT_SERVER_ERR_BY_ZONE_FULL then ---大区已满
            self:_ToastErrorMessage("str_login_getbalance_game_error", nDefaultServerResult)
        else
            self:_ToastErrorMessage("str_login_getserverinfo_error", nDefaultServerResult)
        end
        Log.error("[login] BulletinModule:GetDefaultServerInfo result ", nDefaultServerResult)
        return LoginRes.GetServerFailed
    end

    Log.debug(
        "[login] Current gateway server address ",
        bulletin.current_gateway.ip,
        ":",
        bulletin.current_gateway.port
    )

    -- 和Bulletin断开
    bulletin.caller:Disconnect("normal")

    return LoginRes.Success
end
function LoginProcess:ConnectGatewayAndGame(TT, gatewayInfo, gameServer)
    -- 再连接gateway

    gatewayInfo.ip = dns:AnalysisIP(TT, gatewayInfo.ip)

    Log.debug("[login] ConnectGatewayAndGame ", gatewayInfo.ip, ":", gatewayInfo.port, " game ", gameServer.id)
    local bulletin = GameGlobal.GetModule(BulletinModule)
    local token = bulletin.token
    GameGlobal.GameLogic().CallCenter:GetCallerLua("gateway"):SetLink2Conn(
        NetAddrInfo.New2(gatewayInfo.ip, gatewayInfo.port),
        token
    )
    -- 再连接game
    GameGlobal.GameLogic().CallCenter:GetCallerLua("game"):SetPipe2Conn(
        NetToken:New(NetTokenType.TOKEN_GAME, "GM", gameServer.id),
        "gateway"
    )
end
function LoginProcess:LoginGame(TT)
    local bulletin = GameGlobal.GetModule(BulletinModule)
    local login_module = GameGlobal.GetModule(LoginModule)
    local login_res = login_module:Login(TT, bulletin.current_server.id, false)
    if login_res:GetSucc() then
        local lm = GameGlobal.GetModule(LoginModule)
        lm:EnterGameSucc()

        login_res = login_module:ChooseRole(TT, 0)
        if login_res.m_result == ROLE_RESULT_CODE.ROLE_ERROR_NOT_ROLE then
            return self:CreateRoleTask(TT)
        elseif login_res:GetSucc() then
            Log.debug("[login] ", "角色登录成功")
            return LoginRes.Success
        else
            Log.debug("[login] ", "ChooseRole error")
            self:ShowLoginFailedMsg(-1)
            return LoginRes.MobileLoginFailed
        end
    else
        if login_res.m_result ~= MOBILE_LOGIN_ERROR.MOBILE_LOGIN_BAN then
            Log.fatal("[login] ", "LoginTask err:", login_res.m_result)
            self:ShowLoginFailedMsg(login_res.m_result)
        end

        --ToastManager.ShowToast("LoginTask err:" .. login_res.m_result)
        return LoginRes.MobileLoginFailed
    end
end
function LoginProcess:ShowLoginFailedMsg(res)
    local nLoginStep = Enum_Login_Step.E_Login_Step_RequestChooseRole
    local errorstr = "[" .. tostring(nLoginStep) .. ", " .. tostring(res) .. "]"

    if (res == MOBILE_LOGIN_ERROR.MOBILE_LOGIN_RETRY) then
        ToastManager.ShowToast(StringTable.Get("str_login_need_retry") .. errorstr)
    elseif (res == MOBILE_LOGIN_ERROR.MOBILE_LOGIN_MSDK_ERROR) then
        if IsPc() then
            ToastManager.ShowToast(StringTable.Get("str_login_code_exit") .. errorstr)       
        else
            ToastManager.ShowToast(StringTable.Get("str_login_code_accredit") .. errorstr)        
        end
    elseif res == -1 then
        ToastManager.ShowToast(StringTable.Get("str_login_load_data_error") .. errorstr)
    else
        ToastManager.ShowToast(StringTable.Get("str_login_maintain") .. errorstr)
    end
end
function LoginProcess:CreateRoleTask(TT)
    local login_module = GameGlobal.GetModule(LoginModule)
    local openid = GameGlobal.GameLogic():GetOpenId()
    local sex = 0

    local create_role_res = login_module:RoleCreate(TT, openid, sex)
    if create_role_res:GetSucc() then
        Log.debug("[login] ", "Create Role success:", create_role_res.m_result)
        local chooseRole = login_module:ChooseRole(TT, create_role_res.pstid)
        if chooseRole:GetSucc() then
            Log.debug("[login] ", "角色登录成功")
            return LoginRes.Success
        else
            Log.fatal("[login] ", "LoginTask err:", chooseRole.m_result)
            self:ShowLoginFailedMsg(chooseRole.m_result)
            return LoginRes.ChooseRoleFailed
        end
    else
        Log.fatal("[login] ", "Create Role err:", create_role_res.m_result)
        local nLoginStep = Enum_Login_Step.E_Login_Step_RequestCreateRole
        local errorstr = "[" .. tostring(nLoginStep) .. ", " .. tostring(res) .. "]"
        ToastManager.ShowToast(StringTable.Get("str_login_load_data_error") .. errorstr)
        return LoginRes.CreateRoleFailed
    end
end

--临时检测邮件白名单
function LoginProcess:TempCheckMailTask(TT, address, mailAddr)
    if dns == nil then
        dns = DnsProcess:New()
    end

    local bulletin = GameGlobal.GetModule(BulletinModule)
    local res = nil
    local ret = nil
    for k, vt in ipairs(address) do
        local ips = dns:AnalysisIP(TT, vt.ip)

        if ips == nil or ips == "" then
            Log.debug("[TempCheckMailTask] ", "AnalysisIP is empty ,use ", vt.ip)
            ips = vt.ip
        end
        Log.debug("[TempCheckMailTask] ", "bulletin ip ", ips, " port ", vt.port)

        -- 先连接bulletin
        GameGlobal.GameLogic().CallCenter:GetCallerLua("bulletin"):SetLinkConn(NetAddrInfo.New2(ips, vt.port))
        ---@type BulletinModule
        -- 拉默认服务器信息
        res, ret = bulletin:RequestTempMailMaintain(TT, mailAddr)
        if res:GetSucc() then
            break
        end
    end

    return res, ret
end
