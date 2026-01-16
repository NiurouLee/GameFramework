---用于技能表现使用的条件判断集合
---@class SkillViewConditionHelper: Object
_class("SkillViewConditionHelper", Object)
SkillViewConditionHelper = SkillViewConditionHelper

---@param world MainWorld
function SkillViewConditionHelper:Constructor(world) --Jump指令的条件函数只需定义一个即可，对条件取反只需将Jump指令的result参数配成0即可。
    ---@type MainWorld
    self._world = world
    self._conditionDic = {}
    self._conditionDic["CheckDamageIndexValid"] = self.CheckDamageIndexValid
    self._conditionDic["CheckDamageInfoIndexValid"] = self.CheckDamageInfoIndexValid
    self._conditionDic["CheckDamageIndex2Valid"] = self.CheckDamageIndex2Valid
    self._conditionDic["CheckBuffIndexValid"] = self.CheckBuffIndexValid
    self._conditionDic["CheckIsLastDamage"] = self.CheckIsLastDamage
    self._conditionDic["CheckPickUpIndexValid"] = self.CheckPickUpIndexValid
    self._conditionDic["CheckCurrentScopeGridRangeIndexValid"] = self.CheckCurrentScopeGridRangeIndexValid
    self._conditionDic["CheckAbsortPieceCountLessThan"] = self.CheckAbsortPieceCountLessThan
    self._conditionDic["CheckAbsortPieceCountMoreThan"] = self.CheckAbsortPieceCountMoreThan
    self._conditionDic["CheckTrue"] = self.CheckTrue
    self._conditionDic["CheckBuffRefreshValid"] = self._CheckBuffRefreshValid
    self._conditionDic["CheckSummonThingValid"] = self._CheckSummonThingValid
    self._conditionDic["CheckTargetCountInScope"] = self._CheckTargetCountInScope
    self._conditionDic["CheckEffectResultIndex"] = self._CheckEffectResultIndex
    self._conditionDic["CheckEffectMultiResultIndex"] = self._CheckEffectMultiResultIndex
    self._conditionDic["CheckContainCurrentScopeGrid"] = self._CheckContainCurrentScopeGrid
    self._conditionDic["IsAddBloodValueGreaterThan"] = self._IsAddBloodValueGreaterThan --施法者加血效果值是否大于conditionParam
    self._conditionDic["CheckMiyaPhase2"] = self.CheckMiyaPhase2
    self._conditionDic["CheckDamageIndexLast"] = self.CheckDamageIndexLast
    ---这里判断的是单格可位移的怪物
    self._conditionDic["CheckTargetIsCanMove"] = self._CheckTargetIsCanMove
    self._conditionDic["CheckDamageSkillResultTargetCount"] = self.CheckDamageSkillResultTargetCount --检查伤害结果的目标数量(只查怪物)
    self._conditionDic["CheckCasterHasBuff"] = self.CheckCasterHasBuff --检查施法者是否拥有buff
    self._conditionDic["CheckDeadTarget"] = self.CheckDeadTarget --检查技能目标中死亡的
    self._conditionDic["CheckHasTeleport"] = self._CheckHasTeleport --检查是否瞬移
    self._conditionDic["CheckOnAbyss"] = self._CheckOnAbyss --检查是否在深渊上
    self._conditionDic["CheckCurScopeRangeOnCrossLine"] = self._CheckCurScopeRangeOnCrossLine --检查范围是否是一条十字方向上的直线（希诺普，技能范围是正方形4格或长条四格，需要不同的特效播放方式）
    self._conditionDic["CheckSummonOnFixPosValid"] = self._CheckSummonOnFixPosValid
    self._conditionDic["CheckIsFirstP5PetInTeam"] = self._CheckIsFirstP5PetInTeam
    self._conditionDic["CheckIsAllWeak"] = self._CheckIsAllWeak--p5 合击技 判断敌人是否都处于weak
    self._conditionDic["CheckTrapOpenStateChangeByResult"] = self._CheckTrapOpenStateChangeByResult
    self._conditionDic["CheckTrapSummonMonsterByResult"] = self._CheckTrapSummonMonster
    self._conditionDic["CheckTrapOpenStateChange"] = self._CheckTrapOpenStateChange
    self._conditionDic["CheckCasterIsDead"] = self._CheckCasterIsDead
    self._conditionDic["CheckHasRotate"] = self._CheckHasRotate
    self._conditionDic["CheckCurrentRoundCount"] = self._CheckCurrentRoundCount
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:CheckCondition(conditionName, casterEntity, phaseContext, conditionParam)
    local conditionFunc = self._conditionDic[conditionName]
    if conditionFunc then
        return conditionFunc(self, casterEntity, phaseContext, conditionParam)
    else
        Log.fatal("Can not find condition function:", conditionName)
    end
