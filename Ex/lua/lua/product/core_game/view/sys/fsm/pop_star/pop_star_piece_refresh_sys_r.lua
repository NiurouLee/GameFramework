--[[------------------------------------------------------------------------------------------
    PopStarPieceRefreshSystem_Render：客户端实现格子刷新表现
]]
--------------------------------------------------------------------------------------------

require "pop_star_piece_refresh_system"

---@class PopStarPieceRefreshSystem_Render:PopStarPieceRefreshSystem
_class("PopStarPieceRefreshSystem_Render", PopStarPieceRefreshSystem)
PopStarPieceRefreshSystem_Render = PopStarPieceRefreshSystem_Render

---@param result DataPopStarResult
function PopStarPieceRefreshSystem_Render:_DoRenderFillPiece(TT, result)
    if not result then
        return
    end

    ---@type PopStarServiceRender
    local popStarRSvc = self._world:GetService("PopStarRender")
    popStarRSvc:PlayPopStarResult(TT, result)
end
