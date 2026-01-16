---这个命名实在不知道咋写，只能说纪律性定义了枚举
SkillEffect_WeikeNotify_CompanionType = {
    TypeA = 1,---小动物类型
    TypeB = 2,---小动物类型
    TypeC = 3,---小动物类型
}
---@class SkillEffect_WeikeNotify_CompanionType
---@field TypeA number
---@field TypeB number
---@field TypeC number
_enum("SkillEffect_WeikeNotify_CompanionType", SkillEffect_WeikeNotify_CompanionType)

---触发技能类型，根据技能配置比对的话，可能会遇到更换技能等情况，所以直接写成通过配置决定
SkillEffect_WeikeNotify_SkillType = {
    NormalSkill = 1, ---普攻
    ChainSkill1 = 2, ---连锁1
    ChainSkill2 = 3, ---连锁2
    ChainSkill3 = 4, ---连锁3
    ActiveSkill = 5, ---主动技
}
---@class SkillEffect_WeikeNotify_SkillType
---@field NormalSkill number
---@field ChainSkill1 number
---@field ChainSkill2 number
---@field ChainSkill3 number
---@field ActiveSkill number
_enum("SkillEffect_WeikeNotify_SkillType", SkillEffect_WeikeNotify_SkillType)

_class("SkillEffectParam_WeikeNotify", SkillEffectParamBase)
---@class SkillEffectParam_WeikeNotify : SkillEffectParamBase
SkillEffectParam_WeikeNotify = SkillEffectParam_WeikeNotify

function SkillEffectParam_WeikeNotify:GetEffectType()
    return SkillEffectType.WeikeNotify
end

function SkillEffectParam_WeikeNotify:Constructor(t, petId, effectIndex, skillType, grade, awaking)
    self._companionType = t.companionType
    self._skillType = t.skillType
end

---@return SkillEffect_WeikeNotify_CompanionType
function SkillEffectParam_WeikeNotify:GetCompanionType()
    return self._companionType
end

---@return SkillEffect_WeikeNotify_SkillType
function SkillEffectParam_WeikeNotify:GetSkillType()
    return self._skillType
end