end

---当前伤害索引是否有效
function SkillViewConditionHelper:CheckDamageIndexValid(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, damageStageIndex)
    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if not damageResultArray or #damageResultArray == 0 then
        return false
    end
    if damageResultArray[1]._targetID == -1 then
        return false
    end
    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurDamageResultIndex()
    if damageIndex > 0 and damageIndex <= #damageResultArray then
        return true
    end

    return false
end

function SkillViewConditionHelper:CheckDamageInfoIndexValid(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage,damageStageIndex)
    if not damageResultArray then
        return false
    end
    if damageResultArray[1]._targetID == -1 then
        return false
    end
    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurDamageResultIndex()
    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[damageIndex]
    if not damageResult then
        return false
    end
    local damageInfoIndex = phaseContext:GetCurDamageInfoIndex()
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(damageInfoIndex)
    if not damageInfo then
        return false
    end
    return true
end


function SkillViewConditionHelper:CheckDamageIndex2Valid(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage,damageStageIndex)
    if not damageResultArray then
        return false
    end
    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurDamageIndex()
    for i, damageResult in ipairs(damageResultArray) do
        if damageResult:GetDamageIndex() == damageIndex then
            local damageInfoIndex = phaseContext:GetCurDamageInfoIndex()
            ---@type DamageInfo
            local damageInfo = damageResult:GetDamageInfo(damageInfoIndex)
            if damageInfo then
                return true
            end
        end
    end
    return false
end

---當前buff索引是否有效
function SkillViewConditionHelper:CheckBuffIndexValid(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBuff)
    if not damageResultArray then
        return false
    end
    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurBuffResultIndex()
    if damageIndex > 0 and damageIndex <= #damageResultArray then
        return true
    end
    return false
end

function SkillViewConditionHelper:CheckIsLastDamage(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurDamageResultIndex()
    if damageIndex > 0 and damageIndex < #damageResultArray then
        return false
    end
    return true
end

function SkillViewConditionHelper:CheckCurrentScopeGridRangeIndexValid(casterEntity, phaseContext, conditionParam)
    local scopeGridRange = phaseContext:GetScopeGridRange()
    if not scopeGridRange then
        return false
    end
    local maxScopeRangeCount = phaseContext:GetMaxRangeCount()
    if not maxScopeRangeCount then
        return false
    end
    local curScopeGridRangeIndex = phaseContext:GetCurScopeGridRangeIndex()
    if curScopeGridRangeIndex > maxScopeRangeCount then
        return false
    end
    return true
end

function SkillViewConditionHelper:CheckAbsortPieceCountLessThan(casterEntity, phaseContext, conditionParam)
    local count = 0
    if conditionParam then
        count = tonumber(conditionParam)
    end
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local absorbResult = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AbsorbPiece)
    local absorbCount = 0
    if absorbResult then
        for _, v in pairs(absorbResult) do
            local list = v:GetAbsorbPieceList()
            if list then
                for _, p in pairs(list) do
                    absorbCount = absorbCount + 1
                end
            end
        end
    end
    if absorbCount < count then
        return true
    end
    return false
end

function SkillViewConditionHelper:CheckAbsortPieceCountMoreThan(casterEntity, phaseContext, conditionParam)
    local count = 0
    if conditionParam then
        count = tonumber(conditionParam)
    end
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local absorbResult = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AbsorbPiece)
    local absorbCount = 0
    if absorbResult then
        for _, v in pairs(absorbResult) do
            local list = v:GetAbsorbPieceList()
            if list then
                for _, p in pairs(list) do
                    absorbCount = absorbCount + 1
                end
            end
        end
    end
    if absorbCount > count then
        return true
    end
    return false
end

function SkillViewConditionHelper:CheckTrue(casterEntity, phaseContext, conditionParam)
    return true
end

