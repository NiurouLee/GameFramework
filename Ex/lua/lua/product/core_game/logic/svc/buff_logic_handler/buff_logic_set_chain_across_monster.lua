--[[
    普攻连线，光灵可以穿过怪物脚下
]]
_class("BuffLogicSetChainAcrossMonster", BuffLogicBase)
---@class BuffLogicSetChainAcrossMonster:BuffLogicBase
BuffLogicSetChainAcrossMonster = BuffLogicSetChainAcrossMonster

function BuffLogicSetChainAcrossMonster:Constructor(buffInstance, logicParam)
    self._remove = logicParam.remove or 0
    self._moveEffect = logicParam.moveEffect
end

function BuffLogicSetChainAcrossMonster:DoLogic()
    local e = self._buffInstance:Entity()

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = e:LogicChainPath()
    logicChainPathCmpt:SetChainAcrossMonster(self._remove == 0)

    local buffResult = BuffResultSetChainAcrossMonster:New(self._remove, self._moveEffect)
    return buffResult
end
