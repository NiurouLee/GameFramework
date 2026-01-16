---@class SeasonAudioPlayer:Object
_class("SeasonAudioPlayer", Object)
SeasonAudioPlayer = SeasonAudioPlayer
function SeasonAudioPlayer:Constructor(playerID, distance, audioID, position,
                                        startRadiu, endRadiu, highVolume, lowVolume, isAnimationAudio, AnimAudioID) --播放器
    self.playerID = playerID
    self.distance = distance
    self.audioID = audioID
    self.position = position
    self.startRadiu = startRadiu
    self.endRadiu = endRadiu
    self.highVolume = highVolume
    self.lowVolume = lowVolume
    self.isAnimationAudio = isAnimationAudio ~= nil and isAnimationAudio or false
    self.AnimAudioID = AnimAudioID
end

---@class SeasonAudio:Object
_class("SeasonAudio", Object)
SeasonAudio = SeasonAudio

function SeasonAudio:Constructor()
    self._cfg = Cfg.cfg_season_map_audio {}
    self._voiceCfg = Cfg.cfg_season_map_player_voice[GameGlobal.GetModule(SeasonModule):GetCurSeasonID()]
    ---@type SeasonManager
    self._seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    ---@type SeasonPlayer
    self._player = self._seasonManager:SeasonPlayerManager():GetPlayer()
    self._moveTimer = 0
    self._isPlayMoveVoice = false
    self._staticTimer = 0
    self._audioPlayers = {}
    for k, v in pairs(self._cfg) do
        local name = v[1]
        local audioGO = UnityEngine.GameObject.Find(name)
        if audioGO then
            local position = audioGO.transform.position
            local startRadius = v[2]
            local endRadius = v[3]
            local highVolume = v[4]
            local lowVolume = v[5]
            local isAnimationAudio = v[6]
            local audioID = v[7]
            local AnimAudioID = v[8]
            local audioPlayer = SeasonAudioPlayer:New(-1, 0, audioID, position, startRadius, endRadius, highVolume, lowVolume, isAnimationAudio, AnimAudioID)
            table.insert(self._audioPlayers, audioPlayer)
        end
    end
    self._cameraTransform = self._seasonManager:SeasonCameraManager():SeasonCamera():Transform()
    local soundOn = LocalDB.GetInt("SoundVolumeOnKey", 1) > 0
    local soundGlobal = Cfg.cfg_global["sound_volume"].FloatValue
    self._sound_value = soundOn and LocalDB.GetInt("SoundVolumeKey", 100) / 100 * soundGlobal or 0
    self._stepTimer = 0
    self._stopAllAudio = false
    self._curVoice = nil
    self:_RequestSound()
    AudioHelperController.SetInnerGameSoundPlaySpeed(BattleConst.TimeSpeedList[1])
end

function SeasonAudio:Dispose()
    self:_ReleaseAllSound()
    if self._event then
        GameGlobal.Timer():CancelEvent(self._event)
        self._event = nil
    end
end

function SeasonAudio:Update(deltaTime)
    if self._player:IsMoveing() then
        self:_PlayMoveVoice(deltaTime)
        self._staticTimer = 0
        self._isPlayStaticVoice = false
    else
        self:_PlayStaticVoice(deltaTime)
    end
    self:_PlayEnvSound()
end

function SeasonAudio:_PlayEnvSound()
    local cameraPos = self._cameraTransform.position
    for k, v in ipairs(self._audioPlayers) do
        if not v.isAnimationAudio then
            v.distance = self:_GetPlaneDistance(v.position, cameraPos)
            self:_PlayRadiuSound(v)
        end
    end
end

