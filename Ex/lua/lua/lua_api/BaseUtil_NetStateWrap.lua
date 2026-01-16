---@class BaseUtil.NetState
local m = {}
---@return BaseUtil.NetState.WayType
function m.Way() end
---@return bool
function m.UseNetwork() end
---@return bool
function m.UseCarrierData() end
---@return bool
function m.UseLocalArea() end
BaseUtil = {}
BaseUtil.NetState = m
return m