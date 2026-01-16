---@class GameGlobal:Singleton

---@field GetInstance GameGlobal

_class("GameGlobal", Singleton)

GameGlobal = GameGlobal

--region 初始化/销毁
function GameGlobal:Constructor()
    self.isDisposing = false
    self.timeMS = 0
    self.unscaledTimeMS = 0
    self.deltaMS = 0
    self.unscaledDeltaMS = 0
    self.last_time = 0
    self.frameCount = 0
    self.gameEventListenerIDGenerator = nil
    self.gameEventDispatcher = nil
    self.uiStateManager = nil
    self.resolutionManager = nil
    self.h3dTimer = nil
    self.gameLogic = nil
    self.loadingManager = nil
    self.engineInput = nil
    self.h3dRealTimer = nil
    self._collectors = {}
    self.stringTable = StringTable:GetInstance()
    self.taskManager = TaskManager:GetInstance()
    self.luaProfiler = AutoProfiler:New()
    self.donotDestroyRes = DonotDestroyResource:New()
    self.gameRecorder = nil
    ---@type PoolManager
    self.poolManager = nil
    self.guideMessageBoxMng = nil
    self._print_mem_time = 0
    self._isOfflineMatch = false
end

function GameGlobal:Dispose()
    self.isDisposing = true
    --UI可以依赖逻辑，但逻辑不应该依赖UI，UIStateManager应该在GameLogic前释放
    self.taskManager:KillAllTasks()

    if self.gameLogic then
        self.gameLogic:Dispose()
    --这个地方会不会可能触发对UI的依赖
    end

    --成就弹窗
    AchievementManager:GetInstance():Dispose()
    HomeUIBubbleManager:GetInstance():Dispose()
    ToastManager:GetInstance():Dispose()
    CutsceneManager:GetInstance():Dispose()

    if self.uiStateManager then
        self.uiStateManager:Dispose()
    --这个地方会不会可能触发对UI的依赖
    end

    --[[
    if self.loadingManager then
        self.loadingManager:Dispose()
    end
    ]]
    if self.h3dTimer then
        self.h3dTimer:Clear()
    end

    if self.h3dRealTimer then
        self.h3dRealTimer:Clear()
    end

    if self.gameEventDispatcher then
        self.gameEventDispatcher:RemoveAllListeners()
    end

    self.stringTable:Dispose()
    AudioHelperController.StopBGM()
    self.donotDestroyRes:Dispose()
    self._collectors = {}

    self.gameRecorder:Dispose()

    if self.poolManager then
        self.poolManager:Dispose()
    end
    if self.guideMessageBoxMng then
        self.guideMessageBoxMng:Dispose()
    end
end

--游戏过程中销毁lua世界的回调。
--理论上lua世界关闭的时候主动解引用常驻的C#服务就行了
--目前直接调用GameGlobal:Dispose会暴露很多释放的问题，出现LuaException。不过后续还要完善这个释放过程。
-- function GameGlobal:OnLuaDestroy()
--     self.isDisposing = true
--     --释放GameModule,比如有SDK的注册、解注册
--     if self.gameLogic then
--         self.gameLogic:Reset()
--     end

--     Log.fatal("res0.4")
--     PopupManager.Alert("UIDemoCommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok, "提示", "GameGlobal:OnLuaDestroy")
--     self.uiStateManager:ShowDialog("UIDemoMainController")

--     --释放GameObject:New
--     if self.poolManager then
--         self.poolManager:Dispose()
--     end
-- end
function GameGlobal:IsDisposing()
    return self.isDisposing
end

GameGlobal.Version = "0.0.0.0"
GameGlobal.MagicToken = "MAGICTOKEN_51433213c2e72a6304fb805b10a2201d" .. "jkh3kx95kkfp3lsjflxlvjkf3lfj4"

function GameGlobal:OnApplicationPause(pauseStatus)
    if self.appPaused ~= pauseStatus then
        self.appPaused = pauseStatus

        if self.appPaused then
            self.gameEventDispatcher:Dispatch(GameEventType.AppHome)
        else
            self.gameEventDispatcher:Dispatch(GameEventType.AppResume)
        end
    end
end

function GameGlobal:OnApplicationFocus(hasFocus)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ApplicationFocus, hasFocus)
    if self.appFocused ~= hasFocus then
        self.appFocused = hasFocus
    end
