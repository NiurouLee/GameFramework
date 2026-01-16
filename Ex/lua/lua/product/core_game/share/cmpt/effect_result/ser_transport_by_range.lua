--[[
    ----------------------------------------------------------------
    SkillEffectResultTransportByRange
    ----------------------------------------------------------------
]]
require("skill_effect_result_base")


_class("SkillEffectResultTransportByRange", SkillEffectResultBase)
---@class SkillEffectResultTransportByRange: SkillEffectResultBase
SkillEffectResultTransportByRange = SkillEffectResultTransportByRange

function SkillEffectResultTransportByRange:Constructor()
    ---@type TransportByRangePieceData[]
    self._pieceDataList ={}
    ---@type DirectionType
    self._transportDirType =nil
    self._targetID = nil
    self._targetNextPos = nil
    self._targetOldPos = nil
    self._edgeBegin = nil
    self._edgeEnd = nil
    ---@type Vector2[]
    self._resetGridPosList = nil
    ---@type TransportByRangePieceData[]
    self._resetGridPieceDataList=nil
    self._outlineRange={}
end

function SkillEffectResultTransportByRange:SetOutlineRange(range)
    self._outlineRange = range
end

function SkillEffectResultTransportByRange:GetOutlineRange()
    return self._outlineRange
end

function SkillEffectResultTransportByRange:SetResetGridPosList(posList)
    self._resetGridPosList = posList
end
---@return  Vector2[]
function SkillEffectResultTransportByRange:GetResetGridPosList()
    return self._resetGridPosList
end

function SkillEffectResultTransportByRange:SetResetGridPieceDataList(dataList)
    self._resetGridPieceDataList = dataList
end
---@return TransportByRangePieceData[]
function SkillEffectResultTransportByRange:GetResetGridPieceDataList()
    return self._resetGridPieceDataList
end

---@param pieceData TransportByRangePieceData
function SkillEffectResultTransportByRange:AddPieceData(pieceData)
    table.insert(self._pieceDataList,pieceData)
end
---@return DirectionType
function SkillEffectResultTransportByRange:GetTransportDir()
    return self._transportDirType
end

function SkillEffectResultTransportByRange:SetTransportDir(dirType)
    self._transportDirType = dirType
end

---@return TransportByRangePieceData[]
function SkillEffectResultTransportByRange:GetPieceDataList()
    return self._pieceDataList
end

function SkillEffectResultTransportByRange:AddTargetData(targetID,oldPos,nextPos)
    self._targetID = targetID
    self._targetNextPos = nextPos
    self._targetOldPos = oldPos
end

function SkillEffectResultTransportByRange:GetTargetData()
    return self._targetID,self._targetOldPos,self._targetNextPos
end

function SkillEffectResultTransportByRange:GetEffectType()
    return SkillEffectType.TransportByRange
end

function SkillEffectResultTransportByRange:SetEdge(edgeBegin,edgeEnd)
    self._edgeBegin = edgeBegin
    self._edgeEnd = edgeEnd
end

function SkillEffectResultTransportByRange:GetEdge()
    return self._edgeBegin,self._edgeEnd
end




_class("TransportByRangePieceData", Object)
---@class TransportByRangePieceData:Object
TransportByRangePieceData = TransportByRangePieceData

function TransportByRangePieceData:Constructor(pos,pieceType,nextPos)
    self._pos = pos
    self._pieceType = pieceType
    self._nextPos = nextPos
end

function TransportByRangePieceData:GetPiecePos()
    return self._pos
end

function TransportByRangePieceData:GetPieceType()
    return self._pieceType
end

function TransportByRangePieceData:GetNextPos()
    return self._nextPos
end