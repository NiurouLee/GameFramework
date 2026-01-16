--[[------------------------------------------------
    ActionSingleTrigger 选择一个技能的Action
    ActionSkill = { Type = "ActionSingleTrigger", Data = {1,1} }
    Data里就是要选择的技能下标：对应技能列表在cfg_ai.lua内 SkillList 列配置
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionSingleTrigger:AINewNode
_class("ActionSingleTrigger", AINewNode)
ActionSingleTrigger = ActionSingleTrigger

function ActionSingleTrigger:Constructor()
    self.m_nWorkIndexX = 1
    self.m_nWorkSkillID = 0
end

---@param cfg table
---@param context CustomNodeContext
function ActionSingleTrigger:InitializeNode(cfg, context, parentNode, configData)
    ActionSingleTrigger.super.InitializeNode(self, cfg, context, parentNode, configData)
    if configData then
        if type(configData) == "table" then
            self.m_nWorkIndexX = configData[1]
        else
            self.m_nWorkIndexX = configData or 1
        end
    end
end

function ActionSingleTrigger:Update()
    self.m_nWorkSkillID = self:_GetConfigSkillID()
    return AINewNodeStatus.Success
end

function ActionSingleTrigger:GetActionSkillID()
    --麻痹固定返回普攻【策划改成无攻击了】
    if self.m_entityOwn:BuffComponent():HasBuffEffect(BuffEffectType.Benumb) then
        --return self:GetNormalSkillID() or 0
        return 0
    end
    return self.m_nWorkSkillID
end

function ActionSingleTrigger:_GetConfigSkillID()
    local vecSkillList = self:GetConfigSkillList()
    if vecSkillList then
        return vecSkillList[self.m_nWorkIndexX]
    end
end
