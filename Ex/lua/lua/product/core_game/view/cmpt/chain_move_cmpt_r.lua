--[[------------------------------------------------------------------------------------------
    ChainMoveComponent : 当前划线的路径
]] --------------------------------------------------------------------------------------------

_class("ChainMoveComponent", Object)
---@class ChainMoveComponent: Object
ChainMoveComponent = ChainMoveComponent

function ChainMoveComponent:Constructor(chainPath, pathIndex, startTime, speed, curGridPathIndex)
    self._chainPath = chainPath
    self._pathIndex = pathIndex
    self._startTime = startTime
    self._speed = speed
    ---当前所在的格子在Path中的索引
    self._curGridPathIndex = curGridPathIndex

    ---宝宝是否在停止等待状态
    self._waitState = false
    ---宝宝在等待状态时可以恢复行动的时间
    self._canMoveTime = 0
    ---行动是否完成： 传送漩涡可能会把Entity当前位置重置为起点
    self._moveCount = 0
    ---计算连线的出发前等待时间
    self._startWaitTime = 0
    ---攻击次数
    self._attackCount = 0
    ---星灵到达每个坐标的时间列表
    self._pathArriveTimeList = {}
end

function ChainMoveComponent:Dispose()
    self._chainPath = nil
    self._pathIndex = nil
    self._startTime = nil
    self._speed = nil
    self._moveCount = 0
end

function ChainMoveComponent:AddPathArriveTime(pathIndex, arriveTime)
    self._pathArriveTimeList[pathIndex] = arriveTime
end

function ChainMoveComponent:GetPathArriveTime(pathIndex)
    return self._pathArriveTimeList[pathIndex]
end

function ChainMoveComponent:GetChainPath()
    return self._chainPath
end

function ChainMoveComponent:GetPathIndex()
    return self._pathIndex
end

function ChainMoveComponent:SetPathIndex(pathIndex)
    self._pathIndex = pathIndex
end

function ChainMoveComponent:GetStartTime()
    return self._startTime
end

function ChainMoveComponent:GetSpeed()
    return self._speed
end

function ChainMoveComponent:GetCurGridPathIndex()
    return self._curGridPathIndex
end

function ChainMoveComponent:SetCurGridPathIndex(pathIndex)
    self._curGridPathIndex = pathIndex
end

function ChainMoveComponent:IsWait()
    return self._waitState
end

function ChainMoveComponent:SetWaitState(state)
    self._waitState = state
end
---@param time number
function ChainMoveComponent:SetCanMoveTime(time)
    self._canMoveTime = time
end

function ChainMoveComponent:GetCanMoveTime()
    return self._canMoveTime
end


---------------------------------------------------------------
---@return ChainMoveComponent
function Entity:ChainMove()
    return self:GetComponent(self.WEComponentsEnum.ChainMove)
end

function Entity:HasChainMove()
    return self:HasComponent(self.WEComponentsEnum.ChainMove)
end

function Entity:AddChainMove(chainPath, pathIndex, startTime, speed)
    local index = self.WEComponentsEnum.ChainMove
    local component = ChainMoveComponent:New(chainPath, pathIndex, startTime, speed, pathIndex)
    self:AddComponent(index, component)
end

function Entity:ReplaceChainMove(chainPath, pathIndex, startTime, speed)
    local index = self.WEComponentsEnum.ChainMove
    local curGridPathIndex = pathIndex

    if self:HasChainMove() then
        curGridPathIndex = self:ChainMove():GetCurGridPathIndex()
    end
    local component = ChainMoveComponent:New(chainPath, pathIndex, startTime, speed, curGridPathIndex)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveChainMove()
    if self:HasChainMove() then
        self:RemoveComponent(self.WEComponentsEnum.ChainMove)
    end
end
