---@class System.Enum
local m = {}
---@overload fun(enumType:System.Type, value:string, ignoreCase:bool):object
---@param enumType System.Type
---@param value string
---@return object
function m.Parse(enumType, value) end
---@param enumType System.Type
---@return System.Type
function m.GetUnderlyingType(enumType) end
---@param enumType System.Type
---@return table
function m.GetValues(enumType) end
---@param enumType System.Type
---@param value object
---@return string
function m.GetName(enumType, value) end
---@param enumType System.Type
---@return table
function m.GetNames(enumType) end
---@overload fun(enumType:System.Type, value:sbyte):object
---@overload fun(enumType:System.Type, value:short):object
---@overload fun(enumType:System.Type, value:int):object
---@overload fun(enumType:System.Type, value:byte):object
---@overload fun(enumType:System.Type, value:ushort):object
---@overload fun(enumType:System.Type, value:uint):object
---@overload fun(enumType:System.Type, value:long):object
---@overload fun(enumType:System.Type, value:ulong):object
---@param enumType System.Type
---@param value object
---@return object
function m.ToObject(enumType, value) end
---@param enumType System.Type
---@param value object
---@return bool
function m.IsDefined(enumType, value) end
---@param enumType System.Type
---@param value object
---@param format string
---@return string
function m.Format(enumType, value, format) end
---@param obj object
---@return bool
function m:Equals(obj) end
---@return int
function m:GetHashCode() end
---@overload fun(format:string):string
---@return string
function m:ToString() end
---@param target object
---@return int
function m:CompareTo(target) end
---@param flag System.Enum
---@return bool
function m:HasFlag(flag) end
---@return System.TypeCode
function m:GetTypeCode() end
System = {}
System.Enum = m
return m