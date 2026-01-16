---@class INTL.INTLBaseResult : INTL.JsonSerializable
---@field MethodId int
---@field RetCode int
---@field RetMsg string
---@field ThirdCode int
---@field ThirdMsg string
---@field ExtraJson string
local m = {}
INTL = {}
INTL.INTLBaseResult = m
return m