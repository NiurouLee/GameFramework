--[[
    增加模块
]]
---@class BuffViewAddFeature:BuffViewBase
_class("BuffViewAddFeature", BuffViewBase)
BuffViewAddFeature = BuffViewAddFeature

function BuffViewAddFeature:PlayView(TT)
    ---@type BuffResultAddFeature
    local result = self._buffResult
    ---@type FeatureServiceRender
    local featureSvcRender = self._world:GetService("FeatureRender")
    if featureSvcRender then
        featureSvcRender:_InitUIFeatureList(TT)--更新一下模块ui
    end
end
