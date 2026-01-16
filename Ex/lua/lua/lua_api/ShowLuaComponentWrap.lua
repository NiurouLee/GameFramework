---@class ShowLuaComponent : UnityEngine.MonoBehaviour
---@field componentName string
---@field memberValue table
local m = {}
---@param name string
function m:SetComponentName(name) end
---@param luaVal LuaInterface.LuaTable
function m:RefreshComponent(luaVal) end
ShowLuaComponent = m
return m