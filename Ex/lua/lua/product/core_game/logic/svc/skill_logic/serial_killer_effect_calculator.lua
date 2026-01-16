--[[------------------------------------------------------------------------------------------
    SerialKillerEffectCalculator : 连杀效果计算器
    目前只有微丝的大招在用
]] --------------------------------------------------------------------------------------------

---@class SerialKillerEffectCalculator: Object
_class("SerialKillerEffectCalculator", Object)
SerialKillerEffectCalculator = SerialKillerEffectCalculator

---@param world MainWorld
function SerialKillerEffectCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillLogicService
    self._skillLogicService = self._world:GetService("SkillLogic")
    ---@type SkillEffectCalcService
    self._skillEffectCalcService = self._world:GetService("SkillEffectCalc")
end

---@param casterEntity Entity
---@param skillEffectParam SkillSerialKillerEffectParam
function SerialKillerEffectCalculator:DoSerialKillerCalc(casterEntity, skillEffectParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local targetIDs = scopeResult:GetTargetIDs()

    ---@type SkillSerialKillerResult
    local result = self:_CalcSkillSerialKillerEffect(casterEntity:GetID(), targetIDs, skillEffectParam, skillID)
    local count = table.count(result:GetKilledArray())
    for index, res in ipairs(result:GetKilledArray()) do
        ---@type DamageInfo
        local damageInfo = res:GetDamageInfo(1)
        damageInfo:SetAttackerEntityID(casterEntity:GetID())
        skillEffectResultContainer:AddEffectResult(res)

        ---@type MonsterShowLogicService
        local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(monsterGroup:GetEntities()) do
            sMonsterShowLogic:AddMonsterDeadMark(e)
        end

        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        --判断胜利条件满足则停止伤害
        if battleService:IsFinalAttack() and index == count then
            skillEffectResultContainer:SetFinalAttack(true)
            break
        end
    end

    return result
end

--连环杀人效果
---@param nearestEntityIDs 最近的N个敌人
function SerialKillerEffectCalculator:_CalcSkillSerialKillerEffect(
    casterEntityID,
    nearestEntityIDs,
    skillEffectParam,
    skillID)
    ---@type SkillSerialKillerEffectParam
    local param = skillEffectParam
    local percent = param:GetPercent()
    local firstMultiple = param:GetMultiple()
    local damageFormulaID = param:GetFormulaID()
    local killCount = param:GetKillCount()

    ---@type FormulaService
    local formulaService = self._world:GetService("Formula")
    local attacker = self._world:GetEntityByID(casterEntityID)
    local res = SkillSerialKillerResult:New()

    local extraAttackCount, addPiecePosList = self:_CalExtraAttackCount(param, attacker)
    res:SetAddPiecePosList(addPiecePosList)
    killCount = killCount + extraAttackCount
    local hasDamage = 0
    local curDefendEntity = nil
    local curDefendEntityId = nil

    local deadDefnderIdList = {}
    local defenderIdList = {}
    local damageList = {}
    for k, defenderEntityID in ipairs(nearestEntityIDs) do
        ---@type Entity
        local defender = self._world:GetEntityByID(defenderEntityID)
        local curHp = defender:Attributes():GetCurrentHP()
        if curHp > 0 then
            defenderIdList[#defenderIdList + 1] = defenderEntityID
        end
    end
    local gameFsmCmpt = self._world:GameFSM()
    local gameFsmStateID = gameFsmCmpt:CurStateID()

    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if gameFsmStateID ~= GameStateID.PreviewActiveSkill then
        local mathService = self._world:GetService("Math")
        ---@type CalcDamageService
        local svcCalcDamage = self._world:GetService("CalcDamage")

        for i = 1, killCount do
            --如果当前的目标不存在重新取
            if not curDefendEntity then
                if #defenderIdList <= 0 then
                    if #deadDefnderIdList <= 0 then
                        break
                    end
                    --随机一个目标
                    local randomIndex = randomSvc:LogicRand(1, #deadDefnderIdList)
                    local defenderId = deadDefnderIdList[randomIndex]
                    curDefendEntity = self._world:GetEntityByID(defenderId)
                    curDefendEntityId = defenderId
                else
                    --随机一个目标
                    local randomIndex = randomSvc:LogicRand(1, #defenderIdList)
                    local defenderId = defenderIdList[randomIndex]
                    curDefendEntity = self._world:GetEntityByID(defenderId)
                    curDefendEntityId = defenderId
                end
            end

            ---判定是否是首次伤害
            local tmpPercent = percent
            if not damageList[curDefendEntityId] then
                ---首次伤害按配置倍率翻倍
                tmpPercent = tmpPercent * firstMultiple
            end

            ---@type SkillEffectCalcService
            local effectCalcService = self._world:GetService("SkillEffectCalc")
            effectCalcService:NotifyDamageBegin(attacker, curDefendEntity, attacker:GetGridPosition(), curDefendEntity:GetGridPosition(), skillID)
            ---@type SkillDamageEffectParam
            local _damageParam = SkillDamageEffectParam:New(param);
            _damageParam._pureDamage = param:GetPureDamage()
            _damageParam._percent = tmpPercent
            _damageParam._formulaID = damageFormulaID
            _damageParam.percent = tmpPercent
            _damageParam.skillID = skillID
            _damageParam.formulaID = damageFormulaID
            _damageParam.attackPos = attacker:GetGridPosition()
            --没有死亡继续攻击
            ---@type DamageInfo
            local damageInfo =
                svcCalcDamage:DoCalcDamage(
                attacker,
                curDefendEntity,
                _damageParam
                --{
                --    percent = percent,
                --    skillID = skillID,
                --    formulaID = damageFormulaID
                --}
            )

            effectCalcService:NotifyDamageEnd(attacker, curDefendEntity, attacker:GetGridPosition(), curDefendEntity:GetGridPosition(), skillID, damageInfo, SkillEffectType.SerialKiller, i)

            --目标累计的伤害

            --if not table.intable(damageList, curDefendEntityId) then
            --    local damageSaveData = {}
            --    damageSaveData.id = curDefendEntityId
            --    damageSaveData.damage = 0
            --    table.insert(damageList, damageSaveData)
            --end
            --local curDamageSaveData
            --for i = 1, #damageList do
            --    if damageList[i].id == curDefendEntityId then
            --        curDamageSaveData = damageList[i]
            --        break
            --    end
            --end
            if not damageList[curDefendEntityId] then
                local damageSaveData = {}
                damageSaveData.id = curDefendEntityId
                damageSaveData.damage = 0
                damageList[curDefendEntityId] = damageSaveData
            end
            local curDamageSaveData = damageList[curDefendEntityId]
            --Log.fatal("Begin EntityID:",curDefendEntityId,"Damage:",damageInfo:GetDamageValue(),"TotalHP:",curDefendEntity:Attributes():GetAttribute("HP") ,"Damage:", curDamageSaveData.damage)
            curDamageSaveData.damage = curDamageSaveData.damage + damageInfo:GetDamageValue()
            --Log.fatal("End EntityID:",curDefendEntityId,"Damage:",damageInfo:GetDamageValue(),"TotalHP:",curDefendEntity:Attributes():GetAttribute("HP") ,"Damage", curDamageSaveData.damage)
            local damageResult =
                SkillDamageEffectResult:New(
                curDefendEntity:GetGridPosition(),
                curDefendEntityId,
                damageInfo:GetDamageValue(),
                {damageInfo}
            )
            res:AddOneKilled(damageResult)

            --目标死亡，需要重新取获取目标
            --if curDefendEntity:Attributes():GetAttribute("HP") - curDamageSaveData.damage <= 0 then
            if curDefendEntity:Attributes():GetCurrentHP() <= 0 then
                --删除已经死亡的角色
                for i = 1, #defenderIdList do
                    if defenderIdList[i] == curDefendEntityId then
                        table.remove(defenderIdList, i)
                        break
                    end
                end
                --增加死亡的角色
                local isFind = false
                for i = 1, #deadDefnderIdList do
                    if deadDefnderIdList[i] == curDefendEntityId then
                        isFind = true
                        break
                    end
                end
                if not isFind then
                    table.insert(deadDefnderIdList, curDefendEntityId)
                end
            end
            curDefendEntity = nil
            curDefendEntityId = nil
        end
    end
    return res
end

--计算额外攻击次数
function SerialKillerEffectCalculator:_CalExtraAttackCount(param, attacker)
    --计算指定区域的格子数量
    local serialScopeType = param:GetSerialScopeType()
    local radius = param:GetRadius()
    local posCaster = attacker:GetGridPosition()
    local casterBodyArea = attacker:BodyArea():GetArea()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local scopeResult =
        scopeCalculator:ComputeScopeRange(serialScopeType, {[1] = radius, [2] = 0}, posCaster, casterBodyArea)
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()

    --计算额外攻击次数
    local extraAttackCount = 0
    local boardService = self._world:GetService("BoardRender")
    local pieceType = param:GetPieceType()
    ---@type Vector2[]
    local addPiecePosList = {}
    if scopeResult then
        local array = scopeResult:GetAttackRange()
        for _, v in ipairs(array) do
            local pt = board:GetPieceType(v)
            if pt == pieceType then
                extraAttackCount = extraAttackCount + 1
                table.insert(addPiecePosList, v)
            end
        end
    end
    local onPieceAddAttackCount = param:GetOnePieceAddAttackCount()
    extraAttackCount = extraAttackCount * onPieceAddAttackCount
    return extraAttackCount, addPiecePosList
end
