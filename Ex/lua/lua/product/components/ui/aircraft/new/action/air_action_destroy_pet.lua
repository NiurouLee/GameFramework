--[[
    风船行为，星灵离开娱乐区后销毁
]]
---@class AirActionDestroyPet:AirActionBase
_class("AirActionDestroyPet", AirActionBase)
AirActionDestroyPet = AirActionDestroyPet

function AirActionDestroyPet:Constructor(pet, main)
    ---@type  AircraftPet
    self._pet = pet
    ---@type AircraftMain
    self._main = main
end
function AirActionDestroyPet:Start()
    self._main:RemoveRestPet(self._pet:TemplateID())
    self._running = false
end
function AirActionDestroyPet:Update(deltaTimeMS)
end
function AirActionDestroyPet:IsOver()
    return true
end
function AirActionDestroyPet:Stop()
end
