require("calc_base")

---@class SkillEffectCalcDeathBomb : SkillEffectCalc_Base
_class("SkillEffectCalcDeathBomb", SkillEffectCalc_Base)
SkillEffectCalcDeathBomb = SkillEffectCalcDeathBomb

function SkillEffectCalcDeathBomb:Constructor(world)
	---@type MainWorld
	self._world = world
	---@type SkillEffectCalcService
	self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param param SkillEffectCalcParam
function SkillEffectCalcDeathBomb:DoSkillEffectCalculator(param)
	if #param.targetEntityIDs == 0 or param.targetEntityIDs[1]  == - 1 then
		return {SkillEffectDeathBombResult:New()}
	end
	local attacker = self._world:GetEntityByID(param.casterEntityID)

	---@type SkillEffectParamDeathBomb
	local effectParam = param.skillEffectParam

	-- 以scopeResult的受击点为中心计算范围
	local lastHitpoint = param.gridPos
	---@type UtilScopeCalcServiceShare
	local utilScopeSvc = self._world:GetService("UtilScopeCalc")
	---@type SkillScopeCalculator
	local calcScope         = utilScopeSvc:GetSkillScopeCalc()

	local scopeType         = effectParam:GetDeathBombScopeType()
	local scopeParam           = effectParam:GetDeathBombScopeParam()
	local parser               = SkillScopeParamParser:New()
	local rangeScopeParam      = parser:ParseScopeParam(scopeType, scopeParam)
	local casterBodyArea       = attacker:BodyArea():GetArea()
	local casterDirection      = attacker:GetGridDirection()
	local deathTargetID        = param.targetEntityIDs[1]
	local deathTargetEntity    = self._world:GetEntityByID(deathTargetID)
	---@type BuffLogicService
	local buffLogicService     = self._world:GetService("BuffLogic")
	local buffID               = effectParam:GetDeathBombBuffID()
	local deathTargetBuffLayer = buffLogicService:GetBuffLayer(deathTargetEntity,buffID)
	local ScopeResult          =
	calcScope:ComputeScopeRange(
			scopeType,
			rangeScopeParam,
			lastHitpoint,
			casterBodyArea,
			casterDirection,
			SkillTargetType.MonsterTrap, -- TODO
			lastHitpoint
	)

	-- 用新范围获取挨打的目标
	local targetSelector    = self._world:GetSkillScopeTargetSelector()
	local targetArray       = targetSelector:DoSelectSkillTarget(attacker, SkillTargetType.MonsterTrap, ScopeResult)
	local targetGridAreaMap = {}
	for _, targetEntityID in ipairs(targetArray) do
		local targetEntity = self._world:GetEntityByID(targetEntityID)
		if targetEntity then
			targetGridAreaMap[targetEntityID] = {}

			local targetCenterPos = targetEntity:GetGridPosition()
			local bodyAreaComponent = targetEntity:BodyArea()
			if bodyAreaComponent then
				local bodyAreaArray = bodyAreaComponent:GetArea()
				for _, areaPos in ipairs(bodyAreaArray) do
					local absAreaPos = (areaPos + targetCenterPos)
					if not targetGridAreaMap[absAreaPos.x] then
						targetGridAreaMap[absAreaPos.x] = {}
					end
					targetGridAreaMap[absAreaPos.x][absAreaPos.y] = targetEntityID
				end
			else
				if not targetGridAreaMap[targetCenterPos.x] then
					targetGridAreaMap[targetCenterPos.x] = {}
				end
				targetGridAreaMap[targetCenterPos.x][targetCenterPos.y] = targetEntityID
			end
		end
	end

	local resultArray = {}

	local attackRange = ScopeResult:GetAttackRange()
	table.removev(attackRange, lastHitpoint)

	---@type SkillDamageEffectParam
	local skillDamageParam = param.skillEffectParam
	skillDamageParam.buffLayer = deathTargetBuffLayer
	local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
	for _, attackPos in ipairs(attackRange) do
		if (targetGridAreaMap[attackPos.x]) and (targetGridAreaMap[attackPos.x][attackPos.y]) then
			local defenderEntityID = (targetGridAreaMap[attackPos.x][attackPos.y])
			---@type Entity
			local defender = self._world:GetEntityByID(defenderEntityID)
			local attackerPos = param.attackPos
			local gridPos = attackPos

			local nTotalDamage, listDamageInfo =
			self._skillEffectService:ComputeSkillDamage(
					attacker,
					attackerPos,
					defender,
					gridPos,
					param.skillID,
					skillDamageParam,
					SkillEffectType.DeathBomb,
					damageStageIndex
			)

			local skillResult =
			self._skillEffectService:NewSkillDamageEffectResult(
					gridPos,
					defenderEntityID,
					nTotalDamage,
					listDamageInfo,
					damageStageIndex
			)
			table.insert(resultArray, skillResult)
		end
	end

	return resultArray-- {SkillDamageEffectResult:New(resultArray, ScopeResult)}
end
