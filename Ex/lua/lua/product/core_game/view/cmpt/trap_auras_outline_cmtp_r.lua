_class( "TrapAurasOutlineComponent", Object )
---@class TrapAurasOutlineComponent: Object
TrapAurasOutlineComponent = TrapAurasOutlineComponent


function TrapAurasOutlineComponent:Constructor()
    --self._aurasEffect    = nil
    --self._aurasBirthAnim = nil
    --self._aurasDeathAnim = nil
    --self._aurasLoopAnim  = nil
    --self._aurasGroupID   = nil
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return TrapAurasOutlineComponent
function Entity:TrapAurasOutlineComponent()
    return self:GetComponent(self.WEComponentsEnum.TrapAurasOutline)
end


function Entity:HasTrapAurasOutline()
    return self:HasComponent(self.WEComponentsEnum.TrapAurasOutline)
end


function Entity:AddTrapAurasOutline()
    local index = self.WEComponentsEnum.TrapAurasOutline;
    local component = TrapAurasOutlineComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplaceTrapAurasOutline()
    local index = self.WEComponentsEnum.TrapAurasOutline;
    local component = TrapAurasOutlineComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemoveTrapAurasOutline()
    if self:HasTrapAurasOutline() then
        self:RemoveComponent(self.WEComponentsEnum.TrapAurasOutline)
    end
end
