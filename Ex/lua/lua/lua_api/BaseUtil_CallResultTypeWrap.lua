---@class BaseUtil.CallResultType : System.Enum
---@field value__ int
---@field Normal BaseUtil.CallResultType
---@field ConnectFailed BaseUtil.CallResultType
---@field ConnectClosed BaseUtil.CallResultType
---@field CallTimeout BaseUtil.CallResultType
---@field CallReset BaseUtil.CallResultType
---@field CallWithoutTask BaseUtil.CallResultType
---@field InvalidMessage BaseUtil.CallResultType
---@field CreateMessageFailed BaseUtil.CallResultType
---@field EncodeMessageFailed BaseUtil.CallResultType
---@field DecodeMessageFailed BaseUtil.CallResultType
---@field OtherErr BaseUtil.CallResultType
local m = {}
BaseUtil = {}
BaseUtil.CallResultType = m
return m