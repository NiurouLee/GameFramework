--[[
    元素伤害免疫
]]
require "buff_logic_base"
_class("BuffLogicElementImmunity", BuffLogicBase)
---@class BuffLogicElementImmunity:BuffLogicBase
BuffLogicElementImmunity = BuffLogicElementImmunity

function BuffLogicElementImmunity:Constructor(buffInstance, logicParam)
    --免疫的元素列表
    self._element = logicParam.element
end

function BuffLogicElementImmunity:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()

    cpt:SetSimpleAttribute("BuffElementImmunity", self._element)
end

-------------------------------------------------------------------------------------------

--[[
    移除元素伤害免疫
]]
_class("BuffLogicRemoveElementImmunity", BuffLogicBase)
BuffLogicRemoveElementImmunity = BuffLogicRemoveElementImmunity

function BuffLogicRemoveElementImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveElementImmunity:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()

    cpt:RemoveSimpleAttribute("BuffElementImmunity")
end
