--[[
    播放中毒buff
]]
_class("BuffViewAddPoison", BuffViewBase)
BuffViewAddPoison = BuffViewAddPoison

function BuffViewAddPoison:PlayView(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)

    local recoverDamageInfos = self._buffResult:GetRecoverDamageInfo()
    --毒性萤火 中毒状态敌人每次毒伤触发时为玩家恢复毒伤量20%的生命值
    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    ---@param recoverDamageInfo DamageInfo
    for i, recoverDamageInfo in ipairs(recoverDamageInfos) do
        local playerEntity = self._world:GetEntityByID(recoverDamageInfo:GetTargetEntityID())
        playDamageService:AsyncUpdateHPAndDisplayDamage(playerEntity, recoverDamageInfo)
    end
end