end

function GameGlobal:OnApplicationQuit()
    Log.sys("GameGlobal:OnApplicationQuit")

    if self.appQuit then
        return
    end

    self.appQuit = true
    TSSSDKProxy:GetInstance():OnQuit()
    GameGlobal.GameRecorder():StopRecord()
    GameGlobal:GetInstance():Dispose()
    ResourceManager:GetInstance():Dispose()
end

--endregion

--region 启动流程中做的事情

function GameGlobal:Init()
    Log.init()
    Log.prof("[loading] Init Start")
    self.gameEventListenerIDGenerator = IDGenerator:New(IDGeneratorType.GAME_EVENT_LISTENER_FIRST_ID)

    self.gameEventDispatcher = GameEventDispatcher:New()

    self.h3dTimer = H3DTimer:New()

    self.h3dRealTimer = H3DRealTimer:New()

    self.loadingManager = LoadingManager:New()

    self.poolManager = PoolManager:New()
    self.guideMessageBoxMng = GuideMessageBoxMng:New()
    self:AddCollector("LoginLoading")
    self:AddCollector("CoreGameLoading")

    self.gameRecorder = GameRecorder:New()

    self.taskManager:StartTask(GameGlobal.InitUI, self)

    TSSSDKProxy:GetInstance():Init()
    -- self.coreGameTest = CoreGameEntryTest:New()
end

---@private
function GameGlobal:InitUI(TT)
    Log.debug("GameGlobal InitUI started")

    self.resolutionManager = ResolutionManager:New()

    self.resolutionManager:Init()

    --重载ab 主要是重载shader 因为shader的ab已经加载了 如果有热更不重载会找不到新增的shader，修改也不会生效
    ResourceManager:GetInstance():UnloadAllABs()

    local request = ResourceManager:GetInstance():SyncLoadAsset("GlobalUIRoot.prefab", LoadType.GameObject)
    self.uiStateManager = UIStateManager:New(request)

    self.resolutionManager:InitAfterUI(request.Obj)
    ToastManager:GetInstance():Init(request.Obj)
    CutsceneManager:GetInstance():Init(request.Obj)
    UISwitchImgManager:GetInstance():Init(request.Obj)
    self:InitAfterUI(TT)
    --放在stringtable后面
    AchievementManager:GetInstance():Init(request.Obj)

    HomeUIBubbleManager:GetInstance():Init(request.Obj)

    Log.debug("GameGlobal InitUI ended")
end

