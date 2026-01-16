---@class HandleInputSystem_Render:Object
_class("HandleInputSystem_Render", Object)
HandleInputSystem_Render = HandleInputSystem_Render

---@param world World
function HandleInputSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type TimeService
    self._timeService = self._world:GetService("Time")

    ---@type InputComponent
    self._inputComponent = world:Input()

    ---@type PickUpComponent
    self._pickUpCmpt = world:PickUp()

    ---@type ChessPickUpComponent
    self._chessPickUpCmpt = world:ChessPickUp()

    ---@type PopStarPickUpComponent
    self._popStarPickUpCmpt = self._world:PopStarPickUp()

    ---@type MiragePickUpComponent
    self._miragePickUpCmpt = world:MiragePickUp()

    self._click = false
    self._doubleClick = false
    self._lastDoubleClickTime = 0 ---最近一次双击的时刻

    self._heldDown = false
    self._lastClickTime = 0
    self._heldDownPos = nil
    self._longPress = false

    self._beginDrag = false
    self._dragging = false
    self._endDrag = false

    self._lastHeldDownTime = 0

    self._hitInfo = nil
    self._rayCastMaxDistance = 2000

    self._lastMousePosition = nil

    self._lastFramePosArray = {}

    self._inputUIArray = {"black_mask", "GuideMask"}

    --这个值是为了在世界坐标空间下的拾取点与像素空间对应
    --self._hitPointOffset = Vector3(0.15,0,-0.15)
    self._hitPointOffset = Vector3(0, 0, 0)
    self._cancelChainPathFunc = GameHelper:GetInstance():CreateCallback(self.CancelChainPath, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.CancelChainPath, self._cancelChainPathFunc)
end

function HandleInputSystem_Render:TearDown()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.CancelChainPath, self._cancelChainPathFunc)
end

function HandleInputSystem_Render:Execute()
    local touchCount = UnityEngine.Input.touchCount
    if touchCount > 1 then
        ---同时按下多个点，不响应
        return
    end

    local hasInput = self:_UpdateInputState()

    local isWaitInputState = self:_IsWaitInputState()
    local isActiveSkillInputState = self:_IsActiveSkillInputState()
    local isMirageWaitInputState = self:_IsMirageWaitInputState()
    if self._world:MatchType() == MatchType.MT_Chess then
        ---战棋模式下的点选走自己的一套逻辑
        self:_UpdateChessInputState()
    elseif isMirageWaitInputState then
        self:_UpdateMirageInputState()
    else
        if isWaitInputState == true and self._world:MatchType() ~= MatchType.MT_PopStar then
            ---@type UtilDataServiceShare
            local utilStatSvc = self._world:GetService("UtilData")
            if not utilStatSvc:GetStatAutoFight() then
                self:_UpdateMultiDragState(hasInput)
            end
        elseif isWaitInputState == true and self._world:MatchType() == MatchType.MT_PopStar then
            self:_UpdatePopStarInputState()
        elseif isActiveSkillInputState == true then
            self:_UpdateActiveSkillInputState()
        else
            --self._inputComponent:SetTouchEndPosition(nil)
        end
    end

    --self:_CreateLookAtObj()
    --self:_LookAtPlayer()
end

function HandleInputSystem_Render:_UpdateDragState(hasInput)
    self:_UpdateTouchState()

    ---检测输入状态：单击、双击、抬起、长按
    if hasInput ~= true then
        return
    end

    ---是否点到对象
    local castRes = self:_DoRayCast()
    if castRes ~= true then
        return
    end

    --Log.fatal("click:",self._click,"dbclick:",self._doubleClick,";longPress",self._longPress,";beginDrag:",self._beginDrag,";dragging:",self._dragging,";enddrag:",self._endDrag,";framecount:",UnityEngine.Time.frameCount)
    --Log.fatal("hitinfo: ",self._hitInfo.collider.gameObject.name)
    local originalHitPoint = self._hitInfo.point

    local hitPoint =
        Vector3(
        originalHitPoint.x + self._hitPointOffset.x,
        originalHitPoint.y,
        originalHitPoint.z + self._hitPointOffset.z
    )
    --Log.fatal("hitPoint ",hitPoint.x," ",hitPoint.y," ",hitPoint.z)
    self:_CreateTestObj(hitPoint)
    self:_SetInputComponent(hitPoint)

    self:InputDirty()
