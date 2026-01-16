---@class UnityEngine.Gradient : object
---@field colorKeys table
---@field alphaKeys table
---@field mode UnityEngine.GradientMode
local m = {}
---@param time float
---@return UnityEngine.Color
function m:Evaluate(time) end
---@param colorKeys table
---@param alphaKeys table
function m:SetKeys(colorKeys, alphaKeys) end
---@overload fun(other:UnityEngine.Gradient):bool
---@param o object
---@return bool
function m:Equals(o) end
---@return int
function m:GetHashCode() end
UnityEngine = {}
UnityEngine.Gradient = m
return m