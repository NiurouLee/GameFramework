--[[-------------------------------------
    ActionCompareLayerCount 比较buff叠加层数
--]] -------------------------------------
require "ai_node_new"

---@class ActionCompareLayerCount:AINewNode
_class("ActionCompareLayerCount", AINewNode)
ActionCompareLayerCount = ActionCompareLayerCount

function ActionCompareLayerCount:OnUpdate()
    local buffID = self:GetLogicData(-1)
    local compareFlag = self:GetLogicData(-2) --比较操作枚举
    local count = self:GetLogicData(-3) --配置的层数

    local layerCount = 0

    local cBuff = self.m_entityOwn:BuffComponent()
    if cBuff then
        local instanbce = cBuff:GetBuffById(buffID)
        if instanbce then
            local layerName = instanbce:GetBuffLayerName()
            layerCount = cBuff:GetBuffValue(layerName) or 0
        end
    end

    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = layerCount == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = layerCount ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = layerCount > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = layerCount >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = layerCount < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = layerCount <= count
    end

    if satisfied then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
