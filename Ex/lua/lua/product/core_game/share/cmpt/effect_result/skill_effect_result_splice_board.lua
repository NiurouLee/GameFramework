require("skill_effect_result_base")

_class("SkillEffectResultSpliceBoard", SkillEffectResultBase)
---@class SkillEffectResultSpliceBoard: SkillEffectResultBase
SkillEffectResultSpliceBoard = SkillEffectResultSpliceBoard

function SkillEffectResultSpliceBoard:Constructor()
    self._moveEntities = {}
    self._spliceBoardPrism = {}
    self._convertColors = {}
    self._spliceBoardGrid = {}
    self._destroyTrapList = {}
    self._spliceBoardOnlyPlayDark = {}
end

function SkillEffectResultSpliceBoard:GetEffectType()
    return SkillEffectType.SpliceBoard
end

---位移的entity
function SkillEffectResultSpliceBoard:AddMoveEntity(eid, oldPos, newPos)
    table.insert(self._moveEntities, {eid, oldPos, newPos})
end

function SkillEffectResultSpliceBoard:GetMoveEntities()
    return self._moveEntities
end

---位移的棱镜
function SkillEffectResultSpliceBoard:AddSpliceBoardPrism(oldPos, newPos)
    table.insert(self._spliceBoardPrism, {oldPos, newPos})
end

function SkillEffectResultSpliceBoard:GetSpliceBoardPrisms()
    return self._spliceBoardPrism
end

---转色
function SkillEffectResultSpliceBoard:AddConvertColor(oldPos, newPos, newPieceType, isAddGrid, isRemoveGrid)
    table.insert(self._convertColors, {oldPos, newPos, newPieceType, isAddGrid, isRemoveGrid})
end

function SkillEffectResultSpliceBoard:GetConvertColors()
    return self._convertColors
end

function SkillEffectResultSpliceBoard:SetPieceTable(pieceTable)
    self._pieceTable = pieceTable
end

function SkillEffectResultSpliceBoard:GetPieceTable()
    return self._pieceTable
end

function SkillEffectResultSpliceBoard:SetMoveParam(distance, direction)
    self._distance = distance
    self._direction = direction
end

function SkillEffectResultSpliceBoard:GetMoveParam()
    return self._distance, self._direction
end

function SkillEffectResultSpliceBoard:AddSpliceBoardGrid(pos, isAddGrid, isRemoveGrid, pieceType, isPrism)
    table.insert(self._spliceBoardGrid, {pos, isAddGrid, isRemoveGrid, pieceType, isPrism})
end

function SkillEffectResultSpliceBoard:GetSpliceBoardGrid()
    return self._spliceBoardGrid
end

function SkillEffectResultSpliceBoard:SetDestroyTrapList(destroyTrapList)
    self._destroyTrapList = destroyTrapList
end

function SkillEffectResultSpliceBoard:GetDestroyTrapList()
    return self._destroyTrapList
end

function SkillEffectResultSpliceBoard:SetNotifyStartTrapEntityID(trapEntityID)
    self._notifyStartTrapEntityID = trapEntityID
end

function SkillEffectResultSpliceBoard:GetNotifyStartTrapEntityID()
    return self._notifyStartTrapEntityID
end

function SkillEffectResultSpliceBoard:SetNotifyEndTrapEntityID(trapEntityID)
    self._notifyEndTrapEntityID = trapEntityID
end

function SkillEffectResultSpliceBoard:GetNotifyEndTrapEntityID()
    return self._notifyEndTrapEntityID
end

function SkillEffectResultSpliceBoard:AddSpliceBoardOnlyPlayDark(pos)
    table.insert(self._spliceBoardOnlyPlayDark, pos)
end

function SkillEffectResultSpliceBoard:GetSpliceBoardOnlyPlayDark()
    return self._spliceBoardOnlyPlayDark
end
