--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    Loading 管理器

    维护加载状态；加载场景；预加载资源（交给对应的Loader来处理）；更新Loading进度；针对在加载时段的一些异常，处理退出（yqqtodo）；
    资源加载结束，看看是否有必要做unused资源卸载、清理缓存UI；资源加载进度需要资源管理器的配合（yqqtodo）；Loading场景不变，Loading界面可变
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

LoadingType = {
    STATICPIC = 0, --静态图
    PROGRESS = 1, --进度条
    BOTTOM = 2 --底条
}

---@field Discovery_Enter string 进入大地图
LoadingHandlerName = {
    Battle_Loading = "BattleLoadingHandler", --进入战斗
    Battle_Exit = "BattleExitLoadingHandler", --战斗中途离开
    Exit_Core_Game = "ExitCoreGameHandler", -- 结算离开
    Aircraft_Exit = "AircraftExitLoadingHandler", --离开风船
    Aircraft_Room_Exit = "AircraftRoomExitLoadingHandler", --离开风船房间
    Aircraft_Enter = "AircraftEnterLoadingHandler", --进入风船
    Maze_Enter = "MazeEnterLoadingHandler", --进入秘境
    Maze_Exit = "MazeExitLoadingHandler", --离开秘境
    Res_Exit = "ResExitLoadingHandler", --离开资源本
    Shop_Enter = "ShopEnterLoadingHandler", --进入商店
    DrawCard_Enter = "UIDrawCardLoadingEnter", --进入抽卡
    DrawCard_Enter_UL = "UIDrawCardLoadingEnterUL", --UniversalLink进入抽卡
    DrawCard_Exit = "UIDrawCardLoadingExit", --离开抽卡
    Discovery_Enter = "UIDiscoveryLoadingEnterHandler", --进入大地图
    Cutscene_Enter = "CutsceneLoadingHandler", ---进入回放剧情
    Cutscene_Exit = "CutsceneExitLoadingHandler", ---退出回放剧情
    Aircraft2Drawcard = "AircraftToDrawcardLoading", --风船到抽卡
    Homeland_Enter = "HomelandEnterLoadingHandler", --进入家园
    Homeland_Exit = "HomelandExitLoadingHandler", --离开家园
    Season_Enter = "SeasonEnterLoadingHandler", --进入赛季地图
    Season_Exit = "SeasonExitLoadingHandler" --退出赛季地图
}

--**********************************************************
-- 进入UI场景的loadingHandler 直接设置progress为100
local EnterUILoadingHandler = {
    [LoadingHandlerName.Aircraft_Enter] = true,
    [LoadingHandlerName.Aircraft_Room_Exit] = true,
    [LoadingHandlerName.Aircraft_Exit] = true,
    [LoadingHandlerName.Maze_Enter] = true,
    [LoadingHandlerName.Maze_Exit] = true,
    [LoadingHandlerName.DrawCard_Enter] = true,
    [LoadingHandlerName.DrawCard_Exit] = true
}
---@class LoadingManager
_class("LoadingManager", Object)

local unpack = table.unpack
local LOADING_SCENE_NAME = "Loading.unity"

--region 初始化/销毁
function LoadingManager:Constructor()
    ---@type LoadingHandler
    self.loadingHandler = nil
    self.loadingHandlerName = nil
    self.targetLevelName = nil
    self.loadingParams = nil

    --manager和handler更新同1个进度条
    ---@type LoadingProgressBar
    self._progressBar = LoadingProgressBar:New()

    self._isCoreGameLoading = false
    self._isLoading = false
    --打断Loading的回调，单次Loading不会被实时打断，结束时会判断是否有需要执行的打断回调
    self._interruptCallback = nil
end
--endregion

---@public
---切到新场景的Loading入口
---@param loadingHandlerName string LoadingHandler(处理预加载)
---@param targetLevelName string 目标场景名称(可以为空)
---@param ... 其他loading参数 用在预加载函数中
function LoadingManager:StartLoading(loadingHandlerName, targetLevelName, ...)
    self._isLoading = true
    self._interruptCallback = nil
    ResourceManager:GetInstance():SetSyncLoadNum(3)
    self.loadingHandlerName = loadingHandlerName
    if not self.loadingHandlerName then
        return
    end
    ---@type LoadingHandler
    local loadingHandler = _createInstance(self.loadingHandlerName)
    if not loadingHandler then
        return
    end

    if not loadingHandler:IsChildOf("LoadingHandler") then
        Log.fatal(
            "LoadingManager:StartLoading Fail,",
            self.loadingHandlerName,
            " is not inherited from LoadingHandler!"
        )
        return
    end

    loadingHandler:SetProgressBar(self._progressBar)

    self.loadingHandler = loadingHandler
    self.targetLevelName = targetLevelName
    self.loadingParams = {...}
    self._latestHandler = loadingHandlerName --记录最近一次的loading
    self:StartTask(LoadingManager.Load, self)
end

---不能删
function LoadingManager:Update(deltaTimeMS)
end

