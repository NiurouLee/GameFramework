--[[ 
    formula service 战斗公式
---------------------------------
公式术语英翻统一，朱春辉提供：
    Attack              攻击
    AttackPercentage    攻击百分比加成
    AttackConstantFix   攻击固定加成值

    Defence             防御
    DefencePercentage   防御百分比加成
    DefenceConstantFix  防御固定加成值

    Hp                  生命
    HpPercentage        生命百分比加成
    HpConstantFix       生命固定加成值

    BaseDamage              基础伤害
    SkillParam              普攻技能系数
    ComboParam              Combo系数
    ElementParam            属性克制系数
	superGridParam			强化格子系数

    NormalChainParam        普攻连线系数
    ChainChainParam         连锁技连线系数

    NormalSkillAbsorbParam  普攻吸收系数
    ChainSkillAbsorbParam   连锁技吸收系数
    ActiveSkillAbsorbParam  主动技吸收系数
    DamageAbsorbParam       伤害吸收系数

    PrimarySecondaryParam   主副属性系数
    CritParam               暴击系数
    SkillIncreaseParam      技能倍率系数
	skillFinalParam			技能最终系数
---------------------------------
基础伤害：
    BaseDamage = 攻击者Attack – 受击者Defence
        攻击者Attack = [Attack * (1 + AttackPercentage) + AttackConstantFix]
        受击者Defence = [Defence * (1 + DefencePercentage) + DefenceConstantFix]
    BaseDamage = [Attack * (1 + AttackPercentage) + AttackConstantFix] – [Defence * (1 + DefencePercentage) + DefenceConstantFix]
普攻伤害：
    普攻伤害 = BaseDamage * (SkillParam + ComboParam + NormalChainParam + superGridParam) * ElementParam * NormalSkillAbsorbParam * PrimarySecondaryParam * CritParam * SkillIncreaseParam * skillFinalParam
连锁技伤害：
    连锁技伤害 = BaseDamage * SkillParam * (1 + ChainChainParam + superGridParam) * ElementParam * ChainSkillAbsorbParam * PrimarySecondaryParam * CritParam * SkillIncreaseParam * skillFinalParam
主动技伤害：
    主动技伤害 = BaseDamage * SkillParam * ElementParam * ActiveSkillAbsorbParam * CritParam * SkillIncreaseParam * skillFinalParam
怪物伤害：
    怪物伤害 = BaseDamage * SkillParam * ElementParam * DamageAbsorbParam * CritParam * SkillIncreaseParam * skillFinalParam
--]]

require("directional_relative_pos_map_type")

-- 这段一开始是放在上面require的代码里，但这样会导致导表出错
-- 二级索引下标规则：1234=>下左上右
_G.DirectionalRelativePosMap = {
    --https://wiki.h3d.com.cn/pages/viewpage.action?pageId=86363411
    [DirectionalRelativePosMapType.Classical4Grid] = {
        -- 下
        [1] = {
            [1] = Vector2.New(0, 0),
            [2] = Vector2.New(1, 0),
            [3] = Vector2.New(0, 1),
            [4] = Vector2.New(1, 1)
        },
        -- 左
        [2] = {
            [1] = Vector2.New(0, 1),
            [2] = Vector2.New(0, 0),
            [3] = Vector2.New(1, 1),
            [4] = Vector2.New(1, 0)
        },
        -- 上
        [3] = {
            [1] = Vector2.New(1, 1),
            [2] = Vector2.New(0, 1),
            [3] = Vector2.New(1, 0),
            [4] = Vector2.New(0, 0)
        },
        --右
        [4] = {
            [1] = Vector2.New(1, 0),
            [2] = Vector2.New(1, 1),
            [3] = Vector2.New(0, 0),
            [4] = Vector2.New(0, 1)
        }
    },
    [DirectionalRelativePosMapType.Classical9Grid] = {
        [1] = {
            Vector2.New(0, 0), Vector2.New(1, 0), Vector2.New(2, 0),
            Vector2.New(0, 1), Vector2.New(1, 1), Vector2.New(2, 1),
            Vector2.New(0, 2), Vector2.New(1, 2), Vector2.New(2, 2),
        },
        [2] = {
            Vector2.New(0, 2), Vector2.New(0, 1), Vector2.New(0, 0),
            Vector2.New(1, 2), Vector2.New(1, 1), Vector2.New(1, 0),
            Vector2.New(2, 2), Vector2.New(2, 1), Vector2.New(2, 0),
        },
        [3] = {
            Vector2.New(2, 2), Vector2.New(1, 2), Vector2.New(0, 2),
            Vector2.New(2, 1), Vector2.New(1, 1), Vector2.New(0, 1),
            Vector2.New(2, 0), Vector2.New(1, 0), Vector2.New(0, 0),
        },
        [4] = {
            Vector2.New(2, 0), Vector2.New(2, 1), Vector2.New(2, 2),
            Vector2.New(1, 0), Vector2.New(1, 1), Vector2.New(1, 2),
            Vector2.New(0, 0), Vector2.New(0, 1), Vector2.New(0, 2),
        },
    }
}

---@class PrimarySecondaryParamType
---@field TeamLeader number
---@field Pet number
local PrimarySecondaryParamType = {
    TeamLeader = 1,
    Pet = 2
}
_enum("PrimarySecondaryParamType", PrimarySecondaryParamType)

