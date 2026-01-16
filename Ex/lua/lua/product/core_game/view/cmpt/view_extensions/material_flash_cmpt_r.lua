--[[------------------------------------------------------------------------------------------
    MaterialFlashComponent : 在攻击范围内的怪物材质闪烁效果组件
]] --------------------------------------------------------------------------------------------

---@class MaterialFlashComponent: Object
_class("MaterialFlashComponent", Object)
MaterialFlashComponent = MaterialFlashComponent

function MaterialFlashComponent:Constructor()
end

function MaterialFlashComponent:WEC_PostRemoved()
end

---@param owner Entity
function MaterialFlashComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end
--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return MaterialFlashComponent
function Entity:MaterialFlash()
    return self:GetComponent(self.WEComponentsEnum.MaterialFlash)
end

function Entity:HasMaterialFlash()
    return self:HasComponent(self.WEComponentsEnum.MaterialFlash)
end

function Entity:AddMaterialFlash()
    local index = self.WEComponentsEnum.MaterialFlash
    local component = MaterialFlashComponent:New()
    self:AddComponent(index, component)
end

function Entity:RemoveMaterialFlash()
    if self:HasMaterialFlash() then
        self:RemoveComponent(self.WEComponentsEnum.MaterialFlash)
    end
end
