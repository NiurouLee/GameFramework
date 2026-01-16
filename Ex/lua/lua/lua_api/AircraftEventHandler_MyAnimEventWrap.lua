---@class AircraftEventHandler.MyAnimEvent
---@field targets table
---@field clipName string
---@field time float
---@field opration AircraftEventHandler.Opration
local m = {}
---@return AircraftEventHandler.MyAnimEvent
function m:Copy() end
AircraftEventHandler = {}
AircraftEventHandler.MyAnimEvent = m
return m