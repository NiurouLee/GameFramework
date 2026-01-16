--[[------------------------------------------------------------------------------------------
    SkillRandAttackCalculator : 随机伤害
    只有刑拘娘用
]] --------------------------------------------------------------------------------------------

_class("SkillRandAttackCalculator", Object)
---@class SkillRandAttackCalculator: Object
SkillRandAttackCalculator = SkillRandAttackCalculator

---@param world MainWorld
function SkillRandAttackCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillLogicService
    self._skillLogicService = self._world:GetService("SkillLogic")
    ---@type SkillEffectCalcService
    self._skillEffectCalcService = self._world:GetService("SkillEffectCalc")

    ---@type MathService
    self._mathService = self._world:GetService("Math")
end

---@param casterEntity Entity
---@param skillEffectParam SkillSerialKillerEffectParam
function SkillRandAttackCalculator:DoRandAttack(skillID, casterEntity, skillEffectParam)
    ---@type SkillEffectParam_RandAttack
    local workEffectParam = skillEffectParam

    local posCaster = casterEntity:GridLocation().Position

    ---2020-03-17 修改灵魂数量为"全局"
    if not casterEntity:HasAttributes() then
        casterEntity:AddAttributes()
    end

    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillDamageEffectResult
    local skillResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    local listTargetHp = {}
    local listAlive = {} ---保存第一轮打击后的幸存目标
    local listDeath = {}
    for k, res in ipairs(skillResultArray) do
        local targetEntityID = res:GetTargetID()
        if targetEntityID > 0 then
            local nCurHp = listTargetHp[targetEntityID]
            if nil == nCurHp then
                local targetEntity = self._world:GetEntityByID(targetEntityID)
                local nCurHp = targetEntity:Attributes():GetCurrentHP() ---获取的是逻辑层的值
                listTargetHp[targetEntityID] = nCurHp
                if nCurHp > 0 then
                    listAlive[#listAlive + 1] = targetEntity
                elseif targetEntity:HasMonsterID() then --黑拳赛容错
                    listDeath[#listDeath + 1] = targetEntity
                    --立即死亡
                    sMonsterShowLogic:AddMonsterDeadMark(targetEntity)

                end
            end
        end
    end

    ---@type CalcDamageService
    local svcCalcDamage = self._world:GetService("CalcDamage")
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")

    local soulCount = casterEntity:BuffComponent():GetBuffValue("SoulCount") or 0
    ---生成随机打击目标
    local nNewSoulCount = soulCount
    nNewSoulCount = math.min(nNewSoulCount, workEffectParam:GetMaxTimes())
    nNewSoulCount = math.max(nNewSoulCount, workEffectParam:GetMinTimes())
    local nAttackTimes = nNewSoulCount
    ---@type SkillEffectResult_RandAttackData[]
    local listRandAttackData = {}
    if #listAlive > 0 then
        ---@type FormulaService
        local formulaService = self._world:GetService("Formula")
        ---@type SkillLogicService
        local skillLogicService = self._world:GetService("SkillLogic")
        ---@type TriggerService
        local triggerSvc = self._world:GetService("Trigger")
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        local attackPos = casterEntity:GridLocation():GetGridPos()
        for i = 1, nAttackTimes do
            local nRand = randomSvc:LogicRand(1, #listAlive)
            local targetEntity = listAlive[nRand]
            if targetEntity then
                local targetPos = targetEntity:GridLocation():GetGridPos()
                local nt = NTRandAttackBegin:New(casterEntity, targetEntity, attackPos, targetPos)
                triggerSvc:Notify(nt)
                ---@type DamageInfo
                local damageInfo =
                    svcCalcDamage:DoCalcDamage(
                    casterEntity,
                    targetEntity,
                    {
                        percent = workEffectParam:GetPercent(),
                        skillID = skillID,
                        formulaID = workEffectParam:GetFormulaID(),
                        skillEffectType = SkillEffectType.RandAttack
                    }
                )

                local defenderData = SkillEffectResult_RandAttackData:New(targetEntity:GetID(), damageInfo)
                listRandAttackData[#listRandAttackData + 1] = defenderData
                ---修改逻辑数据：生效
                if targetEntity:HasMonsterID() then
                    local curHP = targetEntity:Attributes():GetCurrentHP()
                    if curHP <= 0 then
                        --立即死亡
                        sMonsterShowLogic:AddMonsterDeadMark(targetEntity)

                    end
                end
                local nt = NTRandAttackEnd:New(casterEntity, targetEntity, attackPos, targetPos)
                triggerSvc:Notify(nt)
            end
        end
    end
    local skillResult = self:_GenerateResult(nAttackTimes, listRandAttackData, listDeath, listAlive)
    skillEffectResultContainer:AddEffectResult(skillResult, true)
    return skillResult
end

function SkillRandAttackCalculator:_EntityList2IDList(entityList)
    local t = {}
    for _, e in ipairs(entityList) do
        table.insert(t, e:GetID())
    end

    return t
end

-- 将所有对实体的直接关联转换为ID
function SkillRandAttackCalculator:_GenerateResult(nAttackTimes, listRandAttackData, listDeath, listAlive)
    local listDeathID = {}
    local listDeathPos = {}
    for _, entity in ipairs(listDeath) do
        table.insert(listDeathID, entity:GetID())
        table.insert(listDeathPos, entity:GetGridPosition())
    end

    local listAliveID = self:_EntityList2IDList(listAlive)

    return SkillEffectResult_RandAttack:New(nAttackTimes, listRandAttackData, listDeathID, listDeathPos, listAliveID)
end
