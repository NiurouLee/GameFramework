--[[------------------------------------------------
    ActionCheckBuffLayer 根据buff层数和操作符返回true,false
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionCheckBuffLayer:AINewNode
_class("ActionCheckBuffLayer", AINewNode)
ActionCheckBuffLayer = ActionCheckBuffLayer


---@param cfg table
---@param context CustomNodeContext
function ActionCheckBuffLayer:InitializeNode(cfg, context, parentNode, configData)
    ActionCheckBuffLayer.super.InitializeNode(self, cfg, context, parentNode, configData)
    --检查的buff
    self._buffID = configData[1]
    --比较的类型和参数
    self._comparisonType = configData[2]
    self._comparisonParam = configData[3]
end
function ActionCheckBuffLayer:OnUpdate()
    local buffCmp = self.m_entityOwn:BuffComponent()
    local buffInstance = buffCmp:GetBuffById(self._buffID)
    if buffInstance then
        local satisfied
        local layer = buffInstance:GetLayerCount()
        if self._comparisonType == ComparisonOperator.EQ then --eq
            satisfied = layer == self._comparisonParam
        elseif self._comparisonType == ComparisonOperator.NE then --ne
            satisfied = layer ~= self._comparisonParam
        elseif self._comparisonType == ComparisonOperator.GT then --gt
            satisfied = layer > self._comparisonParam
        elseif self._comparisonType == ComparisonOperator.GE then --ge
            satisfied = layer >= self._comparisonParam
        elseif self._comparisonType == ComparisonOperator.LT then --lt
            satisfied = layer < self._comparisonParam
        elseif self._comparisonType == ComparisonOperator.LE then --le
            satisfied = layer <= self._comparisonParam
        end
        if satisfied then
            return AINewNodeStatus.Success
        else
            return AINewNodeStatus.Failure
        end
    end
    return AINewNodeStatus.Failure
end
