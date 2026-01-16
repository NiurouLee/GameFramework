---@class UnityEngine.Display : object
---@field renderingWidth int
---@field renderingHeight int
---@field systemWidth int
---@field systemHeight int
---@field colorBuffer UnityEngine.RenderBuffer
---@field depthBuffer UnityEngine.RenderBuffer
---@field active bool
---@field main UnityEngine.Display
---@field displays table
local m = {}
---@overload fun(width:int, height:int, refreshRate:int):void
function m:Activate() end
---@param width int
---@param height int
---@param x int
---@param y int
function m:SetParams(width, height, x, y) end
---@param w int
---@param h int
function m:SetRenderingResolution(w, h) end
---@param inputMouseCoordinates UnityEngine.Vector3
---@return UnityEngine.Vector3
function m.RelativeMouseAt(inputMouseCoordinates) end
UnityEngine = {}
UnityEngine.Display = m
return m