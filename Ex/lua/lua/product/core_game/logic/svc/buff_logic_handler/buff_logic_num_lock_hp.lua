--[[
    整数锁血
]]
_class("BuffLogicNumLockHP", BuffLogicBase)
---@class BuffLogicNumLockHP:BuffLogicBase
BuffLogicNumLockHP = BuffLogicNumLockHP

function BuffLogicNumLockHP:Constructor(buffInstance, logicParam)
    self._num = logicParam.num
end

function BuffLogicNumLockHP:DoLogic()
    local e = self._buffInstance:Entity()

    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()
    buffCmpt:SetBuffValue("NumLockHP", self._num)

    local buffResult = BuffResultNumLockHP:New(e:GetID(), self._num)
    return buffResult
end
