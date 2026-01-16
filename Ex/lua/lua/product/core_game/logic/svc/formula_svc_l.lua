require("formula_svc_base_l")

local NoFinalProcessFormulaID = {
    FormulaNumberType.CalcDamage_130, -- 130是对局机制(世界法则)扣血，不吃最终加成
    FormulaNumberType.AbsoluteRemainHP,
	FormulaNumberType.DeadDamage,
	FormulaNumberType.RealTransmitDamage
}

local No1DamageAtLeastFormulaID = {
    FormulaNumberType.AbsoluteRemainHP
}

--[2020-12-10修改] damageparam表示公式使用的参数列表，从配置传进来的，只读table
function FormulaService:CalcDamageByFormulaID(attacker, defender, damageParam, formulaID, damageGridPos)
    --local formulaFunStr = "CalcDamage_" .. formulaID
    --local func = FormulaService[formulaFunStr]
    local func = self._formulaList[formulaID]
    if not func then
        Log.exception("### [Formula] can not find func", formulaID)
        return
    end
    local val, damageType, costPercent = func(self, attacker, defender, damageParam, damageGridPos)

    local defenderFinal = self:_CalcDefenderBeHitDamageParam(defender)
    if not table.icontains(NoFinalProcessFormulaID, formulaID) then
        val = val * defenderFinal
        val = self:_ProcessFinalDamage(val,damageType, defender, attacker, damageParam, damageGridPos)
    end

    local isRoundRequired = not ((damageType == DamageType.RealDead) or (table.icontains(No1DamageAtLeastFormulaID, formulaID)))

    ---N33灾典词条通过转色格子数量造成伤害，策划大爷不确定公式会改来改去
    if damageParam.GetN33DamageMul and  damageParam:GetN33DamageMul()>1 then
        val =val* damageParam:GetN33DamageMul()
    end

    if isRoundRequired then
        val = self:_RET(val)
    end

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "FinalDamage",
            desc = "***被击者最终伤害增伤系数[defenderFinal] 最终伤害值[val]***",
            defenderFinal = defenderFinal,
            val = val
        }
    )

    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "FinalDamage",
            desc = "***最终加成阶段结束：最终伤害值[val]***",
            val = val
        }
    )

    return val, damageType, costPercent
end

---普攻伤害
function FormulaService:CalcDamage_1(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local damagePercent =
        damageParams.percent + self:_CalcSkillParam_NormalSkill(attacker) +
        self:_CalcSkillParam_DefenderSkillAmpfily(defender)
    local comboParam = self:CalcComboParam(attacker)
    local normalChainParam = self:CalcNormalChainParam(attacker)
    local superGridParam = self:CalcSuperGridParam(attacker)
    local poorGridParam = self:CalcPoorGridParam(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local normalSkillAbsorbParam = self:CalcAbsorbParam_NormalSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_NormalSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_NormalSkill(attacker)
    local val =
        baseDamage * (damagePercent + comboParam + normalChainParam + superGridParam + poorGridParam) * elementParam *
        normalSkillAbsorbParam *
        primarySecondaryParam *
        critParam *
        skillIncreaseParam *
        skillFinalParam

    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_1",
            desc = "公式1：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * (普攻技能系数[damagePercent] + combo系数[comboParam] + 普攻连线系数[normalChainParam] + 强化格子系数[superGridParam] + 弱化格子系数[poorGridParam]) * 属性克制系数[elementParam] * 普攻吸收系数[normalSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            comboParam = comboParam,
            normalChainParam = normalChainParam,
            superGridParam = superGridParam,
            poorGridParam = poorGridParam,
            elementParam = elementParam,
            normalSkillAbsorbParam = normalSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

---怪伤害
function FormulaService:CalcDamage_2(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local monsterSkillParam = self:_CalcSkillParam_MonsterSkill(attacker)
    local damagePercent = damageParams.percent + monsterSkillParam
    local elementParam = self:CalcElementParam(attacker, defender)
    local damageAbsorbParam = self:CalcAbsorbParam_Damage()
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_MonsterSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_MonsterSkill(attacker)
    local val =
        baseDamage * damagePercent * elementParam * damageAbsorbParam * critParam * skillIncreaseParam * skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            desc = "公式2：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 属性克制[elementParam] * 吸收系数[damageAbsorbParam] * 暴击系数[critParam] * 技能提升[skillIncreaseParam] * 最终系数[skillFinalParam]",
            key = "CalcDamage_2",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            monsterSkillParam = monsterSkillParam,
            elementParam = elementParam,
            damageAbsorbParam = damageAbsorbParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

---机关真实伤害
function FormulaService:CalcDamage_3(attacker, defender, damageParam, damageGridPos)
    local trapSkillIncreaseParam = self:_CalcSkillIncreaseParam_TrapSkill(attacker) --机关伤害倍率
    local val = 10000 * damageParam.percent * trapSkillIncreaseParam
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_3",
            desc = "公式3：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 技能提升[trapSkillIncreaseParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = 10000,
            damagePercent = damageParam.percent,
            trapSkillIncreaseParam = trapSkillIncreaseParam
        }
    )

    return val, DamageType.Real
end

---连琐技伤害
function FormulaService:CalcDamage_4(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local chainSkillParam = self:_CalcSkillParam_ChainSkill(attacker)
    local damagePercent = damageParams.percent + chainSkillParam
    local chainChainParam = self:CalcChainChainParam(attacker)
    local superGridParam = self:CalcSuperGridParam(attacker)
    local poorGridParam = self:CalcPoorGridParam(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local chainSkillAbsorbParam = self:CalcAbsorbParam_ChainSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_ChainSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_ChainSkill(attacker)
    local val =
        baseDamage * damagePercent * (1 + chainChainParam + superGridParam + poorGridParam) * elementParam * chainSkillAbsorbParam *
        primarySecondaryParam *
        critParam *
        skillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_4",
            desc = "公式4：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * (1+连锁技连锁系数[chainChainParam]+强化格子系数[superGridParam]+弱化格子系数[poorGridParam]) * 元素克制系数[elementParam] * 连锁技吸收系数[chainSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            chainSkillParam = chainSkillParam,
            chainChainParam = chainChainParam,
            superGridParam = superGridParam,
            poorGridParam = poorGridParam,
            elementParam = elementParam,
            chainSkillAbsorbParam = chainSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

---主动技伤害
function FormulaService:CalcDamage_5(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParams, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParams.percent + activeSkillParam

    local val =
        baseDamage * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_5",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式5：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam]",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

--浮游炮
function FormulaService:CalcDamage_6(attacker, defender, damageParam, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local val = baseDamage * elementParam * damageParam.percent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_6",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式6：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 元素克制[elementParam] * 技能系数[damagePercent]",
            val = val,
            baseDamage = baseDamage,
            elementParam = elementParam,
            damagePercent = damageParam.percent
        }
    )

    return val, DamageType.Normal
end

--机关落雷：带属性的机关对人和怪的伤害，x*最大生命值*属性克制系数
function FormulaService:CalcDamage_7(attacker, defender, damageParam, damageGridPos)
    local defenderMaxHp = self:_Attributes(defender):CalcMaxHp()
    local trapSkillIncreaseParam = self:_CalcSkillIncreaseParam_TrapSkill(attacker) --机关伤害倍率
    local trapElementParam = self:CalcTrapElementParam(attacker, defender)
    local val = defenderMaxHp * damageParam.percent * trapElementParam * trapSkillIncreaseParam
    val = self:_RET(val)
    local costPercent = damageParam.percent * trapElementParam * trapSkillIncreaseParam
    local damageType = DamageType.Real
    val, damageType = self:PostProcessDeadDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_7",
            desc = "公式7：攻击者[attacker] 被击者[defender] 伤害[val] = 血量上限[maxHp] * 技能系数[damagePercent] * 元素克制[trapElementParam] * 技能提升[trapSkillIncreaseParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            maxHp = defenderMaxHp,
            damagePercent = damageParam.percent,
            trapSkillIncreaseParam = trapSkillIncreaseParam,
            trapElementParam = trapElementParam
        }
    )

    return val, DamageType.Real, costPercent
end

--buff落雷：带属性的buff对人和怪的伤害，x*最大生命值*属性克制系数
function FormulaService:CalcDamage_8(attacker, defender, damageParam, damageGridPos)
    local maxHp = self:_Attributes(defender):CalcMaxHp()
    -- 原先这个element数据就不存在，新增参数时发现参数表冲突，所以直接写成了等价的常值
    local buffElementParam = self:CalcBuffElementParam(PieceType.None, attacker, defender)
    local val = maxHp * damageParam.percent * buffElementParam
    val = self:_RET(val)
    local costPercent = damageParam.percent * buffElementParam
    local damageType = DamageType.Real
    val, damageType = self:PostProcessDeadDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_8",
            desc = "公式8：攻击者[attacker] 被击者[defender] 伤害[val] = 血量上限[maxHp] * 技能系数[damagePercent] * 元素克制[buffElementParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            maxHp = maxHp,
            damagePercent = damageParam.percent,
            buffElementParam = buffElementParam
        }
    )

    return val, DamageType.Real, costPercent
end

---卡戎被动/击退buff：基于攻击力百分比的真实伤害
function FormulaService:CalcDamage_9(attacker, defender, damageParam, damageGridPos)
    local attack = self:CalcAttack(attacker)
    local addPercent = damageParam.addPercent or 0
    local damagePercent = damageParam.percent * (1 + addPercent)
    local val = attack * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_9",
            desc = "公式9：攻击者[attacker] 被击者[defender] 伤害[val] = 攻击[attack] * (百分比[percent] * (1 + 百分比加成[addPercent]))",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            attack = attack,
            percent = damageParam.percent,
            addPercent = damageParam.addPercent,
            damagePercent = damagePercent
        }
    )

    return val, DamageType.Real
