--[[
    改昼夜模块ui样式（夜王三阶段）
]]
---@class BuffViewChangeFeatureDayNightUiStyle:BuffViewBase
_class("BuffViewChangeFeatureDayNightUiStyle", BuffViewBase)
BuffViewChangeFeatureDayNightUiStyle = BuffViewChangeFeatureDayNightUiStyle

function BuffViewChangeFeatureDayNightUiStyle:PlayView(TT)
    ---@type BuffResultChangeFeatureDayNightUiStyle
    local result = self:GetBuffResult()
    local uiStyle = result:GetUiStyle()
    ---@type FeatureServiceRender
    local featureSvc = self._world:GetService("FeatureRender")
    featureSvc:NotifyDayNightUIStyleChange(uiStyle)
end
