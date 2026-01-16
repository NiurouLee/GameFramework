--[[
    是否显示被动技能计数超载的表现
]]
---@class BuffLogicShowPassiveAccumulateOverload:BuffLogicBase
_class("BuffLogicShowPassiveAccumulateOverload", BuffLogicBase)
BuffLogicShowPassiveAccumulateOverload = BuffLogicShowPassiveAccumulateOverload

function BuffLogicShowPassiveAccumulateOverload:Constructor(buffInstance, logicParam)
    self._showOverload = logicParam.showOverload
end

function BuffLogicShowPassiveAccumulateOverload:DoLogic(notify)
    local buffResult = BuffResultShowPassiveAccumulateOverload:New(self._showOverload)
    return buffResult
end
