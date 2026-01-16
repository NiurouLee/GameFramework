--[[---------------------------------------------------------------
    ActionIsInSkillRange 检测目标是否在技能范围内
--]] ---------------------------------------------------------------
require "action_is_base"
---------------------------------------------------------------
_class("ActionIsInSkillRange", ActionIsBase)
---@class ActionIsInSkillRange:ActionIsBase
ActionIsInSkillRange = ActionIsInSkillRange

function ActionIsInSkillRange:Constructor()
end

function ActionIsInSkillRange:OnUpdate()
    if AINewNode.IsEntityDead(self.m_entityOwn) then
        return AINewNodeStatus.Failure
    end
    local entityCaster = self.m_entityOwn
    local aiComponent = entityCaster:AI()
    if nil == aiComponent then
        return AINewNodeStatus.Failure
    end
    local nSkillID = self:GetLogicData(1)
    local cSkillID = self:GetLogicData(-1)
    if cSkillID then
        nSkillID = cSkillID
    end

    local entityTarget = aiComponent:GetTargetEntity() ---这里是玩家
    local isTargetInSkillRange = false
    if nSkillID > 0 then
        isTargetInSkillRange = self:IsEntityInSkillRange(nSkillID, entityTarget)
    end
    local bSuccess = nSkillID > 0 and isTargetInSkillRange
    if bSuccess then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
