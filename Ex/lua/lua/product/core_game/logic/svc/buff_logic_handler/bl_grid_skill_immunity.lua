--[[
    不会被格子技能命中
]]
---@class BuffLogicGridSkillImmunity:BuffLogicBase
_class("BuffLogicGridSkillImmunity", BuffLogicBase)
BuffLogicGridSkillImmunity = BuffLogicGridSkillImmunity

function BuffLogicGridSkillImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicGridSkillImmunity:DoLogic(notify)
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:SetSimpleAttribute("BuffGridSkillImmunity", 1)
    return true
end

-------------------------------------------------------------------------------------------

--[[
    移除格子技能免疫
]]
---@class BuffLogicRemoveGridSkillImmunity:BuffLogicBase
_class("BuffLogicRemoveGridSkillImmunity", BuffLogicBase)
BuffLogicRemoveGridSkillImmunity = BuffLogicRemoveGridSkillImmunity

function BuffLogicRemoveGridSkillImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveGridSkillImmunity:DoLogic(notify)
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:RemoveSimpleAttribute("BuffGridSkillImmunity")
    return true
end
