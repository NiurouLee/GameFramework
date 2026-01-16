--[[
    全局伤害计算
]]
_class("CalcDamageService", BaseService)
---@class CalcDamageService:BaseService
CalcDamageService = CalcDamageService

function CalcDamageService:Constructor(_)
    self.__NTMonsterHPCChangeCount = 0
end

--队伍逻辑血量
function CalcDamageService:GetTeamLogicHP(teamEntity)
    ---@type AttributesComponent
    local teamAttrConmpt = teamEntity:Attributes()
    local teamHP = teamAttrConmpt:GetCurrentHP()
    local teamMaxHP = teamAttrConmpt:CalcMaxHp()
    return teamHP, teamMaxHP
end

----------------------------------------------------------------
---加血量上限
----------------------------------------------------------------
function CalcDamageService:AddTargetMaxHP(defenderEntityID, addValue, modifyID)
    local defender = self._world:GetEntityByID(defenderEntityID)

    --派生不同的处理方案
    return self:_DoAddTargetMaxHP(defender, addValue, modifyID)
end

---@param defender Entity
function CalcDamageService:_DoAddTargetMaxHP(defender, addValue, modifyID)
    local ret = {}
    if defender:HasPetPstID() then
        Log.error("_DoAddTargetMaxHP() CANNOT ADD HP TO PET!! addHP=", addValue, " defender=", defender:GetID())
        return ret
    end
    --增加血量上限绝对值
    defender:Attributes():Modify("MaxHPConstantFix", addValue, modifyID)
    ret[defender:GetID()] = defender:Attributes():CalcMaxHp()

    self._world:GetService("BuffLogic"):FixGreyHPVal(defender)
    return ret
end

---@param eid number EntityID
---@param val number value
---@param modifyID number modification indicator(e.g., buffID)
function CalcDamageService:DecreaseTargetMaxHP(eid, val, modifyID)
    val = val * (-1)
    local e = self._world:GetEntityByID(eid)

    if e:HasPetPstID() or e:HasTeam() then
        Log.exception("DecreaseTargetMaxHP: 该接口在设计时没有考虑给玩家使用。请在对过需求之后实现正确的逻辑。")
        return {}
    end

    return self:_DoDecreaseTargetMaxHP(e, val, modifyID)
end

---@param e Entity Entity
---@param val number value
---@param modifyID number modification indicator(e.g., buffID)
function CalcDamageService:_DoDecreaseTargetMaxHP(e, val, modifyID)
    local ret = {}

    e:Attributes():Modify("MaxHPConstantFix", val, modifyID)
    ret[e:GetID()] = e:Attributes():CalcMaxHp()

    self._world:GetService("BuffLogic"):FixGreyHPVal(e)
    return ret
end

----------------------------------------------------------------
--- 加血逻辑
----------------------------------------------------------------

---@param damageInfo DamageInfo
function CalcDamageService:AddTargetHP(defenderEntityID, damageInfo)
    local defender = self._world:GetEntityByID(defenderEntityID)
    assert(defender)
    local damageType = damageInfo:GetDamageType()
    assert(damageType == DamageType.Recover or damageType == DamageType.RecoverTransmit)

    --加血处理，派生不同的处理方案
    self:_DoAddTargetHP(defender, damageInfo)
end

---@param damageInfo DamageInfo
function CalcDamageService:_DoAddTargetHP(defender, damageInfo)
    local val = damageInfo:GetDamageValue()
    if defender:HasPetPstID() then
        Log.error("_DoAddTargetHP() CANNOT ADD HP TO PET!! addHP=", val, " defender=", defender:GetID())
        return
    end
    --实际修改血量
    damageInfo:SetChangeHP(val)
    self:_ModifyDefenderHP(defender, damageInfo)
    if defender:MonsterID() and damageInfo:GetChangeHP() > 0 then
        ---@type BattleStatComponent
        local stateCmpt = self._world:BattleStat()
        ---@type MonsterIDComponent
        local monsterIDCmpt = defender:MonsterID()
        if monsterIDCmpt:IsWorldBoss() then
            stateCmpt:SubMonsterBeHitDamageValue(defender:GetID(), damageInfo:GetChangeHP())
        end
    end

    self._world:GetService("BuffLogic"):FixGreyHPVal(defender)
end

---------------------------------------------------------------
---直接减血逻辑
---------------------------------------------------------------
function CalcDamageService:_DoSubTargetHPPercent(casterEntity, targetEntity, percent, byMaxHP,ignoreShield, leastHP)
    local maxHp = targetEntity:Attributes():CalcMaxHp()
    local curHP = targetEntity:Attributes():GetCurrentHP()
    local subHP = 0
    if byMaxHP then
        subHP = math.ceil(maxHp * percent)
    else
        subHP = math.ceil(curHP * percent)
    end
    local damageOnHP = subHP
    -- if curHP - subHP < 1 then
    --     subHP = 0
    -- end

    local damageInfo = DamageInfo:New(subHP, DamageType.Real)
    damageInfo:SetChangeHP(-subHP)
    if ignoreShield then
        if curHP - subHP < 1 then
            if leastHP then
                subHP = subHP - leastHP
            else
                subHP = 0
            end
        end
        damageInfo:SetDamageValue(subHP)
        damageInfo:SetChangeHP(-subHP)
        if subHP ~= 0 then
            self:_ModifyDefenderHP(targetEntity, damageInfo)
        end
    else
        local shieldCostDamage, curShield = 0, 0
        local shieldDelta = 0
        shieldCostDamage, curShield, shieldDelta = self:_CalcHealthShield(targetEntity, damageOnHP)
        local isHPShieldGuard = shieldCostDamage == damageOnHP
        damageOnHP = damageOnHP - shieldCostDamage
        if curHP - damageOnHP < 1 then
            if leastHP then
                damageOnHP = damageOnHP - leastHP
            else
                damageOnHP = 0
            end
        end
        damageInfo:SetHPShield(curShield)
        damageInfo:SetHPShieldDelta(shieldDelta)
        damageInfo:SetHPShieldGuard(isHPShieldGuard)
        damageInfo:SetShieldCostDamage(shieldCostDamage)
        
        damageInfo:SetDamageValue(subHP)
        damageInfo:SetChangeHP(-damageOnHP)

        if damageOnHP ~= 0 or shieldCostDamage ~= 0 then
            self:_ModifyDefenderHP(targetEntity, damageInfo)
        end
    end
    return damageInfo
