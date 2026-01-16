---@class ResExitLoadingHandler:LoadingHandler
_class("ResExitLoadingHandler", LoadingHandler)
ResExitLoadingHandler = ResExitLoadingHandler

function ResExitLoadingHandler:PreLoadBeforeLoadLevel(TT)
end

function ResExitLoadingHandler:PreLoadAfterLoadLevel(TT, ...)
    LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)
    -- Log.error("PreLoadAfterLoadLevel")
end

function ResExitLoadingHandler:OnLoadingFinish(...)
    local module = GameGlobal.GetModule(ResDungeonModule)
    local clientResInstance = module:GetClientResInstance()
    local instanceId = module:GetEnterInstanceId()
    local mainType = clientResInstance:GetMainTypeByInstanceId(instanceId)
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIResDetailController, mainType)
    -- module:GetOpenStatus(TT)
    -- if result ~= {} then
    --     GameGlobal.UIStateManager():ShowDialog("UIResEntryController", mainType)
    -- end
    -- Log.error("PreLoadBeforeLoadLevel")
    -- YIELD(TT, 10000)
    -- Log.error("等了10")
    -- GameGlobal.UIStateManager():CloseDialog("UICommonLoading")
    -- Log.error("OnLoadingFinish")
end

function ResExitLoadingHandler:LoadingType()
    return LoadingType.BOTTOM
end