---@private
function LoadingManager:Load(TT)
    Log.debug("[HomelandProfile] (LoadingManager:Load) StartLoadTask")
    --todo 考虑需不需要清理资源 UnloadUnusedResources
    local tik = os.clock()
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:StopAll()
    --停止全部UI语音
    AudioHelperController.StopAllUIVoice()

    if GameGlobal.UIStateManager():CurUIStateType() == UIStateType.Invalid or self.loadingHandler:NeedSwitchState() then
        GameGlobal.UIStateManager():SwitchState(
            UIStateType.UICommonLoading,
            self.loadingHandler:LoadingType(),
            self.loadingHandler:LoadingID()
        )
        YIELD(TT)
    else
        local showTaskid =
            GameGlobal.UIStateManager():ShowDialog(
            "UICommonLoading",
            self.loadingHandler:LoadingType(),
            self.loadingHandler:LoadingID()
        )
        JOIN(TT, showTaskid)
    end
    Log.debug("[HomelandProfile] (LoadingManager:Load) ShowLoadingUI")
    --显示完LoadingUI之后设置进度条
    self._progressBar:Reset()

    --进入Loading场景过渡
    if self.targetLevelName then
        Log.debug("[HomelandProfile] (LoadingManager:Load) StartLoadLoadingScene -> " .. LOADING_SCENE_NAME)
        local req = ResourceManager:GetInstance():AsyncLoadAsset(TT, LOADING_SCENE_NAME, LoadType.Unity)
        req:Dispose()
        Log.debug("[HomelandProfile] (LoadingManager:Load) FinishLoadLoadingScene ->" .. LOADING_SCENE_NAME)
    end

    --预加载资源
    self.loadingHandler:PreLoadBeforeLoadLevel(TT, unpack(self.loadingParams, 1, table.maxn(self.loadingParams)))
    local sceneReq = nil
    if self.targetLevelName then
        Log.debug("[HomelandProfile] (LoadingManager:Load) StartLoadHomelandScene -> ", self.targetLevelName)
        --不是很懂为什么等一帧
        YIELD(TT)
        sceneReq = self.loadingHandler:LoadLevel(TT, self.targetLevelName)
        Log.debug("[HomelandProfile] (LoadingManager:Load) FinishLoadLoadingScene ->", self.targetLevelName)
    end
    Log.debug("[HomelandProfile] (LoadingManager:Load) StartPreLoadAfterLoadLevel")
    self.loadingHandler:PreLoadAfterLoadLevel(TT, unpack(self.loadingParams, 1, table.maxn(self.loadingParams)))
    Log.debug("[HomelandProfile] (LoadingManager:Load) FinishPreLoadAfterLoadLevel")
    GameGlobal.EventDispatcher():Dispatch(GameEventType.LoadLevelEnd, true)
    -- 直接进入UI的loading progress直接设置为100
    if self:IsEnterUI() then
        self._progressBar:Complete()
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.LoadingProgressChanged, 100)
    end
    local tok = os.clock() - tik
    Log.prof("LoadingManager:Load(TT) use time=", tok * 1000)
    Log.debug("[HomelandProfile] (LoadingManager:Load) FinishLoad ->" .. tok * 1000)
end

---@public
---进度条loading的条件以后可能会拓展很多
function LoadingManager:Excute(value)
    ResourceManager:GetInstance():SetSyncLoadNum(0)
    self:onLoadingFinish()
end

---@private
function LoadingManager:StartTask(func, ...)
    TaskManager:GetInstance():StartTask(func, ...)
end

function LoadingManager:IsEnterUI()
    return EnterUILoadingHandler[self.loadingHandlerName]
end

function LoadingManager:IsLoading()
    return self._isLoading or self._isCoreGameLoading
end

--打断Loading
function LoadingManager:Interrupt(cb)
    if not self:IsLoading() then
        Log.warn("not loading now,cant interrupt")
        return
    end

    if self._interruptCallback and not cb then
        Log.warn("cant set interrupt callback nil")
        return
    end

    if self._isCoreGameLoading then
        Log.debug("[Loading] 尝试打断局内loading")
    end

    if cb then
        GameGlobal.UIStateManager():Lock("WaitToInterruptLoading")
        GameGlobal.UIStateManager():ShowBusy(true)
        self._interruptCallback = cb
    end
end

--局内走特殊的Loading，需要通知LoadingManager
function LoadingManager:CoreGameLoadingStart()
    self._isCoreGameLoading = true
end

function LoadingManager:CoreGameLoadingFinish()
    Log.debug("[Loading] 局内loading结束")
    self:onLoadingFinish()
    self._isCoreGameLoading = false
end

function LoadingManager:onLoadingFinish()
    self._isLoading = false

    if self._interruptCallback then
        local cb = self._interruptCallback
        self._interruptCallback = nil
        GameGlobal.UIStateManager():UnLock("WaitToInterruptLoading")
        GameGlobal.UIStateManager():ShowBusy(false)
        if self._isCoreGameLoading then
            Log.debug("[Loading] 执行局内打断回调")
        else
            Log.debug("[Loading] 执行普通打断回调")
        end
        cb()
        return
    end

    if self.loadingHandler then
        self.loadingHandler:LoadingFinish(unpack(self.loadingParams, 1, table.maxn(self.loadingParams)))
    end
    self.loadingHandler = nil
    self.loadingHandlerName = nil
    self.targetLevelName = nil
    self.loadingParams = nil
end

----------------------------------
--[[
    Loading进度条
]]
---@class LoadingProgressBar:Object
_class("LoadingProgressBar", Object)
LoadingProgressBar = LoadingProgressBar

function LoadingProgressBar:Constructor()
    self._percent = 0
end

--设置进度0-100
function LoadingProgressBar:SetProgress(progress)
    progress = Mathf.Clamp(progress, 0, 100)
    if self._percent > progress then
        Log.fatal("Loading progress error:", progress, "，current is ", self._percent)
        return
    elseif self._percent == progress then
        return
    end
    self._percent = progress
    GameGlobal.EventDispatcher():Dispatch(GameEventType.LoadingProgressChanged, self._percent)
end

--获取当前进度
function LoadingProgressBar:GetProgress()
    return self._percent
end

function LoadingProgressBar:Reset()
    self._percent = -1
    self:SetProgress(0)
end

function LoadingProgressBar:Complete()
    self:SetProgress(100)
end
