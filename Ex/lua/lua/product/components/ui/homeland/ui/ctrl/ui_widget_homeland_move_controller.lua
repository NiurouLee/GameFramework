---@class UIWidgetHomelandMoveController:UICustomWidget
_class("UIWidgetHomelandMoveController", UICustomWidget)
UIWidgetHomelandMoveController = UIWidgetHomelandMoveController

function UIWidgetHomelandMoveController:OnShow(uiParams)
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self._uiHomelandModule = self._homelandModule:GetUIModule()
    ---@type HomelandClient
    self._homelandClient = self._uiHomelandModule:GetClient()
    ---@type HomelandInputControllerCharBase
    self._HomelandInputControllerChar = self._homelandClient:InputManager():GetControllerChar()

    ---@type UnityEngine.GameObject 右下锚点根节点
    self._rb = self:GetGameObject("RightBottom")

    if self._homelandClient:InputManager():UseMobileController() then
        self:InitMobileController()

        self.resetCallback = function()
            self:OnReset()
        end
        self._homelandClient:InputManager():AddResetCallback(self.resetCallback)
    else
        self:InitPCController()
    end

    self:AttachEvent(GameEventType.OnChangeUIHomelandButtonSprintShow, self.OnChangeUIHomelandButtonSprintShow)
    self:AttachEvent(GameEventType.FishMatchHideDash, self.OnFishMatchReadyHideUI)
    self:AttachEvent(GameEventType.FishMatchEnd, self.OnFishMatchEndShowUI)

    --打开摆放界面再退出  这个界面会初始化  冲刺按钮是默认打开的   需要根据主角的状态重新设置
    ---@type UIHomelandModule
    local homeLandModule = GameGlobal.GetUIModule(HomelandModule)
    ---@type HomelandClient
    local homelandClient = homeLandModule:GetClient()
    ---@type HomelandMainCharacterController
    local characterController = homelandClient:CharacterManager():MainCharacterController()
    --主角在泳池中，不显示冲刺按钮
    if characterController:IsSwimming() then
        self._rb:SetActive(false)
    end

    local dashBtn = self:GetGameObject("DashButton")
    local el = UICustomUIEventListener.Get(dashBtn)
    self:AddUICustomEventListener(
        el,
        UIEvent.Press,
        function()
            self:OnDashBtnDown()
        end
    )
    self:AddUICustomEventListener(
        el,
        UIEvent.Release,
        function()
            self:OnDashBtnUp()
        end
    )
    self._dashBtnHolding = false
end

function UIWidgetHomelandMoveController:OnHide()
    self._moveFingerID = nil
    self._rotateFingerID = nil
    self._scaleFingerID = nil

    self._homelandClient:InputManager():RemoveResetCallback(self.resetCallback)
end

function UIWidgetHomelandMoveController:OnReset()
    self._moveFingerID = nil
    self._rotateFingerID = nil
    self._scaleFingerID = nil

    self._TouchPointMoveTrans.anchoredPosition = Vector2.zero
end

function UIWidgetHomelandMoveController:HideExceptCameraRotation(hide)
    if self._homelandClient:InputManager():UseMobileController() then
        self._joystickArea:SetActive(not hide)
    end

    ---@type UIHomelandModule
    local homeLandModule = GameGlobal.GetUIModule(HomelandModule)
    ---@type HomelandClient
    local homelandClient = homeLandModule:GetClient()
    ---@type HomelandMainCharacterController
    local characterController = homelandClient:CharacterManager():MainCharacterController()
    --主角在泳池中，不显示冲刺按钮
    if characterController:IsSwimming() then
        return
    end

    self._rb:SetActive(not hide)
end

