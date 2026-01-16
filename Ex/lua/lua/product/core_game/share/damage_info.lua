--[[------------------------------------------------------------------------------------------
    DamageInfo : 伤害数据 包括伤害值及类型
]] --------------------------------------------------------------------------------------------

_class("DamageInfo", Object)
---@class DamageInfo: Object
DamageInfo = DamageInfo

---@class DamageType
local DamageType = {
    Invalid = 0, --无效无表现
    Normal = 1, --正常伤害
    Real = 2, ---真实伤害
    Recover = 3, -- 恢复
    Guard = 4, --护盾
    Miss = 5, --丢失
    Critical = 6, --暴击
    Burn = 21, --灼烧
    Poison = 22, --中毒
    Bleed = 23, --流血
    Explode = 24, --爆炸
    RealReflexive = 25, --反伤-真实伤害
    RealDead = 26, ---即死-当前血量的-真实伤害
    NoElementNormal = 27, --无属性的正常伤害
    RealTransmit = 28, --传递的真实伤害
    RecoverTransmit = 29 --传递的恢复
}
_enum("DamageType", DamageType)
function DamageInfo:Constructor(damageValue, damageType)
    if damageValue then
        self._damageValue = math.ceil(damageValue) --原始伤害值
    else
        self._damageValue = nil
    end

    self._damageType = damageType --伤害类型
    self._changeHP = 0 --实际造成的目标血量变化值
    self._attackerEntityId = nil --伤害来源
    self._targetEntityId = nil --伤害目标
    self._dropAssetList = nil --造成的掉落
    self._isTriggerHPLock = nil --是否触发锁血
    self._isTriggerSecKill = nil --是否触发即死
    self._isHpShieldGuard = nil --是否血条盾抵挡全部伤害
    self._hpShield = nil --当前剩余血条盾
    self._hpShieldDelta = nil --血条盾变化值，用于表现
    self._comboCount = nil --当时的combo数
    self._shieldLayer = nil --当时的盾层数
    self._mazeDamageList = nil --秘境中对队伍造成伤害后几个星灵的不同伤害值
    self._singlePet = nil --秘境中是否只对一个星灵生效
    self._showPosition = nil --伤害飘字的渲染坐标
    self._elementType = nil --元素类型
    self._showType = DamageShowType.Single --单体还是格子飘字
    self._beHitRefreshBuff = true --在通用被击HandleBeHit的时候可以刷新buff，默认可以刷新
    self._playBuffResult = nil --在通用被击的时候 只播放指定的buffResult，而不是播放所有
    self._renderGridPos = nil --伤害飘字的位置
    self._hpAndShieldChangeValue = nil --血量和血条盾加起来的变化值，只在造成伤害的时候统计，只加盾时不计数
end
---@param other DamageInfo
function DamageInfo:Clone(other)
    self._damageValue = other._damageValue
    self._damageType = other._damageType --伤害类型
    self._changeHP = other._changeHP --实际造成的目标血量变化值
    self._attackerEntityId = other._attackerEntityId --伤害来源
    self._targetEntityId = other._targetEntityId --伤害目标
    self._dropAssetList = nil--造成的掉落
    self._isTriggerHPLock = other._isTriggerHPLock --是否触发锁血
    self._isTriggerSecKill = other._isTriggerSecKill --是否触发即死
    self._isHpShieldGuard = other._isHpShieldGuard --是否血条盾抵挡全部伤害
    self._hpShield = nil --当前剩余血条盾
    self._hpShieldDelta = nil --血条盾变化值，用于表现
    self._comboCount = other._comboCount --当时的combo数
    self._shieldLayer = nil --当时的盾层数
    if other._mazeDamageList then
        self._mazeDamageList = table.clone(other._mazeDamageList)  --秘境中对队伍造成伤害后几个星灵的不同伤害值
    end
    self._singlePet = other._singlePet --秘境中是否只对一个星灵生效
    self._showPosition = other._showPosition --伤害飘字的渲染坐标
    self._elementType = other._elementType --元素类型
    self._showType = other._showType  --单体还是格子飘字
    self._beHitRefreshBuff = other._beHitRefreshBuff  --在通用被击HandleBeHit的时候可以刷新buff，默认可以刷新
    self._playBuffResult = other._playBuffResult --在通用被击的时候 只播放指定的buffResult，而不是播放所有
    self._renderGridPos = other._renderGridPos --伤害飘字的位置
    self._hpAndShieldChangeValue = other._hpAndShieldChangeValue --血量和血条盾加起来的变化值，只在造成伤害的时候统计，只加盾时不计数
end

function DamageInfo:GetDamageValue()
    return self._damageValue
end

function DamageInfo:GetMazeDamageList()
    return self._mazeDamageList
end

function DamageInfo:SetMazeDamageList(mazeDamageList)
    self._mazeDamageList = mazeDamageList
end

function DamageInfo:GetMazeDamageValue(entityID)
    if not self._mazeDamageList then
        return 0
    end
    return self._mazeDamageList[entityID]
end

function DamageInfo:AddMazeDamage(entityID, damageValue)
    if not self._mazeDamageList then
        self._mazeDamageList = {}
    end
    damageValue = damageValue
    self._mazeDamageList[entityID] = damageValue
end

---@param damageInfo DamageInfo
function DamageInfo:MergeDamageInfo(damageInfo)
    if self._damageType ~= damageInfo:GetDamageType() then
        return
    end
    self._damageValue = self._damageValue + damageInfo:GetDamageValue()
    self._changeHP = self._changeHP + damageInfo:GetChangeHP()
    local mazeDamageList = damageInfo:GetMazeDamageList()
    if mazeDamageList then
        if not self._mazeDamageList then
            self._mazeDamageList = {}
        end
        for eid, val in pairs(mazeDamageList) do
            self._mazeDamageList[eid] = (self._mazeDamageList[eid] or 0) + val
        end
    end
