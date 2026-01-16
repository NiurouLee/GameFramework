--[[------------------------------------------------------------------------------------------
    SkillPhaseRoleCGParam : 技能播放Spine动画
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---@class SkillPhaseRoleCGParam: Object
_class("SkillPhaseRoleCGParam", SkillPhaseParamBase)
SkillPhaseRoleCGParam = SkillPhaseRoleCGParam

function SkillPhaseRoleCGParam:Constructor(t)
    self._cgTimeLen = t.cgTimeLen
    self._cgRes = t.cgRes
    self._hideRoleTime = t.hideRoleTime
end

function SkillPhaseRoleCGParam:GetCacheTable()
    --技能播放Spine
    local t = {
        {self._cgRes .. ".prefab", 1}
    }
    return t
end
function SkillPhaseRoleCGParam:GetPhaseType()
    return SkillViewPhaseType.RoleCG
end
function SkillPhaseRoleCGParam:GetCGTimeLen()
    return self._cgTimeLen
end

function SkillPhaseRoleCGParam:GetCGRes()
    return self._cgRes
end

function SkillPhaseRoleCGParam:GetHideRoleTime()
    return self._hideRoleTime
end
