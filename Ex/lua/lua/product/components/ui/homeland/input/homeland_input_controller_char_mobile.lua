require("homeland_input_controller_char_base")

---@class HomelandInputControllerCharMobile:HomelandInputControllerCharBase
_class("HomelandInputControllerCharMobile", HomelandInputControllerCharBase)
HomelandInputControllerCharMobile = HomelandInputControllerCharMobile

function HomelandInputControllerCharMobile:Constructor()
end

---@param mainCharacterController HomelandMainCharacterController
---@param followCameraController HomelandFollowCameraController
function HomelandInputControllerCharMobile:Init(mainCharacterController, followCameraController)
    HomelandInputControllerCharMobile.super.Init(self, mainCharacterController, followCameraController)
    
    ---@type number
    self._rotateFactorX = 0.1
    ---@type number
    self._rotateFactorY = 0.05

    ---@type Vector2
    self._inputMoveVec = Vector2.zero
    ---@type Vector2
    self._movementVec = nil
    ---@type boolean
    self._moveInput = false
    ---@type boolean
    self._rotateInput = false

    self._moveType = HomelandCharMoveType.Idle
    self._guideLock = false
end

function HomelandInputControllerCharMobile:Leave()
    self:Reset()
end

function HomelandInputControllerCharMobile:Reset()
    self._inputMoveVec = Vector2.zero
    self._movementVec = nil
    self._moveInput = false
    self._rotateInput = false
    self._moveType = HomelandCharMoveType.Idle
end

function HomelandInputControllerCharMobile:OnUpdate(deltaTimeMS)
    if self._mainCharacterController:State() == HomelandActorStateType.Dash then
        return
    end

    if self._guideLock then
        return
    end

    if self._moveInput or self._rotateInput then
        if self._inputMoveVec.x ~= 0 or self._inputMoveVec.y ~= 0 then
            self._movementVec = self._followCameraController:CalcMovement(Vector3(self._inputMoveVec.x, 0, self._inputMoveVec.y))
        else
            self._movementVec = nil
        end
        self._moveInput = false
    end

    if self._movementVec and self._mainCharacterController:CanReceiveMoveInput() then
        if self:IsRushing() then
            self._mainCharacterController:Move(self._movementVec:SetNormalize(), HomelandCharMoveType.Rush, deltaTimeMS)
        else
            self._mainCharacterController:Move(self._movementVec:SetNormalize(), self._moveType, deltaTimeMS)
        end
    end
end

---@param moveVec Vector2
function HomelandInputControllerCharMobile:HandleMove(moveVec, moveState)
    self._inputMoveVec = moveVec
    self._moveType = moveState
    self._moveInput = true
end

---@param moveVec Vector2
function HomelandInputControllerCharMobile:HandleRotate(rotateVec)
    self._followCameraController:HandleRotate(rotateVec.x * self._rotateFactorX, rotateVec.y * self._rotateFactorY)
    self._rotateInput = true
end

---@param scale number
function HomelandInputControllerCharMobile:HandleScale(scale)
    self._followCameraController:HandleScale(scale)
end
--剧情下转视角
function HomelandInputControllerCharMobile:HandleRotateInInteract(rotateVec)
    self._followCameraController:HandleRotate(rotateVec.x, rotateVec.y)
end

function HomelandInputControllerCharMobile:SetGuideLock(guideLock)
    self._guideLock = guideLock
end