_class("FormulaService", BaseService)
---@class FormulaService:BaseService
FormulaService = FormulaService

function FormulaService:Constructor(world)
    self._world = world
    -- 连线数	系数a	系数b
    -- [0,4)	0.025	0
    -- [4,8)	0.025	0.1
    -- [8,12)	0.025	0.2
    -- [12,16)	0.025	0.3
    -- [16,)	0.025	0.4
    self._comboSegment = {
        [1] = {comboNum = 0, a = 0.02, b = 0},
        [2] = {comboNum = 6, a = 0.015, b = 0.025},
        [3] = {comboNum = 16, a = 0.01, b = 0.1},
        [4] = {comboNum = 26, a = 0.005, b = 0.225},
        [5] = {comboNum = 41, a = 0.002, b = 0.345}
    } --Combo分段
    self._chainSegmentNormal = {
        [1] = {chainNum = 0, a = 0, b = 0},
        [2] = {chainNum = 2, a = 0.05, b = -0.05},
        [3] = {chainNum = 4, a = 0.045, b = -0.035},
        [4] = {chainNum = 6, a = 0.04, b = -0.01},
        [5] = {chainNum = 8, a = 0.035, b = 0.025},
        [6] = {chainNum = 10, a = 0.03, b = 0.07},
        [7] = {chainNum = 12, a = 0.025, b = 0.125},
        [8] = {chainNum = 16, a = 0, b = 0.5}
    } --普攻分段
    self._chainSegmentChain = {
        [1] = {chainNum = 0, a = 0, b = 0},
        [2] = {chainNum = 3, a = 0.1, b = -0.2},
        [3] = {chainNum = 7, a = 0.09, b = -0.14},
        [4] = {chainNum = 9, a = 0.08, b = -0.06},
        [5] = {chainNum = 11, a = 0.07, b = 0.04},
        [6] = {chainNum = 13, a = 0.05, b = 0.28},
        [7] = {chainNum = 15, a = 0.02, b = 0.7},
        [8] = {chainNum = 16, a = 0, b = 1}
    } --连锁分段
    self:Register()
end

---计算攻击力
function FormulaService:_CalcFinalAtk(attacker)
    local attack = self:CalcAttack(attacker)
    local attackPercentage = self:CalcAttackPercentage(attacker)
    local attackConstantFix = self:CalcAttackConstantFix(attacker)

    local finalAtk = math.floor(attack * (1 + attackPercentage) + attackConstantFix)

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "FinalAtk",
            attacker = attacker:GetID(),
            desc = "1)最终攻击[finalAtk] = 攻击[attack] * (1 + 攻击百分比[attackPercentage]) + 攻击绝对值[attackConstantFix]",
            finalAtk = finalAtk,
            attack = attack,
            attackPercentage = attackPercentage,
            attackConstantFix = attackConstantFix
        }
    )

    return finalAtk
end

---计算防御
function FormulaService:_CalcFinalDef(defender, attacker, damageGridPos)
    local defence = self:CalcDefenceWithAttacker(defender,attacker)--计算防御力时可能受攻击者影响
    local defencePercentage = self:CalcDefencePercentage(defender)
    local defenceConstantFix = self:CalcDefenceConstantFix(defender)

    --region 身形对格子伤害防御系数
    local directionalDefPercentage = 0
    local defenderDirectionalDefPosArray = defender:BuffComponent():GetBuffValue("DEFENDER_DIRECTIONAL_DEF_POS_ARRAY") or {}
    --没有传位置的<===>非格子伤害<===>无身形防御
    if damageGridPos and #defenderDirectionalDefPosArray > 0 then
        local defGridType = self:_GetRelativePosMapDir(defender:GetGridDirection())
        local bodyAreaPosMap
        local defBodyArea = defender:BodyArea():GetArea()
        if #defBodyArea == 4 then
            bodyAreaPosMap = _G.DirectionalRelativePosMap[DirectionalRelativePosMapType.Classical4Grid]
        elseif #defBodyArea == 9 then
            bodyAreaPosMap = _G.DirectionalRelativePosMap[DirectionalRelativePosMapType.Classical9Grid]
        end
        if bodyAreaPosMap and bodyAreaPosMap[defGridType] then
            local t = {}
            for _, index in ipairs(defenderDirectionalDefPosArray) do
                local v2Relative = bodyAreaPosMap[defGridType][index]
                table.insert(t, v2Relative + defender:GetGridPosition())
            end
            if table.Vector2Include(t, damageGridPos) then
                local rate = defender:BuffComponent():GetBuffValue("DEFENDER_DIRECTIONAL_DEF_POS_RATE") or 0
                directionalDefPercentage = rate
            end
        end
    end
    --endregion

    local finalDef = math.floor(defence * (1 + defencePercentage + directionalDefPercentage) + defenceConstantFix)
    finalDef = math.max(0,finalDef)--最终防御最低为0 2021-11-15
    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            desc = "2)最终防御[finalDef] = 防御[defence] * (1 + 防御百分比[defencePercentage] + 身形防御百分比[directionalDefPercentage]) + 防御绝对值[defenceConstantFix]",
            key = "FinalDef",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            finalDef = finalDef,
            defence = defence,
            defencePercentage = defencePercentage,
            defenceConstantFix = defenceConstantFix,
            directionalDefPercentage = directionalDefPercentage,
        }
    )

    return finalDef
