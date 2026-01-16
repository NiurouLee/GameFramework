--[[------------------------------------------------------------------------------------------
    2020-02-11 韩玉信添加
    SkillPhaseParam_ShowHideRole ： 显示/隐藏角色
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

--- @class SkillPhaseParam_ShowType
local SkillPhaseParam_ShowType = {
    Hide = 0, ---隐藏
    Show = 1, ---显示
    Replace = 2, ---替换
    Fade = 3 --渐隐/渐显
}
_enum("SkillPhaseParam_ShowType", SkillPhaseParam_ShowType)
----------------------------------------------------------------
---@class SkillPhaseParam_ShowHideRole: Object
_class("SkillPhaseParam_ShowHideRole", SkillPhaseParamBase)
SkillPhaseParam_ShowHideRole = SkillPhaseParam_ShowHideRole

---@type SkillCommonParam
function SkillPhaseParam_ShowHideRole:Constructor(t)
    self._beginDelay = t.beginDelay --延迟显示
    self._showType = t.showType --显示类型： 0是隐藏， 1是显示，2是变身（使用新的prefab）
    self._showParam = t.showParam --显示参数
    self._endDelay = t.endDelay --延迟显示
end

function SkillPhaseParam_ShowHideRole:GetCacheTable()
    local t = {}
    if SkillPhaseParam_ShowType.Replace == self._showType then
        if self._showParam then
            local resPrefab = self._showParam
            t[#t + 1] = {resPrefab, 1}
        -- t[#t + 1] = {Cfg.cfg_effect[nEffectID].ResPath, 1}
        end
    end
    return t
end

function SkillPhaseParam_ShowHideRole:GetPhaseType()
    return SkillViewPhaseType.ShowHideRole
end

function SkillPhaseParam_ShowHideRole:GetBeginDelay()
    return self._beginDelay
end

function SkillPhaseParam_ShowHideRole:GetEndDelay()
    return self._endDelay
end

function SkillPhaseParam_ShowHideRole:GetShowData()
    return self._showType, self._showParam
end
