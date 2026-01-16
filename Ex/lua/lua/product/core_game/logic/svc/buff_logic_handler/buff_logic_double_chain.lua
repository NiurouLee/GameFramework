--[[
    二次连锁技 TODO 改成entity的attribute
]]
--设置
_class("BuffLogicSetDoubleChain", BuffLogicBase)
BuffLogicSetDoubleChain = BuffLogicSetDoubleChain

function BuffLogicSetDoubleChain:Constructor(buffInstance, logicParam)
    self._chainSkillCount = logicParam.chainSkillCount
    self._rate = logicParam.rate
end

function BuffLogicSetDoubleChain:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("ChainSkillCount", self._chainSkillCount)
    e:BuffComponent():SetBuffValue("DoubleChainRate", self._rate)
end

--重置
_class("BuffLogicResetDoubleChain", BuffLogicBase)
BuffLogicResetDoubleChain = BuffLogicResetDoubleChain

function BuffLogicResetDoubleChain:Constructor(buffInstance, logicParam)
    self._chainSkillCount = logicParam.chainSkillCount
end

function BuffLogicResetDoubleChain:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("ChainSkillCount", 1)
    e:BuffComponent():SetBuffValue("DoubleChainRate", 1)
end