end

---基础伤害
function FormulaService:CalcBaseDamage(attacker, defender, damageGridPos)
    local finalAtk = self:_CalcFinalAtk(attacker)
    local finalDef = self:_CalcFinalDef(defender, attacker, damageGridPos)
    local noDefence = self:_IsNoDefence(attacker)

    local rawFinalDef = finalDef
    finalDef = finalDef * (1 - noDefence)

    local result = finalAtk - finalDef

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "BaseDamage",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "3)基础伤害[baseDamage] = 最终攻击[finalAtk] - (最终防御[rawFinalDef] * (1 - 无视防御系数[noDefence]))",
            baseDamage = result,
            finalAtk = finalAtk,
            finalDef = finalDef,
            rawFinalDef = rawFinalDef,
            noDefence = noDefence
        }
    )

    return result
end
function FormulaService:CalcBaseDamageWithSpecificFinalAttack(attacker, defender,spFinalAtk, damageGridPos)
    local finalAtk = 0
    if spFinalAtk then
        finalAtk = spFinalAtk
    else
        finalAtk = self:_CalcFinalAtk(attacker)
    end
    local finalDef = self:_CalcFinalDef(defender, attacker, damageGridPos)
    local noDefence = self:_IsNoDefence(attacker)

    local rawFinalDef = finalDef
    finalDef = finalDef * (1 - noDefence)

    local result = finalAtk - finalDef

    local logger = self._world:GetMatchLogger()
    logger:AddDamageLog(
        attacker:GetID(),
        {
            key = "BaseDamage",
            attacker = attacker:GetID(),
            defender = defender:GetID(),
            desc = "3)基础伤害[baseDamage] = 最终攻击[finalAtk] - (最终防御[rawFinalDef] * (1 - 无视防御系数[noDefence]))",
            baseDamage = result,
            finalAtk = finalAtk,
            finalDef = finalDef,
            rawFinalDef = rawFinalDef,
            noDefence = noDefence
        }
    )

    return result
end

--保证结果非负
function FormulaService:_RET(val)
    if val < 1 then
        return 1
    end
    val = math.ceil(val)
    return val
end

---@param entity Entity
---@return AttributesComponent
---获取entity身上的AttributesComponent
function FormulaService:_Attributes(entity)
    return entity:Attributes()
end

---@param entity Entity
function FormulaService:CalcAttack(entity)
    local val = self:_Attributes(entity):GetAttribute("Attack") or 1
    return val
end
---@param entity Entity
function FormulaService:CalcAttackPercentage(entity)
    local val = self:_Attributes(entity):GetAttribute("AttackPercentage") or 0
    --TODO攻击加成百分比可能会来自装备、加攻buff等，届时的计算可能不仅仅是从Attribute中取
    return val
end
---@param entity Entity
function FormulaService:CalcAttackConstantFix(entity)
    local val = self:_Attributes(entity):GetAttribute("AttackConstantFix") or 0
    return val
end

---@param entity Entity
function FormulaService:CalcDefenceWithAttacker(entity,attacker)
    if attacker then
        local ignoreTeamMemberDefence = self:_IsIgnoreTeamMemberDefence(attacker)
        if ignoreTeamMemberDefence > 0 then
            return self:CalcDefenceIgnoreTeamMember(entity,ignoreTeamMemberDefence)
        end
    end
    return self:CalcDefence(entity)
end
---@param entity Entity
function FormulaService:CalcDefence(entity)
    local defense = self:_Attributes(entity):GetAttribute("Defense")
    local val = defense or 1
    return val
end
---@param entity Entity
function FormulaService:CalcDefenceIgnoreTeamMember(entity,ignoreTeamMemberDefence)
    if entity:HasTeam() then
        local def = 0
        local teamMembers = entity:Team():GetTeamPetEntities()
        local teamLeaderId = entity:Team():GetTeamLeaderEntityID()
        for _, e in ipairs(teamMembers) do
            local memberId = e:GetID()
            local memDef = self:_Attributes(e):GetAttribute("Defense")
            if teamLeaderId == memberId then
            else
                memDef = memDef*(1-ignoreTeamMemberDefence)
            end
            def = def + memDef
        end
        return def
    else
        return self:CalcDefence(entity)
    end
end
---@param entity Entity
function FormulaService:CalcDefencePercentage(entity)
    local val = self:_Attributes(entity):GetAttribute("DefencePercentage") or 0
    return val
end
---@param entity Entity
function FormulaService:CalcDefenceConstantFix(entity)
    local val = self:_Attributes(entity):GetAttribute("DefenceConstantFix") or 0
    return val
end

---@param entity Entity
function FormulaService:CalcComboParam(entity)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local logicComboNum = battleService:GetLogicComboNum()
    for i = table.count(self._comboSegment), 1, -1 do
        local v = self._comboSegment[i]
        if logicComboNum >= v.comboNum then
            return v.a * logicComboNum + v.b
        end
    end
    return 0
