--[[
    负面buff免疫，人和怪都可用
]]
_class("BuffLogicDebuffImmunity", BuffLogicBase)
BuffLogicDebuffImmunity = BuffLogicDebuffImmunity

function BuffLogicDebuffImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicDebuffImmunity:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()

    cpt:SetSimpleAttribute("DebuffImmunity", 1)
end

-------------------------------------------------------------------------------------------

--[[
    移除负面Buff免疫
]]
_class("BuffLogicRemoveDebuffImmunity", BuffLogicBase)
BuffLogicRemoveDebuffImmunity = BuffLogicRemoveDebuffImmunity

function BuffLogicRemoveDebuffImmunity:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveDebuffImmunity:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()

    cpt:RemoveSimpleAttribute("DebuffImmunity")
end
