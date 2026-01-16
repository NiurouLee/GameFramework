--[[
    走向1层宿舍，离开风船
]]
---@class AirActionMoveToLeave:AirActionBase
_class("AirActionMoveToLeave", AirActionBase)
AirActionMoveToLeave = AirActionMoveToLeave

function AirActionMoveToLeave:Constructor(pet, main)
    ---@type AircraftMain
    self._main = main
    ---@type AircraftPet
    self._pet = pet
    self._exitFloor = 1 --出口在1层
    self._pos = self._main:ExitPosition()
    self._pet:SetAsLeavingPet()
    self._pet:SetState(AirPetState.Leaving)
end
function AirActionMoveToLeave:Start()
    ---@type AirActionMoveToDo
    self._moveToAction =
        AirActionMoveToDo:New(self._pet, self._exitFloor, self._pos, AircraftPetMoveType.ToLeave, self._main)
    self._moveToAction:Start()
    self._running = true
end
function AirActionMoveToLeave:IsOver()
    return not self._running
end
function AirActionMoveToLeave:Update(deltaTimeMS)
    if self._running then
        self._moveToAction:Update(deltaTimeMS)
        if self._moveToAction:IsOver() then
            self._running = false
            self:Stop()
        end
    end
end
function AirActionMoveToLeave:Duration()
    return nil
end
function AirActionMoveToLeave:CurrentTime()
    return nil
end
function AirActionMoveToLeave:Stop()
    if self._running then
        -- Log.exception("星灵离开中，不能停止行为：", self._pet:TemplateID(), debug.traceback())
    else
        self._main:RemoveRestPet(self._pet:TemplateID())
    end
end
function AirActionMoveToLeave:Dispose()
    if self._running then
        AirLog("离开中的星灵行为析构：", self._pet:TemplateID())
    end
end
function AirActionMoveToLeave:Pets()
    return {self._pet}
end
