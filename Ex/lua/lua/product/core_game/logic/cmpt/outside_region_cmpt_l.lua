--[[------------------------------------------------------------------------------------------
    OutsideRegionComponent : 目前逻辑和表现都用这个组件
]] --------------------------------------------------------------------------------------------

_class("OutsideRegionComponent", Object)
---@class OutsideRegionComponent: Object
OutsideRegionComponent = OutsideRegionComponent

function OutsideRegionComponent:Constructor(boardIndex)
    self._boardIndex = boardIndex --棋盘编号

    self._monsterID = nil
    -- self._trapID = nil
end

function OutsideRegionComponent:GetBoardIndex()
    return self._boardIndex
end
function OutsideRegionComponent:SetBoardIndex(boardIndex)
    self._boardIndex = boardIndex
end

function OutsideRegionComponent:GetMonsterID()
    return self._monsterID
end
function OutsideRegionComponent:SetMonsterID(monsterID)
    self._monsterID = monsterID
end

-- function OutsideRegionComponent:GetTrapID()
--     return self._trapID
-- end
-- function OutsideRegionComponent:SetTrapID(trapID)
--     self._trapID = trapID
-- end

---@return OutsideRegionComponent
function Entity:OutsideRegion()
    return self:GetComponent(self.WEComponentsEnum.OutsideRegion)
end

function Entity:HasOutsideRegion()
    return self:HasComponent(self.WEComponentsEnum.OutsideRegion)
end

function Entity:AddOutsideRegion(boardIndex)
    local index = self.WEComponentsEnum.OutsideRegion
    local component = OutsideRegionComponent:New(boardIndex)
    self:AddComponent(index, component)
end

function Entity:ReplaceOutsideRegion(boardIndex)
    local index = self.WEComponentsEnum.OutsideRegion
    local component = OutsideRegionComponent:New(boardIndex)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveOutsideRegion()
    if self:HasOutsideRegion() then
        self:RemoveComponent(self.WEComponentsEnum.OutsideRegion)
    end
end
