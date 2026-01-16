--[[
    传递伤害表现
]]
_class("BuffViewTransmitDamage", BuffViewBase)
BuffViewTransmitDamage = BuffViewTransmitDamage

function BuffViewTransmitDamage:PlayView(TT)
    ---@type BuffResultTransmitDamage
    local result = self._buffResult

    --扣血飘字和刷新血条
    local targetIDList = result:GetDefenderIDs()
    ---@type DamageInfo
    local damageInfoList = result:GetDamageInfos()
    if not targetIDList or not damageInfoList then
        return
    end
    if table.count(targetIDList) ~= table.count(damageInfoList) then
        return
    end

    local viewParams = self._viewInstance:BuffConfigData():GetViewParams()
    local hitEffectID = 0
    if viewParams then
        hitEffectID = viewParams.HitEffectId
    end

    for i = 1, #targetIDList do
        local targetEntity = self._world:GetEntityByID(targetIDList[i])

        ---@type DamageInfo
        local damageInfo = damageInfoList[i]
        local damageType = damageInfo:GetDamageType()
        local targetDamage = damageInfo:GetDamageValue()

        if hitEffectID > 0 then
            ---@type Entity
            local effectEntity = self._world:GetService("Effect"):CreateBeHitEffect(hitEffectID, targetEntity)
            YIELD(TT)
            local view = self._entity:View()
            if view then
                local tran = view:GetGameObject().transform
                local castPos = tran.position
                local targetPos = targetEntity:Location().Position
                local dir = targetPos - castPos
                if effectEntity:View() then
                    effectEntity:View():GetGameObject().transform.forward = dir
                end
            end
        end

        damageInfo:SetShowType(DamageShowType.Single)
        ---@type PlayDamageService
        local svc = self._world:GetService("PlayDamage")

        --伤害飘字
        svc:AsyncUpdateHPAndDisplayDamage(targetEntity, damageInfo)
    end
end

--是否匹配参数
---@param notify NTMonsterHPCChange
function BuffViewTransmitDamage:IsNotifyMatch(notify)
    ---@type BuffResultTransmitDamage
    local result = self._buffResult
    if result:GetOriginalAttackerID() ~= notify:GetDamageSrcEntityID() then
        return false
    end

    if notify.GetAttackPos and result:GetAttackPos() ~= notify:GetAttackPos() then
        return false
    end

    return true
end
