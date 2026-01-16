---@class GameLogic : Object
_class("GameLogic", Object)
GameLogic = GameLogic

function GameLogic:Constructor()
    self.CallCenter = NetCallCenter.GetInstance()
    self.ClientInfo = MobileClientInfo:New()
    ---@type MSDKAuthInfo
    self.msdkAuthorityInfo = MSDKAuthInfo:New()
    --弱网管理
    ---@type NetworkMonitor
    self.NetworkMonitor = NetworkMonitor:New()

    ---@field callback 使用此回调前先确认别处是否也在使用哦
    self.onLoadSceneBegin = nil
    self.onLoadSceneEnd = nil
    ---@type table<string, GameModule>
    self.modules = {}

    self.ZoneId = 0
    self.last_time = 0
end
---@private
function GameLogic:Dispose()
    self.NetworkMonitor:Dispose()
    self:Reset("GameLogic:Dispose")
    self.NetworkMonitor = nil
    self.CallCenter = nil
end

---退出登录
---@param bAutoAuthority bool
function GameLogic:BackToLogin(bAutoAuthority, moudle, reason, popup, errcode, ...)
    if bAutoAuthority == true then
        LoginLuaHelper.CancelChannel()
    end
    TSSSDKProxy:GetInstance():LogOff()
    self.NetworkMonitor:LogoutReset(self:GetModule(moudle), reason, popup, errcode, ...) 
end

---新的登出
function GameLogic:GoBack()
    if HelperProxy:GetInstance():GetConfig("TMPLoginSwitch", "false") == "true" then
        GameGlobal.GameLogic().NetworkMonitor:GoBack(UIStateType.LoginEmpty)
    else
        GameGlobal.GameLogic().NetworkMonitor:GoBack(UIStateType.Login) -- 默认回到大厅页        
    end
end


---重置
---@param reason string
function GameLogic:Reset(reason)
    Log.debug("GameLogic:Reset")
    if not self.inited then
        return
    end
    self.inited = false

    --释放GameModule、UIModule
    self:ClearAllModule()

    --重置所有netcaller，清空消息handle
    self.CallCenter:Reset(reason)
end
--临时修改@李学森 ui用来判断是否退出了
function GameLogic:Inited()
    return self.inited
end
---初始化
---@param reason string
function GameLogic:Init(reason)
    reason = reason or "GameLogic:Init"
    self:Reset(reason)
    self.CallCenter:Init()
    NetMessageFactory:GetInstance():RegisterEvents()

    --重新注册、初始化Caller
    NetCallerRegister:RegCallers(self.CallCenter)
    self.CallCenter:InitCallers()

    --重新注册、初始化GameModule
    GameModuleRegister:RegisterModules(self)
    self:InitAllModule()

    --注册配置下发处理函数
    if APPVERNETSTAT then
        self.CallCenter:GetCallerLua("game"):RegisterPushHandler(CEventSvrNetworkCfgPush, self.HandleNetworkCfg, self)
    end

    --初始化UIModule
    UIModuleRegister:RegisterUIModules(self)
    Log.debug("GameLogic:Init")
    self.inited = true
end

---@param curTick int
function GameLogic:Update(curTick)
    if not self.inited then
        return
    end

    self:UpdateAllModule(curTick)

    if APPVERNETSTAT then
        self:NetStat(curTick)
    end
end

local SCENE_LOADER_SUFFIX = ".unity"
function GameLogic:LoadScene(TT, sceneName)
    --Log.debug("LoadScene ",sceneName,Log.traceback())
    if self.onLoadSceneBegin then
        self.onLoadSceneBegin(sceneName)
    end

    Log.sys("GameLogic:LoadScene start: ", sceneName)
    local scene = ResourceManager:GetInstance():AsyncLoadAsset(TT, sceneName .. SCENE_LOADER_SUFFIX, LoadType.Unity)
    if not scene then 
        if Log.loglevel < ELogLevel.None then 
            Log.exception("找不到场景资源：",sceneName)
        end
    end

    if self.scene then
        self.scene:Dispose()
    end
    self.scene = scene
    if self.onLoadSceneEnd then
        self.onLoadSceneEnd(sceneName)
    end
    Log.sys("GameLogic:LoadScene end: ", sceneName)
    return scene
end

---@param type GameModule
---@param caller NetCaller
function GameLogic:AddModule(type, caller)
    local module = type:New()
    module.logic = self
    module.caller = caller
    self.modules[type._className] = module
    --Log.notice("GameLogic:AddModule ", type._className)