end

---风船核心：基于目标的生命上限的 百分比伤害
function FormulaService:CalcDamage_10(attacker, defender, damageParam, damageGridPos)
    local defenderMaxHp = self:_Attributes(defender):CalcMaxHp()
    local val = defenderMaxHp * damageParam.percent
    val = self:_RET(val)
    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    local costPercent = damageParam.percent
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_10",
            desc = "公式10：攻击者[attacker] 被击者[defender] 伤害[val] = 血量上限[maxHp] * 百分比[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            maxHp = defenderMaxHp,
            damagePercent = damageParam.percent
        }
    )

    return val, damageType, costPercent
end

---重伤buff专用：当前生命值的百分比伤害【真实伤害】
---wiki里一直都是当前生命值
function FormulaService:CalcDamage_11(attacker, defender, damageParam, damageGridPos)
    local defenderHp = self:_Attributes(defender):GetCurrentHP()

    local val = defenderHp * damageParam.percent
    val = self:_RET(val)
    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_11",
            desc = "公式11：攻击者[attacker] 被击者[defender] 伤害[val] = 当前血量[hp] * 百分比[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            hp = defenderHp,
            damagePercent = damageParam.percent
        }
    )

    return val, damageType
end

--流血buff专用公式【真实伤害】
function FormulaService:CalcDamage_13(attacker, defender, damageParam, damageGridPos)
    local maxHP = defender:Attributes():CalcMaxHp()
    local curHp = defender:Attributes():GetCurrentHP()
    --[[
        流血伤害加深
        2021/10/8 代码 + 配置搜索过没有IncreaseBleed这个值的设置
                  为与其他效果命名一致，从IncreaseBleed改为BleedIncrease
                  现在对应效果BuffLogicSetBleedIncrease和BuffLogicResetBleedIncrease
                  参见bl_bleed_increase.lua
    ]]
    local increaseBleed = defender:BuffComponent():GetBuffValue("BleedIncrease") or 1
    local loseHP = maxHP - curHp
    local val = loseHP * damageParam.percent * damageParam.layer * increaseBleed
    val = self:_RET(val)
    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_13",
            desc = "公式13：攻击者[attacker] 被击者[defender] 伤害[val] = 损失血量[loseHP] * 百分比[damagePercent]* 流血层数[layer]* 流血加深[inc]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            loseHP = loseHP,
            damagePercent = damageParam.percent,
            layer = damageParam.layer,
            inc = increaseBleed
        }
    )
    return val, damageType
end

--灼烧buff专用公式【真实伤害】
function FormulaService:CalcDamage_14(attacker, defender, damageParam, damageGridPos)
    local defenderHp = defender:Attributes():GetCurrentHP()
    --灼烧伤害加深
    local increaseBurn = defender:BuffComponent():GetBuffValue("BurnIncrease") or 1
    local val = math.ceil(defenderHp * damageParam.percent * damageParam.layer * increaseBurn)
    val = self:_RET(val)
    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_14",
            desc = "公式14：攻击者[attacker] 被击者[defender] 伤害[val] = 当前血量[curHP] * 百分比[damagePercent]* 层数[layer] * 灼烧加深[increaseBurn]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            curHP = defenderHp,
            damagePercent = damageParam.percent,
            layer = damageParam.layer,
            increaseBurn = increaseBurn
        }
    )
    return val, damageType
end

--中毒buff专用公式【真实伤害】
function FormulaService:CalcDamage_15(attacker, defender, damageParam, damageGridPos)
    local defenderMaxHp = defender:Attributes():CalcMaxHp()
    --中毒伤害加深
    local increasePoison = defender:BuffComponent():GetBuffValue("PoisonIncrease") or 1
    local val = defenderMaxHp * damageParam.percent * damageParam.layer * increasePoison
    val = self:_RET(val)
    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_15",
            desc = "公式15：攻击者[attacker] 被击者[defender] 伤害[val] = 最大血量[maxHP] * 伤害系数[damagePercent]* 层数[layer]*中毒伤害加深[inc]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            maxHP = defenderMaxHp,
            damagePercent = damageParam.percent,
            layer = damageParam.layer,
            inc = increasePoison
        }
    )
    return val, damageType
end

--爆炸buff专用公式【真实伤害】
function FormulaService:CalcDamage_16(attacker, defender, damageParam, damageGridPos)
    local val = damageParam.baseDamage * damageParam.percent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_16",
            desc = "公式16：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 伤害系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = damageParam.baseDamage,
            damagePercent = damageParam.percent
        }
    )
    return val, DamageType.Real
end

--即死buff专用公式【真实伤害】
function FormulaService:CalcDamage_17(attacker, defender, damageParam, damageGridPos)
    local val = defender:Attributes():GetCurrentHP()
    if val < 0 then
        val = 0
    end
    local damageType = DamageType.RealDead
    val, damageType = self:PostProcessDeadDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_17",
            desc = "公式17：攻击者[attacker] 被击者[defender] 伤害[val]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val
        }
    )
    return val, damageType
end

--反伤专用公式 （休拉德反伤：基于攻击者攻击力百分比的真实伤害）【真实伤害】【反伤的真实伤害不可再反伤】
function FormulaService:CalcDamage_18(attacker, defender, damageParam, damageGridPos)
    local attack = self:CalcAttack(attacker)
    local addPercent = damageParam.addPercent or 0
    local damagePercent = damageParam.percent * (1 + addPercent)
    local val = attack * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_18",
            desc = "公式18：攻击者[attacker] 被击者[defender] 伤害[val] = 攻击[attack] * (伤害系数[damagePercent] = 百分比[percent] * (1 + 百分比加成[addPercent]))",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            attack = attack,
            percent = damageParam.percent,
            addPercent = damageParam.addPercent,
            damagePercent = damagePercent
        }
    )

    return val, DamageType.RealReflexive
end

--反伤专用公式 （基础伤害的百分比反伤）【真实伤害】【反伤的真实伤害不可再反伤】
function FormulaService:CalcDamage_19(attacker, defender, damageParam, damageGridPos)
    local val = damageParam.baseDamage * damageParam.percent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_19",
            desc = "公式19：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 伤害系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = damageParam.baseDamage,
            damagePercent = damageParam.percent
        }
    )
    return val, DamageType.RealReflexive
end

----------------------------------------------------------------
---新增公式ID从100开始，表示某单位专用公式，没必要通用
---目的是把特殊处理限制在具体实现上，保持上层调用稳定
----------------------------------------------------------------

---黑蹄大招定制：最终伤害 = (最终ATK) * 基础伤害系数 * (1 + 额外增伤系数)
function FormulaService:CalcDamage_100(attacker, defender, damageParam, damageGridPos)
    local damagePercent = damageParam.percent
    local additionalPercent = damageParam.addPercent
    local finalAtk = self:_CalcFinalAtk(attacker)
    local rawFinalDamage = finalAtk * damagePercent * (1 + additionalPercent)
    local val = self:_RET(rawFinalDamage)
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_100",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式100：攻击者[attacker] 被击者[defender] 伤害[val] = 攻击[finalAtk] * 伤害系数[damagePercent]* (1 + 加成[additionalPercent])",
            val = val,
            finalAtk = finalAtk,
            damagePercent = damagePercent,
            additionalPercent = additionalPercent
        }
    )

    return val, DamageType.Real
end

--米娅大招专用公式
function FormulaService:CalcDamage_101(attacker, defender, damageParam, damageGridPos)
    local activeSkillPercentByDefenderHP = self:_CalcActiveSkillPercentByDefenderHP(defender, damageParam)
    if not self:_CheckPercentDamage(defender) then
        activeSkillPercentByDefenderHP = 0
    end
    damageParam.percent = damageParam.percent + activeSkillPercentByDefenderHP
    local val, damageType = self:CalcDamage_5(attacker, defender, damageParam)

    return val, damageType
end

--[维多利亚大招，吸血变伤害]
function FormulaService:CalcDamage_102(attacker, defender, damageParam, damageGridPos)
    local val = 0
    local damagePercent = damageParam:GetHpDamagePercent()
    local totalAddedHp = 0
    local targetCount = 0
    ---取出默认的范围数据
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local targetIdArray = scopeResult:GetEffectTargetIdArray()
    if targetIdArray then
        targetCount = table.count(targetIdArray)
        if targetCount > 0 then
            ---@type SkillEffectResult_AddBlood
            local addBloodResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBlood)
            if addBloodResultArray then
                for i = 1, #addBloodResultArray do
                    local value = addBloodResultArray[i]:GetAddValue()
                    totalAddedHp = totalAddedHp + value
                end
            end
        end
    end
    if totalAddedHp > 0 then
        val = damagePercent * totalAddedHp / targetCount
    end
    val = self:_RET(val)
    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_102",
            desc = "公式102：攻击者[attacker] 被击者[defender] 伤害[val] = 总回血量[totalAddedHp] / 目标数量[targetCount] * 伤害系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            damagePercent = damagePercent,
            totalAddedHp = totalAddedHp,
            targetCount = targetCount
        }
    )
    return val, damageType
end

