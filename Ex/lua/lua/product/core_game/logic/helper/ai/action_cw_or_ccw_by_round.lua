--[[-------------------------------------
    ActionCWOrCCWByRound 根据回合数判断顺时针还是逆时针旋转
--]] -------------------------------------
require "ai_node_new"

---@class ActionCWOrCCWByRound : AINewNode
_class("ActionCWOrCCWByRound", AINewNode)
ActionCWOrCCWByRound = ActionCWOrCCWByRound

function ActionCWOrCCWByRound:OnUpdate()
    local attrCmpt = self.m_entityOwn:Attributes()
    local totalRound = attrCmpt:GetAttribute("TotalRound")
    local nGameRound = self:GetGameRountNow() --当前回合数
    if nGameRound % totalRound == 0 then
        if (nGameRound / totalRound) % 2 == 0 then
            return AINewNodeStatus.Success
        else
            return AINewNodeStatus.Failure
        end
    end
    return AINewNodeStatus.Other + 1
end
