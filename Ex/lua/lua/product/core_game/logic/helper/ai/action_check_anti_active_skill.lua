--[[-------------------------------------
    ActionCheckAntiActiveSkill 检查是否可以释放反制主动技
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckAntiActiveSkill:AINewNode
_class("ActionCheckAntiActiveSkill", AINewNode)
ActionCheckAntiActiveSkill = ActionCheckAntiActiveSkill

function ActionCheckAntiActiveSkill:OnUpdate()
    ---@type AttributesComponent
    local attributeCmpt = self.m_entityOwn:Attributes()

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    aiCmpt:SetAntiSkill(false)

    --反制是否激活，默认1激活
    local antiSkillEnabled = attributeCmpt:GetAttribute("AntiSkillEnabled")
    if antiSkillEnabled == 0 then
        return AINewNodeStatus.Failure
    end

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local activeSkillID = activeSkillCmpt:GetActiveSkillID()
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local skillTags = skillConfigData:GetSkillTag()

    local checkActiveSkillType = attributeCmpt:GetAttribute("AntiActiveSkillType")
    --有检查主动技类型就检查  没有就跳过
    if checkActiveSkillType then
        local hasTag = false
        for i, v in ipairs(checkActiveSkillType) do
            --如果是-1 则所有主动技都符合
            if v == -1 then
                hasTag = true
                break
            end

            if table.icontains(skillTags, v) then
                hasTag = true
                break
            end
        end
        if hasTag == false then
            return AINewNodeStatus.Failure
        end
    end

    --没有配置反制参数的 默认为1 可以释放
    local activeSkillCount = attributeCmpt:GetAttribute("WaitActiveSkillCount") or 1

    --成功以后赋值新的值，主要表现的就是漏斗1到0
    local newActiveSkillCount = activeSkillCount - 1
    if newActiveSkillCount < 0 then
        newActiveSkillCount = 0
    end
    attributeCmpt:Modify("WaitActiveSkillCount", newActiveSkillCount)

    --当前值不等于0不可释放，这个值是从高向低递减，从1到0后可以释放。
    if newActiveSkillCount ~= 0 then
        return AINewNodeStatus.Failure
    end

    --本回合剩余可以反制的次数
    local curRoundAntiCount = attributeCmpt:GetAttribute("MaxAntiSkillCountPerRound") or 1
    if curRoundAntiCount < 1 then
        return AINewNodeStatus.Failure
    end

    aiCmpt:SetAntiSkill(true)

    return AINewNodeStatus.Success
end