--白矮星牵引导致的伤害加成专用公式
function FormulaService:CalcDamage_103(attacker, defender, damageParam, damageGridPos)
    local baseDamage, damageType = self:CalcDamage_5(attacker, defender, damageParam)
    local cSkillCtx = attacker:SkillContext()
    local finalDamageFixMap = cSkillCtx:GetFinalDamageFixMulVal(defender:GetID())
    local damagePercent = (1 + finalDamageFixMap)
    local val = baseDamage * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_103",
            desc = "公式103：攻击者[attacker] 被击者[defender] 伤害[val] = 基本伤害[baseDamage] * (伤害系数[damagePercent] = 1+ 距离增伤[fixMul])",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            damagePercent = damagePercent,
            baseDamage = baseDamage,
            fixMul = finalDamageFixMap
        }
    )
    return val, damageType
end

--连锁技范围重叠增伤公式
function FormulaService:CalcDamage_104(attacker, defender, damageParam, damageGridPos)
    local baseDamage, damageType = self:CalcDamage_4(attacker, defender, damageParam)
    local finalDamageFixChainScopeOverlap = 0
    local buffComp = attacker:BuffComponent()
    local chainScopeOverlapPosList = buffComp:GetBuffValue("ChainScopeOverlapPosList")
    if damageParam.damagePos and chainScopeOverlapPosList and #chainScopeOverlapPosList > 0 then
        local isInChainScopeOverlap = table.intable(chainScopeOverlapPosList, damageParam.damagePos)
        if isInChainScopeOverlap then
            finalDamageFixChainScopeOverlap = buffComp:GetBuffValue("ChainScopeOverlapChangeDamage")
        end
    end
    local damagePercent = 1 + finalDamageFixChainScopeOverlap
    local val = baseDamage * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_104",
            desc = "公式104：攻击者[attacker] 被击者[defender] 伤害[val] = 基本伤害[baseDamage] * (伤害系数[damagePercent] = 1 + 范围重叠增伤[fixMul])",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            fixMul = finalDamageFixChainScopeOverlap,
            damagePercent = damagePercent
        }
    )

    return val, damageType
end

--百斯特曼最大伤害限制公式[真实伤害]
function FormulaService:CalcDamage_105(attacker, defender, damageParam, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)
    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local defenderHp = self:_Attributes(defender):GetCurrentHP()
    local trueDamageFixParam = self:CalcTrueDamageFixParam(attacker)
    local damagePercent = damageParam.percent + trueDamageFixParam
    local val =
        (defenderHp * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam)

    local maxDamage = self:_CalcOnceMaxDamage(attacker, damageParam) or val
    val = math.min(val, maxDamage)

    local damageType = DamageType.Real
    val = self:_RET(val)
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_105",
            desc = "公式105：攻击者[attacker] 被击者[defender] 伤害[val] = min(伤害上限[maxDamage], 当前血量[hp] * (伤害系数[damagePercent] = 百分比[percent] + 修正系数[fixParam]) * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam])",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            hp = defenderHp,
            percent = damageParam.percent,
            fixParam = trueDamageFixParam,
            maxDamage = maxDamage,
            activeSkillParam = activeSkillParam,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam,
            damagePercent = damagePercent
        }
    )

    return val, damageType
end

--- 卡夫卡溅射伤害
function FormulaService:CalcDamage_106(attacker, defender, damageParam, damageGridPos)
    -- local baseDamage, damageType = self:CalcDamage_4(attacker, defender, damageParam)
    local baseDamage = attacker:SkillContext():GetSplashBaseDamage()
    local damagePercent = damageParam:GetSplashRate()
    local val = baseDamage * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_106",
            desc = "公式106：攻击者[attacker] 被击者[defender] 伤害[val] = 基本伤害[baseDamage] * 溅射伤害系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent
        }
    )

    return val, DamageType.Normal
end

--- 圣钉根据当前损失血量造成真实伤害
---@param attacker Entity
---
function FormulaService:CalcDamage_107(attacker, defender, damageParam, damageGridPos)
    ---@type BattleService
    local battle_svc = self._world:GetService("Battle")
    local curHP, maxHP = battle_svc:GetCasterHP(attacker)

    local val = maxHP - curHP
    val = self:_RET(val)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_107",
            desc = "公式107：攻击者[attacker] 被击者[defender] 伤害[val] = 最大血量[MaxHP] - 当前血量[HP]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            maxHP = maxHP,
            HP = curHP
        }
    )
    return val, DamageType.Real
end

---5号公式的真伤版本 去掉防御力
function FormulaService:CalcDamage_108(attacker, defender, damageParam, damageGridPos)
    local finalAtk = self:_CalcFinalAtk(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParam.percent + activeSkillParam

    local val =
        finalAtk * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_108",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式108：攻击者[attacker] 被击者[defender] 伤害[val] = 基础攻击力[finalAtk] * 伤害系数[damagePercent] * 元素克制[elementParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam]",
            val = val,
            finalAtk = finalAtk,
            damagePercent = damagePercent,
            activeSkillParam = activeSkillParam,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

---根据目标buff层数 乘以攻击力乘以 一个转化百分比
function FormulaService:CalcDamage_109(attacker, defender, damageParam, damageGridPos)
    local finalAtk = self:_CalcFinalAtk(attacker)

    local buffLayer = damageParam.buffLayer

    local atkPercent = damageParam.percent
    local damagePercent = atkPercent * buffLayer
    local val = finalAtk * damagePercent
    val = self:_RET(val)

    local damageType = DamageType.Normal

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_109",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式109：攻击者[attacker] 被击者[defender] 伤害[val] = 基础攻击力[finalAtk] * (伤害系数[damagePercent] = Buff层数[buffLayer] *攻击力百分比[atkPercent])",
            val = val,
            finalAtk = finalAtk,
            buffLayer = buffLayer,
            atkPercent = atkPercent,
            damagePercent = damagePercent
        }
    )

    return val, damageType
end

function FormulaService:CalcDamage_110(attacker, defender, damageParam, damageGridPos)
    ---@type SkillContextComponent
    local cSkillContext = attacker:SkillContext()
    local baseDamage = cSkillContext:GetConductBaseDamage()
    local damagePercent = cSkillContext:GetCurrentConductRate()

    local damageType = DamageType.Real

    local val = baseDamage * damagePercent

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_110",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "传导伤害公式110：攻击者[attacker] 被击者[defender] 伤害[val] = 核心伤害[baseDamage] * 传导系数[damagePercent]",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent
        }
    )

    return val, damageType
end

---泰莎专用：5变体，ActiveSkillIncreaseParam代替skillParam
function FormulaService:CalcDamage_111(attacker, defender, damageParam, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = activeSkillIncreaseParam - 1

    local val = baseDamage * damagePercent * elementParam * critParam * activeSkillAbsorbParam * skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_111",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式111：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * (伤害系数[damagePercent] = 技能提升系数[skillIncreaseParam] - 1) * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 最终系数[skillFinalParam]",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            activeSkillParam = activeSkillParam,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

---泰莎专用：108变体，ActiveSkillIncreaseParam代替skillParam
function FormulaService:CalcDamage_112(attacker, defender, damageParam, damageGridPos)
    local finalAtk = self:_CalcFinalAtk(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = activeSkillIncreaseParam - 1

    local val = finalAtk * elementParam * critParam * activeSkillAbsorbParam * damagePercent * skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_112",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式112：攻击者[attacker] 被击者[defender] 伤害[val] = 基础攻击力[finalAtk] * 元素克制[elementParam] * 主动技吸收系数[activeSkillAbsorbParam] * (伤害系数[damagePercent] = 技能提升系数[skillIncreaseParam] - 1) * 最终系数[skillFinalParam]",
            val = val,
            finalAtk = finalAtk,
            damagePercent = damagePercent,
            activeSkillParam = activeSkillParam,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

-- 5号公式变体，根据buff层数额外加percent
function FormulaService:CalcDamage_113(attacker, defender, damageParam, damageGridPos)
    local finalAtk = self:_CalcFinalAtk(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    ---@type SkillContextComponent
    local cSkillContext = attacker:SkillContext()
    local buffEffectType = cSkillContext:GetDamagePctIncreaseBuffEffectType()
    local buffMul = cSkillContext:GetDamagePctIncreaseMul()
    ---@type BuffLogicService
    local lbfsvc = self._world:GetService("BuffLogic")
    local layer = lbfsvc:GetBuffLayer(defender, buffEffectType)
    local increasedPercent = layer * buffMul

    ---@type BuffComponent
    local cBuffAttacker = attacker:BuffComponent()
    if attacker:SuperEntityComponent() then
        cBuffAttacker = attacker:GetSuperEntity():BuffComponent()
    end
    local rawLimit = cBuffAttacker:GetBuffValue("SmokeyParamLimit")
    local limit = rawLimit or (1 + increasedPercent)

    local damagePercent = damageParam.percent + activeSkillParam

    local val =
        finalAtk * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam *
        math.max((1 + increasedPercent), limit)
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical
    --local damageType = DamageType.Real

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_113",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式113：攻击者[attacker] 被击者[defender] 伤害[val] = 基础攻击力[finalAtk] * (伤害系数[damagePercent] = 百分比[percent]+主动技系数buff[activeSkillParam]) * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam] * math.max((1 + (斯莫奇系数[increasedPercent])), 衰减底线[limit])。【原始衰减底线=[rawLimit]】",
            val = val,
            finalAtk = finalAtk,
            damagePercent = damagePercent,
            activeSkillParam = activeSkillParam,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam,
            increasedPercent = increasedPercent,
            percent = damageParam.percent,
            damagePercent = damagePercent,
            limit = limit,
            rawLimit = rawLimit
        }
    )

    return val, damageType
end

---根据攻击者的防御力造成【真实伤害】
function FormulaService:CalcDamage_114(attacker, defender, damageParam, damageGridPos)
    local attackerDefence = self:CalcDefence(attacker)
    local attackerDefencePercentage = self:CalcDefencePercentage(attacker)
    local attackerDefenceConstantFix = self:CalcDefenceConstantFix(attacker)

    local attackerDefenceFianal =
        math.floor(attackerDefence * (1 + attackerDefencePercentage) + attackerDefenceConstantFix)
    local val = attackerDefenceFianal * damageParam.percent
    val = self:_RET(val)

    local damageType = DamageType.Real

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_114",
            desc = "公式114：攻击者[attacker] 被击者[defender] 伤害[val] = (攻击者防御力[attackerDefence] * (1 + 攻击者防御力百分比加成系数[attackerDefencePercentage] ) + 攻击者的防御加成绝对值[attackerDefenceConstantFix]) * 伤害系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            attackerDefence = attackerDefence,
            attackerDefencePercentage = attackerDefencePercentage,
            attackerDefenceConstantFix = attackerDefenceConstantFix,
            damagePercent = damageParam.percent
        }
    )

    return val, damageType
