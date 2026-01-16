--[[------------------------------------------------------------------------------------------
    2020-03-02 韩玉信添加
    SkillPhaseParam_GridDark ： 显示/隐藏角色
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

--- @class SkillPhaseParam_GridDark_Type
local SkillPhaseParam_GridDark_Type = {
    Dark = 0,   --变暗
    Resume = 1, --恢复
}
_enum("SkillPhaseParam_GridDark_Type", SkillPhaseParam_GridDark_Type)
----------------------------------------------------------------
---@class SkillPhaseParam_GridDark: Object
_class("SkillPhaseParam_GridDark", SkillPhaseParamBase)
SkillPhaseParam_GridDark = SkillPhaseParam_GridDark

---@type SkillCommonParam
function SkillPhaseParam_GridDark:Constructor(t)
    self._darkType = t.darkType             --显示参数： 非0是显示，0是隐藏
end

function SkillPhaseParam_GridDark:GetCacheTable()
	local t = {	}
    return t
end

function SkillPhaseParam_GridDark:GetPhaseType()
    return SkillViewPhaseType.GridDark
end

function SkillPhaseParam_GridDark:GetDarkType()
    return self._darkType
end
