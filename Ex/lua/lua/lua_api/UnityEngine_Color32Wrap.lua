---@class UnityEngine.Color32
---@field r byte
---@field g byte
---@field b byte
---@field a byte
local m = {}
---@overload fun(c:UnityEngine.Color32):UnityEngine.Color
---@param c UnityEngine.Color
---@return UnityEngine.Color32
function m.op_Implicit(c) end
---@param a UnityEngine.Color32
---@param b UnityEngine.Color32
---@param t float
---@return UnityEngine.Color32
function m.Lerp(a, b, t) end
---@param a UnityEngine.Color32
---@param b UnityEngine.Color32
---@param t float
---@return UnityEngine.Color32
function m.LerpUnclamped(a, b, t) end
---@overload fun(format:string):string
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.Color32 = m
return m