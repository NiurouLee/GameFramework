--[[
 
]]
_class("BuffLogicRefreshBoardPreview", BuffLogicBase)
---@class BuffLogicRefreshBoardPreview:BuffLogicBase
BuffLogicRefreshBoardPreview = BuffLogicRefreshBoardPreview

function BuffLogicRefreshBoardPreview:Constructor(buffInstance, logicParam)
end

function BuffLogicRefreshBoardPreview:DoLogic()
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
end
