require("calc_base")


_class("SkillEffectCalcCostCasterHP", SkillEffectCalc_Base)
---@class SkillEffectCalcCostCasterHP:SkillEffectCalc_Base
SkillEffectCalcCostCasterHP = SkillEffectCalcCostCasterHP

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcCostCasterHP:DoSkillEffectCalculator(skillEffectCalcParam)
	---@type SkillEffectCostCasterHPParam
	local effectParam = skillEffectCalcParam.skillEffectParam
	local casterEntity =self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
	if effectParam:GetCostType() == SkillEffectCostCasterHPType.CurHPPercent 
		or effectParam:GetCostType() == SkillEffectCostCasterHPType.MaxHPPercent
	then
		local result = SkillEffectCostCasterHPResult:New(effectParam:GetCostPercent(),effectParam:GetCostType(),effectParam:GetIgnoreShield(),effectParam:GetLeastHP())
		return result
	else
		Log.exception("SkillEffectCalcCostCasterHP CostType:",effectParam:GetCostType(),"Invalid ")
		return nil
	end
end
