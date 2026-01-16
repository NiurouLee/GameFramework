---@class INTL.INTLAPIUtils : object
local m = {}
---@param account string
---@return int
function m.GetAccountType(account) end
---@param year int
---@param month int
---@param day int
---@return string
function m.GetBirthdayString(year, month, day) end
---@param port int
---@param ruleName string
function m.AddFireWallRuleWindows(port, ruleName) end
INTL = {}
INTL.INTLAPIUtils = m
return m