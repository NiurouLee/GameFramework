--拜访client
---@class HomelandVisitClient:Object
_class("HomelandVisitClient", Object)
HomelandVisitClient = HomelandVisitClient

function HomelandVisitClient:Constructor()
    LogWrapper.LogDebug("拜访家园初始化")
    ---@type UIHomelandMinimapManager
    self._minimapManager = UIHomelandMinimapManager:New()
    ---@type HomelandSceneManager 场景管理器
    self._sceneManager = HomelandSceneManager:New()
    ---@type InteractPointManager
    self._interactPointManager = InteractPointManager:New()
    ---@type HomeBuildManager
    self._buildManager = HomeBuildManager:New()
    ---@type HomelandCharacterManager 角色管理器
    self._characterManager = HomelandCharacterManager:New()
    ---@type HomelandCameraManager 相机管理器
    self._cameraManager = HomelandCameraManager:New()
    ---@type HomelandInputManager 输入管理器
    self._inputManager = HomelandInputManager:New()
    ---@type HomelandPetManager 光灵管理器
    self._petManager = HomelandPetManager:New()

    ---@type HomelandEventManager 事件管理器
    -- self._eventManager = HomelandEventManager:New()

    ---@type Home3DUIManager _3DUI管理器
    self._3duiManager = Home3DUIManager:New()
    ---@type HomelandFishingManager
    -- self._homelandFishingManager = HomelandFishingManager:New()

    -- ---@type HomelandTreeCuttingManager
    -- self._treeCuttingManager = HomelandTreeCuttingManager:New()

    -- ---@type HomelandTreasureManager
    -- self._homelandTrasureManager = HomelandTreasureManager:New()
    -- ---@type HomelandFindTreasureManager
    -- self._homelandFindTreasureManager = nil --不在这里构造
    -- ---@type HomelandMiningManager
    -- self._homelandMiningManager = HomelandMiningManager:New()

    ---@type HomelandSceneEffectManager
    self._homelandSceneEffectManager = HomelandSceneEffectManager:New()
    ---@type HomelandPetInviteManager
    self._homelandPetInviteManager = HomelandPetInviteManager:New()
    self._mode = HomelandMode.Normal
end

function HomelandVisitClient:Init(TT)
    ---@type number 上一次update的tick
    self._lastTick = GameGlobal:GetInstance():GetLastTimeMS()
    self._sceneManager:Init()
    self._interactPointManager:Init(self)
    self._buildManager:Init(TT, self)
    self._characterManager:Init(self)
    self._cameraManager:Init(self)
    self._inputManager:Init(self)
    self._petManager:Init(self)

    -- self._eventManager:Init(self)

    self._3duiManager:Init(self)

    self._homelandSceneEffectManager:Init(self)
    self._homelandPetInviteManager:Init(self)
    AudioHelperController.PlayBGM(CriAudioIDConst.BGMEnterHomeland, AudioConstValue.BGMCrossFadeTime)
    -- self._homelandFishingManager:Init(self)
    -- self._treeCuttingManager:Init(self)
    -- self._homelandTrasureManager:Init(self)
    -- self._homelandFindTreasureManager = HomelandFindTreasureConst.InitHomelandFindTreausre(self)
    -- self._homelandMiningManager:Init(self)
    --测试代码
    -- local build = BuildBase:New()
    -- self._interactPointManager:AddBuildInteractArea(build)
    -- self._interactPointManager:AddBuildInteractPoint(build, 1, 1)
    -- self._interactPointManager:AddBuildInteractPoint(build, 1, 2)
end

function HomelandVisitClient:OnEnterHomeland()
    -- self._homelandTrasureManager:OnEnterHomeland()
    --每日好感度增加
    -- local module = GameGlobal.GetModule(HomelandModule)
    -- if module:IsPopDormitoryTips() then
    --     ---@type dormitoryInfo
    --     local info = module:GetHomelandInfo().dormitory_info
    --     local petID = nil
    --     local count = 0
    --     for i, domi in ipairs(info.list) do
    --         if domi.bBulid then
    --             for _, pstid in ipairs(domi.petList) do
    --                 if pstid > 0 then
    --                     if not petID then
    --                         petID = pstid
    --                     end
    --                     count = count + 1
    --                 end
    --             end
    --         end
    --     end
    --     local pet = GameGlobal.GetModule(PetModule):GetPet(petID)
    --     local icon = HelperProxy:GetInstance():HomeGetBody(petID)
    --     local name = StringTable.Get(pet:GetPetName())
    --     local param = {icon, StringTable.Get("str_homeland_domitory_affinity_is_added", name, count)}
    --     GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips, UIHomeEventTipsType.PetBody, param)
    -- end
