--[[
    吸收被攻击目标的攻击力上限是施法者的攻击力
]]
require('buff_logic_base')
_class("BuffLogicAbsorbTargetAttack", BuffLogicBase)
---@class BuffLogicAbsorbTargetAttack:BuffLogicBase
BuffLogicAbsorbTargetAttack = BuffLogicAbsorbTargetAttack

function BuffLogicAbsorbTargetAttack:Constructor(buffInstance, logicParam)
	self._absorbAttackPercent = logicParam.absorbAttackPercent
	self._absorbAttackType = logicParam.absorbAttackType
	self._absorbValue =0
end

---@param notify NotifyAttackBase
function BuffLogicAbsorbTargetAttack:DoLogic(notify)
	local notifyType =notify:GetNotifyType()
	if table.icontains(self._absorbAttackType,notifyType) then
		local attacker = self._buffInstance:Entity()
		local defenderEntity = notify:GetDefenderEntity()

		if not attacker or not defenderEntity or not attacker:Attributes() or not defenderEntity:Attributes() then
			return false
		end
		---只吸怪
		if not defenderEntity:MonsterID() then
			return false
		end

		local baseAttackValue = attacker:Attributes():GetAttribute("Attack")
		if baseAttackValue <= self._absorbValue then
			--Log.fatal("AbsorbAttack Full")
			return false
		end
		local defenderAttackRealValue = self._buffLogicService:GetEntityAttackValue(defenderEntity)
		local defenderAttackValue = defenderEntity:Attributes():GetAttribute("Attack")
		local absorbValue = math.floor(defenderAttackValue*self._absorbAttackPercent)

		if defenderAttackRealValue == 0 then
			--Log.fatal("Target 一滴都没有了 ")
			return false
		end

		if absorbValue > defenderAttackRealValue then
			--Log.fatal("剩余不够了 Value:",defenderAttackRealValue)
			absorbValue = defenderAttackRealValue
		end
		if self._absorbValue + absorbValue >baseAttackValue then
			--Log.fatal("吸多了 AB:",self._absorbValue + absorbValue,"Base:",baseAttackValue)
			absorbValue = baseAttackValue - self._absorbValue
		end
		self._absorbValue = self._absorbValue +absorbValue
		local defenderModifier = self._buffLogicService:_GetAttributeModifier(defenderEntity,"AttackConstantFix")

		local alreadyAbsorbValue =defenderModifier:GetModifyValue(self:GetBuffSeq())
		if alreadyAbsorbValue then
			--Log.fatal("曾经吸过 Value:",alreadyAbsorbValue)
			absorbValue = absorbValue + alreadyAbsorbValue*-1
		end
		--Log.fatal("最终吸收了：",absorbValue)
		--Log.fatal("我变强了：",self._absorbValue)
		self._buffLogicService:ChangeBaseAttack(
				defenderEntity,
				self:GetBuffSeq(),
				ModifyBaseAttackType.AttackConstantFix,
				absorbValue*-1
		)
		self._buffLogicService:ChangeBaseAttack(
				attacker,
				self:GetBuffSeq(),
				ModifyBaseAttackType.AttackConstantFix,
				self._absorbValue
		)
		--Log.fatal("AbsorbAttackValue:",absorbValue)
		return true
	end
	return false
end
