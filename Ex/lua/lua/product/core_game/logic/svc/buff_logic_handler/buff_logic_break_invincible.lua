--[[
    添加和去除 破除无敌
]]
--添加 破除无敌
_class("BuffLogicSetBreakInvincible", BuffLogicBase)
BuffLogicSetBreakInvincible = BuffLogicSetBreakInvincible

function BuffLogicSetBreakInvincible:Constructor(buffInstance, logicParam)
end

function BuffLogicSetBreakInvincible:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetFlag(BuffFlags.BreakInvincible)
end

--去除 破除无敌
_class("BuffLogicResetBreakInvincible", BuffLogicBase)
BuffLogicResetBreakInvincible = BuffLogicResetBreakInvincible

function BuffLogicResetBreakInvincible:Constructor(buffInstance, logicParam)
end

function BuffLogicResetBreakInvincible:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    e:BuffComponent():ResetFlag(BuffFlags.BreakInvincible)
end
