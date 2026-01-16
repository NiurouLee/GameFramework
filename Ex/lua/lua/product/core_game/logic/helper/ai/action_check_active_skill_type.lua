--[[-------------------------------------
    ActionCheckActiveSkillType 检查主动技类型是否匹配
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckActiveSkillType:AINewNode
_class("ActionCheckActiveSkillType", AINewNode)
ActionCheckActiveSkillType = ActionCheckActiveSkillType

function ActionCheckActiveSkillType:OnUpdate()
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local activeSkillID = activeSkillCmpt:GetActiveSkillID()

    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local skillTags = skillConfigData:GetSkillTag()
    -- if skillTags and table.count(skillTags) == 0 then
    --     return AINewNodeStatus.Success
    -- end

    ---@type AttributesComponent
    local attributeCmpt = self.m_entityOwn:Attributes()
    local checkActiveSkillType = attributeCmpt:GetAttribute("AntiActiveSkillType")
    if not checkActiveSkillType then
        return AINewNodeStatus.Success
    end

    for i, v in ipairs(checkActiveSkillType) do
        --如果是-1 则所有主动技都符合
        if v == -1 then
            return AINewNodeStatus.Success
        end
        if table.icontains(skillTags, v) then
            return AINewNodeStatus.Success
        end
    end

    return AINewNodeStatus.Failure
end