end
---@return SkillPetAttackDataComponent
---@param entity Entity
function FormulaService:GetEntityPetAtkDataCmpt(entity)
    if entity:HasSuperEntity() and entity:SuperEntityComponent():IsUseSuperPetAttackData() then
        ---@type Entity
        local superEntity = entity:SuperEntityComponent():GetSuperEntity()
        return superEntity:SkillPetAttackData()
    end
    return entity:SkillPetAttackData()
end

function FormulaService:CalcSuperGridParam(entity)
    ---@type SkillPetAttackDataComponent
    local petAtkComponent = self:GetEntityPetAtkDataCmpt(entity)
    local superGridNum = petAtkComponent:GetCurrentSuperGridNum()

    return superGridNum * BattleConst.EachSuperGridDamageParam
end

function FormulaService:CalcPoorGridParam(entity)
    ---@type SkillPetAttackDataComponent
    local petAtkComponent = self:GetEntityPetAtkDataCmpt(entity)
    local superGridNum = petAtkComponent:GetCurrentPoorGridNum()

    return superGridNum * BattleConst.EachPoorGridDamageParam
end

---@param entity Entity
function FormulaService:CalcNormalChainParam(entity)
    return self:_GetChainSegment(self._chainSegmentNormal, entity)
end
---@param entity Entity
function FormulaService:CalcChainChainParam(entity)
    return self:_GetChainSegment(self._chainSegmentChain, entity)
end
---@return number
function FormulaService:_GetChainSegment(segment, entity)
    ---@type SkillPetAttackDataComponent
    local petAtkComponent = self:GetEntityPetAtkDataCmpt(entity)
    local chainNum = petAtkComponent:GetCurrentChainDamageRate()

    for i = table.count(segment), 1, -1 do
        local v = segment[i]
        if chainNum >= v.chainNum then
            return v.a * chainNum + v.b
        end
    end
    return 0
end

function FormulaService:CalcPrimarySecondaryParam_ActiveSkill(attacker)
    return BattleConst.PrimarySecondaryActiveParam
end

function FormulaService:CalcPrimarySecondaryParam(attacker)
    local val = self:_Attributes(attacker):GetAttribute("PrimarySecondaryParam") or 1
    return val
end
---获取怪物配置
---@param defender Entity
function FormulaService:_GetMonsterAbsorbData(monsterEntity, nType)
    local nReturn = 1
    local compMonsterID = monsterEntity:MonsterID()
    if compMonsterID then
        local nMonsterID = compMonsterID:GetMonsterID()
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        --吸收系数
        if MonsterSkillAbsorbType.NormalSkill == nType then
            nReturn = monsterEntity:Attributes():GetAttribute("AbsorbNormal") or -1
        elseif MonsterSkillAbsorbType.ChainSkill == nType then
            nReturn = monsterEntity:Attributes():GetAttribute("AbsorbChain") or -1
        elseif MonsterSkillAbsorbType.ActiveSkill == nType then
            nReturn = monsterEntity:Attributes():GetAttribute("AbsorbActive") or -1
        end
    end
    return nReturn
end
---吸收系数： 普通伤害
---@param defender Entity
function FormulaService:CalcAbsorbParam_NormalSkill(defender)
    return self:_GetMonsterAbsorbData(defender, 1)
end
---吸收系数： 普通伤害
---@param defender Entity
function FormulaService:CalcAbsorbParam_ChainSkill(defender)
    return self:_GetMonsterAbsorbData(defender, 2)
end
---吸收系数： 普通伤害
---@param defender Entity
function FormulaService:CalcAbsorbParam_ActiveSkill(defender)
    return self:_GetMonsterAbsorbData(defender, 3)
end
---吸收系数： 怪伤害
function FormulaService:CalcAbsorbParam_Damage()
    return 1 --TODO
end

--暴击倍率
function FormulaService:CalcCritParam(damageParam, attacker)
    if not damageParam.critProb or not damageParam.crit then
        return 1
    end
    ---@type AttributesComponent
    local cAttr = attacker:Attributes()
    local critProb = damageParam.critProb + (cAttr:GetAttribute("AdditionalCritProb") or 0)
    if critProb <= 0 then
        return 1
    end
    local critParam = damageParam.crit + (cAttr:GetAttribute("AdditionalCritParam") or 0)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local r = randomSvc:LogicRand()
    local val = (r < critProb) and critParam or 1
    return val --暴击
end

--暴击倍率 随combo数几率提高
function FormulaService:CalcCritParamWithCombo(attacker, damageParam)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local logicComboNum = battleService:GetLogicComboNum()

    --基础几率
    local critProb = damageParam.critProb

    --每一点combo提升暴击几率
    local eachComboIncreaseCritProb = attacker:BuffComponent():GetBuffValue("EachComboIncreaseCritProb") or 0
    local comboIncreaseCritProbMax = attacker:BuffComponent():GetBuffValue("ComboIncreaseCritProbMax") or 0
    if eachComboIncreaseCritProb ~= 0 then
        local critProbIncrease = logicComboNum * eachComboIncreaseCritProb
        if comboIncreaseCritProbMax ~= 0 and critProbIncrease > comboIncreaseCritProbMax then
            critProbIncrease = comboIncreaseCritProbMax
        end
        critProb = critProb + critProbIncrease
    end

    if not critProb or not damageParam.crit then
        return 1
    end
    if critProb <= 0 then
        return 1
    end
    ---@type AttributesComponent
    local cAttr = attacker:Attributes()
    local critParam = damageParam.crit + (cAttr:GetAttribute("AdditionalCritParam") or 0)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local r = randomSvc:LogicRand()
    local val = (r < critProb) and critParam or 1
    return val --暴击
