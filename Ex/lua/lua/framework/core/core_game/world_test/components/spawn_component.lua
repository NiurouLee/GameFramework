

---@class ISpawnRule:Object
_class( "ISpawnRule", Object )
function ISpawnRule:MakeSpawn(entity) end


---@class ISpawnRuleWitchManager:Object
_class( "ISpawnRuleWitchManager", Object )
function ISpawnRuleWitchManager:MakeSpawnByMng(entity) end

--[[------------------------------------------------------------------------------------------
    SpawnComponent : 
]]--------------------------------------------------------------------------------------------

---@class SpawnComponent:Object
_class( "SpawnComponent", Object )

function SpawnComponent:Constructor(spawnRule)
    self.SpawnRule = spawnRule
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return SpawnComponent
function Entity:Spawn()
    return self:GetComponent(self.WEComponentsEnum.Spawn)
end


function Entity:HasSpawn()
    return self:HasComponent(self.WEComponentsEnum.Spawn)
end


function Entity:AddSpawn(spawnRule)
    local index = self.WEComponentsEnum.Spawn;
    local component = SpawnComponent:New(spawnRule)
    self:AddComponent(index, component)
end


function Entity:ReplaceSpawn(spawnRule)
    local index = self.WEComponentsEnum.Spawn;
    local component = SpawnComponent:New(spawnRule)
    self:ReplaceComponent(index, component)
end


function Entity:RemoveSpawn()
    if self:HasSpawn() then
        self:RemoveComponent(self.WEComponentsEnum.Spawn)
    end
end