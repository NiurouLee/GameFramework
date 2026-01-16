--[[
    风船行为，随机剧情超时
]]
---@class AirAction_RS_Cancel:AirActionBase
_class("AirAction_RS_Cancel", AirActionBase)
AirAction_RS_Cancel = AirAction_RS_Cancel

function AirAction_RS_Cancel:Constructor(pet, main, storyid)
    ---@type AircraftPet
    self._pet = pet

    ---@type AircraftMain
    self._main = main

    self._storyid = storyid

    local cfg = Cfg.cfg_aircraft_pet_stroy_refresh[self._storyid]
    if not cfg then
        Log.fatal("###[RandomStory]cfg_aircraft_pet_stroy_refresh is nil ! id --> ", self._storyid)
        return
    end

    self._timeLength = 5000

    --超时气泡id
    self._timeOutBubble = cfg.CancelHeadBubbleID

    self._startTime = 0
end

function AirAction_RS_Cancel:Start()
    self._running = true

    self:CancelRandomStory()
end

--如果规定时间内没被点击，取消随机事件
function AirAction_RS_Cancel:Update(deltaTimeMS)
    if self._running then
        if self._timeOutOn then
            self._startTime = self._startTime + deltaTimeMS

            if self._startTime >= self._timeLength then
                self._timeOutOn = false
                self:Close()
            end
        end
    end
end

function AirAction_RS_Cancel:Close()
    self._main:RemoveOneRandomEvent(self._storyid)

    self:Stop()
end

--取消随机事件
function AirAction_RS_Cancel:CancelRandomStory()
    --说话
    if self._timeOutBubble then
        --气泡
        --语音
        --动作
        --喊话
        self:CancelShow()

        self._timeOutOn = true
    else
        self:Close()
    end
end

function AirAction_RS_Cancel:CancelShow()
    local cfg = Cfg.cfg_aircraft_click_action_lib[self._timeOutBubble]
    if cfg then
        --喊话
        local sentence = cfg.Sentence
        --气泡
        local bubble = cfg.Bubble
        --动作
        local anim = cfg.Anim
        --声音
        local audio = cfg.Audio

        local skinList = cfg.SkinID
        local currSkinID = self._pet:ClothSkinID()
        local _playIdx = 0
        if skinList then
            for i = 1, #skinList do
                local skinid = skinList[i]
                if skinid == currSkinID then
                    _playIdx = i
                    break
                end
            end
        end
        local playIdx = _playIdx + 1

        local sentenceTex = nil
        --开一个喊话action
        if sentence then
            sentenceTex = sentence[playIdx]
        else
            if audio then
                local cfg_voice = AudioHelperController.GetCfgAudio(audio[playIdx])
                sentenceTex = cfg_voice.Content
            end
        end
        if sentenceTex ~= nil then
            self._sentenceAction = AirActionSentence:New(self._pet, sentenceTex, self._main)
            self._pet:StartViceAction(self._sentenceAction)
        end
        --加载气泡要不要使用faceaction
        if bubble then
            local faceAction = AirActionFace:New(self._pet, bubble[playIdx])
            self._pet:StartViceAction(faceAction)
        end
        if anim then
            local animationAction = AirAnimationAction:New(self._pet, anim[playIdx])

            self._pet:StartViceAction(animationAction)

            self._animLength = GetTimeLengthByAnim(anim[playIdx])
        end
        if audio then
            ---@type PetAudioModule
            local audioModule = GameGlobal.GetModule(PetAudioModule)
            audioModule:PlayAudio(audio[playIdx])

            self._audioLength = GetTimeLengthByAudio(audio[playIdx])
        end

        ---时长,如果配了语音获取语音时长，如果有动作获取动作时长，取最大值，如果两个都没配，用默认时长
        if self._audioLength or self._animLength then
            if self._audioLength > self._animLength then
                self._timeLength = self._audioLength
            else
                self._timeLength = self._animLength
            end
        end
    else
        Log.fatal("###cfg_aircraft_click_action_lib is nil ! id --> ", self._timeOutBubble)
    end
end

function AirAction_RS_Cancel:GetTimeLength()
    return self._timeLength
end

function AirAction_RS_Cancel:IsOver()
    return not self._running
end
function AirAction_RS_Cancel:Stop()
    self._running = false
end
