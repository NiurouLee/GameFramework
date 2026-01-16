--[[
    增加buff的CD计数，计数为0自动卸载
]]
require("buff_logic_base")
_class("BuffLogicAddBuffCD", BuffLogicBase)
BuffLogicAddBuffCD = BuffLogicAddBuffCD

function BuffLogicAddBuffCD:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 1
end

function BuffLogicAddBuffCD:DoLogic(notify)
    self._buffInstance:AddExecuteCount(notify, self._addValue)
end
