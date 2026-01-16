---@class SkillEffectCalc_RecoverFromGreyHP: SkillEffectCalc_Base
_class("SkillEffectCalc_RecoverFromGreyHP", SkillEffectCalc_Base)
SkillEffectCalc_RecoverFromGreyHP = SkillEffectCalc_RecoverFromGreyHP

---
---@param calcParam SkillEffectCalcParam
---@param targetID number
function SkillEffectCalc_RecoverFromGreyHP:CalculateOnSingleTarget(calcParam, targetID)
    local casterEntity = self._world:GetEntityByID(calcParam:GetCasterEntityID())
    ---@type SkillEffectParam_RecoverFromGreyHP
    local effectParam =calcParam:GetSkillEffectParam()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local damageInfo = buffLogicService:GetRecoverFromGreyHPDamageInfo(casterEntity, effectParam:GetRecoverRate())
    if not damageInfo then
        return
    end

    return SkillEffectResult_RecoverFromGreyHP:New(calcParam:GetCasterEntityID(), damageInfo)
end
