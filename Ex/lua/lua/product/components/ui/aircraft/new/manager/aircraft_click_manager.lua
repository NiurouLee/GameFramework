---@class AircraftClickManager:Object
_class("AircraftClickManager", Object)
AircraftClickManager = AircraftClickManager

function AircraftClickManager:Constructor(aircraftMain)
    ---@type AircraftMain
    self._main = aircraftMain

    ---@type AircraftModule
    self._airModule = GameGlobal.GetModule(AircraftModule)

    ---@type PetAudioModule
    self._audioModule = GameGlobal.GetModule(PetAudioModule)

    ---@type SvrTimeModule
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)

    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)

    --当前交互的星灵
    ---@type AircraftPet
    self._currentInteractionPet = nil
    self._petIsNilState = "Constructor"

    self._firstEnter = {}

    --送礼中
    self._isGiftSending = false
    self._currentPetInteractionState = true

    self._lastInteractionPets = {}

    self._canPlaySendGiftAudioGapsTime = 1500
    self._canPlaySendGiftAudioStartTime = 0
    self._cantClickPets = {}

    self._canPlaySengGiftAudio = true

    self._interactiving = false

    self._currentAnimPet = nil

    --交互星灵次数
    self._clickCount = 0
end

--送礼触发剧情
function AircraftClickManager:SendGiftRandomStory(storyid)
    self._main:StartOneRandomEvent(storyid, true)
end

function AircraftClickManager:Init()
    --送礼特效
    self._loveEffName = Cfg.cfg_aircraft_const["LoveEffName"].StrValue or "ui_click_01.prefab"
    self._lvUpEffName = Cfg.cfg_aircraft_const["LvUpEffName"].StrValue or "ui_click_01.prefab"
    --交互等待时间
    self._startTime = 0
    self._timeOutTime = Cfg.cfg_global["AirActionInteractionWaitTime"].IntValue or 10 * 1000

    --点击特效
    --self._clickEffName = Cfg.cfg_aircraft_const["clickEffName"].StrValue
    self._clickLoopEffName = Cfg.cfg_aircraft_const["clickLoopEffName"].StrValue

    self:_LoadClickEff()

    --同一个人点击间隔
    self._onePetClickGaps = Cfg.cfg_aircraft_const["onePetClickGaps"].IntValue

    self._lastInteractionPets = {}

    --点击特效名字
    self._effLastTime = Cfg.cfg_aircraft_const["effLastName"].IntValue

    self._effStartTime = 0

    self._requesting = false
    self._cameraMoving = false
end

--加载特效
function AircraftClickManager:_LoadClickEff()
    if self._clickEffName then
        self._clickEffEeq = ResourceManager:GetInstance():SyncLoadAsset(self._clickEffName, LoadType.GameObject)
        self._clickEffGo = self._clickEffEeq.Obj
        self._clickEffGo:SetActive(false)
    end
    if self._clickLoopEffName then
        self._clickLoopEffReq = ResourceManager:GetInstance():SyncLoadAsset(self._clickLoopEffName, LoadType.GameObject)
        self._clickLoopEff = self._clickLoopEffReq.Obj
        self._clickLoopEffTr = self._clickLoopEff.transform
        self._clickLoopEff:SetActive(false)
        self._loopEff = false
    end
end
--开点击特效
function AircraftClickManager:_PlayClickEff(pos)
    if not pos then
        return
    end

    if self._clickEffGo then
        self._clickEffGo.transform.position = pos
        self._clickEffGo:SetActive(true)
    end
end
--关点击特效
function AircraftClickManager:_StopClickEff()
    if self._clickEffGo then
        self._clickEffGo:SetActive(false)
    end
end

--强制清空交互星灵和待处理星灵群
function AircraftClickManager:ForceRemoveInteractivePets(pstidList)
    for i = 1, #pstidList do
        local pstid = pstidList[i]
        if self._currentInteractionPet then
            if self._currentInteractionPet:PstID() == pstid then
                self:StopInteraction(true)
            end
        end
        for key, value in pairs(self._lastInteractionPets) do
            local pet = value
            if pet:PstID() == pstid then
                self._lastInteractionPets[key] = nil
                break
            end
        end
    end
end

--交互结束
function AircraftClickManager:StopInteraction(force)
    if not self._currentInteractionPet then
        return
    end

    if not self._currentInteractionPet:IsAlive() then
        self:StopClickLoopEff()
        
        --已被销毁
        self._currentInteractionPet = nil
        self._petIsNilState = "Pet:IsAlive"
        return
    end

    if force then
    else
        self._lastInteractionPet = self._currentInteractionPet
        if self._currentPetInteractionState then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnPetClick, nil)
            Log.debug("###交互结束，插入一个", self._lastInteractionPet:TemplateID())
            table.insert(self._lastInteractionPets, self._lastInteractionPet)
        end
    end

    self:StopClickLoopEff()

    --材质动画
    self._currentInteractionPet:StopMatAnim()

    self._currentInteractionPet:StopSentenceAction()

    self._currentInteractionPet = nil
    self._petIsNilState = "StopInteraction"

    self._interactiving = false

    self._startTime = 0

    self._clickCount = 0

    self._currAnim = false

    if self._faceAction and not self._faceAction:IsOver() then
        self._faceAction:Stop()
        self._faceAction = nil
    end

    if self._currentPlayingAudioID then
        local isPlaying = AudioHelperController.CheckUIVoicePlaying(self._currentPlayingAudioID)
        if isPlaying then
            AudioHelperController.StopUIVoice(self._currentPlayingAudioID)
        end
        self._currentPlayingAudioID = nil
    end

    --[[

        local isWorking = self._currentInteractionPet:IsWorkingPet()
        
        if isWorking then
            self._main:StartWorkingAction(self._currentInteractionPet)
        else
            self._main:RandomActionForPet(self._currentInteractionPet)
        end
        ]]
