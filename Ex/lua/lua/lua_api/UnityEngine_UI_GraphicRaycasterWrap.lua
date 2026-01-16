---@class UnityEngine.UI.GraphicRaycaster : UnityEngine.EventSystems.BaseRaycaster
---@field sortOrderPriority int
---@field renderOrderPriority int
---@field ignoreReversedGraphics bool
---@field blockingObjects UnityEngine.UI.GraphicRaycaster.BlockingObjects
---@field eventCamera UnityEngine.Camera
local m = {}
---@param eventData UnityEngine.EventSystems.PointerEventData
---@param resultAppendList table
function m:Raycast(eventData, resultAppendList) end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.GraphicRaycaster = m
return m