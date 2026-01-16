--[[
    锁血后释放一个技能在View里面
]]
require("buff_logic_base")
_class("BuffLogicHPLock", BuffLogicBase)
BuffLogicHPLock = BuffLogicHPLock

function BuffLogicHPLock:Constructor(buffInstance, logicParam)
end

---@param notify NTHPLock
function BuffLogicHPLock:DoLogic(notify)
    local result = BuffResultHPLock:New(notify:GetIndex())
    return result
end
