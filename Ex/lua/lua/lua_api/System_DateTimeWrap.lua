---@class System.DateTime
---@field Date System.DateTime
---@field Day int
---@field DayOfWeek System.DayOfWeek
---@field DayOfYear int
---@field Hour int
---@field Kind System.DateTimeKind
---@field Millisecond int
---@field Minute int
---@field Month int
---@field Now System.DateTime
---@field UtcNow System.DateTime
---@field Second int
---@field Ticks long
---@field TimeOfDay System.TimeSpan
---@field Today System.DateTime
---@field Year int
---@field MinValue System.DateTime
---@field MaxValue System.DateTime
local m = {}
---@param value System.TimeSpan
---@return System.DateTime
function m:Add(value) end
---@param value double
---@return System.DateTime
function m:AddDays(value) end
---@param value double
---@return System.DateTime
function m:AddHours(value) end
---@param value double
---@return System.DateTime
function m:AddMilliseconds(value) end
---@param value double
---@return System.DateTime
function m:AddMinutes(value) end
---@param months int
---@return System.DateTime
function m:AddMonths(months) end
---@param value double
---@return System.DateTime
function m:AddSeconds(value) end
---@param value long
---@return System.DateTime
function m:AddTicks(value) end
---@param value int
---@return System.DateTime
function m:AddYears(value) end
---@param t1 System.DateTime
---@param t2 System.DateTime
---@return int
function m.Compare(t1, t2) end
---@overload fun(value:System.DateTime):int
---@param value object
---@return int
function m:CompareTo(value) end
---@param year int
---@param month int
---@return int
function m.DaysInMonth(year, month) end
---@overload fun(value:System.DateTime):bool
---@overload fun(t1:System.DateTime, t2:System.DateTime):bool
---@param value object
---@return bool
function m:Equals(value) end
---@param dateData long
---@return System.DateTime
function m.FromBinary(dateData) end
---@param fileTime long
---@return System.DateTime
function m.FromFileTime(fileTime) end
---@param fileTime long
---@return System.DateTime
function m.FromFileTimeUtc(fileTime) end
---@param d double
---@return System.DateTime
function m.FromOADate(d) end
---@return bool
function m:IsDaylightSavingTime() end
---@param value System.DateTime
---@param kind System.DateTimeKind
---@return System.DateTime
function m.SpecifyKind(value, kind) end
---@return long
function m:ToBinary() end
---@return int
function m:GetHashCode() end
---@param year int
---@return bool
function m.IsLeapYear(year) end
---@overload fun(s:string, provider:System.IFormatProvider):System.DateTime
---@overload fun(s:string, provider:System.IFormatProvider, styles:System.Globalization.DateTimeStyles):System.DateTime
---@param s string
---@return System.DateTime
function m.Parse(s) end
---@overload fun(s:string, format:string, provider:System.IFormatProvider, style:System.Globalization.DateTimeStyles):System.DateTime
---@overload fun(s:string, formats:table, provider:System.IFormatProvider, style:System.Globalization.DateTimeStyles):System.DateTime
---@param s string
---@param format string
---@param provider System.IFormatProvider
---@return System.DateTime
function m.ParseExact(s, format, provider) end
---@overload fun(value:System.TimeSpan):System.DateTime
---@param value System.DateTime
---@return System.TimeSpan
function m:Subtract(value) end
---@return double
function m:ToOADate() end
---@return long
function m:ToFileTime() end
---@return long
function m:ToFileTimeUtc() end
---@return System.DateTime
function m:ToLocalTime() end
---@return string
function m:ToLongDateString() end
---@return string
function m:ToLongTimeString() end
---@return string
function m:ToShortDateString() end
---@return string
function m:ToShortTimeString() end
---@overload fun(format:string):string
---@overload fun(provider:System.IFormatProvider):string
---@overload fun(format:string, provider:System.IFormatProvider):string
---@return string
function m:ToString() end
---@return System.DateTime
function m:ToUniversalTime() end
---@overload fun(s:string, provider:System.IFormatProvider, styles:System.Globalization.DateTimeStyles, result:System.DateTime):bool
---@param s string
---@param result System.DateTime
---@return bool
function m.TryParse(s, result) end
---@overload fun(s:string, formats:table, provider:System.IFormatProvider, style:System.Globalization.DateTimeStyles, result:System.DateTime):bool
---@param s string
---@param format string
---@param provider System.IFormatProvider
---@param style System.Globalization.DateTimeStyles
---@param result System.DateTime
---@return bool
function m.TryParseExact(s, format, provider, style, result) end
---@param d System.DateTime
---@param t System.TimeSpan
---@return System.DateTime
function m.op_Addition(d, t) end
---@overload fun(d1:System.DateTime, d2:System.DateTime):System.TimeSpan
---@param d System.DateTime
---@param t System.TimeSpan
---@return System.DateTime
function m.op_Subtraction(d, t) end
---@param d1 System.DateTime
---@param d2 System.DateTime
---@return bool
function m.op_Equality(d1, d2) end
---@param d1 System.DateTime
---@param d2 System.DateTime
---@return bool
function m.op_Inequality(d1, d2) end
---@param t1 System.DateTime
---@param t2 System.DateTime
---@return bool
function m.op_LessThan(t1, t2) end
---@param t1 System.DateTime
---@param t2 System.DateTime
---@return bool
function m.op_LessThanOrEqual(t1, t2) end
---@param t1 System.DateTime
---@param t2 System.DateTime
---@return bool
function m.op_GreaterThan(t1, t2) end
---@param t1 System.DateTime
---@param t2 System.DateTime
---@return bool
function m.op_GreaterThanOrEqual(t1, t2) end
---@overload fun(provider:System.IFormatProvider):table
---@overload fun(format:char):table
---@overload fun(format:char, provider:System.IFormatProvider):table
---@return table
function m:GetDateTimeFormats() end
---@return System.TypeCode
function m:GetTypeCode() end
System = {}
System.DateTime = m
return m