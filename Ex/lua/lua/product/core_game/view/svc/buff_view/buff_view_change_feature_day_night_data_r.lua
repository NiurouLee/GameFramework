--[[
    主动改昼夜（夜王三阶段）
]]
---@class BuffViewChangeFeatureDayNightData:BuffViewBase
_class("BuffViewChangeFeatureDayNightData", BuffViewBase)
BuffViewChangeFeatureDayNightData = BuffViewChangeFeatureDayNightData

function BuffViewChangeFeatureDayNightData:PlayView(TT)
    ---@type BuffResultChangeFeatureDayData
    local result = self:GetBuffResult()
    local oldState = result:GetOldState()
    local newState = result:GetNewState()
    local restRound = result:GetRestRound()
    ---@type FeatureServiceRender
    local featureSvc = self._world:GetService("FeatureRender")
    featureSvc:ModifyDayNightData(TT,oldState,newState,restRound)
end
