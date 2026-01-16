--[[
    修改攻击防御 （增加的值是Buff提供者的攻击力或防御力的百分比）
]]

_class("BuffLogicChangeAtkDefByBuffSource", BuffLogicBase)
---@class BuffLogicChangeAtkDefByBuffSource:BuffLogicBase
BuffLogicChangeAtkDefByBuffSource = BuffLogicChangeAtkDefByBuffSource

function BuffLogicChangeAtkDefByBuffSource:Constructor(buffInstance, logicParam)
	self._percent = logicParam.percent or 0
	self._entity = buffInstance._entity
	self._type = logicParam.type
end

function BuffLogicChangeAtkDefByBuffSource:DoLogic()
	local sourceEntity = self:GetBuffSourceEntity()
	if sourceEntity  then
		local teamEntity=sourceEntity:Pet():GetOwnerTeamEntity()
		if self._type == ChangeAtkDefType.ChangeDefByAtk then
			local atk  = sourceEntity:Attributes():GetAttribute("Attack")
			local value = math.floor(atk*self._percent)
			self._buffLogicService:ChangeBaseDefence(sourceEntity,self._buffInstance:BuffSeq(),ModifyBaseDefenceType.DefenceConstantFix,value)
			self:UpdateTeamDefenceLogic(teamEntity)
		elseif self._type == ChangeAtkDefType.ChangeAtkByDef then
			local def = sourceEntity:Attributes():GetAttribute("Defense")
			local value = math.floor(def*self._percent)
			self._buffLogicService:ChangeBaseAttack(self._entity,self._buffInstance:BuffSeq(),ModifyBaseAttackType.AttackConstantFix,value)
		end
	end
end
---@class ChangeAtkDefType
---@field ChangeAtkByDef number
---@field ChangeDefByAtk number
local ChangeAtkDefType ={
	ChangeAtkByDef = 1,  ---通过防御力修改攻击力
	ChangeDefByAtk = 2,  ---通过攻击力修改防御力
}
_enum("ChangeAtkDefType",ChangeAtkDefType)

_class("BuffLogicRemoveChangeAtkDefByBuffSource", BuffLogicBase)
---@class BuffLogicRemoveChangeAtkDefByBuffSource:BuffLogicBase
BuffLogicRemoveChangeAtkDefByBuffSource = BuffLogicRemoveChangeAtkDefByBuffSource

function BuffLogicRemoveChangeAtkDefByBuffSource:Constructor(buffInstance, logicParam)

end

function BuffLogicRemoveChangeAtkDefByBuffSource:DoLogic()
	local sourceEntity = self:GetBuffSourceEntity()
	if sourceEntity  then
		local teamEntity = sourceEntity:Pet():GetOwnerTeamEntity()
		self._buffLogicService:RemoveBaseDefence(sourceEntity,self._buffInstance:BuffSeq(),ModifyBaseDefenceType.DefenceConstantFix)
		self:UpdateTeamDefenceLogic(teamEntity)
		self._buffLogicService:RemoveBaseAttack(self._entity,self._buffInstance:BuffSeq(),ModifyBaseAttackType.AttackConstantFix)
	end
end