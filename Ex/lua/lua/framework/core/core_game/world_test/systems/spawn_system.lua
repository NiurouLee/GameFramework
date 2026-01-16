--[[------------------------------------------------------------------------------------------
    SpawnSystem : 
]]--------------------------------------------------------------------------------------------

---@class SpawnSystem:ReactiveSystem
_class( "SpawnSystem", ReactiveSystem )

---@param world BaseWorld
function SpawnSystem:Constructor(world)
    self.world = world
end

function SpawnSystem:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.Spawn)
    local c = Collector:New({ group }, {"Added"})
    return c
end

---@param entity Entity
function SpawnSystem:Filter(entity)
    return entity:HasSpawn()
end

function SpawnSystem:ExecuteEntities(entities)
    local world = self.world
    for i = 1, #entities do
        ---@type Entity
        local e = entities[i]
        local component = e:Spawn()
        local rule = component.SpawnRule
        rule:MakeSpawn(e, world)
        
        e:RemoveSpawn() --暂定Spawn是瞬态
    end
end

