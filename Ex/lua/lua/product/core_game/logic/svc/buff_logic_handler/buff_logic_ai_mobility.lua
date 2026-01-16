--[[
    提升AI行动力
]]
_class("BuffLogicAddAIMobility", BuffLogicBase)
---@class BuffLogicAddAIMobility:BuffLogicBase
BuffLogicAddAIMobility = BuffLogicAddAIMobility

function BuffLogicAddAIMobility:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
    self._mulValue = logicParam.mulValue or 1
    self._runCount = 0
end

function BuffLogicAddAIMobility:DoLogic()
    self._runCount = self._runCount + 1
    ---@type Entity
    local e = self._buffInstance:Entity()
    if not e:HasMonsterID() then
        return
    end
    local mulVal = self._mulValue * self._runCount
    if mulVal ~= 1 then
        e:Attributes():Modify("Mobility", mulVal, self._buffInstance:BuffSeq(), MultModifyOperator.MULTIPLY)
    end
    local addVal = self._addValue * self._runCount
    if addVal ~= 0 then
        e:Attributes():Modify("Mobility", addVal, self._buffInstance:BuffSeq(), MultModifyOperator.PLUS)
    end
end

function BuffLogicAddAIMobility:DoOverlap()
    self:DoLogic()
end

_class("BuffLogicRemoveAIMobility", BuffLogicBase)
---@class BuffLogicRemoveAIMobility:BuffLogicBase
BuffLogicRemoveAIMobility = BuffLogicRemoveAIMobility

function BuffLogicRemoveAIMobility:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveAIMobility:DoLogic()
    local e = self._buffInstance:Entity()
    if not e:HasMonsterID() then
        return
    end
    e:Attributes():RemoveModify("Mobility", self._buffInstance:BuffSeq())
end
