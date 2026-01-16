---@class UnityEngine.Input : object
---@field simulateMouseWithTouches bool
---@field anyKey bool
---@field anyKeyDown bool
---@field inputString string
---@field mousePosition UnityEngine.Vector3
---@field mouseScrollDelta UnityEngine.Vector2
---@field imeCompositionMode UnityEngine.IMECompositionMode
---@field compositionString string
---@field imeIsSelected bool
---@field compositionCursorPos UnityEngine.Vector2
---@field mousePresent bool
---@field touchCount int
---@field touchPressureSupported bool
---@field stylusTouchSupported bool
---@field touchSupported bool
---@field multiTouchEnabled bool
---@field deviceOrientation UnityEngine.DeviceOrientation
---@field acceleration UnityEngine.Vector3
---@field compensateSensors bool
---@field accelerationEventCount int
---@field backButtonLeavesApp bool
---@field compass UnityEngine.Compass
---@field gyro UnityEngine.Gyroscope
---@field touches table
---@field accelerationEvents table
local m = {}
---@param axisName string
---@return float
function m.GetAxis(axisName) end
---@param axisName string
---@return float
function m.GetAxisRaw(axisName) end
---@param buttonName string
---@return bool
function m.GetButton(buttonName) end
---@param buttonName string
---@return bool
function m.GetButtonDown(buttonName) end
---@param buttonName string
---@return bool
function m.GetButtonUp(buttonName) end
---@param button int
---@return bool
function m.GetMouseButton(button) end
---@param button int
---@return bool
function m.GetMouseButtonDown(button) end
---@param button int
---@return bool
function m.GetMouseButtonUp(button) end
function m.ResetInputAxes() end
---@return table
function m.GetJoystickNames() end
---@param index int
---@return UnityEngine.Touch
function m.GetTouch(index) end
---@param index int
---@return UnityEngine.AccelerationEvent
function m.GetAccelerationEvent(index) end
---@overload fun(name:string):bool
---@param key UnityEngine.KeyCode
---@return bool
function m.GetKey(key) end
---@overload fun(name:string):bool
---@param key UnityEngine.KeyCode
---@return bool
function m.GetKeyUp(key) end
---@overload fun(name:string):bool
---@param key UnityEngine.KeyCode
---@return bool
function m.GetKeyDown(key) end
UnityEngine = {}
UnityEngine.Input = m
return m