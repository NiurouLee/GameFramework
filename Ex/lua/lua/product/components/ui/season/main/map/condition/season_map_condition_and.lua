--赛季事件的条件和检测 AND
---@class SeasonMapConditionAnd:Object
_class("SeasonMapConditionAnd", Object)
SeasonMapConditionAnd = SeasonMapConditionAnd

function SeasonMapConditionAnd:Constructor(andStr)
    if andStr then
        local strArr = string.split(andStr, "&")
        if strArr then
            self._params = {}
            for i = 1, #strArr do
                local id_progress = string.split(strArr[i], ",")
                if id_progress then
                    local t =  {}
                    t.id = tonumber(id_progress[1])
                    t.progress = tonumber(id_progress[2])
                    self._params[i] = t
                end
            end
        end
    else
        self._params = nil
    end
end

---@param map table<int, int> SeasonMissionComponentInfo.m_stage_info
---@return boolean
function SeasonMapConditionAnd:OnCheck(map)
    if self._params then
        local result = nil
        for i = 1, #self._params do
            local id = self._params[i].id
            local progress = self._params[i].progress
            if result == nil then
                result = map[id] == progress
            end
            if result == false then
                return result
            end
            result = result and (map[id] == progress)
        end
        return result
    end
    return true
end