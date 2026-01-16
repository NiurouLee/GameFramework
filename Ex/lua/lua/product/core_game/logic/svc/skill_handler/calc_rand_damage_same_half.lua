--[[
    StampDamage = 17, ---龙之印记伤害
]]
---@class SkillEffectCalcRandDamageSameHalf: Object
_class("SkillEffectCalcRandDamageSameHalf", Object)
SkillEffectCalcRandDamageSameHalf = SkillEffectCalcRandDamageSameHalf

function SkillEffectCalcRandDamageSameHalf:Constructor(world)
	---@type MainWorld
	self._world = world

	---@type SkillEffectCalcService
	self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcRandDamageSameHalf:DoSkillEffectCalculator(skillEffectCalcParam)
	local results          = {}
	---@type SkillEffectParamRandDamageSameHalf
	local skillDamageParam = skillEffectCalcParam.skillEffectParam
	local percents         = skillDamageParam:GetDamagePercent()
	local damageFormulaID  = skillDamageParam:GetDamageFormulaID()

	local attacker         = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
	local targets          = skillEffectCalcParam:GetTargetEntityIDs()
	local damageDampList   = {}
	local damageCount      = skillDamageParam:GetDamageCount()
	---每次重复攻击衰减百分比
	local dampPer          = skillDamageParam:GetDampPercent()
	local percentAddParam  = skillDamageParam:GetPercentAdd()
	local isSelTargetLoop  = skillDamageParam:GetIsSelTargetLoop()--是否循环选敌 默认是随机
	local isKeepDamageList = skillDamageParam:IsKeepDampList()
	---@type RandomServiceLogic
	local randomSvc        = self._world:GetService("RandomLogic")
	---@type CalcDamageService
	local svcCalcDamage    = self._world:GetService("CalcDamage")
	local curDamageIndex = 1
	local lastIndex = 0

	-- 维克现在的需求是在他的一次技能内的伤害list保持
	if isKeepDamageList then
		local super = attacker
		if attacker:HasSuperEntity() then
			super = attacker:GetSuperEntity() or attacker
		end
		if super:SkillContext() then
			-- 这里是引用传递，但修改完确实还要存回去，所以引用没关系，虽然也写了SetDamageDampList这个东西
			damageDampList = super:SkillContext():GetDamageDampList()
		end
	end
	
    --如果是配置随机攻击次数，从配置的2个参数区间中随机作为攻击次数
    local damageRandomCount = skillDamageParam:GetDamageRandomCount()
    if damageRandomCount and type(damageRandomCount) == "table" then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local randomCount = randomSvc:LogicRand(damageRandomCount[1], damageRandomCount[2])
        damageCount = randomCount
    end
	local preCalTargetPer = self:_CalcPreRepeatTargetDmgPer(skillDamageParam,targets,damageCount)
	while #results < damageCount do
		local index
		if isSelTargetLoop then
			index = lastIndex + 1
			if index > #targets then
				index = 1
			end
			lastIndex = index
		else
			index =  randomSvc:LogicRand(1,#targets)
		end
		local targetID = targets[index]
		if not  damageDampList[targetID] then
			damageDampList[targetID] =1
		end
		if preCalTargetPer and preCalTargetPer[targetID] then --米洛斯
			damageDampList[targetID] = preCalTargetPer[targetID]
		end
		local multiDamageInfo = {}
		local totalDamage = 0
		---@type Entity
		local target = self._world:GetEntityByID(targetID)
		if target then
			local targetPos = target:GridLocation():GetGridPos()
			for _, percent in ipairs(percents) do
				self._skillEffectService:NotifyDamageBegin(
						attacker,
						target,
						attacker:GetGridPosition(),
						targetPos,
						skillEffectCalcParam.skillID,
						nil,nil,
						curDamageIndex
				)
				---@type DamageInfo
				local damageInfo =
				svcCalcDamage:DoCalcDamage(
						attacker,
						target,
						{
							percent = (percent+percentAddParam)*damageDampList[targetID],
							skillID = skillEffectCalcParam.skillID,
							formulaID = damageFormulaID
						}
				)
				damageInfo:SetRandHalfDamageIndex(curDamageIndex)
				curDamageIndex = curDamageIndex + 1
				---下次再被打要衰减
				damageDampList[targetID] = damageDampList[targetID] * dampPer
				totalDamage = totalDamage + damageInfo:GetDamageValue()
				table.insert(multiDamageInfo, damageInfo)
				self._skillEffectService:NotifyDamageEnd(
						attacker,
						target,
						skillEffectCalcParam.attackPos,
						targetPos,
						skillEffectCalcParam.skillID,
						damageInfo
				)
			end

			local skillResult = SkillDamageEffectResult:New(targetPos, targetID, totalDamage, multiDamageInfo)
			results[#results + 1] = skillResult
		end
	end
	--连锁技的这个部分移动到了ChainSkillCalculator:_CalcAndApplyChainSkillEffect_RandDamageSameHalf
	--因为维克的需求把这个效果放到了主动技内，这段代码会让result被添加两次
	-----@type SkillEffectResultContainer
    --local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
    --for _, v in ipairs(results) do
    --    skillEffectResultContainer:AddEffectResult(v)
    --end
	return results
end
--米洛斯 两次目标相同，则两次伤害都是衰减一次后
---@param skillDamageParam SkillEffectParamRandDamageSameHalf
function SkillEffectCalcRandDamageSameHalf:_CalcPreRepeatTargetDmgPer(skillDamageParam,targets,damageCount)
	local dampPer = skillDamageParam:GetDampPercent()
	local isSelTargetLoop = skillDamageParam:GetIsSelTargetLoop()--是否循环选敌 默认是随机
	local isRepeatAllSameHalf = skillDamageParam:IsRepeatAllSameHalf()--米洛斯
	if isRepeatAllSameHalf and isSelTargetLoop then--只处理循环选敌情况
		local attackTargetArray = {}
		local index = 0
		for i = 1, damageCount do
			index = index + 1
			if index > #targets then
				index = 1
			end
			local targetID = targets[index]
			table.insert(attackTargetArray,targetID)
		end
		local targetCountDic = {}
		for _, targetID in ipairs(attackTargetArray) do
			if targetCountDic[targetID] then
				targetCountDic[targetID] = targetCountDic[targetID] + 1
			else
				targetCountDic[targetID] = 1
			end
		end
		local preCalTargetPer = {}
		for _, targetID in ipairs(targets) do
			if targetCountDic[targetID] and targetCountDic[targetID] > 1 then
				preCalTargetPer[targetID] = dampPer
			end
		end
		return preCalTargetPer
	end
end