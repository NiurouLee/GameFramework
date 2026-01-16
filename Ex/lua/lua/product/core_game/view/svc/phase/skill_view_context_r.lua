---设计目标：单个技能表现的上下文，整个view过程可用，每个phase也可以使用
---由于现在还没有这个需求，所以这个跨phase的context暂时还用不上，等以后用的话，再传上去也好加
---@class SkillViewContext: Object
_class("SkillViewContext", Object)
SkillViewContext = SkillViewContext

function SkillViewContext:Constructor(world,casterEntity)
    ---@type MainWorld
    self._world = world

    ---@type Entity
    self._casterEntity = casterEntity
end