--[[----------------------------------------------------------------
    2019-12-16  韩玉信添加
    2019-12-17  从 SkillPhaseScopeForwardParam 拷贝的原始代码
    SkillPhaseParam_GridRange : 计划把所有格子动画、特效技能表现都集成到这里
--]]----------------------------------------------------------------
require "skill_phase_param_base"

--- @class SkillPhaseParam_GridRange_SortCenterType
local SkillPhaseParam_GridRange_SortCenterType = {
    CasterPos = 0,      --使用Scope的中心坐标
    CasterX = 1,        --使用Scope的中心坐标X轴，Y轴为自定义
    CasterY = 2,        --使用Scope的中心坐标Y周，X轴位自定义
    User = 3,           --完全自定义
}
_enum("SkillPhaseParam_GridRange_SortCenterType", SkillPhaseParam_GridRange_SortCenterType)
----------------------------------------------------------------
_class("SkillPhaseParam_GridRange", SkillPhaseParamBase)
---@class SkillPhaseParam_GridRange: SkillPhaseParamBase
SkillPhaseParam_GridRange = SkillPhaseParam_GridRange

function SkillPhaseParam_GridRange:Constructor(t)
    ---这三个参数跟cfg_battle_skill表内参数大体相同
    self._scopeCenterType = t.scopeCenterType;
    self._scopeType = t.scopeType;      ---如果为0或者为nil，则使用技能配置的范围，并按照距离圆心远近来排序
    self._scopeParam = t.scopeParam;
    self._targetType = t.targetType or SkillTargetType.Pet;
    self._sortCenterType = t.sortCenterType;  --1：使用主角中心，其他：自定义， sortCenterPos
    self._sortCenterPos = t.sortCenterPos;    ---自定义排序基准位置，默认是(0,0)

    -- self._groupType = t.groupType;
    self._groupIntervalTime = t.groupIntervalTime;

    self._gridEffectID = t.gridEffectID
    self._gridIntervalTime = t.gridIntervalTime
    self._hasConvert = t.hasConvert
    self._bestConvertTime = t.bestConvertTime
    self._damageIndex = t.damageIndex
    self._hitAnimationName = t.hitAnimationName
    self._hitEffectID = t.hitEffectID
    self._finishDelayTime = t.finishDelayTime
end

function SkillPhaseParam_GridRange:GetCacheTable()
    local listID = {}
    self:AddEffectIDToListID(listID, self._gridEffectID)
    self:AddEffectIDToListID(listID, self._hitEffectID)
    return self:GetCacheTableFromListID(listID)
end

function SkillPhaseParam_GridRange:GetPhaseType()
    return SkillViewPhaseType.GridRangeEffect
end

function SkillPhaseParam_GridRange:GetGroupIntervalTime()
    return self._groupIntervalTime
end

function SkillPhaseParam_GridRange:GetGridEffectID()
    return self._gridEffectID
end

function SkillPhaseParam_GridRange:GetGridIntervalTime()
    return self._gridIntervalTime
end

function SkillPhaseParam_GridRange:GetBestEffectTime()
    return self._bestEffectTime
end

---@return number
function SkillPhaseParam_GridRange:GetFinishDelayTime()
    return self._finishDelayTime
end

---@return boolean
function SkillPhaseParam_GridRange:HasDamage()
    if self._damageIndex then
        return self._damageIndex > 0
    else
        return false
    end
end

function SkillPhaseParam_GridRange:GetDamageIndex()
    return self._damageIndex
end


function SkillPhaseParam_GridRange:HasConvert()
    if self._hasConvert then
        return self._hasConvert == 1
    else
        return false
    end
end

function SkillPhaseParam_GridRange:GetGridEffectTime()
    return self._gridEffectTime
end

function SkillPhaseParam_GridRange:GetHitAnimationName()
    return self._hitAnimationName
end

function SkillPhaseParam_GridRange:GetHitEffectID()
    return self._hitEffectID
end

function SkillPhaseParam_GridRange:GetScopeCenterType()
    return self._scopeCenterType
end


function SkillPhaseParam_GridRange:GetScapeType()
    return self._scopeType
end

function SkillPhaseParam_GridRange:GetScapeParam()
    return self._scopeParam
end

function SkillPhaseParam_GridRange:GetSortCenterType()
    return self._sortCenterType
end

function SkillPhaseParam_GridRange:GetSortCenterPos()
    return self._sortCenterPos
end

function SkillPhaseParam_GridRange:GetTargetType()
    return self._targetType
end
