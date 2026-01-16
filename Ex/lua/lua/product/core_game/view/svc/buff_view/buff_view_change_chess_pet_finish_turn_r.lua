--[[
    改变棋子的本回合完成行动的状态
]]
_class("BuffViewChangeChessPetFinishTurn", BuffViewBase)
BuffViewChangeChessPetFinishTurn = BuffViewChangeChessPetFinishTurn

---
function BuffViewChangeChessPetFinishTurn:PlayView(TT)
    ---@type BuffResultChangeChessPetFinishTurn
    local result = self:GetBuffResult()

    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:RefreshChessPetFinishStateRender(result:GetEntityID(), result:GetFinish())
end
