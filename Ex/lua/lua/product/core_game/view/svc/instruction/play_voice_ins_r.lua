require("base_ins_r")
---@class PlayVoiceInstruction: BaseInstruction
_class("PlayVoiceInstruction", BaseInstruction)
PlayVoiceInstruction = PlayVoiceInstruction

function PlayVoiceInstruction:Constructor(paramList)
    self._voiceID = tonumber(paramList["voiceID"])
end

function PlayVoiceInstruction:DoInstruction(TT,casterEntity,phaseContext)
    AudioHelperController.PlayInnerGameVoiceByAudioId(self._voiceID)
end

---提取指令需要缓存的语音资源
function PlayVoiceInstruction:GetCacheVoice()
    if self._voiceID and self._voiceID > 0 then
        return {self._voiceID}
    end
end