end

function FormulaService:CalcDamage_115(attacker, defender, damageParam, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParam.percent + activeSkillParam

    local degressiveParam = attacker:SkillContext():GetDegressiveDamageParam()

    local val =
        baseDamage * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam *
        degressiveParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_115",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式115：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 伤害系数[damagePercent] * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam] * 伤害衰减系数[degressiveParam]",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            activeSkillParam = activeSkillParam,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam,
            degressiveParam = degressiveParam
        }
    )

    return val, damageType
end

---正常攻防+玩家血量最大百分比伤害
function FormulaService:CalcDamage_116(attacker, defender, damageParam, damageGridPos)
    local baseDamage = self:CalcDamage_2(attacker, defender, damageParam)
    local critParam = self:CalcCritParam(damageParam, attacker)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local curHP, maxHP = battleService:GetCasterHP(defender)
    local val = baseDamage
    local percentDamage = damageParam:GetMaxHPDamagePercent() * maxHP
    if not self:_CheckPercentDamage(defender) then
        percentDamage = 0
    end
    val = val + percentDamage
    val = self:_RET(val)
    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_116",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式116：攻击者[attacker] 被击者[defender] 伤害[val] = 傷害公式2[baseDamage] + 伤害百分比[percent] * 最大血量[maxHP]",
            val = val,
            baseDamage = baseDamage,
            percent = damageParam:GetMaxHPDamagePercent(),
            maxHP = maxHP
        }
    )
    return val, damageType
end

---怪伤害
---@param damageParam SkillDamageEffectParam
function FormulaService:CalcDamage_117(attacker, defender, damageParam, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local monsterSkillParam = self:_CalcSkillParam_MonsterSkill(attacker)
    local damagePercent = damageParam.percent + monsterSkillParam
    local elementParam = self:CalcElementParam(attacker, defender)
    local damageAbsorbParam = self:CalcAbsorbParam_Damage()
    local critParam = self:CalcCritParam(damageParam, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_MonsterSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_MonsterSkill(attacker)
    local val =
        baseDamage * damagePercent * elementParam * damageAbsorbParam * critParam * skillIncreaseParam * skillFinalParam

    local cAttributes = defender:Attributes()
    local curHP = cAttributes:GetCurrentHP()
    local maxHP = cAttributes:CalcMaxHp()
    local percentHP = curHP / maxHP

    local defEntityHPThreshold = damageParam:GetHPThresholdFormula117()
    local increaseRate = damageParam:GetDamageIncreaseRateFormula117()

    local increaseIndex = 0
    for index, percent in ipairs(defEntityHPThreshold) do
        if percent >= percentHP then
            increaseIndex = index
        end
    end
    local specialIncreaseRate = increaseRate[increaseIndex] or 0

    val = val * (1 + specialIncreaseRate)
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            desc = "公式117：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 伤害系数[damagePercent] * 属性克制[elementParam] * 吸收系数[damageAbsorbParam] * 暴击系数[critParam] * 技能提升[skillIncreaseParam] * 最终系数[skillFinalParam] * (1 + 特殊系数[specialIncreaseRate])",
            key = "CalcDamage_117",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            monsterSkillParam = monsterSkillParam,
            elementParam = elementParam,
            damageAbsorbParam = damageAbsorbParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam,
            specialIncreaseRate = specialIncreaseRate
        }
    )

    return val, damageType
end

---世界BOSS里的黑蹄BOSS专用
function FormulaService:CalcDamage_118(attacker, defender, damageParam, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local basicPercent = damageParam.percent
    local additionalPercent = damageParam.addPercent
    local rawFinalDamage = baseDamage * basicPercent * (1 + additionalPercent)
    local val = self:_RET(rawFinalDamage)
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_118",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式118：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 百分比[basicPercent]* (1 + 加成[additionalPercent])",
            val = val,
            baseDamage = baseDamage,
            basicPercent = basicPercent,
            additionalPercent = additionalPercent
        }
    )

    return val, DamageType.Normal
end

---柯蒂觉醒2主动技强化：在5号公式结果的基础上乘受击者体型(占据格子数)^N，N为配置量
---@param attacker Entity
---@param defender Entity
function FormulaService:CalcDamage_119(attacker, defender, damageParam, damageGridPos)
    local baseDamage, damageType = self:CalcDamage_5(attacker, defender, damageParam, damageGridPos)

    local defBodyArea = defender:BodyArea():GetArea()
    local defBodyCount = #defBodyArea

    local pow = damageParam.BodyAreaPow_119
    local damagePercent = defBodyCount ^ pow

    local val = self:_RET(baseDamage * damagePercent)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_119",
            desc = "公式119：攻击者[attacker] 被击者[defender] 伤害[val] = 5号公式结果[baseDamage] * (伤害系数[damagePercent] = 受击者占格数[defBodyCount] ^ 幂系数[pow])",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            baseDamage = baseDamage,
            pow = pow,
            defBodyCount = defBodyCount,
            damagePercent = damagePercent,
            val = val
        }
    )
    return val, damageType
end

---普攻伤害,和1的区别是，每combo提升N%的普攻暴击概率，支持配置上限
function FormulaService:CalcDamage_120(attacker, defender, damageParam, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local damagePercent =
        damageParam.percent + self:_CalcSkillParam_NormalSkill(attacker) +
        self:_CalcSkillParam_DefenderSkillAmpfily(defender)
    local comboParam = self:CalcComboParam(attacker)
    local normalChainParam = self:CalcNormalChainParam(attacker)
    local superGridParam = self:CalcSuperGridParam(attacker)
    local poorGridParam = self:CalcPoorGridParam(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local normalSkillAbsorbParam = self:CalcAbsorbParam_NormalSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParamWithCombo(attacker, damageParam)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_NormalSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_NormalSkill(attacker)
    local val =
        baseDamage * (damagePercent + comboParam + normalChainParam + superGridParam + poorGridParam) * elementParam *
        normalSkillAbsorbParam *
        primarySecondaryParam *
        critParam *
        skillIncreaseParam *
        skillFinalParam

    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_120",
            desc = "公式120：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * (普攻伤害系数[damagePercent] + combo系数[comboParam] + 普攻连线系数[normalChainParam] + 强化格子系数[superGridParam] + 弱化格子系数[poorGridParam]) * 属性克制系数[elementParam] * 普攻吸收系数[normalSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            comboParam = comboParam,
            normalChainParam = normalChainParam,
            superGridParam = superGridParam,
            poorGridParam = poorGridParam,
            elementParam = elementParam,
            normalSkillAbsorbParam = normalSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

---使用上一个释放主动技的光灵的基础攻击力*系数
---@param defender Entity
function FormulaService:CalcDamage_121(attacker, defender, damageParam, damageGridPos)
    ---@type ActiveSkillComponent
    local activeSkillCmpt = defender:ActiveSkill()
    ---@type Entity
    local lastCastSkillEntity = self._world:GetEntityByID(activeSkillCmpt:GetActiveSkillCasterEntityID())
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    local attack = lastCastSkillEntity:MatchPet():GetMatchPet():GetPetAttack()

    local val = damageParam.percent * attack

    val = self:_RET(val)
    local damageType = DamageType.Normal

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_121",
            desc = "公式121：攻击者[attacker] 被击者[defender] 伤害[val] = 释放主动技宝宝基础攻击力[finalAtk] * 伤害系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            finalAtk = attack,
            damagePercent = damageParam.percent
        }
    )

    return val, damageType
end

---直接传入的伤害值，诺维亚大招
function FormulaService:CalcDamage_122(attacker, defender, damageParam, damageGridPos)
    local finalAtk = self:_CalcFinalAtk(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParam.percent + activeSkillParam
    local damageValue = damageParam.damageValue

    local val =
        damageValue * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_122",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式122：攻击者[attacker] 被击者[defender] 伤害[val] = 传入的伤害值[baseDamage] *伤害系数[damagePercent] * 元素克制[elementParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam]",
            val = val,
            baseDamage = damageValue,
            damagePercent = damagePercent,
            activeSkillParam = activeSkillParam,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end
---艾露玛主动技 伤害按角度衰减：在5号公式结果的基础上乘传入的伤害比例
---@param attacker Entity
---@param defender Entity
function FormulaService:CalcDamage_123(attacker, defender, damageParam, damageGridPos)
    local baseDamage, damageType = self:CalcDamage_5(attacker, defender, damageParam, damageGridPos)

    local damagePercent = damageParam:GetAngleDamageRate()

    local val = self:_RET(baseDamage * damagePercent)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_123",
            desc = "公式123：攻击者[attacker] 被击者[defender] 伤害[val] = 5号公式结果[baseDamage] * (传入的伤害系数[damagePercent])",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            val = val
        }
    )
    return val, damageType
