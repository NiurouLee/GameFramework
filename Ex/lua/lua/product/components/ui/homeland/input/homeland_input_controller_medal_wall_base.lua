---@class HomelandInputControllerMedalWallBase:Object
_class("HomelandInputControllerMedalWallBase", Object)
HomelandInputControllerMedalWallBase = HomelandInputControllerMedalWallBase

function HomelandInputControllerMedalWallBase:Constructor()
    self._speedMin = MedalWallConfig.SpeedMin
    self._speedMax = MedalWallConfig.SpeedMax
end

---@param mainCharacterController HomelandMainCharacterController
---@param medalWallCameraController HomelandMedalWallCameraController
function HomelandInputControllerMedalWallBase:Init(mainCharacterController, medalWallCameraController)
    self._mainCharacterController = mainCharacterController
    self._medalWallCameraController = medalWallCameraController
end

function HomelandInputControllerMedalWallBase:Dispose()
end

function HomelandInputControllerMedalWallBase:Update(deltaTimeMS)
end

---@param moveVec Vector2
function HomelandInputControllerMedalWallBase:HandleMove(moveVec)
end

---@param moveVec Vector2
function HomelandInputControllerMedalWallBase:HandleRotate(rotateVec)
end

---@param scale number
function HomelandInputControllerMedalWallBase:HandleScale(scale)
end

function HomelandInputControllerMedalWallBase:Enter(cameraTransform)
    self._medalWallCameraController:UpdateCameraTransform(cameraTransform)
end

---@param pos Vector2
function HomelandInputControllerMedalWallBase:HandleMedalClick(pos)
end

function HomelandInputControllerMedalWallBase:_GetMoveSpeed()
    return self._speedMin + self._medalWallCameraController:ScalePercent() * (self._speedMax - self._speedMin)
end
