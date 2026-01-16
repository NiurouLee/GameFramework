---@class INTL.JsonSerializable : object
---@field JsonDict table
---@field UnityJsonDict table
local m = {}
---@return string
function m:ToString() end
---@return string
function m:ToJsonString() end
---@overload fun(json:object):void
---@param json string
function m:Fill(json) end
INTL = {}
INTL.JsonSerializable = m
return m