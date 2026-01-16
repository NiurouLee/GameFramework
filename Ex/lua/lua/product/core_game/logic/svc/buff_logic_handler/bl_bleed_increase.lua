_class("BuffLogicSetBleedIncrease", BuffLogicBase)
---@class BuffLogicSetBleedIncrease:BuffLogicBase
BuffLogicSetBleedIncrease = BuffLogicSetBleedIncrease

function BuffLogicSetBleedIncrease:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
end

function BuffLogicSetBleedIncrease:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("BleedIncrease", 1 + self._addValue)

end

--取消中毒伤害加成
_class("BuffLogicResetBleedIncrease", BuffLogicBase)
---@class BuffLogicResetBleedIncrease:BuffLogicBase
BuffLogicResetBleedIncrease = BuffLogicResetBleedIncrease

function BuffLogicResetBleedIncrease:Constructor(buffInstance, logicParam)
end

function BuffLogicResetBleedIncrease:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("BleedIncrease", 1)
end
