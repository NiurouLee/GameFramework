---@class UIWidgetHomelandBuildController:UICustomWidget
_class("UIWidgetHomelandBuildController", UICustomWidget)
UIWidgetHomelandBuildController = UIWidgetHomelandBuildController

function UIWidgetHomelandBuildController:OnShow(uiParams)
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self._uiHomelandModule = self._homelandModule:GetUIModule()
    ---@type HomelandClient
    self._homelandClient = self._uiHomelandModule:GetClient()
    ---@type HomelandInputControllerBuildBase
    self._homelandInputControllerBuild = self._homelandClient:InputManager():GetControllerBuild()
    ---@type boolean
    self._isMobile = self._homelandClient:InputManager():UseMobileController()
    
    if self._isMobile then
        self:InitMobileController()
    else
        self:InitPCController()
    end
end

function UIWidgetHomelandBuildController:InitMobileController()
    ---@type UnityEngine.GameObject
    self._joystickArea = self:GetGameObject("JoystickArea")

    ---@type UnityEngine.RectTransform
    self._TouchPointMoveTrans = self:GetUIComponent("RectTransform", "JoystickPoint")
    ---@type UnityEngine.UI.Image
    self._JoystickBGImage = self:GetUIComponent("Image", "JoystickBG")


    self._uiCam = GameGlobal.UIStateManager():GetControllerCamera(self.uiOwner:GetName())
    ---@type UnityEngine.Input
    self._input = GameGlobal.EngineInput()

    ---@type number 当前控制移动虚拟摇杆的触控id
    self._moveFingerID = nil
    ---@type number 当前控制相机旋转的触控id
    self._rotateFingerID = nil
    ---@type number 当前控制相机缩放的触控id
    self._scaleFingerID = nil
    ---@type number 当前从建筑列表拖拽进场景的触控id
    self._dragInFingerID = nil

    ---@type Vector2 旋转触控点坐标
    self._rotateFingerPos = nil
    ---@type Vector2 缩放触控点坐标
    self._scaleFingerPos = nil
    ---@type number 缩放触控点间距
    self._scaleDistance = nil

    ---@type boolean
    self._rotated = false
    ---@type number
    self._touchTime = 0
    
    --摇杆区
    self._joystickAreaTrans = self._joystickArea.transform
    self._joystickEtl = UICustomUIEventListener.Get(self._joystickArea)
    self:AddUICustomEventListener(self._joystickEtl, UIEvent.Press, 
        function(go)
            self:OnPressJoystick()   
        end
    )
    self:AddUICustomEventListener(self._joystickEtl, UIEvent.Drag, 
        function(pointerEventData)
            self:OnDragJoystick(pointerEventData)   
        end
    )
    self:AddUICustomEventListener(self._joystickEtl, UIEvent.Release,
        function(go)
            self:OnUpJoystick()   
        end
    )

    --转向区
    self._goTrans = self:GetGameObject().transform
    self._slidingAreaEtl = UICustomUIEventListener.Get(self:GetGameObject())
    self:AddUICustomEventListener(self._slidingAreaEtl, UIEvent.Press, 
        function(go)
            self:OnPressSlidingArea()   
        end
    )
    self:AddUICustomEventListener(self._slidingAreaEtl, UIEvent.Drag, 
        function(pointerEventData)
            self:OnDragSlidingArea(pointerEventData)   
        end
    )
    self:AddUICustomEventListener(self._slidingAreaEtl, UIEvent.Release,
        function(go)
            self:OnUpSlidingArea()   
        end
    )
    
    self._circleRadius = 186
    self._circleRadiusSQ = self._circleRadius * self._circleRadius

    self._scaleFactor = 0.01
    ---@type number 点击间隔配置(毫秒)
    self._clickInterval = 500
end

function UIWidgetHomelandBuildController:OnHide()
    self._dragInFingerID = nil
    self._moveFingerID = nil
    self._rotateFingerID = nil
    self._scaleFingerID = nil
end

function UIWidgetHomelandBuildController:InitPCController()
    ---@type UnityEngine.GameObject
    self._joystickArea = self:GetGameObject("JoystickArea")

    self._joystickArea:SetActive(false)
    self:GetGameObject():GetComponent(typeof(EmptyImage)).enabled = false
end

function UIWidgetHomelandBuildController:DragBuildingIntoScene(buildingID, touchID)
    self._homelandInputControllerBuild:HandleDragIn(buildingID)
    if self._isMobile then
        self._dragInFingerID = touchID
        self:StartTask(self.HandleDragIn, self)
    end    
end

function UIWidgetHomelandBuildController:HandleDragIn(TT)
    while true do
        if not self._dragInFingerID then
            return
        end

        local dragFingerExist = false
        for i = 0, self._input.touchCount - 1 do
            local touch = self._input.GetTouch(i)

            if self._dragInFingerID == touch.fingerId then
                if touch.phase == TouchPhase.Ended or touch.phase == TouchPhase.Canceled then
                    self._dragInFingerID = nil
                    if self._homelandInputControllerBuild:TouchBuilding() then  --如果挪动了家具 抬起时通知逻辑层
                        self._homelandInputControllerBuild:ReleaseTouch()                        
                    end
                    return
                end

                dragFingerExist = true
                if touch.phase == TouchPhase.Moved then
                    self._homelandInputControllerBuild:MoveDragInFinger(touch.position)
                end
            end
        end

        if not dragFingerExist then
            return
        end

        YIELD(TT)
    end
end

function UIWidgetHomelandBuildController:OnPressJoystick()
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
    if sqDis > self._circleRadiusSQ then
        self._TouchPointMoveTrans.anchoredPosition = self._circleRadius / math.sqrt(sqDis) * pos
    else
        self._TouchPointMoveTrans.anchoredPosition = pos
    end
    self._homelandInputControllerBuild:HandleMove(pos)
    
    --ToastManager.ShowToast("move start touch id:"..touch.fingerId.." pos:"..tostring(pos))