end

---普攻 技能系数
---@param caster Entity
function FormulaService:_CalcSkillParam_NormalSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("NormalSkillParam") or 0
    return val
end

---连锁技 技能系数
---@param caster Entity
function FormulaService:_CalcSkillParam_ChainSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("ChainSkillParam") or 0
    return val
end

---主动技 技能系数
---@param caster Entity
function FormulaService:_CalcSkillParam_ActiveSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("ActiveSkillParam") or 0
    return val
end

---怪物 技能系数
---@param caster Entity
function FormulaService:_CalcSkillParam_MonsterSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("MonsterSkillParam") or 0
    return val
end

---普攻 技能伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillIncreaseParam_NormalSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("NormalSkillIncreaseParam") or 1
    return val
end

---连锁技 技能伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillIncreaseParam_ChainSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("ChainSkillIncreaseParam") or 1
    return val
end

---主动技 技能伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillIncreaseParam_ActiveSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("ActiveSkillIncreaseParam") or 1
    return val
end

---怪物 技能伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillIncreaseParam_MonsterSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("MonsterSkillIncreaseParam") or 1
    return val
end

---机关 技能伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillIncreaseParam_TrapSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("TrapSkillIncreaseParam") or 1
    return val
end

---普攻 技能最终伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillFinalParam_NormalSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("NormalSkillFinalParam") or 1
    return val
end

---连锁技 技能最终伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillFinalParam_ChainSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("ChainSkillFinalParam") or 1
    return val
end

---主动技 技能最终伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillFinalParam_ActiveSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("ActiveSkillFinalParam") or 1
    return val
end

---怪物 技能最终伤害倍率
---@param caster Entity
function FormulaService:_CalcSkillFinalParam_MonsterSkill(caster)
    local val = self:_Attributes(caster):GetAttribute("MonsterSkillFinalParam") or 1
    return val
end

--被击者最终伤害增伤系数
function FormulaService:_CalcDefenderBeHitDamageParam(defender)
    local val = self:_Attributes(defender):GetAttribute("FinalBehitDamageParam") or 1
    return val
end
--被击者(怪)受敌方队伍中队长攻击的增伤系数
function FormulaService:_CalcDefenderBeHitByTeamLeaderDamageParam(defender)
    local val = self:_Attributes(defender):GetAttribute("FinalBehitByTeamLeaderDamageParam") or 1
    return val
end
--被击者(怪)受敌方队伍中队员攻击的增伤系数
function FormulaService:_CalcDefenderBeHitByTeamMemberDamageParam(defender)
    local val = self:_Attributes(defender):GetAttribute("FinalBehitByTeamMemberDamageParam") or 1
    return val
end

function FormulaService:_GetAbsolutePosArrayByRelativeOne()

end

