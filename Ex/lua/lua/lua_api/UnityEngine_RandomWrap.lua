---@class UnityEngine.Random : object
---@field state UnityEngine.Random.State
---@field value float
---@field insideUnitSphere UnityEngine.Vector3
---@field insideUnitCircle UnityEngine.Vector2
---@field onUnitSphere UnityEngine.Vector3
---@field rotation UnityEngine.Quaternion
---@field rotationUniform UnityEngine.Quaternion
local m = {}
---@param seed int
function m.InitState(seed) end
---@overload fun(min:int, max:int):int
---@param min float
---@param max float
---@return float
function m.Range(min, max) end
---@overload fun(hueMin:float, hueMax:float):UnityEngine.Color
---@overload fun(hueMin:float, hueMax:float, saturationMin:float, saturationMax:float):UnityEngine.Color
---@overload fun(hueMin:float, hueMax:float, saturationMin:float, saturationMax:float, valueMin:float, valueMax:float):UnityEngine.Color
---@overload fun(hueMin:float, hueMax:float, saturationMin:float, saturationMax:float, valueMin:float, valueMax:float, alphaMin:float, alphaMax:float):UnityEngine.Color
---@return UnityEngine.Color
function m.ColorHSV() end
UnityEngine = {}
UnityEngine.Random = m
return m