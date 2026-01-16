--[[------------------------------------------------

--]] ------------------------------------------------
require "ai_node_new"
---@class ActionSkillSelectByBuffLayerCount:ActionCastSkillBase
_class("ActionSkillSelectByBuffLayerCount", ActionCastSkillBase)
ActionSkillSelectByBuffLayerCount = ActionSkillSelectByBuffLayerCount

function ActionSkillSelectByBuffLayerCount:Constructor()
end

function ActionSkillSelectByBuffLayerCount:GetWorkSkillID()
    --默认
    local skillID = self:GetLogicData(1)
    --
    self._skillListIndex = self:GetLogicData(-1)
    --检查的buff
    self._buffID = self:GetLogicData(-2)

    local vecSkillLists = self:GetConfigSkillList()
    local skillList = vecSkillLists[self._skillListIndex]
    local skillListCount = table.count(skillList)

    local buffCmp = self.m_entityOwn:BuffComponent()

    for i = 1, skillListCount do
        local targetBuffID = self._buffID + i
        local buffInstance = buffCmp:GetBuffById(targetBuffID)
        if buffInstance and not buffInstance:IsUnload() then
            skillID = skillList[i]
            break
        end
    end

    return skillID
end