function UIWidgetHomelandMoveController:InitMobileController()
    ---@type UnityEngine.GameObject
    self._joystickArea = self:GetGameObject("JoystickArea")

    ---@type UnityEngine.RectTransform
    self._TouchPointMoveTrans = self:GetUIComponent("RectTransform", "JoystickPoint")
    ---@type UnityEngine.UI.Image
    --self._JoystickBGBigImage = self:GetUIComponent("Image", "JoystickBGBig")
    ---@type UnityEngine.UI.Image
    --self._JoystickBGSmallImage = self:GetUIComponent("Image", "JoystickBGSmall")

    self._uiCam = GameGlobal.UIStateManager():GetControllerCamera(self.uiOwner:GetName())
    ---@type UnityEngine.Input
    self._input = GameGlobal.EngineInput()

    ---@type number 当前控制移动虚拟摇杆的触控id
    self._moveFingerID = nil
    ---@type number 当前控制相机旋转的触控id
    self._rotateFingerID = nil
    ---@type number 当前控制相机缩放的触控id
    self._scaleFingerID = nil

    ---@type Vector2 旋转触控点坐标
    self._rotateFingerPos = nil
    ---@type Vector2 缩放触控点坐标
    self._scaleFingerPos = nil
    ---@type number 缩放触控点间距
    self._scaleDistance = nil

    --摇杆区
    self._joystickAreaTrans = self._joystickArea.transform
    self._joystickEtl = UICustomUIEventListener.Get(self._joystickArea)
    self:AddUICustomEventListener(
        self._joystickEtl,
        UIEvent.Press,
        function(go)
            self:OnPressJoystick()
        end
    )
    self:AddUICustomEventListener(
        self._joystickEtl,
        UIEvent.Drag,
        function(pointerEventData)
            self:OnDragJoystick(pointerEventData)
        end
    )
    self:AddUICustomEventListener(
        self._joystickEtl,
        UIEvent.Release,
        function(go)
            self:OnUpJoystick()
        end
    )

    --转向区
    self._goTrans = self:GetGameObject().transform
    self._slidingAreaEtl = UICustomUIEventListener.Get(self:GetGameObject())
    self:AddUICustomEventListener(
        self._slidingAreaEtl,
        UIEvent.Press,
        function(go)
            self:OnPressSlidingArea()
        end
    )
    self:AddUICustomEventListener(
        self._slidingAreaEtl,
        UIEvent.Drag,
        function(pointerEventData)
            self:OnDragSlidingArea(pointerEventData)
        end
    )
    self:AddUICustomEventListener(
        self._slidingAreaEtl,
        UIEvent.Release,
        function(go)
            self:OnUpSlidingArea()
        end
    )

    self._smallCircleRadius = 63
    self._smallCircleRadiusSQ = self._smallCircleRadius * self._smallCircleRadius
    self._bigCircleRadius = 186
    self._bigCircleRadiusSQ = self._bigCircleRadius * self._bigCircleRadius
    self._moveType = HomelandCharMoveType.Idle

    self._scaleFactor = 0.005
end

function UIWidgetHomelandMoveController:InitPCController()
    ---@type UnityEngine.GameObject
    self._joystickArea = self:GetGameObject("JoystickArea")

    self._joystickArea:SetActive(false)
    self:GetGameObject():GetComponent(typeof(EmptyImage)).enabled = false
end

function UIWidgetHomelandMoveController:OnPressJoystick()
    if self._moveFingerID ~= nil then
        return
    end

    local pointerEventData = self._joystickEtl.CurrentPointerEventData
    self._moveFingerID = pointerEventData.pointerId

    local _, pos =
        UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
        self._joystickAreaTrans,
        pointerEventData.position,
        pointerEventData.pressEventCamera,
        nil
    )

    local sqDis = pos:SqrMagnitude()
    if sqDis > self._smallCircleRadiusSQ then
        --self._JoystickBGBigImage.color = Color.black
        self._moveType = HomelandCharMoveType.Run
    else
        --self._JoystickBGSmallImage.color = Color.black
        self._moveType = HomelandCharMoveType.Walk
    end

    if sqDis > self._bigCircleRadiusSQ then
        self._TouchPointMoveTrans.anchoredPosition = self._bigCircleRadius / math.sqrt(sqDis) * pos
    else
        self._TouchPointMoveTrans.anchoredPosition = pos
    end

    self._HomelandInputControllerChar:HandleMove(pos, self._moveType)

    --ToastManager.ShowToast("move start touch id:"..touch.fingerId.." pos:"..tostring(pos))
end

---@param pointerEventData UnityEngine.EventSystems.PointerEventData
function UIWidgetHomelandMoveController:OnDragJoystick(pointerEventData)
    if self._moveFingerID == pointerEventData.pointerId then
        local _, pos =
            UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
            self._joystickAreaTrans,
            pointerEventData.position,
            pointerEventData.pressEventCamera,
            nil
        )

        local sqDis = pos:SqrMagnitude()

        if self._moveType == HomelandCharMoveType.Walk and sqDis > self._smallCircleRadiusSQ then
            --self._JoystickBGBigImage.color = Color.black
            --self._JoystickBGSmallImage.color = Color.white
            self._moveType = HomelandCharMoveType.Run
        elseif self._moveType == HomelandCharMoveType.Run and sqDis <= self._smallCircleRadiusSQ then
            --self._JoystickBGBigImage.color = Color.white
            --self._JoystickBGSmallImage.color = Color.black
            self._moveType = HomelandCharMoveType.Walk
        end

        if sqDis > self._bigCircleRadiusSQ then
            self._TouchPointMoveTrans.anchoredPosition = self._bigCircleRadius / math.sqrt(sqDis) * pos
        else
            self._TouchPointMoveTrans.anchoredPosition = pos
        end

        self._HomelandInputControllerChar:HandleMove(pos, self._moveType)
    --ToastManager.ShowToast("move drag touch id:"..touch.fingerId.." pos:"..tostring(pos))
    end
end

function UIWidgetHomelandMoveController:OnUpJoystick()
    if self._moveFingerID == nil then
        return
    end
    if not self._joystickEtl.CurrentPointerEventData then
        return
    end
    local pointerEventData = self._joystickEtl.CurrentPointerEventData
    if self._moveFingerID == pointerEventData.pointerId then
        self._moveFingerID = nil
        --self._JoystickBGBigImage.color = Color.white
        --self._JoystickBGSmallImage.color = Color.white

        self._HomelandInputControllerChar:HandleMove(Vector2.zero, HomelandCharMoveType.Idle)
        self._TouchPointMoveTrans.anchoredPosition = Vector2.zero

    --ToastManager.ShowToast("move end touch id:"..touch.fingerId.." pos:"..tostring(pos))
    end