end

--点击常住动画
function AircraftClickManager:StopClickLoopEff()
    self._loopEff = false
    self._clickLoopEff:SetActive(false)
end
--点击常住动画
function AircraftClickManager:PlayClickLoopEff()
    self._loopEff = true
    self._clickLoopEff:SetActive(true)
end

--开始送礼
function AircraftClickManager:ChangeGiftSending(state)
    AirLog("聚焦星灵送礼，state：", state, "，petID:", self._currentInteractionPet:TemplateID())
    self._isGiftSending = state
    local offset = nil
    local callback = nil
    if state then
        offset = Vector3(1.5, 0, 0)
        self:Lock("ChangeGiftSending")

        callback = function()
            self:UnLock("ChangeGiftSending")
        end
    else
        self:Lock("ChangeGiftSending")
        callback = function()
            self:UnLock("ChangeGiftSending")
        end
    end
    self._main:FocusPet(self._currentInteractionPet, offset, callback, 250)
end

--送礼成功
function AircraftClickManager:AircraftOnSendGiftSuccess(lvUp, love)
    --送礼爱心特效
    local effectName
    if lvUp then
        effectName = self._loveEffName
    else
        effectName = self._lvUpEffName
    end
    local delayTime = 1000

    ---@type AirActionSendGift
    local sendGiftAction = AirActionSendGift:New(self._currentInteractionPet, effectName, delayTime)
    self._currentInteractionPet:StartViceAction(sendGiftAction)

    self:SendGiftAndAudio(love)
end

--送礼喊话
function AircraftClickManager:SendGiftAndAudio(love)
    --保底1.5秒
    if not self._canPlaySengGiftAudio then
        return
    end
    self._canPlaySengGiftAudio = false
    --保底声音没播完
    if self._sendGiftAudioID then
        Log.debug("###self._sendGiftAudioID -- ", self._sendGiftAudioID)
        local isPlaying = AudioHelperController.CheckUIVoicePlaying(self._sendGiftAudioID)
        if isPlaying then
            return
        end
        self._sendGiftAudioID = nil
    end
    local petid = self._currentInteractionPet:TemplateID()
    --可以播放
    local voiceConfig = Cfg.cfg_pet_voice{PetID=petid}
    if not voiceConfig then
        return
    end
    local content_cfg = nil
    --播放
    ---@type PetAudioModule
    local pm = GameGlobal.GetModule(PetAudioModule)

    --先关掉点击交互的语音
    if self._currentPlayingAudioID then
        AudioHelperController.StopUIVoice(self._currentPlayingAudioID,0)
    end

    if love then
        self._sentenceAudioID, self._sendGiftAudioID = pm:PlayPetAudio("ReceiveLoveGift", petid, true)
        if self._sentenceAudioID then
            content_cfg = AudioHelperController.GetCfgAudio(self._sentenceAudioID).Content
        end
    else
        self._sentenceAudioID, self._sendGiftAudioID = pm:PlayPetAudio("ReceiveGift", petid, true)
        if self._sentenceAudioID then
            content_cfg = AudioHelperController.GetCfgAudio(self._sentenceAudioID).Content
        end
    end

    if content_cfg then
        ---@type AirActionSentence
        local sendGiftSentenceAction =
            AirActionSentence:New(self._currentInteractionPet, content_cfg, self._main, self._sendGiftAudioID)
        self._currentInteractionPet:StartSentenceAction(sendGiftSentenceAction)
    end
end

