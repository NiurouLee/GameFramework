require("skill_damage_effect_param")

_class("SkillEffectDestroyTrapParam", SkillEffectParamBase)
---@class SkillEffectDestroyTrapParam: SkillEffectParamBase
SkillEffectDestroyTrapParam = SkillEffectDestroyTrapParam

function SkillEffectDestroyTrapParam:Constructor(t)
    self._trapID = {}
    if t.trapID then
        for _, id in ipairs(t.trapID) do
            self._trapID[id] = true
        end
    end
    self._protectTrapID = {}
    if t.protectTrapID then
        for _, id in ipairs(t.protectTrapID) do
            self._protectTrapID[id] = true
        end
    end
    self._trapType = {}
    if t.trapType then
        for _, id in ipairs(t.trapType) do
            self._trapType[id] = true
        end
    end
    self._destroyType = t.destroyType or SkillEffectDestroyTrapType.Range
    self._disableDieSkill = t.disableDieSkill

    self._special = t.special or 0 --默认0，配置1才可以删除机关表里配置SpecialDestroy特殊的机关，否则其他条件符合也不可以删除

    self._stageIndex = t.stageIndex or 1
end

function SkillEffectDestroyTrapParam:GetEffectType()
    return SkillEffectType.DestroyTrap
end

function SkillEffectDestroyTrapParam:IsDestroyTrap(trapID)
    return self._trapID[trapID]
end

function SkillEffectDestroyTrapParam:IsDestroyTrapWithType(trapType)
    return self._trapType[trapType]
end

function SkillEffectDestroyTrapParam:IsProtectTrap(trapID)
    return self._protectTrapID[trapID]
end

---@return SkillEffectDestroyTrapType
function SkillEffectDestroyTrapParam:GetDestroyType()
    return self._destroyType
end

function SkillEffectDestroyTrapParam:GetDisableDieSkill()
    return self._disableDieSkill
end

function SkillEffectDestroyTrapParam:GetSpecial()
    return self._special
end
function SkillEffectDestroyTrapParam:GetStageIndex()
    return self._stageIndex
end

---@class SkillEffectDestroyTrapType
---@field Self number 删除自己
---@field Other number 删除除自己外其他全部机关：2020-12-04 只允许自动测试功能内使用
---@field Range number 删除范围内指定机关
local SkillEffectDestroyTrapType = {
    Self = 1, ---删除自己
    Other = 2, ---删除除自己外其他全部机关
    Range = 3, ---删除范围内指定机关
    RangeExceptConfig = 4, ---删除范围内除了配置ID外的其余机关
    Sticker = 5, --贴纸专用，在深渊上删除所有机关，普通格子上只删除自己
    RangeSelectTrapType = 6, --范围内指定机关类型
    MySummonTrap = 7, --自己召唤的机关
    RangeAll = 8, ---删除范围内全部机关
    SelfSummonDone = 9, ---自己召唤完毕后
    HitBackRange = 10 ,
}
_enum("SkillEffectDestroyTrapType", SkillEffectDestroyTrapType)