end

function HandleInputSystem_Render:_UpdateMultiDragState(hasInput)
    self:_UpdateTouchState()

    ---检测输入状态：单击、双击、抬起、长按
    if hasInput ~= true then
        return
    end

    ---是否点到对象
    local castRes = self:_DoMultiPointRayCast()
    if castRes ~= true then
    --return
    end

    ---将输入坐标数据转到输入组件
    self:_RefreshInputData()

    ---通知selectGridSystem执行
    self:InputDirty()
end

function HandleInputSystem_Render:_UpdateActiveSkillInputState()
    --检测点击
    local mouseClick = UnityEngine.Input.GetMouseButtonDown(0)
    if not mouseClick then
        return
    end

    ---是否点到对象
    local castRes = self:_DoRayCast()
    if castRes ~= true then
        return
    end

    ---测试点
    self:_CreateTestObj(self._hitInfo.point)

    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.TouchInput,
        {input = "PickUp", hitPoint = self._hitInfo.point}
    )
    --通知拾取开始
    self._pickUpCmpt:SetClickPos(self._hitInfo.point)
    self:_PickUpDirty()
end

function HandleInputSystem_Render:_UpdateChessInputState()
    --检测点击
    local mouseClick = UnityEngine.Input.GetMouseButtonDown(0)
    if not mouseClick then
        return
    end

    ---是否点到对象
    local castRes = self:_DoRayCast()
    if castRes ~= true then
        return
    end

    ---测试点
    self:_CreateTestObj(self._hitInfo.point)

    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.TouchInput,
        { input = "PickUp", hitPoint = self._hitInfo.point }
    )
    --通知拾取开始
    self._chessPickUpCmpt:SetChessClickPos(self._hitInfo.point)
    self:_ChessPickUpDirty()
end

function HandleInputSystem_Render:_UpdatePopStarInputState()
    --检测点击
    local mouseClick = UnityEngine.Input.GetMouseButtonDown(0)
    if not mouseClick then
        return
    end

    ---是否点到对象
    local castRes = self:_DoRayCast()
    if castRes ~= true then
        return
    end

    ---测试点
    self:_CreateTestObj(self._hitInfo.point)

    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.TouchInput,
        { input = "PickUp", hitPoint = self._hitInfo.point }
    )

    ---设置点击位置
    self._popStarPickUpCmpt:SetPopStarClickPos(self._hitInfo.point)
    self:_PopStarPickUpDirty()
end

function HandleInputSystem_Render:_UpdateMirageInputState()
    --检测点击
    local mouseClick = UnityEngine.Input.GetMouseButtonDown(0)
    if not mouseClick then
        return
    end

    ---是否点到对象
    local castRes = self:_DoRayCast()
    if castRes ~= true then
        return
    end

    ---测试点
    self:_CreateTestObj(self._hitInfo.point)

    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.TouchInput,
        { input = "PickUp", hitPoint = self._hitInfo.point }
    )
    --通知拾取开始
    self._miragePickUpCmpt:SetClickPos(self._hitInfo.point)
    self:_MiragePickUpDirty()
end

function HandleInputSystem_Render:_SetInputComponent(hitPoint)
    if self._doubleClick then
        self._inputComponent:SetDoubleClickPos(hitPoint)
    elseif self._dragging then
        self._inputComponent:SetTouchMovePosition(hitPoint)
    elseif self._beginDrag then
        self._inputComponent:SetTouchBeginPosition(hitPoint)
    elseif self._endDrag then
        self._inputComponent:SetTouchEndPosition(hitPoint)
        self._endDrag = false
        self._doubleClick = false
    end
end