---@param player SeasonAudioPlayer
function SeasonAudio:_PlayRadiuSound(player)
    local globalVolume = self._stopAllAudio and 0 or self._sound_value
    if player.distance < player.startRadiu and player.distance > player.endRadiu then
        if player.playerID and player.playerID ~= -1 then
            local volume = Mathf.Lerp(player.lowVolume, player.highVolume, (player.startRadiu - player.distance) / (player.startRadiu - player.endRadiu))
            AudioHelperController.SetInnerVolumeRuntime(player.playerID, volume * globalVolume)
        else
            player.playerID = AudioHelperController.PlayInnerGameSfx(player.audioID, true)
        end
    elseif player.distance < player.endRadiu then
        if player.playerID and player.playerID ~= -1 then
            AudioHelperController.SetInnerVolumeRuntime(player.playerID, player.highVolume * globalVolume)
        end
    else
        if player.playerID and player.playerID ~= -1 then
            AudioHelperController.SetInnerVolumeRuntime(player.playerID, CriAudioManager.Instance.SoundVolume)
            AudioHelperController.StopInnerGameSfx(player.playerID, player.audioID)
        end
        player.playerID = -1
    end
end

function SeasonAudio:_GetPlaneDistance(position1, position2)
    position1.y = 0
    position2.y = 0
    return Vector3.Distance(position1, position2)
end

function SeasonAudio:_RequestSound()
    for k, v in ipairs(self._audioPlayers) do
        if v.isAnimationAudio then
            for key, value in pairs(v.AnimAudioID) do
                if value ~= -1 then
                    AudioHelperController.RequestInnerGameSound(value)
                end
            end
        else
            AudioHelperController.RequestInnerGameSound(v.audioID)
        end
    end
    AudioHelperController.RequestUISound(SeasonCriAudio.StepDefault)
    AudioHelperController.RequestUISound(SeasonCriAudio.StepMetal)
    AudioHelperController.RequestUISound(SeasonCriAudio.StepStone)
end

function SeasonAudio:_ReleaseAllSound()
    AudioHelperController.StopAllUIVoice()
    for k, v in ipairs(self._audioPlayers) do
        self:_ReleaseSound(v)
    end
    AudioHelperController.ReleaseUISoundById(SeasonCriAudio.StepDefault)
    AudioHelperController.ReleaseUISoundById(SeasonCriAudio.StepMetal)
    AudioHelperController.ReleaseUISoundById(SeasonCriAudio.StepStone)
end

function SeasonAudio:_ReleaseSound(player)
    if player.playerID and player.playerID ~= -1 then
        AudioHelperController.SetInnerVolumeRuntime(player.playerID, CriAudioManager.Instance.SoundVolume)
        AudioHelperController.StopInnerGameSfx(player.playerID, player.audioID)
    end
    table.clear(player)
end

function SeasonAudio:PlayStepSound(mapMaterial, deltaTime)
    if self._stopAllAudio then
        return
    end
    local clock = self._voiceCfg.stepInterval * 1000
    if self._stepTimer == 0 then
        if mapMaterial == SeasonMapMaterial.Default then
            AudioHelperController.PlayUISoundResource(SeasonCriAudio.StepDefault)
        elseif mapMaterial == SeasonMapMaterial.Metal then
            AudioHelperController.PlayUISoundResource(SeasonCriAudio.StepMetal)
        elseif mapMaterial == SeasonMapMaterial.Stone then
            AudioHelperController.PlayUISoundResource(SeasonCriAudio.StepStone)
        end
    end
    self._stepTimer = self._stepTimer + deltaTime
    if self._stepTimer > clock then
        self._stepTimer = 0
    end
end

function SeasonAudio:_PlayMoveVoice(deltaTime)
    local audio_id = self._voiceCfg.breatheAudio[1]
    self._moveTimer = self._moveTimer + deltaTime
    local firstVoiceTime = self._voiceCfg.breatheAudio[2] * 1000
    local repitVoiceTime = self._voiceCfg.breatheAudio[3] * 1000
    if (not self._isPlayMoveVoice) and self._moveTimer > firstVoiceTime then
        self._isPlayMoveVoice = true
        self:_PlayVoice(audio_id)
        self._moveTimer = 0
    end
    if self._isPlayMoveVoice and self._moveTimer > repitVoiceTime then
        self._moveTimer = 0
        self:_PlayVoice(audio_id)
    end
