--[[-------------------------------------------
    ActionSetMobility 设置行动力
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionSetMobility : AINewNode
_class("ActionSetMobility", AINewNode)
ActionSetMobility = ActionSetMobility

function ActionSetMobility:OnBegin()
    local mobility = self:GetLogicData(-1)

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    aiCmpt:SetMobilityTotal(mobility)
end
----------------------------------------------------------------
