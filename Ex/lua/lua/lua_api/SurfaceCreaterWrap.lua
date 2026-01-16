---@class SurfaceCreater : object
local m = {}
---@param x int
---@param z int
function m:Push(x, z) end
function m:Create() end
function m:Destroy() end
SurfaceCreater = m
return m