--[[
    RenderPartnerComponent : 伙伴
]]

---@class RenderPartnerComponent: Object
_class( "RenderPartnerComponent", Object )
RenderPartnerComponent = RenderPartnerComponent

---
function RenderPartnerComponent:Constructor()

end
---
---@param owner Entity
function RenderPartnerComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end
---
function RenderPartnerComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end



--[[
    Entity Extensions
]]
---@return RenderPartnerComponent
function Entity:RenderPartner()
    return self:GetComponent(self.WEComponentsEnum.RenderPartner)
end

---
function Entity:HasRenderPartner()
    return self:HasComponent(self.WEComponentsEnum.RenderPartner)
end

---
function Entity:AddRenderPartner()
    local index = self.WEComponentsEnum.RenderPartner;
    local component = RenderPartnerComponent:New()
    self:AddComponent(index, component)
end

---
function Entity:ReplaceRenderPartner()
    local index = self.WEComponentsEnum.RenderPartner;
    local component = RenderPartnerComponent:New()
    self:ReplaceComponent(index, component)
end

---
function Entity:RemoveRenderPartner()
    if self:HasRenderPartner() then
        self:RemoveComponent(self.WEComponentsEnum.RenderPartner)
    end
end