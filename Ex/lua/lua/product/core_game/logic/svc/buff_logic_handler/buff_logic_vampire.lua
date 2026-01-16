--[[
    吸血buff-伤害转血量
]]
_class("BuffLogicVampire", BuffLogicBase)
BuffLogicVampire = BuffLogicVampire

---@class BloodChangeSanType
BloodChangeSanType = {
    None = 0,   --不做任何操作
    Add = 1,    --增加San值
    Reduce = 2, --扣除San值
}
_enum("BloodChangeSanType", BloodChangeSanType)

function BuffLogicVampire:Constructor(buffInstance, logicParam)
    --吸血参数，3个值
    self._vampireParam = logicParam["vampire"]
    --吸血对什么类型的伤害生效，可以为table，为0时表示对任何类型生效
    self._skillTypes = logicParam["skillTypes"]
    --根据吸血量和队伍血量的百分比恢复或扣除San值
    self._changeSanType = logicParam["changeSanType"] or BloodChangeSanType.None
end

function BuffLogicVampire:DoLogic(notify)
    local damage = notify:GetDamageValue()
    if damage == nil then
        Log.fatal("[Vampire] notify 中没有damage参数，无法计算吸血")
        return
    end

    if damage <= 0 then
        Log.notice("[Vampire] 伤害为0，不吸血")
        return
    end

    --MSG26675 与策划讨论过，如果目标是机关，直接不处理
    if notify.GetDefenderEntity then
        local e = notify:GetDefenderEntity()
        if e:HasTrap() then
            return
        end
    end

    ---@type Entity
    local attacker = notify:GetNotifyEntity()
    local targetHPEntity = notify:GetNotifyEntity()
    if targetHPEntity:HasSuperEntity() then
        targetHPEntity = targetHPEntity:GetSuperEntity()
    end

    if targetHPEntity:HasPetPstID() then
        targetHPEntity = targetHPEntity:Pet():GetOwnerTeamEntity()
    end

    --从攻击者身上取出技能id
    local skillID = attacker:SkillContext():GetResultContainer():GetSkillID()

    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type SkillType
    local skillType = cfgService:GetSkillConfigData(skillID):GetSkillType()

    local canVampire = false
    if type(self._skillTypes) == "number" and self._skillTypes == 0 then
        --配置0时表示对任何技能吸血
        canVampire = true
    elseif type(self._skillTypes) == "table" and table.icontains(self._skillTypes, skillType) then
        canVampire = true
    end
    if not canVampire then
        --技能类型不符合，不能吸血
        return
    end

    --禁疗
    if targetHPEntity:Attributes():GetAttribute("BuffForbidCure") then
        return
    end

    ---@type FormulaService
    local formulaSvc = self._world:GetService("Formula")
    ---@type SkillContextComponent
    local skillCtx = attacker:SkillContext()

    local value = formulaSvc:CalcBaseByPercent(damage, self._vampireParam[2])
    local rate = attacker:Attributes():GetAttribute("AddBloodRate") or 0
    local rate2 = targetHPEntity:Attributes():GetAttribute("AddBloodRate") or 0
    value = value * (1 + rate + rate2)
    local vampire = skillCtx:TryVampireOnce(self._vampireParam[1], value, self._vampireParam[3], false)

    --应用逻辑
    ---@type CalcDamageService
    local calcDamageSvc = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(vampire, DamageType.Recover)
    calcDamageSvc:AddTargetHP(targetHPEntity:GetID(), damageInfo)
    damageInfo:SetHPShield(targetHPEntity:BuffComponent():GetBuffValue("HPShield"))
    local result = BuffResultVampire:New(damageInfo)

    --根据吸血量和队伍血量的百分比恢复San值
    if self._changeSanType ~= BloodChangeSanType.None and vampire > 0 then
        result:SetAddSan(true)

        ---@type AttributesComponent
        local attributesCmpt = targetHPEntity:Attributes()
        local maxHP = attributesCmpt:CalcMaxHp()
        local addHPPercent = (vampire / maxHP) * 100
        local addSan = math.ceil(addHPPercent)

        local curVal, oldVal, changeVal, debtVal, modifyTimes = self:CalculateSan(addSan)
        result:SetOldSanValue(oldVal)
        result:SetNewSanValue(curVal)
        result:SetModifySanValue(changeVal)
        result:SetDebtValue(debtVal)
        result:SetModifyTimes(modifyTimes)

        local nt = NTSanValueChange:New(curVal, oldVal, debtVal, modifyTimes)
        self._world:GetService("Trigger"):Notify(nt)
    end
    local notifyType = notify:GetNotifyType()
    if notifyType == NotifyType.NormalEachAttackEnd then
        result.attacker = notify:GetAttackerEntity()
        result.defender = notify:GetDefenderEntity()
        result.attackPos = notify:GetAttackPos()
        result.targetPos = notify:GetTargetPos()
    end

    return result
end

function BuffLogicVampire:CalculateSan(addSan)
    ---@type FeatureServiceLogic
    local svc = self._world:GetService("FeatureLogic")
    if self._changeSanType == BloodChangeSanType.Add then
        return svc:IncreaseSanValue(addSan)
    elseif self._changeSanType == BloodChangeSanType.Reduce then
        return svc:DecreaseSanValue(addSan)
    end
end
