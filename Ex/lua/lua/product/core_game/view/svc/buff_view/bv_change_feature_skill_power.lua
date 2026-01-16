--[[
    改变模块技能CD
]]
---@class BuffViewChangeFeatureSkillPower:BuffViewBase
_class("BuffViewChangeFeatureSkillPower", BuffViewBase)
BuffViewChangeFeatureSkillPower = BuffViewChangeFeatureSkillPower

function BuffViewChangeFeatureSkillPower:PlayView(TT)
    ---@type BuffResultChangeFeatureSkillPower
    local result = self._buffResult
    ---@type FeatureServiceRender
    local featureSvcRender = self._world:GetService("FeatureRender")
    if featureSvcRender then
        local dataList = result:GetFeatureSkillPowerDataList()
        for _, data in ipairs(dataList) do
            ---@type FeatureSkillCommonPowerData
            local powerData = data
            featureSvcRender:NotifyFeatureSkillPowerChange(powerData.featureType,powerData.power,powerData.ready)
        end
        -- ---@type PlayBuffService
        -- local svcPlayBuff = self._world:GetService("PlayBuff")
        -- svcPlayBuff:PlayBuffView(TT, NTSanValueChange:New(result:GetCurSan(),result:GetOldSan(),result:GetDebtVal(),result:GetModifyTimes()))
    end
end
