---@class CriAudioManager : CriWare.CriMonoBehaviour
---@field Instance CriAudioManager
---@field OverallVolume float
---@field OverallMute bool
---@field BgmVolume float
---@field BgmMute bool
---@field SoundVolume float
---@field UiSfxMute bool
---@field InnerGameSoundPlaySpeed float
---@field VoiceVolume float
---@field C_ENCRYPT_KEY string
---@field AutoCreateSoundPlayer bool
---@field AutoCreateCriVoicePlayer bool
local m = {}
---@param strDefaultAcf string
---@param strDefaultCommonAcb string
---@param strDefaultBtnCue string
---@param strDefaultBGMAcb string
---@param DefaultBGMCue string
---@param nBGMAudioID int
function m:Initialize(strDefaultAcf, strDefaultCommonAcb, strDefaultBtnCue, strDefaultBGMAcb, DefaultBGMCue, nBGMAudioID) end
function m:ClearInnerGameAudio() end
---@return int
function m:GetBGMAudioId() end
---@param nBGMId int
---@param strAcb string
---@param strCue string
---@param fadeTime float
function m:PlayCriBGM(nBGMId, strAcb, strCue, fadeTime) end
---@param fadeTime float
function m:StopCriBGM(fadeTime) end
---@param controlName string
---@param value float
function m:SetBGMAisacControl(controlName, value) end
---@return bool
function m:BGMPlayerIsPlaying() end
function m:PauseBGM() end
function m:UnpauseBGM() end
---@return long
function m:GetPlayingBGMTimeSyncedWithAudio() end
---@return long
function m:GetPlayingBGMTotalTimeMs() end
function m:StopAllInnerGameSound() end
---@param strAcbName string
---@return int
function m:RequestUICueSheetSync(strAcbName) end
---@param strAcbName string
function m:RequestUICueSheetAsync(strAcbName) end
---@param strAcbName string
function m:SetAutoReleaseUICueSheet(strAcbName) end
---@param strAcb string
---@param strCue string
function m:PlayUIAcbCueDontRelease(strAcb, strCue) end
---@param strAcb string
---@param strCue string
function m:PlayUIAcbCueAutoRelease(strAcb, strCue) end
---@param strCueCheet string
---@param strCueName string
---@param isLoop bool
---@param scaler float
---@return int
function m:PlayUICue(strCueCheet, strCueName, isLoop, scaler) end
---@param playingId int
---@return bool
function m:StopUICue(playingId) end
---@param acbNameList table
---@param nOneUpdateLoadNum int
function m:RequestInnerGameSoundSync(acbNameList, nOneUpdateLoadNum) end
---@param strAcb string
function m:RequestInnerGameSoundASync(strAcb) end
function m:PauseAllInnerGameSfx() end
function m:UnpauseAllSfx() end
---@param strCueCheet string
---@param strCueName string
---@param isLoop bool
---@param scaler float
---@return int
function m:PlayInnerCue(strCueCheet, strCueName, isLoop, scaler) end
---@param playingId int
---@return bool
function m:StopInnerGameSfx(playingId) end
---@param nPlayingId int
---@return bool
function m:StopUICriPlayer(nPlayingId) end
---@param nPlayingId int
---@param strCueName string
---@return bool
function m:StopInnerSfxCue(nPlayingId, strCueName) end
---@param strAcb string
---@param bAutoRelease bool
function m:RequestCriUIVoice(strAcb, bAutoRelease) end
---@param strAcb string
---@param bForceRelease bool
function m:ReleaseUICriVoice(strAcb, bForceRelease) end
---@param strAcb string
---@return int
function m:PlayRandomUIVoiceCue(strAcb) end
---@param strAcb string
---@param strCue string
---@param bAutoRelease bool
---@return int
function m:PlayUIVoiceCue(strAcb, strCue, bAutoRelease) end
---@param playingID int
---@return float
function m:GetPlayingVoiceSecLength(playingID) end
---@param strAcb string
---@param strCue string
---@return float
function m:GetVoiceSecLength(strAcb, strCue) end
---@param strAcb string
---@param strCue string
---@return float
function m:GetVoiceSecLengthSyncReq(strAcb, strCue) end
---@param playingID int
---@return bool
function m:CheckCriUIVoicePlaying(playingID) end
---@param playingID int
---@param fadeOutTime float
function m:StopCriVoice(playingID, fadeOutTime) end
---@param strAcb string
function m:RequestCriInnerGameVoice(strAcb) end
---@param strCueCheet string
---@param strCueName string
---@param isLoop bool
---@param scaler float
---@return int
function m:PlayCueInnerCriVoice(strCueCheet, strCueName, isLoop, scaler) end
function m:StopAllCriVoice() end
CriAudioManager = m
return m