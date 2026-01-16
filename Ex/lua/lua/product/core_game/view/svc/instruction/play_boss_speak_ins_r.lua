require("base_ins_r")
---@class PlayBossSpeakInstruction: BaseInstruction
_class("PlayBossSpeakInstruction", BaseInstruction)
PlayBossSpeakInstruction = PlayBossSpeakInstruction

function PlayBossSpeakInstruction:Constructor(paramList)
    self._bossCardImage = paramList["bossCardImage"]
    self._bossName = paramList["bossName"]
    self._prob = tonumber(paramList["prob"])
    self._speakList = {}
    self._audioList = {}

    local paramStr = paramList["speakList"]
    local splitStrArray = string.split(paramStr, "|")
    for _, v in ipairs(splitStrArray) do
        self._speakList[#self._speakList + 1] = v
    end

    paramStr = paramList["audioList"]
    splitStrArray = string.split(paramStr, "|")
    for _, v in ipairs(splitStrArray) do
        self._audioList[#self._audioList + 1] = tonumber(v)
    end

    if #self._speakList ~= #self._audioList then
        Log.error("PlayBossSpeak speak and audio size error!")
    end

    self._duration = tonumber(paramList["duration"])

    self._inAnimName = paramList["inAnimName"]
    self._loopAnimName = paramList["loopAnimName"]
    self._outAnimName = paramList["outAnimName"]
end

function PlayBossSpeakInstruction:GetCacheAudio()
    local t = {}
    for _, v in ipairs(self._audioList) do
        if v and v > 0 then
            t[#t + 1] = v
        end
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayBossSpeakInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local rand = Mathf.Random(1, 100)
    if rand <= self._prob then
        local index = Mathf.Random(1, #self._speakList)
        local curSpeak = self._speakList[index]

        ---显示头像及对话内容
        world:EventDispatcher():Dispatch(GameEventType.UIShowBossSpeak, { self._inAnimName, self._loopAnimName },
            self._bossCardImage, self._bossName, curSpeak, self._duration, self._outAnimName)

        ---播放音效
        local curAudioID = self._audioList[index]
        if curAudioID and curAudioID > 0 then
            AudioHelperController.PlayInnerGameVoiceByAudioId(curAudioID)
        end
    end
end
