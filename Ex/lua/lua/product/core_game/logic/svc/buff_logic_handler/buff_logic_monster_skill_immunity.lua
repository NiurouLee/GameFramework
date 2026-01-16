--[[
    技能免疫，只对怪物有效，免疫连锁技、主动技、被动技（出了普攻）伤害
]]
---@class BuffLogicMonsterSkillImmunity:BuffLogicBase
_class("BuffLogicMonsterSkillImmunity", BuffLogicBase)
BuffLogicMonsterSkillImmunity = BuffLogicMonsterSkillImmunity

function BuffLogicMonsterSkillImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicMonsterSkillImmunity:DoLogic(notify)
    if not self._buffInstance:Entity():HasMonsterID() then
        Log.fatal("只能给怪挂技能免疫buff!")
        return true
    end
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:SetSimpleAttribute("BuffMonsterSkillImmunity", 1)
    return true
end

-------------------------------------------------------------------------------------------

--[[
    移除技能免疫
]]
---@class BuffLogicRemoveMonsterSkillImmunity:BuffLogicBase
_class("BuffLogicRemoveMonsterSkillImmunity", BuffLogicBase)
BuffLogicRemoveMonsterSkillImmunity = BuffLogicRemoveMonsterSkillImmunity

function BuffLogicRemoveMonsterSkillImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveMonsterSkillImmunity:DoLogic(notify)
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:RemoveSimpleAttribute("BuffMonsterSkillImmunity")
    return true
end