end

--进入家园后第一次显示完主ui
function HomelandVisitClient:AfterHomelandUIShow()
    if self._isMainUIShown then
        return
    end
    self._isMainUIShown = true
    -- if not self:IsVisit() then
    --     --每日好感度增加
    --     local module = GameGlobal.GetModule(HomelandModule)
    --     if module:IsPopDormitoryTips() then
    --         ---@type dormitoryInfo
    --         local info = module:GetHomelandInfo().dormitory_info
    --         local petID = nil
    --         local count = 0

    --         for i = 1, 4 do
    --             ---@type dormitory_room
    --             local room = info.list[i]
    --             if room and room.bBulid then
    --                 for _, pstid in pairs(room.hasAddFaPetList) do
    --                     if pstid > 0 then
    --                         if not petID then
    --                             petID = pstid
    --                         end
    --                         count = count + 1
    --                     end
    --                 end
    --             end
    --         end

    --         if not petID then
    --             Log.exception("获取不到增加了好感度的星灵")
    --             return
    --         end

    --         local pet = GameGlobal.GetModule(PetModule):GetPet(petID)
    --         local icon = HelperProxy:GetInstance():HomeGetBody(petID)
    --         local name = StringTable.Get(pet:GetPetName())
    --         local param = {icon, StringTable.Get("str_homeland_domitory_affinity_is_added", name, tostring(count))}
    --         GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips, UIHomeEventTipsType.PetBody, param)
    --     end
    -- end
end

function HomelandVisitClient:Dispose()
    self._minimapManager:Destroy()
    self._minimapManager = nil
    -- self._homelandMiningManager:Dispose()
    -- if self._homelandFindTreasureManager then
    --     self._homelandFindTreasureManager:Destroy()
    -- end
    -- self._homelandTrasureManager:Dispose()
    -- self._treeCuttingManager:Dispose()
    -- self._homelandFishingManager:Dispose()
    self._3duiManager:Dispose()
    -- self._eventManager:Dispose()
    self._petManager:Dispose()
    self._inputManager:Dispose()
    self._cameraManager:Dispose()
    self._characterManager:Dispose()
    self._buildManager:Dispose()
    self._interactPointManager:Dispose()
    self._sceneManager:Dispose()
    self._homelandSceneEffectManager:Dispose()
    self._homelandPetInviteManager:Dispose()
    LogWrapper.LogDebug("家园销毁")
end

function HomelandVisitClient:Update(curTick)
    local deltaTimeMS = curTick - self._lastTick
    self._lastTick = curTick

    self._inputManager:Update(deltaTimeMS)

    if self._mode == HomelandMode.Normal then
        self._characterManager:Update(deltaTimeMS)
        self._interactPointManager:Update(deltaTimeMS)
        self._petManager:Update(deltaTimeMS)

        self._cameraManager:Update(deltaTimeMS)
    elseif self._mode == HomelandMode.Build then
    end
    if self._minimapManager then
        self._minimapManager:Update(deltaTimeMS)
    end

    if self._homelandSceneEffectManager then
        self._homelandSceneEffectManager:Update(deltaTimeMS)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUpdatePerFrame)
end
---当前模式
---@return HomelandMode
function HomelandVisitClient:CurrentMode()
    return self._mode
end

--进入建造模式
function HomelandVisitClient:StartBuild()
    BuildLog("开始建造")
    --TODO:建造前处理
    -- self._mode = HomelandMode.Build
    -- self._inputManager:OnModeChanged(self._mode)
    -- self._cameraManager:OnModeChanged(self._mode)
    -- self._petManager:OnModeChanged(self._mode)
    -- self._characterManager:OnModeChanged(self._mode)

    -- self._buildManager:OnModeChanged(self._mode)
    Log.exception("拜访模式不可建造")