function AircraftClickManager:Update(deltaTimeMS)
    --送礼中星灵也可能在播动画，缩放放在最开始检查
    --检查星灵是否正在播放点击动画
    if self._currAnim and self._currentAnimPet then
        --判断隐藏了星灵
        if self._currentAnimPet:Animation() then
            if self._currentAnimPet:Animation():IsPlaying(AirPetAnimName.Click) then
                local stateInfo = self._currentAnimPet:Animation():get_Item(AirPetAnimName.Click)
                if stateInfo.normalizedTime >= 0.95 then
                    self._currentAnimPet:Anim_Stand()
                    self._currAnim = false
                    self._currentAnimPet = nil
                end
            end
        else
            self._currAnim = false
            self._currentAnimPet = nil
        end
    end

    if self._currentInteractionPet then
        --检查是否在送礼中
        if self._isGiftSending then
            --送礼语音
            if not self._canPlaySengGiftAudio then
                self._canPlaySendGiftAudioStartTime = self._canPlaySendGiftAudioStartTime + deltaTimeMS
                if self._canPlaySendGiftAudioStartTime >= self._canPlaySendGiftAudioGapsTime then
                    self._canPlaySengGiftAudio = true
                    self._canPlaySendGiftAudioStartTime = 0
                end
            end
            return
        end
        if self._interactiving then
            -- if self._currentInteractionPet then
            --交互超时
            if self._startTime >= self._timeOutTime then
                Log.debug("###[audio]>= self._timeOutTime --> ", self._timeOutTime)
                self:StopInteraction()
            else
                self._startTime = self._startTime + deltaTimeMS
            end
        end
    end
    --点击特效
    if self._effIsPlaying then
        self._effStartTime = self._effStartTime + deltaTimeMS
        if self._effStartTime >= self._effLastTime then
            self._effIsPlaying = false
            self._effStartTime = 0
            self:_StopClickEff()
        end
    end
    --结束交互星灵待处理群
    if table.count(self._lastInteractionPets) > 0 then
        for key, value in pairs(self._lastInteractionPets) do
            ---@type AircraftPet
            local pet = value
            local state = pet:GetState()
            if pet:Animation() and pet:Animation():IsPlaying(AirPetAnimName.Click) then
                local stateInfo = pet:Animation():get_Item(AirPetAnimName.Click)
                if stateInfo.normalizedTime >= 0.95 then
                    local isWorking = pet:IsWorkingPet()

                    if isWorking then
                        if state ~= AirPetState.RandomEvent and state ~= AirPetState.RandomEventWith then
                            self._main:StartWorkingAction(pet)
                        end
                    else
                        if state ~= AirPetState.RandomEvent and state ~= AirPetState.RandomEventWith then
                            self._main:RandomActionForPet(pet)
                        end
                    end

                    self._lastInteractionPets[key] = nil
                    -- table.remove(self._lastInteractionPets, value)

                    Log.debug("###交互动作结束，走一个", pet:TemplateID())
                end
            else
                local isWorking = pet:IsWorkingPet()

                if isWorking then
                    if state ~= AirPetState.RandomEvent and state ~= AirPetState.RandomEventWith then
                        self._main:StartWorkingAction(pet)
                    end
                else
                    if state ~= AirPetState.RandomEvent and state ~= AirPetState.RandomEventWith then
                        self._main:RandomActionForPet(pet)
                    end
                end

                self._lastInteractionPets[key] = nil

                Log.debug("###交互动作结束，走一个", pet:TemplateID())
            end
        end
    end
    --点击过的星灵多长时间不可点击，计时
    if self._cantClickPets and table.count(self._cantClickPets) > 0 then
        for key, value in pairs(self._cantClickPets) do
            self._cantClickPets[key] = self._cantClickPets[key] + deltaTimeMS
            if self._cantClickPets[key] >= self._onePetClickGaps then
                self._cantClickPets[key] = nil
                Log.debug("###移除id-->", key)
            end
        end
    end

    --点击常住动画
    if self._loopEff then
        if not self._currentInteractionPet then
            if self._reportError then
                return
            end
            local state = self._petIsNilState or "nil"
            self._reportError = true
            HelperProxy:GetInstance():ReportException("###[Air_Report_Error_AircraftClickManager] petState --> "..state)
        else
            self._clickLoopEffTr.position = self._currentInteractionPet:WorldPosition()
        end
    end
end

function AircraftClickManager:Dispose()
    self._startTime = 0
    self._timeOutTime = 0
    self._currentInteractionPet = nil
    self._petIsNilState = "Dispose"

    self._currentAnimPet = nil
    self._main = nil

    if self._clickEffEeq then
        self._clickEffEeq:Dispose()
        self._clickEffGo = nil
        self._clickEffEeq = nil
    end
    if self._clickLoopEffReq then
        self._clickLoopEffReq:Dispose()
        self._clickLoopEff = nil
        self._clickLoopEffTr = nil
        self._clickLoopEffReq = nil
    end

    if self._animEvent then
        GameGlobal.Timer():CancelEvent(self._animEvent)
        self._animEvent = nil
    end

    self._lastInteractionPet = nil
    table.clear(self._lastInteractionPets)
    self._lastInteractionPets = nil
end

