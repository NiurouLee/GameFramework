require "play_skill_phase_base_r"
---@class PlaySkillPlayLoopAudioPhase: PlaySkillPhaseBase
_class("PlaySkillPlayLoopAudioPhase", PlaySkillPhaseBase)
PlaySkillPlayLoopAudioPhase = PlaySkillPlayLoopAudioPhase

---@param casterEntity Entity
---@param phaseParam SkillPhasePlayLoopAudioParam
---播放音效语音表现
function PlaySkillPlayLoopAudioPhase:PlayFlight(TT, casterEntity, phaseParam)
    local audioID = phaseParam:GetAudioID()
    local isPlay = phaseParam:IsPlayLoopAudio()
    if isPlay == true then 
        local playingID = AudioHelperController.PlayInnerGameSfx(audioID,true)
        self:SkillService():SetLoopAudioPlayingID(playingID)
    else
        local loopAudioPlayingID = self:SkillService():GetLoopAudioPlayingID()
        if loopAudioPlayingID ~= nil then 
            AudioHelperController.StopInnerGameSfx(loopAudioPlayingID,audioID)
        end
    end
end
