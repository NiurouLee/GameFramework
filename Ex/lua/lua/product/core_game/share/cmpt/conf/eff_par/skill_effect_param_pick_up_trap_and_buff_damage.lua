--[[------------------------------------------------------------------------------------------
    PickUpTrapAndBuffDamage = 169, --根据选中地点指定机关上的指定buff层数来释放不同的伤害
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamPickUpTrapAndBuffDamage", SkillEffectParamBase)
---@class SkillEffectParamPickUpTrapAndBuffDamage: SkillEffectParamBase
SkillEffectParamPickUpTrapAndBuffDamage = SkillEffectParamPickUpTrapAndBuffDamage

function SkillEffectParamPickUpTrapAndBuffDamage:Constructor(t)
    self._trapIDList = t.trapIDList
    self._buffID = t.buffID
    self._formulaID = t.formulaID
    self._percentList = t.percentList
    self._skillList = t.skillList
end

function SkillEffectParamPickUpTrapAndBuffDamage:GetEffectType()
    return SkillEffectType.PickUpTrapAndBuffDamage
end

function SkillEffectParamPickUpTrapAndBuffDamage:GetTrapIDList()
    return self._trapIDList
end

function SkillEffectParamPickUpTrapAndBuffDamage:GetBuffID()
    return self._buffID
end
function SkillEffectParamPickUpTrapAndBuffDamage:GetFormulaID()
    return self._formulaID
end

function SkillEffectParamPickUpTrapAndBuffDamage:GetPercentList()
    return self._percentList
end
function SkillEffectParamPickUpTrapAndBuffDamage:GetSkillList()
    return self._skillList
end