end

--按百分比扣血，不能死
---@param byMaxHP boolean 新增，按最大生命值百分比扣血
function CalcDamageService:SubTargetHPPercent(casterEntity, targetEntity, percent, byMaxHP,ignoreShield, leastHP)
    ---@type Entity
    local subTarget = nil
    if targetEntity:HasPetPstID() then
        subTarget = casterEntity:Pet():GetOwnerTeamEntity()
    else
        subTarget = targetEntity
    end
    return self:_DoSubTargetHPPercent(casterEntity, subTarget, percent, byMaxHP,ignoreShield, leastHP)
end

--[[
    直接减血逻辑：降低生命值最大百分比使用

    下面这个逻辑最初给精英怪词缀的降低最大生命值使用的
    因为是怪物创建时使用，一些逻辑问题会被避开，其他用途时需注意是否符合需求
]]
---@param e Entity
---@param damageInfo DamageInfo
function CalcDamageService:DecreaseTargetHP(e, damageInfo)
    if (e:HasPetPstID() or e:HasTeam()) then
        Log.exception("DecreaseTargetHP: 该接口在设计时没有考虑给玩家使用。请在对过需求之后实现正确的逻辑。")
        return {}
    end

    self:_DoDecreaseTargetHP(e, damageInfo)
end

function CalcDamageService:_DoDecreaseTargetHP(e, damageInfo)
    -- 注意第三个参数为true时将不会发送这次修改操作的buff通知
    -- 添加的原因是这个接口被设计为怪物组装时使用
    -- 如果没有拦住，可能触发在这之前加在身上的其他buff
    self:_ModifyDefenderHP(e, damageInfo, true)
end

----------------------------------------------------------------
---伤害计算并扣血
----------------------------------------------------------------

--所有伤害计算走这个函数
---@param attacker Entity
---@param defender Entity
---@param damageparam SkillDamageEffectParam
function CalcDamageService:DoCalcDamage(attacker, defender, damageparam, ignoreShield, damageGridPos)
    ---@type FormulaService
    local formulaService = self._world:GetService("Formula")
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    if defender:Attributes():GetAttribute("CanBeAttacked") == 0 then
        return DamageInfo:New(0, DamageType.Invalid)
    end

    --伤害计算日志
    local logger = self._world:GetMatchLogger()
    logger:BeginDamageLog(attacker:GetID(), defender:GetID())

    local damage = 0
    local damageType = DamageType.Normal
    local skillID = damageparam.skillID
    local formulaID = damageparam.formulaID
    local attackPos = damageparam.attackPos
    local effectType = damageparam.skillEffectType
    local damageInfo = DamageInfo:New(damage, damageType)

    damageInfo:SetAttackerEntityID(attacker:GetID())
    damageInfo:SetTargetEntityID(defender:GetID())
    damageInfo:SetAttackPos(attackPos)
    damageInfo:SetSkillEffectType(effectType)
    damageInfo:SetSkillID(skillID)

    --伤害转诅咒血条 此时所有伤害都穿盾
    if self:_NeedCurseHpTrans(attacker, defender) then
        ignoreShield = true
    end
    --伤害前的buff处理
    damageType = buffLogicService:CheckCanBeDamage(attacker, defender, skillID, ignoreShield)
    damageInfo:SetDamageType(damageType)
    --记录表现用的盾层数
    local shieldLayer = buffLogicService:GetBuffLayer(defender, BuffEffectType.LayerShield)
    damageInfo:SetShieldLayer(shieldLayer)

    if damageType == DamageType.Normal then
        --伤害公式
        damage, damageType = formulaService:CalcDamageByFormulaID(attacker, defender, damageparam, formulaID, damageGridPos)

        damageInfo:SetDamageType(damageType)
        damageInfo:SetDamageValue(damage)

        --伤害的元素属性
        self:CalcDamageElement(attacker, damageInfo)

        --最终伤害扣血，派生不同的方案
        self:_DoDamageModifyHP(attacker, defender, damageInfo, ignoreShield)

        --掉落buff
        self:DoDropAsset(defender, damageInfo)

        --停止怪物AI
        self:_DisableMonsterAI(defender)

        ---主动技击碎的机关不立即结算死亡技能,在主动技结算后再单独结算死亡机关的死亡
        local isActiveSkill = false
        if attacker:HasSkillInfo() and attacker:SkillInfo():GetActiveSkillID() == skillID then
            isActiveSkill = true
        end
        trapServiceLogic:DestroyTrapAtOnce(defender:GetID(), attacker, isActiveSkill)

        ---只处理空血状态
        local curHp = defender:Attributes():GetCurrentHP()
        if defender:HasChessPet() and curHp <= 0 then
            local t = {defender:GetID()}
            self._world:BattleStat():SetChessDeadPlayerPawnCount(t)
        end
    end

    self:_StatData(defender)
    logger:EndDamageLog(attacker:GetID())
    if attacker:SkillContext() then
        attacker:SkillContext():AddDamage(defender:GetID(), damageInfo)
    end

    --记录日志
    local curHP = defender:Attributes():GetCurrentHP()
    self._world:GetSyncLogger():Trace(
        {
            key = "DoCalcDamage",
            attackerID = attacker:GetID(),
            defenderID = defender:GetID(),
            skillID = skillID,
            damageType = damageInfo:GetDamageType(),
            damageValue = damageInfo:GetDamageValue(),
            changeHP = damageInfo:GetChangeHP(),
            curHP = curHP
        }
    )
    self:LogNotice(
        "DoCalcDamage() attacker=",
        attacker:GetID(),
        " defender=",
        defender:GetID(),
        " skillID=",
        skillID,
        " damage=",
        damageInfo:GetDamageValue(),
        " changeHP=",
        damageInfo:GetChangeHP(),
        " curHP=",
        curHP
    )
    if defender:MonsterID() and damageInfo:GetChangeHP() < 0 then
        ---@type BattleStatComponent
        local stateCmpt = self._world:BattleStat()
        ---@type MonsterIDComponent
        local monsterIDCmpt = defender:MonsterID()
        if monsterIDCmpt:IsWorldBoss() then
            stateCmpt:AddMonsterBeHitDamageValue(defender:GetID(), damageInfo:GetChangeHP() * -1, skillID)
            monsterIDCmpt:AddMonsterBeHitDamage(damageInfo:GetChangeHP() * -1)
        end
    end

    if defender:HasDamageStatisticsComponent() then
        defender:DamageStatisticsComponent():Append(attacker, damageInfo:GetDamageValue())
    end

    return damageInfo