end

function SeasonAudio:_PlayStaticVoice(deltaTime)
    local audioID = self._voiceCfg.staticAudio[self._player:CurZone()][1]
    local staticVoiceTime = self._voiceCfg.staticAudio[self._player:CurZone()][2] * 1000
    self._staticTimer = self._staticTimer + deltaTime
    if self._staticTimer > staticVoiceTime then
        self._staticTimer = 0
        self:_PlayVoice(audioID)
    end
end

function SeasonAudio:PlaySound(audio_id)
    AudioHelperController.PlayUISoundAutoRelease(audio_id)
end

function SeasonAudio:SetLizardVolume()
    if self._daxiyiPlayer and self._daxiyiPlayer.playerID ~= -1 then
        self._daxiyiPlayer.distance = self:_GetPlaneDistance(self._daxiyiPlayer.position, self._cameraTransform.position)
        self:_PlayRadiuSound(self._daxiyiPlayer)
    end
end

function SeasonAudio:PlayLizardAudio(curName)
    if self._daxiyiPlayer and self._daxiyiPlayer.playerID ~= -1 then
        AudioHelperController.StopInnerGameSfx(self._daxiyiPlayer.playerID, self._daxiyiPlayer.audioID)
        self._daxiyiPlayer.playerID = -1
    end
    for k, v in ipairs(self._audioPlayers) do
        if v.isAnimationAudio then
            for key, value in pairs(v.AnimAudioID) do
                if curName == key then
                    self._daxiyiPlayer = v
                    self._daxiyiPlayer.audioID = value
                    break
                end
            end
        end
    end
    if self._daxiyiPlayer.audioID ~= -1 then
        self._daxiyiPlayer.playerID = AudioHelperController.PlayInnerGameSfx(self._daxiyiPlayer.audioID, false)
    else
        self._daxiyiPlayer = nil
    end
    
end

function SeasonAudio:PlayEventAudio(eventPointType)
    if eventPointType == SeasonEventPointType.MainLevel then
        AudioHelperController.PlayUISoundAutoRelease(SeasonCriAudio.Monster) --点击怪物测试音
    elseif eventPointType == SeasonEventPointType.Box then
        local box1Audio = self._voiceCfg.box1Audio[1]
        local delay = self._voiceCfg.box1Audio[2] * 1000
        AudioHelperController.PlayUISoundAutoRelease(SeasonCriAudio.Box) --点击宝箱测试音
        self._event = GameGlobal.Timer():AddEvent(delay, function()      --点击宝箱延迟播放
            if not self._stopAllAudio then
                self:_PlayVoice(box1Audio)
            end
        end)
    elseif eventPointType == SeasonEventPointType.Mechanism then
        --AudioHelperController.PlayUISoundAutoRelease(SeasonCriAudio.Door) --砸门测试音
    end
end

function SeasonAudio:_PlayVoice(audioID)
    self:_StopSeasonUIVoice()
    if not self._stopAllAudio then
        self._curVoice = AudioHelperController.PlayUIVoiceByAudioId(audioID)
    end
end

function SeasonAudio:_StopSeasonUIVoice()
    if self._curVoice then
        AudioHelperController.StopUIVoice(self._curVoice)
    end
end

function SeasonAudio:StopSeasonSounds()
    self._stopAllAudio = true
    self:_StopSeasonUIVoice()
    AudioHelperController.PauseBGM()
end

function SeasonAudio:ResumeSeasonSounds()
    self._stopAllAudio = false
    AudioHelperController.UnpauseBGM()
end

function SeasonAudio:PlayVoice(stop)
    self._stopAllAudio = stop
    if stop then
        self:_StopSeasonUIVoice()
    end
end