end

---旋转缩放区按下处理
function UIWidgetHomelandMoveController:OnPressSlidingArea()
    if self._rotateFingerID ~= nil and self._scaleFingerID ~= nil then
        return
    end

    local pointerEventData = self._slidingAreaEtl.CurrentPointerEventData
    local fingerId = pointerEventData.pointerId

    if self._rotateFingerID == nil and self._scaleFingerID ~= fingerId then
        --Log.fatal("rotate press id:"..touch.fingerId)
        --ToastManager.ShowToast("rotate start touch id:"..touch.fingerId.." pos:"..tostring(pos))
        self._rotateFingerID = fingerId
        self._rotateFingerPos = pointerEventData.position
    elseif self._scaleFingerID == nil and self._rotateFingerID ~= fingerId then
        self._scaleFingerID = fingerId
        self._scaleFingerPos = pointerEventData.position

    --Log.fatal("scale press id:"..touch.fingerId)
    --ToastManager.ShowToast("scale start touch id:"..touch.fingerId.." pos:"..tostring(pos))
    end

    if self._rotateFingerID and self._scaleFingerID then
        self._scaleDistance = Vector2.Distance(self._rotateFingerPos, self._scaleFingerPos)
    end
end

---@param pointerEventData UnityEngine.EventSystems.PointerEventData
function UIWidgetHomelandMoveController:OnDragSlidingArea(pointerEventData)
    if self._rotateFingerID and self._scaleFingerID then
        local scaled = false
        if self._rotateFingerID == pointerEventData.pointerId then
            --Log.fatal("fc:"..UnityEngine.Time.frameCount.." rotate move id:"..pointerEventData.pointerId.." delta:"..tostring(pointerEventData.delta))
            self._rotateFingerPos = pointerEventData.position
            scaled = true
        elseif self._scaleFingerID == pointerEventData.pointerId then
            self._scaleFingerPos = pointerEventData.position
            scaled = true

        --Log.fatal("fc:"..UnityEngine.Time.frameCount.." scale press id:"..pointerEventData.pointerId.." delta:"..tostring(pointerEventData.delta))
        end
        if scaled then
            local newDistance = Vector2.Distance(self._rotateFingerPos, self._scaleFingerPos)
            self._HomelandInputControllerChar:HandleScale((newDistance - self._scaleDistance) * self._scaleFactor)
            self._scaleDistance = newDistance
        end
    elseif self._rotateFingerID == pointerEventData.pointerId then
        self._HomelandInputControllerChar:HandleRotate(pointerEventData.delta)

    --ToastManager.ShowToast("rotate drag touch id:"..touch.fingerId.." pos:"..tostring(pos))
    end
end

function UIWidgetHomelandMoveController:OnUpSlidingArea()
    if self._rotateFingerID == nil and self._scaleFingerID == nil then
        return
    end

    local pointerEventData = self._slidingAreaEtl.CurrentPointerEventData
    if self._rotateFingerID == pointerEventData.pointerId then
        --Log.fatal("rotate up id:"..touch.fingerId)
        --ToastManager.ShowToast("rotate end touch id:"..touch.fingerId.." pos:"..tostring(pos))
        self._rotateFingerID = nil
        self._rotateFingerPos = nil
    elseif self._scaleFingerID == pointerEventData.pointerId then
        self._scaleFingerID = nil
        self._scaleFingerPos = nil

    --Log.fatal("scale up id:"..touch.fingerId)
    end
end

-- function UIWidgetHomelandMoveController:DashButtonOnClick()
--     self._HomelandInputControllerChar:Dash()
-- end

--控制冲刺按钮的显示
function UIWidgetHomelandMoveController:OnChangeUIHomelandButtonSprintShow(visible)
    self._rb:SetActive(visible)
    if not visible then
        --隐藏冲刺按钮的时候需要清理按下状态
        self._HomelandInputControllerChar:DashRelease()
    end
end
--钓鱼比赛隐藏ui
function UIWidgetHomelandMoveController:OnFishMatchReadyHideUI()
    if self._homelandClient:InputManager():UseMobileController() then
        self._joystickArea:SetActive(false)
    end
    self._rb:SetActive(false)
end
--钓鱼比赛结束显示
function UIWidgetHomelandMoveController:OnFishMatchEndShowUI()
    if self._homelandClient:InputManager():UseMobileController() then
        self._joystickArea:SetActive(true)
    end

    self._rb:SetActive(true)
end
function UIWidgetHomelandMoveController:OnDashBtnDown()
    self._HomelandInputControllerChar:DashStart()
end
function UIWidgetHomelandMoveController:OnDashBtnUp()
    self._HomelandInputControllerChar:DashRelease()
end
