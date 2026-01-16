--[[
    修改传说星灵能量表现
]]
_class("BuffViewChangePetLegendPower", BuffViewBase)
BuffViewChangePetLegendPower = BuffViewChangePetLegendPower
function BuffViewChangePetLegendPower:IsNotifyMatch(notify)
    if notify.GetAttackPos and notify.GetTargetPos and self._buffResult.attackPos and self._buffResult.targetPos then
        return (self._buffResult.attackPos == notify:GetAttackPos() and
            self._buffResult.targetPos == notify:GetTargetPos())
    else
        return true
    end
end
function BuffViewChangePetLegendPower:PlayView(TT)
    local petPowerStateList = self._buffResult:GetPetPowerList()
    for _, petPowerState in pairs(petPowerStateList) do
        self:_PlayView(TT, petPowerState)
    end
end

function BuffViewChangePetLegendPower:_PlayView(TT, petPowerState)
    local entityID = petPowerState.petEntityID
    local petPstID = petPowerState.petPstID
    local curPower = petPowerState.power
    local ready = petPowerState.ready
    local requireNTPowerReady = petPowerState.requireNTPowerReady
    local maxValue = petPowerState.maxValue
    local extraSkillID = petPowerState.extraSkillID --可能没有，附加技相关buff增加
    local previouslyReady = petPowerState.previouslyReady

    --改变CD
    --MSG46384 EventDispatcher:Dispatch如果参数中包含nil，会导致nil之后的参数无法传递
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PetLegendPowerChange, petPstID, curPower, true, false, maxValue)
    --可以释放
    if ready then
        if extraSkillID and extraSkillID ~= 0 then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PetExtraActiveSkillGetReady, petPstID,extraSkillID, ready, previouslyReady)
        else
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, ready, previouslyReady)
        end
    else
        if extraSkillID and extraSkillID ~= 0 then
            GameGlobal:EventDispatcher():Dispatch(GameEventType.PetExtraActiveSkillCancelReady, petPstID,extraSkillID)
        else
            GameGlobal:EventDispatcher():Dispatch(GameEventType.PetActiveSkillCancelReady, petPstID)
        end
    end

    if requireNTPowerReady then
        local notify = NTPowerReady:New(self._world:GetEntityByID(entityID))
        self._world:GetService("PlayBuff"):PlayBuffView(TT, notify)
    end
end
