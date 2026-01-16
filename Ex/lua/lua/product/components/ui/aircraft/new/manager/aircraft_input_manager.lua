--[[
    风船输入模块，支持按下、抬起、点击、拖拽、长按、缩放，包含鼠标和手势两套逻辑
]]
---@class AircraftInputManager:Object
_class("AircraftInputManager", Object)
AircraftInputManager = AircraftInputManager

---@type UnityEngine.Input
local unityInput = nil
---@type UnityEngine.EventSystems.EventSystem
local currentEvent = nil
local scrollAxis = nil

function AircraftInputManager:Constructor()
    unityInput = GameGlobal.EngineInput()
    currentEvent = UnityEngine.EventSystems.EventSystem.current
    scrollAxis = "Mouse ScrollWheel"

    ---@type boolean
    self._enabled = true
    ---@type boolean 是否在使用鼠标控制
    self._mousePresent = nil

    ---手指按下时记录的数据---
    self.mouseDown = false
    ---@type UnityEngine.Vector3
    self.downPos = nil
    ---@type boolean
    self.downOnUI = false
    ---end---

    ---上一帧的数据---
    self.lastMousePos = nil
    ---end---

    ---输出数据---
    ---点击
    ---@type boolean
    self._clicked = false
    ---@type Vector3
    self._clickPos = nil
    ---拖拽
    ---@type boolean
    self._dragging = false
    ---@type Vector3
    self._dragStartPos = nil
    ---@type Vector3
    self._dragEndPos = nil
    ---缩放
    ---@type boolean
    self._scaling = false
    ---@type number
    self._scaleLength = 0
    ---@type Vector2
    self._scaleCenterPos = Vector2.zero
    ---长按
    ---@type boolean
    self._longPressing = false
    self.longPressTime = 0
    self.longPresingPos = nil
    ---输出数据end---

    ---const
    ---@type number
    self._touchScaleRatio = Cfg.cfg_aircraft_camera["scaleRatio"].Value
    ---@type number
    self.longPressCheckTime = Cfg.cfg_aircraft_camera["longPressCheckTime"].Value
    local pixels = Cfg.cfg_aircraft_camera["clickAndDragPixelLength"].Value
    pixels = 10
    self.clickDragPixelLengthMag = pixels * pixels

    ---@type number
    self.longPressTimer = 0
end

---@return boolean
function AircraftInputManager:Init()
    self._mousePresent = unityInput.mousePresent
    UnityEngine.Input.multiTouchEnabled = true
    return true
end

function AircraftInputManager:Dispose()
    UnityEngine.Input.multiTouchEnabled = false
    unityInput = nil
    currentEvent = nil
    scrollAxis = nil
end

---@param enable boolean
function AircraftInputManager:SetEnable(enable)
    self._enabled = enable
    if not enable then
        self:_ResetInputData()
        self._clickPos = nil
        self.lastMousePos = nil
    end
end

