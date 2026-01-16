--[[
    HandleBeHitParam：通用受击表现的统一参数对象

    参见MSG33431：内部所有set函数以SetHandleBeHitParam_开头，get函数以GetHandleBeHitParam_
]]


_class("HandleBeHitParam", Object)
---@class HandleBeHitParam : Object
---@field New fun():HandleBeHitParam
HandleBeHitParam = HandleBeHitParam

function HandleBeHitParam:SetHandleBeHitParam_HitCasterEntity(entity)
    self.hitCasterEntity = entity
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_HitCasterEntity()
    return self.hitCasterEntity
end

function HandleBeHitParam:SetHandleBeHitParam_CasterEntity(casterEntity)
    self.casterEntity = casterEntity
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_CasterEntity() return self.casterEntity end

function HandleBeHitParam:SetHandleBeHitParam_TargetEntity(targetEntity)
    self.targetEntity = targetEntity
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_TargetEntity() return self.targetEntity end

function HandleBeHitParam:SetHandleBeHitParam_HitAnimName(hitAnimName)
    self.hitAnimName = hitAnimName
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_HitAnimName() return self.hitAnimName end

function HandleBeHitParam:SetHandleBeHitParam_HitEffectID(hitEffectID)
    self.hitEffectID = hitEffectID
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_HitEffectID() return self.hitEffectID end

function HandleBeHitParam:SetHandleBeHitParam_DamageInfo(damageInfo)
    self.damageInfo = damageInfo
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_DamageInfo() return self.damageInfo end

function HandleBeHitParam:SetHandleBeHitParam_DamagePos(damagePos)
    self.damagePos = damagePos
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_DamagePos() return self.damagePos end

function HandleBeHitParam:SetHandleBeHitParam_HitTurnTarget(hitTurnTarget)
    -- 配置里也有这么写的，所以直接在这里做转换
    if hitTurnTarget == true then
        hitTurnTarget = TurnToTargetType.Caster
    elseif hitTurnTarget == false then
        hitTurnTarget = TurnToTargetType.None
    end

    self.hitTurnTarget = hitTurnTarget
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_HitTurnTarget() return self.hitTurnTarget end

function HandleBeHitParam:SetHandleBeHitParam_DeathClear(deathClear)
    self.deathClear = deathClear
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_DeathClear() return self.deathClear end

function HandleBeHitParam:SetHandleBeHitParam_IsFinalHit(isFinalHit)
    self.isFinalHit = isFinalHit
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_IsFinalHit() return self.isFinalHit end

function HandleBeHitParam:SetHandleBeHitParam_SkillID(skillID)
    self.skillID = skillID
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_SkillID() return self.skillID end

function HandleBeHitParam:SetHandleBeHitParam_HitBackSpeed(hitBackSpeed)
    self.hitBackSpeed = hitBackSpeed
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_HitBackSpeed() return self.hitBackSpeed end

function HandleBeHitParam:SetHandleBeHitParam_DamageIndex(damageIndex)
    self.damageIndex = damageIndex
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_DamageIndex() return self.damageIndex end

function HandleBeHitParam:SetHandleBeHitParam_PlayHitBack(isPlayHitBack)
    self.isPlayHitBack = isPlayHitBack
    return self
end

function HandleBeHitParam:GetHandleBeHitParam_PlayHitBack()
    if self.isPlayHitBack == nil then
        --默认需要播放击退
        self.isPlayHitBack = true
    end

    return self.isPlayHitBack
end
