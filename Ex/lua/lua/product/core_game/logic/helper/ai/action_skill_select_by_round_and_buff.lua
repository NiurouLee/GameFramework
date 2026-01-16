--[[------------------------------------------------
    ActionSkillSelectByRoundAndBuff 根据回合数选择技能 配置的是技能组id 技能组配置在monster cfg中
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionSkillSelectByRoundAndBuff:AINewNode
_class("ActionSkillSelectByRoundAndBuff", AINewNode)
ActionSkillSelectByRoundAndBuff = ActionSkillSelectByRoundAndBuff

function ActionSkillSelectByRoundAndBuff:Constructor()
    self._skillListIndex = 1
    self._skillID = 0
    self.m_nDefaultSkillIndex = 0
    self.m_nSkillListCount = 0
end

---@param cfg table
---@param context CustomNodeContext
function ActionSkillSelectByRoundAndBuff:InitializeNode(cfg, context, parentNode, configData)
    ActionSkillSelectByRoundAndBuff.super.InitializeNode(self, cfg, context, parentNode, configData)
    self._skillListIndex = configData[1]
    self.m_nDefaultSkillIndex = configData[2]

    --检查buff的回合
    self._checkRound = configData[3]

    --检查的buff effect
    self._buffAttribute = configData[4]

    --检查的buff
    self._buffID = configData[5]
end
function ActionSkillSelectByRoundAndBuff:Update()
    local vecSkillLists = self:GetConfigSkillList()
    local skillList = vecSkillLists[self._skillListIndex]
    if skillList then
        local nGameRound = self:GetGameRountNow()
        local nSaveRound = self:GetRuntimeData("GameRound")
        if nil == nSaveRound or nSaveRound ~= nGameRound then
            local roundCount = self:GetRuntimeData("NextRoundCount") or self.m_nDefaultSkillIndex or 1
            self._skillID = skillList[roundCount]

            if roundCount == self._checkRound and self._checkRound > 0 then
                local addRound = self.m_entityOwn:Attributes():GetAttribute(self._buffAttribute)
                if addRound then
                    addRound = addRound - 1
                end
                if addRound and addRound > 0 then
                    self._skillID = skillList[roundCount + addRound]
                end
            end

            if self._buffID > 0 then
                local buffCmp = self.m_entityOwn:BuffComponent()
                local buffInstance = buffCmp:GetBuffById(self._buffID)
                if not buffInstance then
                    self._skillID = skillList[roundCount + self._checkRound]
                end
            end

            self:PrintLog("按回合选技能<初次进入>，RoundCount = " ,roundCount ,", skillID = " ,self._skillID)
        else
            local roundCount = self:GetRuntimeData("NextRoundCount") or self.m_nDefaultSkillIndex or 1
            self:PrintLog("按回合选技能<多次进入>，RoundCount = " ,roundCount ,", skillID = " ,self._skillID)
        end
        ---如下代码不写在 InitializeNode 内是因为， InitializeNode 内还没有初始化 AIComponentNew
        if self.m_nSkillListCount <= 0 then
            self.m_nSkillListCount = table.count(skillList)
            if self.m_nSkillListCount > 0 then
                self:SetRuntimeData("SkillCount", self.m_nSkillListCount)
            end
        end
    end
    return AINewNodeStatus.Success
end

function ActionSkillSelectByRoundAndBuff:GetActionSkillID()
    return self._skillID
end
