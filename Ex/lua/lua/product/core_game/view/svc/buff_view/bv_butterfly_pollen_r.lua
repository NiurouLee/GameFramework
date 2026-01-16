_class("BuffViewButterflyPollen", BuffViewBase)
---@class BuffViewButterflyPollen:BuffViewBase
---@field _buffResult BuffResultButterflyPollen
BuffViewButterflyPollen = BuffViewButterflyPollen

function BuffViewButterflyPollen:PlayView(TT)
    local poisonDamageInfo = self._buffResult:GetPoisonDamageInfo()
    if poisonDamageInfo then
        ---@type PlayBuffService
        local playBuffSvc = self._world:GetService("PlayBuff")
        playBuffSvc:PlayDamageBuff(TT, self)
    end

    local recoveryDamageInfo = self._buffResult:GetRecoveryDamageInfo()
    if recoveryDamageInfo then
        ---@type PlayDamageService
        local playDamageService = self._world:GetService("PlayDamage")
        playDamageService:AsyncUpdateHPAndDisplayDamage(self._entity, recoveryDamageInfo)
    end
end
