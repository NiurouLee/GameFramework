--[[------------------------------------------------------------------------------------------
    ControlMonsterCastHitBackTeam = 217, -- 控制目标怪物施法击退队伍

]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamControlMonsterCastHitBackTeam", SkillEffectParamBase)
---@class SkillEffectParamControlMonsterCastHitBackTeam: SkillEffectParamBase
SkillEffectParamControlMonsterCastHitBackTeam = SkillEffectParamControlMonsterCastHitBackTeam

function SkillEffectParamControlMonsterCastHitBackTeam:Constructor(t)
    self._monsterClassID = t.monsterClassID
    self._trapID = t.trapID

    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式
end

function SkillEffectParamControlMonsterCastHitBackTeam:GetEffectType()
    return SkillEffectType.ControlMonsterCastHitBackTeam
end

function SkillEffectParamControlMonsterCastHitBackTeam:GetMonsterClassID()
    return self._monsterClassID
end

function SkillEffectParamControlMonsterCastHitBackTeam:GetTrapID()
    return self._trapID
end

function SkillEffectParamControlMonsterCastHitBackTeam:GetDamageFormulaID()
    return self._formulaID
end

function SkillEffectParamControlMonsterCastHitBackTeam:GetDamagePercent()
    return self._percent
end