---@param defender Entity
---@param attacker Entity
function FormulaService:_ProcessFinalDamage(damage,damageType,defender,attacker,damageParam,damageGridPos)
    local logger = self._world:GetMatchLogger()

    local val = damage
    if attacker:HasPet() then
        local teamEntity = attacker:Pet():GetOwnerTeamEntity()
        if teamEntity then
            local isTeamLeader = teamEntity:Team():IsTeamLeaderByEntityId(attacker:GetID())
            if isTeamLeader then
                local beAttackParam = self:_CalcDefenderBeHitByTeamLeaderDamageParam(defender)
                val = val * beAttackParam
                logger:AddDamageLog(attacker:GetID(), {
                    key = "FinalDamage",
                    desc = "***光灵作为队长时最终伤害增伤系数[finalBehitByTeamLeaderDamageParam] 最终伤害值[val]***",
                    finalBehitByTeamLeaderDamageParam = beAttackParam,
                    val = val
                })
            else
                local beAttackParam = self:_CalcDefenderBeHitByTeamMemberDamageParam(defender)
                val = val * beAttackParam
                logger:AddDamageLog(attacker:GetID(), {
                    key = "FinalDamage",
                    desc = "***光灵作为队长时最终伤害增伤系数[finalBehitByTeamMemberDamageParam] 最终伤害值[val]***",
                    finalBehitByTeamMemberDamageParam = beAttackParam,
                    val = val
                })
            end
        end
    end

    if damageParam then
        local skillID = damageParam.skillID
        if skillID and skillID > 0 then
            ----@type SkillLogicService
            local skillLogicService = self._world:GetService("SkillLogic")
            local isSingleEntitySkill = skillLogicService:IsSelectEntitySkill(skillID)
            if isSingleEntitySkill then
                --怪受单体攻击伤害加成
                if defender:MonsterID() then
                    ----@type AttributesComponent
                    local attributeCmpt = defender:Attributes()
                    local dmgParamSingleTypeSkill = attributeCmpt:GetAttribute("DmgParamSingleTypeSkill")
                    if dmgParamSingleTypeSkill then
                        val = val * dmgParamSingleTypeSkill
                        logger:AddDamageLog(attacker:GetID(), {
                            key = "FinalDamage",
                            desc = "***怪受单体攻击时最终伤害增伤系数[dmgParamSingleTypeSkill] 最终伤害值[val]***",
                            dmgParamSingleTypeSkill = dmgParamSingleTypeSkill,
                            val = val
                        })
                    end
                end
            end
        end
    end

    local attackerSanFinal = (1 + (self:_Attributes(attacker):GetAttribute("SanSkillFinalParam") or 0))
    val = val * attackerSanFinal
    logger:AddDamageLog(attacker:GetID(), {
        key = "FinalDamage",
        desc = "***san技能最终伤害系数[attackerSanFinal] 最终伤害值[val]***",
        attackerSanFinal = attackerSanFinal,
        val = val
    })

    -- 带有这个参数的==格子伤害
    if damageGridPos then
        local defenderFinalBeHitArray = defender:BuffComponent():GetBuffValue("DEFENDER_FINAL_BE_HIT_POS_ARRAY") or {}
        if #defenderFinalBeHitArray > 0 then
            local defGridType = self:_GetRelativePosMapDir(defender:GetGridDirection())
            local bodyAreaPosMap
            local defBodyArea = defender:BodyArea():GetArea()
            if #defBodyArea == 4 then
                bodyAreaPosMap = _G.DirectionalRelativePosMap[DirectionalRelativePosMapType.Classical4Grid]
            elseif #defBodyArea == 9 then
                bodyAreaPosMap = _G.DirectionalRelativePosMap[DirectionalRelativePosMapType.Classical9Grid]
            end
            if bodyAreaPosMap and bodyAreaPosMap[defGridType] then
                local t = {}
                for _, index in ipairs(defenderFinalBeHitArray) do
                    local v2Relative = bodyAreaPosMap[defGridType][index]
                    table.insert(t, v2Relative + defender:GetGridPosition())
                end

                if table.Vector2Include(t, damageGridPos) then
                    local rate = defender:BuffComponent():GetBuffValue("DEFENDER_FINAL_BE_HIT_POS_RATE") or 0
                    val = val * (1 - rate)
                    logger:AddDamageLog(attacker:GetID(), {
                        key = "FinalDamage",
                        desc = "***身形减伤[rate] 最终伤害值[val]***",
                        rate = rate,
                        val = val
                    })
                end
            end
        end
    end
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    if affixSvc:HasIncreasePetNoDefenceDamage() then
        local increasePercent = affixSvc:GetIncreasePetNoDefenceDamageParam()
        local needIncrease = false
        local useAttacker = attacker
        if attacker:HasSuperEntity() then
            useAttacker = attacker:SuperEntityComponent():GetSuperEntity()
        end
        if useAttacker and useAttacker:HasPet() then
            ---@type Entity
            local localTeamEntity = self._world:Player():GetLocalTeamEntity()
            local ownerTeamEntity = useAttacker:Pet():GetOwnerTeamEntity()
            if ownerTeamEntity == localTeamEntity then
                if defender then
                    local defenderCheckOk = false
                    ---@type Entity
                    local enemyTeam = ownerTeamEntity:Team():GetEnemyTeamEntity()
                    if defender:HasMonsterID() then
                        defenderCheckOk = true
                    elseif enemyTeam and (enemyTeam == defender) then
                        defenderCheckOk = true
                    end
                    if defenderCheckOk then
                        if damageType == DamageType.Real then
                            needIncrease = true
                        else
                            local finalDef = self:_CalcFinalDef(defender, attacker, damageGridPos)
                            local noDefence = self:_IsNoDefence(attacker)
                            if noDefence and noDefence == 1 then
                                needIncrease = true
                            elseif finalDef and finalDef <= 0 then
                                needIncrease = true
                            end
                        end
                    end
                end
            end
        end
        if needIncrease then
            local petNoDefenceDamageIncreaseParam = increasePercent
            val = val * (1 + petNoDefenceDamageIncreaseParam)
            logger:AddDamageLog(attacker:GetID(), {
                key = "FinalDamage",
                desc = "***光灵无视防御伤害提高系数[petNoDefenceDamageIncreaseParam] 最终伤害值[val]***",
                petNoDefenceDamageIncreaseParam = petNoDefenceDamageIncreaseParam,
                val = val
            })
        end
    end
    return val
end

---@param gridDir Vector2
---@return number
function FormulaService:_GetRelativePosMapDir(gridDir)
    local dir = gridDir:Clone()
    --这个方向是向量做差得到的，其数值可能超出我们的想象，只有变量的正负关系是我们需要的
    if dir.x > 0 then
        dir.x = 1
    elseif dir.x < 0 then
        dir.x = -1
    end
    if dir.y > 0 then
        dir.y = 1
    elseif dir.y < 0 then
        dir.y = -1
    end

    local dirType = 0
    if dir == Vector2.down then
        dirType = 1
    elseif dir == Vector2.left then
        dirType = 2
    elseif dir == Vector2.up then
        dirType = 3
    elseif dir == Vector2.right then
        dirType = 4
    else
        Log.error("身形减伤判定错误：方向不受支持：", tostring(gridDir))
    end
    return dirType
end