end

---怪伤害（无属性）
function FormulaService:CalcDamage_124(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender)
    local monsterSkillParam = self:_CalcSkillParam_MonsterSkill(attacker)
    local damagePercent = damageParams.percent + monsterSkillParam
    local damageAbsorbParam = self:CalcAbsorbParam_Damage()
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_MonsterSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_MonsterSkill(attacker)
    local val = baseDamage * damagePercent * damageAbsorbParam * critParam * skillIncreaseParam * skillFinalParam
    val = self:_RET(val)

    local damageType = DamageType.NoElementNormal
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            desc = "公式124：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 伤害系数[damagePercent] * 吸收系数[damageAbsorbParam] * 暴击系数[critParam] * 技能提升[skillIncreaseParam] * 最终系数[skillFinalParam]",
            key = "CalcDamage_124",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            monsterSkillParam = monsterSkillParam,
            damageAbsorbParam = damageAbsorbParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end
--- max(被击者当前血量*百分比,攻击者基础防御力*百分比)【真实伤害】
---@param damageParam SkillDamageEffectParam
function FormulaService:CalcDamage_125(attacker, defender, damageParam, damageGridPos)
    local defenderHp = self:_Attributes(defender):GetCurrentHP()
    local val = defenderHp * damageParam.percent

    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)

    local attackerDefence = self:CalcDefence(attacker)
    local attackPercentage = damageParam:GetAttackPercentFormula125()
    local val2 = attackerDefence * attackPercentage

    val = self:_RET(val)
    val2 = self:_RET(val2)

    if val <= val2 then
        damageType = DamageType.Real
    end

    val = math.max(val, val2)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_125",
            desc = "公式125：攻击者[attacker] 被击者[defender] 伤害[val] = max((被击者当前血量[hp] * 百分比[damagePercent]),(攻击基础防御力[defense] * 百分比[attackPercentage]))",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            hp = defenderHp,
            damagePercent = damageParam.percent,
            defense = attackerDefence,
            attackPercentage = attackPercentage
        }
    )

    return val, damageType
end

--- 传递伤害Buff的伤害计算，【真实伤害】【传伤的真实伤害不可再反伤】
---@param attacker Entity
---@param defender Entity
---
function FormulaService:CalcDamage_126(attacker, defender, damageParam, damageGridPos)
    local changeHp = math.abs(damageParam.changeHp)
    local damagePercent = damageParam.percent

    local val = changeHp * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_126",
            desc = "公式126：攻击者[attacker] 被击者[defender] 伤害[val] = 传递者[transer]的流失血量[baseDamage] * 系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            transer = damageParam.transerID,
            val = val,
            baseDamage = changeHp,
            damagePercent = damagePercent
        }
    )
    return val, DamageType.RealReflexive
end

---公式3+玩家最大血量百分比
---@param defender Entity
function FormulaService:CalcDamage_127(attacker, defender, damageParam, damageGridPos)
    local val, damageType = self:CalcDamage_3(attacker, defender, damageParam)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local curHP, maxHP = battleService:GetCasterHP(defender)
    local maxPercent = damageParam:GetMaxHPDamagePercent()
    local exValue = maxPercent * maxHP
    if not self:_CheckPercentDamage(defender) then
        exValue = 0
    end
    local retValue = val + exValue
    retValue = self:_RET(retValue)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_127",
            desc = "公式127：攻击者[attacker] 被击者[defender] 伤害[retValue] = 公式3伤害[baseDamage]+最大血量百分比[damagePercent] * 目标最大血量[maxHP]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            retValue = retValue,
            baseDamage = val,
            damagePercent = maxPercent,
            maxHP = maxHP
        }
    )

    return retValue, damageType
end

---给战棋用的，不考虑敌方防御力的公式
---@param damageParam SkillDamageEffectParam 技能伤害结果参数
function FormulaService:CalcDamage_128(attacker, defender, damageParam, damageGridPos)
    local pureDamage = damageParam:GetPureDamage()
    return pureDamage,DamageType.Real
end

---类似传常量伤害的方式
function FormulaService:CalcDamage_129(attacker, defender, damageParam, damageGridPos)
    local simpleDamage = damageParam.simpleDamage or 0
    simpleDamage = damageParam.percent * simpleDamage
    return simpleDamage,DamageType.Real
end

---对局机制（如释放主动技扣血、剩余回合数不足扣血）扣除生命值专用，专门处理过不吃任何增减益（受伤加重/受伤减轻等）
---@param attacker Entity
function FormulaService:CalcDamage_130(attacker, defender, damageParam, damageGridPos)
    local val = self:_RET(damageParam.hp)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_130",
                desc = "对局机制专用公式130：被击者[defender] 最终伤害[val]由逻辑计算得出，公式不做处理，不受伤害加重及受伤减轻影响。",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
            }
    )
    return val, DamageType.Real
end

---莲被动专用公式：使用攻击者的队伍最大血量乘单独的配置系数，最后乘SanSkillFinalParam加成
---@param attacker Entity
function FormulaService:CalcDamage_131(attacker, defender, damageParam, damageGridPos)
    local eCaster = attacker
    if attacker:HasSuperEntity() then
        eCaster = attacker:GetSuperEntity()
    end
    local eAttackerTeam = eCaster:Pet():GetOwnerTeamEntity()
    local maxHP = eAttackerTeam:Attributes():CalcMaxHp()
    local percent = damageParam.percent
    local elementParam = self:CalcElementParam(attacker, defender)
    local activeSkillFinal = self:_CalcSkillFinalParam_ActiveSkill(attacker)

    local val = maxHP * percent * elementParam * activeSkillFinal
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_131",
            desc = "公式131：攻击者[attacker] 被击者[defender] 最终伤害[val] = 最大生命值[maxHP] * 技能系数[damagePercent] * 元素加成[elementParam] * buff终伤加成[skillFinalParam] 【觉3加成在最终处理内】",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            maxHP = maxHP,
            damagePercent = percent,
            elementParam = elementParam,
            skillFinalParam = activeSkillFinal
        }
    )

    return val, DamageType.Real
end

---连琐技伤害，4号公式为基础 但是chain相关参数不参与计算
function FormulaService:CalcDamage_132(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local chainSkillParam = self:_CalcSkillParam_ChainSkill(attacker)
    local damagePercent = damageParams.percent + chainSkillParam
    local elementParam = self:CalcElementParam(attacker, defender)
    local chainSkillAbsorbParam = self:CalcAbsorbParam_ChainSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_ChainSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_ChainSkill(attacker)
    local val =
        baseDamage * damagePercent * elementParam * chainSkillAbsorbParam * primarySecondaryParam * critParam *
        skillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_132",
            desc = "公式132：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制系数[elementParam] * 连锁技吸收系数[chainSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            chainSkillParam = chainSkillParam,
            elementParam = elementParam,
            chainSkillAbsorbParam = chainSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end
---连琐技伤害，133号公式为基础 多一个溅射系数
function FormulaService:CalcDamage_133(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local chainSkillParam = self:_CalcSkillParam_ChainSkill(attacker)
    local damagePercent = damageParams.percent + chainSkillParam
    local elementParam = self:CalcElementParam(attacker, defender)
    local chainSkillAbsorbParam = self:CalcAbsorbParam_ChainSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_ChainSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_ChainSkill(attacker)
    local splashRate = damageParams:GetSplashRate()
    local val =
    baseDamage * damagePercent * elementParam * chainSkillAbsorbParam * primarySecondaryParam * critParam *
            skillIncreaseParam *
            skillFinalParam * splashRate
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_133",
                desc = "公式133：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制系数[elementParam] * 连锁技吸收系数[chainSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam] *溅射系数[splashRate]",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                baseDamage = baseDamage,
                damagePercent = damagePercent,
                chainSkillParam = chainSkillParam,
                elementParam = elementParam,
                chainSkillAbsorbParam = chainSkillAbsorbParam,
                primarySecondaryParam = primarySecondaryParam,
                critParam = critParam,
                skillIncreaseParam = skillIncreaseParam,
                skillFinalParam = skillFinalParam,
                splashRate = splashRate,
            }
    )

    return val, damageType
