--[[
    范围中心类型组件，配合SkillScopeCenterType.Component使用
]]
---@class ScopeCenterComponent:Object
_class("ScopeCenterComponent", Object)
ScopeCenterComponent = ScopeCenterComponent

function ScopeCenterComponent:Constructor(groupId)
    self._groupId = groupId
end

---@return number 范围中心组id
function ScopeCenterComponent:GetGroupId()
    return self._groupId
end

---------------------------------------------------------------------
---@return ScopeCenterComponent
function Entity:ScopeCenter()
    return self:GetComponent(self.WEComponentsEnum.ScopeCenter)
end

function Entity:AddScopeCenter(groupId)
    local index = self.WEComponentsEnum.ScopeCenter
    local component = ScopeCenterComponent:New(groupId)
    self:AddComponent(index, component)
end

function Entity:HasScopeCenter()
    return self:HasComponent(self.WEComponentsEnum.ScopeCenter)
end

function Entity:RemoveScopeCenter()
    if self:HasScopeCenter() then
        self:RemoveComponent(self.WEComponentsEnum.ScopeCenter)
    end
end
