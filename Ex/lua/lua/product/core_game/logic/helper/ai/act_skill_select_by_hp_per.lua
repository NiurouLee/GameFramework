--[[-------------------------------------
    ActionSkillSelectedByHPPercent 根据血量百分比选择释放的技能
--]] -------------------------------------
require "action_cast_skill_base"
---@class ActionSkillSelectedByHPPercent : AINewNode
_class("ActionSkillSelectedByHPPercent", AINewNode)
ActionSkillSelectedByHPPercent = ActionSkillSelectedByHPPercent
----------------------------------------------------------------
function ActionSkillSelectedByHPPercent:Constructor()
end

function ActionSkillSelectedByHPPercent:OnUpdate()
    local e = self.m_entityOwn
    if e:MonsterID() then
        ---@type AttributesComponent
        local attrCmpt = e:Attributes()
        local max_hp = attrCmpt:CalcMaxHp()
        local cur_hp = attrCmpt:GetCurrentHP()
        local hpPercent = math.floor(cur_hp / max_hp * 100)
        local configHPPercent = self:GetLogicData(-1)
        self:PrintDebugLog("curHPPercent = ",hpPercent," ConfigHPPercent = ",configHPPercent)
        if hpPercent > configHPPercent then
            return AINewNodeStatus.Other + 2
        else
            return AINewNodeStatus.Other + 1
        end
    end
end
