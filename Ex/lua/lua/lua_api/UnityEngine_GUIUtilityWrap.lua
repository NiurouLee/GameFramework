---@class UnityEngine.GUIUtility : object
---@field hasModalWindow bool
---@field systemCopyBuffer string
---@field hotControl int
---@field keyboardControl int
local m = {}
---@overload fun(focus:UnityEngine.FocusType):int
---@overload fun(contents:UnityEngine.GUIContent, focus:UnityEngine.FocusType):int
---@overload fun(focus:UnityEngine.FocusType, position:UnityEngine.Rect):int
---@overload fun(contents:UnityEngine.GUIContent, focus:UnityEngine.FocusType, position:UnityEngine.Rect):int
---@overload fun(hint:int, focus:UnityEngine.FocusType):int
---@param hint int
---@param focusType UnityEngine.FocusType
---@param rect UnityEngine.Rect
---@return int
function m.GetControlID(hint, focusType, rect) end
---@overload fun(rect:UnityEngine.Rect):UnityEngine.Rect
---@param rect UnityEngine.Rect
---@param widthInPixels int
---@param heightInPixels int
---@return UnityEngine.Rect
function m.AlignRectToDevice(rect, widthInPixels, heightInPixels) end
---@param t System.Type
---@param controlID int
---@return object
function m.GetStateObject(t, controlID) end
---@param t System.Type
---@param controlID int
---@return object
function m.QueryStateObject(t, controlID) end
function m.ExitGUI() end
---@param guiPoint UnityEngine.Vector2
---@return UnityEngine.Vector2
function m.GUIToScreenPoint(guiPoint) end
---@param screenPoint UnityEngine.Vector2
---@return UnityEngine.Vector2
function m.ScreenToGUIPoint(screenPoint) end
---@param screenRect UnityEngine.Rect
---@return UnityEngine.Rect
function m.ScreenToGUIRect(screenRect) end
---@param angle float
---@param pivotPoint UnityEngine.Vector2
function m.RotateAroundPivot(angle, pivotPoint) end
---@param scale UnityEngine.Vector2
---@param pivotPoint UnityEngine.Vector2
function m.ScaleAroundPivot(scale, pivotPoint) end
UnityEngine = {}
UnityEngine.GUIUtility = m
return m