--[[
    增加怪物中毒 队长回血
]]
--设置怪物中毒 队长回血
_class("BuffLogicSetPoisonVampire", BuffLogicBase)
---@class BuffLogicSetPoisonVampire:BuffLogicBase
BuffLogicSetPoisonVampire = BuffLogicSetPoisonVampire

function BuffLogicSetPoisonVampire:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
end

function BuffLogicSetPoisonVampire:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("PoisonVampire", self._mulValue)
end

--取消怪物中毒 队长回血
_class("BuffLogicResetPoisonVampire", BuffLogicBase)
---@class BuffLogicResetPoisonVampire:BuffLogicBase
BuffLogicResetPoisonVampire = BuffLogicResetPoisonVampire

function BuffLogicResetPoisonVampire:Constructor(buffInstance, logicParam)
end

function BuffLogicResetPoisonVampire:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("PoisonVampire", 0)
end
