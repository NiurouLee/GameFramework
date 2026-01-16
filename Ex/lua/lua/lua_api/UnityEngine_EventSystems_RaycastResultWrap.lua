---@class UnityEngine.EventSystems.RaycastResult
---@field gameObject UnityEngine.GameObject
---@field isValid bool
---@field module UnityEngine.EventSystems.BaseRaycaster
---@field distance float
---@field index float
---@field depth int
---@field sortingLayer int
---@field sortingOrder int
---@field worldPosition UnityEngine.Vector3
---@field worldNormal UnityEngine.Vector3
---@field screenPosition UnityEngine.Vector2
local m = {}
function m:Clear() end
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.EventSystems = {}
UnityEngine.EventSystems.RaycastResult = m
return m