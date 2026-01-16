--[[-------------------------------------
    ActionCheckAntiSkillCountPerRound 检查每回合当前剩余反制AI次数
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckAntiSkillCountPerRound:AINewNode
_class("ActionCheckAntiSkillCountPerRound", AINewNode)
ActionCheckAntiSkillCountPerRound = ActionCheckAntiSkillCountPerRound

function ActionCheckAntiSkillCountPerRound:OnUpdate()
    ---@type AttributesComponent
    local attributeCmpt = self.m_entityOwn:Attributes()
    local curValue = attributeCmpt:GetAttribute("MaxAntiSkillCountPerRound") or 1

    if curValue >= 1 then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