function GameGlobal:InitAfterUI(TT)
    self.stringTable:ClearTable()

    self.stringTable:Init()

    AudioHelperController.Initialize()

    --CriAudioHelper.RequestUICueSheetSync(1001)

    local bgmOn = LocalDB.GetInt("MusicVolumeOnKey", 1) > 0
    local soundOn = LocalDB.GetInt("SoundVolumeOnKey", 1) > 0
    local voiceOn = LocalDB.GetInt("VoiceVolumeOnKey", 1) > 0

    local bgmGlobal = Cfg.cfg_global["bgm_volume"].FloatValue
    local voiceGlobal = Cfg.cfg_global["voice_volume"].FloatValue
    local soundGlobal = Cfg.cfg_global["sound_volume"].FloatValue

    local bgm_value = bgmOn and LocalDB.GetInt("MusicVolumeKey", 100) / 100 * bgmGlobal or 0
    AudioHelperController.SetBgmVolume(bgm_value)

    local voice_value = voiceOn and LocalDB.GetInt("VoiceVolumeKey", 100) / 100 * voiceGlobal or 0
    AudioHelperController.SetVoiceVolume(voice_value)

    local sound_value = soundOn and LocalDB.GetInt("SoundVolumeKey", 100) / 100 * soundGlobal or 0
    AudioHelperController.SetSoundVolume(sound_value)

    self.gameLogic = GameLogic:New()

    self.gameLogic:Init()
    self.poolManager:Init()

    local gameStartType = UIHelper.GameStartType()

    Log.prof("[prof] GameGlobal:InitAfterUI", gameStartType)

    --限制帧数
    GameGlobal.SetTargetFrameRate()
    --设置抗锯齿
    GameGlobal.SetAntialiasing()

    GameGlobal.SetQualityByLodLevel()
    --设置高帧率
    GameGlobal.SetHighFrameStatus(GameGlobal.GetHighFrameStatus())

    if gameStartType == EGameStartType.Normal then
        --新版登陆不会调用这里的ui
        if HelperProxy:GetInstance():GetConfig("TMPLoginSwitch", "false") == "false" then
            self.uiStateManager:PushAndSwitchState(UIStateType.Login)
        else
            GameGlobal.UIStateManager():SetBlackSideVisible(false)
            self.uiStateManager:PushAndSwitchState(UIStateType.LoginEmpty)
        end
    elseif gameStartType == EGameStartType.UITest then
        self.UIStateManager():PushAndSwitchState(UIStateType.DemoMain)
    elseif gameStartType == EGameStartType.StoryViewer then
        self.UIStateManager():PushAndSwitchState(UIStateType.UIStoryViewer)
    elseif gameStartType == EGameStartType.StoryViewer3D then
        self.UIStateManager():PushAndSwitchState(UIStateType.UIStoryViewer3D)
    elseif gameStartType == EGameStartType.SkillEditor then
        self.UIStateManager():PushAndSwitchState(UIStateType.UISKillEditor)
    end

    --缓存常用资源配置
    self:Cache()

    Log.prof("[loading] Init end")
end

function GameGlobal:Cache()
    Cfg.cfg_level()
    Cfg.cfg_refresh()
    Cfg.cfg_refresh_monster()
    Cfg.cfg_monster_class()
    Cfg.cfg_monster()
    Cfg.cfg_monster_wave()

    self._cacheReqList = {}
    self.taskManager:StartTask(GameGlobal.CacheRes, self, "UIDiscovery.prefab", LoadType.GameObject)
    self.taskManager:StartTask(GameGlobal.CacheRes, self, "UIStage.prefab", LoadType.GameObject)
    self.taskManager:StartTask(GameGlobal.CacheRes, self, "map_bantou18_frame.mat", LoadType.Mat)
    self.taskManager:StartTask(GameGlobal.CacheRes, self, "UIEnemyItem.prefab", LoadType.GameObject)
    self.taskManager:StartTask(GameGlobal.CacheRes, self, "UICommonTopButton.prefab", LoadType.GameObject)
end

function GameGlobal:CacheRes(TT, resName, resType)
    self._cacheReqList[resName] = ResourceManager:GetInstance():AsyncLoadAsset(TT, resName, resType)
end

function GameGlobal.GetHighFrameKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = "HIGH_FRAME_STATUS"
    return key
end

function GameGlobal.GetHighFrameStatus()
    Log.error(LocalDB.GetInt(GameGlobal.GetHighFrameKey(), 0))
    local highFrameStatus = LocalDB.GetInt(GameGlobal.GetHighFrameKey(), 0) ~= 0
    return highFrameStatus
end

function GameGlobal.SetHighFrameStatus(status)
    if status then
        LocalDB.SetInt(GameGlobal.GetHighFrameKey(), 1)
        UnityEngine.Application.targetFrameRate = 60
        UnityEngine.QualitySettings.vSyncCount = 0
    else
        LocalDB.SetInt(GameGlobal.GetHighFrameKey(), 0)
        GameGlobal.SetTargetFrameRate()
    end
end

