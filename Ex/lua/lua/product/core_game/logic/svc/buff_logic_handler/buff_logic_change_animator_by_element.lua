--[[
    根据属性改变动画状态机
]]
_class("BuffLogicChangeAnimatorByElement", BuffLogicBase)
---@class BuffLogicChangeAnimatorByElement:BuffLogicBase
BuffLogicChangeAnimatorByElement = BuffLogicChangeAnimatorByElement

function BuffLogicChangeAnimatorByElement:Constructor(buffInstance, logicParam)
    self._animator = logicParam.animator
end

function BuffLogicChangeAnimatorByElement:DoLogic(notify)
    ---@type Entity
    local entity = self._buffInstance:Entity()

    -- if entity:Element() and entity:Element():GetPrimaryType() then
    local element = entity:Element():GetPrimaryType()
    -- end

    local changeAnimator = self._animator[element]

    Log.error(changeAnimator)

    entity:BuffComponent():SetBuffValue("ChangeAnimator", changeAnimator)
end
