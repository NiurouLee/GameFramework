--[[------------------------------------------------------------------------------------------
    TrailEffectExComponent : 精英怪的材质动画组件
]] --------------------------------------------------------------------------------------------

---@class TrailEffectExComponent: Object
_class("TrailEffectExComponent", Object)
TrailEffectExComponent = TrailEffectExComponent

function TrailEffectExComponent:Constructor()
    self._trailEffectContainer = nil
end

---@param csTrailEffectEx TrailEffectEx
function TrailEffectExComponent:SetTrailEffectExController(csTrailEffectEx)
    ---@type TrailEffectEx
    self._trailEffectEx = csTrailEffectEx
end

function TrailEffectExComponent:LoadContainer(container)
    self._trailEffectContainer = container
    self._trailEffectEx:SetProfile(self._trailEffectContainer.Obj)
end

--------------------------------------------------------------------------------------------

-- This:
--//////////////////////////////////////////////////////////

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
function Entity:TrailEffectEx()
    return self:GetComponent(self.WEComponentsEnum.TrailEffectEx)
end

function Entity:HasTrailEffectEx()
    return self:HasComponent(self.WEComponentsEnum.TrailEffectEx)
end

---@param csTrailEffectEx TrailEffectEx
function Entity:AddTrailEffectEx(container, csTrailEffectEx)
    assert(container)
    local index = self.WEComponentsEnum.TrailEffectEx
    local component = TrailEffectExComponent:New(self)
    component:SetTrailEffectExController(csTrailEffectEx)
    component:LoadContainer(container)
    self:AddComponent(index, component)
end

function Entity:ReplaceTrailEffectEx()
    local index = self.WEComponentsEnum.TrailEffectEx
    local component = TrailEffectExComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveTrailEffectEx()
    if self:HasTrailEffectEx() then
        self:RemoveComponent(self.WEComponentsEnum.TrailEffectEx)
    end
end
