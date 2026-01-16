require("homeland_input_controller_medal_wall_base")

---@class HomelandInputControllerMedalWallMobile:HomelandInputControllerMedalWallBase
_class("HomelandInputControllerMedalWallMobile", HomelandInputControllerMedalWallBase)
HomelandInputControllerMedalWallMobile = HomelandInputControllerMedalWallMobile

---@param homelandClient HomelandClient
function HomelandInputControllerMedalWallMobile:Constructor(homelandClient)
    self._homelandClient = homelandClient
end

---@param mainCharacterController HomelandMainCharacterController
---@param medalWallCameraController HomelandMedalWallCameraController
function HomelandInputControllerMedalWallMobile:Init(mainCharacterController, medalWallCameraController)
    HomelandInputControllerMedalWallMobile.super.Init(self, mainCharacterController, medalWallCameraController)

    ---@type HomeBuildManager
    self._homelandBuildManager = self._homelandClient:BuildManager()
    ---@type UnityEngine.Camera
    self._medalWallCamera = medalWallCameraController:CameraCmp()

    ---@type Vector2
    self._inputMoveVec = Vector2.zero
    ---@type Vector3
    self._movementVec = nil
    ---@type boolean
    self._moveInput = false

    self._moveXFactor = MedalWallConfig.MobileMoveXFactor
    self._moveYFactor = MedalWallConfig.MobileMoveYFactor

end

function HomelandInputControllerMedalWallMobile:Leave()
    self._inputMoveVec = Vector2.zero
    self._movementVec = nil
    self._moveInput = false
end

function HomelandInputControllerMedalWallMobile:Update(deltaTimeMS)
    if self._moveInput then
        if self._inputMoveVec.x ~= 0 or self._inputMoveVec.y ~= 0 then
            self._movementVec = Vector3(self._inputMoveVec.x, self._inputMoveVec.y, 0)
        else
            self._movementVec = nil
        end
        self._moveInput = false
    end

    if self._movementVec then
        local movementVec = self._movementVec:SetNormalize() * self:_GetMoveSpeed() * deltaTimeMS / 1000
        self._medalWallCameraController:HandleMove(movementVec.x, movementVec.y)
        self._movementVec = nil
    end
end

---@param moveVec Vector2
function HomelandInputControllerMedalWallMobile:HandleMove(moveVec)
    self._inputMoveVec = Vector2(moveVec.x * self._moveXFactor, moveVec.y * self._moveYFactor)
    self._moveInput = true
end

---@param scale number
function HomelandInputControllerMedalWallMobile:HandleScale(scale)
    self._medalWallCameraController:HandleScale(scale)
end

---@param pos Vector2
function HomelandInputControllerMedalWallMobile:HandleMedalClick(pos)
    self._homelandBuildManager:OnClickMedal(self._medalWallCamera:ScreenPointToRay(pos))
end
