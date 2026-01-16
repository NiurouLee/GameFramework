--[[------------------------------------------------------------------------------------------
    刷新棋盘技能效果参数
]]
--------------------------------------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillEffectRefreshGridByBoardIDParam: SkillEffectParamBase
_class("SkillEffectRefreshGridByBoardIDParam", SkillEffectParamBase)
SkillEffectRefreshGridByBoardIDParam = SkillEffectRefreshGridByBoardIDParam

function SkillEffectRefreshGridByBoardIDParam:Constructor(t)
    ---cfg_board中的ID 用于生成地板
    self._boardID = t.boardID
end

function SkillEffectRefreshGridByBoardIDParam:GetEffectType()
    return SkillEffectType.RefreshGridByBoardID
end

function SkillEffectRefreshGridByBoardIDParam:GetBoardID()
    return self._boardID
end
