--[[
    舒摩尔血量同步UI特殊处理开关
]]
_class("BuffLogicHandleShumolHPUI", BuffLogicBase)
BuffLogicHandleShumolHPUI = BuffLogicHandleShumolHPUI

function BuffLogicHandleShumolHPUI:Constructor(buffInstance, logicParam)
    self._val = logicParam.val
end

function BuffLogicHandleShumolHPUI:DoLogic(notify)
    self._world:BattleStat():SetHandleShumolHPUI(self._val)
end
