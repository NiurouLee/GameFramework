--[[------------------------------------------------------------------------------------------
    MonsterViewAddSystem_Render : 监听怪物表现变化
    这个System原来是做修改材质的，由于时序的问题，现已不进入world
]] --------------------------------------------------------------------------------------------

---@class MonsterViewAddSystem_Render:ReactiveSystem
_class("MonsterViewAddSystem_Render", ReactiveSystem)
MonsterViewAddSystem_Render = MonsterViewAddSystem_Render

function MonsterViewAddSystem_Render:Constructor(world)
    self._world = world
end

function MonsterViewAddSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.View)
    local c = Collector:New({group}, {"Added"})
    return c
end

---@param entity Entity
function MonsterViewAddSystem_Render:Filter(entity)
    if entity:HasGhost() or entity:HasGuideGhost() then 
        return false
    end
    return entity:HasMonsterID()
end

function MonsterViewAddSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:OnMonsterViewAdded(entities[i])
    end
end

function MonsterViewAddSystem_Render:OnMonsterViewAdded(monsterEntity)

end
