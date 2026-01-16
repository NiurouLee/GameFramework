--[[
    PreviewChessPetComponent : 战棋棋子的预览数据组件
]]

---@class PreviewChessPetComponent: Object
_class( "PreviewChessPetComponent", Object )
PreviewChessPetComponent = PreviewChessPetComponent

---构造
function PreviewChessPetComponent:Constructor()
    self._moveRangeEffectEntityIDList = {}
    self._attackTargetEffectEntityIDList = {}
    self._attackRangeEffectEntityIDList = {} 
end

---添加移动范围特效ID
---@param entityID number 特效ID
function PreviewChessPetComponent:AddMoveRangeEffectEntityID(entityID)
    self._moveRangeEffectEntityIDList[#self._moveRangeEffectEntityIDList + 1] = entityID
end

---添加攻击范围特效ID
---@param entityID number 特效ID
function PreviewChessPetComponent:AddAttackRangeEffectEntityID(entityID)
    self._attackRangeEffectEntityIDList[#self._attackRangeEffectEntityIDList + 1] = entityID
end

---添加攻击目标特效ID
---@param entityID number 特效ID
function PreviewChessPetComponent:AddAttackTargetEffectEntityID(entityID)
    self._attackTargetEffectEntityIDList[#self._attackTargetEffectEntityIDList + 1] = entityID
end

---获取移动范围的特效列表
function PreviewChessPetComponent:GetMoveRangeEffectEntityIDList()
    return self._moveRangeEffectEntityIDList
end

---获取攻击范围的特效列表
function PreviewChessPetComponent:GetAttackRangeEffectEntityIDList()
    return self._attackRangeEffectEntityIDList
end

---获取攻击目标的特效列表
function PreviewChessPetComponent:GetAttackTargetEffectEntityIDList()
    return self._attackTargetEffectEntityIDList
end

---重置所有特效列表
function PreviewChessPetComponent:ClearChessPetPreviewList()
    self._moveRangeEffectEntityIDList = {}
    self._attackTargetEffectEntityIDList = {}
    self._attackRangeEffectEntityIDList = {} 
end

--[[
    Entity Extensions
]]
---获取组件
---@return PreviewChessPetComponent
function Entity:PreviewChessPet()
    return self:GetComponent(self.WEComponentsEnum.PreviewChessPet)
end

---查询是否有组件
function Entity:HasPreviewChessPet()
    return self:HasComponent(self.WEComponentsEnum.PreviewChessPet)
end

---添加组件
function Entity:AddPreviewChessPet()
    local index = self.WEComponentsEnum.PreviewChessPet;
    local component = PreviewChessPetComponent:New()
    self:AddComponent(index, component)
end

---重置组件
function Entity:ReplacePreviewChessPet()
    local index = self.WEComponentsEnum.PreviewChessPet;
    local component = PreviewChessPetComponent:New()
    self:ReplaceComponent(index, component)
end

---移除组件
function Entity:RemovePreviewChessPet()
    if self:HasPreviewChessPet() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewChessPet)
    end
end