--[[-------------------------------------
    ActionIsCrazy 判断AI上是否挂了狂暴组件 CrazyModeComponent
--]] -------------------------------------
require "ai_node_new"

---@class ActionIsCrazy:AINewNode
_class("ActionIsCrazy", AINewNode)
ActionIsCrazy = ActionIsCrazy

function ActionIsCrazy:OnUpdate()
    if self.m_entityOwn:HasCrazyMode() then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end

---@class ActionBeCrazy:AINewNode
_class("ActionBeCrazy", AINewNode)
ActionBeCrazy = ActionBeCrazy

function ActionBeCrazy:OnUpdate()
    self.m_entityOwn:ReplaceCrazyMode()
    return AINewNodeStatus.Success
end
