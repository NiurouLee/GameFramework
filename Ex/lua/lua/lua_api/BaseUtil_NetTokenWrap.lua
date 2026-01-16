---@class BaseUtil.NetToken : object
---@field Type BaseUtil.NetTokenType
---@field type short
---@field serial short
---@field token_id long
local m = {}
function m:ResetSelf() end
---@param type BaseUtil.NetTokenType
---@param serial short
---@param token_id long
---@return BaseUtil.NetToken
function m:CtorFromArg(type, serial, token_id) end
---@param type BaseUtil.NetTokenType
---@param svc string
---@param id int
---@return BaseUtil.NetToken
function m:CtorFromSvr(type, svc, id) end
---@param token BaseUtil.NetToken
---@return BaseUtil.NetToken
function m:CtorFromToken(token) end
---@param type int
---@param serial short
---@param token_id long
---@return BaseUtil.NetToken
function m.NewBySerial(type, serial, token_id) end
---@param token_string string
---@return long
function m.GenTokenID(token_string) end
---@param outs BaseUtil.NetOutStream
function m:ToStream(outs) end
---@param ins BaseUtil.NetInStream
function m:FromStream(ins) end
---@param type BaseUtil.NetTokenType
---@return bool
function m:IsType(type) end
---@return string
function m:TokenDesc() end
---@param svc string
---@param id int
---@return string
function m.MakeTokenDesc(svc, id) end
---@return int
function m:GetHashCode() end
---@param obj object
---@return bool
function m:Equals(obj) end
---@return string
function m:ToString() end
BaseUtil = {}
BaseUtil.NetToken = m
return m