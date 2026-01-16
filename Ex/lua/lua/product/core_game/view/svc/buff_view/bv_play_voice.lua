_class("BuffViewPlayVoice", BuffViewBase)
---@class BuffViewPlayVoice : BuffViewBase
BuffViewPlayVoice = BuffViewPlayVoice

function BuffViewPlayVoice:PlayView(TT)
    local result = self._buffResult
    local entity = self._entity

    if result.audioType == SkillAudioType.Cast then
        local playingID = AudioHelperController.PlayInnerGameSfx(result.audioID)
        ---@type EffectHolderComponent
        local effectCpmt = entity:EffectHolder()
        if not effectCpmt then
            entity:AddEffectHolder()
            effectCpmt = entity:EffectHolder()
        end
        effectCpmt:AttachAudioID(result.audioID, playingID)
    elseif result.audioType == SkillAudioType.Hit then
        Log.error("BuffViewPlayVoice: Hit类音效与伤害结果相关，PlayVoice不能处理")
    elseif result.audioType == SkillAudioType.Voice then
        AudioHelperController.PlayInnerGameVoiceByAudioId(result.audioID)
    end
end
