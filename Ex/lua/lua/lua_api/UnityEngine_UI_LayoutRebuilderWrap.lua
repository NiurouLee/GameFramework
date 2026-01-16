---@class UnityEngine.UI.LayoutRebuilder : object
---@field transform UnityEngine.Transform
local m = {}
---@return bool
function m:IsDestroyed() end
---@param layoutRoot UnityEngine.RectTransform
function m.ForceRebuildLayoutImmediate(layoutRoot) end
---@param executing UnityEngine.UI.CanvasUpdate
function m:Rebuild(executing) end
---@param rect UnityEngine.RectTransform
function m.MarkLayoutForRebuild(rect) end
function m:LayoutComplete() end
function m:GraphicUpdateComplete() end
---@return int
function m:GetHashCode() end
---@param obj object
---@return bool
function m:Equals(obj) end
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.LayoutRebuilder = m
return m