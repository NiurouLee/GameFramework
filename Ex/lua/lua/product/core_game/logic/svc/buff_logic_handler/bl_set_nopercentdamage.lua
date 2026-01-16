--[[
    免疫宝宝的百分比伤害
]]
require "buff_logic_base"
_class("BuffLogicSetNoPercentDamage", BuffLogicBase)
---@class BuffLogicSetNoPercentDamage:BuffLogicBase
BuffLogicSetNoPercentDamage = BuffLogicSetNoPercentDamage

function BuffLogicSetNoPercentDamage:Constructor(buffInstance, logicParam)

end

function BuffLogicSetNoPercentDamage:DoLogic()
    local entity = self._buffInstance:Entity()
    ----@type AttributesComponent
    local attributeCmpt = entity:Attributes()
    attributeCmpt:SetSimpleAttribute("NoPercentDamage", 1)
end

_class("BuffLogicResetNoPercentDamage", BuffLogicBase)
---@class BuffLogicResetNoPercentDamage:BuffLogicBase
BuffLogicResetNoPercentDamage = BuffLogicResetNoPercentDamage

function BuffLogicResetNoPercentDamage:Constructor(buffInstance, logicParam)

end

function BuffLogicResetNoPercentDamage:DoLogic()
    local entity = self._buffInstance:Entity()
    ----@type AttributesComponent
    local attributeCmpt = entity:Attributes()
    attributeCmpt:SetSimpleAttribute("NoPercentDamage",0)
end