--点击星灵
---@param pet AircraftPet
function AircraftClickManager:OnClickPet(pet, petpoint)
    AirLog("点击到了一个星灵:", pet:TemplateID())

    --点击特效
    if self._effIsPlaying then
        self:_StopClickEff()
    end
    self._effStartTime = 0
    self._effIsPlaying = true
    self:_PlayClickEff(petpoint)

    --描边动画动画
    pet:PlaySelectAnim()
    --状态判断
    local state = pet:GetState()
    if state == AirPetState.RandomEvent then
        AirLog("点击随机剧情星灵")
        self:ClickAndLookStory(pet)
    elseif state == AirPetState.RandomEventWith then
        AirLog("点击伴随随机剧情的星灵")
        local pet = pet
        local storyPetID = self._main:GetStoryPetByNeedPet(pet)
        local storyPet = self._main:GetPetByTmpID(storyPetID)
        self:ClickAndLookStory(storyPet)
    else
        if state == AirPetState.InElevator or state == AirPetState.Upstairs then
            return
        elseif state == AirPetState.WaitingElevator then
            AirLog("点击等电梯星灵")
            self:OnInterAction(pet, false)
        elseif pet:IsGiftPet() then
            AirLog("点击送礼星灵")
            self:StopInteraction()
            self._main:TryStopBlockHandler(pet)
            self:ClickDelieverPresent(pet)
        elseif pet:IsVisitPet() and pet:HasVisitGift() then
            AirLog("点击拜访星灵，且有礼物")
            self:StopInteraction()
            self._main:TryStopBlockHandler(pet)
            self:AttemptAcceptVisitingPresent(pet)
        elseif pet:IsLeavingPet() then
            AirLog("点击到正在离开的星灵")
            self:OnInterAction(pet, false)
        elseif state == AirPetState.MoveToWork then
            AirLog("点击到正在走向工作室的星灵")
            self:OnInterAction(pet, false)
        else
            AirLog("点击星灵，开始交互")
            --点击交互
            self:OnInterAction(pet, true)
        end
    end
end

--点开剧情
function AircraftClickManager:ClickAndLookStory(pet)
    self:Lock("ReadyPlayStory")

    self:CloseSendGiftBtn()
    self:StopInteraction()

    self:RotateOnePet(pet)

    --剧情
    --随机事件
    self._main:FocusPet(
        pet,
        nil,
        function()
            local storyid = self._main:GetStoryIDByPetID(pet:TemplateID())
            if storyid then
                self._main:TriggerRandomStory(storyid)
            end
        end
    )
end

function AircraftClickManager:ClickDelieverPresent(pet)
    self._main:FocusPet(pet, nil)
    self._main:AcceptPresent(pet)
end

function AircraftClickManager:AttemptAcceptVisitingPresent(pet)
    self._main:FocusPet(pet, nil)
    self._main:AcceptVisitingPresent(pet)
end

--修改交互超时时长
function AircraftClickManager:ChangeInteractiveTimeOut(timeOut)
    self._timeOutTime = timeOut
end

--点击到一个可点击的星灵
---@param pet AircraftPet
function AircraftClickManager:OnInterAction(pet, turn)
    --[[

        --点击的星灵是否是可停下交互状态
        self._currentPetInteractionState = turn
        ]]
    --重置时长
    self._timeOutTime = Cfg.cfg_global["AirActionInteractionWaitTime"].IntValue or 10 * 1000
    if self._currentInteractionPet then
        if self._currentInteractionPet == pet then
            --点击的星灵是否是可停下交互状态
            self._currentPetInteractionState = turn
            --[[
                ]]
            --三秒不能点qa
            if self._cantClickPets then
                if self._cantClickPets[self._currentInteractionPet:PstID()] then
                    Log.debug("###不能点id-->", self._currentInteractionPet:PstID())
                    return
                end
            end

            self:Lock("StartInteractive")
            self._main:FocusPet(
                self._currentInteractionPet,
                nil,
                function()
                    self:UnLock("StartInteractive")
                end
            )

            Log.debug("###重置id-->", self._currentInteractionPet:TemplateID())

            -- local tplID = self._currentInteractionPet:TemplateID()
            -- local pm = GameGlobal.GetModule(PetAudioModule)
            -- self._sentenceAudioID = pm:PlayPetAudio("AircraftInteract", tplID)
            -- Log.fatal("###[audio] --> 开启一个语音 id-->", self._sentenceAudioID)

            --MSG35122	【TAPD_81819756】【必现】（测试_朱文科）诺维亚风船内触发剧情后走动时疯狂点击光灵，会出现模型背对玩家，并且脚不动的进行位移，播放交互特效
            --触发完剧情走向工作房间的星灵在到达之前点击，跨越了切主行为的时间点之后，继续点击会导致进行交互而不切换主行为
            if
                self._currentInteractionPet:IsWorkingPet() and turn and
                    self._currentInteractionPet:GetMainActionName() ~= AirActionEmpty._className
             then
                local actionEmpty = AirActionEmpty:New(self._currentInteractionPet)
                self._currentInteractionPet:StartMainAction(actionEmpty)
                self._currentInteractionPet:SetState(AirPetState.Selected)
                self:RotateOnePet(self._currentInteractionPet)
            end

            self:TriggerInterAction(false)

            if self._cantClickPets then
                self._cantClickPets[self._currentInteractionPet:PstID()] = 0
            end
        else
            self:StopInteraction()

            --点击的星灵是否是可停下交互状态
            self._currentPetInteractionState = turn
            --[[
                ]]
            self._currentInteractionPet = pet

            Log.debug("###换一个星灵交互")
            -- local tplID = self._currentInteractionPet:TemplateID()
            -- local pm = GameGlobal.GetModule(PetAudioModule)
            -- self._sentenceAudioID = pm:PlayPetAudio("AircraftClick", tplID)
            -- Log.fatal("###[audio] --> 开启一个语音 id-->", self._sentenceAudioID)

            self:StartInteractive()
            self:TriggerInterAction(true)
        end
    else
        --点击的星灵是否是可停下交互状态
        self._currentPetInteractionState = turn
        --[[
            ]]
        self._currentInteractionPet = pet
        Log.debug("###开启一个交互")
        -- local tplID = self._currentInteractionPet:TemplateID()
        -- local pm = GameGlobal.GetModule(PetAudioModule)
        -- self._sentenceAudioID = pm:PlayPetAudio("AircraftClick", tplID)

        -- Log.fatal("###[audio] --> 开启一个语音 id-->", self._sentenceAudioID)

        self:StartInteractive()
        self:TriggerInterAction(true)
    end
