---@class AceSdk.AceClient : object
local m = {}
---@param init_info AceSdk.ClientInitInfo
---@param ace_base_path string
---@param ace_client AceSdk.AceClient
---@return AceSdk.AntiCheatExpertResult
function m.init(init_info, ace_base_path, ace_client) end
---@param acc AceSdk.AceAccountInfo
---@return AceSdk.AntiCheatExpertResult
function m:log_on(acc) end
function m:tick() end
function m:log_off() end
function m:exit_process() end
AceSdk = {}
AceSdk.AceClient = m
return m