function GameGlobal.SetTargetFrameRate()
    if GameGlobal.GetHighFrameStatus() then
        GameGlobal.SetHighFrameStatus(true)
        return
    end
    local lodlevel = LODManager.Instance:GetLODLevel()
    if (GetPlatformOS() == ClientRuntimeOS.CRO_PC) then
        UnityEngine.Application.targetFrameRate = 60
    elseif (lodlevel == 0) then
        UnityEngine.Application.targetFrameRate = 30
    elseif (lodlevel == 1) then
        UnityEngine.Application.targetFrameRate = 30
    else
        UnityEngine.Application.targetFrameRate = 30
    end
end
function GameGlobal.SetQualityByLodLevel()
    local lodlevel = LODManager.Instance:GetLODLevel()
    if (lodlevel == 0) then
        --GameGlobal.SetQuality("Level1")
        UnityEngine.QualitySettings.SetQualityLevel(2)
        Log.debug(" GameGlobal.SetQuality level 2")
    elseif (lodlevel == 1) then
        --GameGlobal.SetQuality("Level2")
        UnityEngine.QualitySettings.SetQualityLevel(1)
        Log.debug(" GameGlobal.SetQuality level 1")
    else
        --GameGlobal.SetQuality("Level3")
        UnityEngine.QualitySettings.SetQualityLevel(0)
        Log.debug(" GameGlobal.SetQuality level 0")
    end
end

function GameGlobal.SetAntialiasing()
    if APPVER130 then
        local currLevel = LODManager.Instance:GetLODLevel()
        Log.debug("###[GameGlobal] SetAnti currLevel --> ", currLevel)
    
        --控制值
        local openAntialiasing = false
        local value = LocalDB.GetString("CloseAntialiasing", "null")
        if value == "close" then
            --关闭
            openAntialiasing = false
        elseif value == "open" then
            --开启
            openAntialiasing = true
        else
            --如果没有手动设置该值，默认为关闭。只有一档机开(LODLevel.HIGH-=0)，其余关，并设置LocalDB为close
            openAntialiasing = false
            value = "close"
            if currLevel == 0 then
                openAntialiasing = true
                value = "open"
            end
        end
    
        ---@type LODSetting
        local setting = LODManager.Instance.setting
        setting.IsOpenAntialiasing = openAntialiasing
        if currLevel == 2 then
            setting.isOpenImageProcess = openAntialiasing
        end
        Log.debug("###[GameGlobal] SetAnti IsOpenAntialiasing --> ", tostring(setting.IsOpenAntialiasing))
        Log.debug("###[GameGlobal] SetAnti isOpenImageProcess --> ", tostring(setting.isOpenImageProcess))
    
        LocalDB.SetString("CloseAntialiasing", value)
    end
end
function GameGlobal:Update(deltaMS, unscaledDeltaMS, timeMS, unscaledTimeMS)
    self.engineInput = UnityEngine.Input
    -- if GetPlatformOS() ~= ClientRuntimeOS.CRO_PC then
    --     local roleModule = self.GameLogic():GetModule(RoleModule)
    --     roleModule:ReportTssData2Server()
    -- end

    if (timeMS - self.last_time >= 1000) then
        self.last_time = timeMS
    end
    --[[
    self._print_mem_time = self._print_mem_time + deltaTimeMS
    if (self._print_mem_time > 10 * 1000) then
        local memoryCount = math.floor(collectgarbage("count") / 1024)
        Log.prof("[luamem] update current memory: ", memoryCount, " MB")
        self._print_mem_time = 0
    end
    ]]
    self.frameCount = self.frameCount + 1

    self.timeMS = timeMS
    self.unscaledTimeMS = unscaledTimeMS
    self.deltaMS = deltaMS
    self.unscaledDeltaMS = unscaledDeltaMS

    self.taskManager:Update()

    if self.gameLogic then
        self.gameLogic:Update(self.timeMS)
    end

    if self.uiStateManager then
        self.uiStateManager:Update(deltaMS)
    end

    if self.h3dTimer then
        self.h3dTimer:Update(deltaMS)
    end

    if self.h3dRealTimer then
        self.h3dRealTimer:Update(deltaMS)
    end

    if self.loadingManager then
        self.loadingManager:Update(deltaMS)
    end

    --Test
    -- if self.coreGameTest then
    --     self.coreGameTest:Update(deltaMS)
    -- end

    --检测Android返回
    if self.engineInput.GetKeyDown(UnityEngine.KeyCode.Escape) then
        self.gameEventDispatcher:Dispatch(GameEventType.AppReturn)
    end

    ---[[----------------局内--------------
    if self.coreGame and self.coreGame:Running() then
        self.coreGame:Update(self.timeMS, deltaMS)
    end
    self.luaProfiler:StoreSamepleData()

    --]]-----------------------------------------

    ---[[----------------剧情--------------
    if self.cutsceneGame and self.cutsceneGame:Running() then
        self.cutsceneGame:Update(self.timeMS, deltaMS)
    end
    --]]-----------------------------------------

    --每帧步进gc 256k
    collectgarbage("step", 256)
