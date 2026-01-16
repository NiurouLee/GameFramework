---@class CriUIVideoPlayer : UnityEngine.MonoBehaviour
local m = {}
---@param strResName string
---@param bLoop bool
---@param bPlayEndAutoStop bool
---@param pSubtitleCB CriUIVideoPlayer.SubtitleChangeCBDelegate
---@param pPlayOrStopCB CriUIVideoPlayer.PlayEndOrStopCBDelegate
---@return bool
function m:PlayUSMEBySofdec2(strResName, bLoop, bPlayEndAutoStop, pSubtitleCB, pPlayOrStopCB) end
function m:Stop() end
---@param sw bool
---@return bool
function m:Pause(sw) end
---@param bPlayEndAutoStop bool
function m:SetPlayEndAutoStop(bPlayEndAutoStop) end
---@param nStatus int
---@return bool
function m:CheckVideoStatus(nStatus) end
---@param nStatus int
---@return bool
function m:CheckPlayerStatus(nStatus) end
---@return int
function m:GetVideoStatus() end
---@return int
function m:GetPlayerStatus() end
---@param volume float
function m:SetVolume(volume) end
---@param volume float
function m:SetExtraAudioVolume(volume) end
---@return bool
function m:CanStop() end
---@return bool
function m:CanPlay() end
---@return long
function m:GetVideoTotalMS() end
---@return long
function m:GetCurPlayMS() end
---@param fSpeed float
function m:SetSpeed(fSpeed) end
---@param lTemp long
function m:SetPlayTo(lTemp) end
---@param track int
function m:SetSubAudioTrack(track) end
---@param track int
function m:SetExtraAudioTrack(track) end
CriUIVideoPlayer = m
return m