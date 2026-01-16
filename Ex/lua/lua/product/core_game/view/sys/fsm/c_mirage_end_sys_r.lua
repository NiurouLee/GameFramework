--[[------------------------------------------------------------------------------------------
    ClientMirageEndSystem_Render：幻境结束的客户端表现
]] --------------------------------------------------------------------------------------------

require "mirage_end_system"

---@class ClientMirageEndSystem_Render:MirageEndSystem
_class("ClientMirageEndSystem_Render", MirageEndSystem)
ClientMirageEndSystem_Render = ClientMirageEndSystem_Render

function ClientMirageEndSystem_Render:_DoRenderMirageClearWarningArea(TT)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:DoMirageClearWarningArea()
end

function ClientMirageEndSystem_Render:_DoRenderForceCastTrapSkill(TT, eTraps)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:DoMiragePlayTrapSkill(TT, eTraps)
end

function ClientMirageEndSystem_Render:_DoRenderMiragePlayTrapDieSkill(TT, eTraps)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:DoMiragePlayTrapDieSkill(TT, eTraps)
end

function ClientMirageEndSystem_Render:_DoRenderMirageBossReturn(TT, bossEntity)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:DoMiragePlayBossReturn(TT, bossEntity)
end

function ClientMirageEndSystem_Render:_DoRenderMirageEndUI(TT)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowMirageEnterUI, false)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:SetMirageStepVisible(false)

    ---@type MiragePickUpComponent
    local pickUpCmpt = self._world:MiragePickUp()
    pickUpCmpt:GetCurPickUpGridPos(Vector2.zero)
end
