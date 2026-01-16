---@class UIAircraftController:UIController
_class("UIAircraftController", UIController)
UIAircraftController = UIAircraftController

function UIAircraftController:OnShow(uiParams)
    AirLog("UIAircraftController OnShow Start")

    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIAircraft)
    self.guideFingerOffset = Vector3(0, 300, 0)
    self.fingerShow = false
    self.sceneRes = uiParams[1]
    ---@type AircraftModule
    self._module = self:GetModule(AircraftModule)
    self:Init(uiParams)

    UIBgmHelper.PlyAircraftBgm()
    --容错
    if self._main ~= nil then
        self.active = true
    end

   self:RefrshEasyEntryBtns()

    AirLog("UIAircraftController OnShow Done")
end


function UIAircraftController:RefrshEasyEntryBtns()
     --快捷入口
     local makeState = self._module:GetRoomStatus(AirRoomType.SmeltRoom)
     local lock = not makeState or makeState < SpaceState.SpaceStateFull
     self._btnMake:SetActive(not lock)
 

     local sendState = self._module:GetRoomStatus(AirRoomType.DispatchRoom)
     local lock = not sendState or sendState < SpaceState.SpaceStateFull
     self._btnSend:SetActive(not lock)
     if not lock then
        --刷新派遣室内红点
        self:RefreshEasyBtnsRed()
     end
end

function UIAircraftController:RefreshEasyBtnsRed()
    local redCount = self:CalcDispachRoomRedCount()
    self._sendRed:SetActive(redCount > 0)
    if redCount > 0 then
        self._txtSendRedNum:SetText(redCount)
    end
end

function UIAircraftController:CalcDispachRoomRedCount()
    local room = self._module:GetRoomWithType(AirRoomType.DispatchRoom)
    if not room then
        return 0
    end

    --可派次数
    local dispatchCount = room:GetDispatchCount()

    --可派队伍数
    local dispatchTeamCount = room:GetDispatchTeamCount()
    local roomCfg = room:GetRoomConfig()
    local lessTeamCount = roomCfg.TeamMax - dispatchTeamCount

    --可派星灵数
    local lessPetCount = math.modf((table.count(room:GetDispatchPetList()) / 5) + 0.05)

    --取最小值
    local showNumber = dispatchCount
    if lessTeamCount < showNumber then
        showNumber = lessTeamCount
    end
    if lessPetCount < showNumber then
        showNumber = lessPetCount
    end

    if room:HasCompleteTask() or showNumber > 0 then
        local addCount = room:GetCompleteCount()
        showNumber = showNumber + addCount
    end                 

    return showNumber
end

