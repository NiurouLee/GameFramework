--[[
    扣血效果
]]
_class("BuffViewCostHPBySanChangeDebt", BuffViewBase)
---@class BuffViewCostHPBySanChangeDebt:BuffViewBase
BuffViewCostHPBySanChangeDebt = BuffViewCostHPBySanChangeDebt

function BuffViewCostHPBySanChangeDebt:IsNotifyMatch(notify)
    ---@type NTSanValueChange
    local nt = self._buffResult:GetLogicNotify()
    if (nt and notify and
            nt:GetNotifyType() == NotifyType.SanValueChange and
            notify:GetNotifyType() == NotifyType.SanValueChange) then
        local ntTimes = nt:GetModifyTimes()
        local notifyTimes = notify:GetModifyTimes()
        return (ntTimes == notifyTimes)
    end
end

function BuffViewCostHPBySanChangeDebt:PlayView(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end