end

function CalcDamageService:_CalcElementDamageReduce(attacker, defender, damageInfo)
    --[buff伤害是自己对自己的伤害]
    if attacker == defender then
        return
    end
    local t = defender:Attributes():GetAttribute("BuffElementHarmReduce")
    if not t then
        return
    end

    local elementList = t[1]
    local rate = t[2]
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local element = utilSvc:GetEntityElementType(attacker)

    if elementList ~= nil then
        for _, el in ipairs(elementList) do
            if element == el then
                local damage = damageInfo:GetDamageValue()
                damage = damage * rate
                damageInfo:SetDamageValue(damage)
                return
            end
        end
    end
end

---处理属性强化buff对伤害的影响
---@param damageInfo DamageInfo
function CalcDamageService:_CalcElementReinforce(casterEntity, defenderEntity, damageInfo)
    --[buff伤害是自己对自己的伤害]
    if casterEntity == defenderEntity then
        return
    end
    if damageInfo:GetDamageType() == DamageType.Real or damageInfo:GetDamageType() == DamageType.RealReflexive then --真实伤害不受属性强化影响
        return
    end
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    local damage = damageInfo:GetDamageValue()
    local cBuff = defenderEntity:BuffComponent()
    local flagElementReinforce = buffLogicSvc:CheckElementReinforce(casterEntity, defenderEntity)
    if flagElementReinforce == 0 then --带属性强化的怪被克，掉血
        local a = cBuff:GetBuffValue("ElementReinforceFactorA")
        if a then
            damage = damage * a
        end
    elseif flagElementReinforce == 1 then --带属性强化的怪克制攻击者，加血
        local c = cBuff:GetBuffValue("ElementReinforceFactorC")
        if c then
            damage = damage * c
        end
    elseif flagElementReinforce == 2 then --无克制关系
        local b = cBuff:GetBuffValue("ElementReinforceFactorB")
        if b then
            damage = damage * b
        end
    end
    if damage > 0 then
        return --大于0走公式系数，此处不生效
    elseif damage == 0 and damageInfo:GetDamageType() == DamageType.RealDead then
        return --斩杀伤害是目标的剩余血量 可能是0
    elseif damage == 0 then
        damageInfo:SetDamageType(DamageType.Guard)
    else
        damage = -damage
        damageInfo:SetDamageType(DamageType.Recover)
    end
    damageInfo:SetDamageValue(damage)
    local val = damageInfo:GetDamageValue()
    damageInfo:SetChangeHP(val)
end

function CalcDamageService:CalcDamageElement(caster, damageInfo)
    --元素属性
    ---@type ElementComponent
    local elementCmpt = caster:Element()
    ---@type ElementType
    local elementType = ElementType.ElementType_None
    if elementCmpt then
        if caster:HasPetPstID() == true then
            ---星灵会有副属
            if elementCmpt:IsUseSecondaryType() == true then
                elementType = elementCmpt:GetSecondaryType()
            else
                elementType = elementCmpt:GetPrimaryType()
            end
        else
            elementType = elementCmpt:GetPrimaryType()
        end
    end
    damageInfo:SetElementType(elementType)
end

function CalcDamageService:_DoDamageModifyHP(attacker, defender, damageInfo, ignoreShield)
    self:_CalcDamageOnHP(attacker, defender, damageInfo, ignoreShield)
    --修改血量
    self:_ModifyDefenderHP(defender, damageInfo)
end

