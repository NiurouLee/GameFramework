--[[------------------------------------------------------------------------------------------
    GuideLinkLineComponent : 
]]--------------------------------------------------------------------------------------------

---@class GuideLinkLineComponent: Object
_class( "GuideLinkLineComponent", Object )

function GuideLinkLineComponent:Constructor()

end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function GuideLinkLineComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function GuideLinkLineComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return GuideLinkLineComponent
function Entity:GuideLinkLine()
    return self:GetComponent(self.WEComponentsEnum.GuideLinkLine)
end


function Entity:HasGuideLinkLine()
    return self:HasComponent(self.WEComponentsEnum.GuideLinkLine)
end


function Entity:AddGuideLinkLine()
    local index = self.WEComponentsEnum.GuideLinkLine;
    local component = GuideLinkLineComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplaceGuideLinkLine()
    local index = self.WEComponentsEnum.GuideLinkLine;
    local component = GuideLinkLineComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemoveGuideLinkLine()
    if self:HasGuideLinkLine() then
        self:RemoveComponent(self.WEComponentsEnum.GuideLinkLine)
    end
end