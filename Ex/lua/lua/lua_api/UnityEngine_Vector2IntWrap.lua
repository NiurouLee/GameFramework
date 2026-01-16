---@class UnityEngine.Vector2Int
---@field x int
---@field y int
---@field Item int
---@field magnitude float
---@field sqrMagnitude int
---@field zero UnityEngine.Vector2Int
---@field one UnityEngine.Vector2Int
---@field up UnityEngine.Vector2Int
---@field down UnityEngine.Vector2Int
---@field left UnityEngine.Vector2Int
---@field right UnityEngine.Vector2Int
local m = {}
---@param x int
---@param y int
function m:Set(x, y) end
---@param a UnityEngine.Vector2Int
---@param b UnityEngine.Vector2Int
---@return float
function m.Distance(a, b) end
---@param lhs UnityEngine.Vector2Int
---@param rhs UnityEngine.Vector2Int
---@return UnityEngine.Vector2Int
function m.Min(lhs, rhs) end
---@param lhs UnityEngine.Vector2Int
---@param rhs UnityEngine.Vector2Int
---@return UnityEngine.Vector2Int
function m.Max(lhs, rhs) end
---@overload fun(scale:UnityEngine.Vector2Int):void
---@param a UnityEngine.Vector2Int
---@param b UnityEngine.Vector2Int
---@return UnityEngine.Vector2Int
function m.Scale(a, b) end
---@param min UnityEngine.Vector2Int
---@param max UnityEngine.Vector2Int
function m:Clamp(min, max) end
---@param v UnityEngine.Vector2Int
---@return UnityEngine.Vector2
function m.op_Implicit(v) end
---@param v UnityEngine.Vector2Int
---@return UnityEngine.Vector3Int
function m.op_Explicit(v) end
---@param v UnityEngine.Vector2
---@return UnityEngine.Vector2Int
function m.FloorToInt(v) end
---@param v UnityEngine.Vector2
---@return UnityEngine.Vector2Int
function m.CeilToInt(v) end
---@param v UnityEngine.Vector2
---@return UnityEngine.Vector2Int
function m.RoundToInt(v) end
---@param a UnityEngine.Vector2Int
---@param b UnityEngine.Vector2Int
---@return UnityEngine.Vector2Int
function m.op_Addition(a, b) end
---@param a UnityEngine.Vector2Int
---@param b UnityEngine.Vector2Int
---@return UnityEngine.Vector2Int
function m.op_Subtraction(a, b) end
---@overload fun(a:UnityEngine.Vector2Int, b:int):UnityEngine.Vector2Int
---@param a UnityEngine.Vector2Int
---@param b UnityEngine.Vector2Int
---@return UnityEngine.Vector2Int
function m.op_Multiply(a, b) end
---@param lhs UnityEngine.Vector2Int
---@param rhs UnityEngine.Vector2Int
---@return bool
function m.op_Equality(lhs, rhs) end
---@param lhs UnityEngine.Vector2Int
---@param rhs UnityEngine.Vector2Int
---@return bool
function m.op_Inequality(lhs, rhs) end
---@overload fun(other:UnityEngine.Vector2Int):bool
---@param other object
---@return bool
function m:Equals(other) end
---@return int
function m:GetHashCode() end
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.Vector2Int = m
return m