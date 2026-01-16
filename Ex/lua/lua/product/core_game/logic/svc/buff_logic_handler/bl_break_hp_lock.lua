--[[
    锁血破后释放一个技能在View里面
]]
require("buff_logic_base")
_class("BuffLogicBreakHPLock", BuffLogicBase)
BuffLogicBreakHPLock = BuffLogicBreakHPLock

function BuffLogicBreakHPLock:Constructor(buffInstance, logicParam)
end

function BuffLogicBreakHPLock:DoLogic(notify)
    return true
end