end

--退出建造模式
function HomelandVisitClient:FinishBuild()
    BuildLog("停止建造")
    -- self._mode = HomelandMode.Normal
    -- self._buildManager:OnModeChanged(self._mode)
    -- --TODO:建造后恢复
    -- self._inputManager:OnModeChanged(self._mode)
    -- self._cameraManager:OnModeChanged(self._mode)
    -- self._petManager:OnModeChanged(self._mode)
    -- self._characterManager:OnModeChanged(self._mode)
    Log.exception("拜访模式不可停止建造")
end
function HomelandVisitClient:BeginStory()
    -- self._mode = HomelandMode.Story
    -- self._buildManager:OnModeChanged(self._mode)
    -- self._inputManager:OnModeChanged(self._mode)
    -- self._cameraManager:OnModeChanged(self._mode)
    -- self._petManager:OnModeChanged(self._mode)
    -- self._characterManager:OnModeChanged(self._mode)
    Log.exception("拜访不可进入剧情模式")
end
function HomelandVisitClient:EndStory()
    -- self._mode = HomelandMode.Normal
    -- self._buildManager:OnModeChanged(self._mode)
    -- self._inputManager:OnModeChanged(self._mode)
    -- self._cameraManager:OnModeChanged(self._mode)
    -- self._petManager:OnModeChanged(self._mode)
    -- self._characterManager:OnModeChanged(self._mode)
    Log.exception("拜访不可退出剧情模式")
end

function HomelandVisitClient:FishingManager()
    Log.exception("拜访模式不可访问FishingManager")
    -- return self._homelandFishingManager
end

---@return HomelandSceneManager
function HomelandVisitClient:SceneManager()
    return self._sceneManager
end

function HomelandVisitClient:CharacterManager()
    return self._characterManager
end

function HomelandVisitClient:CameraManager()
    return self._cameraManager
end

function HomelandVisitClient:InputManager()
    return self._inputManager
end

---@return InteractPointManager
function HomelandVisitClient:InteractPointManager()
    return self._interactPointManager
end

---@return HomeBuildManager
function HomelandVisitClient:BuildManager()
    return self._buildManager
end
---@return HomelandPetManager
function HomelandVisitClient:PetManager()
    return self._petManager
end

---@return Home3DUIManager
function HomelandVisitClient:Home3DUIManager()
    return self._3duiManager
end

---@return TreasureManager
function HomelandTreasureManager:TreasureManager()
    Log.exception("拜访模式不可访问TreasureManager")
    -- return self._treasureManager
end

---@return HomelandTreeCuttingManager
function HomelandVisitClient:TreeCuttingManager()
    Log.exception("拜访模式不可访问TreeCuttingManager")
    -- return self._treeCuttingManager
end

function HomelandVisitClient:OpenPetInteract(pet)
    Log.exception("拜访模式不可与星灵交互")
    -- GameGlobal.UIStateManager():ShowDialog("UIHomePetInteract", pet)
    -- self._inputManager:GetControllerChar():SetActive(false)
end

---@return HomelandEventManager
function HomelandVisitClient:HomeEventManager()
    Log.exception("拜访模式不可访问HomeEventManager")
    -- return self._eventManager
end

function HomelandVisitClient:FindTreasureManager()
    Log.exception("拜访模式不可访问FindTreasureManager")
    -- return self._homelandFindTreasureManager
end

function HomelandVisitClient:HomelandMiningManager()
    Log.exception("拜访模式不可访问HomelandMiningManager")
    -- return self._homelandMiningManager
end

function HomelandVisitClient:IsVisit()
    return true
end
function HomelandVisitClient:GetMinimapManager()
    return self._minimapManager
end

--
function HomelandVisitClient:GetHomelandSceneEffectManager()
    return self._homelandSceneEffectManager
end
-- 适配 HomelandPetInviteManager
function HomelandVisitClient:GetHomelandTaskManager() 
    return nil
end 

function HomelandVisitClient:GetHomelandPetInviteManager()
    return  self._homelandPetInviteManager
    -- return self._homelandMiningManager
end