function SkillViewConditionHelper:_CheckBuffRefreshValid(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local ResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ModifyBuffValue)

    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurBuffResultIndex()
    if damageIndex > 0 and damageIndex <= #ResultArray then
        return true
    end

    return false
end

---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckSummonThingValid(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer == nil then
        Log.fatal("_CheckSummonThingValid skillEffectResultContainer is nil")
        return false
    end

    ---@type SkillEffectResult_SummonEverything[]
    local summonEverythingResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    if not summonEverythingResultArray then
        return false
    end
    local idx = phaseContext:GetCurSummonInEverythingIndex() ---取出当前的召唤索引
    if summonEverythingResultArray[idx] then
        return true
    end
    return false
end

---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckTargetCountInScope(casterEntity, phaseContext, conditionParam)
    local count = tonumber(conditionParam) or 0

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local scopeResult = skillEffectResultContainer:GetScopeResult()
    if not scopeResult then
        return false
    end

    local targetIDs = scopeResult:GetTargetIDs()

    return count == #targetIDs
end

---@class CfgCheckEffectResultIndexParam
---@field effectType number

---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckEffectResultIndex(casterEntity, phaseContext, rawParam)
    assert(type(rawParam) == "string", "Jump: CheckEffectResultIndex需要配置参数")
    local splitParam = string.split(rawParam, "|")
    local conditionParam = {
        effectType = splitParam[1],
        isTargetRequired = splitParam[2]
    }
    local effectType = tonumber(conditionParam.effectType)
    assert(effectType, "Jump: CheckEffectResultIndex需要配置effectType")
    local isTargetRequired = conditionParam.isTargetRequired == "true"

    local resultEffectType = effectType
    local overrideEffectType = SkillEffectResultTypeOverride[effectType]
    if overrideEffectType then
        Log.notice(self._className, "override effectType for results: ", effectType, "=>", overrideEffectType)
        resultEffectType = overrideEffectType
    end

    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultBase[]
    local resultArray = routineCmpt:GetEffectResultsAsArray(resultEffectType)
    if not resultArray then
        Log.warn(self._className, "No results for type", effectType, "=>", overrideEffectType)
        return false
    end

    local index = phaseContext:GetCurResultIndexByType(effectType)
    local result = resultArray[index]

    if not result then
        return false
    end

    if isTargetRequired and result:GetTargetID() == (-1) then
        Log.notice(self._className, "Index ", index, "is invalid. ")
        return false
    end

    return true
end

---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckEffectMultiResultIndex(casterEntity, phaseContext, rawParam)
    assert(type(rawParam) == "string", "Jump: _CheckEffectMultiResultIndex需要配置参数")
    local splitParam = string.split(rawParam, "|")

    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()

    --检测多个技能结果，有一个技能结果就true
    local hasResultCount = 0
    for _, value in ipairs(splitParam) do
        local effectType = tonumber(value)
        ---@type SkillEffectResultBase[]
        local resultArray = routineCmpt:GetEffectResultsAsArray(effectType)
        if resultArray then
            for _, result in ipairs(resultArray) do
                if result then
                    if effectType == SkillEffectType.Damage and result:GetTargetID() == (-1) then
                    else
                        hasResultCount = hasResultCount + 1
                        break
                    end
                end
            end
        end
    end

    return hasResultCount > 0
end

---当前范围位置是否在参数列表中
---@param phaseContext SkillPhaseContext
---@param casterEntity Entity
function SkillViewConditionHelper:_CheckContainCurrentScopeGrid(casterEntity, phaseContext, rawParam)
    local arrStr = string.split(rawParam, "|")
    local posList = {}
    for _, str in ipairs(arrStr) do
        local arrStrPos = string.split(str, "_")
        local v = Vector2(tonumber(arrStrPos[1]), tonumber(arrStrPos[2])) + casterEntity:GetGridPosition()
        table.insert(posList, v)
    end
    local scopeGridRange = phaseContext:GetScopeGridRange()
    local curScopeGridRangeIndex = phaseContext:GetCurScopeGridRangeIndex()
    local gridList = scopeGridRange[curScopeGridRangeIndex]
    for _, range in pairs(scopeGridRange) do
        if range then
            local posList2 = range[curScopeGridRangeIndex]
            if posList2 then
                for _, pos2 in ipairs(posList2) do
                    if table.icontains(posList, pos2) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

---@param casterEntity Entity
function SkillViewConditionHelper:_IsAddBloodValueGreaterThan(casterEntity, phaseContext, conditionParam)
    local valCompare = 0
    if conditionParam then
        valCompare = tonumber(conditionParam)
    end
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_AddBlood[]
    local addHpResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBlood)
    if addHpResultArray then
        for _, result in ipairs(addHpResultArray) do
            local addValue = result:GetAddValue()
            if addValue > valCompare then
                return true
            end
        end
    end
    local eachTrapAddBloodResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.EachTrapAddBlood)--罗伊 连锁加血效果
    if eachTrapAddBloodResultArray then
        for _, result in ipairs(eachTrapAddBloodResultArray) do
            local addValue = result:GetAddValue()
            if addValue > valCompare then
                return true
            end
        end
    end
    return false
