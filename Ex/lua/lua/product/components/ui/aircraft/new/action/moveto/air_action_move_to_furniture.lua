--[[
    走到家具上开始交互
]]
---@class AirActionMoveToFurniture:AirActionBase
_class("AirActionMoveToFurniture", AirActionBase)
AirActionMoveToFurniture = AirActionMoveToFurniture

function AirActionMoveToFurniture:Constructor(main, pet, furniture, point, cond, duration)
    ---@type AircraftMain
    self._main = main
    ---@type AircraftPet
    self._pet = pet
    self._pet:SetState(AirPetState.Transiting)
    ---@type AircraftFurniture
    self._furniture = furniture
    ---@type AircraftFurniturePoint
    self._furPoint = point
    ---@type AircraftPetFurPointCondition
    self._pointCond = cond
    self._duration = duration
end
function AirActionMoveToFurniture:Start()
    ---@type AirActionMoveToDo
    self._moveToAction =
        AirActionMoveToDo:New(
        self._pet,
        self._furniture:Floor(),
        self._furPoint:MovePoint(),
        AircraftPetMoveType.ToFurniture,
        self._main
    )
    self._moveToAction:Start()
    self._running = true
end
function AirActionMoveToFurniture:IsOver()
    return not self._running
end
function AirActionMoveToFurniture:Update(deltaTimeMS)
    if self._running then
        self._moveToAction:Update(deltaTimeMS)
        if self._moveToAction:IsOver() then
            self._running = false
            self:Stop()
        end
    end
end
function AirActionMoveToFurniture:Duration()
    return nil
end
function AirActionMoveToFurniture:CurrentTime()
    return nil
end
function AirActionMoveToFurniture:Stop()
    if self._running then
        --中途停止时需要释放家具点
        self._pointCond:ReleasePointOnStop()
        self._running = false
    else
        --执行完了MoveToDo，开始执行与家具交互
        local action =
            AirActionOnFurniture:New(self._pet, self._furniture, self._furPoint, self._pointCond, self._duration)
        self._pet:StartMainAction(action)
    end
end
function AirActionMoveToFurniture:Dispose()
    if self._running then
        --中途停止时需要释放家具点
        self._pointCond:ReleasePointOnStop()
        self._running = false
    end
end
function AirActionMoveToFurniture:Pets()
    return {self._pet}
end