end

---@param gameModuleType GameModule
---@param uiModuleType UIModule
function GameLogic:AddUIModule(gameModuleType, uiModuleType)
    local uiModule = uiModuleType:New()
    local gameModule = self:GetModule(gameModuleType)
    if gameModule then
        gameModule["uiModule"] = uiModule
    else
        Log.fatal("GameLogic:AddUIModule Fail, no game module ", gameModuleType._className, Log.traceback())
    end
    -- self.uiModules[type._className] = ui_module
end

---@generic T : GameModule
---@param type T 模块类型
---@return T 模块
function GameLogic:GetModule(type)
    return self.modules[type._className]
end
function GameLogic:ForModules(cb)
    for _, v in pairs(self.modules) do
        if v then
            cb(v)
        end
    end
end
function GameLogic:ClearAllModule()
    for _, v in pairs(self.modules) do
        if v then
            --Log.debug(v._className)
            v:DetachAllEvents()
            v:Dispose()

            if v.uiModule then
                v.uiModule:DetachAllEvents()
                v.uiModule:Dispose()
            end
        end
    end
    table.clear(self.modules)
end

function GameLogic:InitAllModule()
    for _, v in pairs(self.modules) do
        v:Init()
    end
end

---@param curTick int
function GameLogic:UpdateAllModule(curTick)
    for _, v in pairs(self.modules) do
        v:Update(curTick)
    end
end

function GameLogic:GetOpenId()
    return self.msdkAuthorityInfo.open_id
end
function GameLogic:GetZoneID()
    return self.ZoneId
end

function GameLogic:SetZoneID(zId)
    self.ZoneId = zId
end

---处理网络配置更新push
---@private
---@param msg CEventSvrNetworkCfgPush
function GameLogic:HandleNetworkCfg(msg)
    self.CallCenter:GetCallerLua("bulletin"):UpdateNetworkCfgInfo(msg.m_net_cfg_info)
end

---@param curTick int
function GameLogic:NetStat(curTick)
    if self.CallCenter:GetCallerLua("bulletin") == nil then
        return
    end
    
    if curTick - self.last_time < self.CallCenter:GetCallerLua("bulletin").wait_tick4_report then
        return
    end

    Log.debug("wait_tick4_report:", tostring(self.CallCenter:GetCallerLua("bulletin").wait_tick4_report))
    self.last_time = curTick
    local reportData = self.CallCenter:GetCallerLua("bulletin"):GetReportData()
    if reportData == nil then
        Log.error("reportData == nil")
        return
    end
    local avgDelay = reportData.avgDelay
    local maxDelay = reportData.maxDelay
    local minDelay = reportData.minDelay
    local totalSize = reportData.totalSize / 1024
    local sendSize = reportData.sendSize / 1024
    local recvSize = reportData.recvSize / 1024
    local totalCount = reportData.totalCount
    local sendCount = reportData.sendCount
    local recvCount = reportData.recvCount
    local resendCount = reportData.resendCount
    local maxResendWaitTick = reportData.maxResendWaitTick
    local repeatCount = reportData.repeatCount
    local lostCount = reportData.lostCount
    local rangeCount = reportData.rangeCount
    local conflictCount = reportData.conflictCount
    local connFailedCount = reportData.connFailedCount
    local rto = reportData.aliveRto
    local connectTimeoutCount = reportData.connectTimeoutCount
    local callTimeoutCount = reportData.callTimeoutCount
    local recvTimeoutCount = reportData.recvTimeoutCount
    Log.debug("NetworkStatDelay:", 
        tostring(avgDelay), tostring(maxDelay), tostring(minDelay), tostring(rto),
        tostring(totalSize), tostring(sendSize), tostring(recvSize),
        tostring(totalCount), tostring(sendCount), tostring(recvCount),
        tostring(resendCount), tostring(maxResendWaitTick), tostring(repeatCount),
        tostring(callTimeoutCount), tostring(recvTimeoutCount), tostring(connectTimeoutCount),
        tostring(lostCount), tostring(rangeCount), tostring(conflictCount), tostring(connFailedCount))
    GameGlobal.ReportCustomEvent("NetStat", "NetworkStatDelay", {avgDelay, minDelay, maxDelay, callTimeoutCount, sendSize, recvSize, math.ceil(rto), sendCount, sendCount, resendCount, recvTimeoutCount, repeatCount, lostCount, connectTimeoutCount, rangeCount, conflictCount})
end
