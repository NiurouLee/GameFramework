require("homeland_input_controller_char_base")

---@class HomelandInputControllerCharPC:HomelandInputControllerCharBase
_class("HomelandInputControllerCharPC", HomelandInputControllerCharBase)
HomelandInputControllerCharPC = HomelandInputControllerCharPC

function HomelandInputControllerCharPC:Constructor()
    ---@type number x轴输入
    self._inputX = 0
    ---@type number z轴输入
    self._inputZ = 0
    ---@type UnityEngine.Input
    self._input = GameGlobal.EngineInput()

    ---@type UnityEngine.EventSystems.EventSystem
    self._currentEvent = UnityEngine.EventSystems.EventSystem.current

    self._ignoreControllers = {"UIFindTreasureMain"}
    self._guideLock = false
end

function HomelandInputControllerCharPC:OnUpdate(deltaTimeMS)
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

    if (self._inputX ~= 0 or self._inputZ ~= 0) and self._mainCharacterController:CanReceiveMoveInput() then
        local movement = self._followCameraController:CalcMovement(Vector3(self._inputX, 0, self._inputZ)):SetNormalize()
        if self:IsRushing() then
            self._mainCharacterController:Move(movement, HomelandCharMoveType.Rush, deltaTimeMS)
        else
            self._mainCharacterController:Move(movement, HomelandCharMoveType.Run, deltaTimeMS)
        end
    end

    -- if self._currentEvent:IsPointerOverGameObject() then
    --     Log.fatal("############################")
    -- end

    ---鼠标输入
    if self._input.GetMouseButton(0) and not self._currentEvent:IsPointerOverGameObject() then
        if GameGlobal.UIStateManager().uiControllerManager:TopDepth() < 1 or self:IsIgnoreControllersShow() then 
            local mx = self._input.GetAxis("Mouse X")
            local my = self._input.GetAxis("Mouse Y")
            self._followCameraController:HandleRotate(mx, my) 
        end 

        --[[
        if self.oldx ~= nil then
            local mx = self.oldx
            local my = self.oldy
            mx = (self._input.mousePosition.x - mx)*0.01
            my = (self._input.mousePosition.y - my)*0.01

            self._followCameraController:HandleRotate(mx, my)
        end
        self.oldx = self._input.mousePosition.x
        self.oldy = self._input.mousePosition.y
        
    else
        self.oldx = nil
        self.oldy = nil
        --]]
    end
    

    ---鼠标滚轮输入
    local mouseWheel = self._input.GetAxis("Mouse ScrollWheel")
    if mouseWheel ~= 0 then
        self._followCameraController:HandleScale(mouseWheel)
    end

    if self._input.GetKey(UnityEngine.KeyCode.UpArrow) 
    or self._input.GetKey(UnityEngine.KeyCode.DownArrow) 
    or self._input.GetKey(UnityEngine.KeyCode.LeftArrow) 
    or self._input.GetKey(UnityEngine.KeyCode.RightArrow) then
        local mx = 0
        local my = 0
        if self._input.GetKey(UnityEngine.KeyCode.UpArrow) then
            my = 0.1
        elseif self._input.GetKey(UnityEngine.KeyCode.DownArrow) then
            my = -0.1
        end

        if self._input.GetKey(UnityEngine.KeyCode.RightArrow) then
            mx = 0.1
        elseif self._input.GetKey(UnityEngine.KeyCode.LeftArrow) then
            mx = -0.1
        end
        self._followCameraController:HandleRotate(mx, my)
    end

end

--剧情下转视角
function HomelandInputControllerCharPC:HandleRotateInInteract(v2)
    self._followCameraController:HandleRotate(v2.x, v2.y)
end

function HomelandInputControllerCharPC:IsIgnoreControllersShow()
    for i = 1, #self._ignoreControllers do
        if GameGlobal.UIStateManager().uiControllerManager:IsShow(self._ignoreControllers[i]) then
            return true
        end
    end
    return false
end

function HomelandInputControllerCharPC:SetGuideLock(guideLock)
    self._guideLock = guideLock
end