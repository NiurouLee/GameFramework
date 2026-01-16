--[[
    仲胥 清除 buffvalue CurRoundForceMoveStep (本回合强制位移步数)
]]
_class("BuffLogicClearRecordForceMovementStep", BuffLogicBase)
---@class BuffLogicClearRecordForceMovementStep:BuffLogicBase
BuffLogicClearRecordForceMovementStep = BuffLogicClearRecordForceMovementStep

function BuffLogicClearRecordForceMovementStep:Constructor(buffInstance, logicParam)
end

function BuffLogicClearRecordForceMovementStep:DoLogic()
    local buffValueKey = "CurRoundForceMoveStep"
    self._buffComponent:SetBuffValue(buffValueKey,0)
end
