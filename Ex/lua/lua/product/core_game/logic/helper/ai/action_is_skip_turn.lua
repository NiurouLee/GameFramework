--[[-------------------------------------
    ActionIsSkipTurn 是否跳过本回合
    2020-07-14 韩玉信
    支持眩晕Buff的跳过
--]] -------------------------------------
require "ai_node_new"

---@class ActionIsSkipTurn : AINewNode
_class("ActionIsSkipTurn", AINewNode)
ActionIsSkipTurn = ActionIsSkipTurn

function ActionIsSkipTurn:Constructor()
end

function ActionIsSkipTurn:OnUpdate(dt)
    local bSkipTurn = false
    ---检查BUFF状态：晕倒
    ---@type BuffComponent
    local buffCmpt = self.m_entityOwn:BuffComponent()
    if buffCmpt then
        bSkipTurn = buffCmpt:HasFlag(BuffFlags.SkipTurn)
    end

    if bSkipTurn then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