end
--关闭送礼按钮
function AircraftClickManager:CloseSendGiftBtn()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CloseSendGiftBtn)
end

--检查是否点击触发了剧情
function AircraftClickManager:OnCheckPetRandomEvent(TT,storyid)
    local res = self._airModule:CheckTriggerCilckStoryEvent(TT, self._currentInteractionPet:PstID())
    if res then
        --开启第二个请求
        GameGlobal.TaskManager():StartTask(function(TT)
            Log.debug("###[AirAction_RS_Look]click story test --> trigger req")
            ---@type PetModule
            local petModule = GameGlobal.GetModule(PetModule)
            local res,replay = petModule:RequestPetFinishTriggeredStory(TT, self._currentInteractionPet:PstID(), EStoryTriggerType.TouchPet, storyid)
            local reward = nil
            local affinity = nil
            if res:GetSucc() then
                self._canTrigger = true

                self._saveStoryID = storyid
                self._saveRewards = replay.reward
                self._saveAffinity = replay.affinity
            else
                self._canTrigger = false
            end
            self._requesting = false
            self:MoveCameraAndReqStory()
        end,self)
    else
        self._canTrigger = false
        self._requesting = false
        self:MoveCameraAndReqStory()
    end
end

--转向摄像机
---@param pet AircraftPet
function AircraftClickManager:RotateOnePet(pet)
    pet:SetNaviEnable(false)
    pet:SetAsObstacle()

    local _x, _z = self._main:GetMainCameraXZ()
    local _y = pet:WorldPosition().y
    local lookAtPoint = Vector3(_x, _y, _z)
    ---@type AirActionRotate
    local rotateAction = AirActionRotate:New(pet, lookAtPoint)
    pet:StartViceAction(rotateAction)
end

--开启一个交互
function AircraftClickManager:StartInteractive()
    for key, value in pairs(self._lastInteractionPets) do
        if value == self._currentInteractionPet then
            Log.debug("###开始重复交互，移除关闭列表", self._currentInteractionPet:TemplateID())
            -- table.remove(self._lastInteractionPets, self._currentInteractionPet)
            self._lastInteractionPets[key] = nil

            if self._currentInteractionPet:Animation():IsPlaying(AirPetAnimName.Click) then
                self._currAnim = true
                self._currentAnimPet = self._currentInteractionPet
            end
        end
    end

    -- 点击交互 停止社交
    if self._currentInteractionPet then
        self._main:StopSocialByPet(self._currentInteractionPet)
        --停止拥堵处理
        self._main:TryStopBlockHandler(self._currentInteractionPet)
    end

    if self._currentPetInteractionState and self._currentInteractionPet then
        --站立
        ---@type UnityEngine.Animation
        local animation = self._currentInteractionPet:Animation()
        local stand = true
        if animation and animation:IsPlaying(AirPetAnimName.Click) then
            stand = false
        end
        if stand then
            self._currentInteractionPet:Anim_Stand()
        end
        --开一个空行为
        local actionEmpty = AirActionEmpty:New(self._currentInteractionPet)
        self._currentInteractionPet:StartMainAction(actionEmpty)
        --设置状态
        self._currentInteractionPet:SetState(AirPetState.Selected)
        self:RotateOnePet(self._currentInteractionPet)
    end

    --第一次点击检查是否触发随机剧情
    local triggerEvent =
        Cfg.cfg_aircraft_pet_stroy_refresh {
        TriggerType = EStoryTriggerType.TouchPet,
        PetID = self._currentInteractionPet:TemplateID()
    }
    local isTrigger = false
    if triggerEvent and table.count(triggerEvent) > 0 then
        isTrigger = true
    end
    Log.debug("###click story test --> click")
    --别人的星灵
    local beVisitingPet = self._currentInteractionPet:IsVisitPet()
    if isTrigger and self._currentPetInteractionState and not beVisitingPet then
        self:Lock("CheckPetRandomEvent")

        self._requesting = true
        self._cameraMoving = true
        self._canTrigger = false

        Log.debug("###click story test --> trigger")
        local storyid = triggerEvent[1].ID
        GameGlobal.TaskManager():StartTask(self.OnCheckPetRandomEvent, self,storyid)

        self._main:FocusPet(
            self._currentInteractionPet,
            nil,
            function()
                self._cameraMoving = false
                self:MoveCameraAndReqStory()
            end
        )
    else
        self:Lock("StartInteractive")

        if self._currentPetInteractionState and not beVisitingPet then
            --如果没有剧情，post请求服务器做任务条件判断
            self._airModule:ClickNotHaveStoryPet(self._currentInteractionPet:PstID())
        end
        self._main:FocusPet(
            self._currentInteractionPet,
            nil,
            function()
                self:UnLock("StartInteractive")

                self:StartInteractiveGoOn()
            end
        )
    end
    self._lastInterActionID = 0
