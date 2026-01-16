require("base_ins_r")
---@class PlayRemoveAudioInstruction: BaseInstruction
_class("PlayRemoveAudioInstruction", BaseInstruction)
PlayRemoveAudioInstruction = PlayRemoveAudioInstruction

function PlayRemoveAudioInstruction:Constructor(paramList)
    self._audioID = tonumber(paramList["audioID"])
end
---@param casterEntity Entity
function PlayRemoveAudioInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type EffectHolderComponent
    local effectCpmt = casterEntity:EffectHolder()
    local playingIDList= effectCpmt:GetAudioPlayingID(self._audioID)
    for i, playingID in ipairs(playingIDList) do
        AudioHelperController.StopInnerGameSfx(playingID,self._audioID)
    end
end