---@param paramType OpenAircraftParamType
function UIAircraftController:Init(uiParams)
    AirLog("UIAircraftController Init Start")
    self._guideFingerRect = self:GetUIComponent("RectTransform", "guideFinger")
    self:ShowGuideFinger(false)

    --Full
    self._fullGo = self:GetGameObject("Full")
    self._blackMask = self:GetGameObject("mask")
    self._btnDecorate = self:GetGameObject("BtnDecorate")

    --randomStory
    ---@type UnityEngine.UI.Image
    self._randomStoryBlackMask = self:GetUIComponent("Image", "randomStoryBlackMask")

    --顶条
    ---@type UICustomWidgetPool
    self._topBarLoader = self:GetUIComponent("UISelectObjectPath", "TopBarLoader")
    self._enterInteractiveLoader = self:GetUIComponent("UISelectObjectPath", "EnterInteractiveRoot")
    self._interactiveLoader = self:GetUIComponent("UISelectObjectPath", "InteractiveRoot")
    self._roomUILoader = self:GetUIComponent("UISelectObjectPath", "RoomUI")

    --region
    self._giftBtn = self:GetGameObject("giftBtn")
    self._giftNumber = self:GetUIComponent("UILocalizationText", "giftNumber")
    self._giftFillAmount = self:GetUIComponent("Image", "giftFillAmount")
    self._petHeadIcon = self:GetUIComponent("RawImageLoader", "petHead")
    self._petNameTex = self:GetUIComponent("UILocalizationText", "petName")

    --endregion

    --快捷入口
    self._btnMake = self:GetGameObject("btnMake")
    self._btnSend = self:GetGameObject("btnSend")
    self._sendRed = self:GetGameObject("sendRed")
    self._easyBtns = self:GetGameObject("easyBtns")
    self._txtSendRedNum = self:GetUIComponent("UILocalizationText", "txtSendRedNum")

    self._uiRoot = self:GetGameObject("uianim")

    ---@type UIAircraftTopBarItem
    self._topBar = self._topBarLoader:SpawnObject("UIAircraftTopBarItem")
    self._topBar:SetData(
        true,
        function()
            self:OnBack()
        end,
        function()
            local param = "UIAircraftController"
            if self._roomUI and self._roomUI:IsClosed() == false then
                local data = self._roomUI:GetRoomData()
                if data then
                    local roomType = data:GetRoomType()
                    if roomType == AirRoomType.AisleRoom then --过道
                    elseif roomType == AirRoomType.CentralRoom then --主控室
                        param = "UIAircraftCentralRoom"
                    elseif roomType == AirRoomType.PowerRoom then --能源室
                        param = "UIAircraftPowerRoom"
                    elseif roomType == AirRoomType.MazeRoom then --秘境室
                        param = "UIAircraftMazeRoom"
                    elseif roomType == AirRoomType.ResourceRoom then --资源室
                        param = "UIAircraftResourceRoom"
                    elseif roomType == AirRoomType.PrismRoom then --棱镜室
                        param = "UIAircraftPrismRoom"
                    elseif roomType == AirRoomType.TowerRoom then --灯塔室
                        param = "UIAircraftTowerRoom"
                    elseif roomType == AirRoomType.EvilRoom then --恶鬼室
                    elseif roomType == AirRoomType.PurifyRoom then --净化室
                    elseif roomType == AirRoomType.SmeltRoom then --熔炼室
                        param = "UIAircraftSmeltRoom"
                    elseif roomType == AirRoomType.DispatchRoom then --派遣室
                        param = "UIDispatchDetailController"
                    elseif roomType == AirRoomType.TacticRoom then --派遣室
                        param = "UIAircraftTactic"
                    end
                end
            end
            self:ShowDialog("UIHelpController", param)
        end,
        true,
        false
    )

    --初始化widget变量
    self._enterInteractiveWidget = nil
    self._interactiveWidget = nil

    --3d场景初始化
    -- self._uiAircraft3DManager = UIAircraft3DManager:New()
    -- self._uiAircraft3DManager:Init(self)
    self.curRoomWidget = nil
    -- self.roomWidgets = {}
    ---@type UIAircraftRoomItem 房间ui
    self._roomUI = nil

    -- self:RequestAndRefreshMainUI()
    -- self._uiAircraft3DManager:ToggleUI(true)
    -- self:RefreshMainUI()

    self:registEvent()

    self:InitDataUpdater()

    ---@type AircraftMain
    self._main = self._module:GetClientMain()
    self._input = self._main:Input()
    --摇杆在这里初始化是因为需要加载ui资源，具体逻辑在相机逻辑中执行
    local stick = self:InitJoyStick()

    local focusGo = self:GetGameObject("Focus")
    local focusText = self:GetUIComponent("UILocalizationText", "FocusText")

    focusGo:SetActive(false)
    local focusStart = function()
        focusGo:SetActive(true)
    end
    local focusing = function(t)
        focusText.text = string.format("%.1f", Mathf.Lerp(1, 10, 1 - t))
    end
    local focusEnd = function()
        focusGo:SetActive(false)
    end

    self._main:SetJoyStick(stick, focusStart, focusing, focusEnd)

    ----------------------
    --初始化导航栏
    local navMenuPool = self:GetUIComponent("UISelectObjectPath", "navMenu")
    ---@type UIAirNavMenu
    self._navMenu = navMenuPool:SpawnObject("UIAirNavMenu")
    self._navMenuGo = self:GetGameObject("navMenu")
    self._navMenu:SetData(
        self._main,
        function(room, cb)
            self:FocusRoom(room, cb)
        end,
        function(airPet)
            self:FocusPet(airPet)
        end
    )
    ----------------------

    Log.notice("[Aircraft] 风船Loading结束，显示UI")
    if GuideHelper.GuideInProgress() then
        self._main:MoveCameraToFar()
    else
        --触发了引导则不跳转
        -- cfg_jump 类型为7的有两种配置方式
        --参数修改uiParams，2-打开类型(OpenAircraftParamType)，3-打开id(focusPetTempId/gotospaceid)，4-打开参数
        if uiParams[2] then
            local paramType = uiParams[2]
            if paramType == OpenAircraftParamType.Spaceid then
                local param = uiParams[3]
                if param and param ~= 0 then
                    self:SetGotoSpaceId(param, uiParams[4])
                end
            elseif paramType == OpenAircraftParamType.Petid then
                local focusPetTempId = uiParams[3]
                if focusPetTempId then
                    local pet = self._main:GetPetByTmpID(focusPetTempId)
                    if pet then
                        self._main:FocusPet(
                            pet,
                            nil,
                            function()
                            end
                        )
                    else
                        Log.error("no find pet in aircraft petid:", focusPetTempId)
                    end
                end
            end
        end
    end

    self._btnDecorate:SetActive(self._module:IsDecorateUnLocked())
    AirLog("UIAircraftController Init Done")
end

