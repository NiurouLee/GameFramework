--[[-------------------------------------
    ActionIsHPLessThan 判断宿主血量
--]] -------------------------------------
require "ai_node_new"

---@class ActionIsHPLessThan:AINewNode
_class("ActionIsHPLessThan", AINewNode)
ActionIsHPLessThan = ActionIsHPLessThan

function ActionIsHPLessThan:OnUpdate()
    local hp = self.m_entityOwn:Attributes():GetCurrentHP()
    local hpMax = self.m_entityOwn:Attributes():GetAttribute("MaxHP")
    local percent = self:GetLogicData(-1)
    if hp / hpMax < percent then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
