--[[
    仲胥 双击处理 恢复形态
]]
_class("BuffLogicZhongxuForceRevertTrans", BuffLogicBase)
---@class BuffLogicZhongxuForceRevertTrans:BuffLogicBase
BuffLogicZhongxuForceRevertTrans = BuffLogicZhongxuForceRevertTrans

function BuffLogicZhongxuForceRevertTrans:Constructor(buffInstance, logicParam)
end

function BuffLogicZhongxuForceRevertTrans:DoLogic()
    local buffResult = BuffResultZhongxuForceRevertTrans:New()
    return buffResult
end
