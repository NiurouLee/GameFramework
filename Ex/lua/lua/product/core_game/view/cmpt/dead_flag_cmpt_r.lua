--[[------------------------------------------------------------------------------------------
    DeadFlagComponent : 用于标记表现死亡
    怪物表现上的死亡有固定的阶段，因此并不是所有加了deadmark的都立即会挂上deadflag组件
]] --------------------------------------------------------------------------------------------

---@class DeadFlagComponent: Object
_class("DeadFlagComponent", Object)

function DeadFlagComponent:Constructor()

end

--死亡掉落
function DeadFlagComponent:SetDeadDrop(deadDrop)
    self._deadDrop = deadDrop
end
function DeadFlagComponent:GetDeadDrop()
    return self._deadDrop
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return DeadFlagComponent
function Entity:DeadFlag()
    return self:GetComponent(self.WEComponentsEnum.DeadFlag)
end

function Entity:HasDeadFlag()
    return self:HasComponent(self.WEComponentsEnum.DeadFlag)
end

function Entity:AddDeadFlag()
    local index = self.WEComponentsEnum.DeadFlag
    local component = DeadFlagComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceDeadFlag()
    local index = self.WEComponentsEnum.DeadFlag
    local component = DeadFlagComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveDeadFlag()
    if self:HasDeadFlag() then
        self:RemoveComponent(self.WEComponentsEnum.DeadFlag)
    end
end
