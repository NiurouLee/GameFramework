--[[------------------------------------------------------------------------------------------
    DirectionAnimatorSystem_Render : 根据角色方向设置动作状态机参数
]] --------------------------------------------------------------------------------------------

---@class DirectionAnimatorSystem_Render: ReactiveSystem
_class("DirectionAnimatorSystem_Render", ReactiveSystem)
DirectionAnimatorSystem_Render=DirectionAnimatorSystem_Render


function DirectionAnimatorSystem_Render:Constructor(world)
    self.world = world
end

function DirectionAnimatorSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.GridLocation)
    local c = Collector:New({group}, {"Added"})
    return c
end

---@param entity Entity
function DirectionAnimatorSystem_Render:Filter(entity)
    return entity:HasGridLocation() and entity:HasAnimatorController() and
        entity:AnimatorController().AniNeedDirToBoolTable
end

function DirectionAnimatorSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        local e = entities[i]
        self:HandleEntity(e)
    end
end

---@param e Entity
function DirectionAnimatorSystem_Render:HandleEntity(e)
    local dir = e:GridLocation().Direction
    local boolTable = {}

    boolTable["left"] = dir.y == 0 and dir.x < 0
    boolTable["right"] = dir.y == 0 and dir.x > 0

    e:SetAnimatorControllerBools(boolTable)
end
