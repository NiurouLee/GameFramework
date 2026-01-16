--[[-------------------------------------
    ActionCheckWaitActiveSkillCount 检查当前光灵已施放主动技的次数
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckWaitActiveSkillCount:AINewNode
_class("ActionCheckWaitActiveSkillCount", AINewNode)
ActionCheckWaitActiveSkillCount = ActionCheckWaitActiveSkillCount

function ActionCheckWaitActiveSkillCount:OnUpdate()
    --剩余光灵技能释放技能次数,如果配置了,需要怪物当前属性小于等于这个值才可以反制。如果没配是1就是通用规则到1才可以释放
    local target = self:GetLogicData(-1) or 1

    ---@type AttributesComponent
    local attributeCmpt = self.m_entityOwn:Attributes()
    --没有配置反制参数的 默认为1 可以释放
    local curValue = attributeCmpt:GetAttribute("WaitActiveSkillCount") or 1

    if curValue <= target then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
