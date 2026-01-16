--[[-------------------------------------
    ActionMatchMonster 判断当前是那个怪物
--]] -------------------------------------
require "action_move_base"
---@class ActionMatchMonster:AINewNode
_class("ActionMatchMonster", AINewNode)
ActionMatchMonster = ActionMatchMonster

--------------------------------
function ActionMatchMonster:Constructor()
end
function ActionMatchMonster:Reset()
    ActionMatchMonster.super.Reset(self)
end
function ActionMatchMonster:OnUpdate(dt)
    local monsterID = self.m_entityOwn:MonsterID():GetMonsterID()

    local monsterClassID = Cfg.cfg_monster[monsterID].ClassID

    -- local skillIndexX, skillIndexY = self:GetLogicData(-1), self:GetLogicData(-2)
    -- local targetMonsterClassID = self:GetConfigSkillID(skillIndexX, skillIndexY)

    local targetMonsterClassID = self:GetLogicData(-1)

    if monsterClassID == targetMonsterClassID then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
