--[[------------------------------------------------------------------------------------------
    Transposition = 183, --互换位置
]]
--------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamTransposition", SkillEffectParamBase)
---@class SkillEffectParamTransposition: SkillEffectParamBase
SkillEffectParamTransposition = SkillEffectParamTransposition

function SkillEffectParamTransposition:Constructor(t)
    self._monsterClassID = t.monsterClassID

    ---是否使用SuperEntity，默认不用 [KZY:SkillHolder去Self]
    self._useSuper = t.useSuper or false
end

function SkillEffectParamTransposition:GetEffectType()
    return SkillEffectType.Transposition
end

function SkillEffectParamTransposition:GetMonsterClassID()
    return self._monsterClassID
end

function SkillEffectParamTransposition:IsUseSuper()
    return self._useSuper
end