end
---@private
function GameGlobal:LateUpdate()
end

---@private
function GameGlobal:FixedUpdate(fixedDeltaMS)
end

--endregion

--region接口
---获取当前时间(单位：毫秒)
---@return number
function GameGlobal:GetCurrentTime()
    return self.timeMS
end
---获取当前时间，不受时间缩放影响(单位：毫秒)
---@return number
function GameGlobal:GetCurrentUnscaledTime()
    return self.unscaledTimeMS
end
---获取当前帧间隔(单位：毫秒)
---@return number
function GameGlobal:GetDeltaTime()
    return self.deltaMS
end
---获取当前帧间隔(未缩放)(单位：毫秒)
---@return number
function GameGlobal:GetUnscaledDeltaTime()
    return self.unscaledDeltaMS
end
---获取当前时间, 不受应用切后台影响(单位：毫秒)
---@return number
function GameGlobal:GetCurrentRealTime()
    if self.engineTime == nil then
        self.engineTime = UnityEngine.Time
    end

    return self.engineTime.realtimeSinceStartup * 1000
end

function GameGlobal:GetCurrentFrameCount()
    return self.frameCount
end

function GameGlobal:GetLastTimeMS()
    return self.last_time
end

function GameGlobal.GameLogic()
    return GameGlobal:GetInstance().gameLogic
end

---@return TaskManager
function GameGlobal.TaskManager()
    return GameGlobal:GetInstance().taskManager
end

---@return UIStateManager
function GameGlobal.UIStateManager()
    return GameGlobal:GetInstance().uiStateManager
end

function GameGlobal.ResolutionManager()
    return GameGlobal:GetInstance().resolutionManager
end

---@return LoadingManager

function GameGlobal.LoadingManager()
    return GameGlobal:GetInstance().loadingManager
end

---@return H3DTimer

function GameGlobal.Timer()
    return GameGlobal:GetInstance().h3dTimer
end

function GameGlobal.RealTimer()
    return GameGlobal:GetInstance().h3dRealTimer
end

---@return StringTable

function GameGlobal.StringTable()
    return GameGlobal:GetInstance().stringTable
end

---@return PoolManager
function GameGlobal.PoolManager()
    return GameGlobal:GetInstance().poolManager
end
function GameGlobal.GuideMessageBoxMng()
    return GameGlobal:GetInstance().guideMessageBoxMng
end
---@generic T:GameModule
---@param type T
---@return T
function GameGlobal.GetModule(type)
    local module = GameGlobal:GetInstance().gameLogic:GetModule(type)

    if (module == nil) then
        Log.error("GameGlobal.GetModule nil ", Log.traceback())
    end

    return module
end

