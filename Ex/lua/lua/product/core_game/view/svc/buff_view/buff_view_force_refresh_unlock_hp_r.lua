_class("BuffViewForceRefreshUnlockHP", BuffViewBase)
---@class BuffViewForceRefreshUnlockHP:BuffViewBase
BuffViewForceRefreshUnlockHP = BuffViewForceRefreshUnlockHP

function BuffViewForceRefreshUnlockHP:PlayView(TT)
    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    -- if buffView and not buffView:IsAlwaysHPLock() then
    local index = buffView:GetHPLockIndex()
    ---@type HPComponent
    local hpComponent = self._entity:HP()
    if hpComponent:IsShowHPSlider() then
        local sepPoolWidget = hpComponent:GetSepPoolWidget()
        if sepPoolWidget then
            local sepPool = sepPoolWidget:GetAllSpawnList()
            if sepPool and table.count(sepPool) > 0 then
                for i = 1, table.count(sepPool) do
                    sepPool[i]:GetGameObject():SetActive(false)
                end
            end
        end
    end

    --这个只是添加新的  不能清除旧的
    --即时刷新大血条
    -- self._entity:ReplaceInitHPLockSepList({})

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeBossHPLock, index, false)

    ---@type HPComponent
    local hp = self._entity:HP()
    hp:SetHPLockSepList({})

    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTBreakHPLock:New(self._entity))
    buffView:ResetHPLockState()
    -- end
end

function BuffViewForceRefreshUnlockHP:IsNotifyMatch(notify)
    return true
end
