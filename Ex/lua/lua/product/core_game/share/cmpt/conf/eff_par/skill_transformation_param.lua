--[[
    怪物变身技能参数
]]
require("skill_effect_param_base")
_class("SkillTransformationParam", SkillEffectParamBase)
---@class SkillTransformationParam:SkillEffectParamBase
SkillTransformationParam = SkillTransformationParam

function SkillTransformationParam:Constructor(t)
    self._targetMonsterID = t.targetID

    self._useHpPercent = t.useHpPercent or 0 --默认0不生效。变身后的血量为：（当前血量百分数 + n%）*（变身目标血量最大值）

    self.m_InheritAttribute = {} --Attack, Defense, MaxHP
    -- 继承母体的属性 百分比
    if t.InheritAttribute ~= nil and type(t.InheritAttribute) == "table" then
        self.m_InheritAttribute = t.InheritAttribute
    end
    self._useTargetBodyArea = t.useTargetBodyArea or 0
    -- 继承变身前的元素属性，默认不继承
    self._inheritElement = t.inheritElement or false
    self._setTargetPosByOriBodyAreaIndex = t.setTargetPosByOriBodyAreaIndex or 0
end

function SkillTransformationParam:GetEffectType()
    return SkillEffectType.Transformation
end

function SkillTransformationParam:GetTargetMonsterID()
    return self._targetMonsterID
end

function SkillTransformationParam:GetUseHpPercent()
    return self._useHpPercent
end

---获取召唤怪继承母体三围数据 攻 防 血 Attack, Defense, MaxHP
function SkillTransformationParam:GetInheritAttribute()
    return self.m_InheritAttribute
end
---@return boolean
function SkillTransformationParam:IsUseTargetBodyArea()
    return self._useTargetBodyArea == 1
end

---获取是否继承变身前的元素属性
function SkillTransformationParam:GetInheritElement()
    return self._inheritElement
end
---@return boolean
function SkillTransformationParam:GetSetTargetPosByOriBodyAreaIndex()
    return self._setTargetPosByOriBodyAreaIndex
end