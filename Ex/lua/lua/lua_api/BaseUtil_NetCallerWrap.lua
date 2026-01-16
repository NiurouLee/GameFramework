---@class BaseUtil.NetCaller : BaseUtil.ADisposableObjectWithKey
---@field State BaseUtil.NetCaller.ConnState
---@field CallRemaining int
---@field ConnectDoneCallback System.Action
---@field ConnectFailedCallback System.Action
---@field ConnectClosedCallback System.Action
---@field ReceiveDoneCallback System.Action
---@field CallBeginCallback System.Action
---@field CallEndCallback System.Action
---@field CallTimelongCallback System.Action
---@field CallTimeoutCallback System.Action
local m = {}
---@return string
function m:GetKey() end
function m:Dispose() end
---@param reason string
function m:Reset(reason) end
function m:Init() end
---@param curTick BaseUtil.tick_t
function m:Update(curTick) end
---@param desAddr BaseUtil.NetAddrInfo
---@return bool
function m:SetLinkConn(desAddr) end
---@param desAddr BaseUtil.NetAddrInfo
---@param srcToken BaseUtil.NetToken
---@return bool
function m:SetLink2Conn(desAddr, srcToken) end
---@param desToken BaseUtil.NetToken
---@param proxyKey string
---@return bool
function m:SetPipe2Conn(desToken, proxyKey) end
---@return string
function m:GetPipeProxyKey() end
---@return string
function m:GetConnInfo() end
function m:Connect() end
---@param reason string
function m:Disconnect(reason) end
---@return bool
function m:IsConnected() end
---@return bool
function m:IsConnecting() end
---@return bool
function m:IsDisconnecting() end
---@return bool
function m:IsDisconnected() end
---@return bool
function m:HasAuth() end
function m:GainAuth() end
function m:LostAuth() end
function m:Alive() end
---@return float
function m:GetAvgDelay() end
---@return uint
function m:LastSendElapsedTick() end
---@return uint
function m:LastRecvElapsedTick() end
---@param msg BaseUtil.CPushEvent
function m:Push(msg) end
---@param type System.Type
---@param cb BaseUtil.NetCaller.PushHandlerDelegate
function m:RegisterPushHandler(type, cb) end
---@param type System.Type
function m:UnRegisterPushHandler(type) end
---@param type System.Type
---@return bool
function m:HasRegisterPushHandler(type) end
function m:ClearPushHandlers() end
---@param reqMsg BaseUtil.CCallRequestEvent
---@param sync bool
---@param timeout uint
---@return System.Collections.IEnumerator
function m:Call(reqMsg, sync, timeout) end
---@param id int
---@return bool
function m:RetryCall(id) end
---@return bool
function m:IsCallRecovering() end
function m:CallRecovering() end
function m:CallRecovered() end
---@return bool
function m:HasSyncCall() end
---@return bool
function m:IsCallTimelong() end
---@return bool
function m:IsCallTimeout() end
function m:ResetCallTimeout() end
---@param reason BaseUtil.CallResultType
function m:ResetCall(reason) end
---@param cfgInfo BaseUtil.NetworkCfgInfoDc
function m:UpdateNetworkCfgInfo(cfgInfo) end
---@return BaseUtil.NetworkReportDataDc
function m:GetReportData() end
BaseUtil = {}
BaseUtil.NetCaller = m
return m