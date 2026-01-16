---@class LoginLuaHelper : object
local m = {}
function m.CloseAllUI() end
function m.StartUI() end
---@param v bool
function m.ResetCanStartGame(v) end
function m.CancelChannel() end
---@param values string
---@param keys string
---@return table
function m.GetDataByJson(values, keys) end
---@param values string
---@return table
function m.GetChannelByJson(values) end
---@param values string
---@return string
function m.GetJsonString(values) end
---@return string
function m.GetOpenId() end
---@return int
function m.GetChannelId() end
---@return string
function m.GetToken() end
---@return bulletin_zone_info
function m.GetZoneInfo() end
---@return LoginUIState
function m.GetUIState() end
---@return bool
function m.IsAdult() end
---@return bool
function m.IsEEA() end
---@return string
function m.GetRegChannelDis() end
---@return StateRegionInfo
function m.GetStateRegionInfo() end
---@return StateRegionInfo
function m.GetLBSStateRegionInfo() end
---@return string
function m.GetRegAccount() end
LoginLuaHelper = m
return m