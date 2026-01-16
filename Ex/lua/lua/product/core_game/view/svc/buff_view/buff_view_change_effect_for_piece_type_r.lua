--[[
    
]]
_class("BuffViewChangeEffectForPieceType", BuffViewBase)
---@class BuffViewChangeEffectForPieceType : BuffViewBase
BuffViewChangeEffectForPieceType = BuffViewChangeEffectForPieceType

---@param notify NTGridConvert
function BuffViewChangeEffectForPieceType:PlayView(TT, notify)
    ---@type BuffResultChangeEffectForPieceType
    local result = self._buffResult
    local pos = result:GetPos()
    local beforePieceType = result:GetBeforePieceType()
    local afterPieceType = result:GetAfterPieceType()

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")

    if beforePieceType == 0 then
        trapServiceRender:OnClosePreviewPrismEffectTrap(pos)
    end
    trapServiceRender:SetPrismEffectTrapShow(pos, beforePieceType, afterPieceType, true)
end

--是否匹配参数
---@param notify NTGridConvert
function BuffViewChangeEffectForPieceType:IsNotifyMatch(notify)
    -- local notifyType = notify:GetNotifyType()
    -- if notifyType ~= NotifyType.GridConvert then
    --     return false
    -- end

    ---@type BuffResultChangeEffectForPieceType
    local result = self._buffResult
    local notifyType = result:GetNotifyType()
    local pos = result:GetPos()
    local beforePieceType = result:GetBeforePieceType()
    local afterPieceType = result:GetAfterPieceType()

    if notifyType ~= notify:GetNotifyType() then
        return false
    end

    if notifyType == NotifyType.GridConvert then
        ---@type NTGridConvert_ConvertInfo
        local convertInfo = notify:GetConvertInfoAt(pos)
        if not convertInfo then
            return false
        end
    end

    return true
end
