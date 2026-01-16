---@class HomelandInputControllerCharBase:Object
_class("HomelandInputControllerCharBase", Object)
HomelandInputControllerCharBase = HomelandInputControllerCharBase

function HomelandInputControllerCharBase:Constructor()
    self._active = false
    self._dashHolding = false
    self._rushing = false
end

---@param mainCharacterController HomelandMainCharacterController
---@param followCameraController HomelandFollowCameraController
function HomelandInputControllerCharBase:Init(mainCharacterController, followCameraController)
    self._mainCharacterController = mainCharacterController
    self._followCameraController = followCameraController
    self:SetActive(true)
end

function HomelandInputControllerCharBase:SetActive(active)
    self._active = active
end

function HomelandInputControllerCharBase:Dispose()
end

function HomelandInputControllerCharBase:Update(deltaTimeMS)
    if self._active then
        self:OnUpdate(deltaTimeMS)
    end
end

---@param moveVec Vector2
function HomelandInputControllerCharBase:HandleMove(moveVec, moveState)
end

---@param moveVec Vector2
function HomelandInputControllerCharBase:HandleRotate(rotateVec)
end

---@param scale number
function HomelandInputControllerCharBase:HandleScale(scale)
end
--开始冲刺，按下按钮
function HomelandInputControllerCharBase:DashStart()
    self._dashHolding = true
    self._mainCharacterController:Dash(
        function()
            self:DashUpdateCallback()
        end
    )
end
--松开冲刺按钮
function HomelandInputControllerCharBase:DashRelease()
    self._dashHolding = false
    self._rushing = false
end
--结束冲刺，0.3s
function HomelandInputControllerCharBase:DashEnd()
    self._rushing = self._dashHolding --结束冲刺的时候是否快跑，取决于是否还按着冲刺按钮
end
--是否正在快跑
function HomelandInputControllerCharBase:IsRushing()
    return self._rushing
end

function HomelandInputControllerCharBase:DashUpdateCallback()
    self._followCameraController:UpdatePos(self._mainCharacterController:Position())
end

function HomelandInputControllerCharBase:Enter()
    self._followCameraController:UpdatePos(self._mainCharacterController:Position())
end
