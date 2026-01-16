---@class StatePetForecast : State
_class("StatePetForecast", State)
StatePetForecast = StatePetForecast

function StatePetForecast:Init()
    self.fsm = self:GetFsm()
    ---@type UIPetForecast
    self.ui = self.fsm:GetData()
    ---@type PetForecastData
    self.data = self.ui.data
end

function StatePetForecast:Destroy()
    StatePetForecast.super:Destroy()
    self.ui = nil
end
