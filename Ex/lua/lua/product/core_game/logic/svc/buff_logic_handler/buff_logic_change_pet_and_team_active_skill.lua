--[[
    改变星灵主动技能
]]
_class("BuffLogicChangePetAndTeamActiveSkill", BuffLogicBase)
---@class BuffLogicChangePetAndTeamActiveSkill:BuffLogicBase
BuffLogicChangePetAndTeamActiveSkill = BuffLogicChangePetAndTeamActiveSkill

---
function BuffLogicChangePetAndTeamActiveSkill:Constructor(buffInstance, logicParam)
    self._skillID = logicParam.skillID
end

---
function BuffLogicChangePetAndTeamActiveSkill:DoLogic()
    ---@type SkillInfoComponent
    local skillInfoComponent = self._entity:SkillInfo()
    skillInfoComponent:SetActiveSkillID(self._skillID)

    local teamEntity = self._entity:Pet():GetOwnerTeamEntity()
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    activeSkillCmpt:SetActiveSkillID(self._skillID, self._entity:GetID())

    --将计算结果设置到result中
    local petPstID = self._entity:PetPstID():GetPstID()
    local buffResult = BuffResultChangePetAndTeamActiveSkill:New(petPstID, self._skillID)
    return buffResult
end
