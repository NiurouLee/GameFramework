--[[
    刷新格子(玩家为中心 周围8个)
]]
_class("BuffViewRefreshGrid", BuffViewBase)
BuffViewRefreshGrid = BuffViewRefreshGrid

function BuffViewRefreshGrid:PlayView(TT, notify)
    ---@type BuffResultRefreshGrid
    local result = self._buffResult


    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    ---@type PieceServiceRender
    local pieceServiceR = self._world:GetService("Piece")

    for _, pos in pairs(result:GetRefreshList()) do
        boardServiceR:ReCreateGridEntity(result:GetTarget(), pos, false, true)
        pieceServiceR:SetPieceAnimColor(pos)
    end
end