function GameGlobal.GetZoneCfgTable(cfg_table_name, index)
    if not cfg_table_name then
        return nil
    end
    local l_role_module = GameGlobal.GetModule(RoleModule)
    local l_zone_id = l_role_module:GetZoneIdType()
    local l_strZoneTableName = cfg_table_name .. "_" .. l_zone_id
    local retTable = nil
    if ResourceManager:GetInstance():HasLua(l_strZoneTableName) then
        retTable = GameGlobal.GetCfgTable(l_strZoneTableName, index)
    end
    if retTable ~= nil then
        return retTable
    end

    retTable = GameGlobal.GetCfgTable(cfg_table_name, index)
    return retTable
end

function GameGlobal.GetCfgTable(cfg_table_name, index)
    if (not index) or (type(index) == "table" and not next(index)) then
        return Cfg[cfg_table_name] {}
    end
    return Cfg[cfg_table_name][index]
end

function GameGlobal.GameEventListenerIDGenerator()
    return GameGlobal:GetInstance().gameEventListenerIDGenerator
end

---@return GameEventDispatcher
function GameGlobal.EventDispatcher()
    return GameGlobal:GetInstance().gameEventDispatcher
end

---@param gameModuleType GameModule

---@param uiModuleType UIModule

function GameGlobal:AddUIModule(gameModuleType, uiModuleType)
    local uiModule = uiModuleType:New()

    local gameModule = GameGlobal.GetModule(gameModuleType)

    if gameModule then
        gameModule["uiModule"] = uiModule
    else
        Log.fatal("GameGlobal:AddUIModule Fail, no game module ", gameModuleType._className)
    end

    -- self.uiModules[type._className] = ui_module
end

---@generic T:UIModule, K:GameModule

---@param gameModuleType K

---@return T

function GameGlobal.GetUIModule(gameModuleType)
    return GameGlobal.GetModule(gameModuleType).uiModule
end
function GameGlobal.IsInHomeLand()
    local homeModule = GameGlobal.GetUIModule(HomelandModule)
    if (homeModule == nil) then
        return false
    end
    local homeClient = homeModule:GetClient()
    if (homeClient == nil) then
        return false
    else
        return true
    end
end
---@return UnityEngine.Input

function GameGlobal.EngineInput()
    return GameGlobal:GetInstance().engineInput
end

--停止update

function GameGlobal:StopCoreGame()
    if self.coreGame then
        self.coreGame:Stop()
    end
end

function GameGlobal:IsCoreGameRunning()
    if (self.coreGame == nil) then
        return false
    else
        return self.coreGame:Running()
    end
end

function GameGlobal:ExitCutsceneGame()
    if self.cutsceneGame then
        self.taskManager:KillCoreGameTasks()
        self.cutsceneGame:Stop()
        self.cutsceneGame:Dispose()
        self.cutsceneGame = nil

        --gc start
        HelperProxy:GetInstance():GCCollect()
        collectgarbage("collect")
        HelperProxy:GetInstance():GCCollect()
        collectgarbage("collect")
    end
end

function GameGlobal:ExitCoreGame()
    self.taskManager:KillCoreGameTasks()
    Log.debug("GameGlobal:ExitCoreGame", Log.traceback())
    if self.coreGame then
        --gc finish
        self.coreGame:Stop()

        self.coreGame:CloseCoreGameCamera()

        self.coreGame:Dispose()

        self.coreGame = nil

        AudioHelperController.ClearInnerGameAudio()
        self:StartChangeCacheLevelTask(CacheResLevel.Empty)

        --gc start
        HelperProxy:GetInstance():GCCollect()
        collectgarbage("collect")
        HelperProxy:GetInstance():GCCollect()
        collectgarbage("collect")
        if not USEADX2AUDIO then
            AudioHelper.CacheCommonUISound()
        end
        --离开测试对局
        if EDITOR then
            self.GetModule(AutoTestModule):ExitCoreGame()
            self.GetModule(FakeMatchModule):ExitCoreGame()
            self.GetModule(AIDebugModule):ClearAIDebugInfo()
        end
    else
        Log.notice("GameGlobal:ExitCoreGame coreGame nil")
    end
end

