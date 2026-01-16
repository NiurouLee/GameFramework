require("homeland_input_controller_medal_wall_base")

---@class HomelandInputControllerMedalWallPC:HomelandInputControllerMedalWallBase
_class("HomelandInputControllerMedalWallPC", HomelandInputControllerMedalWallBase)
HomelandInputControllerMedalWallPC = HomelandInputControllerMedalWallPC

---@param homelandClient HomelandClient
function HomelandInputControllerMedalWallPC:Constructor(homelandClient)
    ---@type number
    self._mouseWheelFactor = MedalWallConfig.WheelFactor
    ---@type number
    self._clickInterval = 500

    ---@type UnityEngine.Input
    self._input = GameGlobal.EngineInput()
    ---@type HomelandClient
    self._homelandClient = homelandClient
    ---@type HomeBuildManager
    self._homelandBuildManager = self._homelandClient:BuildManager()
    ---@type UnityEngine.Camera
    self._medalWallCam = self._homelandClient:CameraManager():MedalWallCameraController():CameraCmp()

    ---@type number x轴输入
    self._inputX = 0
    ---@type number y轴输入
    self._inputY = 0

    ---@type boolean 鼠标按下并移动过
    self._mouseMoved = false
    ---@type number 按下时刻
    self._mouseDownTime = 0

    ---@type UnityEngine.EventSystems.EventSystem
    self._currentEvent = UnityEngine.EventSystems.EventSystem.current
end

function HomelandInputControllerMedalWallPC:Update(deltaTimeMS)
    ---键盘输入
    self._inputX = 0
    self._inputY = 0

    if (self._input.GetKey(UnityEngine.KeyCode.W)) then
        self._inputY = 1
    elseif (self._input.GetKey(UnityEngine.KeyCode.S)) then
        self._inputY = -1
    end

    if (self._input.GetKey(UnityEngine.KeyCode.A)) then
        self._inputX = -1
    elseif (self._input.GetKey(UnityEngine.KeyCode.D)) then
        self._inputX = 1
    end

    if self._inputX ~= 0 or self._inputY ~= 0 then
        local movementVec = Vector3(self._inputX, self._inputY, 0)
        movementVec = movementVec:SetNormalize()
        local percent = self:_GetMoveSpeed() * deltaTimeMS / 1000
        movementVec = movementVec * percent
        self._medalWallCameraController:HandleMove(movementVec.x, movementVec.y)
    end

    ---鼠标按键输入
    if self._input.GetMouseButtonDown(0) and not self._currentEvent:IsPointerOverGameObject() then
        self._mouseMoved = false
        self._mouseDownTime = GameGlobal:GetInstance():GetCurrentTime()
    end

    if self._input.GetMouseButtonUp(0) then
        if not self._mouseMoved and
            GameGlobal:GetInstance():GetCurrentTime() - self._mouseDownTime < self._clickInterval
        then
            self._homelandBuildManager:OnClickMedal(self._medalWallCam:ScreenPointToRay(self._input.mousePosition))
        end
    end

    ---鼠标移动输入
    if self._input.GetMouseButton(0) and not self._currentEvent:IsPointerOverGameObject() then
        local mx = self._input.GetAxis("Mouse X")
        local my = self._input.GetAxis("Mouse Y")
        local movementVec = Vector3(mx, my, 0)
        movementVec = movementVec:SetNormalize() * self:_GetMoveSpeed() * deltaTimeMS / 1000
        self._medalWallCameraController:HandleMove(movementVec.x, movementVec.y)
        self._mouseMoved = self._mouseMoved or mx ~= 0 and my ~= 0
        -- end
    end

    ---鼠标滚轮输入
    local mouseWheel = self._input.GetAxis("Mouse ScrollWheel")
    if mouseWheel ~= 0 then
        self._medalWallCameraController:HandleScale(mouseWheel * self._mouseWheelFactor)
    end
end