end

function AircraftClickManager:StartInteractiveGoOn()
    --交互中
    self._interactiving = true

    --检测是不是可送礼的状态
    if self._currentPetInteractionState then
        self:PlayClickLoopEff()
        --如果是别人的星灵,不送礼
        if self._currentInteractionPet:IsVisitPet() then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnPetClick)
        else
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnPetClick, self._currentInteractionPet:PstID())
        end
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnPetClick)
    end
end

--点击交互剧情相机移动结束，剧情检查结束
function AircraftClickManager:MoveCameraAndReqStory()
    if self._cameraMoving or self._requesting then
        return
    end
    self:UnLock("CheckPetRandomEvent")
    Log.debug("###click story test --> move req")

    --点击交互触发随机剧情
    if self._canTrigger then
        self._canTrigger = false
        Log.debug("###click story test --> can trigger")

        local l_pst_story_table = self._airModule:GetStoryEventDicByTriggerType(EStoryTriggerType.TouchPet)

        local _storyid = nil
        if self._saveStoryID then
            _storyid = self._saveStoryID
        else
            if l_pst_story_table and table.count(l_pst_story_table) > 0 then
                local l_story_list_st = l_pst_story_table[self._currentInteractionPet:PstID()]
                if l_story_list_st ~= nil then
                    local l_story_list = l_story_list_st.story_event_id_list
                    if l_story_list and table.count(l_story_list) > 0 then
                        _storyid = l_story_list[1]
                    end
                end
            end
        end
        if _storyid then
            self:Lock("ReadyPlayStory")

            --开启剧情就把交互人物置空，防止stop交互调到
            self._currentInteractionPet = nil
            self._petIsNilState = "MoveCameraAndReqStory"

            self._main:StartOneRandomEvent(_storyid, true)
            Log.debug("###[AircraftClickManager] click story test --> trigger one story")

            local rewards = self._saveRewards
            local affinity = self._saveAffinity
            self._main:TriggerRandomStory(_storyid,rewards,affinity)
            self._saveStoryID = nil
            self._saveRewards = nil
            self._saveAffinity = nil
        else
            Log.debug("###[AircraftClickManager] OnCheckPetRandomEvent --> l_pet_story_struct[1] is nil !")
        end
    else
        self:StartInteractiveGoOn()
    end
end

function AircraftClickManager:Lock(lockName)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, lockName)
end
function AircraftClickManager:UnLock(lockName)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, lockName)
end

