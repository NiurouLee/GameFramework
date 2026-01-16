--[[------------------------------------------------------------------------------------------
    TrapExtendSkillScopeComponent : 可以扩展技能范围的机关
]] --------------------------------------------------------------------------------------------

---@class TrapExtendSkillScopeComponent: Object
_class("TrapExtendSkillScopeComponent", Object)
TrapExtendSkillScopeComponent = TrapExtendSkillScopeComponent

function TrapExtendSkillScopeComponent:Constructor(param)
    self._scopeType = param.scopeType
    self._scopeParam = param.scopeParam
end

function TrapExtendSkillScopeComponent:GetScopeType()
    return self._scopeType
end

function TrapExtendSkillScopeComponent:GetScopeParam()
    return self._scopeParam
end
-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function TrapExtendSkillScopeComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function TrapExtendSkillScopeComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

---@return TrapExtendSkillScopeComponent
--------------------------------------------------------------------------------------------

-- This:
--//////////////////////////////////////////////////////////

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
function Entity:TrapExtendSkillScope()
    return self:GetComponent(self.WEComponentsEnum.TrapExtendSkillScope)
end

function Entity:HasTrapExtendSkillScope()
    return self:HasComponent(self.WEComponentsEnum.TrapExtendSkillScope)
end

function Entity:AddTrapExtendSkillScope(param)
    local index = self.WEComponentsEnum.TrapExtendSkillScope
    local component = TrapExtendSkillScopeComponent:New(param)
    self:AddComponent(index, component)
end

function Entity:ReplaceTrapExtendSkillScope(param)
    local index = self.WEComponentsEnum.TrapExtendSkillScope
    local component = TrapExtendSkillScopeComponent:New(param)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveTrapExtendSkillScope()
    if self:HasTrapExtendSkillScope() then
        self:RemoveComponent(self.WEComponentsEnum.TrapExtendSkillScope)
    end
end
