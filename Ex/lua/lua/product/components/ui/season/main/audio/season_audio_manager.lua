---@class SeasonAudioManager:Object
_class("SeasonAudioManager", Object)
SeasonAudioManager = SeasonAudioManager

function SeasonAudioManager:Constructor()
end

function SeasonAudioManager:OnInit()
    ---@type SeasonAudio
    self._seasonAudio = SeasonAudio:New()
end

function SeasonAudioManager:Update(deltaTime)
    self._seasonAudio:Update(deltaTime)
end

function SeasonAudioManager:Dispose()
    self._seasonAudio:Dispose()
    self._seasonAudio = nil
end

---@return SeasonAudio
function SeasonAudioManager:GetSeasonAudio()
    return self._seasonAudio
end
