--[[------------------------------------------------------------------------------------------
    2019-12-12 韩玉信添加
    旧版本类名是SkillPhaseShowWarningAreaParam
    SkillPhaseParam_ShowWarningArea : 牵引效果表现参数
]] --------------------------------------------------------------------------------------------
---
---@class WarningCenterPosType
local WarningCenterPosType ={
	CasterPos = 1 , --以施法者为中心这个时候直接使用施法者的坐标
	GridPos = 2,   --固定坐标，使用配置的固定坐标
	CasterPosOffSet = 3 , --针对施法者的偏移量,数值类型
	EffectPos = 4, --效果传入的坐标
}
_enum("WarningCenterPosType",WarningCenterPosType)
require "skill_phase_param_base"

_class("SkillPhaseParam_ShowWarningArea", SkillPhaseParamBase)
---@class SkillPhaseParam_ShowWarningArea: Object
SkillPhaseParam_ShowWarningArea = SkillPhaseParam_ShowWarningArea

---@type SkillCommonParam
function SkillPhaseParam_ShowWarningArea:Constructor(t)
	self._warningCenterPosType = t.warningCenterPosType
	self._warningCenterPosParam = t.warningCenterPosParam

	self._warningTextEffectID = t.warningTextEffectID
	self._areaRes = t.areaRes
    self._hasDeadWarning = t.hasDeadWarning
end

function SkillPhaseParam_ShowWarningArea:GetCacheTable()
	local t = {
		{self._areaRes, 1},
	}
    return t
end

function SkillPhaseParam_ShowWarningArea:GetTextEffectID()
	return self._warningTextEffectID
end

function SkillPhaseParam_ShowWarningArea:GetAreaRes()
	return self._areaRes
end

function SkillPhaseParam_ShowWarningArea:GetWarningCenterPosType()
	return self._warningCenterPosType
end

function SkillPhaseParam_ShowWarningArea:GetPhaseType()
    return SkillViewPhaseType.ShowWarningArea
end

function SkillPhaseParam_ShowWarningArea:GetGridPosList()
	local gridPosList ={}
	for k, v in ipairs(self._warningCenterPosParam) do
		local gridPos =Vector2(v.x,v.y)
		table.insert(gridPosList,gridPos)
	end
	return gridPosList
end

function SkillPhaseParam_ShowWarningArea:GetOffSet()
	return tonumber(self._warningCenterPosParam)
end

function SkillPhaseParam_ShowWarningArea:HasDeadWaring()
    return self._hasDeadWarning
end