--鼠标输入
function AircraftInputManager:MouseInput(deltaTime)
    local down = unityInput.GetMouseButtonDown(0)
    local hold = unityInput.GetMouseButton(0)
    local up = unityInput.GetMouseButtonUp(0)
    local mousePos = unityInput.mousePosition
    local onUI = currentEvent:IsPointerOverGameObject()

    ---click---
    self._clicked = false
    self._clickPos = nil
    if up then
        if self.mouseDown and not self.downOnUI and not onUI then
            if not self._dragging and not self._longPressing and not self._scaling then
                self._clicked = true
                self._clickPos = mousePos
            end
        end
    end
    ---end---

    ---longpress---
    self._longPressing = false
    self.longPressTime = 0
    self.longPresingPos = nil
    --拖拽发生后不可能再发生长按
    if not self._dragging and hold and not onUI then
        if self.mouseDown then
            if (mousePos - self.downPos).sqrMagnitude < self.clickDragPixelLengthMag then
                self.longPressTimer = self.longPressTimer + deltaTime
                if self.longPressTimer > self.longPressCheckTime then
                    self._longPressing = true
                    self.longPressTime = self.longPressTimer - self.longPressCheckTime
                    self.longPresingPos = mousePos
                end
            else
                self._longPressing = false
                self.longPressTime = 0
                self.longPressTimer = 0
                self.longPresingPos = nil
            end
        end
    elseif down then
        self.longPressTimer = 0
    elseif up then
        self._longPressing = false
        self.longPressTime = 0
        self.longPressTimer = 0
        self.longPresingPos = nil
    end
    ---end---

    ---drag---
    if self._dragging then
        --一旦发生拖拽，除非拖到ui上或抬起，否则不会发生状态变化
        if onUI or up then
            self._dragging = false
            self._dragStartPos = nil
            self._dragEndPos = nil
        else
            self._dragStartPos = self.lastMousePos
            self._dragEndPos = mousePos
        end
    else
        if hold and not onUI and self.mouseDown and self.lastMousePos and not self.downOnUI then
            if (mousePos - self.downPos).sqrMagnitude > self.clickDragPixelLengthMag then
                self._dragging = true
                self._dragStartPos = self.lastMousePos
                self._dragEndPos = mousePos
            end
        end
    end
    ---end---

    ---scale---
    self._scaleLength = 0
    self._scaling = false
    self._scaleCenterPos = nil
    if down or up or hold or onUI then
    else
        self._scaleLength = unityInput.GetAxis(scrollAxis)
        self._scaling = self._scaleLength ~= 0
        self._scaleCenterPos = mousePos
    end
    ---end---

    --在pc上快速点击，同一帧里可能同时触发按下和抬起
    if down and not up and not self.mouseDown then
        self.mouseDown = true
        self.downPos = mousePos
        self.downOnUI = onUI
    elseif up and not down and self.mouseDown then
        self.mouseDown = false
        self.downPos = nil
        self.downOnUI = false
    end

    ---down---
    self._down = down and not onUI and not up
    ---end---

    ---up---
    self._up = up and not down
    if up then
        self._upPos = mousePos
    end
    ---end---

    self.lastMousePos = mousePos
end

