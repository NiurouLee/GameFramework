---@class UnityEngine.ScriptableObject : UnityEngine.Object
local m = {}
---@overload fun(type:System.Type):UnityEngine.ScriptableObject
---@param className string
---@return UnityEngine.ScriptableObject
function m.CreateInstance(className) end
UnityEngine = {}
UnityEngine.ScriptableObject = m
return m