end
---早苗主动技伤害 使用指定机关计算finalAttack
function FormulaService:CalcDamage_134(attacker, defender, damageParams, damageGridPos)
    local oriAttack = self:CalcAttack(attacker)
    local trapAttack = 0
    local trapFinalAttack = 0
    if damageParams:GetUseTrapAttackTrapID() then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local trapEntitys = utilDataSvc:GetTrapByID(damageParams:GetUseTrapAttackTrapID())
        local useAtkEntity = nil
        if #trapEntitys > 0 then
            useAtkEntity = trapEntitys[1]
        end
        if useAtkEntity then
            trapFinalAttack = self:_CalcFinalAtk(useAtkEntity)
            -- local useAttr = self:_Attributes(useAtkEntity)
            -- if useAttr then
            --     trapAttack = useAttr:GetAttribute("Attack")
            --     --用机关攻击力替换一下attacker属性，之后恢复
            --     self:_Attributes(attacker):Modify("Attack",trapAttack)
            -- end
        end
    end
    local baseDamage = self:CalcBaseDamageWithSpecificFinalAttack(attacker, defender,trapFinalAttack, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParams, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParams.percent + activeSkillParam

    local val =
        baseDamage * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    --恢复攻击力
    -- self:_Attributes(attacker):Modify("Attack",oriAttack)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_134",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式134：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam]",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

--- 早苗 连琐技伤害 使用指定机关计算finalAttack
function FormulaService:CalcDamage_135(attacker, defender, damageParams, damageGridPos)
    local oriAttack = self:CalcAttack(attacker)
    local trapAttack = 0
    local trapFinalAttack = 0
    if damageParams:GetUseTrapAttackTrapID() then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local trapEntitys = utilDataSvc:GetTrapByID(damageParams:GetUseTrapAttackTrapID())
        local useAtkEntity = nil
        if #trapEntitys > 0 then
            useAtkEntity = trapEntitys[1]
        end
        if useAtkEntity then
            trapFinalAttack = self:_CalcFinalAtk(useAtkEntity)
            -- local useAttr = self:_Attributes(useAtkEntity)
            -- if useAttr then
            --     trapAttack = useAttr:GetAttribute("Attack")
            --     --用机关攻击力替换一下attacker属性，之后恢复
            --     self:_Attributes(attacker):Modify("Attack",trapAttack)
            -- end
        end
    end
    local baseDamage = self:CalcBaseDamageWithSpecificFinalAttack(attacker, defender,trapFinalAttack, damageGridPos)
    local chainSkillParam = self:_CalcSkillParam_ChainSkill(attacker)
    local damagePercent = damageParams.percent + chainSkillParam
    local chainChainParam = self:CalcChainChainParam(attacker)
    local superGridParam = self:CalcSuperGridParam(attacker)
    local poorGridParam = self:CalcPoorGridParam(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local chainSkillAbsorbParam = self:CalcAbsorbParam_ChainSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_ChainSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_ChainSkill(attacker)
    local val =
        baseDamage * damagePercent * (1 + chainChainParam + superGridParam + poorGridParam) * elementParam * chainSkillAbsorbParam *
        primarySecondaryParam *
        critParam *
        skillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    --恢复攻击力
    --self:_Attributes(attacker):Modify("Attack",oriAttack)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_135",
            desc = "公式135：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * (1+连锁技连锁系数[chainChainParam]+强化格子系数[superGridParam]+弱化格子系数[poorGridParam]) * 元素克制系数[elementParam] * 连锁技吸收系数[chainSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            chainSkillParam = chainSkillParam,
            chainChainParam = chainChainParam,
            superGridParam = superGridParam,
            poorGridParam = poorGridParam,
            elementParam = elementParam,
            chainSkillAbsorbParam = chainSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = skillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

--早苗 主动技伤害 使用机关的攻击力的真伤 （只计算属性克制）
function FormulaService:CalcDamage_136(attacker, defender, damageParams, damageGridPos)
    local trapFinalAttack = 0
    local trapElementParam = 1
    local val = 0
    if damageParams:GetUseTrapAttackTrapID() then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local trapEntitys = utilDataSvc:GetTrapByID(damageParams:GetUseTrapAttackTrapID())
        local useAtkEntity = nil
        if #trapEntitys > 0 then
            useAtkEntity = trapEntitys[1]
        end
        if useAtkEntity then
            trapFinalAttack = self:_CalcFinalAtk(useAtkEntity)
            trapElementParam = self:CalcTrapElementParam(attacker, defender)
        end
    end
    val = trapFinalAttack * damageParams.percent * trapElementParam
    val = self:_RET(val)
    local damageType = DamageType.Real
    --val, damageType = self:PostProcessDeadDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_136",
            desc = "公式136：攻击者[attacker] 被击者[defender] 伤害[val] = 攻击[finalAtk] * 技能系数[damagePercent] * 元素克制[elementParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            finalAtk = trapFinalAttack,
            damagePercent = damageParams.percent,
            elementParam = trapElementParam
        }
    )

    return val, DamageType.Real
end
---P5 合击技公式
---@param damageParams SkillDamageEffectParam
function FormulaService:CalcDamage_137(attacker, defender, damageParams, damageGridPos)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = 1--self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParams, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParams.percent + activeSkillParam

    local val =
        baseDamage * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam

    local spParams = damageParams:GetDamageSpParamsFormula137()

    local buffLayer = 1
    if spParams.layerBuffEffect then
        ---@type BuffLogicService
        local buffLogicService = self._world:GetService("BuffLogic")
	    buffLayer = buffLogicService:GetBuffLayer(defender,spParams.layerBuffEffect)
    end

    local bWeak = false
    ---@type BuffComponent
    local cBuff = defender:BuffComponent()
    if spParams.weakBuffEffect and cBuff and cBuff:HasBuffEffect(spParams.weakBuffEffect) then
        bWeak = true
    end
    local p5PetCount = 1
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if featureLogicSvc then
        p5PetCount = featureLogicSvc:GetPersonaPetCount()
    end
    local defBodyArea = defender:BodyArea():GetArea()
    local defBodyCount = #defBodyArea
    local weakParam = bWeak and spParams.d or 0

    val = val * defBodyCount ^ (spParams.a) * (spParams.b + spParams.c * buffLayer + weakParam) * (spParams.e + spParams.f * p5PetCount)
    val = self:_RET(val)

    --local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical
    local damageType = DamageType.Real

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_137",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式137：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam]"
                    .. " * 被击者身形[defBodyCount] ^ 参数a[paramA] * (参数b[paramB] + 参数c[paramC] * 层数[buffLayer] + weak加成[weakParam]) * (参数e[paramE] + 参数f[paramF] * p5光灵数[p5PetNum])",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam,
            defBodyCount = defBodyCount,
            paramA = spParams.a,
            paramB = spParams.b,
            paramC = spParams.c,
            paramE = spParams.e,
            paramF = spParams.f,
            buffLayer = buffLayer,
            weakParam = weakParam,
            p5PetNum = p5PetCount
        }
    )

    return val, damageType
end

--国际服N22 卡斯特伤害公式 普攻基础上增加a%~b%的随机浮动，且伤害类型（如果有伤害）为暴击
---@param damageParams SkillDamageEffectParam
function FormulaService:CalcDamage_138(attacker, defender, damageParams, damageGridPos)
    local mulMin = damageParams._damageMulMin138 * 100
    local mulMax = damageParams._damageMulMax138 * 100

    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local damagePercent =
    damageParams.percent + self:_CalcSkillParam_NormalSkill(attacker) +
            self:_CalcSkillParam_DefenderSkillAmpfily(defender)
    local comboParam = self:CalcComboParam(attacker)
    local normalChainParam = self:CalcNormalChainParam(attacker)
    local superGridParam = self:CalcSuperGridParam(attacker)
    local poorGridParam = self:CalcPoorGridParam(attacker)
    local elementParam = self:CalcElementParam(attacker, defender)
    local normalSkillAbsorbParam = self:CalcAbsorbParam_NormalSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_NormalSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_NormalSkill(attacker)
    local val =
    baseDamage * (damagePercent + comboParam + normalChainParam + superGridParam + poorGridParam) * elementParam *
            normalSkillAbsorbParam *
            primarySecondaryParam *
            critParam *
            skillIncreaseParam *
            skillFinalParam

    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local mul = randomSvc:LogicRand(mulMin, mulMax) * 0.01

    val = val * mul

    val = self:_RET(val)

    local damageType = DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_138",
                desc = "公式138：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * (普攻技能系数[damagePercent] + combo系数[comboParam] + 普攻连线系数[normalChainParam] + 强化格子系数[superGridParam] + 弱化格子系数[poorGridParam]) * 属性克制系数[elementParam] * 普攻吸收系数[normalSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam] * 最终浮动系数[floatRate]",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                baseDamage = baseDamage,
                damagePercent = damagePercent,
                comboParam = comboParam,
                normalChainParam = normalChainParam,
                superGridParam = superGridParam,
                poorGridParam = poorGridParam,
                elementParam = elementParam,
                normalSkillAbsorbParam = normalSkillAbsorbParam,
                primarySecondaryParam = primarySecondaryParam,
                critParam = critParam,
                skillIncreaseParam = skillIncreaseParam,
                skillFinalParam = skillFinalParam,
                floatRate = mul
            }
    )

    return val, damageType
end


---胡闹主播用护盾值打伤害
---@param damageParams SkillDamageEffectParam
---@param attacker Entity
function FormulaService:CalcDamage_139(attacker, defender, damageParams, damageGridPos)
    ---@type Entity
    local casterEntity = attacker
    if casterEntity:HasSuperEntity() then
        casterEntity= casterEntity:GetSuperEntity()
    end
    if casterEntity:HasPetPstID() then
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        casterEntity = teamEntity
    end

    ---@type BuffComponent
    local buffCmpt = casterEntity:BuffComponent()
    local baseDamage = buffCmpt:GetBuffValue("HPShield")
    local damagePercent = damageParams.percent
    local val = baseDamage* damagePercent
    val = self:_RET(val)

    local damageType = DamageType.Real

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            casterEntity:GetID(),
            {
                key = "CalcDamage_139",
                desc = "公式139：攻击者[attacker] 被击者[defender] 伤害[val] = 护盾数值[baseDamage]* 技能系数[damagePercent]",
                attacker = casterEntity:GetID(),
                defender = defender:GetID(),
                val = val,
                baseDamage = baseDamage,
                damagePercent = damagePercent,
            }
    )

    return val, damageType
