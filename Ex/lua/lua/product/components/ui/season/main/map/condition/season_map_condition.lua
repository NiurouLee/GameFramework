--赛季事件的条件和检测
---@class SeasonMapCondition:Object
_class("SeasonMapCondition", Object)
SeasonMapCondition = SeasonMapCondition

function SeasonMapCondition:Constructor(conditionStr)
    if conditionStr then
        local str = string.gsub(string.gsub(conditionStr, "%(", ""), "%)", "")
        ---@type SeasonMapConditionOr
        self._params = SeasonMapConditionOr:New(str)
    else
        self._params = nil
    end
end

---@param map table<int, int> SeasonMissionComponentInfo.m_stage_info
---@return boolean
function SeasonMapCondition:OnCheck(map)
    if self._params then
        return self._params:OnCheck(map)
    end
    return true
end