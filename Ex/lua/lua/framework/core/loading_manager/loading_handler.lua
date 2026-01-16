--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    针对切场景预加载以及加载完成进行处理。
    有自定义预加载的局内，继承LoadingHandler。
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class LoadingHandler
_class("LoadingHandler", Object)
LoadingHandler = LoadingHandler

function LoadingHandler:Constructor()
    self.sceneResReq = nil
    self.loadingID = nil
    self.cfg = Cfg.cfg_system_loading {loadingHandlerName = self._className}
end

function LoadingHandler:SetProgressBar(progressBar)
    ---@type LoadingProgressBar
    self._progressBar = progressBar
end

---具体的资源预加载由具体的LoadingHandler来处理
function LoadingHandler:PreLoadBeforeLoadLevel(TT, ...)
end

function LoadingHandler:LoadLevel(TT, levelName)
    if string.equal_with_ignorecase(UIHelper.GetActiveSceneName(), levelName) then
        Log.debug("[Loading] LoadingHandler:LoadLevel, this level is already active ,", levelName)
        return
    end
    Log.debug("[Loading] LoadingHandler:LoadLevel, ", levelName)
    self.sceneResReq = GameGlobal.GameLogic():LoadScene(TT, levelName)
end

function LoadingHandler:PreLoadAfterLoadLevel(TT, ...)
end

---@public
function LoadingHandler:LoadingFinish(...)
    self:OnLoadingFinish(...)
end

function LoadingHandler:OnLoadingFinish()
    --创建对局
    --切入对局界面
end

function LoadingHandler:SetLoadingProgress(progress)
    if self._progressBar then
        self._progressBar:SetProgress(progress)
    end

    -- Log.debug("progress ",progress, " self.progress ", self.progress)
    -- if self.progress < progress then
    --     Log.debug("[Loading] LoadingHandler:SetLoadingProgress ", progress)
    --     self.progress = progress
    --     GameGlobal.EventDispatcher():Dispatch(GameEventType.LoadingProgressChanged, progress)
    -- end
end

---加载类型，默认PROGRESS，子类可重写
function LoadingHandler:LoadingType()
    return LoadingType.STATICPIC
end

function LoadingHandler:LoadingID()
    local loadingIds = self.cfg and self.cfg[1].loadingIds
    if loadingIds then
        local index = math.random(1, #loadingIds)
        return loadingIds[index]
    else
        return nil
    end
end
--Loading时切换State
function LoadingHandler:NeedSwitchState()
    return false
end
