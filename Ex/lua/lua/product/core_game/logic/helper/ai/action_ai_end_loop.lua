--[[-------------------------------------------
    ActionAiEndLoop 结束AI：
    2019-11-01 韩玉信增加：跟据 aiComponent:m_nMobilityTotal 来判断终止，如果m_nMobilityTotal>0会重启逻辑
--]] -------------------------------------------
require "ai_node_new"
---@class ActionAiEndLoop : AINewNode
_class("ActionAiEndLoop", AINewNode)
ActionAiEndLoop = ActionAiEndLoop

function ActionAiEndLoop:Constructor()
end

function ActionAiEndLoop:Update()
    if  self:IsActive() then
        if self.Status == AINewNodeStatus.Ready then
            self:OnBegin()
            self.Status = AINewNodeStatus.Running
        end
        self.Status = self:OnUpdate()
        if self.Status ~= AINewNodeStatus.Running then
            self:OnEnd()
        end
    end
    return self.Status;
end

---@return AIComponentNew
function ActionAiEndLoop:_GetAiComponent()
    local aiComponent = nil
    if self.m_entityOwn then
        aiComponent = self.m_entityOwn:AI();
    end
    return aiComponent
end

function ActionAiEndLoop:OnBegin()
    local aiComponent = self:_GetAiComponent()
    if nil == aiComponent then
        self:PrintLog("AI逻辑<结束>，所属的Entity被销毁。" );
        return 
    end

    if BattleConst.UseObsoleteAI then 
        local logicData = self:GetLogicData(-1);
        local nEndForce = logicData or 0;
        if nEndForce > 0 then
            aiComponent:ClearMobilityTotal();
            self:PrintLog("AI逻辑<强制结束>" );
        end
    end
end

function ActionAiEndLoop:OnEnd()
    ---@type AIComponentNew
    local aiComponent = self:_GetAiComponent()
    if nil == aiComponent then
        return 
    end
    if AINewNode.IsEntityDead(self.m_entityOwn) then
        aiComponent:SetComponentStatus( AINewNodeStatus.Success );
        self:PrintLog("AI宿主死亡，清空行动力: AI逻辑<结束>" );
        self.Status = AINewNodeStatus.Success;

        if BattleConst.UseObsoleteAI then 
            aiComponent:ClearMobilityTotal();
        end
    else
        if BattleConst.UseObsoleteAI then 
            local nMobilityTotal = aiComponent:CostMobility(1);
            if nMobilityTotal > 0 then
                aiComponent:SetComponentStatus( AINewNodeStatus.Running );
                self:PrintLog("nMobilityTotal = " .. nMobilityTotal .. ": AI逻辑<重置>" );
                --重启AI循环
                self.Status = AINewNodeStatus.Failure;
            else
                aiComponent:SetComponentStatus( AINewNodeStatus.Success );
                self:PrintLog("nMobilityTotal = " .. nMobilityTotal .. ": AI逻辑<结束>" );
                self.Status = AINewNodeStatus.Success;

            end
        else
            local isRoundEnd = aiComponent:IsAIRoundEnd()
            if isRoundEnd then 
                self.Status = AINewNodeStatus.Success
            else
                self.Status = AINewNodeStatus.Failure
            end
        end
    end
end
