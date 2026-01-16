---@class HomelandExitLoadingHandler:LoadingHandler
_class("HomelandExitLoadingHandler", LoadingHandler)
HomelandExitLoadingHandler = HomelandExitLoadingHandler

function HomelandExitLoadingHandler:Constructor()
    GameGlobal.UIStateManager():Lock("HomelandExitLoading")
end

function HomelandExitLoadingHandler:PreLoadBeforeLoadLevel(TT)
    --正常的家园析构逻辑，在销毁场景前
    ---@type UIHomelandModule
    local uiModule = GameGlobal.GetUIModule(HomelandModule)
    uiModule:LeaveHomeland()
end

function HomelandExitLoadingHandler:OnLoadingFinish(...)
    --[[
    local loadingParams = {...}
    local finishCallBack = loadingParams[1]

    local triggerGuide = false

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.GuideLeaveHomeland,
        function(trigger)
            triggerGuide = trigger
        end
    )
    if not triggerGuide then
        if finishCallBack then
            finishCallBack()
        else
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
        end
    end]]

    local loadingParams = { ... }
    local finishCallBack = loadingParams[1]
    if finishCallBack then
        finishCallBack()
    else
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
    end
    GameGlobal.UIStateManager():UnLock("HomelandExitLoading")
end

function HomelandExitLoadingHandler:LoadingType()
    return LoadingType.STATICPIC
end
