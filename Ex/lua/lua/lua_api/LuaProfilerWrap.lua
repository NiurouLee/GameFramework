---@class LuaProfiler
---@field list table
local m = {}
function m.Clear() end
---@param name string
---@return int
function m.GetID(name) end
---@param id int
function m.BeginSample(id) end
---@param name string
function m.UnityBeginSample(name) end
function m.EndSample() end
LuaProfiler = m
return m