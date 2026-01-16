require("calc_base")

---@class SkillEffectIncreaseSanMode
---@field FixVal number
---@field LossPercent number
SkillEffectIncreaseSanMode = {
    FixVal = 1, --固定值
    LossPercent = 2, --流失San值百分比
}
_enum("SkillEffectIncreaseSanMode", SkillEffectIncreaseSanMode)

_class("SkillEffectCalc_IncreaseSan", SkillEffectCalc_Base)
---@class SkillEffectCalc_IncreaseSan : SkillEffectCalc_Base
SkillEffectCalc_IncreaseSan = SkillEffectCalc_IncreaseSan

---@param calcParam SkillEffectCalcParam
---@param targetEntityID number
function SkillEffectCalc_IncreaseSan:CalculateOnSingleTarget(calcParam, targetEntityID)
    if targetEntityID <= 0 then
        return
    end

    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")

    if not lsvcFeature:HasFeatureType(FeatureType.Sanity) then
        return
    end

    local minVal = lsvcFeature:GetSanMinValue()
    local maxVal = lsvcFeature:GetSanMaxValue()

    ---@type SkillEffectParam_IncreaseSan
    local param = calcParam:GetSkillEffectParam()

    local val = self:_GetIncreaseSanVal(param)
    local currentVal = lsvcFeature:GetSanValue()
    local finalVal = currentVal + val
    if finalVal < minVal then
        finalVal = minVal
    end
    if finalVal > maxVal then
        finalVal = maxVal
    end

    local delta = finalVal - currentVal
    return SkillEffectResult_IncreaseSan:New(delta)
end

---@param param SkillEffectParam_IncreaseSan
function SkillEffectCalc_IncreaseSan:_GetIncreaseSanVal(param)
    local mode = param:GetMode()
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")

    local val = 0
    if mode == SkillEffectIncreaseSanMode.FixVal then
        val = param:GetSanValue()
    elseif mode == SkillEffectIncreaseSanMode.LossPercent then
        local currentVal = lsvcFeature:GetSanValue()
        local minVal = lsvcFeature:GetSanMinValue()
        local maxVal = lsvcFeature:GetSanMaxValue()

        val = param:GetSanValue() * (maxVal - currentVal)
        val = math.floor(val + 0.5)
    end

    return val
end
