--[[
    星灵行为，移动到工作房间
]]
---@class AirActionMoveToWorkOld:AirActionBase
_class("AirActionMoveToWorkOld", AirActionBase)
AirActionMoveToWorkOld = AirActionMoveToWorkOld

function AirActionMoveToWorkOld:Constructor(pet, room, main)
    ---@type AircraftPet
    self._pet = pet
    ---@type AircraftRoom
    self._room = room
    ---@type AircraftMain
    self._main = main
end

function AirActionMoveToWorkOld:Start()
    self._running = true
    self._point = self._room:GetPointHolder():PopPoint()
    self._moveAction = AirActionMove:New(self._pet, self._point:Pos(), self._room:Floor(), self._main, "移动-到工作房间")
    self._moveAction:Start()
    self._pet:SetState(AirPetState.MoveToWork)
    self:LogStart()
end

function AirActionMoveToWorkOld:Update(deltaTimeMS)
    if self._running then
        if self._moveAction:IsOver() then
            self._running = false
            self:Stop()
        else
            self._moveAction:Update(deltaTimeMS)
        end
    end
end

function AirActionMoveToWorkOld:IsOver()
    return not self._running
end

function AirActionMoveToWorkOld:Stop()
    if self._running then
        --外部打断的时候，只停止移动
        self._running = false
        self._moveAction:Stop()
    else
        self._main:StartWorkingAction(self._pet)
    end
    self._room:GetPointHolder():ReleasePoint(self._point)

    --取消不可销毁状态
    -- self._pet:CancelDontDestroy()
    -- --走到工作室内，判定一次是否依然在工作，因为在走的过程中可能取消入住
    -- local spaceID = self._pet:GetSpace()
    -- local petID = self._pet:TemplateID()
    -- local roomData = GameGlobal.GetModule(AircraftModule):GetRoom(spaceID)
    -- ---@type table<number,Pet>
    -- local roomPets = roomData:GetPets()
    -- local exist = false
    -- for _, value in pairs(roomPets) do
    --     if value:GetTemplateID() == petID then
    --         exist = true
    --     end
    -- end
    -- if not exist then
    --     self._main:PetStopWork(petID, spaceID)
    -- end
end

function AirActionMoveToWorkOld:GetPets()
    return {self._pet}
end
