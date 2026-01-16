--buff大类
BuffType = {
    Control = 1, --控制类
    DOT = 2, --持续伤害
    Positive = 3, --增益
    Negative = 4, --减益
    Team = 5, --队伍光环
    Logic = 6, --仅用于逻辑
    PopStarStage = 7, --消灭星星的阶段Buff
}

---@class ModifySkillIncreaseParamType
---@field NormalSkill number 普通攻击修改公式中的普攻伤害倍率
---@field ChainSkill number  连锁攻击修改公式中的连锁伤害倍率
---@field ActiveSkill number 主动技修改公式中的主动技伤害倍率
---@field MonsterDamage number 怪物伤害值修改公式怪物伤害倍率
---@field TrapDamage number 机关伤害值修改公式机关伤害倍率
local ModifySkillIncreaseParamType = {
    NormalSkill = 1, ---普通攻击修改公式中的普攻伤害倍率
    ChainSkill = 2, ---连锁攻击修改公式中的连锁伤害倍率
    ActiveSkill = 3, ---主动技修改公式中的主动技伤害倍率
    MonsterDamage = 4, ---怪物伤害值修改公式怪物伤害倍率
    TrapDamage = 5
}
_enum("ModifySkillIncreaseParamType", ModifySkillIncreaseParamType)

---@class ModifySkillParamType
local ModifySkillParamType = {
    NormalSkill = 1, ---普通攻击修改公式中的普攻伤害倍率
    ChainSkill = 2, ---连锁攻击修改公式中的连锁伤害倍率
    ActiveSkill = 3, ---主动技修改公式中的主动技伤害倍率
    MonsterDamage = 4, ---怪物伤害值修改公式怪物伤害倍率
    SanSkill = 5, ---san值相关需求的最终伤害系数
}
_enum("ModifySkillParamType", ModifySkillParamType)

---@class MonsterSkillAbsorbType
local MonsterSkillAbsorbType = {
    NormalSkill = 1, ---怪物对的光灵普攻的吸收系数
    ChainSkill = 2, ---怪物对的光灵连锁的吸收系数
    ActiveSkill = 3 ---怪物对的光灵主动技的吸收系数
}
_enum("MonsterSkillAbsorbType", MonsterSkillAbsorbType)

---@class ModifyBaseDefenceType
---@field Defense number 公式中的基础防御
---@field DefencePercentage number 公式中的防御修正系数  参数为小数
---@field DefenceConstantFix number 公式中的防御固定修正值 参数为整数
local ModifyBaseDefenceType = {
    "Defense", ---公式中的基础防御
    "DefencePercentage", ---公式中的防御修正系数
    "DefenceConstantFix" ---公式中的防御固定修正值
}
_autoEnum("ModifyBaseDefenceType", ModifyBaseDefenceType)

---@class ModifyBaseAttackType
---@field Attack number 公式中的基础攻击
---@field AttackPercentage number 公式中的攻击修正系数  参数为小数形式
---@field AttackConstantFix number 公式中的攻击固定修正值 参数为整数值
local ModifyBaseAttackType = {
    "Attack", --公式中的基础攻击
    "AttackPercentage", ---公式中的攻击修正系数
    "AttackConstantFix" ---公式中的攻击固定修正值
}
_autoEnum("ModifyBaseAttackType", ModifyBaseAttackType)

---@class BuffSourceType
---@field Buff number
---@field PassiveSkill number
---@field SkillIntensify number
local BuffSourceType = {
    "Buff",
    "PassiveSkill", ---被动技能
    "SkillIntensify", ---技能强化
    "EquipRefine", ---装备精炼
}
_autoEnum("BuffSourceType", BuffSourceType)

---@class ModifyBaseMaxHPType
---@field MaxHPPercentage number 最大血量修正系数  参数为小数形式
---@field MaxHPConstantFix number 最大血量固定修正值 参数为整数值
local ModifyBaseMaxHPType = {
    "MaxHPPercentage", ---最大血量修正系数
    "MaxHPConstantFix" ---最大血量固定修正值
}
_autoEnum("ModifyBaseMaxHPType", ModifyBaseMaxHPType)
_class("BuffSource", Object)
---@class BuffSource:Object
BuffSource = BuffSource
---@param sourceType BuffSourceType
function BuffSource:Constructor(sourceType, sourceID)
    ---来源类型
    ---@type BuffSourceType
    self._sourceType = sourceType
    ---对应来源类型的ID,每种来源使用自己内部的唯一id
    ---被动技能使用PetPstID
    self._sourceID = sourceID
end
---判断是否是同一个来源
---
function BuffSource:IsMe(sourceType, sourceID)
    if self._sourceType and self._sourceType == sourceType then
        if self._sourceID and self._sourceID == sourceID then
            return true
        end
    end
    return false
end
---@return BuffSourceType
function BuffSource:GetSourceType()
    return self._sourceType
end

function BuffSource:GetSourceID()
    return self._sourceID
end

BuffSource.__eq = function(a, b)
    if a._sourceType and b._sourceType and a._sourceType == b._sourceType then
        if a._sourceID and b._sourceID and a._sourceID == b._sourceID then
            return true
        end
    end
    return false
end

_class("BuffIntensifyParam", Object)
---@class BuffIntensifyParam:Object
BuffIntensifyParam = BuffIntensifyParam
function BuffIntensifyParam:Constructor()
    ---@type number
    self.BuffID = nil
    ---@type number
    self.value = nil
    self.isShow = true
    ---@type number
    self.type = 1
    ---@type BuffIntensifyParamKey
    self.key = BuffIntensifyParamKey:New()
end
_class("BuffIntensifyParamKey", Object)
---@class BuffIntensifyParamKey:Object
BuffIntensifyParamKey = BuffIntensifyParamKey
function BuffIntensifyParamKey:Constructor()
    ---@type string
    self.LogicType = nil
    ---@type number
    self.LogicIndex = nil
    ---@type string
    self.param = nil
    ---@type number
    self.paramIndex = nil
    ---@type number
    self.TriggerType = nil
    ---@type number
    self.TriggerIndex = nil
    ---@type number
    self.TriggerParamIndex = nil
end
