--[[
    棋盘数据
]]
_class("DataBoardLogicResult", Object)
---@class DataBoardLogicResult : Object
DataBoardLogicResult = DataBoardLogicResult

function DataBoardLogicResult:Constructor()
    self._prismPieces = nil
    self._prismEntityIDs = nil
    self._pieceTypes = nil
    self._blockFlags = nil
    self._pieceTable = nil
    self._pieceEntities = nil
    self._previewTeamEntityID = nil
end

function DataBoardLogicResult:SetPrismPieces(t)
    self._prismPieces = t
end

function DataBoardLogicResult:GetPrismPieces()
    return self._prismPieces
end

function DataBoardLogicResult:SetPrismEntityIDs(t)
    self._prismEntityIDs = t
end

function DataBoardLogicResult:GetPrismEntityIDs()
    return self._prismEntityIDs
end

function DataBoardLogicResult:SetPieceTypes(t)
    self._pieceTypes = t
end

function DataBoardLogicResult:GetPieceTypes()
    return self._pieceTypes
end

function DataBoardLogicResult:SetBlockFlags(t)
    self._blockFlags = t
end

function DataBoardLogicResult:GetBlockFlags()
    return self._blockFlags
end

function DataBoardLogicResult:SetPieceTable(t)
    self._pieceTable = t
end

function DataBoardLogicResult:GetPieceTable()
    return self._pieceTable
end

function DataBoardLogicResult:SetImmuneHitbacks(ids)
    self._immuneHitbacks=ids
end

function DataBoardLogicResult:GetImmuneHitbacks()
    return self._immuneHitbacks
end

function DataBoardLogicResult:SetPieceEntities(t)
    self._pieceEntities=t
end

function DataBoardLogicResult:GetPieceEntities()
    return self._pieceEntities
end
