--[[---------------------------------------------------------------
    ActionIsBase 检测自己位置是否是可以发起攻击的有效位置： 是否在攻击范围内、到目标位置是否有障碍物
--]] ---------------------------------------------------------------
require "ai_node_new"
---@class ActionIsBase : AINewNode
_class("ActionIsBase", AINewNode)
ActionIsBase = ActionIsBase


function ActionIsBase:OnUpdate()
    if AINewNode.IsEntityDead(self.m_entityOwn) then
        return AINewNodeStatus.Failure
    end
    return AINewNodeStatus.Failure
end

function ActionIsBase:_IsBodyInSkillRange(bodyArea, skillRange)
    for i = 1, #bodyArea do
        for j = 1, #skillRange do
            if bodyArea[i] == skillRange[j] then
                return true
            end
        end
    end
    return false
end
---@param entityTarget Entity
function ActionIsBase:_IsTargetInSkillRange(entityTarget, skillRange)
    ---角色死亡，直接返回
    if AINewNode.IsEntityDead(self.m_entityOwn) then
        return false
    end
    local targetPos = entityTarget:GridLocation().Position
    local bodyArea = entityTarget:GetCoverAreaList(targetPos)
    local bInSkillRange = self:_IsBodyInSkillRange(bodyArea, skillRange)
    return bInSkillRange
end

