--[[-------------------------------------
    ActionIsTrapNextRoundPlaySkillWithParam 下一回合是否施法
--]] -------------------------------------
require "ai_node_new"

---@class ActionIsTrapNextRoundPlaySkillWithParam : AINewNode
_class("ActionIsTrapNextRoundPlaySkillWithParam", AINewNode)
ActionIsTrapNextRoundPlaySkillWithParam = ActionIsTrapNextRoundPlaySkillWithParam

function ActionIsTrapNextRoundPlaySkillWithParam:OnUpdate(dt)
    local attrCmpt = self.m_entityOwn:Attributes()

    --是否使用总的战斗回合数，默认0使用AI自己的回合
    local useGameRound = self:GetLogicData(-2) or 0
    local curRound = attrCmpt:GetAttribute("CurrentRound")
    if useGameRound > 0 then
        curRound = self:GetGameRountNow() % useGameRound
        if curRound == 0 then
            curRound = useGameRound
        end
    end

    local str = self:GetLogicData(-1)
    if str then
        local ss = string.split(str, ",")
        local rounds = {}
        for i, s in ipairs(ss) do
            rounds[#rounds + 1] = tonumber(s)
        end

        if table.intable(rounds, curRound) then
            return AINewNodeStatus.Success
        end
    else
        local totalRound = attrCmpt:GetAttribute("TotalRound")
        if totalRound == curRound then
            return AINewNodeStatus.Success
        end
    end

    return AINewNodeStatus.Failure
end
