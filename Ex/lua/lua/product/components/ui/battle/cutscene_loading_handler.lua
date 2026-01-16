---@class CutsceneLoadingHandler:LoadingHandler
_class("CutsceneLoadingHandler", LoadingHandler)
CutsceneLoadingHandler = CutsceneLoadingHandler

function CutsceneLoadingHandler:PreLoadBeforeLoadLevel(TT)
    --GameGlobal.LoadingManager():CoreGameLoadingStart()
end

function CutsceneLoadingHandler:PreLoadAfterLoadLevel(TT, ...)
    LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)

    ---@type UIStoryModule
    local uiStoryModule = GameGlobal.GetModule(StoryModule):GetUIModule()
    self._levelID = uiStoryModule:GetLevelID()

    if self._levelID == nil then
        self._levelID = 1000902
    end

    local levelRawData = Cfg.cfg_level[self._levelID]
    local themeRawData = Cfg.cfg_theme[levelRawData.Theme]
    local levelResPath = themeRawData.SceneResPath

    ---加载场景
    GameGlobal:GetInstance().gameLogic:LoadScene(TT, levelResPath)
end

function CutsceneLoadingHandler:OnLoadingFinish(...)
    GameGlobal:GetInstance():GetCollector("CoreGameLoading"):Sample("CutsceneLoadingHandler:OnLoadingFinish() begin")

    GameGlobal.UIStateManager():SwitchState(UIStateType.UICutsceneReview)
    GameGlobal:GetInstance():EnterCutscene(self._levelID)

    GameGlobal:GetInstance():GetCollector("CoreGameLoading"):Sample("CutsceneLoadingHandler:OnLoadingFinish()")
end