---将输入数据放到组件里
function HandleInputSystem_Render:_RefreshInputData()
    local currentTimeMS = self._timeService:GetCurrentTimeMs()
    if self._doubleClick then
        local deltaLength = currentTimeMS - self._lastDoubleClickTime
        ---两次双击间隔至少50毫秒，大于一帧
        if #self._lastFramePosArray > 0 and deltaLength >HelperProxy:GetInstance():GetFixTimeLen(27) then
            local firstHitPoint = self._lastFramePosArray[1]
            self._inputComponent:SetDoubleClickPos(firstHitPoint)
            GameGlobal.GameRecorder():RecordAction(
                GameRecordAction.TouchInput,
                {input = "DoubleClick", hitPoint = firstHitPoint}
            )
        end
    elseif self._dragging then
        if #self._lastFramePosArray > 0 then
            self._inputComponent:SetTouchMovePositionList(self._lastFramePosArray)
            GameGlobal.GameRecorder():RecordAction(
                GameRecordAction.TouchInput,
                {input = "Dragging", hitPoint = self._lastFramePosArray[1]}
            )
        end
    elseif self._beginDrag then
        if #self._lastFramePosArray > 0 then
            local firstHitPoint = self._lastFramePosArray[1]
            self._inputComponent:SetTouchBeginPosition(firstHitPoint)
            GameGlobal.GameRecorder():RecordAction(
                GameRecordAction.TouchInput,
                {input = "BeginDrag", hitPoint = firstHitPoint}
            )
        end
    elseif self._endDrag then
        self._inputComponent:SetTouchEndPosition(nil)
        self._endDrag = false
        self._doubleClick = false
        GameGlobal.GameRecorder():RecordAction(GameRecordAction.TouchInput, {input = "EndDrag"})
    --Log.fatal("_RefreshInputData enddrag false >>>>>>>>>>>",UnityEngine.Time.frameCount)
    end
end

function HandleInputSystem_Render:_UpdateInputState()
    local mouseClick = UnityEngine.Input.GetMouseButtonDown(0)
    local mouseHoldDown = UnityEngine.Input.GetMouseButton(0)
    local mouseRelease = UnityEngine.Input.GetMouseButtonUp(0)

    if mouseClick then
        self:_OnMouseClick()
    else
        self._click = false
    end

    if mouseHoldDown then
        self:_OnMouseHoldDown()
    end

    if mouseRelease then
        self:_OnMouseUp()
    end

    if self._doubleClick or self._click or self._dragging or self._beginDrag or self._endDrag or self._longPress then
        return true
    end

    return false
end

---检测是单击还是双击
function HandleInputSystem_Render:_OnMouseClick()
    local currentTimeMS = self._timeService:GetCurrentTimeMs()
    if currentTimeMS - self._lastClickTime < HelperProxy:GetInstance():GetFixTimeLen(222) then
        --Log.fatal("dobule Click >>>>Time ",UnityEngine.Time.frameCount)
        self._doubleClick = true
        self._lastDoubleClickTime = currentTimeMS
    else
        --Log.fatal("Click >>>>Time ",UnityEngine.Time.frameCount)
        self._click = true
    end
    self._lastClickTime = currentTimeMS
end

function HandleInputSystem_Render:_OnMouseHoldDown()
    local currentInputPos = UnityEngine.Input.mousePosition
    local currentTimeMS = self._timeService:GetCurrentTimeMs()
    if self._heldDown ~= true then
        self._lastHeldDownTime = currentTimeMS
        self._heldDownPos = currentInputPos
        self._heldDown = true
    end
    local deltaTime = currentTimeMS - self._lastHeldDownTime
    if deltaTime > 10 then
        self._longPress = true
        self._click = false

        if self._dragging == false then
            if self._beginDrag == false and self._doubleClick == false then
                --Log.fatal("SetBD true，DC:",self._doubleClick,";E:",self._endDrag," ",UnityEngine.Time.frameCount)
                self._beginDrag = true
            else
                if currentInputPos ~= self._heldDownPos then
                    self._dragging = true
                    self._beginDrag = false
                --Log.fatal("drag >>>>mouseButtonState ",mouseButtonState ," Time ",UnityEngine.Time.frameCount)
                end
            end
        end
    end
