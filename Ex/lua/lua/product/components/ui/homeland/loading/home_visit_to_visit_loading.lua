---@class HomeVisitToVisitLoading:LoadingHandler
_class("HomeVisitToVisitLoading", LoadingHandler)
HomeVisitToVisitLoading = HomeVisitToVisitLoading

function HomeVisitToVisitLoading:Constructor()
    Log.notice("[Homeland] 开始析构好友的家园，并进入其他好友家园Loading")
    GameGlobal.UIStateManager():Lock(self._className)
end

function HomeVisitToVisitLoading:PreLoadBeforeLoadLevel()
    ---@type UIHomelandModule
    local uiModule = GameGlobal.GetUIModule(HomelandModule)
    uiModule:LeaveHomeland()
end

function HomeVisitToVisitLoading:PreLoadAfterLoadLevel(TT, ...)
    self._canEnter = false

    LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)

    ---@type HomelandModule
    local _module = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    local _uimodule = GameGlobal.GetUIModule(HomelandModule)
    if _uimodule:IsRunning() then
        Log.exception("严重错误，当前家园正在运行！")
        return
    end

    --访问别人的家园也需要先拉自己的数据
    local ack1 = _module:EnterHomeLand(TT)
    if not ack1:GetSucc() then
        Log.fatal("请求家园数据失败:", ack1:GetResult())
        return
    end
    --拉去完清理掉不需要的数据
    _module:ClearNormalData()

    local params = {...}
    --请求家园数据并更新状态
    local ack, data = _module:HomelandVisitFriendReq(TT, params[1])
    if not ack:GetSucc() then
        ToastManager.ShowHomeToast(_module:GetVisitErrorMsg(ack:GetResult()))
        return
    end

    _uimodule:SetVisitInfo(data.infos)

    YIELD(TT) --第二次进家园需要延迟一帧

    _uimodule:EnterHomeland(TT, true)

    self._canEnter = true
end

function HomeVisitToVisitLoading:OnLoadingFinish(...)
    if self._canEnter then
        local loadingParams = {...}
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeland, self.sceneResReq, table.unpack(loadingParams))
    else
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
    end
    GameGlobal.UIStateManager():UnLock(self._className)
end
function HomeVisitToVisitLoading:NeedSwitchState()
    return true
end
