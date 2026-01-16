--[[
    设置连锁数
]]
---@class BuffLogicSetChainRate:BuffLogicBase
_class("BuffLogicSetChainRate", BuffLogicBase)
BuffLogicSetChainRate = BuffLogicSetChainRate

function BuffLogicSetChainRate:Constructor(buffInstance, logicParam)
    self._chainRate = logicParam.chainRate or 1 --连线数量倍数
end

function BuffLogicSetChainRate:DoLogic(notify)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type BuffComponent
    local buffCmpt = teamEntity:BuffComponent()
    buffCmpt:SetBuffValue("ChainRate", self._chainRate)
end