--触发交互
function AircraftClickManager:TriggerInterAction(first)
    self._startTime = 0
    --通过星灵获取交互行为库
    local cfg_aircraft_pet = Cfg.cfg_aircraft_pet[self._currentInteractionPet:TemplateID()]
    if cfg_aircraft_pet then
        local interactiveGroup = cfg_aircraft_pet.ClickActionLib

        local nextid = 0

        if self._currentPetInteractionState then
            if first and self._currentInteractionPet:IsVisitPet() and not self._currentInteractionPet:HasVisitGift() then
                --拜访星灵送完礼之后，交互的首次点击弹弹特殊气泡，其他时刻走正常点击逻辑
                local cfgs = Cfg.cfg_aircraft_click_action_lib {Group = interactiveGroup, GiftTag = 2}
                if cfgs == nil or #cfgs == 0 then
                    Log.exception("找不到拜访星灵首次点击气泡：", interactiveGroup)
                end
                local cfg = cfgs[1]
                if not cfg.Sentence then
                    Log.exception("拜访星灵首次点击行为配置错误，没有Sentence：", cfg.ID)
                end
                nextid = cfg.ID
            else
                --这里优先检查首次进风船，点击人的语音，qa17551
                nextid = self:FirstEnterBaseClickAudio(self._currentInteractionPet:TemplateID(), interactiveGroup)

                if nextid == 0 then
                    nextid = self:GetInterActionID(interactiveGroup, first)
                end
            end
        else
            nextid = self:GetInterActionIDOtherState(interactiveGroup)
        end

        self._lastInterActionID = nextid

        local cfg = Cfg.cfg_aircraft_click_action_lib[nextid]
        if cfg then
            --喊话
            local sentenceList = cfg.Sentence
            --气泡
            local bubbleList = cfg.Bubble
            --动作
            local animList = cfg.Anim
            --声音
            local audioList = cfg.Audio
            --皮肤
            local skinList = cfg.SkinID

            local currSkinID = self._currentInteractionPet:ClothSkinID()
            local _playIdx = 0
            local isSkinCfg = false
            if skinList then
                for i = 1, #skinList do
                    local skinid = skinList[i]
                    if skinid == currSkinID then
                        _playIdx = i
                        isSkinCfg = true
                        break
                    end
                end
            end
            local playIdx = _playIdx + 1

            --开一个喊话action
            local sentenceTex = nil
            self._sentenceAudioID = nil
            if sentenceList and table.count(sentenceList)>0 then
                sentenceTex = sentenceList[playIdx]
            else
                if audioList then
                    local audio = nil
                    if table.count(audioList) > 0 then
                        audio = audioList[playIdx]
                    end
                    local cfg_voice = AudioHelperController.GetCfgAudio(audio)
                    if cfg_voice then
                        sentenceTex = cfg_voice.Content
                    else
                        Log.error(
                            "AircraftClickManager:TriggerInterAction not find cfg_voice:",
                            cfg_voice,
                            " cfg_aircraft_click_action_lib ID:",
                            nextid
                        )
                    end
                end
            end

            --加载气泡要不要使用faceaction
            if bubbleList then
                local bubble
                if table.count(bubbleList)>0 then
                    bubble = bubbleList[playIdx]
                end
                if self._faceAction and not self._faceAction:IsOver() then
                    self._faceAction:Stop()
                    self._faceAction = nil
                end
                self._faceAction = AirActionFace:New(self._currentInteractionPet, bubble)
                self._currentInteractionPet:StartViceAction(self._faceAction)
            end
            if animList then
                local specailClick = false
                local anim = AirPetAnimName.Click
                if isSkinCfg then
                    anim = animList[playIdx]
                end
                if not self._currAnim then
                    if isSkinCfg then
                        if not self._currentInteractionPet:Animation():IsPlaying(anim) then
                            self._currentInteractionPet:Anim_Click(anim)
                            self._currentAnimPet = self._currentInteractionPet
                        end
                    else
                        if not self._currentInteractionPet:Animation():IsPlaying(AirPetAnimName.Click) then
                            self._currentInteractionPet:Anim_Click()
                            self._currentAnimPet = self._currentInteractionPet
                        end
                    end
                    
                    self._currAnim = true
                end
            end
            if audioList then
                local audio
                if table.count(audioList) > 0 then
                    audio = audioList[playIdx]
                end
                if self._currentPlayingAudioID then
                    local isPlaying = AudioHelperController.CheckUIVoicePlaying(self._currentPlayingAudioID)
                    if isPlaying then
                        AudioHelperController.StopUIVoice(self._currentPlayingAudioID)
                    end
                end
                self._currentPlayingAudioID = AudioHelperController.RequestAndPlayUIVoiceAutoRelease(audio)
                if self._currentPlayingAudioID then
                    self._sentenceAudioID = self._currentPlayingAudioID
                end
            end
            if sentenceTex ~= nil then
                ---@type AirActionSentence
                local sentenceAction =
                    AirActionSentence:New(
                    self._currentInteractionPet,
                    sentenceTex,
                    self._main,
                    self._sentenceAudioID,
                    self._timeOutTime
                )
                self._currentInteractionPet:StartSentenceAction(sentenceAction)
            end
        else
            Log.error("###cfg_aircraft_click_action_lib is nil ! id -> ", nextid)
        end
    end
    self._clickCount = self._clickCount + 1
end

--其他状态的星灵走固定行为
function AircraftClickManager:GetInterActionIDOtherState(groupid)
    local cfgs = Cfg.cfg_aircraft_click_action_lib {Group = groupid, OtherState = 1, GiftTag = 0}
    if cfgs and #cfgs > 0 then
        return cfgs[1].ID
    else
        Log.error("###星灵的其他行为点击表现没配,星灵-->", self._currentInteractionPet:TemplateID())
    end
end

--首次进风船点击语音（日期条件，某月某天第一次点击交互）
function AircraftClickManager:FirstEnterBaseClickAudio(petid, group)
    if self._firstEnter[petid] then
        return 0
    end
    if not self._firstEnter[petid] then
        self._firstEnter[petid] = true
    end
    local cfgs = Cfg.cfg_aircraft_click_action_lib {Group = group, GiftTag = 0}
    if cfgs then
        for i = 1, #cfgs do
            if cfgs[i].Date then
                if self:CheckDate(cfgs[i].Date) then
                    return cfgs[i].ID
                end
            end
        end
    end
    return 0
end
--判断日期符合
function AircraftClickManager:CheckDate(date)
    local svrTime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    local s_month = tonumber(os.date("%m", svrTime))
    local s_day = tonumber(os.date("%d", svrTime))
    for i = 1, #date do
        local dateTemp = date[i]
        local month = dateTemp[1]
        local day = dateTemp[2]
        if s_month == month and day == s_day then
            return true
        end
    end
    return false
end

