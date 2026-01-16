--[[
    修改消灭星星关卡特殊格子刷新策略ID
]]
require "buff_logic_base"
---@class BuffLogicModifyPopStarTrapRefreshID:BuffLogicBase
_class("BuffLogicModifyPopStarTrapRefreshID", BuffLogicBase)
BuffLogicModifyPopStarTrapRefreshID = BuffLogicModifyPopStarTrapRefreshID

function BuffLogicModifyPopStarTrapRefreshID:Constructor(buffInstance, logicParam)
    self._refreshID = logicParam.refreshID
end

function BuffLogicModifyPopStarTrapRefreshID:DoLogic(notify)
    if not self._refreshID then
        return true
    end

    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    popStarSvc:DoParseTrapRefreshData(self._refreshID)

    return true
end
