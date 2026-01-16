--[[------------------------------------------------------------------------------------------
    GridMoveComponent : 基于逻辑坐标的移动控制组件
]] --------------------------------------------------------------------------------------------


_class("GridMoveComponent", Object)
---@class GridMoveComponent: Object
GridMoveComponent = GridMoveComponent

function GridMoveComponent:Constructor(speed, targetPos, originPos)
    self.speed = speed
    self.targetPos = Vector2(targetPos.x,targetPos.y)
    self.originPos = Vector2(originPos.x,originPos.y)
    self.isRefreshPiece = true
    self.isUpdateBlockInfo =false
    self.movingHeight = nil--格子下落功能 移动过程中设置的高度
end
---@return Vector2
function GridMoveComponent:GetTargetPos()
    return self.targetPos:Clone()
end
---@return Vector2
function GridMoveComponent:GetOriginPos()
    return self.originPos:Clone()
end
---格子下落功能 移动过程中设置的高度
function GridMoveComponent:SetMovingHeight(height)
    self.movingHeight = height
end
---格子下落功能 移动过程中设置的高度
function GridMoveComponent:GetMovingHeight()
    return self.movingHeight
end
function GridMoveComponent:GetSpeed()
    return self.speed
end
---@return boolean
function GridMoveComponent:HasUpdateBlockInfo()
    return self.isUpdateBlockInfo
end

function GridMoveComponent:SetUpdateBlockInfoState(state)
    self.isUpdateBlockInfo = state
end

---@param isRefreshPiece boolean
function GridMoveComponent:SetIsRefreshPiece(isRefreshPiece)
    self.isRefreshPiece = isRefreshPiece
end

---@return boolean
function GridMoveComponent:IsRefreshPiece()
    return self.isRefreshPiece
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return GridMoveComponent
function Entity:GridMove()
    return self:GetComponent(self.WEComponentsEnum.GridMove)
end

function Entity:HasGridMove()
    return self:HasComponent(self.WEComponentsEnum.GridMove)
end

function Entity:AddGridMove(speed, targetPos,originPos)
    --Log.fatal("AddGridMove TargetPos:", tostring(targetPos),"SourcePos:", tostring(originPos),"EntityID:",self:GetID()," ",Log.traceback())
    --local originPos = self:GetGridPosition()
    --local pos = Vector2(math.floor(targetPos.x),math.floor(targetPos.y))
    --self:SetGridPosition(pos)
    if self:GetGridOffset() then
        targetPos = targetPos +self:GetGridOffset()
    end
    local index = self.WEComponentsEnum.GridMove
    local component = GridMoveComponent:New(speed, targetPos, originPos)
    self:AddComponent(index, component)
    return component
end

function Entity:ReplaceGridMove(speed, targetPos,originPos)
    --Log.fatal("AddGridMove TargetPos:", tostring(targetPos),"EntityID:",self:GetID()," ",Log.traceback())
    --local originPos = self:GetGridPosition()
    --local pos = Vector2(math.floor(targetPos.x),math.floor(targetPos.y))
    --self:SetGridPosition(pos)
    if self:GetGridOffset() then
        targetPos = targetPos +self:GetGridOffset()
    end
    local index = self.WEComponentsEnum.GridMove
    local component = GridMoveComponent:New(speed, targetPos, originPos)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveGridMove()
    if self:HasGridMove() then
        self:RemoveComponent(self.WEComponentsEnum.GridMove)
    end
end
