--[[------------------------------------------------------------------------------------------
    ClientChessPetMoveSystem_Render：客户端实现主动技状态的表现部分
]] --------------------------------------------------------------------------------------------

require "chess_pet_move_system"

---@class ClientChessPetMoveSystem_Render:ChessPetMoveSystem
_class("ClientChessPetMoveSystem_Render", ChessPetMoveSystem)
ClientChessPetMoveSystem_Render = ClientChessPetMoveSystem_Render

function ClientChessPetMoveSystem_Render:_DoRenderChessPetMove(TT)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")

    chessSvcRender:DoRenderChessPetPathMove(TT)

    chessSvcRender:ShowCurChessPetEndTurnEffect(TT)
end
