--[[--------------------
    AINewNode AI中按距离排序
--]] --------------------
-- require "ai_config"
----------------------------------------------------------------
---用于移动判断距离的“排序单元”
---@class AiSortByDistance : Object
_class("AiSortByDistance", Object)
AiSortByDistance = AiSortByDistance
function AiSortByDistance:Constructor(centrePos, dataPos, nIndex)
    self.centre = centrePos
    self.data = dataPos
    self.m_nIndex = nIndex or 0
    self.m_nDistance = self:Distance()
end
function AiSortByDistance:GetDistance()
    return self.m_nDistance
end
function AiSortByDistance:GetPosData()
    return self.data
end
function AiSortByDistance:Distance()
    return GameHelper.ComputeLogicDistance(self.centre, self.data)
end
---@param dataA AiSortByDistance
---@param dataB AiSortByDistance
AiSortByDistance._ComparerByFar = function(dataA, dataB)
    local nDistanceA = dataA:GetDistance()
    local nDistanceB = dataB:GetDistance()
    if nDistanceA > nDistanceB then
        return 1
    elseif nDistanceA < nDistanceB then
        return -1
    else
        return dataB.m_nIndex - dataA.m_nIndex
    end
end
---@param dataNew AiSortByDistance
---@param dataOld AiSortByDistance
AiSortByDistance._ComparerByNear = function(dataNew, dataOld)
    local nDistanceA = dataNew:GetDistance()
    local nDistanceB = dataOld:GetDistance()
    if nDistanceA > nDistanceB then
        return -1
    elseif nDistanceA < nDistanceB then
        return 1    ---返回值为正表示A排在B前面
    else    ---m_nIndex小的在前面
        return dataOld.m_nIndex - dataNew.m_nIndex
    end
end
---@param dataA AiSortByDistance
---@param dataB AiSortByDistance
AiSortByDistance._ComparerByNear_2 = function(dataA, dataB)
    if dataA.data == dataB.data then
        return 0
    end
    return AiSortByDistance._ComparerByNear(dataA, dataB)
end
----------------------------------------------------------------
