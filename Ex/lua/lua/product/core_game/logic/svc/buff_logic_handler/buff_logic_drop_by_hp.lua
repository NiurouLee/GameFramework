--[[
    被击血量掉落资源
]]
--添加护盾buff
_class("BuffLogicDropByHP", BuffLogicBase)
---@class BuffLogicDropByHP:BuffLogicBase
BuffLogicDropByHP = BuffLogicDropByHP

function BuffLogicDropByHP:Constructor(buffInstance, logicParam)
	self._hitEffectID = logicParam.hitEffectID
	self._dropList = logicParam.dropList
end

function BuffLogicDropByHP:DoLogic()
	local e = self._buffInstance:Entity()
	e:BuffComponent():SetBuffValue("DropByHPEffectID", self._hitEffectID)
	e:BuffComponent():SetBuffValue("DropListByHP", self._dropList)
end