end

---同公式5, 只是不处理buff附加的主动技伤害系数activeSkillParam
function FormulaService:CalcDamage_140(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParams, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
    self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParams.percent

    local val =
    baseDamage * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
        skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_140",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式140：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam]",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            elementParam = elementParam,
            activeSkillAbsorbParam = activeSkillAbsorbParam,
            primarySecondaryParam = primarySecondaryParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
            skillFinalParam = skillFinalParam
        }
    )

    return val, damageType
end

--- 传递的真实伤害计算，【真实伤害】
---@param attacker Entity
---@param defender Entity
---
function FormulaService:CalcDamage_141(attacker, defender, damageParam, damageGridPos)
    local changeHp = math.abs(damageParam.changeHp)
    local damagePercent = damageParam.percent

    local val = changeHp * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_141",
            desc = "公式141：攻击者[attacker] 被击者[defender] 伤害[val] = 血量变化[baseDamage] * 传导系数[transPercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = changeHp,
            transPercent = damagePercent
        }
    )
    return val, DamageType.RealTransmit
end

---主动技伤害
function FormulaService:CalcDamage_AkxyCasterLayerToDamage(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParams, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
    self:_GetActiveSkillParam(attacker, defender)

    --local damagePercent = damageParams.percent + activeSkillParam

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local curLayer = blsvc:GetBuffLayer(attacker, damageParams:GetBuffLayerTypeFormula143())
    local percentByLayer = damageParams:GetPercentByLayerFormula143()
    local damagePercent = curLayer * percentByLayer + activeSkillParam

    local val =
    baseDamage * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
            skillFinalParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_142",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                desc = "公式142：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam]",
                val = val,
                baseDamage = baseDamage,
                damagePercent = damagePercent,
                elementParam = elementParam,
                activeSkillAbsorbParam = activeSkillAbsorbParam,
                primarySecondaryParam = primarySecondaryParam,
                critParam = critParam,
                skillIncreaseParam = activeSkillIncreaseParam,
                skillFinalParam = skillFinalParam
            }
    )

    return val, damageType
end

--中毒buff（按Buff附加者的实时攻击力计算伤害）专用公式【真实伤害】
function FormulaService:CalcDamage_PoisonByAttack(attacker, defender, damageParam)
    local val = damageParam.attack * damageParam.percent * damageParam.layer
    val = self:_RET(val)
    local damageType = DamageType.Real
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_PoisonByAttack",
            desc = "公式142：攻击者[attacker] 被击者[defender] 伤害[val] = 最终攻击力[finalAtk] * 伤害系数[damagePercent] * 层数[layer]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            finalAtk = damageParam.attack,
            damagePercent = damageParam.percent,
            layer = damageParam.layer,
        }
    )
    return val, damageType
end

---普攻伤害
function FormulaService:CalcDamage_WeikeCompanionNormalAttack(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local damagePercent =
    damageParams.percent + self:_CalcSkillParam_NormalSkill(attacker) +
            self:_CalcSkillParam_DefenderSkillAmpfily(defender)
    local elementParam = self:CalcElementParam(attacker, defender)
    local normalSkillAbsorbParam = self:CalcAbsorbParam_NormalSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam(attacker)
    local critParam = self:CalcCritParam(damageParams, attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_NormalSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_NormalSkill(attacker)
    local val =
    baseDamage * (damagePercent) * elementParam *
            normalSkillAbsorbParam *
            primarySecondaryParam *
            critParam *
            skillIncreaseParam *
            skillFinalParam

    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_WeikeCompanionNormalAttack",
                desc = "公式144：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * (普攻技能系数[damagePercent]) * 属性克制系数[elementParam] * 普攻吸收系数[normalSkillAbsorbParam] * 主副属性系数[primarySecondaryParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] * 技能最终系数[skillFinalParam]",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                baseDamage = baseDamage,
                damagePercent = damagePercent,
                elementParam = elementParam,
                normalSkillAbsorbParam = normalSkillAbsorbParam,
                primarySecondaryParam = primarySecondaryParam,
                critParam = critParam,
                skillIncreaseParam = skillIncreaseParam,
                skillFinalParam = skillFinalParam
            }
    )

    return val, damageType
end

---强令目标**当前生命值**等于配置值，无视最终伤害步骤的所有增益和减益，使用该效果时，配置可决定该伤害是否可由护盾抵消
---@param attacker Entity
---@param damageParam SkillDamageEffectParam
function FormulaService:CalcDamage_AbsoluteRemainHP(attacker, defender, damageParam, damageGridPos)
    ---@type AttributesComponent
    local cAttr = defender:Attributes()
    local currentHP = cAttr:GetCurrentHP()
    local val = self:_RET(currentHP - damageParam:GetAbsoluteRemainHPFormula145())
    --保底规则：_RET里面有一个最低伤害为1的保证逻辑
    if currentHP - val <= 0 then
        val = currentHP - 1
    end
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_145",
                desc = "公式145：【boss特殊机制】被击者[defender] 最终伤害[val] 公式不做处理，不受伤害加重及受伤减轻影响。",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
            }
    )
    return val, DamageType.Real
end

---@param attacker Entity
---@param defender Entity
---@param damageParam SkillDamageEffectParam
function FormulaService:CalcDamage_RealDamageByLoseHP(attacker, defender, damageParam, damageGridPos)
    ---@type AttributesComponent
    local cAttr = defender:Attributes()
    local maxHP = cAttr:CalcMaxHp()
    local currentHP = cAttr:GetCurrentHP()
    local loseHP = maxHP - currentHP

    local damagePercent = damageParam.percent
    local val = loseHP * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_RealDamageByLoseHP",
            desc = "公式146：攻击者[attacker] 被击者[defender] 伤害[val] = 损失血量[loseHP] * 技能系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            loseHP = loseHP,
            damagePercent = damagePercent,
        }
    )
    return val, DamageType.Real
end

--百斯特曼最大伤害限制公式[真实伤害]
function FormulaService:CalcDamage_AntiSetNoPercentDamage(attacker, defender, damageParam, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)
    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
    self:_GetActiveSkillParam(attacker, defender)

    local defenderHp = self:_Attributes(defender):GetCurrentHP()
    local trueDamageFixParam = self:CalcTrueDamageFixParam(attacker)
    local damagePercent = damageParam.percent + trueDamageFixParam
    local val =
    (defenderHp * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
            skillFinalParam)

    local maxDamage = self:_CalcOnceMaxDamage(attacker, damageParam) or val
    val = math.min(val, maxDamage)

    local minDamage = self:_CalcOnceMinDamage(attacker, damageParam) or val
    val = math.max(val, minDamage)

    local damageType = DamageType.Real

    --val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    if not buffLogicSvc:IsTargetCanBePercentDamage(defender) then
        val = minDamage
    end

    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_AntiSetNoPercentDamage",
                desc = "公式147：攻击者[attacker] 被击者[defender] 伤害[val] = min(伤害上限[maxDamage], 当前血量[hp] * (伤害系数[damagePercent] = 百分比[percent] + 修正系数[fixParam]) * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam])",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                hp = defenderHp,
                percent = damageParam.percent,
                fixParam = trueDamageFixParam,
                maxDamage = maxDamage,
                activeSkillParam = activeSkillParam,
                elementParam = elementParam,
                activeSkillAbsorbParam = activeSkillAbsorbParam,
                primarySecondaryParam = primarySecondaryParam,
                critParam = critParam,
                skillIncreaseParam = activeSkillIncreaseParam,
                skillFinalParam = skillFinalParam,
                damagePercent = damagePercent
            }
    )

    return val, damageType
end

--百斯特曼最大伤害限制公式[真实伤害]
function FormulaService:CalcDamage_AntiSetNoPercentDamageMaxHPPercent(attacker, defender, damageParam, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)
    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam, activeSkillParam =
    self:_GetActiveSkillParam(attacker, defender)

    --[[
        路万博(@PLM) 5-22 15:32:45
        加成后还是加成前的最大生命值

        宋微木 5-22 15:33:29
        怪物血量也有加成吗

        路万博(@PLM) 5-22 15:34:31
        修改最大生命值是很久以前就有的东西了

        宋微木 5-22 15:34:58
        按加成后吧
    ]]
    local defenderHp = self:_Attributes(defender):CalcMaxHp()
    local trueDamageFixParam = self:CalcTrueDamageFixParam(attacker)
    local damagePercent = damageParam.percent + trueDamageFixParam
    local val =
    (defenderHp * damagePercent * elementParam * critParam * activeSkillAbsorbParam * activeSkillIncreaseParam *
            skillFinalParam)

    local maxDamage = self:_CalcOnceMaxDamage(attacker, damageParam) or val
    val = math.min(val, maxDamage)

    local minDamage = self:_CalcOnceMinDamage(attacker, damageParam) or val
    val = math.max(val, minDamage)

    local damageType = DamageType.Real

    --val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    if not buffLogicSvc:IsTargetCanBePercentDamage(defender) then
        val = minDamage
    end

    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_AntiSetNoPercentDamageMaxHPPercent",
                desc = "公式148：攻击者[attacker] 被击者[defender] 伤害[val] = min(伤害上限[maxDamage], 当前血量[hp] * (伤害系数[damagePercent] = 百分比[percent] + 修正系数[fixParam]) * 元素克制[elementParam] * 暴击系数[critParam] * 主动技吸收系数[activeSkillAbsorbParam] * 技能提升系数[skillIncreaseParam] * 最终系数[skillFinalParam])",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                hp = defenderHp,
                percent = damageParam.percent,
                fixParam = trueDamageFixParam,
                maxDamage = maxDamage,
                activeSkillParam = activeSkillParam,
                elementParam = elementParam,
                activeSkillAbsorbParam = activeSkillAbsorbParam,
                primarySecondaryParam = primarySecondaryParam,
                critParam = critParam,
                skillIncreaseParam = activeSkillIncreaseParam,
                skillFinalParam = skillFinalParam,
                damagePercent = damagePercent
            }
    )

    return val, damageType