function UIAircraftController:registEvent()
    --风船全局消息只在此处监听，传递给其他manager
    self:AttachEvent(GameEventType.AircraftRefreshMainUI, self.RefreshMainUI) --刷新整个风船数据
    self:AttachEvent(GameEventType.AircraftRefreshRoomUI, self.RefreshOneRoomUI) --刷新某一个房间的3dui
    self:AttachEvent(GameEventType.AircraftRequestDataAndRefreshMainUI, self.RequestAndRefreshMainUI) --请求并刷新整个风船数据
    self:AttachEvent(GameEventType.AircraftSettledPetChanged, self.OnCurrentRoomPetChanged) --当前房间星灵入住发生改变
    self:AttachEvent(GameEventType.SwitchToInteractiveView, self.SwitchToInteractiveView) --摄像机切换到交互模式
    -- self:AttachEvent(GameEventType.AircraftSelectPetEvent, self.ShowPetSelectedUI) --？
    -- self:AttachEvent(GameEventType.AircraftShowInteractiveUI, self.ShowInteractiveUI) --？

    self:AttachEvent(GameEventType.AircraftLeaveAircraft, self.CloseAircraft) --停止风船主逻辑循环
    self:AttachEvent(GameEventType.AircraftRefreshTopbar, self.RefreshTopBar) --刷新顶条数据
    self:AttachEvent(GameEventType.PetDataChangeEvent, self.PetDataChangeEvent)
    self:AttachEvent(GameEventType.AircraftJumpOutTo, self.JumpOutTo)
    self:AttachEvent(GameEventType.AircraftShowRoomUI, self.ReqAndShowRoomUI)

    self:AttachEvent(GameEventType.AircraftOnPetClick, self.RefreshClickPet)

    self:AttachEvent(GameEventType.ForceRemoveInteractivePets, self.ForceRemoveInteractivePets)

    self:AttachEvent(GameEventType.AircraftCleanSpace, self.ShowSpcaceClean)
    self:AttachEvent(GameEventType.AircraftBuildRoom, self.BuildRoom)
    self:AttachEvent(GameEventType.AircraftSpeedUp, self.BuildOrUpgradeSpeedup)

    --开始送礼
    self:AttachEvent(GameEventType.AircraftChangeGiftSending, self.ChangeGiftSending)
    --送礼成功
    self:AttachEvent(GameEventType.AircraftOnSendGiftSuccess, self.AircraftOnSendGiftSuccess)
    self:AttachEvent(GameEventType.SendGiftRandomStory, self.SendGiftRandomStory)

    --某个星灵有了随机事件
    self:AttachEvent(GameEventType.AirStartOneRandomEvent, self.StartOneRandomEvent)

    --Lock
    self:AttachEvent(GameEventType.AircraftUILock, self.AircraftUILock)

    self:AttachEvent(GameEventType.AircraftTryStopClickAction, self.TryStopClickAction)
    self:AttachEvent(GameEventType.CloseSendGiftBtn, self.CloseSendGiftBtn)

    self:AttachEvent(GameEventType.OpenSendGiftDiaLog, self.OpenSendGiftDiaLog)

    self:AttachEvent(GameEventType.RandomStoryStartOrEnd, self.RandomStoryStartOrEnd)

    self:AttachEvent(GameEventType.AircraftPlayDoorAnim, self.PlayDoorAnim)

    --当在风船内部需要打开某个房间
    self:AttachEvent(GameEventType.AircraftOpenRoom, self.AircraftOpenRoom)

    --导航栏控制相机
    self:AttachEvent(GameEventType.AircraftMainMoveCameraToNavMenu, self.AircraftMainMoveCameraToNavMenu)
    self:AttachEvent(GameEventType.SetCameraToNavMenuPos, self.SetCameraToNavMenuPos)
    self:AttachEvent(GameEventType.RefreshNavMenuData, self.RefreshNavMenuData)
    self:AttachEvent(GameEventType.AircraftTacticRefreshTapeList, self.RefreshNavMenuData)
    self:AttachEvent(GameEventType.SetAircraftMainUI, self.SetMainUIActive)

    self:AttachEvent(GameEventType.AircraftDeletePet, self.AircraftDeletePet)
    self:AttachEvent(GameEventType.AircraftPushPetQueue, self.AircraftPushPetQueue)

    --显隐导航栏
    self:AttachEvent(GameEventType.UIAirNavMenuActive, self.UIAirNavMenuActive)

    self:AttachEvent(GameEventType.AircraftEnterDecorateMode, self.DoDerorate)

    self:AttachEvent(GameEventType.AircraftRefreshDecorateArea, self.RefreshDecorateArea)

    --如果当前房间ui已打开，则刷新一遍，没打开则return
    self:AttachEvent(GameEventType.AircraftTryRefreshRoomUI, self.TryRefreshRoomUI)

    self:AttachEvent(GameEventType.AircraftLeaveToBattle, self.LeaveToBattle)
end

function UIAircraftController:AircraftDeletePet(templateId)
    self._main:DeletePet(templateId)
end

function UIAircraftController:AircraftPushPetQueue(templateId)
    self._main:PushInQueue(templateId)
end

--初始化风船摇杆
function UIAircraftController:InitJoyStick()
    local eventListener = self:GetUIComponent("UIEventTriggerListener", "joyStick")
    local image = self:GetUIComponent("Image", "Viewport")
    local content = self:GetUIComponent("RectTransform", "Content")
    local resetBtn = self:GetGameObject("ResetButton")
    local atlas = self:GetAsset("UIAircraftMainUI.spriteatlas", LoadType.SpriteAtlas)
    local normal = atlas:GetSprite("wind_tongyong_btn4")
    local drag = atlas:GetSprite("wind_tongyong_btn5")
    return UIAircraftJoyStick:New(eventListener, image, normal, drag, content, resetBtn)
end

function UIAircraftController:CloseSendGiftBtn()
    self._giftBtn:SetActive(false)
end

function UIAircraftController:SendGiftRandomStory(storyid)
    self._main:SendGiftRandomStory(storyid)
end

function UIAircraftController:SetMainUIActive(active)
    self._uiRoot:SetActive(active)
    if active then
        if self:CheckAirNavMenuCanActive() then
            self:UIAirNavMenuActive(true)
        end
    else
        self:UIAirNavMenuActive(false)
    end
end

function UIAircraftController:OnHide()
    --销毁3dmanager
    self.sceneRes:Dispose()

    -- self._uiAircraft3DManager:Destory()
    -- self._uiAircraft3DManager = nil

    GameGlobal.Timer():CancelEvent(self.d_dataUpdater)
    self.d_dataUpdater = nil

    --析构
    -- self._main:Dispose()
    -- self._module:SetClientMain(nil)