--扣血前的buff处理
---@param damageInfo DamageInfo
---@param attacker Entity
---@param defender Entity
function CalcDamageService:_CalcDamageOnHP(attacker, defender, damageInfo, ignoreShield)
    -- 属性减伤buff
    self:_CalcElementDamageReduce(attacker, defender, damageInfo)
    -- 属性强化buff
    self:_CalcElementReinforce(attacker, defender, damageInfo)

    --这里不处理加血
    if damageInfo:GetDamageType() == DamageType.Recover then
        return
    end

    --算血
    local damageOnHP = damageInfo:GetDamageValue()
    local damageType = damageInfo:GetDamageType()

    --血条盾
    --大航海回合耗尽扣血机制：无视护盾
    --[[
        路万博(@PLM) 9-15 15:40:22
        如果一个人没血有盾算死亡？

        午蔚刚 9-15 15:40:55
        恩，算死亡
    ]]
    local shieldCostDamage, curShield = 0, 0
    local shieldDelta = 0
    if not ignoreShield then
        shieldCostDamage, curShield, shieldDelta = self:_CalcHealthShield(defender, damageOnHP)
        if shieldCostDamage > 0 then
            Log.debug("Calc damage hp shiled, defenderID: ",defender:GetID()," shieldCostDmg: "
                ,shieldCostDamage," curShield: ",curShield, " curDamageOnHP: ",damageOnHP)
        end
    else
        --无视护盾的情况下，护盾值保持当前值
        local buffCmpt = defender:BuffComponent()
        local shield = 0
        if buffCmpt:GetBuffValue("HPShield") then
            shield = buffCmpt:GetBuffValue("HPShield")
        end
        curShield = shield
    end
    local isHPShieldGuard = shieldCostDamage == damageOnHP
    damageOnHP = damageOnHP - shieldCostDamage
    damageInfo:SetHPShield(curShield)
    damageInfo:SetHPShieldDelta(shieldDelta)
    damageInfo:SetHPShieldGuard(isHPShieldGuard)
    damageInfo:SetShieldCostDamage(shieldCostDamage)

    -- 计算单次受击掉血上限buff
    local maxHp = defender:Attributes():CalcMaxHp()
    local curHp = defender:Attributes():GetCurrentHP()
    local cBuff = defender:BuffComponent()
    if cBuff then
        --region 受伤减轻(偏斜)
        local glancingRate = cBuff:GetBuffValue("GlancingRate")
        local glancingMaxValue = cBuff:GetBuffValue("GlancingMaxValue")
        if glancingRate and glancingMaxValue then
            local val = math.floor(damageOnHP * glancingRate)
            damageOnHP = math.min(glancingMaxValue, val)
        end
        --endregion
        local attackIgnoreLoseHpLimit = false
        local cAttackerBuff = attacker:BuffComponent()
        if cAttackerBuff then
            local attackIgnoreMaxLoseHpPercent = cAttackerBuff:GetBuffValue("AttackIgnoreMaxLoseHPPercent")
            if attackIgnoreMaxLoseHpPercent and attackIgnoreMaxLoseHpPercent == 1 then
                attackIgnoreLoseHpLimit = true
            end
        end
        if not attackIgnoreLoseHpLimit then
            local t = cBuff:GetBuffValue("MaxLoseHPPercent")
            if t then
                if t.percent then
                    local val = math.floor(maxHp * t.percent)
                    damageOnHP = math.min(val, damageOnHP)
                elseif t.fixValue then
                    damageOnHP = math.min(t.fixValue, damageOnHP)
                end
            end
        end
    end

    --处理伤害转诅咒血条
    local canTransToCurseHp,transCurseCostDamage, curCurseHp, curseHpModifyVal,transCurseValue = self:_CalcCurseHpTrans(attacker,defender, damageOnHP)
    if canTransToCurseHp and transCurseCostDamage and transCurseCostDamage > 0 then
        damageOnHP = damageOnHP - transCurseCostDamage
        damageInfo:SetCurseHp(curCurseHp)
        damageInfo:SetCurseHpDelta(curseHpModifyVal)
        damageInfo:SetDamageValue(transCurseValue)--飘字用 transCurseValue是伤害转换的诅咒量，curseHpModifyVal是实际的变化量，可能是0
    end

    --处理即死buff，不要担心，锁血会避免目标死亡
    local isTriggerSecKill = false
    damageOnHP, isTriggerSecKill = self:CalcSecKillBuff(defender, damageOnHP)
    damageInfo:SetTriggerSecKill(isTriggerSecKill)

    --计算锁血buff
    local lockCostHP, isTriggerHPLock = self:CalcLockHP(defender, damageOnHP)
    damageInfo:SetTriggerHPLock(isTriggerHPLock)

    if isTriggerHPLock then
        damageInfo:SetTriggerSecKill(false)
    end

    if lockCostHP < damageOnHP then
        damageOnHP = lockCostHP
        damageInfo:SetDamageValue(lockCostHP)
        if lockCostHP == 0 then
            damageInfo:SetDamageType(DamageType.Guard)
        end
    end

    ---新手引导锁血功能,只锁血不改伤害字----
    damageOnHP = self:DoGuideLockPlayerHPPercent(defender, damageOnHP)

    damageOnHP = math.ceil(damageOnHP)
    damageInfo:SetChangeHP(-damageOnHP)
end