end

function HandleInputSystem_Render:_OnMouseUp()
    --Log.fatal("_OnMouseUp >>>>>>>>>>>",UnityEngine.Time.frameCount)
    if self._dragging == true or self._beginDrag == true then
        self._endDrag = true
    end

    self._lastHeldDownTime = 0
    self._heldDown = false
    self._longPress = false
    self._beginDrag = false
    self._dragging = false
    self._click = false
    self._doubleClick = false
end

function HandleInputSystem_Render:_DoMultiPointRayCast()
    local camera = self._world:MainCamera()
    if not camera then
        return false
    end

    self._lastFramePosArray = {}
    local posData = InputHelper.LastFramePositionArray()
    --Log.fatal("posData count ",posData.Length)
    --for i = 0, posData.Length - 1 do
    --Log.fatal("posData ",posData[i])
    local inputPos = posData[0]
    local ray = camera:ScreenPointToRay(inputPos)
    local layMask = 2 ^ LayerMask.NameToLayer("Stage")
    local castRes, hitInfo = UnityEngine.Physics.Raycast(ray, nil, self._rayCastMaxDistance, layMask)
    if castRes == true then
        local isCastUI = self:_CheckInputPosCastUI(inputPos)
        if isCastUI == false then
            self._lastFramePosArray[#self._lastFramePosArray + 1] = hitInfo.point
        end
    end
    --end

    local hitInfoCount = #self._lastFramePosArray
    if hitInfoCount > 0 then
        return true
    end

    return false
end

function HandleInputSystem_Render:_DoRayCast()
    local camera = self._world:MainCamera()
    if not camera then
        return false
    end

    local inputPos = UnityEngine.Input.mousePosition
    local ray = camera:ScreenPointToRay(inputPos)
    local layMask = 2 ^ LayerMask.NameToLayer("Stage")
    local castRes, hitInfo = UnityEngine.Physics.Raycast(ray, nil, self._rayCastMaxDistance, layMask)
    if castRes == true then
        local isCastUI = self:_IsCastUI()
        if isCastUI then
            --Log.fatal("Cast UI >>>>>>>>>>>>")
            return false
        end
    end

    self._hitInfo = hitInfo

    --UnityEngine.Debug.DrawLine(ray.origin, hitInfo.point);

    return castRes
end

function HandleInputSystem_Render:_CheckInputPosCastUI(inputPos)
    local eventSystem = UnityEngine.EventSystems.EventSystem.current
    if InputHelper.IsPointerOverGameObject() then
        --todo 点击到UI元素，需要清空状态
        local pointer = UnityEngine.EventSystems.PointerEventData:New(eventSystem)
        pointer.position = inputPos
        local raycastResults = UIHelper.CreateEventSystemRaycastResultList()
        eventSystem:RaycastAll(pointer, raycastResults)

        for i = 1, raycastResults.Count do
            ---@type UnityEngine.GameObject
            local go = raycastResults:get_Item(i - 1).gameObject
            --Log.fatal(i..": "..go.name)
            local isContain = table.icontains(self._inputUIArray, go.name)
            if isContain == false then --无视背景mask
                self._inputComponent._touchHasBegin = false
                return true
            end
        end

    --Log.fatal("On Event System!!! currentInputModule name:"..UnityEngine.EventSystems.EventSystem.current.currentInputModule.name)
    end

    return false
end

function HandleInputSystem_Render:_IsCastUI()
    local inputPos = UnityEngine.Input.mousePosition
    local eventSystem = UnityEngine.EventSystems.EventSystem.current
    if InputHelper.IsPointerOverGameObject() then
        --todo 点击到UI元素，需要清空状态
        local pointer = UnityEngine.EventSystems.PointerEventData:New(eventSystem)
        pointer.position = inputPos
        local raycastResults = UIHelper.CreateEventSystemRaycastResultList()
        eventSystem:RaycastAll(pointer, raycastResults)

        for i = 1, raycastResults.Count do
            ---@type UnityEngine.GameObject
            local go = raycastResults:get_Item(i - 1).gameObject
            --Log.fatal(i..": "..go.name)
            if go.name ~= "black_mask" then --无视背景mask
                self._inputComponent._touchHasBegin = false
                return true
            end
        end

    --Log.fatal("On Event System!!! currentInputModule name:"..UnityEngine.EventSystems.EventSystem.current.currentInputModule.name)
    end
end

function HandleInputSystem_Render:InputDirty()
    local component = self._world:GetUniqueComponent(self._world.BW_UniqueComponentsEnum.Input)
    self._world:SetUniqueComponent(self._world.BW_UniqueComponentsEnum.Input, component)
end

function HandleInputSystem_Render:_PickUpDirty()
    local component = self._world:GetUniqueComponent(self._world.BW_UniqueComponentsEnum.PickUp)
    self._world:SetUniqueComponent(self._world.BW_UniqueComponentsEnum.PickUp, component)
end

function HandleInputSystem_Render:TouchDirty()
    local touchCmpt = self._world:GetUniqueComponent(self._world.BW_UniqueComponentsEnum.Touch)
    self._world:SetUniqueComponent(self._world.BW_UniqueComponentsEnum.Touch, touchCmpt)
end

function HandleInputSystem_Render:_ChessPickUpDirty()
    local component = self._world:GetUniqueComponent(self._world.BW_UniqueComponentsEnum.ChessPickUp)
    self._world:SetUniqueComponent(self._world.BW_UniqueComponentsEnum.ChessPickUp, component)
end

function HandleInputSystem_Render:_PopStarPickUpDirty()
    local component = self._world:GetUniqueComponent(self._world.BW_UniqueComponentsEnum.PopStarPickUp)
    self._world:SetUniqueComponent(self._world.BW_UniqueComponentsEnum.PopStarPickUp, component)
end

function HandleInputSystem_Render:_MiragePickUpDirty()
    local component = self._world:GetUniqueComponent(self._world.BW_UniqueComponentsEnum.MiragePickUp)
    self._world:SetUniqueComponent(self._world.BW_UniqueComponentsEnum.MiragePickUp, component)
end

function HandleInputSystem_Render:_CreateTestObj(hitPoint)
    if not EDITOR then --EDITOR环境下才显示
        return
    end
    if self.sphere == nil then
        self.sphere = UnityEngine.GameObject.CreatePrimitive(UnityEngine.PrimitiveType.Sphere)
        self.sphere.name = "Test"
        self.sphere.transform.localScale = Vector3(0.1, 0, 0.1)
    end
    local newPos = Vector3(hitPoint.x, hitPoint.y, hitPoint.z)
    self.sphere.transform.position = newPos
end

function HandleInputSystem_Render:_LookAtPlayer()
    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    if cameraCmpt == nil then
        return
    end

    if self._boardCenterObj == nil then
        self._boardCenterObj = UnityEngine.GameObject.CreatePrimitive(UnityEngine.PrimitiveType.Sphere)
        self._boardCenterObj.name = "BoardCenter"
        self._boardCenterObj.transform.localScale = Vector3(0.1, 0, 0.1)
        self._boardCenterObj.transform.position = Vector3(0, 0, 1)
    end

    local cameraObj = cameraCmpt:Camera()
    cameraObj.gameObject.transform:LookAt(self._boardCenterObj.transform)
end

function HandleInputSystem_Render:_CreateLookAtObj()
    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    if cameraCmpt == nil then
        return
    end

    local cameraObj = cameraCmpt:Camera()
    local cameraForward = cameraObj.gameObject.transform.forward
    local cameraPosition = cameraObj.gameObject.transform.position
    local castDistance = 2000
    local layMask = 2 ^ LayerMask.NameToLayer("Stage")
    local castRes, hitInfo = UnityEngine.Physics.Raycast(cameraPosition, cameraForward, nil, castDistance, layMask)
    if castRes ~= true then
        return
    end

    local hitPoint = hitInfo.point

    if self.sphere == nil then
        self.sphere = UnityEngine.GameObject.CreatePrimitive(UnityEngine.PrimitiveType.Sphere)
        self.sphere.name = "LookAt"
        --self.sphere.transform.localScale = Vector3(0.1,0.1,0.1)
        self.sphere.transform.localScale = Vector3(0.1, 0, 0.1)
    end

    --local newPos = Vector3(hitPoint.x,0.15,hitPoint.z)
    local newPos = Vector3(hitPoint.x, hitPoint.y, hitPoint.z)
    self.sphere.transform.position = newPos

    local rayDistance = Vector3.Distance(cameraPosition, hitPoint)
    UnityEngine.Debug.DrawRay(cameraPosition, cameraForward * rayDistance, Color.green)
end

function HandleInputSystem_Render:CancelChainPath()
    self:_OnMouseUp()

    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    if cameraCmpt:IsFocusPlayer() then
        cameraCmpt:DoMoveCamera(false)
    end

    self._lastMousePosition = nil

    Log.notice("HandleInput CancelChainPath")
end

function HandleInputSystem_Render:_IsWaitInputState()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local isInput = utilDataSvc:GetMainStateInputEnable()

    if self._inputComponent:IsPreviewActiveSkill() then
        isInput = true
    end
    return isInput
end

function HandleInputSystem_Render:_IsActiveSkillInputState()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()

    if gameFsmStateID == GameStateID.PickUpActiveSkillTarget or gameFsmStateID == GameStateID.PreviewActiveSkill then
        return true
    end
    if gameFsmStateID == GameStateID.PickUpChainSkillTarget then --拾取连锁
        return true
    end

    return false
end

function HandleInputSystem_Render:_IsMirageWaitInputState()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()

    if gameFsmStateID == GameStateID.MirageWaitInput then
        if not utilDataSvc:GetStatAutoFight() then
            return true
        end
    end

    return false
end

---检测滑屏操作
function HandleInputSystem_Render:_UpdateTouchState()
    ---@type GridTouchComponent
    local gridTouchComponent = self._world:GridTouch()
    local touchState = gridTouchComponent:GetGridTouchStateID()

    ---@type MainCameraComponent
    local mainCameraCmpt = self._world:MainCamera()

    if touchState == GridTouchStateID.Drag and mainCameraCmpt:IsMovingToFocus() then
        mainCameraCmpt:MoveCameraToFocusImmediately()
    end

    local isFocusPlayer = mainCameraCmpt:IsFocusPlayer()
    if not isFocusPlayer then
        self._lastMousePosition = nil
        return
    end

    local curMousePos = UnityEngine.Input.mousePosition
    if self._lastMousePosition == nil then
        self._lastMousePosition = curMousePos
    end

    local mouseHoldDown = UnityEngine.Input.GetMouseButton(0)
    if not mouseHoldDown then
        --没有按下，返回
        return
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    ---@type LevelCameraParam
    local cameraParam = levelConfigData:GetCameraParam()

    --local moveSpeed = BattleConst.TouchMoveCameraSpeed
    local moveSpeed = cameraParam:GetTouchMoveCameraSpeed()
    local hitPoint = self:_CalcHitPoint(curMousePos)
    if hitPoint ~= nil then

        local moveEdge = cameraParam:GetMoveCameraEdge()
        local moveEdgeSpeed = cameraParam:GetTouchMoveCameraEdgeSpeed()


        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        local gridPos = boardServiceRender:BoardRenderPos2FloatGridPos(hitPoint)

        local x = math.abs(gridPos.x)
        local y = math.abs(gridPos.y)
        if x <= 1 or y <= 1 or x >= moveEdge or y >= moveEdge then
            --Log.fatal("curMousePos",curMousePos,"gridPos",gridPos)
            moveSpeed = moveEdgeSpeed
        end

        local modifiedSpeed = self:_DoModifyCameraMoveFactor(x,y)
        if modifiedSpeed then 
            moveSpeed = modifiedSpeed
        end
    end

    ---移动
    local mouseDelta = curMousePos - self._lastMousePosition
    local deltaMove = mouseDelta * moveSpeed

    ---@type MainCameraComponent
    local mainCameraCmpt = self._world:MainCamera()
    local cameraCmpt = mainCameraCmpt:Camera()
    local targetCameraPos = self:_CalcTargetCameraPos(deltaMove)
    --cameraCmpt.transform:DOMove(targetCameraPos,BattleConst.MoveCameraToDeltaTime,false)
    cameraCmpt.transform.position = targetCameraPos

    --设置上次移动位置
    self._lastMousePosition = curMousePos
end

function HandleInputSystem_Render:_CalcTargetCameraPos(moveDir)
    ---@type MainCameraComponent
    local mainCameraCmpt = self._world:MainCamera()
    local cameraObj = mainCameraCmpt:Camera()

    local curCameraPos = cameraObj.transform.position
    local worldMoveDir = cameraObj.transform:TransformDirection(moveDir)
    local targetCameraPos = curCameraPos + worldMoveDir

    local targetFocusPos = mainCameraCmpt:GetFocusTargetPos()

    if targetFocusPos ~= nil then
        local deltaDir = targetCameraPos - targetFocusPos
        local localDeltaDir = cameraObj.transform:InverseTransformDirection(deltaDir)

            ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type LevelConfigData
        local levelConfigData = configService:GetLevelConfigData()
        ---@type LevelCameraParam
        local cameraParam = levelConfigData:GetCameraParam()
        local cameraMaxHorizatalLeft = cameraParam:GetCameraMaxHorizatalLeft()
        local cameraMaxHorizatalRight = cameraParam:GetCameraMaxHorizatalRight()
        local cameraMaxVerticalUp = cameraParam:GetCameraMaxVerticalUp()
        local cameraMaxVerticalDown = cameraParam:GetCameraMaxVerticalDown()

        ---检查左右边界
        if localDeltaDir.x < 0 and math.abs(localDeltaDir.x) > cameraMaxHorizatalLeft then
            ---左
            localDeltaDir.x = -cameraMaxHorizatalLeft
        elseif localDeltaDir.x > 0 and localDeltaDir.x > cameraMaxHorizatalRight then
            ---右
            localDeltaDir.x = cameraMaxHorizatalRight
        end

        -- 检查上下边界
        if localDeltaDir.y > 0 and localDeltaDir.y > cameraMaxHorizatalRight then
            ---上
            localDeltaDir.y = cameraMaxHorizatalRight
        elseif localDeltaDir.y < 0 and math.abs(localDeltaDir.y) > cameraMaxVerticalDown then
            ---下
            localDeltaDir.y = -cameraMaxVerticalDown
        end

        targetCameraPos = targetFocusPos + cameraObj.transform:TransformDirection(localDeltaDir)
    end

    return targetCameraPos
end

---计算当前的屏幕输入坐标对应的格子点
function HandleInputSystem_Render:_CalcHitPoint(inputPos)
    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    if cameraCmpt == nil then
        return nil
    end

    local ray = cameraCmpt:ScreenPointToRay(inputPos)
    local layMask = 2 ^ LayerMask.NameToLayer("Stage")
    local castRes, hitInfo = UnityEngine.Physics.Raycast(ray, nil, self._rayCastMaxDistance, layMask)
    if castRes == true then
        return hitInfo.point
    end

    return nil
end

function HandleInputSystem_Render:_DoModifyCameraMoveFactor(gridX,gridY)
    if not IsPc() then 
        return 
    end

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    ---@type LevelCameraParam
    local cameraParam = levelConfigData:GetCameraParam()
    local moveEdgeSpeed = cameraParam:GetTouchMoveCameraEdgeSpeed()

    local baseWidth = 1920
    local rate = baseWidth / UnityEngine.Screen.width
    local edgeFactor = moveEdgeSpeed * rate

    if gridY >= 5 then 
        return edgeFactor
    end
end