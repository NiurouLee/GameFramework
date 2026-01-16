--[[------------------------------------------------------------------------------------------
    ClientPreChainSystem_Render 客户端实现连锁前表现阶段
]] --------------------------------------------------------------------------------------------

require "pre_chain_state_system"

---@class ClientPreChainSystem_Render:PreChainStateSystem
_class("ClientPreChainSystem_Render", PreChainStateSystem)
ClientPreChainSystem_Render = ClientPreChainSystem_Render

function ClientPreChainSystem_Render:_PlayPreChainTrapSkill(TT, trapIds)
    --传送前先删掉虚影
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyGhost()

    ---@type TrapServiceRender
    local sTrapRender = self._world:GetService("TrapRender")
    local taskIds = sTrapRender:PlayTrapPreChainSkill(trapIds)
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
        YIELD(TT)
    end
end

---@param listTrapTrigger Entity[]
function ClientPreChainSystem_Render:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity)
    ---@type PlaySkillInstructionService
    local sPlaySkillInstruction = self._world:GetService("PlaySkillInstruction")
    local listTrapTask = sPlaySkillInstruction:PlayTrapTrigger(TT, teamEntity, listTrapTrigger)
    self:_WaitTasksEnd(TT, listTrapTask)
end

function ClientPreChainSystem_Render:_DoRenderResetPickUp()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    pickUpTargetCmpt:Reset()
    renderBoardEntity:ReplacePickUpTarget()
end