--触摸输入
function AircraftInputManager:TouchInput(deltaTime)
    local touchCount = unityInput.touchCount
    local touch0 = nil
    if touchCount > 0 then
        touch0 = unityInput.GetTouch(0)
    end
    local mousePos = nil
    local touch0OnUI = false
    if touch0 then
        touch0OnUI = currentEvent:IsPointerOverGameObject(touch0.fingerId)
        mousePos = touch0.position
    end
    local touch1 = nil
    if touchCount > 1 then
        touch1 = unityInput.GetTouch(1)
    end
    local touch1OnUI = false
    if touch1 then
        touch1OnUI = currentEvent:IsPointerOverGameObject(touch1.fingerId)
    end

    ---click---
    self._clicked = false
    self._clickPos = nil
    if touch0 and touch0.phase == TouchPhase.Ended then
        if self.mouseDown and not self.downOnUI and not touch0OnUI and not touch1 then
            if not self._dragging and not self._longPressing and not self._scaling then
                self._clicked = true
                self._clickPos = mousePos
            end
        end
    end
    ---end---

    ---longpress---
    self._longPressing = false
    self.longPressTime = 0
    self.longPresingPos = nil
    if touch0 then
        if touch0OnUI or touch1 then
            self._longPressing = false
            self.longPressTimer = 0
            self.longPressTime = 0
            self.longPresingPos = nil
        elseif (touch0.phase == TouchPhase.Moved or touch0.phase == TouchPhase.Stationary) and self.mouseDown then
            --手指静止或移动
            if (self.downPos - touch0.position).sqrMagnitude < self.clickDragPixelLengthMag then
                self.longPressTimer = self.longPressTimer + deltaTime
                if self.longPressTimer > self.longPressCheckTime then
                    self._longPressing = true
                    self.longPressTime = self.longPressTimer - self.longPressCheckTime
                    self.longPresingPos = Vector3(touch0.position.x, touch0.position.y, 0)
                end
            else
                self._longPressing = false
                self.longPressTime = 0
                self.longPressTimer = 0
                self.longPresingPos = nil
            end
        elseif touch0.phase == TouchPhase.Ended then
            self._longPressing = false
            self.longPressTime = 0
            self.longPressTimer = 0
            self.longPresingPos = nil
        end
    end
    ---end---

    ---drag---
    if touch0 then
        if touch1 then
            --拖拽操作只适应于单指操作
            self._dragging = false
            self._dragStartPos = nil
            self._dragEndPos = nil
        elseif self._dragging then
            if touch0OnUI or touch0.phase == TouchPhase.Ended then
                self._dragging = false
                self._dragStartPos = nil
                self._dragEndPos = nil
            else
                self._dragStartPos =
                    Vector3(touch0.position.x - touch0.deltaPosition.x, touch0.position.y - touch0.deltaPosition.y, 0)
                self._dragEndPos = Vector3(touch0.position.x, touch0.position.y, 0)
            end
        else
            if
                (touch0.phase == TouchPhase.Moved or touch0.phase == TouchPhase.Stationary) and not touch0OnUI and
                    self.mouseDown and
                    not self.downOnUI
             then
                if (mousePos - self.downPos).sqrMagnitude > self.clickDragPixelLengthMag then
                    self._dragging = true
                    self._dragStartPos =
                        Vector3(
                        touch0.position.x - touch0.deltaPosition.x,
                        touch0.position.y - touch0.deltaPosition.y,
                        0
                    )
                    self._dragEndPos = Vector3(touch0.position.x, touch0.position.y, 0)
                end
            end
        end
    end
    ---end---

    ---scale---
    self._scaleLength = 0
    self._scaling = false
    self._scaleCenterPos = nil
    local onui = touch0OnUI or touch1OnUI
    if touch0 and touch1 and (not onui) and (touch0.phase == TouchPhase.Moved or touch1.phase == TouchPhase.Moved) then
        local lastLength =
            Vector2.Distance(touch0.position - touch0.deltaPosition, touch1.position - touch1.deltaPosition)
        local length = Vector2.Distance(touch0.position, touch1.position)
        self._scaleLength = (length - lastLength) * self._touchScaleRatio
        local centerPos = (touch0.position + touch1.position) / 2
        self._scaleCenterPos = Vector3(centerPos.x, centerPos.y, 0)
        self._scaling = true
    end
    ---end---

    if touch0 then
        if touch0.phase == TouchPhase.Began and not self.mouseDown then
            self.mouseDown = true
            self.downPos = touch0.position
            self.downOnUI = touch0OnUI
        elseif (touch0.phase == TouchPhase.Ended or touch0.phase == TouchPhase.Canceled) and self.mouseDown then
            self.mouseDown = false
            self.downPos = nil
            self.downOnUI = false
        end
    end

    ---down---
    self._down = touch0 and touch0.phase == TouchPhase.Began and not touch0OnUI
    ---end---

    ---up---
    self._up = touch0 and touch0.phase == TouchPhase.Ended --抬起不判定是否在ui上
    if self._up then
        self._upPos = touch0.position
    end
    ---end---

    self.lastMousePos = mousePos
end

---@param deltaTimeMS number1
function AircraftInputManager:Update(deltaTimeMS)
    if not self._enabled then
        return
    end

    if self._mousePresent then
        self:MouseInput(deltaTimeMS / 1000)
    else
        self:TouchInput(deltaTimeMS / 1000)
    end
end

function AircraftInputManager:_ResetInputData()
    self._clicked = false
    self._clickPos = nil
    self._dragging = false
    self._dragStartPos = nil
    self._dragEndPos = nil
    self._scaling = false
    self._scaleLength = 0
    self._scaleCenterPos = nil
    self._longPressing = false
    self.longPressTime = 0
    self.longPresingPos = nil

    self.longPressTimer = 0
    self.mouseDown = false
    self.downOnUI = false
    self.downPos = nil
    self.lastMousePos = nil
end

---@return boolean, Vector3
function AircraftInputManager:GetClick()
    return self._clicked, self._clickPos
end

---@return boolean, Vector3, Vector3
function AircraftInputManager:GetDrag()
    return self._dragging, self._dragStartPos, self._dragEndPos
end

---@return boolean, number, Vector3
function AircraftInputManager:GetScale()
    return self._scaling, self._scaleLength, self._scaleCenterPos
end

function AircraftInputManager:GetLongPress()
    return self._longPressing, self.longPressTime, self.longPresingPos
end

function AircraftInputManager:GetMouseDown()
    return self._down, self.downPos
end

function AircraftInputManager:GetMouseUp()
    return self._up, self._upPos
end
