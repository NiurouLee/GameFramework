--[[-------------------------------------
    ActionCheckTrapRound 检查回合数
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckTrapRound : AINewNode
_class("ActionCheckTrapRound", AINewNode)
ActionCheckTrapRound = ActionCheckTrapRound

function ActionCheckTrapRound:OnUpdate(dt)
    local val = self:GetLogicData(-1)

    local allowMoreThanMax = self:GetLogicData(-2) == 1

    local attrCmpt = self.m_entityOwn:Attributes()
    local totalRound = attrCmpt:GetAttribute("TotalRound")
    local curRound = attrCmpt:GetAttribute("CurrentRound")

    if allowMoreThanMax then
        if totalRound <= curRound + val then
            return AINewNodeStatus.Success
        end
        return AINewNodeStatus.Failure
    else
        if totalRound == curRound + val then
            return AINewNodeStatus.Success
        end
        return AINewNodeStatus.Failure
    end
end