end

function UIAircraftController:AircraftUILock(lock, lockName)
    if lock then
        self:Lock(lockName)
    else
        self:UnLock(lockName)
    end
end

--退出风船，跳转到什么敌方由func决定
function UIAircraftController:JumpOutTo(func)
    self:CloseAircraft()
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft_Exit, "UI", func)
end

--退出风船到主界面
function UIAircraftController:LeaveAircraft()
    self:CloseAircraft()
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft_Exit, "UI")
end

--从风船进局前析构所有逻辑
function UIAircraftController:LeaveToBattle()
    AirLog("进局析构风船逻辑")
    self:CloseAircraft()
    self._main:Dispose()
    self._main = nil
    self._module:SetClientMain(nil)
    self._module:PushLeaveAircraft()
end

function UIAircraftController:OnUpdate(deltaTimeMS)
    if not self.active then
        return
    end

    -- self._uiAircraft3DManager:Update(deltaTimeMS)
    self._main:Update(deltaTimeMS)

    if self._interactiveWidget ~= nil and self._interactiveWidget:GetGameObject().activeInHierarchy then
        self._interactiveWidget:Update(deltaTimeMS)
    end
    if self.fingerShow then
        local petTrans = self:GetPetTransform()
        if petTrans then
            local pos = self:ConvertPos(petTrans)
            self._guideFingerRect.anchoredPosition = pos
        end
    end

    if self._navMenu then
        self._navMenu:Update(deltaTimeMS)
    end
end
function UIAircraftController:ConvertPos(petTrans)
    local camera = self._main:GetMainCamera()
    local screenPos = camera:WorldToScreenPoint(petTrans.position) + self.guideFingerOffset
    local sw = ResolutionManager.ScreenWidth()
    local rw = ResolutionManager.RealWidth()
    local factor = rw / sw
    local sx, sy = screenPos.x * factor, screenPos.y * factor
    screenPos = Vector2(sx, sy)
    return screenPos
end

function UIAircraftController:ShowGuideFinger(show)
    if self.isShowFinger ~= nil and self.isShowFinger == show then
        return
    end
    self.isShowFinger = show
    self._guideFingerRect.gameObject:SetActive(self.isShowFinger)
    if self.isShowFinger == false then
        self.petKey = nil
    end
end

--选择精灵处理函数
function UIAircraftController:ShowPetSelectedUI(room, targetPet)
    if self._enterInteractiveWidget == nil then
        self._enterInteractiveWidget = self._enterInteractiveLoader:SpawnObject("UIAircraftRoomEnterInteractiveItem")
    end
    self._enterInteractiveWidget:Refresh(self, room, targetPet)
    self._enterInteractiveWidget:GetGameObject():SetActive(true)
end

--显示交互模式ui
function UIAircraftController:ShowInteractiveUI(room, targetPet)
    if self._interactiveWidget == nil then
        self._interactiveWidget = self._interactiveLoader:SpawnObject("UIAircraftRoomInteractiveItem")
    end
    self._interactiveWidget:Refresh(room, targetPet)
    self._interactiveWidget:GetGameObject():SetActive(true)
    self:CheckGuideFinger(targetPet)
    self.fingerShow = true
end

function UIAircraftController:SwitchToInteractiveView(room, targetPet)
    local topBarGo = self:GetGameObject("TopBarLoader")
    if topBarGo then
        topBarGo:SetActive(false)
    end
    local centerRoomGo = self:GetGameObject("RoomUI")
    if centerRoomGo then
        centerRoomGo:SetActive(false)
    end

    -- self._uiAircraft3DManager:SwitchToInteractiveView(room, targetPet)
end

function UIAircraftController:InteractiveViewSwitchToRoomView(room, targetPet)
    -- self._uiAircraft3DManager:InteractiveViewSwitchToRoomView(room, targetPet)
    self.fingerShow = false
    self.isShowFinger = false
    self._guideFingerRect.gameObject:SetActive(false)
end

function UIAircraftController:InteractiveViewSwitchToRoomViewComplete()
    local topBarGo = self:GetGameObject("TopBarLoader")
    if topBarGo then
        topBarGo:SetActive(true)
    end
    local centerRoomGo = self:GetGameObject("RoomUI")
    if centerRoomGo then
        centerRoomGo:SetActive(true)
    end
end

--停止风船主循环
function UIAircraftController:CloseAircraft()
    if not self.active then
        Log.fatal("already close aircraft")
        return
    end

    self.active = false

    --停止主逻辑时立刻取消所有事件
    self:DetachAllEvents()
end

function UIAircraftController:OnBack()
    if self._main:TryBack() then
        self:LeaveAircraft()
    end
end

function UIAircraftController:ReqAndShowRoomUI(spaceID)
    if spaceID == nil then
        if self._roomUI and not self._roomUI:IsClosed() then
            self._roomUI:Close()

            --打开导航栏
            if self:CheckAirNavMenuCanActive() then
                self:UIAirNavMenuActive(true)
            end

            self._blackMask:SetActive(false)
            if self._module:IsDecorateUnLocked() then
                self._btnDecorate:SetActive(true)
            end
        end
        return
    end

    --需要在所有刷新UI的地方请求更新整个风船数据
    GameGlobal.TaskManager():StartTask(
        self.ReqData,
        self,
        function()
            if self.active then
                local navMenuTempData = self:GetNavMenuData()

                self:ShowRoomUI(spaceID, true, navMenuTempData)

                if navMenuTempData ~= nil then
                    self:SetNavMenuData(nil)
                end
            end
        end
    )
    -- self:SetTopBarActive(true)