---修改目标血量
---@param damageInfo DamageInfo
---@param defender Entity
function CalcDamageService:_ModifyDefenderHP(defender, damageInfo, noTrigger)
    local originalHP = defender:Attributes():GetCurrentHP()
    local maxHP = defender:Attributes():CalcMaxHp()
    local curHP = defender:Attributes():GetCurrentHP()
    local changeHP = damageInfo:GetChangeHP()
    local damageType = damageInfo:GetDamageType()

    --除了复活其他情况都是错误
    if curHP == 0 and changeHP > 0 then
        Log.error("ModifyDefenderHP add hp to a dead entity:", defender:GetID())
    end

    local spilled = 0
    if changeHP + curHP > maxHP then
        spilled = changeHP + curHP - maxHP
    end

    --血量实际的变化值
    local hpAndShieldChangeValue = 0
    if damageType == DamageType.Recover then
        --加血，溢出减飘字
        hpAndShieldChangeValue = changeHP - spilled
    else
        --伤害全被血条盾裆下，血量变化是0
        --伤害扣血，伤害和剩余血量的最大值 （伤害是负数）
        hpAndShieldChangeValue = math.max(changeHP, -curHP)
        local shieldCostDamage = damageInfo:GetShieldCostDamage()
        if shieldCostDamage then
            hpAndShieldChangeValue = hpAndShieldChangeValue - damageInfo:GetShieldCostDamage()
        end
    end
    damageInfo:SetHpAndShieldChangeValue(hpAndShieldChangeValue)

    --逻辑掉血
    curHP = math.floor(math.max(math.min(curHP + changeHP, maxHP), 0))
    defender:Attributes():Modify("HP", curHP)

    if defender:HasMonsterID() and defender:MonsterID():IsWorldBoss() then
        defender:Attributes():Modify("HP", BattleConst.WorldBossHP)
    end

    self._world:GetSyncLogger():Trace(
        {
            key = "_ModifyDefenderHP",
            entityID = defender:GetID(),
            changeHP = changeHP,
            curHP = curHP
        }
    )
    self:LogNotice(" _ModifyDefenderHP() entityID=", defender:GetID(), " changeHP=", changeHP, " curHP=", curHP)

    if noTrigger then
        --[[
            这个接口可能用在单位组装时的buff添加环节
            如果这里没有拦住，配置上又正好有下面的通知会触发的东西，又在修改生命值操作之前挂载
            则相关通知将被触发
        ]]
        return
    end

    local svcTrigger = self._world:GetService("Trigger")
    local damageSrcID = damageInfo:GetAttackerEntityID()
    if defender:HasPetPstID() or defender:HasTeam() then
        local nt = NTPlayerHPChange:New(defender, curHP, maxHP, spilled, changeHP, damageSrcID)
        nt:SetDamageType(damageInfo:GetDamageType())
		nt:SetAttackPos(damageInfo:GetAttackPos())
		nt:SetDamageInfo(damageInfo)
        svcTrigger:Notify(nt)
        if changeHP < 0 then
            self._world:GetDataLogger():AddDataLog("OnPetBehit", defender, damageInfo:GetDamageValue())
        else
            self._world:GetDataLogger():AddDataLog("OnPetAddBlood", changeHP, spilled)
        end
        if curHP == 0 and defender:HasTeam() then
            defender:AddTeamDeadMark()
        end
    elseif defender:HasMonsterID() then
        self:MonsterHPChangeNT(defender, curHP, maxHP,changeHP,damageSrcID,damageInfo)
        if originalHP ~= 0 and curHP == 0 then
            local skillID = damageInfo:GetSkillID()
            if not table.icontains(BattleConst.PetMiyaNotCollectSoulsSkillIDs, skillID) then
                local casterEntity = self._world:GetEntityByID(damageSrcID)
                local effectType = damageInfo:GetSkillEffectType()
                --状态机是主动技 and 技能效果不是25
                ---@type GameFSMComponent
                local gameFsmCmpt = self._world:GameFSM()
                if
                    casterEntity and effectType ~= SkillEffectType.RandAttack and
                        gameFsmCmpt:CurStateID() == GameStateID.ActiveSkill
                 then
                    --只考虑Super  不考虑Summoner
                    if casterEntity:HasSuperEntity() then
                        casterEntity = casterEntity:GetSuperEntity()
                    end
                    --攻击者是光灵
                    if casterEntity:HasPetPstID() then
                        local ntCollectSouls = NTCollectSouls:New(casterEntity, 1, {defender})
                        svcTrigger:Notify(ntCollectSouls)
                    end
                end
            end
        end
    elseif defender:Trap() then
        local nt = NTTrapHpChange:New(defender, curHP, maxHP)
        nt:SetChangeHP(changeHP)
        nt:SetDamageSrcEntityID(damageSrcID)
        nt:SetDamageType(damageInfo:GetDamageType())
		nt:SetDamageInfo(damageInfo)
		nt:SetAttackPos(damageInfo:GetAttackPos())
        svcTrigger:Notify(nt)
    elseif defender:ChessPet() then
        local nt = NTChessHPChange:New(defender, curHP, maxHP)
        nt:SetChangeHP(changeHP)
        nt:SetDamageSrcEntityID(damageSrcID)
        nt:SetDamageType(damageInfo:GetDamageType())
        nt:SetAttackPos(damageInfo:GetAttackPos())
        nt:SetDamageInfo(damageInfo)
        svcTrigger:Notify(nt)
    end
    if defender:HasMonsterID() and defender:MonsterID():GetDamageSyncMonsterID() then
        local syncChangeHP = damageInfo:GetChangeHP()
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local entityList =  utilDataSvc:FindMonsterByMonsterID(defender:MonsterID():GetDamageSyncMonsterID())
        for i, entity in ipairs(entityList) do
            local syncMaxHP = entity:Attributes():CalcMaxHp()
            local syncCurHP = entity:Attributes():GetCurrentHP()
            --local syncChangeHP = damageInfo:GetChangeHP()
            syncCurHP = math.floor(math.max(math.min(syncCurHP + syncChangeHP, syncMaxHP), 0))
            entity:Attributes():Modify("HP", syncCurHP)
            self._world:GetSyncLogger():Trace(
                    {
                        key = "_ModifyDefenderHP",
                        entityID = entity:GetID(),
                        changeHP = syncChangeHP,
                        curHP = syncCurHP
                    }
            )
            self:LogNotice(" _ModifyDefenderHP() entityID=", entity:GetID(), " changeHP=", syncChangeHP, " curHP=", syncCurHP)
            --世界boss 记录被同步伤害
            ---@type BattleStatComponent
            local stateCmpt = self._world:BattleStat()
            ---@type MonsterIDComponent
            local syncMonsterIDCmpt = entity:MonsterID()
            if syncMonsterIDCmpt:IsWorldBoss() then
                if syncChangeHP < 0 then--20230525 世界boss只记录同步伤害，不记录同步加血
                    stateCmpt:AddMonsterBeHitDamageValue(entity:GetID(), syncChangeHP * -1, 0)
                    syncMonsterIDCmpt:AddMonsterBeHitDamage(syncChangeHP * -1)
                end
            end
            ---@type DamageInfo
            local newDamageInfo = DamageInfo:New()
            newDamageInfo:Clone(damageInfo)
            newDamageInfo:SetTargetEntityID(entity:GetID())

            self:MonsterHPChangeNT(entity, syncCurHP, syncMaxHP,syncChangeHP,damageSrcID,newDamageInfo)
        end
    end
