---@class AudioManager : UnityEngine.MonoBehaviour
---@field Instance AudioManager
---@field IsStopPlayCriBgm bool
---@field InitLoginInfoEnd bool
---@field OverallVolume float
---@field OverallMute bool
---@field BgmVolume float
---@field BgmMute bool
---@field BgmResName string
---@field SoundVolume float
---@field UiSfxMute bool
---@field InnerGameSoundPlaySpeed float
---@field VoiceVolume float
---@field m_strDefaultAcfName string
---@field m_strDefaultBGMAcb string
---@field m_strDefaultBGMAwb string
---@field m_strDefaultUIAcb string
---@field bgmPlayer UnityEngine.AudioSource
---@field fadeSpeed float
---@field uiSfxPlayer UnityEngine.AudioSource
---@field SoundPlayerRoot UnityEngine.GameObject
---@field AutoCreateSoundPlayer bool
---@field VoicePlayerRoot UnityEngine.GameObject
---@field AutoCreateVoicePlayer bool
local m = {}
function m:InitCriWareHandlerComponent() end
function m:InitCriAudioManager() end
---@param defaultButtonSoundName string
---@param defaultBGMName string
function m:Initialize(defaultButtonSoundName, defaultBGMName) end
function m:ClearInnerGameAudio() end
---@param path string
---@return UnityEngine.Audio.AudioMixerGroup
function m:GetMixerGroup(path) end
---@param name string
---@param fadeTime float
function m:PlayBGM(name, fadeTime) end
---@param fadeTime float
function m:StopBGM(fadeTime) end
function m:PauseBGM() end
function m:UnpauseBGM() end
---@param mixerGroupName string
function m:SetBGMMixerGroup(mixerGroupName) end
---@param res string
function m:PlayUISoundAutoRelease(res) end
---@param res string
function m:RequestUISound(res) end
---@param res string
function m:RequestUISoundSync(res) end
---@param res string
---@param loop bool
---@return int
function m:PlayUISound(res, loop) end
---@param playingID int
function m:StopUISound(playingID) end
---@param res string
function m:ReleaseUISound(res) end
---@param soundRes string
function m:RequestInnerGameSound(soundRes) end
---@param soundName string
---@param isLoop bool
---@param scaler float
---@param mixPath string
---@return int
function m:PlayInnerGameSfx(soundName, isLoop, scaler, mixPath) end
---@param soundName string
---@param category EAudioCategory
---@param priority int
---@param isLoop bool
---@param scaler float
---@param mixPath string
---@return int
function m:PlayInnerGamePrioritySfx(soundName, category, priority, isLoop, scaler, mixPath) end
---@param playingId int
---@return bool
function m:StopInnerGameSfx(playingId) end
function m:StopAllInnerGameSfx() end
---@param sfx int
function m:StopRestInnerGameSfx(sfx) end
function m:PauseAllInnerGameSfx() end
function m:UnpauseAllSfx() end
---@param idx int
---@return bool
function m:IsInnerSfxPlaying(idx) end
---@param res string
---@return int
function m:RequestAndPlayUIVoiceAutoRelease(res) end
---@param playingID int
---@return float
function m:GetPlayingVoiceSecLength(playingID) end
---@param res string
---@return float
function m:GetVoiceSecLength(res) end
---@param res string
function m:RequestUIVoice(res) end
---@param playingID int
---@return bool
function m:CheckUIVoicePlaying(playingID) end
---@param res string
---@param autoRelease bool
---@return int
function m:PlayUIVoice(res, autoRelease) end
---@param playingID int
---@param fadeOutTime float
function m:StopUIVoice(playingID, fadeOutTime) end
---@param res string
function m:ReleaseUIVoice(res) end
function m:StopAllUIVoice() end
---@param voiceRes string
function m:RequestInnerGameVoice(voiceRes) end
---@param voiceName string
---@param isLoop bool
---@param scaler float
---@param mixPath string
---@return int
function m:PlayInnerGameVoice(voiceName, isLoop, scaler, mixPath) end
---@param voiceName string
---@param category EAudioCategory
---@param priority int
---@param isLoop bool
---@param scaler float
---@param mixPath string
---@return int
function m:PlayInnerGamePriorityVoice(voiceName, category, priority, isLoop, scaler, mixPath) end
---@param playingId int
---@return bool
function m:StopInnerGameVoice(playingId) end
function m:StopAllInnerGameVoice() end
---@param sfx int
function m:StopRestInnerGameVoice(sfx) end
function m:PauseAllInnerGameVoice() end
function m:UnpauseAllVoice() end
---@param idx int
---@return bool
function m:IsInnerVoicePlaying(idx) end
AudioManager = m
return m