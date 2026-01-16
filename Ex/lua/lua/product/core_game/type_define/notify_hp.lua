
_class("NTHPCChange", INotifyBase)
---@class NTHPCChange : INotifyBase
NTHPCChange = NTHPCChange

function NTHPCChange:GetNotifyType()
    Log.exception("notify object not have notify type!")
end

---血量是否增长
function NTHPCChange:IsHPIncrease()
    return self._changeHP > 0
end

--region 怪物血量变化
_class("NTMonsterHPCChange", NTHPCChange)
---@class NTMonsterHPCChange : INotifyBase
NTMonsterHPCChange = NTMonsterHPCChange
----@param entity Entity
function NTMonsterHPCChange:Constructor(entity, hp, maxhp, notifyIndex)
    self._ownerEntity = entity
    self.hp = hp
    self.maxhp = maxhp
    self.notifyIndex = notifyIndex
end

function NTMonsterHPCChange:GetNotifyIndex()
    return self.notifyIndex
end

function NTMonsterHPCChange:GetNotifyType()
    return NotifyType.MonsterHPCChange
end

function NTMonsterHPCChange:GetNotifyEntity()
    return self._ownerEntity
end

function NTMonsterHPCChange:GetMaxHP()
    return self.maxhp
end

function NTMonsterHPCChange:GetHP()
    return self.hp
end

function NTMonsterHPCChange:GetHPPercent()
    return self.hp / self.maxhp * 100
end

function NTMonsterHPCChange:SetChangeHP(changeHP)
    self._changeHP = changeHP
end

function NTMonsterHPCChange:GetChangeHP()
    return self._changeHP
end
function NTMonsterHPCChange:SetDamageSrcEntityID(srcID)
    self._damageSrcEntityID = srcID
end
function NTMonsterHPCChange:GetDamageSrcEntityID()
    return self._damageSrcEntityID
end

function NTMonsterHPCChange:SetDamageType(damageType)
    self._damageType = damageType
end

function NTMonsterHPCChange:GetDamageType()
    return self._damageType
end

function NTMonsterHPCChange:SetAttackPos(attackPos)
    self._attackPos = attackPos
end

function NTMonsterHPCChange:GetAttackPos()
    return self._attackPos
end

function NTMonsterHPCChange:SetAttackEntityID(attackEntityID)
    self._attackEntityID = attackEntityID
end

function NTMonsterHPCChange:GetAttackEntityID()
    return self._attackEntityID
end

function NTMonsterHPCChange:SetDamageInfo(damageInfo)
    self._damageInfo = damageInfo
end

function NTMonsterHPCChange:GetDamageInfo()
    return self._damageInfo
end
--endregion 怪物血量变化

--region 机关血量变化
_class("NTTrapHpChange", NTHPCChange)
NTTrapHpChange = NTTrapHpChange
----@param entity Entity
function NTTrapHpChange:Constructor(entity, hp, maxhp)
    self._ownerEntity = entity
    self.hp = hp
    self.maxhp = maxhp
end

function NTTrapHpChange:GetNotifyType()
    return NotifyType.TrapHpChange
end

function NTTrapHpChange:GetNotifyEntity()
    return self._ownerEntity
end

function NTTrapHpChange:GetHP()
    return self.hp
end

function NTTrapHpChange:GetMaxHP()
    return self.maxhp
end

function NTTrapHpChange:GetHPPercent()
    return self.hp / self.maxhp * 100
end

function NTTrapHpChange:SetChangeHP(changeHP)
    self._changeHP = changeHP
end

function NTTrapHpChange:GetChangeHP()
    return self._changeHP
end
function NTTrapHpChange:SetDamageSrcEntityID(srcID)
    self._damageSrcEntityID = srcID
end
function NTTrapHpChange:GetDamageSrcEntityID()
    return self._damageSrcEntityID
end

function NTTrapHpChange:SetDamageType(damageType)
    self._damageType = damageType
end

function NTTrapHpChange:GetDamageType()
    return self._damageType
end

function NTTrapHpChange:SetDamageInfo(damageInfo)
    self._damageInfo = damageInfo
end

function NTTrapHpChange:GetDamageInfo()
    return self._damageInfo
end

function NTTrapHpChange:SetAttackPos(attackPos)
    self._attackPos = attackPos
end

function NTTrapHpChange:GetAttackPos()
    return self._attackPos
end
--endregion 机关血量变化

--region --玩家血量
_class("NTPlayerHPChange", NTHPCChange)
NTPlayerHPChange = NTPlayerHPChange
----@param entity Entity
function NTPlayerHPChange:Constructor(entity, hp, maxhp, hpSpilled, changeHp, damageSrcEntity)
    self._ownerEntity = entity
    self.hp = hp
    self.maxhp = maxhp
    self.hpSpilled = hpSpilled
    self.changeHp = changeHp
    self._changeHP = changeHp
    self._damageSrcEntity = damageSrcEntity
end

function NTPlayerHPChange:GetNotifyType()
    return NotifyType.PlayerHPChange
end

function NTPlayerHPChange:GetNotifyEntity()
    return self._ownerEntity
end
function NTPlayerHPChange:GetDamageSrcEntity()
    return self._damageSrcEntity
end

function NTPlayerHPChange:GetDamageSrcEntityID()
    --传入的danmageSrcEntity实际上是ID
    return self._damageSrcEntity
end

function NTPlayerHPChange:GetHPSpilled()
    return self.hpSpilled
end

function NTPlayerHPChange:GetChangeHP()
    return self.changeHp
end

function NTPlayerHPChange:GetMaxHP()
    return self.maxhp
end

function NTPlayerHPChange:GetHP()
    return self.hp
end

function NTPlayerHPChange:GetHPPercent()
    return self.hp / self.maxhp * 100
end

function NTPlayerHPChange:NeedCheckGameTurn()
    return false
end

function NTPlayerHPChange:SetDamageType(damageType)
    self._damageType = damageType
end

function NTPlayerHPChange:GetDamageType()
    return self._damageType
end

function NTPlayerHPChange:SetAttackPos(attackPos)
    self._attackPos = attackPos
end

function NTPlayerHPChange:GetAttackPos()
    return self._attackPos
end

function NTPlayerHPChange:SetDamageInfo(damageInfo)
    self._damageInfo = damageInfo
end

function NTPlayerHPChange:GetDamageInfo()
    return self._damageInfo
end
--endregion --玩家血量