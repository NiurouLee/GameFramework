--[[
    添加和去除无敌
]]
--添加无敌
_class("BuffLogicSetInvincible", BuffLogicBase)
BuffLogicSetInvincible = BuffLogicSetInvincible

function BuffLogicSetInvincible:Constructor(buffInstance, logicParam)
    self._layerNum = logicParam.layerNum --层数
end

function BuffLogicSetInvincible:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetFlag(BuffFlags.Invincible)
end

--去除无敌
_class("BuffLogicResetInvincible", BuffLogicBase)
BuffLogicResetInvincible = BuffLogicResetInvincible

function BuffLogicResetInvincible:Constructor(buffInstance, logicParam)
    self._layerNum = logicParam.layerNum --层数
end

function BuffLogicResetInvincible:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():ResetFlag(BuffFlags.Invincible)
end
