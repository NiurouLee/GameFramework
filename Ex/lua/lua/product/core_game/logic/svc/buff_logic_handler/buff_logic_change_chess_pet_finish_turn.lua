--[[
    改变棋子的本回合完成行动的状态
]]
_class("BuffLogicChangeChessPetFinishTurn", BuffLogicBase)
---@class BuffLogicChangeChessPetFinishTurn :BuffLogicBase
BuffLogicChangeChessPetFinishTurn = BuffLogicChangeChessPetFinishTurn

---
function BuffLogicChangeChessPetFinishTurn:Constructor(buffInstance, logicParam)
    self._finish = logicParam.finish == 1
end

---
function BuffLogicChangeChessPetFinishTurn:DoLogic()
    ---@type ChessPetComponent
    local chessPetCmpt = self._entity:ChessPet()
    chessPetCmpt:SetChessPetFinishTurn(self._finish)

    local buffResult = BuffResultChangeChessPetFinishTurn:New(self._entity:GetID(), self._finish)
    return buffResult
end
