--[[------------------------------------------------------------------------------------------
    ClientChessPetMoveAndAttackSystem_Render：客户端实现主动技状态的表现部分
]] --------------------------------------------------------------------------------------------

require "chess_pet_move_and_attack_system"

---@class ClientChessPetMoveAndAttackSystem_Render:ChessPetMoveAndAttackSystem
_class("ClientChessPetMoveAndAttackSystem_Render", ChessPetMoveAndAttackSystem)
ClientChessPetMoveAndAttackSystem_Render = ClientChessPetMoveAndAttackSystem_Render

---
function ClientChessPetMoveAndAttackSystem_Render:_DoRenderChessPetMove(TT)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")

    chessSvcRender:DoRenderChessPetPathMove(TT)

end

---
function ClientChessPetMoveAndAttackSystem_Render:_DoRenderChessPetAttack(TT)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")

    local waitTaskID = chessSvcRender:DoRenderChessPetAttack(TT)
    return waitTaskID
end

---
function ClientChessPetMoveAndAttackSystem_Render:_DoRenderSetChessPetDir(TT, chessPetEntity)
    local dir = chessPetEntity:GetGridDirection()
    chessPetEntity:SetDirection(dir)
end

---完成攻击后的表现
function ClientChessPetMoveAndAttackSystem_Render:_DoRenderChessPetFinishAttack(TT)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ShowCurChessPetEndTurnEffect(TT)
end