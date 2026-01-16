---@class SeasonExitLoadingHandler:LoadingHandler
_class("SeasonExitLoadingHandler", LoadingHandler)
SeasonExitLoadingHandler = SeasonExitLoadingHandler

function SeasonExitLoadingHandler:Constructor()
    GameGlobal.UIStateManager():Lock("SeasonExitLoadingHandler")
end

function SeasonExitLoadingHandler:PreLoadBeforeLoadLevel(TT)
    ---@type SeasonModule
    local module = GameGlobal.GetModule(SeasonModule)
    ---@type UISeasonModule
    local uimodule = GameGlobal.GetUIModule(SeasonModule)
    uimodule:ExitSeasonGame()
end

function SeasonExitLoadingHandler:OnLoadingFinish(...)
    local loadingParams = { ... }
    -- ---@type UISeasonModule
    -- local uimodule = GameGlobal.GetUIModule(SeasonModule)
    -- local state = uimodule:GetLastUIState() --从哪来回哪去
    -- if not state then
    --     state = UIStateType.Main
    -- end
    local param = loadingParams[1]
    local uiState
    local exitCb
    if param then
        if type(param) == "function" then
            exitCb = param
        elseif type(param) == "string" then
            uiState = param
        else
            Log.exception("赛季退出参数错误")
        end
    else
        uiState = UIStateType.UIMain --不传参数默认退回主界面
    end
    if uiState then
        GameGlobal.UIStateManager():SwitchState(uiState)
    elseif exitCb then
        exitCb()
    end
    GameGlobal.UIStateManager():UnLock("SeasonExitLoadingHandler")
end

function SeasonExitLoadingHandler:LoadingType()
    return LoadingType.STATICPIC
end
