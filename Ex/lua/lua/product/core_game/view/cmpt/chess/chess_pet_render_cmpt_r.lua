--[[
    ChessPetRenderComponent : 棋子光灵的表现组件，存放表现类数据
]]
---@class ChessPetRenderComponent: Object
_class("ChessPetRenderComponent", Object)

---
function ChessPetRenderComponent:Constructor()
    self._canMoveEffectEntityID = nil
    self._selectEffectEntityID = nil
end

---------------------------------------------------
function ChessPetRenderComponent:GetCanMoveEffectEntityID()
    return self._canMoveEffectEntityID
end

function ChessPetRenderComponent:SetCanMoveEffectEntityID(entityID)
    self._canMoveEffectEntityID = entityID
end
---------------------------------------------------
---
function ChessPetRenderComponent:GetSelectEffectEntityID()
    return self._selectEffectEntityID
end
---
function ChessPetRenderComponent:SetSelectEffectEntityID(entityID)
    self._selectEffectEntityID = entityID
end
---------------------------------------------------
---@param owner Entity
function ChessPetRenderComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function ChessPetRenderComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

--[[
    Entity Extensions
]]
---@return ChessPetRenderComponent
function Entity:ChessPetRender()
    return self:GetComponent(self.WEComponentsEnum.ChessPetRender)
end

function Entity:HasChessPetRender()
    return self:HasComponent(self.WEComponentsEnum.ChessPetRender)
end

function Entity:AddChessPetRender()
    local index = self.WEComponentsEnum.ChessPetRender
    local component = ChessPetRenderComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceChessPetRender()
    local index = self.WEComponentsEnum.ChessPetRender
    local component = ChessPetRenderComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveChessPetRender()
    if self:HasChessPetRender() then
        self:RemoveComponent(self.WEComponentsEnum.ChessPetRender)
    end
end
