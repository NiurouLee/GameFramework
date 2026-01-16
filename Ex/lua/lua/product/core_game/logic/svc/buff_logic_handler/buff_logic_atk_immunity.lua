--[[
    普攻免疫
]]
_class("BuffLogicAtkImmunity", BuffLogicBase)
BuffLogicAtkImmunity = BuffLogicAtkImmunity

function BuffLogicAtkImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicAtkImmunity:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:SetSimpleAttribute("BuffAtkImmunity", 1)
    return true
end

--[[
    移除普攻免疫
]]
_class("BuffLogicRemoveAtkImmunity", BuffLogicBase)
BuffLogicRemoveAtkImmunity = BuffLogicRemoveAtkImmunity

function BuffLogicRemoveAtkImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveAtkImmunity:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:RemoveSimpleAttribute("BuffAtkImmunity")
    return true
end
