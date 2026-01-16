--[[
    复数cd技能时，控制某个cd区域显隐（凯雅，二技能中途解锁）
]]

_class("BuffLogicShowHideUiMultiPowerInfoByIndex", BuffLogicBase)
---@class BuffLogicShowHideUiMultiPowerInfoByIndex:BuffLogicBase
BuffLogicShowHideUiMultiPowerInfoByIndex = BuffLogicShowHideUiMultiPowerInfoByIndex
---
function BuffLogicShowHideUiMultiPowerInfoByIndex:Constructor(buffInstance, logicParam)
    self._uiIndex = logicParam.uiIndex or 2
    self._showHide = logicParam.showHide or 1
end
---
function BuffLogicShowHideUiMultiPowerInfoByIndex:DoLogic(notify)
    if self._entity:PetPstID() then --是星灵
        local pstId = self._entity:PetPstID():GetPstID()
        local bShow = (self._showHide == 1)
        local buffResult = BuffResultShowHideUiMultiPowerInfoByIndex:New(pstId,self._uiIndex,bShow)
        return buffResult
    end
end
