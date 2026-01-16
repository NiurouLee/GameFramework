--[[
    LogicPartnerComponent : 伙伴
]]

---@class LogicPartnerComponent: Object
_class( "LogicPartnerComponent", Object )
LogicPartnerComponent = LogicPartnerComponent
---
function LogicPartnerComponent:Constructor()
end

---@param owner Entity
function LogicPartnerComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end
---
function LogicPartnerComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end


--[[
    Entity Extensions
]]
---@return LogicPartnerComponent
function Entity:LogicPartner()
    return self:GetComponent(self.WEComponentsEnum.LogicPartner)
end

---
function Entity:HasLogicPartner()
    return self:HasComponent(self.WEComponentsEnum.LogicPartner)
end

---
function Entity:AddLogicPartner()
    local index = self.WEComponentsEnum.LogicPartner;
    local component = LogicPartnerComponent:New()
    self:AddComponent(index, component)
end

---
function Entity:ReplaceLogicPartner()
    local index = self.WEComponentsEnum.LogicPartner;
    local component = LogicPartnerComponent:New()
    self:ReplaceComponent(index, component)
end

---
function Entity:RemoveLogicPartner()
    if self:HasLogicPartner() then
        self:RemoveComponent(self.WEComponentsEnum.LogicPartner)
    end
end