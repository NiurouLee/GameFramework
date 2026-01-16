--[[
    通过buffValue 记录通知内宿主位移的起始位置
]]
--------------------------------
---@class BuffLogicRecordHostOriginalPos:BuffLogicBase
_class("BuffLogicRecordHostOriginalPos", BuffLogicBase)
BuffLogicRecordHostOriginalPos = BuffLogicRecordHostOriginalPos

function BuffLogicRecordHostOriginalPos:DoLogic(notify)
    local notifyType = notify:GetNotifyType()
    if notifyType ~= NotifyType.HitBackEnd and notifyType ~= NotifyType.TractionEnd then
        return
    end

    ---@type BuffComponent
    local buffComponent = self._entity:BuffComponent()
    if not buffComponent then
        return
    end

    if not notify.GetPosStart then
        return
    end

    local pos = notify:GetPosStart()
    if pos then
        buffComponent:SetBuffValue("HostOriginalPos", pos)
    end
end
