---@class HomelandEnterLoadingHandler:LoadingHandler
_class("HomelandEnterLoadingHandler", LoadingHandler)
HomelandEnterLoadingHandler = HomelandEnterLoadingHandler

function HomelandEnterLoadingHandler:Constructor()
    Log.notice("[Homeland] 开始家园Loading")
    Log.debug("[HomelandProfile] (HomelandEnterLoadingHandler.Constructor) LoadingHandlerCtor")
    GameGlobal.UIStateManager():Lock("HomelandEnterLoading")
end

function HomelandEnterLoadingHandler:PreLoadBeforeLoadLevel(TT, ...)
    --请求家园数据并更新状态
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    self._reqStateTable = self._reqStateTable or {}
    Log.debug("[homeland loading] HomelandEnterLoadingHandler:_module:EnterHomeLand start")
    --同步处理家园请求加载
    GameGlobal.TaskManager():StartTask(function()
        self._ack = self._homelandModule:EnterHomeLand(TT, self._reqStateTable)
    end)
end

function HomelandEnterLoadingHandler:PreLoadAfterLoadLevel(TT, ...)
    Log.debug("[homeland loading] HomelandEnterLoadingHandler:PreLoadAfterLoadLevel start")
    LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)
    Log.debug("[homeland loading] HomelandEnterLoadingHandler:PreLoadAfterLoadLevel end")
    ---@type UIHomelandModule
    local _uimodule = GameGlobal.GetUIModule(HomelandModule)

    if _uimodule:IsRunning() then
        Log.exception("严重错误，当前家园正在运行！")
        return
    end
    Log.debug("[HomelandProfile] (HomelandEnterLoadingHandler:PreLoadAfterLoadLevel) BeginRequestHomelandData")

    --阻塞等待数据返回
    while not self._reqStateTable.homelandDataFinish do
        YIELD(TT)
    end
    if not self._ack:GetSucc() then
        Log.fatal("请求家园数据失败:", ack:GetResult())
        return
    end
    
    Log.debug("[HomelandProfile] (HomelandEnterLoadingHandler:PreLoadAfterLoadLevel) FinishRequestHomelandData")
    YIELD(TT) --第二次进家园需要延迟一帧
    
    _uimodule:EnterHomeland(TT)
end

function HomelandEnterLoadingHandler:OnLoadingFinish(...)
    local enterCallback = GameGlobal.GetUIModule(HomelandModule):GetEnterCallback()

    if enterCallback then
        enterCallback()
    else
        local loadingParams = {...}
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeland, self.sceneResReq, table.unpack(loadingParams))
    end
    
    GameGlobal.UIStateManager():UnLock("HomelandEnterLoading")
end
