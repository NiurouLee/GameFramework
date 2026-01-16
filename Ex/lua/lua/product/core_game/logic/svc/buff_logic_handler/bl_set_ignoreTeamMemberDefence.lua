--[[
    修改参数使宿主计算伤害时忽略目标队伍中队员的防御力
]]
require "buff_logic_base"
_class("BuffLogicSetIgnoreTeamMemberDefence", BuffLogicBase)
---@class BuffLogicSetIgnoreTeamMemberDefence:BuffLogicBase
BuffLogicSetIgnoreTeamMemberDefence = BuffLogicSetIgnoreTeamMemberDefence

function BuffLogicSetIgnoreTeamMemberDefence:Constructor(buffInstance, logicParam)
	self._defPercent = tonumber(logicParam.defPercent) or 1
end

function BuffLogicSetIgnoreTeamMemberDefence:DoLogic()
	local petEntity = self._buffInstance:Entity()
	----@type AttributesComponent
	local attributeCmpt = petEntity:Attributes()
	attributeCmpt:SetSimpleAttribute("IgnoreTeamMemberDefence", self._defPercent)
end

function BuffLogicSetIgnoreTeamMemberDefence:DoOverlap(logicParam)
	local newParam = tonumber(logicParam.defPercent) or 1
	self._defPercent = self._defPercent + newParam
end

_class("BuffLogicResetIgnoreTeamMemberDefence", BuffLogicBase)
---@class BuffLogicResetIgnoreTeamMemberDefence:BuffLogicBase
BuffLogicResetIgnoreTeamMemberDefence = BuffLogicResetIgnoreTeamMemberDefence

function BuffLogicResetIgnoreTeamMemberDefence:Constructor(buffInstance, logicParam)

end

function BuffLogicResetIgnoreTeamMemberDefence:DoLogic()
	local petEntity = self._buffInstance:Entity()
	----@type AttributesComponent
	local attributeCmpt = petEntity:Attributes()
	attributeCmpt:SetSimpleAttribute("IgnoreTeamMemberDefence",0)
end