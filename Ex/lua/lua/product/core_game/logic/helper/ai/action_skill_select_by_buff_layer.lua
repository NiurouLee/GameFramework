--[[------------------------------------------------
    ActionSkillSelectByBuffLayer 根据buff层数选择技能。注意：每次都算一遍，AI执行的时候根据当前层数算，玩家预览也根据当前再算一次
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionSkillSelectByBuffLayer:AINewNode
_class("ActionSkillSelectByBuffLayer", AINewNode)
ActionSkillSelectByBuffLayer = ActionSkillSelectByBuffLayer

function ActionSkillSelectByBuffLayer:Constructor()
    self._skillID = 0
end

---@param cfg table
---@param context CustomNodeContext
function ActionSkillSelectByBuffLayer:InitializeNode(cfg, context, parentNode, configData)
    ActionSkillSelectByBuffLayer.super.InitializeNode(self, cfg, context, parentNode, configData)

    --默认 符合判断  Success使用的是 [1][1]的技能
    self._successSkillListIndex = 1

    --默认 不符判断  Failure使用的是 [2][1]的技能
    self._failureSkillListIndex = 2
    self.m_nDefaultSkillIndex = 1

    --检查的buff
    self._buffID = configData[1]
    --比较的类型和参数
    self._comparisonType = configData[2]
    self._comparisonParam = configData[3]
end
function ActionSkillSelectByBuffLayer:Update()
    self:_CakcSkillID()

    return AINewNodeStatus.Success
end

function ActionSkillSelectByBuffLayer:GetActionSkillID()
    self:_CakcSkillID()

    return self._skillID
end

function ActionSkillSelectByBuffLayer:_CakcSkillID()
    local vecSkillLists = self:GetConfigSkillList()
    local selectSkill

    local buffCmp = self.m_entityOwn:BuffComponent()
    local buffInstance = buffCmp:GetBuffById(self._buffID)
    if buffInstance then
        local layer = buffInstance:GetLayerCount()
        local satisfied = false
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
            selectSkill = vecSkillLists[self._successSkillListIndex][self.m_nDefaultSkillIndex]
        end
    end

    if selectSkill then
        self._skillID = selectSkill
    else
        self._skillID = vecSkillLists[self._failureSkillListIndex][self.m_nDefaultSkillIndex]
    end
end
