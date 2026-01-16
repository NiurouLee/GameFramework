require("calc_base")


_class("SkillEffectCalcExchangeGridColor", SkillEffectCalc_Base)
---@class SkillEffectCalcExchangeGridColor:SkillEffectCalc_Base
SkillEffectCalcExchangeGridColor = SkillEffectCalcExchangeGridColor

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcExchangeGridColor:DoSkillEffectCalculator(skillEffectCalcParam)
	---@type SkillEffectExchangeGridColorParam
	local effectParam = skillEffectCalcParam.skillEffectParam
	---@type Vector2[]
	local scopeResult = skillEffectCalcParam:GetSkillRange()

	local summonTrapList = {}
	local newGridList = {}
	---@type BoardServiceLogic
	local boardServiceLogic =self._world:GetService("BoardLogic")
	if #scopeResult ~= 2 then
		Log.exception("Effect ExchangeGridColor scope Invalid,skillID:",skillEffectCalcParam:GetSkillID())
		return nil
	end
	local gridType1 = boardServiceLogic:GetPieceType(scopeResult[1])
	local gridType2 = boardServiceLogic:GetPieceType(scopeResult[2])
	newGridList[scopeResult[1]] = gridType2
	newGridList[scopeResult[2]] = gridType1

	---配置了机关ID就是要召唤了
	if effectParam:GetTrapID() then
		local gridTypeList = effectParam:GetSummonTrapGridTypeList()
		local trapID= effectParam:GetTrapID()
		if table.icontains(gridTypeList,gridType1) then
			summonTrapList[scopeResult[2]] = trapID
		end
		if table.icontains(gridTypeList,gridType2) then
			summonTrapList[scopeResult[1]] = trapID
		end
	end

	local result = SkillEffectExchangeGridColorResult:New(newGridList,summonTrapList)
	return result
end
