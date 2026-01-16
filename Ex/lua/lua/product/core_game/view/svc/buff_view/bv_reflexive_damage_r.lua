--[[
    反伤表现
]]
_class("BuffViewReflexiveDamage", BuffViewBase)
BuffViewReflexiveDamage = BuffViewReflexiveDamage

function BuffViewReflexiveDamage:PlayView(TT)
    ---@type BuffResultReflexiveDamage
    local result = self._buffResult
    --更新护盾数量
    local layer = result:GetLayer()
    if layer and self._entity:PetPstID() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.SetAccumulateNum, self._entity:PetPstID():GetPstID(), layer)
    end
    --扣血飘字和刷新血条
    local targetId = result:GetDefenderID()
    ---@type DamageInfo
    local damageInfo = result:GetDamageInfo()
    if not damageInfo then
        return
    end
    local viewParams = self._viewInstance:BuffConfigData():GetViewParams()
    local targetEntity = self._world:GetEntityByID(targetId)
    local damageType = damageInfo:GetDamageType()
    local targetDamage = damageInfo:GetDamageValue()
    local hitEffectID = 0
    if viewParams then
        hitEffectID = viewParams.HitEffectId
    end

    if damageType == DamageType.Invalid and targetDamage == 0 then
        return
    end

    if damageType == DamageType.Guard then
    else
        -- local hitAnim = "Hit"
        -- targetEntity:SetAnimatorControllerTriggers({hitAnim})
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
    end

    damageInfo:SetShowType(DamageShowType.Single)
    ---@type PlayDamageService
    local svc = self._world:GetService("PlayDamage")

    --表现上的伤害飘字给队员
    local originalAttackerID = result:GetOriginalAttackerID()
    if targetEntity:HasTeam() and originalAttackerID then
        targetEntity = self._world:GetEntityByID(originalAttackerID)
    end

    --伤害飘字
    svc:AsyncUpdateHPAndDisplayDamage(targetEntity, damageInfo)
end

--是否匹配参数
---@param notify NotifyAttackBase
function BuffViewReflexiveDamage:IsNotifyMatch(notify)
    --这里判断 1被反伤的是队伍 2星灵发动攻击的坐标 3防御反击的人 4发动攻击的星灵ID
    ---@type BuffResultReflexiveDamage
    local result = self._buffResult
    if result:GetSkillHolderID() then 
        if result:GetSkillHolderID() == notify:GetAttackerEntity():GetID() then
            return true
        end
    else
        if result:GetOriginalAttackerID() == notify:GetAttackerEntity():GetID() then
            --普攻判断位置，主动技有位移不能判断位置
            if notify:GetSkillType() == SkillType.Normal then
                if result:GetAttackPos() == notify:GetAttackPos() then
                    return true
                else
                    return false
                end
            end
            return true
        end
    end

    return false
end
