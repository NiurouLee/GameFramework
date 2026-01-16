--[[--------------------
    AINewNode AI中按距离排序，距离相同则按当前位置与行动点的角度排序
--]] --------------------

---@class AiSortByDistanceAndDir : Object
_class("AiSortByDistanceAndDir", Object)
AiSortByDistanceAndDir = AiSortByDistanceAndDir
function AiSortByDistanceAndDir:Constructor(centerPos, workPos, curPos, nIndex)
    self.centerPos = centerPos
    self.workPos = workPos
    self.curPos = curPos
    self.index = nIndex or 0
    self.distance = self:Distance()
end
function AiSortByDistanceAndDir:GetDistance()
    return self.distance
end
function AiSortByDistanceAndDir:GetPosData()
    return self.workPos
end
function AiSortByDistanceAndDir:Distance()
    return GameHelper.ComputeLogicDistance(self.centerPos, self.workPos)
end

---上方向的向量沿逆时针旋转至workPos到curPos的向量所对应的角度（即方向优先级：上，左，下，右）
function AiSortByDistanceAndDir:GetUpAngle()
    local angle = nil
    ---@type Vector2
    local vecUp = Vector2.up
    ---@type Vector2
    local vecTarget = self.curPos - self.centerPos
    vecTarget = vecTarget.normalized
    local dot = vecUp.x * vecTarget.x + vecUp.y * vecTarget.y
    if math.abs(dot - 1.0) <= 0.000001 then
        angle = 0
    elseif math.abs(dot + 1.0) <= 0.000001 then
        angle = math.pi
    else
        angle = math.acos(dot)
        local cross = vecUp.x * vecTarget.y - vecTarget.x * vecUp.y
        if cross < 0 then
            angle = 2 * math.pi - angle
        end
    end

    local degree = angle * 180.0 / math.pi
    return degree
end

---@param dataA AiSortByDistanceAndDir
---@param dataB AiSortByDistanceAndDir
AiSortByDistanceAndDir._ComparerByNearAndDir = function(dataA, dataB)
    local nDistanceA = dataA:GetDistance()
    local nDistanceB = dataB:GetDistance()
    local angleUpToA = dataA:GetUpAngle()
    local angleUpToB = dataB:GetUpAngle()
    if nDistanceA > nDistanceB then
        return -1
    elseif nDistanceA < nDistanceB then
        return 1
    elseif angleUpToA > angleUpToB then
        return -1
    elseif angleUpToA > angleUpToB then
        return 1
    else
        return dataB.index - dataA.index
    end
end
----------------------------------------------------------------
