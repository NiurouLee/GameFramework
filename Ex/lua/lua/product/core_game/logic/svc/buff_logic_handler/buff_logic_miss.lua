--[[
    设置攻击丢失
]]
_class("BuffLogicAddMiss", BuffLogicBase)
---@class BuffLogicAddMiss:BuffLogicBase
BuffLogicAddMiss = BuffLogicAddMiss

function BuffLogicAddMiss:Constructor(buffInstance, logicParam)
    self._miss = logicParam.miss
end

function BuffLogicAddMiss:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():AddBuffValue("Miss", self._miss)
end

--去除攻击丢失
_class("BuffLogicRemoveMiss", BuffLogicBase)
---@class BuffLogicRemoveMiss:BuffLogicBase
BuffLogicRemoveMiss = BuffLogicRemoveMiss

function BuffLogicRemoveMiss:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveMiss:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("Miss", 0)
end