end

--导航栏点击入住或者升级需要添加一个打开入住升级的面板的临时数据,1-入住，2-升级
function UIAircraftController:SetNavMenuData(data)
    self._navMenuTempData = data
end
function UIAircraftController:GetNavMenuData()
    return self._navMenuTempData
end
--连点两次房间，选中并拉近
function UIAircraftController:SelectAndFocusRoom(spaceid)
    self._main:GotoSpace(spaceid, true)
    self._main:GotoSpace(spaceid, true)
end
--连点两次房间，选中并拉近
function UIAircraftController:SelectRoom(spaceid)
    self._main:GotoSpace(spaceid, false)
end

function UIAircraftController:RefreshClickPet(pstid)
    if not pstid then
        self._giftBtn:SetActive(false)
        return
    end
    local petModule = self:GetModule(PetModule)
    self._clickPet = petModule:GetPet(pstid)

    if self._clickPet then
        self._giftBtn:SetActive(true)

        local realLevel = self._clickPet:GetPetAffinityLevel()
        local realExp = self._clickPet:GetPetAffinityExp()
        local realMaxExp = self._clickPet:GetPetAffinityMaxExp(realLevel)
        local maxAffinityMaxLevel = self._clickPet:GetPetAffinityMaxLevel()

        local curExp = realExp - Cfg.cfg_pet_affinity_exp[realLevel].NeedAffintyExp
        local percent = curExp / realMaxExp

        --如果满级了，设为1
        if maxAffinityMaxLevel <= realLevel then --等级达到最大
            percent = 1
        end

        local value = percent
        self._giftFillAmount.fillAmount = value

        self._petHeadIcon:LoadImage(self._clickPet:GetPetHead(PetSkinEffectPath.HEAD_AIRCRAFT_INTERACT))
        self._petNameTex:SetText(StringTable.Get(self._clickPet:GetPetName()))

        local number = realLevel
        self._giftNumber:SetText(number)
    else
        self._giftBtn:SetActive(false)
    end
end

function UIAircraftController:giftBtnOnClick()
    --不在送礼界面调用了，防止打开界面的过程中，clickmanager的交互时间到了，交互结束了
    self:ChangeGiftSending(true)
    self:OpenSendGiftDiaLog()
end
function UIAircraftController:OpenSendGiftDiaLog()
    self:ShowDialog("UIAircraftSendGiftController", self._clickPet)
    -- self._main._clickMng._startTime = self._main._clickMng._timeOutTime
end

--交互中星灵状态改为送礼中
function UIAircraftController:ChangeGiftSending(state)
    self._fullGo:SetActive(not state)
    self._main:ChangeGiftSending(state)
end
--送礼成功
function UIAircraftController:AircraftOnSendGiftSuccess(lvup, love)
    -- 播音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundGiveGift)
    self._main:AircraftOnSendGiftSuccess(lvup, love)

    if self._clickPet then
        local realLevel = self._clickPet:GetPetAffinityLevel()
        local realExp = self._clickPet:GetPetAffinityExp()
        local realMaxExp = self._clickPet:GetPetAffinityMaxExp(realLevel)
        local maxAffinityMaxLevel = self._clickPet:GetPetAffinityMaxLevel()

        local curExp = realExp - Cfg.cfg_pet_affinity_exp[realLevel].NeedAffintyExp
        local percent = curExp / realMaxExp

        --如果满级了，设为1
        if maxAffinityMaxLevel <= realLevel then --等级达到最大
            percent = 1
        end

        local value = percent
        self._giftFillAmount.fillAmount = value

        local number = realLevel
        self._giftNumber:SetText(number)
    end
end

function UIAircraftController:ReqData(TT, callBack)
    self:Lock(self:GetName())
    local ack = self._module:AircraftUpdate(TT)
    if ack:GetSucc() then
        callBack()
    else
        ToastManager.ShowToast(self._module:GetErrorMsg(ack:GetResult()))
    end
    self:UnLock(self:GetName())
end

function UIAircraftController:RequestAndRefreshMainUI()
    Log.notice("Request aircraft data")
    --需要在所有刷新UI的地方请求更新整个风船数据
    GameGlobal.TaskManager():StartTask(
        self.ReqData,
        self,
        function()
            if self.active then
                self:RefreshMainUI()
            end
        end
    )
end

function UIAircraftController:RefreshMainUI()
    Log.notice("Refresh aircraft main ui")
    -- self._uiAircraft3DManager:SceneManager():RefreshSpaces()
    self._main:RefreshScene()

    self:RefreshNavMenuData()
    self:RefrshEasyEntryBtns()
end

--刷新一个场景内房间数据
function UIAircraftController:RefreshOneRoomUI(_spaceId)
    -- self._uiAircraft3DManager:SceneManager():RefreshOneRoomUI(_spaceId)
    self._main:RefreshRoom3DUI(_spaceId)
end

