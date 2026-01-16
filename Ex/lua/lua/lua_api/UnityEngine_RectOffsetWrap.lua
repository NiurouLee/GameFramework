---@class UnityEngine.RectOffset : object
---@field left int
---@field right int
---@field top int
---@field bottom int
---@field horizontal int
---@field vertical int
local m = {}
---@param rect UnityEngine.Rect
---@return UnityEngine.Rect
function m:Add(rect) end
---@param rect UnityEngine.Rect
---@return UnityEngine.Rect
function m:Remove(rect) end
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.RectOffset = m
return m