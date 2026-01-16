---@class AceSdk.TssAntibot : object
local m = {}
---@return table
function m:GetReportData() end
---@param data table
function m:OnRecvAntiData(data) end
function m:Release() end
AceSdk = {}
AceSdk.TssAntibot = m
return m