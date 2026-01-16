--[[----------------------------------------------------------
    SkillRangeOutlineSystem_Render 显示技能区域
]] ------------------------------------------------------------
---@class SkillRangeOutlineSystem_Render:ReactiveSystem
_class("SkillRangeOutlineSystem_Render", ReactiveSystem)
SkillRangeOutlineSystem_Render = SkillRangeOutlineSystem_Render

---@param world World
function SkillRangeOutlineSystem_Render:Constructor(world)
    self.world = world
    ---@type TransformServiceRenderer
    self._tranRenderSvc = self.world:GetService("TransformRenderer")
end

---@param world World
function SkillRangeOutlineSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.SkillRangeOutline)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function SkillRangeOutlineSystem_Render:Filter(entity)
    return entity:HasView()
end

function SkillRangeOutlineSystem_Render:ExecuteEntities(entities)
    for _, e in pairs(entities) do
        self._tranRenderSvc:PlaySkillRangeAnim(e)
    end
end