end

---@param pointerEventData UnityEngine.EventSystems.PointerEventData
function UIWidgetHomelandBuildController:OnDragJoystick(pointerEventData)
    if self._moveFingerID == pointerEventData.pointerId then
        local _, pos =
        UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
            self._joystickAreaTrans,
            pointerEventData.position,
            pointerEventData.pressEventCamera,
            nil
        )

        local sqDis = pos:SqrMagnitude()
        if sqDis > self._circleRadiusSQ then
            self._TouchPointMoveTrans.anchoredPosition = self._circleRadius / math.sqrt(sqDis) * pos
        else
            self._TouchPointMoveTrans.anchoredPosition = pos
        end
        self._homelandInputControllerBuild:HandleMove(pos)
        --ToastManager.ShowToast("move drag touch id:"..touch.fingerId.." pos:"..tostring(pos))
    end
end

function UIWidgetHomelandBuildController:OnUpJoystick()
    if self._moveFingerID == nil then
        return
    end

    local pointerEventData = self._joystickEtl.CurrentPointerEventData
    if self._moveFingerID == pointerEventData.pointerId then    
        self._moveFingerID = nil    
        
        self._homelandInputControllerBuild:HandleMove(Vector2.zero)
        self._TouchPointMoveTrans.anchoredPosition = Vector2.zero
    
        --ToastManager.ShowToast("move end touch id:"..touch.fingerId.." pos:"..tostring(pos))
    end
end

function UIWidgetHomelandBuildController:OnPressSlidingArea()
    if self._rotateFingerID ~= nil and self._scaleFingerID ~= nil then
        return
    end

    local pointerEventData = self._slidingAreaEtl.CurrentPointerEventData
    local fingerId = pointerEventData.pointerId

    if self._rotateFingerID == nil and self._scaleFingerID ~= fingerId then
        self._rotateFingerID = fingerId
        self._rotateFingerPos = pointerEventData.position

        --选中家具时 如果按下在家具上 进入拖拽家具状态
        if self._homelandInputControllerBuild:HandleBuildAreaDown(pointerEventData.position) then
            return
        end

        if self._scaleFingerID == nil then
            ---同时判定家具选中
            self._rotated = false
            self._touchTime = GameGlobal:GetInstance():GetCurrentTime()
        end

        --Log.fatal("rotate press id:"..touch.fingerId)
        --ToastManager.ShowToast("rotate start touch id:"..touch.fingerId.." pos:"..tostring(pos))
    elseif self._scaleFingerID == nil and self._rotateFingerID ~= fingerId  then
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
function UIWidgetHomelandBuildController:OnDragSlidingArea(pointerEventData)
    if self._rotateFingerID and self._scaleFingerID then
        local scaled = false
        if self._rotateFingerID == pointerEventData.pointerId then
            self._rotateFingerPos = pointerEventData.position
            scaled = true

            --Log.fatal("fc:"..UnityEngine.Time.frameCount.." rotate move id:"..pointerEventData.pointerId.." delta:"..tostring(pointerEventData.delta))
        elseif self._scaleFingerID == pointerEventData.pointerId then
            self._scaleFingerPos = pointerEventData.position
            scaled = true

            --Log.fatal("fc:"..UnityEngine.Time.frameCount.." scale press id:"..pointerEventData.pointerId.." delta:"..tostring(pointerEventData.delta))
        end
        if scaled then
            self._rotated = true
            local newDistance = Vector2.Distance(self._rotateFingerPos, self._scaleFingerPos)
            self._homelandInputControllerBuild:HandleScale((newDistance - self._scaleDistance) * self._scaleFactor)
            self._scaleDistance = newDistance
        end
    elseif self._rotateFingerID == pointerEventData.pointerId then
        
        if self._homelandInputControllerBuild:TouchBuilding() then
            self._homelandInputControllerBuild:HandleBuildAreaMove(pointerEventData.position)
        else
            self._homelandInputControllerBuild:HandleRotate(pointerEventData.delta)
            self._rotated = true
        end

        --ToastManager.ShowToast("rotate drag touch id:"..touch.fingerId.." pos:"..tostring(pos))
    end
end

function UIWidgetHomelandBuildController:OnUpSlidingArea()
    if self._rotateFingerID == nil and self._scaleFingerID == nil then
        return
    end

    local pointerEventData = self._slidingAreaEtl.CurrentPointerEventData


    if self._rotateFingerID == pointerEventData.pointerId then
        if self._homelandInputControllerBuild:TouchBuilding() then  --如果挪动了家具 抬起时通知逻辑层
            self._homelandInputControllerBuild:ReleaseTouch()
            
        elseif not self._rotated then  --如果没有移动过 执行点击逻辑
            local interval = GameGlobal:GetInstance():GetCurrentTime() - self._touchTime
            if interval < self._clickInterval then
                self._homelandInputControllerBuild:HandleBuildAreaClick(self._rotateFingerPos)
                --Log.fatal("Select:"..tostring(self._rotateFingerPos))
            end
        end

        self._rotateFingerID = nil    
        self._rotateFingerPos = nil

        --Log.fatal("rotate up id:"..touch.fingerId)
        --ToastManager.ShowToast("rotate end touch id:"..touch.fingerId.." pos:"..tostring(pos))
    elseif self._scaleFingerID == pointerEventData.pointerId then
        self._scaleFingerID = nil    
        self._scaleFingerPos = nil
        
        --Log.fatal("scale up id:"..touch.fingerId)
    end
end