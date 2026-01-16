---@class System.Version : object
---@field Major int
---@field Minor int
---@field Build int
---@field Revision int
---@field MajorRevision short
---@field MinorRevision short
local m = {}
---@return object
function m:Clone() end
---@overload fun(value:System.Version):int
---@param version object
---@return int
function m:CompareTo(version) end
---@overload fun(obj:System.Version):bool
---@param obj object
---@return bool
function m:Equals(obj) end
---@return int
function m:GetHashCode() end
---@overload fun(fieldCount:int):string
---@return string
function m:ToString() end
---@param input string
---@return System.Version
function m.Parse(input) end
---@param input string
---@param result System.Version
---@return bool
function m.TryParse(input, result) end
---@param v1 System.Version
---@param v2 System.Version
---@return bool
function m.op_Equality(v1, v2) end
---@param v1 System.Version
---@param v2 System.Version
---@return bool
function m.op_Inequality(v1, v2) end
---@param v1 System.Version
---@param v2 System.Version
---@return bool
function m.op_LessThan(v1, v2) end
---@param v1 System.Version
---@param v2 System.Version
---@return bool
function m.op_LessThanOrEqual(v1, v2) end
---@param v1 System.Version
---@param v2 System.Version
---@return bool
function m.op_GreaterThan(v1, v2) end
---@param v1 System.Version
---@param v2 System.Version
---@return bool
function m.op_GreaterThanOrEqual(v1, v2) end
System = {}
System.Version = m
return m