--刷新一个房间内数据
function UIAircraftController:ShowRoomUI(spaceID, _closeInfoWindow, navMenuTempData)
    local logicRoomData = self._module:GetRoom(spaceID)
    if logicRoomData == nil then
        return
    end
    -- self.room = room
    if self._roomUI == nil then
        self._roomUI = self._roomUILoader:SpawnObject("UIAircraftRoomItem")
    end
    self._roomUI:Close()
    self._roomUI:Refresh(logicRoomData, _closeInfoWindow)
    --关闭导航栏
    self:UIAirNavMenuActive(false)

    self._blackMask:SetActive(true)
    self._btnDecorate:SetActive(false)
    self._easyBtns:SetActive(false)
    -- if _closeInfoWindow then
    --     self:CheckGuideFinger()
    -- end

    --按钮上有动画
    --等待0.43秒
    if navMenuTempData ~= nil then
        self:Lock("UIAircraftController:ShowRoomUI")
        GameGlobal.Timer():AddEvent(
            440,
            function()
                self:UnLock("UIAircraftController:ShowRoomUI")
                if navMenuTempData ~= nil then
                    if navMenuTempData == 1 then
                        --打开roomui并且打开入住
                        self._roomUI:OpenEnterBuild()
                    elseif navMenuTempData == 2 then
                        --打开roomui并且打开升级
                        self._roomUI:OpenLvUp()
                    end
                end
            end
        )
    end
end

function UIAircraftController:PetDataChangeEvent()
    self:CheckGuideFinger()
end
function UIAircraftController:CheckGuideFinger(targetPet)
    -- if not self.room then
    --     self:ShowGuideFinger(false)
    --     return
    -- end
    -- local petModule = self:GetModule(PetModule)
    -- local remain = petModule:GetLeftAffinityAddCount()
    -- local max = petModule:GetMaxAffinityAddCount()
    -- if remain == max then
    --     -- local count = self.room._petList and table.count(self.room._petList)
    --     -- if count and count > 0 then
    --     --     local keys = table.keys(self.room._petList)
    --     --     local index = math.random(1, count)
    --     --     self.petKey = keys[index]
    --     -- end
    --     if targetPet then
    --         self.petKey = targetPet._petData:GetTemplateID()
    --     end
    -- else
    --     self.petKey = nil
    -- end
end

function UIAircraftController:GetPetTransform()
    -- local guidePetTrans
    -- if self.petKey and self.room then
    --     local pet = self.room._petList and self.room._petList[self.petKey]
    --     guidePetTrans = pet and pet._petGO.transform
    -- end
    -- self:ShowGuideFinger(guidePetTrans ~= nil)
    -- return guidePetTrans
end
function UIAircraftController:OnCurrentRoomPetChanged()
    -- self._uiAircraft3DManager:CurrentRoomPetChanged()
    local spaceID = self._roomUI:SpaceID()
    self._main:OnSpacePetChanged(spaceID)
    if self._roomUI then
        local data = self._module:GetRoom(spaceID)
        if data then
            self._roomUI:Refresh(data, false)
        end
        --关闭导航栏
        self:UIAirNavMenuActive(false)

        self._blackMask:SetActive(true)
        self._btnDecorate:SetActive(false)
    end
end

function UIAircraftController:SetTopBarActive(active)
    self._topBar:GetGameObject():SetActive(active)
end

function UIAircraftController:RefreshTopBar()
    self._topBar:RefreshAllMsg()
end

-- function UIAircraftController:GetMainCamera()
--     return self._main._cameraManager:GetCamera()
-- end

---@param _spaceId number 空间id
function UIAircraftController:ShowSpcaceClean(_spaceId)
    if self._roomUI and not self._roomUI:IsClosed() then
        self._roomUI:Close()
        --打开导航栏
        if self:CheckAirNavMenuCanActive() then
            self:UIAirNavMenuActive(true)
        end
        self._blackMask:SetActive(false)
        if self._module:IsDecorateUnLocked() then
            self._btnDecorate:SetActive(true)
        end
    end
    self:StartTask(self.RequestCleanSpace, self, _spaceId)
    -- self:ShowDialog("UIAircraftSpaceCleanController", _spaceId)
end

function UIAircraftController:RequestCleanSpace(TT, spaceID)
    self:Lock(self:GetName())
    ---@type AircraftModule
    local _module = self._module
    local roomType = _module:GetBuildType(spaceID)[1]

    if roomType == AirRoomType.AisleRoom then
        Log.notice("[Aircraft] 建造过道，先请求清理")
        local cleanRes, msg = _module:RequestCleanSpace(TT, spaceID)
        if not cleanRes:GetSucc() then
            ToastManager.ShowToast(_module:GetErrorMsg(cleanRes:GetResult()))
            self:UnLock(self:GetName())
            return
        end

        Log.notice("[Aircraft] 建造过道，清理成功，请求建造")
        local roomCfg = Cfg.cfg_aircraft_room {RoomType = roomType, Level = 1}
        local roomID = roomCfg[1].ID
        local buildRes = _module:RequestBuildRoom(TT, spaceID, roomID)
        if not buildRes:GetSucc() then
            ToastManager.ShowToast(_module:GetErrorMsg(buildRes:GetResult()))
            self:UnLock(self:GetName())
            return
        end
        Log.notice("[Aircraft] 建造过道成功，刷新UI")
        --建造成功
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRequestDataAndRefreshMainUI)
        local showDialog = false
        if #msg.asset > 0 then
            for _, value in ipairs(msg.asset) do
                if value.count > 0 then
                    showDialog = true
                end
            end
        end
        if showDialog then
            self:ShowDialog("UIGetItemController", msg.asset)
        end
        ToastManager.ShowToast(StringTable.Get("str_aircraft_clean_success"))
    else
        Log.notice("[Aircraft] 清理房间，ID: ", spaceID)
        local cleanRes, msg = _module:RequestCleanSpace(TT, spaceID)
        if not cleanRes:GetSucc() then
            ToastManager.ShowToast(_module:GetErrorMsg(cleanRes:GetResult()))
            self:UnLock(self:GetName())
            return
        end
        Log.notice("[Aircraft]  清理房间成功，ID: ", spaceID)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRequestDataAndRefreshMainUI)

        local showDialog = false
        if #msg.asset > 0 then
            for _, value in ipairs(msg.asset) do
                if value.count > 0 then
                    showDialog = true
                end
            end
        end
        if showDialog then
            self:ShowDialog("UIGetItemController", msg.asset)
        end
        ToastManager.ShowToast(StringTable.Get("str_aircraft_clean_success"))
    end
    self:UnLock(self:GetName())
