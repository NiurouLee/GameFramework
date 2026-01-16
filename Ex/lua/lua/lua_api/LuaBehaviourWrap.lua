---@class LuaBehaviour : UnityEngine.MonoBehaviour
---@field luaInstance LuaInterface.LuaTable
---@field globalLuaClass string
---@field serializedValues table
---@field serializedObjValues table
local m = {}
---@param value object
---@return string
function m.ValueToJson(value) end
---@param json string
---@param type System.Type
---@return object
function m.JsonToValue(json, type) end
LuaBehaviour = m
return m