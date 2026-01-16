--[[------------------------------------------------------------------------------------------
    ClientMirageRoleTurnSystem_Render：幻境阶段的角色回合 用于处理角色移动
]] --------------------------------------------------------------------------------------------

require "mirage_role_turn_system"

---@class ClientMirageRoleTurnSystem_Render:MirageRoleTurnSystem
_class("ClientMirageRoleTurnSystem_Render", MirageRoleTurnSystem)
ClientMirageRoleTurnSystem_Render = ClientMirageRoleTurnSystem_Render

function ClientMirageRoleTurnSystem_Render:_DoRenderMirageMove(TT)
    ---@type MirageServiceRender
    local mirageSvcRender = self._world:GetService("MirageRender")
    mirageSvcRender:DoMiragePlayTeamMove(TT)
end