end

--风船内需要自动增长的数据全部在此处计算，并通知其他需要的模块，暂时只有萤火
function UIAircraftController:InitDataUpdater()
    local d_curFireFly = math.floor(self._module:GetFirefly())
    local d_atom = GameGlobal.GetModule(RoleModule):GetAtom()

    self.d_dataUpdater =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()            
            ---@type RoleModule
            local roleModule = GameGlobal.GetModule(RoleModule)
            ---@type AircraftModule
            local airModule = GameGlobal.GetModule(AircraftModule)
            if (roleModule == nil) or (airModule == nil) or (airModule:GetAircraftInfo() == nil) then
                -- 如果玩家与服务器断开连接返回主界面的时候 有可能会先初始化Module然后再调用OnHide导致找不到数据的情况
                return
            end
            --萤火
            local curFire = math.floor(airModule:GetFirefly())
            if curFire ~= d_curFireFly then
                d_curFireFly = curFire
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnFireFlyChanged)
            end
            
            --原子剂
            if airModule:GetSmeltRoom() then
                local count = roleModule:GetAtom()
                if count ~= d_atom then
                    d_atom = count
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnAtomChanged)
                end
            end
        end
    )
end

function UIAircraftController:RandomStoryStartOrEnd(look, timeLength)
    if look then
        self._randomStoryBlackMask.gameObject:SetActive(true)

        self._randomStoryBlackMask:DOColor(Color(0, 0, 0, 1), timeLength * 0.001)
    else
        self._randomStoryBlackMask.color = Color(0, 0, 0, 0)

        self._randomStoryBlackMask.gameObject:SetActive(false)
    end
end

--某个星灵有了随机事件
---@param pet number
function UIAircraftController:StartOneRandomEvent(storyid)
    self._main:StartOneRandomEvent(storyid)
end

function UIAircraftController:BuildRoom(_spaceId)
    if self._roomUI and not self._roomUI:IsClosed() then
        self._roomUI:Close()
        --打开导航栏
        if self:CheckAirNavMenuCanActive() then
            self:UIAirNavMenuActive(true)
        end
        self._blackMask:SetActive(false)
        if self._module:IsDecorateUnLocked() then
            self._btnDecorate:SetActive(true)
        end
    end
    self:ShowDialog("UIAircraftBuildRoomController", _spaceId)
end

function UIAircraftController:BuildOrUpgradeSpeedup(spaceID, option)
    if self._roomUI and not self._roomUI:IsClosed() then
        self._roomUI:Close()
        --打开导航栏
        if self:CheckAirNavMenuCanActive() then
            self:UIAirNavMenuActive(true)
        end
        self._blackMask:SetActive(false)
        if self._module:IsDecorateUnLocked() then
            self._btnDecorate:SetActive(true)
        end
    end
    self:ShowDialog("UIAircraftFireflySpeedupController", spaceID, option)
end

--聚焦到房间
function UIAircraftController:FocusRoom(room, cb)
    self._main:FocusRoom(room, cb)
end

--聚焦到星灵
function UIAircraftController:FocusPet(airPet)
    self._main:FocusPet(airPet)
end

function UIAircraftController:SetGotoSpaceId(spaceId, param)
    -- self.gotoSpaceId = spaceId
    self._main:SetGotoSpaceId(spaceId, param)
end
-- function UIAircraftController:GetGotoSpaceId()
--     return self.gotoSpaceId
-- end

-- function UIAircraftController:GotoSpace(spaceId)
--     self._main._sceneManager:SelectRoom(spaceId, false)
--     -- self._uiAircraft3DManager:SceneManager():GotoSpace(spaceId)
-- end

------------------- guide -----------------
function UIAircraftController:GetFireIcon()
    return self._topBar and self._topBar.fireFlyItem:GetGameObject()
end

function UIAircraftController:GetStarIcon()
    return self._topBar and self._topBar.energyItem:GetGameObject()
end

function UIAircraftController:GetRoomLeftBottom()
    return self._roomUI and self._roomUI:GetRoomInfoGameobject()
end

-- 房间设施按钮
function UIAircraftController:GetRoomInfoBtnFacility()
    return self._roomUI and self._roomUI._roomInfo and self._roomUI._roomInfo:GetGameObject("ButtonFacility")
end

