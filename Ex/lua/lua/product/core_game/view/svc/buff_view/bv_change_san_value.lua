--[[
    修改San值
]]
---@class BuffViewChangeSanValue:BuffViewBase
_class("BuffViewChangeSanValue", BuffViewBase)
BuffViewChangeSanValue = BuffViewChangeSanValue

function BuffViewChangeSanValue:PlayView(TT)
    ---@type BuffResultChangeSanValue
    local result = self._buffResult
    ---@type FeatureServiceRender
    local featureSvcRender = self._world:GetService("FeatureRender")
    if featureSvcRender then
    featureSvcRender:NotifySanValueChange(result:GetCurSan(), result:GetOldSan(), result:GetRealModifyValue())
    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")
    svcPlayBuff:PlayBuffView(TT, NTSanValueChange:New(result:GetCurSan(),result:GetOldSan(),result:GetDebtVal(),result:GetModifyTimes()))
    end
end