end



function CalcDamageService:MonsterHPChangeNT(defender, curHP, maxHP,changeHP,damageSrcID,damageInfo)
    local svcTrigger = self._world:GetService("Trigger")
    local nt = NTMonsterHPCChange:New(defender, curHP, maxHP, self.__NTMonsterHPCChangeCount)
    nt:SetChangeHP(changeHP)
    nt:SetDamageSrcEntityID(damageSrcID)
    nt:SetDamageType(damageInfo:GetDamageType())
    nt:SetAttackPos(damageInfo:GetAttackPos())
    nt:SetDamageInfo(damageInfo)
    svcTrigger:Notify(nt)
    self.__NTMonsterHPCChangeCount = self.__NTMonsterHPCChangeCount + 1
end

--护盾抵挡伤害,返回护盾抵挡的伤害值
function CalcDamageService:_CalcHealthShield(defenderEntity, damage)
    local shieldCostDamage = 0 --血条减少的伤害值
    local buffCmpt = defenderEntity:BuffComponent()
    local shield = buffCmpt:GetBuffValue("HPShield") or 0
    local shieldDelta = 0
    if shield == 0 then --没有血量护盾，不会影响伤害值
        return shieldCostDamage, shield, shieldDelta
    end
    Log.debug("Calc damage hp shiled, defenderID: ",defenderEntity:GetID()," shield: ",shield)

    local buffCmpt = defenderEntity:BuffComponent()
    if not buffCmpt then --机关不带buff组件
        return shieldCostDamage, shield, shieldDelta
    end

    --诺尔5阶觉醒-超盾免疫
    if shield > 0 and shield < damage then
        if buffCmpt:GetBuffValue("HPShieldLockHP") then
            shieldDelta = -shield
            buffCmpt:SetBuffValue("HPShield", 0)
            return damage, 0, shieldDelta
        end
    end

    local curShield = shield - damage
    if curShield > 0 then
        shieldCostDamage = damage
    else
        shieldCostDamage = shield
    end

    --护盾被减到0，移除
    if curShield <= 0 then
        curShield = 0
    end
    shieldDelta = curShield - shield
    ---重置护盾值
    buffCmpt:SetBuffValue("HPShield", curShield)

    return shieldCostDamage, curShield, shieldDelta
end
--有对应buff 伤害会转为诅咒血条，此时所有伤害都穿盾（血条盾和次数盾）
function CalcDamageService:_NeedCurseHpTrans(attackerEntity,defenderEntity)
    local canTrans = false
    ---@type BuffComponent
    local attackerBuffCmpt = attackerEntity:BuffComponent()
    ---@type BuffComponent
    local defenderBuffCmpt = defenderEntity:BuffComponent()
    if (not attackerBuffCmpt) or (not defenderBuffCmpt) then
        return canTrans
    end
    local defenderHasCurseHp = defenderBuffCmpt:IsCurseHPEnabled()
    if not defenderHasCurseHp then
        return canTrans
    end
    local attackerTransPercent = attackerBuffCmpt:GetBuffValue("TransDamageToCurseHp")
    if not attackerTransPercent then
        return canTrans
    end
    canTrans = true
    return canTrans
end
--伤害转为加诅咒血条
function CalcDamageService:_CalcCurseHpTrans(attackerEntity,defenderEntity, damage)
    local canTrans = false
    ---@type BuffComponent
    local attackerBuffCmpt = attackerEntity:BuffComponent()
    ---@type BuffComponent
    local defenderBuffCmpt = defenderEntity:BuffComponent()
    if (not attackerBuffCmpt) or (not defenderBuffCmpt) then
        return canTrans
    end
    local defenderHasCurseHp = defenderBuffCmpt:IsCurseHPEnabled()
    if not defenderHasCurseHp then
        return canTrans
    end
    local attackerTransPercent = attackerBuffCmpt:GetBuffValue("TransDamageToCurseHp")
    if not attackerTransPercent then
        return canTrans
    end
    canTrans = true

    local transCurseValue = math.ceil(damage * attackerTransPercent)
    ---@type BuffLogicService
    local bufflsvc = self._world:GetService("BuffLogic")

    local beforeCurseHpVal = defenderBuffCmpt:GetCurseHPValue(true)
    local afterCurseHpVal = bufflsvc:ChangeCurseHP(defenderEntity,transCurseValue)
    local curseHpModifyVal = afterCurseHpVal - beforeCurseHpVal
    local costDamage = damage
    return canTrans,costDamage, afterCurseHpVal, curseHpModifyVal,transCurseValue
