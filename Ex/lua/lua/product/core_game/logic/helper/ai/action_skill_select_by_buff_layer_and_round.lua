--[[------------------------------------------------
    ActionSkillSelectByBuffLayerAndRound 
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionSkillSelectByBuffLayerAndRound:AINewNode
_class("ActionSkillSelectByBuffLayerAndRound", AINewNode)
ActionSkillSelectByBuffLayerAndRound = ActionSkillSelectByBuffLayerAndRound

function ActionSkillSelectByBuffLayerAndRound:Constructor()
    self._skillID = 0
end

---@param cfg table
---@param context CustomNodeContext
function ActionSkillSelectByBuffLayerAndRound:InitializeNode(cfg, context, parentNode, configData)
    ActionSkillSelectByBuffLayerAndRound.super.InitializeNode(self, cfg, context, parentNode, configData)

    --检查的buff
    self._buffID = configData[1]
    --比较的类型和参数
    self._comparisonType = configData[2]
    self._comparisonParam = configData[3]

    self._checkBuffHavereturn = configData[4] or 0 --对比成功/失败后返回第一阶段选择技能   默认0失败返回

    self._skillListIndex = configData[5] or 1 --
    self._skillIndex = configData[6] or 1

    self._secondSkillListIndex = configData[7] or 1 --
    self._roundCount = configData[8]
end
function ActionSkillSelectByBuffLayerAndRound:Update()
    local buffCmp = self.m_entityOwn:BuffComponent()
    local buffInstance = buffCmp:GetBuffById(self._buffID)

    local checkResult = false

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
            checkResult = true
        else
            checkResult = false
        end
    end

    local checkBuffMatch = false
    if checkResult == true and self._checkBuffHavereturn == 1 then
        checkBuffMatch = true
    elseif checkResult == false and self._checkBuffHavereturn == 0 then
        checkBuffMatch = true
    else
        checkBuffMatch = false
    end

    if checkBuffMatch then
        self._skillID = self:GetConfigSkillID(self._skillListIndex, self._skillIndex)
    else
        local vecSkillLists = self:GetConfigSkillList()
        local skillList = vecSkillLists[self._secondSkillListIndex]

        local skillCount = table.count(skillList)
        if self._roundCount then
            skillCount = self._roundCount
        end

        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        local levelTotalRoundCount = battleStatCmpt:GetLevelTotalRoundCount()
        -- local nextRoundCount = self:GetRuntimeData("GameRound") or 1
        local roundCount = levelTotalRoundCount % skillCount
        if roundCount == 0 then
            roundCount = skillCount
        end

        self._skillID = skillList[roundCount]
    end

    return AINewNodeStatus.Success
end

function ActionSkillSelectByBuffLayerAndRound:GetActionSkillID()
    return self._skillID
end
