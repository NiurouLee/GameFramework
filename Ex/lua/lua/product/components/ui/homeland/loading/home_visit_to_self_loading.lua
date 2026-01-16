---@class HomeVisitToSelfLoading:LoadingHandler
_class("HomeVisitToSelfLoading", LoadingHandler)
HomeVisitToSelfLoading = HomeVisitToSelfLoading

function HomeVisitToSelfLoading:Constructor()
    Log.notice("[Homeland] 开始析构好友家园，并进入自己家园Loading")
    GameGlobal.UIStateManager():Lock(self:GetName())
end

function HomeVisitToSelfLoading:PreLoadBeforeLoadLevel()
    ---@type UIHomelandModule
    local uiModule = GameGlobal.GetUIModule(HomelandModule)
    uiModule:LeaveHomeland()
end

function HomeVisitToSelfLoading:PreLoadAfterLoadLevel(TT, ...)
    LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)

    ---@type HomelandModule
    local _module = GameGlobal.GetModule(HomelandModule)

    ---@type UIHomelandModule
    local _uimodule = GameGlobal.GetUIModule(HomelandModule)

    if _uimodule:IsRunning() then
        Log.exception("严重错误，当前家园正在运行！")
        return
    end

    --请求家园数据并更新状态
    local ack = _module:EnterHomeLand(TT)
    if not ack:GetSucc() then
        Log.fatal("请求家园数据失败:", ack:GetResult())
        return
    end

    YIELD(TT) --第二次进家园需要延迟一帧

    _uimodule:EnterHomeland(TT, true)
end

function HomeVisitToSelfLoading:OnLoadingFinish(...)
    local loadingParams = {...}
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeland, self.sceneResReq, table.unpack(loadingParams))
    GameGlobal.UIStateManager():UnLock(self:GetName())
end
function HomeVisitToSelfLoading:IsStateUI()
    return true
end
