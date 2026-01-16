--[[
    
]]
_class("BuffLogicChangeEffectForPieceType", BuffLogicBase)
---@class BuffLogicChangeEffectForPieceType:BuffLogicBase
BuffLogicChangeEffectForPieceType = BuffLogicChangeEffectForPieceType

function BuffLogicChangeEffectForPieceType:Constructor(buffInstance, logicParam)
end

---@param notify NTGridConvert
function BuffLogicChangeEffectForPieceType:DoLogic(notify)
    local e = self._buffInstance:Entity()
    local gridPos = e:GetGridPosition()

    local pos
    local beforePieceType
    local afterPieceType

    local notifyType = notify:GetNotifyType()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pieceType = utilDataSvc:GetPieceType(gridPos)
    if notifyType == NotifyType.GridConvert then
        ---@type NTGridConvert_ConvertInfo
        local convertInfo = notify:GetConvertInfoAt(gridPos)
        if not convertInfo then
            return
        end

        pos = convertInfo:GetPos()
        if pos ~= gridPos then
            return
        end

        beforePieceType = convertInfo:GetBeforePieceType()
        afterPieceType = convertInfo:GetAfterPieceType()
    elseif
        notifyType == NotifyType.BuffLoad or notifyType == NotifyType.ActiveSkillAttackEnd or
            notifyType == NotifyType.TrapShow
     then
        pos = gridPos
        beforePieceType = 0
        afterPieceType = pieceType
    end

    local buffResult = BuffResultChangeEffectForPieceType:New(notifyType, pos, beforePieceType, afterPieceType)
    return buffResult
end
