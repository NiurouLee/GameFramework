_class("AudioService", Object)
AudioService = AudioService

function AudioService:Constructor()
end

--- 播放局内音效
function AudioService:PlayInnerGameSfx(id)
end

--- 播放UI音效
function AudioService:PlayUISfx(id)
end

--- 播放背景音效
function AudioService:PlayBgmSfx(id, fadetime)
end

function AudioService:PlayAudioSound(id)
end

function AudioService:StopAudioSound(id, autioType)
end
