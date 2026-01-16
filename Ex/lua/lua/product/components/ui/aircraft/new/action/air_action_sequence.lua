--[[
    风船行为 交互动画序列 cfg_aircraft_action_sequence
]]
---@class AirActionSequence:AirActionBase
_class("AirActionSequence", AirActionBase)
AirActionSequence = AirActionSequence
local SeqPhase = {
    Begin = 1, -- 开始
    Loop = 2, -- 循环
    Finish = 3, -- 结束
    None = 4 -- None
}
-- function AirActionSequence:Constructor(pet, furniture, point, seqMaker, index)
function AirActionSequence:Constructor(
    pet,
    pos,
    rot,
    endPos,
    seqMaker,
    index,
    curLoopCount,
    startCallBack,
    loopCallBack,
    stopCallBack)
    if pet == nil then
        return
    end
    self._pos = pos
    self._rot = rot
    self._endPos = endPos
    self._startCallBack = startCallBack
    self._loopCallBack = loopCallBack
    self._stopCallBack = stopCallBack
    ---@type AircraftPet
    self._pet = pet
    -- self._animator = self._pet:Animator()
    ---@type AirActionSeqMaker
    self._seqMaker = seqMaker
    self._index = index
    self._onceLoopCount = self._seqMaker:GetOnceLoopCount()
    self._maxLoopCount = self._seqMaker:GetLoopCount()
    self._state = SeqPhase.None
    self._curLoopCount = curLoopCount or 1
end
function AirActionSequence:Start()
    self._pet:SetPosition(self._pos)
    self._pet:SetRotation(self._rot)
    self._curTime = 0
    self._running = true
    --TODO: 播动作
    if self._startCallBack then
        self._startCallBack()
    end
    -- self._pet:SetFurnitureID(self._furniture._type)
    self._pet:SetNaviEnable(false)
    -- 开始序列动作
    self._beginSeq = self._seqMaker:GetBeginSeq()
    if self._seqMaker:HasBegin() then
        self._pet:Anim_CrossFade(self._beginSeq[1])
        -- self._animator:SetTrigger(self._beginSeq[1])
        -- self._animator:SetBool(self._pet._standIdle, false)
        -- self._animator:SetBool(self._pet.animName.walk, false)
        self._state = SeqPhase.Begin -- 开始序列
    elseif self._seqMaker:HasLoop() then
        self._state = SeqPhase.Loop -- 循环
    elseif self._seqMaker:HasFinish() then
        self._state = SeqPhase.Finish -- 结束序列
    end
end

function AirActionSequence:Update(deltaTimeMS)
    if not self._running then
        return
    end
    if self._state == SeqPhase.Begin then
        self._curTime = self._curTime + deltaTimeMS
        if self._curTime > self._beginSeq[2] then
            if self._seqMaker:HasLoop() then
                self._state = SeqPhase.Loop
            elseif self._seqMaker:HasFinish() then
                self._state = SeqPhase.Finish
            end
            self._curTime = 0
        end
    elseif self._state == SeqPhase.Loop then
        if self._curLoopCount <= self._maxLoopCount then
            if self._curTime == 0 then
                local round = self._curLoopCount % self._onceLoopCount
                if round == 0 then
                    round = self._onceLoopCount
                end
                self._loopSeq = self._seqMaker:GetLoopSeq(round, self._index)
                -- self._animator:SetTrigger(self._loopSeq[1])
                self._pet:Anim_CrossFade(self._loopSeq[1])
            end
            self._curTime = self._curTime + deltaTimeMS
            if self._curTime > self._loopSeq[2] then
                self._curTime = 0
                self._curLoopCount = self._curLoopCount + 1
                if self._loopCallBack then
                    self._loopCallBack(self._curLoopCount, self._index)
                end
            end
        else
            self._curTime = 0
            self._state = SeqPhase.Finish
        end
    elseif self._state == SeqPhase.Finish then
        if self._curTime == 0 then
            self._finishSeq = self._seqMaker:GetFinishSeq(self._index)
            if self._finishSeq and self._finishSeq[1] then
                self._pet:Anim_CrossFade(self._finishSeq[1])
            end
        -- self._animator:SetTrigger(self._finishSeq[1])
        end
        self._curTime = self._curTime + deltaTimeMS
        if self._curTime > self._finishSeq[2] then
            self._state = SeqPhase.None
            self._curTime = 0
            self._running = false
            self:Stop()
        end
    end
end
function AirActionSequence:IsOver()
    return not self._running
end
function AirActionSequence:Stop()
    if self._running then
        self._running = false
    end
    self._pet:SetPosition(self._endPos)
    self._pet:Anim_Stand()
    if self._stopCallBack then
        self._stopCallBack()
    end
    self:LogStop()
end
function AirActionSequence:GetPets()
    return {self._pet}
end