function GameGlobal:EnterCoreGame(enterData, enterPreferenceData)
    Log.debug("EnterCoreGame() traceback:", debug.traceback())
    if self.coreGame ~= nil then
        Log.debug("duplicate coregame")
        self:ExitCoreGame()
    end

    if not USEADX2AUDIO then
        AudioHelper.UnloadCommonUISound()
    end
    UnityEngine.Input.multiTouchEnabled = false
    self.coreGame = MatchCoreGameEntry:New(enterData, enterPreferenceData)
    self.coreGame:InitalizeCoreGame()

    self:GetCollector("CoreGameLoading"):Sample("EnterCoreGame()")
end

function GameGlobal:EnterCutscene(levelID)
    if self.cutsceneGame ~= nil then
        Log.debug("duplicate cutscene")
        return
    end

    if not USEADX2AUDIO then
        AudioHelper.UnloadCommonUISound()
    end
    UnityEngine.Input.multiTouchEnabled = false
    ---@type CutsceneGameEntry
    self.cutsceneGame = CutsceneGameEntry:New(levelID)
    self.cutsceneGame:InitalizeCoreGame()

    self:GetCollector("CutsceneGameLoading"):Sample("EnterCutsceneGame()")
end

function GameGlobal:CoreGameStateID()
    if self.coreGame == nil or self.coreGame:Running() == false then
        return GameStateID.Invalid
    end

    if self.coreGame.GetCurWorldStateID then
        return self.coreGame:GetCurWorldStateID()
    end

    return GameStateID.Invalid
end

---给UI使用，是否可以点击头像预览

function GameGlobal:IsInputEnable()
    if self.coreGame == nil or self.coreGame:Running() == false then
        return false
    end

    if self.coreGame.GetCurWorldStateID then
        return self.coreGame:InputEnalbe()
    end

    return false
end
function GameGlobal:IsLinkLineState()
    if self.coreGame == nil or self.coreGame:Running() == false then
        return false
    end
    if self.coreGame.GetCurWorldStateID then
        return self.coreGame:IsLinkLineState()
    end
    return false
end

function GameGlobal:GetMainWorld()
    if self.coreGame then
        local filename = debug.getinfo(2, "S").short_src
        if string.find(filename, "ui_.*%.lua") then
            --禁止UI访问world，作弊界面不处理
            local splitFilename = string.split(filename, "/")
            local lastFilename = splitFilename[#splitFilename]
            if not string.find(filename, "ui_battle_cheat") then
                Log.error("battle ui get world!!")
                return nil
            end
        end
        return self.coreGame.clientWorld
    end
end
function GameGlobal.StartProfiler()
    return GameGlobal:GetInstance().luaProfiler:Start()
end
function GameGlobal.StopProfiler()
    return GameGlobal:GetInstance().luaProfiler:Stop()
end

function GameGlobal:AddCollector(title)
    local collector = ProfileCollector:New(title)
    self._collectors[title] = collector
    return collector
end

function GameGlobal:GetCollector(title)
    local ret = self._collectors[title]
    if not ret then
        ret = self:AddCollector(title)
    end
    return ret
end

--异步加载资源
function GameGlobal:StartChangeCacheLevelTask(level)
    self.taskManager:StartTask(self.donotDestroyRes.ChangeCacheLevel, self.donotDestroyRes, level)
end

function GameGlobal.DonotDestroyRes()
    return GameGlobal:GetInstance().donotDestroyRes
end

function GameGlobal.GameRecorder()
    return GameGlobal:GetInstance().gameRecorder
end

-- UA渠道打点上报（不含INTL)
---@param uaEventName string
---@param paramsDic table
---@param extraJson string
---@param isRealTime bool
function GameGlobal.UAReportChannelEvent(uaEventName, paramsDic, extraJson, isRealTime)
    if isRealTime == nil then
        isRealTime = true
    end
    local l_paramDic = UAReportHelper.GetParamsDic()
    l_paramDic:Clear()
    if paramsDic ~= nil then
        for key, value in pairs(paramsDic) do
            l_paramDic:Add(key, value)
        end
    end
    UAReportHelper.UAReportChannelEvent(uaEventName, l_paramDic, extraJson or "", isRealTime)
