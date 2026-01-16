--[[------------------------------------------------------------------------------------------
    PopStarTrapTurnSystem_Render：客户端实现的怪物行动表现
]]
--------------------------------------------------------------------------------------------

require "pop_star_trap_turn_system"

---@class PopStarTrapTurnSystem_Render:PopStarTrapTurnSystem
_class("PopStarTrapTurnSystem_Render", PopStarTrapTurnSystem)
PopStarTrapTurnSystem_Render = PopStarTrapTurnSystem_Render

function PopStarTrapTurnSystem_Render:_DoRenderTrapState(TT, calcStateTraps)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    trapServiceRender:RenderTrapState(TT, TrapDestroyType.DestroyByRound, calcStateTraps)
end

function PopStarTrapTurnSystem_Render:_DoRenderTrapBeforeMonster(TT)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end

    playAISvc:DoCommonRountine(TT)
end

function PopStarTrapTurnSystem_Render:_DoRenderTrapAfterMonster(TT)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end

    playAISvc:DoCommonRountine(TT)
end

function PopStarTrapTurnSystem_Render:_UpdateTrapGridRound(TT)
    ---@type TrapServiceRender
    local svc = self._world:GetService("TrapRender")
    svc:UpdateTrapGridRound()
end
