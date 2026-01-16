--[[------------------------------------------------
    ActionSkillSingle 选择一个技能的Action
    ActionSkill = { Type = "ActionSkillSingle", Data = {1,1} }
    Data里就是要选择的技能下标：对应技能列表在cfg_monster.lua内SkillID列配置
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionSkillSingle:AINewNode
_class("ActionSkillSingle", AINewNode)
ActionSkillSingle = ActionSkillSingle

function ActionSkillSingle:Constructor()
    self.m_nWorkIndexX = 1
    self.m_nWorkIndexY = 1
    self.m_nWorkSkillID = 0
end

---@param cfg table
---@param context CustomNodeContext
function ActionSkillSingle:InitializeNode(cfg, context, parentNode, configData)
    ActionSkillSingle.super.InitializeNode(self, cfg, context, parentNode, configData)
    if configData then
        if type(configData) == "table" then
            self.m_nWorkIndexX = configData[1]
            self.m_nWorkIndexY = configData[2]
        else
            self.m_nWorkIndexX = configData or 1
            self.m_nWorkIndexY = 1
        end
    end
end
function ActionSkillSingle:Update()
    self.m_nWorkSkillID = self:GetConfigSkillID(self.m_nWorkIndexY)
    return AINewNodeStatus.Success
end

function ActionSkillSingle:GetActionSkillID()
    return self.m_nWorkSkillID
end

function ActionSkillSingle:GetConfigSkillID(nIndex)
    local vecSkillList = self:GetConfigSkillList()
    return vecSkillList[self.m_nWorkIndexX][nIndex]
end