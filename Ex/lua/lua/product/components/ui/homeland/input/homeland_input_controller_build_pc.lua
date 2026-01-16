require("homeland_input_controller_build_base")

---@class HomelandInputControllerBuildPC:HomelandInputControllerBuildBase
_class("HomelandInputControllerBuildPC", HomelandInputControllerBuildBase)
HomelandInputControllerBuildPC = HomelandInputControllerBuildPC

---@param homelandClient HomelandClient
function HomelandInputControllerBuildPC:Constructor(homelandClient)
    ---@type number
    self._rotateFactorX = 0.5
    ---@type number
    self._rotateFactorY = 0.5
    ---@type number
    self._mouseWheelFactor = 10
    ---@type number
    self._clickInterval = 500

    ---@type UnityEngine.Input
    self._input = GameGlobal.EngineInput()
    ---@type HomelandClient
    self._homelandClient = homelandClient
    ---@type HomeBuildManager
    self._homdelandBuildManager = self._homelandClient:BuildManager()
    ---@type UnityEngine.Camera
    self._buildCam = self._homelandClient:CameraManager():GlobalCameraController():CameraCmp()

    ---@type number x轴输入
    self._inputX = 0
    ---@type number z轴输入
    self._inputZ = 0

    ---@type boolean 鼠标按下并移动过
    self._mouseMoved = false
    ---@type number 按下时刻
    self._mouseDownTime = 0

    ---@type UnityEngine.EventSystems.EventSystem
    self._currentEvent = UnityEngine.EventSystems.EventSystem.current
    self._guideLock = false
end

function HomelandInputControllerBuildPC:Update(deltaTimeMS)
    ---键盘输入
    self._inputX = 0
    self._inputZ = 0

    if self._guideLock then
        return
    end

    if (self._input.GetKey(UnityEngine.KeyCode.W)) then
        self._inputZ = 1
    elseif (self._input.GetKey(UnityEngine.KeyCode.S)) then
        self._inputZ = -1
    end

    if (self._input.GetKey(UnityEngine.KeyCode.A)) then
        self._inputX = -1
    elseif (self._input.GetKey(UnityEngine.KeyCode.D)) then
        self._inputX = 1
    end

    if self._inputX ~= 0 or self._inputZ ~= 0 then
        local movementVec = Vector3(self._inputX, 0, self._inputZ)
        self._globalCameraController:Move(movementVec:SetNormalize() * self:_GetMoveSpeed() * deltaTimeMS / 1000)
        self:CheckAndLimitMovePos()
    end

    ---鼠标按键输入
    if self._input.GetMouseButtonDown(0) and not self._currentEvent:IsPointerOverGameObject() then
        if
            self._curBuildingInfo and
                self._homdelandBuildManager:PressBuilding(self._buildCam:ScreenPointToRay(self._input.mousePosition)) ==
                    self._curBuildingInfo
         then
            self._touchBuilding = true
        else
            self._mouseMoved = false
            self._mouseDownTime = GameGlobal:GetInstance():GetCurrentTime()
        end
    end

    if self._input.GetMouseButtonUp(0) then
        if self._dragInBuildingID then
            self._dragInBuildingID = nil
        elseif self._touchBuilding then
            self._touchBuilding = false
            self._homdelandBuildManager:ReleaseTouch()
        elseif
            not self._mouseMoved and
                GameGlobal:GetInstance():GetCurrentTime() - self._mouseDownTime < self._clickInterval
         then
            self._curBuildingInfo =
                self._homdelandBuildManager:SelectBuilding(self._buildCam:ScreenPointToRay(self._input.mousePosition))
        --Log.fatal("Select:"..tostring(self._input.mousePosition))
        end
    end

    ---鼠标移动输入
    if self._input.GetMouseButton(0) and not self._currentEvent:IsPointerOverGameObject() then
        if self._dragInBuildingID then
            local ray = self._buildCam:ScreenPointToRay(self._input.mousePosition)
            if self._homdelandBuildManager:RayTargetInCircle(ray) then
                self._touchBuilding = true
                self._curBuildingInfo = self._homdelandBuildManager:Add(self._dragInBuildingID, ray)
                self._homdelandBuildManager:PressBuilding(ray)
                self._dragInBuildingID = nil
            end
        elseif self._touchBuilding then
            self._homdelandBuildManager:DragBuilding(self._buildCam:ScreenPointToRay(self._input.mousePosition))
        else
            local mx = self._input.GetAxis("Mouse X")
            local my = self._input.GetAxis("Mouse Y")
            self._globalCameraController:HandleRotate(mx * self._rotateFactorX, my * self._rotateFactorY)
            self._mouseMoved = self._mouseMoved or mx ~= 0 and my ~= 0
        end
    end

    ---鼠标滚轮输入
    local mouseWheel = self._input.GetAxis("Mouse ScrollWheel")
    if mouseWheel ~= 0 then
        self._globalCameraController:HandleScale(mouseWheel * self._mouseWheelFactor)
    end
end

---@param info HomeBuilding
function HomelandInputControllerBuildPC:SetCurrentBuilding(info)
    self._curBuildingInfo = info
    if info == nil then
        self._touchBuilding = false
    end
end

function HomelandInputControllerBuildPC:HandleDragIn(buildingID)
    self._dragInBuildingID = buildingID
end

function HomelandInputControllerBuildPC:SetGuideLock(guideLock)
    self._guideLock = guideLock
end