-- 房间入驻按钮
function UIAircraftController:GetRoomInfoBtnSettle()
    return self._roomUI and self._roomUI._roomInfo and self._roomUI._roomInfo:GetGameObject("ButtonSettle")
end

-- 房间入驻cell +号
function UIAircraftController:GetRoomInfoAddCell(index)
    return self._roomUI and self._roomUI._roomInfo and self._roomUI._roomInfo:GetItem(index)
end

-- 房间入驻cell +号
function UIAircraftController:GetRoomInfoBtnLevelUp()
    return self._roomUI and self._roomUI._roomInfo and self._roomUI._roomInfo:GetGameObject("ButtonLevelUp")
end

function UIAircraftController:ForceRemoveInteractivePets(pstidList)
    self._main:ForceRemoveInteractivePets(pstidList)
end

function UIAircraftController:TryStopClickAction()
    self._main:StopInteraction()
end

function UIAircraftController:AircraftOpenRoom(type, spaceid, param)
    if type == OpenAircraftParamType.Spaceid then
        self:SetGotoSpaceId(spaceid, param)
    end
end

function UIAircraftController:PlayDoorAnim(operate, spaceID)
    local anim = AirAnimRoomOperate:New(self._main, operate, spaceID, nil)
    anim:Play()
    --空间数据改变之后刷新区域内格子
    self._main:RefreshAreaSurfacesBySpaceID(spaceID)
end

--region
function UIAircraftController:AircraftMainMoveCameraToNavMenu(cb, movetime)
    self._main:MoveToNavMenuPos(cb, movetime)
end
function UIAircraftController:GetCurrentCameraPos()
    return self._main:GetCurrentCameraPos()
end
function UIAircraftController:GetNavMenuTargetCameraPos()
    return self._main:GetNavMenuTargetCameraPos()
end
function UIAircraftController:SetCameraToNavMenuPos()
    self._main:SetCameraToNavMenuPos()
end
--刷新导航栏数据
function UIAircraftController:RefreshNavMenuData()
    --初始化导航栏
    ---@type UIAirNavMenu
    self._navMenu:RefreshData()
    self:RefreshEasyBtnsRed()
end

--获取3d相机
function UIAircraftController:GetAirCamera3D()
    return self._main:GetMainCamera()
end
--获取ui相机
function UIAircraftController:GetAirCamera2D()
    return GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
end
function UIAircraftController:AircraftMainGetStroyPets()
    return self._main:GetRandomStoryPets()
end
function UIAircraftController:AircraftMainGetAirPetByID(id)
    return self._main:GetPetByTmpID(id)
end
function UIAircraftController:ClearCurrentRoom()
    self._main:ClearCurrentRoom()
end

--开关导航栏
function UIAircraftController:UIAirNavMenuActive(active)
    if active == true then
        if self._roomUI and not self._roomUI:IsClosed() then
            return
        else
            self._navMenuGo:SetActive(true)
            self._navMenu:ResetIconPos()
            self._easyBtns:SetActive(true)
        end

    else
        self._navMenuGo:SetActive(false)
    end
end
--检测导航栏能否打开（相机距离）
function UIAircraftController:CheckAirNavMenuCanActive()
    return self._main:CheckAirNavMenuCanActive()
end

--endregion

function UIAircraftController:BtnDecorateOnClick()
    self:DoDerorate(nil)
end

function UIAircraftController:BtnMakeOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIAircraftItemSmeltController")
end

function UIAircraftController:BtnSendOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIDispatchMapController", true)
end

function UIAircraftController:DoDerorate(spaceID)
    self._main:ChangeMode(AircraftMode.Decorate, spaceID)
end

function UIAircraftController:RefreshDecorateArea(space)
    self._main:RefreshAreaBySpace(space)
end

function UIAircraftController:TryRefreshRoomUI(spaceID, forceReq)
    if self._roomUI == nil then
        return
    end
    if self._roomUI:IsClosed() then
        return
    end
    --强制请求1次数据再刷新
    if forceReq then
        GameGlobal.TaskManager():StartTask(
            self.ReqData,
            self,
            function()
                self:ShowRoomUI(spaceID, false, nil)
            end
        )
    else
        self:ShowRoomUI(spaceID, false, nil)
    end
end

----------------------------------------------------------------------------------------------------------
---@class OpenAircraftParamType
local OpenAircraftParamType = {
    Spaceid = 1,
    Petid = 2
}
_enum("OpenAircraftParamType", OpenAircraftParamType)

--引导用勿删
function UIAircraftController:GetBackBtn()
    return self._topBar.topButtonWidget:GetGameObject("ButtonBack")
end
function UIAircraftController:GetHomeBtn()
    return self._topBar.topButtonWidget:GetGameObject("ButtonThumb")
end

function UIAircraftController:GetRoomInfoDecorateBtn()
    if self._roomUI then
        return self._roomUI:GetDecorateBtn()
    else
        --娱乐区解锁后打开房间UI前有请求 请求返回前roomUI是空的 但是引导是同步触发的 需要判空处理
        return nil
    end
end
----------------------------------------------
---@class AircraftLevelUpPreCondition:Object  房间升级前置条件数据
_class("AircraftLevelUpPreCondition", Object)
AircraftLevelUpPreCondition = AircraftLevelUpPreCondition
function AircraftLevelUpPreCondition:Constructor(type, level, need, had)
    self.Type = type
    self.Level = level
    self.Need = need
    self.Had = had
end
