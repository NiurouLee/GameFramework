--[[-------------------------------------------
    ActionAiBegin 启动AI：通过设置aiComponent内的行动力来启动本回合ai逻辑
--]] -------------------------------------------
require "ai_node_new"
---@class ActionAiBegin : AINewNode
_class("ActionAiBegin", AINewNode)
ActionAiBegin = ActionAiBegin

function ActionAiBegin:Constructor()
    self.m_bStartLogic = false
end

function ActionAiBegin:OnUpdate()
        ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()

    local posTarget = aiComponent:GetTargetPos()
    local posSelf = self:GetSelfPos()

    local stLogPosition = ", 自己坐标" .. GameHelper.MakePosString(posSelf)
    if posTarget then
        stLogPosition = stLogPosition .. "，目标坐标" .. GameHelper.MakePosString(posTarget)
    end
    local stBeginReason = ""
    local bEnableStart = false
    for i = 1, 1 do
        local nMobilityTotal = aiComponent:GetMobilityValid()
        if BattleConst.UseObsoleteAI then 
            if nMobilityTotal <= 0 then
                stBeginReason = "AI逻辑<禁止进入>, 行动力 = " .. nMobilityTotal
                break
            end
        end

        ---血量检查：自己
        local bMineDead = AINewNode.IsEntityDead(self.m_entityOwn)
        if bMineDead then
            stBeginReason = "AI逻辑<禁止进入>, 行动力 = " .. nMobilityTotal .. ", 自己挂了"
            break
        end
        ---血量检查：敌人
        local bPlayerDead = AINewNode.IsEntityDead(aiComponent:GetTargetEntity())
        if bPlayerDead then
            stBeginReason = "AI逻辑<禁止进入>, 行动力 = " .. nMobilityTotal .. ", 目标挂了"
            break
        end
        ---检查BUFF状态：晕倒
        ---@type BuffComponent
        local buffCmpt = self.m_entityOwn:BuffComponent()
        if buffCmpt then
            local isStun = buffCmpt:HasFlag(BuffFlags.SkipTurn)
            if isStun then
                stBeginReason = "AI逻辑<禁止进入>: Monster is stun 被击晕"
                break
            end
        end

        local isRoundEnd = aiComponent:IsAIRoundEnd()
        if isRoundEnd then 
            stBeginReason = "AI逻辑<回合已经结束>"
            break
        end

        stBeginReason = "AI逻辑<允许进入>, 行动力 = " .. nMobilityTotal
        bEnableStart = true
        break
    end
    self.m_bStartLogic = bEnableStart
    if aiComponent:CanMove() == false then
        aiComponent:SetMoveState(AIMoveState.MoveEnd)
    end

    self:PrintLog(stBeginReason, stLogPosition)
    self:PrintDebugLog(stBeginReason, stLogPosition)
    if self.m_bStartLogic then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
