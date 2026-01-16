--[[------------------------------------------------------------------------------------------
    ControlMonsterMove = 200, -- 控制目标怪物位移(n28蜘蛛)

]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamControlMonsterMove", SkillEffectParamBase)
---@class SkillEffectParamControlMonsterMove: SkillEffectParamBase
SkillEffectParamControlMonsterMove = SkillEffectParamControlMonsterMove

function SkillEffectParamControlMonsterMove:Constructor(t)
    self._monsterClassID = t.monsterClassID
    self._trapID = t.trapID

    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式
end

function SkillEffectParamControlMonsterMove:GetEffectType()
    return SkillEffectType.ControlMonsterMove
end

function SkillEffectParamControlMonsterMove:GetMonsterClassID()
    return self._monsterClassID
end

function SkillEffectParamControlMonsterMove:GetTrapID()
    return self._trapID
end

function SkillEffectParamControlMonsterMove:GetDamageFormulaID()
    return self._formulaID
end

function SkillEffectParamControlMonsterMove:GetDamagePercent()
    return self._percent
end
