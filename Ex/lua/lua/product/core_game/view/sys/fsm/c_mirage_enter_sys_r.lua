--[[------------------------------------------------------------------------------------------
    ClientMirageEnterSystem_Render：主状态机进入幻境阶段的客户端表现
]] --------------------------------------------------------------------------------------------

require "mirage_enter_system"

---@class ClientMirageEnterSystem_Render:MirageEnterSystem
_class("ClientMirageEnterSystem_Render", MirageEnterSystem)
ClientMirageEnterSystem_Render = ClientMirageEnterSystem_Render

function ClientMirageEnterSystem_Render:_DoRenderMirageEnterUI(TT, initStepNum)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowMirageEnterUI, true)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:SetMirageStepVisible(true)
    mirageRenderSvc:RefreshMirageStepNum(initStepNum)
end

function ClientMirageEnterSystem_Render:_DoRenderMirageShowTraps(TT, traps)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:DoMirageShowTraps(TT, traps)
end

function ClientMirageEnterSystem_Render:_DoRenderMiragePlayTrapWarningSkill(TT, traps)
    ---@type MirageServiceRender
    local mirageSvcRender = self._world:GetService("MirageRender")
    mirageSvcRender:DoMiragePlayTrapWarningSkill(TT, traps)
end
