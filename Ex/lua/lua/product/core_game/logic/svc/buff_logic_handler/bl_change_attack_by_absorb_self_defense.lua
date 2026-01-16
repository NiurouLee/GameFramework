--[[
    吸收自身的防御力来提升自身攻击力
]]
require('buff_logic_base')
_class("BuffLogicChangeAttackByAbsorbTargetDefense", BuffLogicBase)
---@class BuffLogicChangeAttackByAbsorbTargetDefense:BuffLogicBase
BuffLogicChangeAttackByAbsorbTargetDefense = BuffLogicChangeAttackByAbsorbTargetDefense

function BuffLogicChangeAttackByAbsorbTargetDefense:Constructor(buffInstance, logicParam)
	self._absorbDefensePercent = logicParam.absorbDefensePercent
	self._changeAttackPercent = logicParam.changeAttackPercent
end

---@param notify NotifyAttackBase
function BuffLogicChangeAttackByAbsorbTargetDefense:DoLogic(notify)
	local notifyType =notify:GetNotifyType()

	---@type Entity
	local attacker = self._buffInstance:Entity()
	if not attacker then 
		return false
	end

	if not attacker:Attributes() then
		Log.fatal("ChangeAttackByAbsorbTargetDefense no attribute cmpt:",notifyType)
		return false
	end

	local defenseValue = attacker:Attributes():GetAttribute("Defense")
	local absorbValue = defenseValue * self._absorbDefensePercent

	---修改目标的防御力
	self._buffLogicService:ChangeBaseDefence(
		attacker,
		self:GetBuffSeq(),
		ModifyBaseDefenceType.DefenceConstantFix,
		absorbValue*-1
	)

	if attacker:HasTeam() then
		self:UpdateTeamDefenceLogic(attacker)
	elseif attacker:HasPet() then
		---@type PetComponent
		local cPet = attacker:Pet()
		local eTeam = cPet:GetOwnerTeamEntity()
		self:UpdateTeamDefenceLogic(eTeam)
	end

	Log.fatal("ChangeAttackByAbsorbTargetDefense,absorbValue:",absorbValue)
	local attackChangeValue = absorbValue * self._changeAttackPercent
	self._buffLogicService:ChangeBaseAttack(
			attacker,
			self:GetBuffSeq(),
			ModifyBaseAttackType.AttackConstantFix,
			attackChangeValue
	)
	Log.fatal("ChangeAttackByAbsorbTargetDefense,changeAttackValue:",attackChangeValue)
	return true

end
