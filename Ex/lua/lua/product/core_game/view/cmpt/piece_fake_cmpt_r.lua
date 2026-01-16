--[[------------------------------------------------------------------------------------------
    PieceFakeComponent : 格子表现数据
]] --------------------------------------------------------------------------------------------

---@class PieceFakeComponent: Object
_class("PieceFakeComponent", Object)
PieceFakeComponent = PieceFakeComponent

function PieceFakeComponent:Constructor(PieceFakeType)
    self.Type = PieceFakeType or PieceFakeType.None
end

---@return PieceFakeType
function PieceFakeComponent:GetPieceFakeType()
    return self.Type
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return PieceFakeComponent
function Entity:PieceFake()
    return self:GetComponent(self.WEComponentsEnum.PieceFake)
end

function Entity:HasPieceFake()
    return self:HasComponent(self.WEComponentsEnum.PieceFake)
end

function Entity:AddPieceFake(PieceFakeType)
    local index = self.WEComponentsEnum.PieceFake
    local component = PieceFakeComponent:New(PieceFakeType)
    self:AddComponent(index, component)
end

function Entity:ReplacePieceFake(PieceFakeType)
    local index = self.WEComponentsEnum.PieceFake
    local component = PieceFakeComponent:New(PieceFakeType)
    self:ReplaceComponent(index, component)
end

function Entity:RemovePieceFake()
    if self:HasPieceFake() then
        self:RemoveComponent(self.WEComponentsEnum.PieceFake)
    end
end
