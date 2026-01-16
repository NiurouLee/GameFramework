--[[------------------------------------------------------------------------------------------
    PieceComponent : 格子表现数据
]] --------------------------------------------------------------------------------------------

---@class PieceComponent: Object
_class("PieceComponent", Object)
PieceComponent = PieceComponent

function PieceComponent:Constructor(pieceType)
    self.Type = pieceType or PieceType.None
end

---@return PieceType
function PieceComponent:GetPieceType()
    return self.Type
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return PieceComponent
function Entity:Piece()
    return self:GetComponent(self.WEComponentsEnum.Piece)
end

function Entity:HasPiece()
    return self:HasComponent(self.WEComponentsEnum.Piece)
end

function Entity:AddPiece(pieceType)
    local index = self.WEComponentsEnum.Piece
    local component = PieceComponent:New(pieceType)
    self:AddComponent(index, component)
end

function Entity:ReplacePiece(pieceType)
    local index = self.WEComponentsEnum.Piece
    local component = PieceComponent:New(pieceType)
    self:ReplaceComponent(index, component)
end

function Entity:RemovePiece()
    if self:HasPiece() then
        self:RemoveComponent(self.WEComponentsEnum.Piece)
    end
end