--region 属性相关系数
--计算属性克制系数（人打怪的情况）
---@param hero Entity
---@param monster Entity
function FormulaService:CalcElementParam(hero, monster)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    local cBuff = monster:BuffComponent()

    local val = 1

    --1.确定属性
    local t1 = utilSvc:GetEntityElementType(hero)
    local t2 = utilSvc:GetEntityElementType(monster)
    if t1 == nil or t2 == nil then 
        Log.fatal("can not find element type")
        return val
    end

    local flag = self:GetRestrainFlag(t1, t2, hero, monster)

    self._world:GetSyncLogger():Trace({key = "CalcElementParam", t1 = t1, t2 = t2})

    if flag == ElementRelationFlag.Counter then --怪被克
        val = val + BattleConst.Strong
        local ExElementParam = self:CalcExElementParam(hero)
        local ExBeHitElementParam = self:CalcExBeHitElementParam(monster)
        val = val + ExElementParam + ExBeHitElementParam
        local a = cBuff:GetBuffValue("ElementReinforceFactorA")
        if a and a > 0 then
            val = val * a
        end
    elseif flag == ElementRelationFlag.BeCountered then --怪克制攻击者
        val = val - BattleConst.Counter
        local c = cBuff:GetBuffValue("ElementReinforceFactorC")
        if c and c > 0 then
            val = val * c
        end
    elseif flag == ElementRelationFlag.Normal then --无克制关系
        local b = cBuff:GetBuffValue("ElementReinforceFactorB")
        if b and b > 0 then
            val = val * b
        end
    end

    return val
end

---@return number 标记 0=t1克t2；1=t2克t1；2=无克制关系
---@param t1 PieceType
---@param t2 PieceType
function FormulaService:GetRestrainFlag(t1, t2, attacker, defender)
    --先判断有没有buff修改克制关系
    if attacker then
        local attr = self:_Attributes(attacker)
        if attr then
            local forceRestrain = attr:GetAttribute("BuffForceElementRestrained") or 0
            if forceRestrain == 1 then
                return ElementRelationFlag.Counter
            end
        end
    end

    if ElementRelation[t1].lt == t2 then --t1被t2克制
        return ElementRelationFlag.BeCountered
    elseif ElementRelation[t1].bt == t2 then --t1克制t2
        return ElementRelationFlag.Counter
    else
        return ElementRelationFlag.Normal
    end
end

--额外属性克制系数
function FormulaService:CalcExElementParam(entity)
    local val = self:_Attributes(entity):GetAttribute("ExElementParam") or 0
    return val
end
--额外被击属性系数
function FormulaService:CalcExBeHitElementParam(entity)
    return self:_Attributes(entity):GetAttribute("ExBeHitElementParam") or 0
end

--百斯特曼：额外被击属性系数
function FormulaService:CalcTrueDamageFixParam(entity)
    return self:_Attributes(entity):GetAttribute("TrueDamageFixParam") or 0
end

--计算属性克制系数（怪打人的情况）
function FormulaService:CalcElementParamM(hero, monster)
    local t1 = PieceType.None
    local t2 = PieceType.None
    if hero:Element() ~= nil and hero:Element():GetPrimaryType() ~= nil then
        t1 = hero:Element():GetPrimaryType()
    end
    if monster:Element() ~= nil and monster:Element():GetPrimaryType() ~= nil then
        t2 = monster:Element():GetPrimaryType()
    end
    if t1 == PieceType.None or t2 == PieceType.None then
        return 1
    end
    local flag = self:GetRestrainFlag(t1, t2, hero, monster)
    -- 打被克制
    if flag == ElementRelationFlag.BeCountered then
        return 0.8
    end
    --打克制的
    if flag == ElementRelationFlag.Counter then
        return 1.2
    end
    return 1
end

--buff附带的x属性伤害系数
function FormulaService:CalcBuffElementParam(element, attacker, monster)
    local t1 = element or PieceType.None
    local t2 = PieceType.None

    if monster:Element() ~= nil and monster:Element():GetPrimaryType() ~= nil then
        t2 = monster:Element():GetPrimaryType()
    end

    if t1 == PieceType.None or t2 == PieceType.None then
        return 1
    end
    local flag = self:GetRestrainFlag(t1, t2, attacker, monster)
    -- 打被克制
    if flag == ElementRelationFlag.BeCountered then
        return 1 - BattleConst.Counter
    end

    --打克制的
    if flag == ElementRelationFlag.Counter then
        return 1 + BattleConst.Strong
    end
    return 1
end

--陷阱对人和怪的属性伤害克制系数
function FormulaService:CalcTrapElementParam(trap, target)
    local t1 = PieceType.None
    local t2 = PieceType.None
    if trap:Element() ~= nil and trap:Element():GetPrimaryType() ~= nil then
        t1 = trap:Element():GetPrimaryType()
    end
    if target:Element() ~= nil and target:Element():GetPrimaryType() ~= nil then
        t2 = target:Element():GetPrimaryType()
    end
    if t1 == PieceType.None or t2 == PieceType.None then
        return 1
    end
    local flag = self:GetRestrainFlag(t1, t2, trap, target)
    -- 打被克制
    if flag == ElementRelationFlag.BeCountered then
        return 1 - BattleConst.Counter
    end
    --打克制的
    if flag == ElementRelationFlag.Counter then
        return 1 + BattleConst.Strong
    end
    return 1
