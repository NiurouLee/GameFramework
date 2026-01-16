--[[
    骑乘Buff结果
]]
---@class BuffResultRide:BuffResultBase
_class("BuffResultRide", BuffResultBase)
BuffResultRide = BuffResultRide

---@param rideID number
---@param gridLocRes DataGridLocationResult
---@param isRide boolean
function BuffResultRide:Constructor(rideID, mountID, gridLocRes)
    self._rideID = rideID
    self._mountID = mountID
    ---@type DataGridLocationResult
    self._gridLocRes = gridLocRes
end

function BuffResultRide:GetRideEntityID()
    return self._rideID
end

function BuffResultRide:GetMountEntityID()
    return self._mountID
end

---@return DataGridLocationResult
function BuffResultRide:GetDataGridLocationResult()
    return self._gridLocRes
end

function BuffResultRide:SetNotifyEntity(entity)
    self._notifyEntity = entity
end

function BuffResultRide:GetNotifyEntity()
    return self._notifyEntity
end

function BuffResultRide:SetNotifyPos(notifyPos)
    self._notifyPos = notifyPos
end

function BuffResultRide:GetNotifyPos()
    return self._notifyPos
end

function BuffResultRide:SetTargetPos(targetPos)
    self._targetPos = targetPos
end

function BuffResultRide:GetTargetPos()
    return self._targetPos
end

function BuffResultRide:SetNotifyChainSkillIndex(index)
    self._chainSkillIndex = index
end

function BuffResultRide:GetNotifyChainSkillIndex()
    return self._chainSkillIndex
end

function BuffResultRide:SetPlayed(hasPlayed)
    self._hasPlayed = hasPlayed
end

function BuffResultRide:HasPlayed()
    if self._hasPlayed and self._hasPlayed == true then
        return true
    end

    return false
end
