--赛季事件的条件和检测 OR
---@class SeasonMapConditionOr:Object
_class("SeasonMapConditionOr", Object)
SeasonMapConditionOr = SeasonMapConditionOr

function SeasonMapConditionOr:Constructor(orStr)
    if orStr then
        local strArr = string.split(orStr, "|")
        if strArr then
            ---@type SeasonMapConditionAnd[]
            self._params = {}
            for i = 1, #strArr do
                self._params[i] = SeasonMapConditionAnd:New(strArr[i])
            end
        end
    else
        self._params = nil
    end
end

---@param map table<int, int> SeasonMissionComponentInfo.m_stage_info
---@return boolean
function SeasonMapConditionOr:OnCheck(map)
    if self._params then
        local result = nil
        for i = 1, #self._params do
            if result == nil then
                result = self._params[i]:OnCheck(map)
            end
            if result == true then
                return result
            end
            result = result or self._params[i]:OnCheck(map)
        end
        return result
    end
    return true
end