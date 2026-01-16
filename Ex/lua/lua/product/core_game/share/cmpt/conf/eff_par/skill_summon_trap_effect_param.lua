--[[------------------------------------------------------------------------------------------
    SkillSummonTrapEffectParam : 召唤陷阱技能效果参数
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")

_class("SkillSummonTrapEffectParam", SkillEffectParamBase)
---@class SkillSummonTrapEffectParam: SkillEffectParamBase
SkillSummonTrapEffectParam = SkillSummonTrapEffectParam

function SkillSummonTrapEffectParam:Constructor(t)
    self._trapID = t.trapID
    self._block = t.block or 1 --召唤机关是否考虑阻挡 默认考虑
    self._transferDisabled = (t.transferDisabled == 1)
    self._overlapFlag = t.overlapFlag or 1 --机关是否可重叠（同一位置召唤同一ID机关），默认可重复召唤
    self._overlapCheckSuper = t.overlapCheckSuper or 0 --机关重叠检查 是否判断机关召唤者的super
    self._absorbTrapNum = t.absorbTrapNum or 0 --吸收机关个数满足条件后，才能召唤机关
    self._moveTrap = t.moveTrap or 0 --是否移动机关：机关已存在则移动机关，机关不存在则召唤机关
    self._type = t.type or SummonTrapType.Normal
    self._stopSummonTrapType = t.stopSummonTrapType --当目标脚下召唤机关时，阻挡召唤的机关类型
    self._blockByMonster = t.blockByMonster or 0 --有怪的位置是否可以召唤机关，默认可以
    self._randomCount = t.randomCount --- 随机召唤数量
    self._usePickUpDir = t.usePickUpDir or 0
    self._aiOrder = t.aiOrder --机关AI的初始Order，若配置，则召唤者召唤出的机关按照召唤顺序设置AI顺序；不配AI应用trap中的原配置
end

function SkillSummonTrapEffectParam:GetEffectType()
    return SkillEffectType.SummonTrap
end

---获取陷阱ID
function SkillSummonTrapEffectParam:GetTrapID()
    return self._trapID
end

function SkillSummonTrapEffectParam:GetBlock()
    return self._block
end

function SkillSummonTrapEffectParam:IsTransferDisabled()
    return self._transferDisabled
end

---@return boolean
function SkillSummonTrapEffectParam:IsTrapOverlap()
    return self._overlapFlag == 1
end

function SkillSummonTrapEffectParam:IsTrapOverlapCheckSuper()
    return self._overlapCheckSuper == 1
end

function SkillSummonTrapEffectParam:GetAbsorbTrapNum()
    return self._absorbTrapNum
end

--是否可以移动机关
function SkillSummonTrapEffectParam:GetMoveTrap()
    return self._moveTrap == 1
end

function SkillSummonTrapEffectParam:GetSummonType()
    return self._type
end

function SkillSummonTrapEffectParam:GetStopSummonTrapType()
    return self._stopSummonTrapType
end

function SkillSummonTrapEffectParam:GetRandomCount()
    return self._randomCount
end

---@return boolean
function SkillSummonTrapEffectParam:IsBlockByMonster()
    return self._blockByMonster == 1
end

--召唤机关朝向是否使用点选的方向
function SkillSummonTrapEffectParam:IsUsePickUpDir()
    return self._usePickUpDir == 1
end

--获取机关AI的Order
function SkillSummonTrapEffectParam:GetTrapAIOrder()
    return self._aiOrder
end

---@class SummonTrapType
local SummonTrapType = {
    Normal = 1,
    ByTargetUnderGrid = 2, ---
    Range = 3, ---范围内
    RandomRange = 4, ---范围内随机
}
_enum("SummonTrapType", SummonTrapType)
