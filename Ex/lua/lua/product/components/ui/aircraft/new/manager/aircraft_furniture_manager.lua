--[[
    家具管理器
]]
---@class AircraftFurnitureManager:Object
_class("AircraftFurnitureManager", Object)
AircraftFurnitureManager = AircraftFurnitureManager

function AircraftFurnitureManager:Constructor(main)
    ---@type AircraftMain
    self._main = main
end

function AircraftFurnitureManager:Init()
end

function AircraftFurnitureManager:Update(deltaTimeMS)
end
function AircraftFurnitureManager:Dispose()
end

function AircraftFurnitureManager:GetFurniture(id)
end