end
--endregion

--根据基础值计算一个结果
function FormulaService:CalcBaseByPercent(base, percent)
    return base * percent
end

---@param entity Entity
function FormulaService:_CalcSkillParam_DefenderSkillAmpfily(entity)
    ---@type AttributesComponent
    local cAttr = entity:Attributes()
    if not cAttr then
        return 0
    end
    local nAttrDamageAmpfily = cAttr:GetAttribute("DamagePercentAmpfily")
    return nAttrDamageAmpfily or 0
end

--[米娅大招，对方损失血量百分比伤害加成]
function FormulaService:_CalcActiveSkillPercentByDefenderHP(defender, damageParam)
    local addedPercent = 0
    local addDamagePercent = damageParam:GetAddDamagePercent()
    if addDamagePercent then
        local maxAddedDamagePercent = damageParam:GetMaxAddedDamagePercent()
        ---@type AttributesComponent
        local cAttr = defender:Attributes()
        local p = 0
        if cAttr then
            local maxHp = cAttr:CalcMaxHp() or 1
            local curHp = cAttr:GetCurrentHP() or 0
            p = (maxHp - curHp) / maxHp * 100
        end
        addedPercent = p * addDamagePercent
        addedPercent = math.min(addedPercent, maxAddedDamagePercent)
    end
    return addedPercent
end

--[百斯特曼大招，单次伤害上限]
function FormulaService:_CalcOnceMaxDamage(casterEntity, damageParam)
    local onceMaxDamageType = damageParam:GetOnceMaxDamageType()
    local onceMaxDamageParam = damageParam:GetOnceMaxDamageParam()

    if onceMaxDamageType == OnceMaxDamageType.CasterBaseATK then
        if not onceMaxDamageParam then
            --MSG64841 需要支持这么配置，但可能不想用这个功能，所以在这里进行处理
            return nil
        end
        local cAttr = casterEntity:Attributes()
        local baseAtk = cAttr:GetAttribute("Attack")
        local final = baseAtk * onceMaxDamageParam
        return self:_RET(final)
    end

    return nil
end

function FormulaService:_CalcOnceMinDamage(casterEntity, damageParam)
    --补一下注释，这里用onceMaxDamageType而不是新的参数是策划的要求
    local onceMaxDamageType = damageParam:GetOnceMaxDamageType()
    local onceMinDamageParam = damageParam:GetOnceMinDamageParam()

    if onceMaxDamageType == OnceMaxDamageType.CasterBaseATK then
        if not onceMinDamageParam then
            return nil
        end
        local cAttr = casterEntity:Attributes()
        local baseAtk = cAttr:GetAttribute("Attack")
        local final = baseAtk * onceMinDamageParam
        return self:_RET(final)
    end

    return nil
end

----返回 主动技吸收系数,主副属性系数,技能提高系数,技能最终伤害系数,主动技系数
function FormulaService:_GetActiveSkillParam(attacker, defender)
    local activeSkillParam = self:_CalcSkillParam_ActiveSkill(attacker)
    local activeSkillAbsorbParam = self:CalcAbsorbParam_ActiveSkill(defender)
    local primarySecondaryParam = self:CalcPrimarySecondaryParam_ActiveSkill(attacker)
    local skillIncreaseParam = self:_CalcSkillIncreaseParam_ActiveSkill(attacker)
    local skillFinalParam = self:_CalcSkillFinalParam_ActiveSkill(attacker)
    return activeSkillAbsorbParam, primarySecondaryParam, skillIncreaseParam, skillFinalParam, activeSkillParam
end
---由攻击者决定计算伤害时是否使用 对方的防御参数
function FormulaService:_IsNoDefence(attacker)
    local val = self:_Attributes(attacker):GetAttribute("NoDefence") or 0

    if val > 1 then
        val = 1
    elseif val < 0 then
        val = 0
    end

    return val
end
---由攻击者决定计算伤害时是否使用忽略对方队伍中队员的防御参数--精英怪buff
function FormulaService:_IsIgnoreTeamMemberDefence(attacker)
    local val = self:_Attributes(attacker):GetAttribute("IgnoreTeamMemberDefence") or 0

    if val > 1 then
        val = 1
    elseif val < 0 then
        val = 0
    end
    return val
end
---@param defender Entity
---@param val number
---@param damageType DamageType
function FormulaService:PostProcessPercentDamage(defender, val, damageType)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    if not buffLogicSvc:IsTargetCanBePercentDamage(defender) then
        return 0, DamageType.Miss
    end
    return val, damageType
end

---@param defender Entity
---@param val number
---@param damageType DamageType
function FormulaService:PostProcessDeadDamage(defender, val, damageType)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    if not buffLogicSvc:IsTargetCanBeToDie(defender) then
        return 0, DamageType.Miss
    end
    return val, damageType
end

---检查是否可以造成百分比伤害
function FormulaService:_CheckPercentDamage(defender)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    return buffLogicSvc:IsTargetCanBePercentDamage(defender)
end

---检查是否可以造成即死伤害
function FormulaService:_CheckDeadDamage(defender)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    return buffLogicSvc:IsTargetCanBeToDie(defender)
end