end

--米娅魂数量
function SkillViewConditionHelper:CheckSoul(casterEntity, phaseContext, conditionParam)
    ---@type BuffViewComponent
    local buffView = casterEntity:BuffView()
    local soulCount = buffView:GetBuffValue("SoulCount") or 0
    return soulCount > 0
end

--米娅一阶段结束后杀怪数量
function SkillViewConditionHelper:CheckMonsterDeath(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_RandAttack
    local results = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.RandAttack)
    local cnt = results:GetListDeadCount()
    return cnt > 0
end

--米娅二阶段开始前存活怪数量
function SkillViewConditionHelper:CheckMonsterAlive(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_RandAttack
    local results = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.RandAttack)
    local cnt = results:GetListAliveCount()
    return cnt > 0
end

--检查米娅是否可以表现2阶段
function SkillViewConditionHelper:CheckMiyaPhase2(casterEntity, phaseContext, conditionParam)
    return self:CheckSoul(casterEntity, phaseContext, conditionParam) and
        self:CheckMonsterAlive(casterEntity, phaseContext, conditionParam)
end

function SkillViewConditionHelper:CheckDamageIndexLast(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, damageStageIndex)
    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if not damageResultArray or #damageResultArray == 0 then
        return false
    end
    if damageResultArray[1]._targetID == -1 then
        return false
    end
    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurDamageResultIndex()
    if damageIndex > 0 and damageIndex == (#damageResultArray - 1) then
        return true
    end

    return false
end

function SkillViewConditionHelper:_CheckTargetIsCanMove(casterEntity, phaseContext, conditionParam)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    ----@type Entity
    local targetEntity = self._world:GetEntityByID(targetEntityID)
    if not targetEntity then
        --容错处理：库斯库塔将目标移动到莱斯特地雷上时，地雷炸死目标，此时库斯库塔找不到目标，targetEntity为nil
        return false
    end
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local bodyAreaCmpt = targetEntity:BodyArea()
    return not env:IsImmuneHitback(targetEntity) and #bodyAreaCmpt:GetArea() == 1
end

function SkillViewConditionHelper:CheckDamageSkillResultTargetCount(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, damageStageIndex)
    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if not damageResultArray or #damageResultArray == 0 then
        return false
    end

    local targetEntityIDsList = {}

    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        if targetEntity and not targetEntity:HasTrapID() and not table.intable(targetEntityIDsList, targetEntityID) then
            table.insert(targetEntityIDsList, targetEntityID)
        end
    end

    local splitParam = string.split(conditionParam, "|")
    local cmpType = tonumber(splitParam[1])
    local count = tonumber(splitParam[2])

    local isMatch = Algorithm.CmpByOperator(#targetEntityIDsList, count, cmpType)
    return isMatch
end

function SkillViewConditionHelper:CheckCasterHasBuff(casterEntity, phaseContext, conditionParam)
    local splitParam = string.split(conditionParam, "|")
    local targetBuffEffectType = tonumber(splitParam[1])
    local targetBuffCount = tonumber(splitParam[2])

    local curBuffCount = 0
    ---@type BuffViewComponent
    local buffViewComponent = casterEntity:BuffView()
    if buffViewComponent then
        local viewIns = buffViewComponent:GetBuffViewInstanceArray()
        for _, inst in ipairs(viewIns) do
            local buffEffectType = inst:GetBuffEffectType()
            if targetBuffEffectType == buffEffectType then
                curBuffCount = curBuffCount + 1
            end
        end
    end

    local isMatch = (targetBuffCount == curBuffCount)
    return isMatch
end

function SkillViewConditionHelper:CheckDeadTarget(casterEntity, phaseContext, conditionParam)
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, damageStageIndex)
    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if not damageResultArray or #damageResultArray == 0 then
        return false
    end

    local targetEntityList = {}
    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = world:GetEntityByID(targetEntityID)
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        if targetEntity and not table.intable(targetEntityList, targetEntity) then
            table.insert(targetEntityList, targetEntity)
        end
    end

    local deadMonsterIDList = {}
    for _, entity in ipairs(targetEntityList) do
        local view = entity:View()
        local renderCurHP = entity:HP():GetRedHP()

        if view and renderCurHP == 0 then
            table.insert(deadMonsterIDList, entity:GetID())
        end
    end

    ---取出当前的伤害索引
    local damageIndex = phaseContext:GetCurDamageResultIndex()
    if damageIndex > 0 and damageIndex <= #deadMonsterIDList then
        return true
    end

    return false
end

function SkillViewConditionHelper:_CheckHasTeleport(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
        skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, damageStageIndex)

    local hasTeleport = 0
    if conditionParam then
        hasTeleport = tonumber(conditionParam)
    end

    if not teleportEffectResult and hasTeleport == 0 then
        return true
    end

    local oldPos = teleportEffectResult:GetPosOld()
    local newPos = teleportEffectResult:GetPosNew()
    local hasMove = oldPos.x ~= newPos.x or oldPos.y ~= newPos.y

    local result = false
    if hasTeleport == 0 then
        result = not hasMove
    else
        result = hasMove
    end

    return result
end

function SkillViewConditionHelper:_CheckOnAbyss(casterEntity, phaseContext, conditionParam)
    local pos = casterEntity:GetGridPosition()
    local world = casterEntity:GetOwnerWorld()
    ---@type PreviewEnvComponent
    local env = world:GetPreviewEntity():PreviewEnv()
    local es =
        env:GetEntitiesAtPos(
        pos,
        function(e)
            return e:TrapRender() and e:TrapRender():GetTrapType() == TrapType.TerrainAbyss
        end
    )
    local onAbyss = #es > 0
    if tonumber(conditionParam) == 1 then
        return onAbyss
    end
    return not onAbyss
end

function SkillViewConditionHelper:_CheckCurScopeRangeOnCrossLine(casterEntity, phaseContext, conditionParam)
    local scopeGridRange = phaseContext:GetScopeGridRange()
    local curScopeGridRangeIndex = phaseContext:GetCurScopeGridRangeIndex()
    local curRange = scopeGridRange[curScopeGridRangeIndex]
    if not curRange then
        return false
    end
    local gridList = curRange[1]
    if not gridList then
        return false
    end
    if #gridList <= 1 then
        return false
    end
    local xIsLine = true
    local yIsLine = true
    local lastX = gridList[1].x
    local lastY = gridList[1].y
    for index, value in ipairs(gridList) do
        if xIsLine then
            if lastX ~= value.x then
                xIsLine = false
            end
        end
        if yIsLine then
            if lastY ~= value.y then
                yIsLine = false
            end
        end
        if not (xIsLine or yIsLine) then
            break
        end
    end
    return (xIsLine or yIsLine)
end

---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckSummonOnFixPosValid(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer == nil then
        Log.fatal("_CheckSummonOnFixPosValid skillEffectResultContainer is nil")
        return false
    end

    ---@type SkillEffectResultSummonOnFixPosLimit[]
    local summonResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonOnFixPosLimit)
    if not summonResultArray then
        return false
    end
    ---@type SkillEffectResultSummonOnFixPosLimit
    local summonResult = summonResultArray[1]
    local trapIDList = summonResult:GetTrapIDList()
    local idx = phaseContext:GetCurSummonOnFixPosIndex() ---取出当前的召唤索引
    if trapIDList[idx] then
        return true
    end
    return false
end
---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckIsFirstP5PetInTeam(casterEntity, phaseContext, conditionParam)
    local checkPetID = 0
    if conditionParam then
        checkPetID = tonumber(conditionParam)
    end
    if checkPetID > 0 then
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        if teamEntity then
            ---@type TeamComponent
            local teamCmpt = teamEntity:Team()
            ---@type table<number,number>  队伍的逻辑顺序 key是序号 value是PetPstID
            local teamOrder = teamCmpt:GetTeamOrder()
            for order,petPstID in ipairs(teamOrder) do
                local petEntity = teamCmpt:GetPetEntityByPetPstID(petPstID)
                ---@type MatchPet
                local matchPet = petEntity:MatchPet():GetMatchPet()
                local petFeatureList = matchPet:GetFeatureList()--原始配置数据
                if petFeatureList then
                    local petFeatures = petFeatureList.feature
                    if petFeatures then
                        if petFeatures[FeatureType.PersonaSkill] then
                            if matchPet:GetTemplateID() == checkPetID then
                                return true
                            else
                                return false
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end
---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckIsAllWeak(casterEntity, phaseContext, conditionParam)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local allWeak = utilDataSvc:GetEntityAttributeByName(casterEntity,"AllEnemyWeak") or 0
    if allWeak == 1 then
        return true
    end

    return false
end

---@param phaseContext SkillPhaseContext
---@param casterEntity Entity
function SkillViewConditionHelper:_CheckTrapOpenStateChangeByResult(casterEntity, phaseContext, conditionParam)
    local checkState =tonumber(conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectTrapSummonMonsterResult[]
    local resultArray =
    skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.TrapSummonMonster)
    if not resultArray or not  casterEntity:HasTrapRender() then
        return false
    end
    ---@type SkillEffectTrapSummonMonsterResult
    local result = resultArray[1]
    ---@type RenderAttributesComponent
    local renderAttrCmpt = casterEntity:RenderAttributes()
    local change = result:GetTrapOpenStateChange()
    local state = result:GetTrapOpenState()
    if not change then
        return false
    end
    if state==checkState then
        return true
    end
    return false
end

---@param phaseContext SkillPhaseContext
---@param casterEntity Entity
function SkillViewConditionHelper:_CheckTrapSummonMonster(casterEntity, phaseContext, conditionParam)
    local checkState =tonumber(conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectTrapSummonMonsterResult[]
    local resultArray =
    skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.TrapSummonMonster)
    if not resultArray or not  casterEntity:HasTrapRender() then
        return false
    end
    ---@type SkillEffectTrapSummonMonsterResult
    local result = resultArray[1]
    local entityID = result:GetSummonEntityID()
    if checkState ==1  and entityID~=nil then
        return true
    elseif checkState ==0  and entityID==nil then
        return true
    end
    return false
end

---@param phaseContext SkillPhaseContext
---@param casterEntity Entity
function SkillViewConditionHelper:_CheckTrapOpenStateChange(casterEntity, phaseContext, conditionParam)
    local checkState =tonumber(conditionParam)
    ---@type RenderAttributesComponent
    local renderAttrCmpt =casterEntity:RenderAttributes()
    if renderAttrCmpt:GetAttribute("OpenState")  and renderAttrCmpt:GetAttribute("OpenState")==checkState then
        return true
    end
    return false
end

---@param phaseContext SkillPhaseContext
---@param casterEntity Entity
function SkillViewConditionHelper:_CheckCasterIsDead(casterEntity, phaseContext, conditionParam)
    ----@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    return  utilDataSvc:IsEntityLogicDead(casterEntity)
end

function SkillViewConditionHelper:_CheckHasRotate(casterEntity, phaseContext, conditionParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    ---@type SkillRotateEffectResult
    local skillRotateEffectResult = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Rotate)

    if skillRotateEffectResult and table.count(skillRotateEffectResult) > 0 then
        return true
    end

    return false
end

---@param phaseContext SkillPhaseContext
function SkillViewConditionHelper:_CheckCurrentRoundCount(casterEntity, phaseContext, conditionParam)
    ---解析配置
    assert(type(conditionParam) == "string", "Jump: _CheckCurrentRoundCount需要配置参数")
    local splitParam = string.split(conditionParam, "|")
    local roundList = {}
    for _, value in ipairs(splitParam) do
        roundList[#roundList + 1] = tonumber(value)
    end

    ---获取当前回合数
    local curRoundCount = BattleStatHelper.GetLevelTotalRoundCount()

    ---配置包含当前回合，则返回true
    if table.icontains(roundList, curRoundCount) then
        return true
    end
    
    return false
end
