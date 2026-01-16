---@class UnityEngine.EventSystems.BaseRaycaster : UnityEngine.EventSystems.UIBehaviour
---@field eventCamera UnityEngine.Camera
---@field sortOrderPriority int
---@field renderOrderPriority int
local m = {}
---@param eventData UnityEngine.EventSystems.PointerEventData
---@param resultAppendList table
function m:Raycast(eventData, resultAppendList) end
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.EventSystems = {}
UnityEngine.EventSystems.BaseRaycaster = m
return m