--通过星灵行为库随机出一个行为
---@param ids number[]
---@return number
function AircraftClickManager:GetInterActionID(groupid, first)
    local cfgs = Cfg.cfg_aircraft_click_action_lib {Group = groupid, FirstClick = 1, GiftTag = 0}
    if cfgs == nil then
        cfgs = {}
    end
    Log.debug("###", self._currentInteractionPet:TemplateID(), "点击获取配置.cfg_count-->", table.count(cfgs))

    --第一次点击取FirstClick
    if first and cfgs and table.count(cfgs) > 0 then
        Log.debug("###[ClickManager] 首次点击 ! groupid --> ", groupid)
    else
        if self._lastInterActionID ~= 0 then
            local cfg_aircraft_click_action_lib = Cfg.cfg_aircraft_click_action_lib[self._lastInterActionID]
            if cfg_aircraft_click_action_lib then
                local nextid = cfg_aircraft_click_action_lib.Next
                if nextid then
                    --如果又连续喊话
                    return nextid
                end
            end
        end
        --没有连续喊话，重新随机
        local temp_cfgs = Cfg.cfg_aircraft_click_action_lib {Group = groupid, GiftTag = 0}
        if not temp_cfgs then
            Log.fatal("###temp_cfgs is nil !groupid-->", groupid)
            return
        end
        if table.count(temp_cfgs) <= 0 then
            Log.fatal("###table.count(temp_cfgs) <= 0 !groupid-->", groupid)
            return
        end
        table.clear(cfgs)
        for i = 1, #temp_cfgs do
            local item = temp_cfgs[i]
            if item.FirstClick then
            else
                table.insert(cfgs, item)
            end
        end
    end

    --点击次数
    for key, value in pairs(cfgs) do
        if value.ClickTime and value.ClickTime <= self._clickCount then
            local nextid = key
            Log.debug("###[ClickManager] 获取了点击次数 self._clickCount --> ", self._clickCount)
            return nextid
        end
    end

    local petAff = self._currentInteractionPet:Affinity()

    local nowTime = os.time()
    local hour = self:Time2Hour(nowTime)
    local currWeather = 1
    local currGrade = self._currentInteractionPet:AwakeLevel()

    --第一次筛选，亲密度，时间，天气
    local firstCfg = {}
    for key, value in pairs(cfgs) do
        local insert = true

        local affinity = value.Affinity
        if affinity then
            if affinity > petAff then
                Log.debug("###[ClickManager] 亲密度不符 petAff --> ", petAff)
                insert = false
            end
        end

        local realTime = value.Time
        if realTime then
            --咵天
            if realTime[1] > realTime[2] then
                if hour < realTime[1] and hour >= realTime[2] then
                    insert = false
                    Log.debug("###[ClickManager] 时间不符 --> ", realTime[1], "|", realTime[2])
                end
            else
                if hour < realTime[1] or hour >= realTime[2] then
                    Log.debug("###[ClickManager] 时间不符 --> ", realTime[1], "|", realTime[2])
                    insert = false
                end
            end
        end

        if value.OtherState then
            Log.debug("###[ClickManager] value.OtherState !")
            insert = false
        end

        local grade = value.Grade
        if grade then
            if grade > currGrade then
                Log.debug("###[ClickManager] 觉醒不符 currGrade --> ", currGrade)
                insert = false
            end
        end

        local wherther = value.Wheather
        if wherther then
            if currWeather ~= wherther then
                Log.debug("###[ClickManager] 天气不符 currWeather --> ", currWeather)
                insert = false
            end
        end

        local date = value.Date
        if date then
            Log.debug("###[ClickManager] value.Date ! ")
            insert = false
        end

        local isNext = false
        for _id, v in pairs(cfgs) do
            if v.Next and v.Next == value.ID then
                isNext = true
                break
            end
        end
        if isNext then
            insert = false
            Log.debug("###[ClickManager] 是连续喊话不符 ！")
        end

        if insert then
            table.insert(firstCfg, value)
        end
    end

    Log.debug("###[ClickManager] 喊话备选 --> firstCfg Count --> ", table.count(firstCfg))

    --第二次筛选,不重复播
    local secondCfg = {}
    if #firstCfg > 1 then
        for i = 1, #firstCfg do
            local item = firstCfg[i]
            if item.ID ~= self._lastInterActionID then
                table.insert(secondCfg, item)
            end
        end
    else
        secondCfg = firstCfg
    end

    --随机
    return self:RandomInterActionID(secondCfg)
end

--Time2Hour
function AircraftClickManager:Time2Hour(time)
    local hour = tonumber(os.date("%H", time))
    return hour
end

--随机
function AircraftClickManager:RandomInterActionID(cfg)
    local id = 0
    local all = 0
    local weightTab = {}
    for i = 1, #cfg do
        all = all + cfg[i].Weight
        local weightTabItem = {}
        weightTabItem.id = cfg[i].ID
        weightTabItem.weight = all
        table.insert(weightTab, weightTabItem)
    end
    if all < 1 then
        all = 1
    end
    local randomNumber = math.random(1, all)
    for i = 1, #weightTab do
        if randomNumber <= weightTab[i].weight then
            id = weightTab[i].id
            break
        end
    end
    return id
end
