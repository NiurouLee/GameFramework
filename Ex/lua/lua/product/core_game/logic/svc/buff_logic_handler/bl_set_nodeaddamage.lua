--[[
    免疫即死伤害
]]
require "buff_logic_base"
_class("BuffLogicSetNoDeadDamage", BuffLogicBase)
---@class BuffLogicSetNoDeadDamage:BuffLogicBase
BuffLogicSetNoDeadDamage = BuffLogicSetNoDeadDamage

function BuffLogicSetNoDeadDamage:Constructor(buffInstance, logicParam)
end

function BuffLogicSetNoDeadDamage:DoLogic()
    local entity = self._buffInstance:Entity()
    ----@type AttributesComponent
    local attributeCmpt = entity:Attributes()
    attributeCmpt:SetSimpleAttribute("NoDeadDamage", 1)
end

_class("BuffLogicResetNoDeadDamage", BuffLogicBase)
---@class BuffLogicResetNoDeadDamage:BuffLogicBase
BuffLogicResetNoDeadDamage = BuffLogicResetNoDeadDamage

function BuffLogicResetNoDeadDamage:Constructor(buffInstance, logicParam)

end

function BuffLogicResetNoDeadDamage:DoLogic()
    local entity = self._buffInstance:Entity()
    ----@type AttributesComponent
    local attributeCmpt = entity:Attributes()
    attributeCmpt:SetSimpleAttribute("NoDeadDamage",0)
end