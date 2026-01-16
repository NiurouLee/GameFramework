--[[
    层数叠加
]]
require "buff_logic_base"
_class("BuffLogicStopBuff", BuffLogicBase)
---@class BuffLogicStopBuff:BuffLogicBase
BuffLogicStopBuff = BuffLogicStopBuff

function BuffLogicStopBuff:Constructor(buffInstance, logicParam)

end

---@param notify NotifyAttackBase
function BuffLogicStopBuff:DoLogic()
	---@type BuffComponent
	local buffComponent = 	self._entity:BuffComponent()
	buffComponent:SetBuffValue("Freeze",1)
end


_class("BuffLogicResumeBuff", BuffLogicBase)
---@class BuffLogicResumeBuff:BuffLogicBase
BuffLogicResumeBuff = BuffLogicResumeBuff

function BuffLogicResumeBuff:Constructor(buffInstance, logicParam)

end

---@param notify NotifyAttackBase
function BuffLogicResumeBuff:DoLogic()
	---@type BuffComponent
	local buffComponent = 	self._entity:BuffComponent()
	buffComponent:SetBuffValue("Freeze",nil)
end
