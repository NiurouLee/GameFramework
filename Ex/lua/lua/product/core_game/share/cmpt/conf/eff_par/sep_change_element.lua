require("skill_damage_effect_param")
---@class EffectChangeElementType
local EffectChangeElementType = {
    Normal = 1,
    ByCurrentTeamLeader = 2,
    RestoreMonsterCfgElement = 3, --还原成monster表里的属性
    MAX = 99
}
_enum("EffectChangeElementType", EffectChangeElementType)
_class("SkillEffectChangeElementParam", SkillEffectParamBase)
---@class SkillEffectChangeElementParam: SkillEffectParamBase
SkillEffectChangeElementParam = SkillEffectChangeElementParam

function SkillEffectChangeElementParam:Constructor(t)
    self._element = t.element
    self._type = t.type or EffectChangeElementType.Normal
    ---是否改变SuperEntity的属性，默认改变的施法者 [KZY:SkillHolder去Self]
    self._changeSuperElement = t.changeSuperElement or false
end

function SkillEffectChangeElementParam:GetEffectType()
    return SkillEffectType.ChangeElement
end

function SkillEffectChangeElementParam:GetElement()
    return self._element
end

function SkillEffectChangeElementParam:GetType()
    return self._type
end

function SkillEffectChangeElementParam:IsChangeSuperElement()
    return self._changeSuperElement
end
