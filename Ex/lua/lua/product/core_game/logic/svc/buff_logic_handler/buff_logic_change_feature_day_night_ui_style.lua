--[[
    改昼夜模块ui样式（夜王三阶段）
]]
---@class BuffLogicChangeFeatureDayNightUiStyle:BuffLogicBase
_class("BuffLogicChangeFeatureDayNightUiStyle", BuffLogicBase)
BuffLogicChangeFeatureDayNightUiStyle = BuffLogicChangeFeatureDayNightUiStyle

function BuffLogicChangeFeatureDayNightUiStyle:Constructor(buffInstance, logicParam)
    self._uiStyle = logicParam.uiStyle or UIFeatureDayNightStyle.Normal
end

function BuffLogicChangeFeatureDayNightUiStyle:DoLogic()
    local buffResult = BuffResultChangeFeatureDayNightUiStyle:New(self._uiStyle)
    return buffResult
end

