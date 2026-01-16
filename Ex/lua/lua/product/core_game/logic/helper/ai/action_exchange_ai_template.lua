--[[-------------------------------------
    ActionExchangeAITemplate 更改AI模板
--]] -------------------------------------
require "action_cast_skill_base"

---@class ActionExchangeAITemplate : AINewNode
_class("ActionExchangeAITemplate", AINewNode)
ActionExchangeAITemplate = ActionExchangeAITemplate

function ActionExchangeAITemplate:OnBegin()
    ---@type Entity
    local entity = self.m_entityOwn
    local newAIID = self:GetLogicData(-1)
    local aiids = {newAIID}
    entity:ReplaceAI(AILogicPeriodType.Main, aiids)
end
