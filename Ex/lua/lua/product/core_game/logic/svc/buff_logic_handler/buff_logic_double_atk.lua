--[[
    两次普攻，目前只处理了怪
]]
_class("BuffLogicDoubleAtk", BuffLogicBase)
BuffLogicDoubleAtk = BuffLogicDoubleAtk

function BuffLogicDoubleAtk:Constructor(buffInstance, logicParam)
end

function BuffLogicDoubleAtk:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()

    if not self._buffInstance:Entity():HasMonsterID() then
        Log.fatal("给非怪物加两次攻击Buff，这种情况在逻辑中并未处理")
    end

    cpt:SetSimpleAttribute("DoubleAtk", 1)
end

---------------------------------------------------------------------

--[[
    移除两次普攻
]]
_class("BuffLogicRemoveDoubleAtk", BuffLogicBase)
BuffLogicRemoveDoubleAtk = BuffLogicRemoveDoubleAtk

function BuffLogicRemoveDoubleAtk:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveDoubleAtk:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:RemoveSimpleAttribute("DoubleAtk")
end
