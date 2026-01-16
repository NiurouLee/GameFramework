require("skill_effect_param_base")

---@class SkillEffectEnterMirageParam: SkillEffectParamBase
_class("SkillEffectEnterMirageParam", SkillEffectParamBase)
SkillEffectEnterMirageParam = SkillEffectEnterMirageParam

function SkillEffectEnterMirageParam:Constructor(t)
    self._trapRefreshID = t.trapRefreshID

    self._inheritAttribute = {} --Attack, Defense, MaxHP
    --继承母体的属性 百分比
    if t.inheritAttribute ~= nil and type(t.inheritAttribute) == "table" then
        self._inheritAttribute = t.inheritAttribute
    end

    --继承属性的时候，默认是读取monster表里的数值，如果这个值是1，那么读取施法者身上的
    self._useAttribute = t.useAttribute or 0

    --继承母体元素属性，默认不继承
    self._inheritElement = t.inheritElement or false
end

function SkillEffectEnterMirageParam:GetEffectType()
    return SkillEffectType.EnterMirage
end

function SkillEffectEnterMirageParam:GetTrapRefreshID()
    return self._trapRefreshID
end

function SkillEffectEnterMirageParam:GetInheritAttribute()
    return self._inheritAttribute
end

function SkillEffectEnterMirageParam:GetUseAttribute()
    return self._useAttribute
end

function SkillEffectEnterMirageParam:GetInheritElement()
    return self._inheritElement
end
