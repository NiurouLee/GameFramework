---@class H3DToggle : UnityEngine.MonoBehaviour
local m = {}
---@overload fun(selected:bool):void
---@param onValueChanged LuaInterface.LuaFunction
function m:OnValueChanged(onValueChanged) end
H3DToggle = m
return m