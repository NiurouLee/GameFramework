--[[------------------------------------------------------------------------------------------
    GuideSpotComponent : 
]]--------------------------------------------------------------------------------------------

---@class GuideSpotComponent: Object
_class( "GuideSpotComponent", Object )

function GuideSpotComponent:Constructor()

end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function GuideSpotComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function GuideSpotComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return GuideSpotComponent
function Entity:GuideSpot()
    return self:GetComponent(self.WEComponentsEnum.GuideSpot)
end


function Entity:HasGuideSpot()
    return self:HasComponent(self.WEComponentsEnum.GuideSpot)
end


function Entity:AddGuideSpot()
    local index = self.WEComponentsEnum.GuideSpot;
    local component = GuideSpotComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplaceGuideSpot()
    local index = self.WEComponentsEnum.GuideSpot;
    local component = GuideSpotComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemoveGuideSpot()
    if self:HasGuideSpot() then
        self:RemoveComponent(self.WEComponentsEnum.GuideSpot)
    end
end