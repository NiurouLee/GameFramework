--[[------------------------------------------------------------------------------------------
    SkillPreviewScopeParam : 技能预览范围数据
]] --------------------------------------------------------------------------------------------
require("skill_scope_filter_param")

_class("SkillPreviewScopeParam", Object)
---@class SkillPreviewScopeParam: Object
SkillPreviewScopeParam = SkillPreviewScopeParam

function SkillPreviewScopeParam:Constructor(t)
    self._targetType = t.TargetType
    self._scopeType = t.ScopeType
    self._scopeCenterType = t.ScopeCenterType
    self._scopeParamData = nil
    self._onlyCanMove = t.OnlyCanMove or false
    self._notDoor = t.NotDoor or false --排除旋涡
    self._notExit = t.NotExit or false --排除出口
	self._canConvert = t.CanConvert or false
	self._targetTypeParam = t.TargetTypeParam
    -- 下面这些等想到个好点的办法改一下 TODO
    if
        ((not t.ScopeCasterOccupiedFilter) and (not t.ScopeObstructingTrapFilter) and
            (not t.ScopeMonsterOccupiedPosFilter) and
            (not t.TargetSelectionMode))
     then
        self._scopeFilterParam = SkillScopeFilterParam.GenerateDefaultParam()
    else
        self._scopeFilterParam =
            SkillScopeFilterParam:New(
            {
                scopeCasterOccupiedFilter = t.ScopeCasterOccupiedFilter,
                obstructingTrapFilter = t.ScopeObstructingTrapFilter,
                monsterOccupiedPosFilter = t.ScopeMonsterOccupiedPosFilter,
                targetSelectionMode = t.TargetSelectionMode
            }
        )
    end
end

---@return SkillTargetType
function SkillPreviewScopeParam:GetScopeTargetType()
    return self._targetType
end

function SkillPreviewScopeParam:GetScopeTargetTypeParam()
    return self._targetTypeParam
end

---@return SkillScopeType
function SkillPreviewScopeParam:GetScopeType()
    return self._scopeType
end

---@type SkillScopeCenterType
function SkillPreviewScopeParam:GetScopeCenterType()
    return self._scopeCenterType
end

function SkillPreviewScopeParam:GetScopeParamData()
    return self._scopeParamData
end

function SkillPreviewScopeParam:SetScopeParamData(paramData)
    self._scopeParamData = paramData
end

function SkillPreviewScopeParam:GetOnlyCanMove()
    return self._onlyCanMove
end

---@return SkillScopeFilterParam
function SkillPreviewScopeParam:GetScopeFilterParam()
    return self._scopeFilterParam
end

function SkillPreviewScopeParam:GetNotDoor()
    return self._notDoor
end
function SkillPreviewScopeParam:GetCanConvert()
    return self._canConvert
end

function SkillPreviewScopeParam:GetNotExit()
    return self._notExit
end
