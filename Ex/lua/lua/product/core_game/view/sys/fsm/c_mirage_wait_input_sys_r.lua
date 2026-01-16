--[[------------------------------------------------------------------------------------------
    ClientMirageWaitInputSystem_Render：等待玩家输入的客户端表现
]] --------------------------------------------------------------------------------------------

require "mirage_wait_input_system"

---@class ClientMirageWaitInputSystem_Render:MirageWaitInputSystem
_class("ClientMirageWaitInputSystem_Render", MirageWaitInputSystem)
ClientMirageWaitInputSystem_Render = ClientMirageWaitInputSystem_Render

function ClientMirageWaitInputSystem_Render:_DoRenderResetBattleState(TT)
end

function ClientMirageWaitInputSystem_Render:_DoRenderPieceAnimation(TT)
    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")

    piece_service:RefreshPieceAnim()
    piece_service:RefreshMonsterAreaOutLine(TT)

    piece_service:SetAllPieceDark()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local roundGrids = utilData:GetRoundGrid(teamEntity:GetGridPosition())
    for _, gridPos in ipairs(roundGrids) do
        piece_service:SetPieceAnimNormal(gridPos)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowMirageChooseGrid, true)
end

function ClientMirageWaitInputSystem_Render:_DoRenderCompareHPLog(TT)
    -- ---暂时关闭，等稳定再打开
    -- local openException = false
    -- --比对逻辑表现血量
    -- self:_CompareLogicRenderHP(openException)
end

function ClientMirageWaitInputSystem_Render:_DoRenderComparePieceType(TT)
    -- if not EDITOR then
    --     return
    -- end

    -- local cPreviewEnv = self._world:GetPreviewEntity():PreviewEnv()

    -- local cPreviewPieceTypeIndexMap = cPreviewEnv._pieceTypes
    -- local cPreviewAllPiece = cPreviewEnv:GetAllPieceType()

    -- local previewPieceDiff = {}
    -- for posIndex, pieceType in pairs(cPreviewPieceTypeIndexMap) do
    --     local x = posIndex // 100
    --     local y = posIndex - (x * 100)

    --     if (not cPreviewAllPiece[x]) then
    --         table.insert(previewPieceDiff, { posIndex = posIndex, err = "not found in all piece table" })
    --     elseif cPreviewAllPiece[x][y] ~= pieceType then
    --         table.insert(
    --             previewPieceDiff,
    --             {
    --                 posIndex = posIndex,
    --                 err = string.format(
    --                     "different color: _pieceType->%s, _allPieceTable->%s",
    --                     tostring(pieceType),
    --                     tostring(cPreviewAllPiece[x][y])
    --                 )
    --             }
    --         )
    --     end
    -- end

    -- local piecePosList = {}
    -- local tePiece = self._world:GetGroupEntities(self._world.BW_WEMatchers.Piece)
    -- for _, ePiece in ipairs(tePiece) do
    --     --这里不判断其他棋盘面的格子颜色
    --     if not ePiece:HasOutsideRegion() then
    --         local cPiece = ePiece:Piece()
    --         local pos = ePiece:GetGridPosition()
    --         local pieceType = cPiece:GetPieceType()
    --         local previewEnvType = cPreviewEnv:GetPieceType(pos)
    --         if pieceType ~= previewEnvType then
    --             if pieceType == 0 and previewEnvType == 5 then
    --                 Log.fatal("player at any piece pos")
    --             else
    --                 table.insert(
    --                     previewPieceDiff,
    --                     {
    --                         posIndex = pos:Pos2Index(),
    --                         err = string.format(
    --                             "different piece color: piece->%s, previewEnv->%s",
    --                             pieceType,
    --                             previewEnvType
    --                         )
    --                     }
    --                 )
    --             end
    --         end
    --         if not table.icontains(piecePosList, pos) then
    --             table.insert(piecePosList, pos)
    --         else
    --             table.insert(
    --                 previewPieceDiff,
    --                 {
    --                     posIndex = pos:Pos2Index(),
    --                     err = "piece entity pos repeat"
    --                 }
    --             )
    --         end
    --     end
    -- end

    -- if #previewPieceDiff ~= 0 then
    --     for _, exception in ipairs(previewPieceDiff) do
    --         Log.error(
    --             "[PieceTypeDiff] err: posIndex=",
    --             tostring(exception.posIndex),
    --             " desc: ",
    --             tostring(exception.err)
    --         )
    --     end
    --     Log.exception("[PieceTypeDiff] PieceType conflict. Check log for more information. ")
    -- end
end
