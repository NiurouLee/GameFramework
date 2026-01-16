--[[------------------------------------------------------------------------------------------
    ClientMirageMonsterTurnSystem_Render 幻境子处理子弹机关行动的客户端表现
]] --------------------------------------------------------------------------------------------

require "mirage_monster_turn_system"

_class("ClientMirageMonsterTurnSystem_Render", MirageMonsterTurnSystem)
---@class ClientMirageMonsterTurnSystem_Render:MirageMonsterTurnSystem
ClientMirageMonsterTurnSystem_Render = ClientMirageMonsterTurnSystem_Render

function ClientMirageMonsterTurnSystem_Render:_DoRenderHidePetInfo(TT)
end

function ClientMirageMonsterTurnSystem_Render:_DoRenderMirageClearWarningArea(TT)
    ---@type MirageServiceRender
    local mirageRenderSvc = self._world:GetService("MirageRender")
    mirageRenderSvc:DoMirageClearWarningArea()
end

function ClientMirageMonsterTurnSystem_Render:_DoRenderMiragePlayTrapSkill(TT, traps)
    ---@type MirageServiceRender
    local mirageSvcRender = self._world:GetService("MirageRender")
    mirageSvcRender:DoMiragePlayTrapSkill(TT, traps)
end

function ClientMirageMonsterTurnSystem_Render:_DoRenderMiragePlayTrapWarningSkill(TT, traps)
    ---@type MirageServiceRender
    local mirageSvcRender = self._world:GetService("MirageRender")
    mirageSvcRender:DoMiragePlayTrapWarningSkill(TT, traps)
end