end

---5号公式没有被击者吸收系数
function FormulaService:CalcDamage_ActiveAttackNoAbsorb(attacker, defender, damageParams, damageGridPos)
    local baseDamage = self:CalcBaseDamage(attacker, defender, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParams, attacker)

    local activeSkillAbsorbParam, primarySecondaryParam, activeSkillIncreaseParam, skillFinalParam =
        self:_GetActiveSkillParam(attacker, defender)

    local damagePercent = damageParams.percent

    local val =
        baseDamage * damagePercent * elementParam * critParam * activeSkillIncreaseParam
    val = self:_RET(val)

    local damageType = critParam == 1 and DamageType.Normal or DamageType.Critical

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_149",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "公式149：攻击者[attacker] 被击者[defender] 伤害[val] = 基础伤害[baseDamage] * 技能系数[damagePercent] * 元素克制[elementParam] * 暴击系数[critParam] * 技能提升系数[skillIncreaseParam] ",
            val = val,
            baseDamage = baseDamage,
            damagePercent = damagePercent,
            elementParam = elementParam,
            critParam = critParam,
            skillIncreaseParam = activeSkillIncreaseParam,
        }
    )

    return val, damageType
end

function FormulaService:CalcDamage_Formula11AntiSetNoPercentDamage(attacker, defender, damageParam, damageGridPos)
    local defenderHp = self:_Attributes(defender):GetCurrentHP()

    local val = defenderHp * damageParam.percent
    val = self:_RET(val)
    local damageType = DamageType.Real
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)

    local maxDamage = self:_CalcOnceMaxDamage(attacker, damageParam) or val
    val = math.min(val, maxDamage)

    local minDamage = self:_CalcOnceMinDamage(attacker, damageParam) or val
    val = math.max(val, minDamage)

    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    if not buffLogicSvc:IsTargetCanBePercentDamage(defender) then
        val = minDamage
        damageType = DamageType.Real
    end

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_150",
                desc = "公式150：攻击者[attacker] 被击者[defender] 伤害[val] = 当前血量[hp] * 百分比[damagePercent]，最低值[min]",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                hp = defenderHp,
                damagePercent = damageParam.percent,
                min = minDamage,
            }
    )

    return val, damageType
end

--105公式去除技能加成[真实伤害]
function FormulaService:CalcDamage_Formula105NoSkillParam(attacker, defender, damageParam, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local defenderHp = self:_Attributes(defender):GetCurrentHP()
    local trueDamageFixParam = self:CalcTrueDamageFixParam(attacker)
    local damagePercent = damageParam.percent + trueDamageFixParam
    local val =
        (defenderHp * damagePercent * elementParam * critParam)

    local maxDamage = self:_CalcOnceMaxDamage(attacker, damageParam) or val
    val = math.min(val, maxDamage)

    local damageType = DamageType.Real
    val = self:_RET(val)
    val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "CalcDamage_Formula105NoSkillParam",
            desc = "公式151：攻击者[attacker] 被击者[defender] 伤害[val] = min(伤害上限[maxDamage], 当前血量[hp] * (伤害系数[damagePercent] = 百分比[percent] + 修正系数[fixParam]) * 元素克制[elementParam] * 暴击系数[critParam])",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            hp = defenderHp,
            percent = damageParam.percent,
            fixParam = trueDamageFixParam,
            maxDamage = maxDamage,
            elementParam = elementParam,
            critParam = critParam,
            damagePercent = damagePercent
        }
    )

    return val, damageType
end

--147公式去除技能加成[真实伤害]
function FormulaService:CalcDamage_Formula147NoSkillParam(attacker, defender, damageParam, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local defenderHp = self:_Attributes(defender):GetCurrentHP()
    local trueDamageFixParam = self:CalcTrueDamageFixParam(attacker)
    local damagePercent = damageParam.percent + trueDamageFixParam
    local val =
    (defenderHp * damagePercent * elementParam * critParam)

    local maxDamage = self:_CalcOnceMaxDamage(attacker, damageParam) or val
    val = math.min(val, maxDamage)

    local minDamage = self:_CalcOnceMinDamage(attacker, damageParam) or val
    val = math.max(val, minDamage)

    local damageType = DamageType.Real

    --val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    if not buffLogicSvc:IsTargetCanBePercentDamage(defender) then
        val = minDamage
    end

    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_Formula147NoSkillParam",
                desc = "公式152：攻击者[attacker] 被击者[defender] 伤害[val] = min(伤害上限[maxDamage], 当前血量[hp] * (伤害系数[damagePercent] = 百分比[percent] + 修正系数[fixParam]) * 元素克制[elementParam] * 暴击系数[critParam] )",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                hp = defenderHp,
                percent = damageParam.percent,
                fixParam = trueDamageFixParam,
                maxDamage = maxDamage,
                elementParam = elementParam,
                critParam = critParam,
                damagePercent = damagePercent
            }
    )

    return val, damageType
end

--148公式去除技能加成[真实伤害]
function FormulaService:CalcDamage_Formula148NoSkillParam(attacker, defender, damageParam, damageGridPos)
    local elementParam = self:CalcElementParam(attacker, defender)
    local critParam = self:CalcCritParam(damageParam, attacker)

    local defenderHp = self:_Attributes(defender):CalcMaxHp()
    local trueDamageFixParam = self:CalcTrueDamageFixParam(attacker)
    local damagePercent = damageParam.percent + trueDamageFixParam
    local val =
    (defenderHp * damagePercent * elementParam * critParam )

    local maxDamage = self:_CalcOnceMaxDamage(attacker, damageParam) or val
    val = math.min(val, maxDamage)

    local minDamage = self:_CalcOnceMinDamage(attacker, damageParam) or val
    val = math.max(val, minDamage)

    local damageType = DamageType.Real

    --val, damageType = self:PostProcessPercentDamage(defender, val, damageType)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    if not buffLogicSvc:IsTargetCanBePercentDamage(defender) then
        val = minDamage
    end

    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_Formula148NoSkillParam",
                desc = "公式153：攻击者[attacker] 被击者[defender] 伤害[val] = min(伤害上限[maxDamage], 当前血量[hp] * (伤害系数[damagePercent] = 百分比[percent] + 修正系数[fixParam]) * 元素克制[elementParam] * 暴击系数[critParam] )",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                hp = defenderHp,
                percent = damageParam.percent,
                fixParam = trueDamageFixParam,
                maxDamage = maxDamage,
                elementParam = elementParam,
                critParam = critParam,
                damagePercent = damagePercent
            }
    )

    return val, damageType
end

---9号公式增加元素克制
function FormulaService:CalcDamage_Formula9AddElementParam(attacker, defender, damageParam, damageGridPos)
    local attack = self:CalcAttack(attacker)
    local addPercent = damageParam.addPercent or 0
    local damagePercent = damageParam.percent * (1 + addPercent)
    local elementParam = self:CalcElementParam(attacker, defender)
    local val = attack * damagePercent * elementParam
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "Formula9AddElementParam",
            desc = "公式154：攻击者[attacker] 被击者[defender] 伤害[val] = 攻击[attack] * (百分比[percent] * (1 + 百分比加成[addPercent])) * 元素克制[elementParam]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            attack = attack,
            elementParam = elementParam,
            percent = damageParam.percent,
            addPercent = damageParam.addPercent,
            damagePercent = damagePercent
        }
    )

    return val, DamageType.Real
end

---根据加血量造成伤害Buff的伤害计算，【真实伤害】
---@param attacker Entity
---@param defender Entity
function FormulaService:CalcDamage_RealDamageByAddBlood(attacker, defender, damageParam, damageGridPos)
    local changeHP = damageParam.changeHP
    local damagePercent = damageParam.percent

    local val = changeHP * damagePercent
    val = self:_RET(val)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "RealDamageByAddBlood",
            desc = "公式155：攻击者[attacker] 被击者[defender] 伤害[val] = 加血量[baseDamage] * 系数[damagePercent]",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            val = val,
            baseDamage = changeHP,
            damagePercent = damagePercent
        }
    )
    return val, DamageType.Real
end

function FormulaService:CalcDamage_Monster2003301SacrificeDamage(attacker, defender, damageParam, damageGridPos)
    ---@type BattleService
    local battle_svc = self._world:GetService("Battle")
    local curHP, maxHP = battle_svc:GetCasterHP(attacker)

    local cSkillContext = attacker:SkillContext()

    local val = cSkillContext:GetSacrificedHP() * damageParam.percent
    val = self:_RET(val)
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
            attacker:GetID(),
            {
                key = "CalcDamage_107",
                desc = "公式107：攻击者[attacker] 被击者[defender] 伤害[val] = 最大血量[MaxHP] - 当前血量[HP]",
                attacker = attacker:GetID(),
                defender = defender:GetID(),
                val = val,
                maxHP = maxHP,
                HP = curHP
            }
    )
    return val, DamageType.Real
end