end

--处理即死buff
function CalcDamageService:CalcSecKillBuff(defenderEntity, damage)
    ---@type BuffComponent
    local buffCmpt = defenderEntity:BuffComponent()
    if buffCmpt == nil then
        return damage
    end
    local isTriggerSecKill = false
    local percent = buffCmpt:GetBuffValue("SecKillHPPercent")
    if percent then
        local maxHP = defenderEntity:Attributes():CalcMaxHp()
        local curHP = defenderEntity:Attributes():GetCurrentHP()
        local killHP = maxHP * percent
        if curHP - damage < killHP then
            damage = curHP --保证死亡
            isTriggerSecKill = true
        end
    end
    return damage, isTriggerSecKill
end

--处理锁血buff
function CalcDamageService:CalcLockHP(defenderEntity, damage)
    ---@type BuffComponent
    local buffCmpt = defenderEntity:BuffComponent()
    if buffCmpt == nil then
        return damage
    end
    ---@type BuffLogicService
    local bufflsvc = self._world:GetService("BuffLogic")
    local hasLockHPBuff, isLock = bufflsvc:CheckEntityLockHP(defenderEntity)

    local isTriggerHPLock = false
    if hasLockHPBuff then
        if isLock then
            damage = 0
            return damage
        end
        damage, isTriggerHPLock = self:DoLockCostHp(defenderEntity, buffCmpt, damage)
        return damage, isTriggerHPLock
    end

    if not hasLockHPBuff and buffCmpt:GetBuffValue("NumLockHP") then
        damage, isTriggerHPLock = self:DoNumLockCostHp(defenderEntity, buffCmpt, damage)
        return damage, isTriggerHPLock
    end

    return damage
end

---@param  buffComponent BuffComponent
---@return  number 实际掉血
function CalcDamageService:DoNumLockCostHp(defenderEntity, buffComponent, damage)
    local curHp = defenderEntity:Attributes():GetCurrentHP()
    local maxHp = defenderEntity:Attributes():CalcMaxHp()
    curHp = curHp - damage
    if curHp < 0 then
        curHp = 0
    end

    local isTriggerHPLock = false
    local numLockHP = buffComponent:GetBuffValue("NumLockHP")
    --血量低于锁血数值
    if curHp < numLockHP then
        curHp = numLockHP
        isTriggerHPLock = true
        damage = defenderEntity:Attributes():GetCurrentHP() - numLockHP
    end

    return damage, isTriggerHPLock
end

---@param  buffComponent BuffComponent
---@return  number 实际掉血
function CalcDamageService:DoLockCostHp(defenderEntity, buffComponent, damage)
    local lockHpList = buffComponent:GetBuffValue("LockHPList")
    local curHp = defenderEntity:Attributes():GetCurrentHP()
    local maxHp = defenderEntity:Attributes():CalcMaxHp()
    curHp = curHp - damage
    if curHp < 0 then
        curHp = 0
    end
    local leftHpPercent = curHp / maxHp * 100

    ---@type BuffLogicService
    local buffsvc = self._world:GetService("BuffLogic")
    local lockHpPercent, index = buffsvc:GetLockHPInfo(defenderEntity, damage)

    local isTriggerHPLock = false
    if lockHpPercent ~= 0 then
        local curRound = self._world:BattleStat():GetCurWaveTotalRoundCount()
        local gameFsmStateID
        local hasGameFsm = self._world:HasGameFSM()
        if hasGameFsm then
            ---@type GameFSMComponent
            local gameFsmCmpt = self._world:GameFSM()
            gameFsmStateID = gameFsmCmpt:CurStateID()
        end
        isTriggerHPLock = true
        ---由于可能在各种玩家回合进入锁血状态,也可能在怪物回合被各种dot或者机关打到锁血 所以要传状态
        buffComponent:AddHpLockState(curRound, lockHpPercent, index, gameFsmStateID)
        damage = defenderEntity:Attributes():GetCurrentHP() - math.floor(maxHp * (lockHpPercent / 100))
        self._world:GetService("Trigger"):Notify(NTHPLock:New(index, lockHpPercent, defenderEntity))
    end
	
    local numLockHP = buffComponent:GetBuffValue("NumLockHP")
    if numLockHP then
        --血量低于锁血数值
        if curHp < numLockHP then
            curHp = numLockHP
            isTriggerHPLock = true
        end
    end
	
    return damage, isTriggerHPLock
end

---回合切换后清空本次锁血结果
---@param  buffInstance BuffInstance
function CalcDamageService:ResetLockHp(defenderEntity, buffInstance)
    ---@type BuffComponent
    local buffComponent = buffInstance:Entity():BuffComponent()
    buffComponent:ResetHPLockState()
end