end

-- UA打点上报(含intl和app_config.json中配置的渠道)
---@param uaEventName string
---@param paramsDic table
---@param extraJson string
---@param isRealTime bool
function GameGlobal.UAReportEvent(uaEventName, paramsDic, extraJson, isRealTime)
    if isRealTime == nil then
        isRealTime = true
    end
    local l_paramDic = UAReportHelper.GetParamsDic()
    l_paramDic:Clear()
    if paramsDic ~= nil then
        for key, value in pairs(paramsDic) do
            l_paramDic:Add(key, value)
        end
    end
    UAReportHelper.UAReportEvent(uaEventName, l_paramDic, extraJson or "", isRealTime)
end

-- 是否是新手引导结束上报打点指定关卡1-3
function GameGlobal.IsUAReportCompleteTutorialMission(mission_id)
    -- if (H3DGCloudLuaHelper.MsdkStatus == MSDKStatus.MS_Inland) then
    --     GCloud.MSDK.MSDKWebView.OpenUrl(url)
    -- elseif (H3DGCloudLuaHelper.MsdkStatus == MSDKStatus.MS_International) then
    --新手引导结束上报打点指定关卡1-3
    if mission_id == EFirstPassCanIgnorPowerMission.EFirstPassCanIgnorPowerMission_1_3 then
        return true
    end
    return false
end

-- INTL上报自定义事件
function GameGlobal.ReportCustomEvent(strEventName, strCustomEventName, paramsList, extraJson)
    local l_paramList = UAReportHelper.GetParamsList()
    l_paramList:Clear()
    if paramsList ~= nil then
        for index, value in ipairs(paramsList) do
            l_paramList:Add(value)
        end
    end
    UAReportHelper.ReportCustomEvent(strEventName, strCustomEventName, l_paramList, extraJson or "")
end

-- UA打点上报 强制引导阶段数据
---@param uaEventName string
---@param paramsList ArrayList
---@param bAddMissionId bool
---@param bAddMatchMissionId bool
function GameGlobal.UAReportForceGuideEvent(uaEventName, paramsList, bAddMissionId, bAddMatchMissionId)
    local l_role_module = GameGlobal.GetModule(RoleModule)
    -- 已过了UA打点上报强引导关卡 就不要上报了
    if not l_role_module or l_role_module:CheckModuleUnlock(GameModuleID.MD_ForceGuideEnd) then
        return
    end

    local time_mod = GameGlobal.GameLogic():GetModule(SvrTimeModule)
    if time_mod == nil then
        Log.error("UAReportForceGuideEvent time_mod == nil")
        return
    end

    local l_paramList = UAReportHelper.GetParamsList()
    l_paramList:Clear()

    local tmSecond = math.floor(time_mod:GetServerTime() / 1000)

    l_paramList:Add(tmSecond)

    if bAddMatchMissionId then
        local match = GameGlobal.GetModule(MatchModule)
        if match then
            local enterData = match:GetMatchEnterData()
            if enterData and enterData._match_type == MatchType.MT_Mission then --主线
                local missionID = enterData:GetMissionCreateInfo().mission_id
                l_paramList:Add(missionID)
            end
        end
    end

    -- 增加当前主线进度
    if bAddMissionId then
        local mission_module = GameGlobal.GetModule(MissionModule)
        if mission_module then
            l_paramList:Add(mission_module:GetCurMissionID())
        end
    end

    if paramsList ~= nil then
        for index, value in ipairs(paramsList) do
            l_paramList:Add(value)
        end
    end

    UAReportHelper.ReportCustomEvent("ForceGuide", uaEventName, l_paramList, "")
end

function GameGlobal:GetFrameCount()
    return 0
end

function GameGlobal:IsOfflineMatch()
    return self._isOfflineMatch
end

function GameGlobal:SetOfflineMatch(v)
    self._isOfflineMatch = v
end
