--[[
    修改参数使宿主计算伤害时不考虑目标的防御力
]]
require "buff_logic_base"
_class("BuffLogicSetNoDefence", BuffLogicBase)
---@class BuffLogicSetNoDefence:BuffLogicBase
BuffLogicSetNoDefence = BuffLogicSetNoDefence

function BuffLogicSetNoDefence:Constructor(buffInstance, logicParam)
	self._defPercent = tonumber(logicParam.defPercent) or 1
end

function BuffLogicSetNoDefence:DoLogic()
	local petEntity = self._buffInstance:Entity()
	----@type AttributesComponent
	local attributeCmpt = petEntity:Attributes()
	attributeCmpt:SetSimpleAttribute("NoDefence", self._defPercent)
end

function BuffLogicSetNoDefence:DoOverlap(logicParam)
	local newParam = tonumber(logicParam.defPercent) or 1
	self._defPercent = self._defPercent + newParam
end

_class("BuffLogicResetNoDefence", BuffLogicBase)
---@class BuffLogicResetNoDefence:BuffLogicBase
BuffLogicResetNoDefence = BuffLogicResetNoDefence

function BuffLogicResetNoDefence:Constructor(buffInstance, logicParam)

end

function BuffLogicResetNoDefence:DoLogic()
	local petEntity = self._buffInstance:Entity()
	----@type AttributesComponent
	local attributeCmpt = petEntity:Attributes()
	attributeCmpt:SetSimpleAttribute("NoDefence",0)
end