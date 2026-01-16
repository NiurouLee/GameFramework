--[[
    传递伤害表现
]]
_class("BuffViewChainDamage", BuffViewBase)
---@class BuffViewChainDamage : BuffViewBase
BuffViewChainDamage = BuffViewChainDamage

function BuffViewChainDamage:PlayView(TT)
    ---@type BuffResultChainDamage
    local result = self._buffResult

    local entity = self._entity

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
    local baseAnim
    if viewParams then
        baseAnim = viewParams.baseAnim
    end

    for i = 1, #targetIDList do
        local targetEntity = self._world:GetEntityByID(targetIDList[i])

        ---@type DamageInfo
        local damageInfo = damageInfoList[i]
        local damageType = damageInfo:GetDamageType()
        local targetDamage = damageInfo:GetDamageValue()

        if baseAnim then
            local damageAnim = baseAnim .. viewParams.damageAnim
            local damageFinishAnim = baseAnim .. viewParams.damageFinishAnim
            local recoverAnim = baseAnim .. viewParams.recoverAnim
            local recoverFinishAnim = baseAnim .. viewParams.recoverFinishAnim
            local animTime = viewParams.animTime

            --需要确定链子特效是在传递双方中谁的身上

            --特效拥有者
            local lineEffectOwner = nil
            local lineEffect = self:_OnGetLineEffect(viewParams, targetEntity, true)
            if not lineEffect then
                lineEffect = self:_OnGetLineEffect(viewParams, entity, true)
            end

            if lineEffect then
                local go = lineEffect:View():GetGameObject()
                --破碎动画
                ---@type UnityEngine.Animation
                local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))

                if anim then
                    local animation = ""
                    local animationFinish = ""
                    if damageType == DamageType.Recover or damageType == DamageType.RecoverTransmit then
                        animation = recoverAnim
                        animationFinish = recoverFinishAnim
                    else
                        animation = damageAnim
                        animationFinish = damageFinishAnim
                    end

                    GameGlobal.TaskManager():StartTask(
                        function(TT)
                            anim:Play(animation)

                            YIELD(TT, animTime)

                            if go and go ~= null and anim and anim ~= null then
                                anim:Play(animationFinish)
                            end
                        end,
                        self
                    )
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
function BuffViewChainDamage:IsNotifyMatch(notify)
    ---@type BuffResultChainDamage
    local result = self._buffResult
    if result:GetOriginalAttackerID() ~= notify:GetDamageSrcEntityID() then
        return false
    end

    if notify.GetAttackPos and result:GetAttackPos() ~= notify:GetAttackPos() then
        return false
    end

    local notifyHp = result:GetNotifyHp()
    if notifyHp and notify.GetChangeHP and notifyHp ~= notify:GetChangeHP() then
        return false
    end

    return true
end

function BuffViewChainDamage:_OnGetLineEffect(viewParams, entity, isCaster)
    --如果是队伍换成队长
    if entity:HasTeam() then
        entity = entity:GetTeamLeaderPetEntity()
    end

    ---@type EffectHolderComponent
    local effectHolderCmpt = entity:EffectHolder()
    if not effectHolderCmpt then
        return
    end

    ---@type EffectLineRendererComponent
    local effectLineRenderer = entity:EffectLineRenderer()
    if not effectLineRenderer then
        return
    end
    local defenderID = effectLineRenderer:GetTargetEntityID()
    local casterEntityID = effectLineRenderer:GetCasterEntityID()

    if isCaster == false and casterEntityID == entity:GetID() and defenderID ~= entity:GetID() then
        return
    end

    local lineEffectID = viewParams.lineEffectID
    local lineEffect = nil
    local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[lineEffectID]
    if effectEntityIdList then
        lineEffect = self._world:GetEntityByID(effectEntityIdList[1])
    end

    return lineEffect
end
