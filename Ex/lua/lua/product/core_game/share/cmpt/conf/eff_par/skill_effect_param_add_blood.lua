--region SkillEffectParam_AddBlood : 加血效果参数
require("skill_effect_param_base")
---@class AddBlood_Type
local AddBlood_Type = {
    Percent = 1,
    AbsData = 2,
    Attribute = 3, -- 配置回复的基础值+该角色某项属性的百分比 属性为：攻防血
    HighestHPOfBoss = 4, --场上Boss里的最高血量与自身血量差值
    AttributeList = 5, --3的数组形态 （配置回复的基础值+该角色某项属性的百分比 属性为：攻防血）
    LastCastActiveSkillPet = 6, --使用上一个释放主动技的光灵的攻击力回血
    AttributeAndTargetBodyAreaInSkillRangeCount = 7, -- 3的基础上 + 目标身形在技能范围内的数量
    LostHPPercent = 8, --以已损失血量为基础值进行计算
    ByLayerAndAttr = 9, -- 使用自身层数和属性加血，直到加满或者层数用尽
    Max = 99
}
_enum("AddBlood_Type", AddBlood_Type)
--endregion

--region AddBlood_Attribute : 按照属性加血的属性类型
---@class AddBlood_Attribute
local AddBlood_Attribute = {
    START = 0,
    None = 0,
    Attack = 1,
    Defense = 2,
    MaxHP = 3,
    TeamLoseHp = 4, --队伍损失血量
    END = 5
}
_enum("AddBlood_Attribute", AddBlood_Attribute)
--endregion


_class("SkillEffectParam_AddBlood", SkillEffectParamBase)
---@class SkillEffectParam_AddBlood: SkillEffectParamBase
SkillEffectParam_AddBlood = SkillEffectParam_AddBlood

function SkillEffectParam_AddBlood:Constructor(t)
    self.m_nType = t.type
    self.m_nData = t.data
    self.m_nAttribute = AddBlood_Attribute.None
    if
        t.Attribute ~= nil and type(t.Attribute) == "number" and t.Attribute > AddBlood_Attribute.START and
            t.Attribute < AddBlood_Attribute.END
     then
        self.m_nAttribute = t.Attribute
    end
    self.m_nAttributePer = 0
    if t.AttributePer ~= nil and type(t.AttributePer) == "number" then
        self.m_nAttributePer = t.AttributePer
    end
    self.m_nAddBloodRateByDefender = t.AddBloodByDefender

    --list
    self.m_nDataList = t.dataList
    self.m_nAttributeList = t.AttributeList
    self.m_nAttributePerList = t.AttributePerList

    self._buffLayerType = t.buffLayerType
    self._costLayer = t.costLayer
    self._perLayer = t.perLayer

end

function SkillEffectParam_AddBlood:GetBuffLayerType()
    return self._buffLayerType
end

function SkillEffectParam_AddBlood:GetCostLayer()
    return self._costLayer
end

function SkillEffectParam_AddBlood:GetPerLayer()
    return self._perLayer
end

function SkillEffectParam_AddBlood:GetEffectType()
    return SkillEffectType.AddBlood
end

---加血计算方式类型，对应AddBlood_Type
function SkillEffectParam_AddBlood:GetType()
    return self.m_nType
end
---加血计算单一参数，区别于m_nDataList，对应配置的data参数
function SkillEffectParam_AddBlood:GetData()
    return self.m_nData or 0
end

-- 获取属性回血技能对应的属性
function SkillEffectParam_AddBlood:GetAttribute()
    return self.m_nAttribute
end

-- 对应属性增加百分比
function SkillEffectParam_AddBlood:GetAttributePer()
    return self.m_nAttributePer
end

--血量加成值的来源
function SkillEffectParam_AddBlood:GetAddBloodRateByDefender()
    return self.m_nAddBloodRateByDefender
end

--一次技能效果里 计算多次加血效果 累加在一起表现
---获取召唤目标类型ID List
function SkillEffectParam_AddBlood:GetDataList()
    return self.m_nDataList
end

-- 获取属性回血技能对应的属性 List
function SkillEffectParam_AddBlood:GetAttributeList()
    return self.m_nAttributeList
end

-- 对应属性增加百分比 List
function SkillEffectParam_AddBlood:GetAttributePerList()
    return self.m_nAttributePerList
end