---引导关卡使用的锁血
function CalcDamageService:DoGuideLockPlayerHPPercent(defenderEntity, damageOnHP)
    ---@type BuffComponent
    local buffComponent = defenderEntity:BuffComponent()
    local buffInstance = buffComponent:GetSingleBuffByBuffEffect(BuffEffectType.GuideLockPlayerHPPercent)
    if buffInstance then
        ---@type AttributesComponent
        local attrCmpt = defenderEntity:Attributes()
        local curHp = attrCmpt:GetCurrentHP()
        local maxHp = attrCmpt:CalcMaxHp()
        local lockPercent = buffComponent:GetBuffValue("GuideLockHPPercent")
        local minHP = math.floor(maxHp * lockPercent / 100)
        local leftHP = math.max(0, curHp - damageOnHP)
        if leftHP < minHP then
            damageOnHP = math.max(0, curHp - minHP)
        end
    end

    return damageOnHP
end

function CalcDamageService:DoDropAsset(defenderEntity, damageInfo)
    ---@type BuffComponent
    local buffCmpt = defenderEntity:BuffComponent()
    if buffCmpt == nil then
        return
    end
    ---@type DropService
    local dropService = self._world:GetService("Drop")
    local buffDataArray = buffCmpt:GetBuffArray()
    local dropIDArray = {}
    for index = #buffDataArray, 1, -1 do
        ---@type BuffInstance
        local buffInstance = buffDataArray[index]
        local buffEffectType = buffInstance:GetBuffEffectType()
        local dropID = 0
        local effectID = 0
        if buffEffectType == BuffEffectType.HitDropByCount then
            dropID, effectID = self:_DoDropAssetByHit(defenderEntity, buffInstance)
        end
        if buffEffectType == BuffEffectType.HitDropByHP then
            dropID, effectID = self:_DoDropAssetByHp(defenderEntity, buffInstance)
        end
        if dropID ~= 0 then
            table.insert(dropIDArray, {id = dropID, effect = effectID})
        end
    end
    ---@type DropService
    local dropService = self._world:GetService("Drop")

    local dropAssetList = {}
    for _, v in ipairs(dropIDArray) do
        local dropAsset = dropService:DoActorDrop(v.id, defenderEntity:GetID())
        if dropAsset then
            table.insert(dropAssetList, {asset = dropAsset, effect = v.effect})
        end
    end

    damageInfo:SetDropAssetList(dropAssetList)
end

function CalcDamageService:_DoDropAssetByHit(defenderEntity, buffInstance)
    ---@type BuffComponent
    local buffComponent = buffInstance:Entity():BuffComponent()
    local hitCount = buffComponent:GetBuffValue("DropHitCount")
    local dropList = buffComponent:GetBuffValue("DropListByHit")
    local hitIndex = buffComponent:AddHitIndex()
    local dropID = 0
    local effectID = 0
    if hitIndex <= hitCount then
        if hitIndex > #dropList then
            dropID = 0
        else
            dropID = dropList[hitIndex].DropGroupID
        end
        effectID = buffComponent:GetBuffValue("DropByCountEffectID")
    end
    return dropID, effectID
end

function CalcDamageService:_DoDropAssetByHp(defenderEntity, buffInstance)
    ---@type BuffComponent
    local buffComponent = buffInstance:Entity():BuffComponent()

    ---@type AttributesComponent
    local attrCmpt = defenderEntity:Attributes()

    local curHp = attrCmpt:GetCurrentHP()
    local maxHp = attrCmpt:CalcMaxHp()

    local leftHpPercent = curHp / maxHp * 100
    local dropList = buffComponent:GetBuffValue("DropListByHP")
    local saveHpPercent, dropID
    for _, v in ipairs(dropList) do
        if v.hpPercentEnd >= leftHpPercent and v.hpPercentBegin < leftHpPercent then
            saveHpPercent = v.hpPercentEnd
            dropID = v.DropGroupID
        end
    end
    local effectID = buffComponent:GetBuffValue("DropByHPEffectID")
    if saveHpPercent and not buffComponent:IsHPPercentHasDrop(saveHpPercent) and dropID then
        buffComponent:AddHasDropHpPercent(saveHpPercent)
        return dropID, effectID
    end
    return 0, effectID
end

---终止怪物AI行动
function CalcDamageService:_DisableMonsterAI(defenderEntity)
    ---只处理空血状态
    local curHp = defenderEntity:Attributes():GetCurrentHP()
    if curHp == nil or curHp > 0 then
        return
    end

    --只处理怪物的逻辑终止，机关并不处理
    if not defenderEntity:HasMonsterID() then
        return
    end

    ---@type GameFSMComponent
    local gameFsmCmpt = self._world:GameFSM()
    ---@type GameStateID
    local curStateID = gameFsmCmpt:CurStateID()
    ---只在怪物回合处理死亡刷新问题，其他回合不需要统一处理
    if curStateID ~= GameStateID.MonsterTurn then
        return
    end

    if not defenderEntity:HasDeadMark() then
        if defenderEntity:HasMonsterID() then
            ---@type MonsterShowLogicService
            local mstrsvc = self._world:GetService("MonsterShowLogic")
            mstrsvc:AddMonsterDeadMark(defenderEntity)
        else
            defenderEntity:AddDeadMark()
        end
    end

    ---终止AI
    ---@type AIComponentNew
    local aiCmpt = defenderEntity:AI()
    if aiCmpt ~= nil then
        aiCmpt:CancelLogic()
    end
end

---@param defender Entity
function CalcDamageService:_StatData(defender)
    if defender:HasPetPstID() or defender:HasTeam() then
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        battleStatCmpt:AddPlayerBeHitCount(1)
    end
end