end

function DamageInfo:GetSinglePet()
    return self._singlePet or 0
end

function DamageInfo:SetSinglePet(singlePet)
    self._singlePet = singlePet
end

---@return DamageType
function DamageInfo:GetDamageType()
    return self._damageType
end

function DamageInfo:GetDropAssetList()
    return self._dropAssetList
end

function DamageInfo:SetDropAssetList(dropAssetList)
    self._dropAssetList = dropAssetList
end

function DamageInfo:SetDamageValue(damage)
    self._damageValue = math.floor(damage)
    ---去掉处理 处理会导致加血0的情况下显示加血1 伤害应该在外面保证达到最低是1
end
function DamageInfo:SetDamageType(damageType)
    self._damageType = damageType
end

function DamageInfo:SetAttackerEntityID(damageSrcEntityId)
    self._attackerEntityId = damageSrcEntityId
end

function DamageInfo:GetAttackerEntityID()
    return self._attackerEntityId
end

function DamageInfo:SetTargetEntityID(targetEntityId)
    self._targetEntityId = targetEntityId
end

function DamageInfo:GetTargetEntityID()
    return self._targetEntityId
end

function DamageInfo:IsTriggerHPLock()
    return self._isTriggerHPLock
end

function DamageInfo:SetTriggerHPLock(val)
    self._isTriggerHPLock = val
end

function DamageInfo:SetTriggerSecKill(val)
    self._isTriggerSecKill = val
end

function DamageInfo:IsTriggerSecKill()
    return self._isTriggerSecKill
end

function DamageInfo:SetShieldLayer(layer)
    self._shieldLayer = layer
end

function DamageInfo:GetShieldLayer()
    return self._shieldLayer
end

function DamageInfo:SetComboCount(count)
    self._comboCount = count
end

function DamageInfo:GetComboCount()
    return self._comboCount
end
function DamageInfo:SetChangeHP(val)
    self._changeHP = val
end

function DamageInfo:GetChangeHP()
    return self._changeHP
end

function DamageInfo:SetShowPosition(pos)
    self._showPosition = pos
end

function DamageInfo:GetShowPosition()
    return self._showPosition
end

function DamageInfo:SetElementType(element)
    self._elementType = element
end

function DamageInfo:GetElementType()
    return self._elementType
end

function DamageInfo:SetShowType(type)
    self._showType = type
end

function DamageInfo:GetShowType()
    return self._showType
end

function DamageInfo:SetHPShield(val)
    self._hpShield = val
end

function DamageInfo:GetHPShield()
    return self._hpShield
end
--血条盾变化值，用于表现
function DamageInfo:SetHPShieldDelta(val)
    self._hpShieldDelta = val
end
function DamageInfo:GetHPShieldDelta()
    return self._hpShieldDelta
end
function DamageInfo:SetHPShieldGuard(val)
    self._isHpShieldGuard = val
end

function DamageInfo:IsHPShieldGuard()
    return self._isHpShieldGuard
end

function DamageInfo:SetBeHitRefreshBuff(val)
    self._beHitRefreshBuff = val
end

function DamageInfo:GetBeHitRefreshBuff()
    return self._beHitRefreshBuff
end

function DamageInfo:SetPlayBuffResult(val)
    self._playBuffResult = val
end

function DamageInfo:GetPlayBuffResult()
    return self._playBuffResult
end

---技能效果里配置的伤害阶段
function DamageInfo:SetDamageStageIndex(val)
    self._damageStageIndex = val
end

function DamageInfo:GetDamageStageIndex()
    return self._damageStageIndex
end

function DamageInfo:SetRenderGridPos(gridPos)
    self._renderGridPos = gridPos
end

function DamageInfo:GetRenderGridPos()
    return self._renderGridPos
end
--SkillEffectCalcRandDamageSameHalf 可能对单个敌人造成多次伤害 处理buffview
function DamageInfo:SetRandHalfDamageIndex(val)
    self._randHalfDamageIndex = val
end

function DamageInfo:GetRandHalfDamageIndex()
    return self._randHalfDamageIndex
end

function DamageInfo:SetAttackPos(attackPos)
    self._attackPos = attackPos
end

function DamageInfo:GetAttackPos()
    return self._attackPos
end

function DamageInfo:SetHpAndShieldChangeValue(val)
    self._hpAndShieldChangeValue = val
end

function DamageInfo:GetHpAndShieldChangeValue()
    return self._hpAndShieldChangeValue
end

function DamageInfo:SetShieldCostDamage(val)
    self._shieldCostDamage = val
end

function DamageInfo:GetShieldCostDamage()
    return self._shieldCostDamage
end

function DamageInfo:SetCurSkillDamageIndex(val)
    self._curSkillDamageIndex = val
end

function DamageInfo:GetCurSkillDamageIndex()
    return self._curSkillDamageIndex
end
---region 诅咒血条
function DamageInfo:SetCurseHp(val)
    self._curseHp = val
end

function DamageInfo:GetCurseHp()
    return self._curseHp
end
function DamageInfo:SetCurseHpDelta(val)
    self._curseHpDelta = val
end
function DamageInfo:GetCurseHpDelta()
    return self._curseHpDelta
end
---endregion 诅咒血条

--是由那个技能效果造成的伤害
function DamageInfo:SetSkillEffectType(skillEffectType)
    self._skillEffectType = skillEffectType
end
function DamageInfo:GetSkillEffectType()
    return self._skillEffectType
end

function DamageInfo:SetSkillID(skillID)
    self._skillID = skillID
end
function DamageInfo:GetSkillID()
    return self._skillID
end
