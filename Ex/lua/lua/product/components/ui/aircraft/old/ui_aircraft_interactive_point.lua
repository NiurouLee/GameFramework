---房间内的交互点对象
---@class UIAircraftInteractivePoint:Object 
_class("UIAircraftInteractivePoint", Object)
UIAircraftInteractivePoint = UIAircraftInteractivePoint

function UIAircraftInteractivePoint:Constructor(pos, targetPos, faceIDList)
    ---@type Vector3
    self._pos = pos
    ---@type Vector3
    self._targetPos = targetPos
    ---@type Vector3
    self._forward = nil
    if targetPos then
        self._forward = targetPos - pos
    end
    ---@type table<number, number>
    self._faceIDList = faceIDList

    ---@type number
    self._index = 0
end

---@type Vector3
function UIAircraftInteractivePoint:GetPos()
    return self._pos
end

---@type Vector3
function UIAircraftInteractivePoint:GetForward()
    return self._forward
end

---@type table<number, number>
function UIAircraftInteractivePoint:GetFaceIDList()
    return self._faceIDList
end

function UIAircraftInteractivePoint:SetIndex(index)
    self._index = index
end

function UIAircraftInteractivePoint:GetIndex()
    return self._index
end