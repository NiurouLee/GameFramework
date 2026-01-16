require("calc_base")

_class("SkillEffectCalc_CoffinMusumeSetCandleLight", SkillEffectCalc_Base)
---@class SkillEffectCalc_CoffinMusumeSetCandleLight: SkillEffectCalc_Base
SkillEffectCalc_CoffinMusumeSetCandleLight = SkillEffectCalc_CoffinMusumeSetCandleLight

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_CoffinMusumeSetCandleLight:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_CoffinMusumeSetCandleLight
    local param = skillEffectCalcParam.skillEffectParam
    return {SkillEffectResult_CoffinMusumeSetCandleLight:New(skillEffectCalcParam.casterEntityID, param:IsLight())}
end
