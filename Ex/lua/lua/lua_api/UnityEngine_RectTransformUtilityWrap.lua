---@class UnityEngine.RectTransformUtility : object
local m = {}
---@overload fun(rect:UnityEngine.RectTransform, screenPoint:UnityEngine.Vector2, cam:UnityEngine.Camera):bool
---@param rect UnityEngine.RectTransform
---@param screenPoint UnityEngine.Vector2
---@return bool
function m.RectangleContainsScreenPoint(rect, screenPoint) end
---@param rect UnityEngine.RectTransform
---@param screenPoint UnityEngine.Vector2
---@param cam UnityEngine.Camera
---@param worldPoint UnityEngine.Vector3
---@return bool
function m.ScreenPointToWorldPointInRectangle(rect, screenPoint, cam, worldPoint) end
---@param rect UnityEngine.RectTransform
---@param screenPoint UnityEngine.Vector2
---@param cam UnityEngine.Camera
---@param localPoint UnityEngine.Vector2
---@return bool
function m.ScreenPointToLocalPointInRectangle(rect, screenPoint, cam, localPoint) end
---@param cam UnityEngine.Camera
---@param screenPos UnityEngine.Vector2
---@return UnityEngine.Ray
function m.ScreenPointToRay(cam, screenPos) end
---@param cam UnityEngine.Camera
---@param worldPoint UnityEngine.Vector3
---@return UnityEngine.Vector2
function m.WorldToScreenPoint(cam, worldPoint) end
---@overload fun(trans:UnityEngine.Transform):UnityEngine.Bounds
---@param root UnityEngine.Transform
---@param child UnityEngine.Transform
---@return UnityEngine.Bounds
function m.CalculateRelativeRectTransformBounds(root, child) end
---@param rect UnityEngine.RectTransform
---@param axis int
---@param keepPositioning bool
---@param recursive bool
function m.FlipLayoutOnAxis(rect, axis, keepPositioning, recursive) end
---@param rect UnityEngine.RectTransform
---@param keepPositioning bool
---@param recursive bool
function m.FlipLayoutAxes(rect, keepPositioning, recursive) end
---@param point UnityEngine.Vector2
---@param elementTransform UnityEngine.Transform
---@param canvas UnityEngine.Canvas
---@return UnityEngine.Vector2
function m.PixelAdjustPoint(point, elementTransform, canvas) end
---@param rectTransform UnityEngine.RectTransform
---@param canvas UnityEngine.Canvas
---@return UnityEngine.Rect
function m.PixelAdjustRect(rectTransform, canvas) end
UnityEngine = {}
UnityEngine.RectTransformUtility = m
return m