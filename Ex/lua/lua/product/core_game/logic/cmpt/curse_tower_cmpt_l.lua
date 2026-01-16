--[[------------------------------------------------------------------------------------------
    CurseTowerComponent : 挂在诅咒塔上的脚本
]]--------------------------------------------------------------------------------------------

---@class CurseTowerState
local CurseTowerState = {
    Idle = -1, ---初始状态
    Deactive = 0,   ---失活
    Active = 1,     ---激活
}
CurseTowerState = CurseTowerState
_enum("CurseTowerState", CurseTowerState)

---@class CurseTowerComponent: Object
_class( "CurseTowerComponent", Object )
CurseTowerComponent = CurseTowerComponent

function CurseTowerComponent:Constructor()
    ---当前塔的索引
    self._towerIndex = 0

    ---塔的状态，0代表失活，1代表激活
    self._towerState = CurseTowerState.Idle
end

function CurseTowerComponent:SetTowerIndex(index)
    self._towerIndex = index
end

function CurseTowerComponent:GetTowerIndex()
    return self._towerIndex
end

function CurseTowerComponent:SetTowerState(state)
    self._towerState = state
end

function CurseTowerComponent:GetTowerState()
    return self._towerState
end
-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function CurseTowerComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function CurseTowerComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return CurseTowerComponent
function Entity:CurseTower()
    return self:GetComponent(self.WEComponentsEnum.CurseTower)
end


function Entity:HasCurseTower()
    return self:HasComponent(self.WEComponentsEnum.CurseTower)
end


function Entity:AddCurseTower()
    local index = self.WEComponentsEnum.CurseTower;
    local component = CurseTowerComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplaceCurseTower()
    local index = self.WEComponentsEnum.CurseTower;
    local component = CurseTowerComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemoveCurseTower()
    if self:HasCurseTower() then
        self:RemoveComponent(self.WEComponentsEnum.CurseTower)
    end
end