--[[
    PetRenderComponent : 挂在光灵身上的表现组件，用于表现数据使用
]]

_class( "PetRenderComponent", Object )
---@class PetRenderComponent: Object
PetRenderComponent = PetRenderComponent

function PetRenderComponent:Constructor()
    -- 对应PickPosPolicy.Pet1601751，记录HP超过限定百分比（目前50%）时是否释放过主动技
    self._pet1601751HPAboveLimitAutoCastActiveCount = 0
end

---光灵米洛斯 幻影攻击（连线移动与主动技时触发） 表现上计算位置，避免重叠，记录下使用的位置
function PetRenderComponent:RecordPetMinosGhostUsedPos(pos)
    if not self._petMinosGhostUsedPosList then
        self._petMinosGhostUsedPosList = {}
    end
    table.insert(self._petMinosGhostUsedPosList,pos)
end
function PetRenderComponent:ClearPetMinosGhostUsedPos(pos)
    if self._petMinosGhostUsedPosList then
        --有重复的也只删一个
        table.removev(self._petMinosGhostUsedPosList, pos)
    end
end
function PetRenderComponent:GetPetMinosGhostUsedPosList()
    if not self._petMinosGhostUsedPosList then
        self._petMinosGhostUsedPosList = {}
    end
    return self._petMinosGhostUsedPosList
end
function PetRenderComponent:ClearPetMinosGhostUsedPosList()
    self._petMinosGhostUsedPosList = {}
end

---@param owner Entity
function PetRenderComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function PetRenderComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

--region 自动战斗-PickPosPolicy.Pet1601751-阿克希亚
function PetRenderComponent:GetPet1601751HPAboveLimitAutoCastActiveCount()
    return self._pet1601751HPAboveLimitAutoCastActiveCount
end

function PetRenderComponent:TickPet1601751HPAboveLimitAutoCastActiveCount()
    self._pet1601751HPAboveLimitAutoCastActiveCount = self._pet1601751HPAboveLimitAutoCastActiveCount + 1
end

function PetRenderComponent:ClearPet1601751HPAboveLimitAutoCastActiveCount()
    self._pet1601751HPAboveLimitAutoCastActiveCount = 0
end
--endregion


--[[
    Entity Extensions
]]
---@return PetRenderComponent
function Entity:PetRender()
    return self:GetComponent(self.WEComponentsEnum.PetRender)
end


function Entity:HasPetRender()
    return self:HasComponent(self.WEComponentsEnum.PetRender)
end


function Entity:AddPetRender()
    local index = self.WEComponentsEnum.PetRender;
    local component = PetRenderComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplacePetRender()
    local index = self.WEComponentsEnum.PetRender;
    local component = PetRenderComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemovePetRender()
    if self:HasPetRender() then
        self:RemoveComponent(self.WEComponentsEnum.PetRender)
    end
end