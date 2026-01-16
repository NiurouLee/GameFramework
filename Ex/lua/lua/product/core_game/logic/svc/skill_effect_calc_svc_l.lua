--[[------------------
    技能效果计算逻辑的公共服务对象
--]] ------------------

_class("SkillEffectCalcService", BaseService)
---@class SkillEffectCalcService:Object
SkillEffectCalcService = SkillEffectCalcService

function SkillEffectCalcService:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---技能效果计算器
    self:RegistSkillEffectCalculator()
end

function SkillEffectCalcService:Initialize()
    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type MathService
    self._mathService = self._world:GetService("Math")

    ---@type CalcDamageService
    self._calcDamageService = self._world:GetService("CalcDamage")
end

---对目标计算技能的效果（普攻）
---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcService:CalcSkillEffect_All(skillEffectCalcParam)
    ---@type ConfigDecorationService
    local svcCfgDeco = self._world:GetService("ConfigDecoration")
    local skillEffectArray =
    svcCfgDeco:GetLatestEffectParamArray(skillEffectCalcParam.casterEntityID, skillEffectCalcParam.skillID)
    local skillEffectResult = {}
    for skillEffectIndex = 1, #skillEffectArray do
        skillEffectCalcParam.skillEffectParam = skillEffectArray[skillEffectIndex]

        --为加血的普攻替换技能范围和技能目标
        self:_ChangeSkillTargetAndScopeForAddBlood(skillEffectCalcParam)
        local skillResult = self:CalcSkillEffectByType(skillEffectCalcParam)
        if skillResult ~= nil then
            if skillResult._className ~= nil then
                skillEffectResult[#skillEffectResult + 1] = skillResult
            else
                for _, v in ipairs(skillResult) do
                    skillEffectResult[#skillEffectResult + 1] = v
                end
            end
        end
    end
    --计算完整个技能过程后重置SkillContext
    self:ResetSkillContext(skillEffectCalcParam.casterEntityID)
    return skillEffectResult
end

function SkillEffectCalcService:_ChangeSkillTargetAndScopeForAddBlood(skillEffectCalcParam)
    if skillEffectCalcParam.skillEffectParam:GetEffectType() ~= SkillEffectType.AddBlood then
        return
    end

    --取施法者的队伍
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    skillEffectCalcParam:SetGridPos(teamPos)
    skillEffectCalcParam:SetTargetEntityIDs({ teamEntity:GetID() })
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcService:CalcSkillEffectByType(skillEffectCalcParam)
    local effectType = skillEffectCalcParam.skillEffectParam:GetEffectType()
    local classType = self._skillEffectCalculatorDic[effectType]

    if (classType == nil) then
        Log.exception("SkillEffectCalcService cant find effectype ", effectType)
    end
    local skillID = skillEffectCalcParam:GetSkillID()
    self:LogNotice(
        "CalcSkillEffectByType() ",
        effectType,
        GetEnumKey("SkillEffectType", effectType),
        " skillID:",
        skillID
    )
    ---创建对象
    local effectDataObj = classType:New(self._world)
    if effectDataObj then
        return effectDataObj:DoSkillEffectCalculator(skillEffectCalcParam)
    end
end

---计算一次在攻击发生位置的伤害数据
---@param attacker Entity
---@param defender Entity
---@param damageParam SkillDamageEffectParam
function SkillEffectCalcService:ComputeSkillDamage(
    attacker,
    attackPos,
    defender,
    damagePos,
    skillID,
    damageParam,
    effectType,
    damageStageIndex,
    ignoreShield,
	curSkillDamageIndex,
    damageGridPos
)
    local percentList = damageParam:GetDamagePercent()
    local damageFormulaID = damageParam:GetDamageFormulaID()

    damageParam.attackPos = attackPos
    damageParam.damagePos = damagePos
    damageParam.formulaID = damageFormulaID
    damageParam.skillID = skillID
    damageParam.skillEffectType = effectType

    local totalDamage = 0
    local multiDamageInfo = {}
    --伤害分段和多次改成用buff实现
    for _, percent in ipairs(percentList) do
        damageParam.percent = percent
        self:NotifyDamageBegin(attacker, defender, attackPos, damagePos, skillID, effectType, damageStageIndex)
        ---@type DamageInfo
        local damageInfo = self._calcDamageService:DoCalcDamage(attacker, defender, damageParam, ignoreShield, damageGridPos)
        damageInfo:SetDamageStageIndex(damageStageIndex)
        damageInfo:SetCurSkillDamageIndex(curSkillDamageIndex)
        totalDamage = totalDamage + damageInfo:GetDamageValue()
        table.insert(multiDamageInfo, damageInfo)
        self:NotifyDamageEnd(
            attacker,
            defender,
            attackPos,
            damagePos,
            skillID,
            damageInfo,
            effectType,
            damageStageIndex
        )
    end

    return totalDamage, multiDamageInfo
end

---@private
---@return SkillDamageEffectResult
---统一实例化SkillDamageEffectResult，用于设置是否需要马上销毁目标
function SkillEffectCalcService:NewSkillDamageEffectResult(gridPos, targetid, damage, damageArray, damageStageIndex)
    local skillResult = SkillDamageEffectResult:New(gridPos, targetid, damage, damageArray, damageStageIndex)
    return skillResult
end

---计算出击退的位置
---击退流程比较复杂，可以抽出去
---@param attackerPos Vector2 施法位置
---@param attackerDir Vector2 施法方向
---@param attackerBodyArea BodyAreaComponent 施法者的bodyarea
---@param beAttackEntityID number 受击者
---@param dirType HitBackDirectionType 被击方向
---@param pullType 是击退还是拉近
---@param distance number 击退距离
---@param calcType 击退结算时机
---@param ignorePlayerBlock 忽略玩家阻挡
---@param excludeCasterPos 略
---@param casterEntity Entity  施法者
---@param skillRange Vector2[] 击退效果的技能范围，连锁机击退的时候没有这个参数
---@return SkillHitBackEffectResult
function SkillEffectCalcService:CalcHitbackEffectResult(
    attackerPos,
    attackerDir,
    attackerBodyArea,
    targetID,
    dirType,
    pullType,
    distance,
    calcType,
    ignorePlayerBlock,
    excludeCasterPos,
    casterEntity,
    skillRange,
    notCalcBomb,
    ignorePathBlock,
    backupDirectionPlan,
    interactType,
    skillType,
    extraBlockPos)
    ---@type Entity
    local defender = self._world:GetEntityByID(targetID)
    if not defender then
        return nil --没有被击者，当然就不会有击退效果
    end

    ---只有炸弹机关才会被击退【TODO应该用阻挡击退判断】
    if defender:HasTrap() then
        ---@type TrapComponent
        local trapCmp = defender:Trap()
        if TrapType.BombByHitBack ~= trapCmp:GetTrapType() then
            return
        end
    end
    local defenderPos = defender:GetGridPosition()
    local defenderBodyArea = defender:BodyArea()

    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    --buff判定
    if not buffLogicSvc:CheckCanBeHitBack(defender) then
        return SkillHitBackEffectResult:New(targetID, defenderPos, defenderPos)
    end
    ---Log.fatal("CalcBegin Distance:",distance)
    --击退方向
    local dir
    dir, distance =
    self:CalHitbackDir(
        attackerPos,
        attackerDir,
        attackerBodyArea,
        targetID,
        dirType,
        pullType,
        distance,
        casterEntity,
        skillRange,
        backupDirectionPlan
    )
    ---Log.fatal("CalcEnd Distance:",distance," Dir :", tostring(dir))
    local excludePosList = {}
    if excludeCasterPos then
        local casterBodyArea = attackerBodyArea:GetArea()
        if casterBodyArea and attackerPos then
            for i = 1, #casterBodyArea do
                excludePosList[#excludePosList + 1] = casterBodyArea[i] + attackerPos
            end
        end
    end

    --击退坐标
    local targetPos, isBlocked, blockMonsterID = self:CalHitbackPosByEntityDir(
        defenderPos,
        defenderBodyArea,
        dir,
        distance,
        excludePosList,
        ignorePlayerBlock,
        defender,
        ignorePathBlock,
        interactType,
        extraBlockPos
    )

    --击退结果
    ---@type SkillHitBackEffectResult
    local hitbackResult = self:CalcHitbackEffectResultProcess(
        targetID,
        calcType,
        casterEntity,
        dir,
        targetPos,
        SkillEffectType.HitBack,
        notCalcBomb,
        isBlocked,
        blockMonsterID,skillType
    )

    return hitbackResult
end

---计算出击退的位置
---击退流程比较复杂，可以抽出去
---@param targetID 受击者
---@param calcType 击退结算时机
---@param casterEntity 施法者
---@param dir Vector2 施法方向
---@param targetPos Vector2 击退坐标
---@param skillType SkillType
---@return SkillHitBackEffectResult
function SkillEffectCalcService:CalcHitbackEffectResultProcess(
    targetID,
    calcType,
    casterEntity,
    dir,
    targetPos,
    convertSource,
    notCalcBomb,
    isBlocked,
    blockMonsterID,skillType)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ----@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    ---@type Entity
    local defender = self._world:GetEntityByID(targetID)
    local defenderPos = defender:GetGridPosition()

    local boardEntity = self._world:GetBoardEntity()

    --移除阻挡
    local bodyArea, blockFlag = boardServiceLogic:RemoveEntityBlockFlag(defender, defenderPos)

    --老位置转色
    local tConvertInfo = {}
    local pieceChangeTable = self:_CalcHitbackPieceChangeTable(defenderPos, targetPos, defender)
    if pieceChangeTable ~= nil then
        for pos, pieceType in pairs(pieceChangeTable) do
            boardServiceLogic:SetPieceTypeLogic(pieceType, pos)
            local convertInfo = NTGridConvert_ConvertInfo:New(pos, PieceType.None, pieceType)
            table.insert(tConvertInfo, convertInfo)
        end
    end
    ---@type NTGridConvert
    local ntGridConvert = NTGridConvert:New(boardEntity, tConvertInfo)
    ntGridConvert:SetConvertEffectType(convertSource)
    ntGridConvert:SetSkillType(skillType)
    self._world:GetService("Trigger"):Notify(ntGridConvert)

    --位移到新位置
    defender:SetGridPosition(targetPos)
    Log.fatal("HitBackData Defender:", defender:GetID(), " NewPos:", targetPos)
    if defender:HasTeam() then
        local pets = defender:Team():GetTeamPetEntities()
        ---@param petEntity Entity
        for i, petEntity in ipairs(pets) do
            petEntity:SetGridPosition(targetPos)
            petEntity:GridLocation():SetMoveLastPosition(targetPos)
        end
    end

    --触发机关
    local trapIds = {}
    if targetPos ~= defenderPos then
        local triggerTraps = trapServiceLogic:TriggerTrapByEntity(defender, TrapTriggerOrigin.Hitback)
        for i, e in ipairs(triggerTraps) do
            trapIds[#trapIds + 1] = e:GetID()
        end
    end

    --新位置转色
    local colorNew = utilData:FindPieceElement(targetPos)
    if defender:HasTeam() and boardServiceLogic:GetCanConvertGridElement(targetPos) then
        colorNew = PieceType.None
    end
    boardServiceLogic:SetPieceTypeLogic(colorNew, defender:GetGridPosition())

    --修改阻挡信息
    boardServiceLogic:SetEntityBlockFlag(defender, targetPos, blockFlag)

    --炸弹爆炸
    local bombPos = targetPos
    if defender:HasTeam() or defender:HasMonsterID() then
        ---击退玩家或者怪物是触发下一格的炸弹
        bombPos = targetPos + dir
    end
    local trapEntity
    --击退后是否计算炸弹。因为很多击退计算不传这个参数，所以这里默认值是nil
    if notCalcBomb == nil then
        trapEntity = trapServiceLogic:TriggerBomb(bombPos, defender)
    end

    if trapEntity then
        ---@type TrapComponent
        local trapCmpt = trapEntity:Trap()
        trapEntity:Attributes():Modify("HP", 0)
        trapServiceLogic:AddTrapDeadMark(trapEntity)

        local notifyTrapAction = NTTrapAction:New(nil, defenderPos)
        triggerService:Notify(notifyTrapAction)
    end

    --击退完成通知
    local sTrigger = self._world:GetService("Trigger")
    sTrigger:Notify(NTHitBackEnd:New(casterEntity, defender, defenderPos, targetPos))

    local hitbackResult =
    SkillHitBackEffectResult:New(targetID, defenderPos, targetPos, pieceChangeTable, calcType, dir, colorNew)
    hitbackResult:SetTriggerTrapIds(trapIds)
    if trapEntity then
        hitbackResult:SetBombTrapEntityID(trapEntity:GetID())
    end

    --击退是否被阻挡
    if isBlocked ~= nil then
        hitbackResult:SetIsBlocked(isBlocked)
    end
    --阻挡击退的怪物ID
    if blockMonsterID then
        hitbackResult:SetBlockMonsterID(blockMonsterID)
    end

    return hitbackResult
end

---计算出击退的方向
---@param attackerPos Vector2 施法位置
---@param attackerDir Vector2 施法方向
---@param attackerBodyArea BodyAreaComponent 施法者的bodyarea
---@param targetID number 受击者
---@param dirType HitBackDirectionType 被击方向
---@param pullType HitBackType 是击退还是拉近
---@param distance number 击退距离
---@param casterEntity Entity  施法者
---@param skillRange Vector2[]
---@return Vector2,number
function SkillEffectCalcService:CalHitbackDir(
    attackerPos,
    attackerDir,
    attackerBodyArea,
    targetID,
    dirType,
    pullType,
    distance,
    casterEntity,
    skillRange,
    backupDirectionPlan)
    ---@type Entity
    local defender = self._world:GetEntityByID(targetID)
    local defenderPos = defender:GetGridPosition()
    local defenderBodyArea = defender:BodyArea()

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    --击退方向
    local dir = nil
    if dirType == HitBackDirectionType.Cross then
        dir = GameHelper.ComputeLogicDir(attackerDir)
    elseif dirType == HitBackDirectionType.SelectCanUseDir then
        dir, distance = utilCalcSvc:_CalCanUseHitBackDir(defender, distance)
    elseif dirType == HitBackDirectionType.SelectSquareRingFarest then
        dir = utilCalcSvc:_CalSelectSquareRingFarest(defender, casterEntity)
    elseif dirType == HitBackDirectionType.SelectCanUse8Dir then
        local tmpDir = GameHelper.ComputeLogicDir(attackerDir)
        dir, distance = utilCalcSvc:_CalCanUseHitBackDir8(tmpDir, defender, distance)
    elseif dirType == HitBackDirectionType.SelectNearestOutOfRange then
        dir, distance = utilCalcSvc:_CalcNearestPosOutOfRange(skillRange, defender)
    elseif dirType == HitBackDirectionType.SelectCanUseDirAndDis then
        dir, distance = utilCalcSvc:CalSelectCanUseDirAndDis(attackerDir, defender, distance)
    elseif dirType == HitBackDirectionType.CoffinMusume then
        dir, distance = utilCalcSvc:CalCoffinMusumeHitbackDirAndDis(attackerPos, attackerDir, defender, distance,
            casterEntity)
    elseif dirType == HitBackDirectionType.CasterDir2Edge then
        dir = attackerDir
    elseif dirType == HitBackDirectionType.Front3Dir then
        dir = utilCalcSvc:CalcHitBackFront3Dir(attackerPos, attackerDir, defender, distance, casterEntity)
    elseif dirType == HitBackDirectionType.AttackFront2Edge then
        dir = utilCalcSvc:CalcHitBackAttackFront2Edge(attackerPos, attackerBodyArea, defenderPos)
    elseif dirType == HitBackDirectionType.EightDirAndCasterAround then
        dir, distance = utilCalcSvc:CalEightDirAndCasterAround(casterEntity, defender, distance)
    elseif dirType == HitBackDirectionType.Butterfly then
        dir, distance = utilCalcSvc:CalButterflyHitBackDirAndDistance(casterEntity, defender)
    else
        dir = utilCalcSvc:_CalcHitBackDir(dirType, attackerPos, defenderPos, attackerBodyArea, defenderBodyArea)
    end
    if dir == nil or dir == Vector2.zero then
        -- 如果没有选到方向，又提供了plan b，可以继续击退计算
        if backupDirectionPlan then
            if backupDirectionPlan == HitBackDirectionBackupPlan.AlwaysUp then
                dir = Vector2.up
            end
        else
            Log.fatal("击退方向计算结果错误！")
            return Vector2.zero, 0
        end
    end

    if pullType == HitBackType.PullBack then
        dir = -dir
    end
    ---Log.fatal("Calc Distance:",distance,"Dir:", tostring(dir))

    return dir, distance
end

---只进行击退位置计算，不涉及状态修改的部分
---@param pos Vector2 受击者的位置
---@param bodyArea BodyAreaComponent 受击者的BodyArea
---@param dir Vector2 击退方向
---@param distance number 击退距离
---@param exceptPosList Vector2[] 例外位置数组（其中的位置不会阻挡击退）
---@param entity Entity
---@param ignorePathBlock 忽略路径上的击退阻挡
---@return Vector2, boolean, number 击退位置, 是否被阻挡(版边或机关怪物), 阻挡击退的怪物ID
function SkillEffectCalcService:CalHitbackPosByEntityDir(
    pos,
    bodyArea,
    dir,
    distance,
    exceptPosList,
    ignorePlayerBlock,
    entity,
    ignorePathBlock,
    interactType,
    extraBlockPos)
    extraBlockPos = extraBlockPos or {}

    local targetPos = pos:Clone()
    local isBlocked = false
    local blockMonsterID = nil
    local defenderBodyArea = bodyArea
    local exceptPosList = exceptPosList or {}
    local bodyArea = defenderBodyArea:GetArea()
    for i = 1, #bodyArea do
        exceptPosList[#exceptPosList + 1] = pos + bodyArea[i]
    end
    local useCheckBlockFlag = BlockFlag.HitBack
    if entity:HasMonsterID() then
        local raceType = entity:MonsterID():GetMonsterRaceType()
        if MonsterRaceType.Fly == raceType then
            useCheckBlockFlag = BlockFlag.HitBackFly --MSG57290 深渊不阻挡击退飞行怪
        end
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ----@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    for i = 1, distance do
        local tempPos = targetPos + dir

        ---needBreak 用于确保撞墙的触发
        local needBreak = false
        for i = 1, #bodyArea do
            local tempBodyPos = tempPos + bodyArea[i]
            if table.Vector2Include(extraBlockPos, tempBodyPos) then
                needBreak = true
                break
            else
                if not table.icontains(exceptPosList, tempBodyPos) then
                    if not utilDataSvc:IsValidPiecePos(tempBodyPos) then --到板边或GapTile边上
                        --可以击退出板边
                        if interactType == HitBackInteractnWithBoardType.OutBoardEdge then
                            targetPos = tempPos
                        end
                        needBreak = true
                        break
                    end

                    if not ignorePathBlock then
                        if utilDataSvc:IsPosBlock(tempBodyPos, useCheckBlockFlag) or
                                utilDataSvc:IsPosBlockWithEntityRace(tempBodyPos, useCheckBlockFlag, entity)
                        then
                            local isHasMonster, monsterID = utilScopeSvc:IsPosHasMonster(tempBodyPos)
                            if isHasMonster then
                                blockMonsterID = monsterID
                            end
                            needBreak = true
                            break
                        end
                    end
                end
            end
        end
        if needBreak then
            isBlocked = true
            break
        end
        targetPos = tempPos
    end
    ---判断是否是炸弹，炸弹被击退的位置要求后移一位
    ---@type TrapComponent
    local cmptTrap = entity:Trap()
    if cmptTrap and TrapType.BombByHitBack == cmptTrap:GetTrapType() then
        local posNext = targetPos + dir
        if utilDataSvc:IsHaveEntity(posNext, EnumTargetEntity.Pet | EnumTargetEntity.Monster) then
            targetPos = posNext
        end
    end

    return targetPos, isBlocked, blockMonsterID
end

---@param defender Entity
function SkillEffectCalcService:_CalcHitbackPieceChangeTable(pos, targetPos, defender)
    local pieceChangeTable = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    if pos ~= targetPos then
        local curPieceType = utilData:FindPieceElement(pos)
        if curPieceType == PieceType.None and defender:HasTeam() and pos == defender:GetGridPosition() then
            local supplyRes = boardServiceLogic:SupplyPieceList({ pos })
            for i = 1, #supplyRes do
                local res = supplyRes[i]
                pieceChangeTable[Vector2(res.x, res.y)] = res.color
            end
        end
    end

    return pieceChangeTable
end

---@return SkillConvertGridElementEffectResult
function SkillEffectCalcService:_DoCalcSkillConvertGridElementEffect(skillEffectParam, skillRangePos, casterEntity)
    ---@type SkillConvertGridElementEffectParam
    local skillConvertEffectParam = skillEffectParam
    local sourceArray = skillConvertEffectParam:GetSourceGridElement()
    local targetElementType = skillConvertEffectParam:GetTargetGridElement()

    local useEntityElement = false
    local elementEntity = nil
    if skillConvertEffectParam:IsConvertToCasterElement() then
        useEntityElement = true
        elementEntity = casterEntity
    elseif skillConvertEffectParam:IsConvertToTeamLeaderElement() then
        useEntityElement = true
        local teamEntity = nil
        if casterEntity:HasPet() then
            ---@type Entity
            teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        elseif casterEntity:HasTeam() then
            teamEntity = casterEntity
        else
            teamEntity = self._world:Player():GetLocalTeamEntity()
        end
        elementEntity = teamEntity:GetTeamLeaderPetEntity()
    end
    if useEntityElement then
        if elementEntity then
            if elementEntity:Element() ~= nil and elementEntity:Element():GetPrimaryType() ~= nil then
                local tarElement = elementEntity:Element():GetPrimaryType()
                targetElementType = tarElement
                local newSource = {}
                for _, elementType in ipairs(sourceArray) do
                    if targetElementType ~= elementType then
                        table.insert(newSource, elementType)
                    end
                end
                sourceArray = newSource
            end
        end
    end
    local targetMaxCount = skillConvertEffectParam:GetTargetGridElementCount()
    local forceConvert = skillConvertEffectParam:IsIgnoreBlock()
    local legendPowerCount = skillConvertEffectParam:GetLegendPowerCount()
    local targetGridDic = {}
    local hasEnoughTarget = false
    local currentTargetCount = 0
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")

    --有一些格子 不可以转色
    local skillRangePosList = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    for k, v in pairs(skillRangePos) do
        local canConverPos = boardServiceLogic:GetCanConvertGridElement(v)
        if canConverPos then
            table.insert(skillRangePosList, v)
        end
    end
    if legendPowerCount ~= 0 then
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        local skillID = battleStatCmpt:GetLastActiveSkillID()
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
        local costPower = skillConfigData:GetSkillTriggerParam()
        local count = math.floor(costPower / legendPowerCount)
        targetMaxCount = count
    end
    ---后续需要在这里判断技能的范围类型，不同类型，选取的范围结果不同，现在默认写的是方环
    if skillConvertEffectParam:NeedRandom() then
        ---@type Vector2[]
        local cloneTargetGridList = {}
        for k, v in pairs(skillRangePosList) do
            local lv = v:Clone()
            table.insert(cloneTargetGridList, lv)
        end
        while currentTargetCount < targetMaxCount and #cloneTargetGridList ~= 0 do
            local randIndex = randomSvc:LogicRand(1, #cloneTargetGridList)
            local gridPos = cloneTargetGridList[randIndex]
            table.remove(cloneTargetGridList, randIndex)
            local isMatch = self:_IsGridElementMatch(gridPos, sourceArray)
            if isMatch then
                currentTargetCount = currentTargetCount + 1
                targetGridDic[#targetGridDic + 1] = Vector2(gridPos.x, gridPos.y)
            end
            if currentTargetCount >= targetMaxCount or #cloneTargetGridList == 0 then
                hasEnoughTarget = true
                break
            end
        end
    else
        for _, gridPos in ipairs(skillRangePosList) do
            local isMatch = self:_IsGridElementMatch(gridPos, sourceArray)
            if isMatch then
                targetGridDic[#targetGridDic + 1] = Vector2(gridPos.x, gridPos.y)
                currentTargetCount = currentTargetCount + 1
                if currentTargetCount >= targetMaxCount then
                    hasEnoughTarget = true
                    break
                end
            end
        end
    end
    local skillConvertEffectResult = SkillConvertGridElementEffectResult:New(targetGridDic, targetElementType)
    return skillConvertEffectResult
end

function SkillEffectCalcService:_IsGridElementMatch(checkPos, convertGridTypeArray)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local checkPosType = utilData:FindPieceElement(checkPos)
    for k, v in ipairs(convertGridTypeArray) do
        local curGridType = tonumber(v)
        if curGridType == checkPosType then
            return true
        end
    end

    return false
end

--------------------------------
function SkillEffectCalcService:_TransBlockByRaceType(nRaceType)
    if MonsterRaceType.Fly == nRaceType then
        return BlockFlag.MonsterFly
    end
    return BlockFlag.MonsterLand
end

---这里需要根据召唤目标物来确定可召唤的目标位置： 飞行怪和陆行怪的可达地形不一样
---@param listPosPlan Vector2[]  召唤预期坐标
function SkillEffectCalcService:_FindSummonPos(
    nSummonType,
    listPosPlan,
    nSummonID,
    listPosHaveDown,
    blockFlag,
    searchRing9,
    bCheckIgnoreBodyArea,
    noRandom
)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local bodyArea = nil
    if SkillEffectEnum_SummonType.Monster == nSummonType then
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        if bCheckIgnoreBodyArea then
            bodyArea = {Vector2(0,0)}
        else
            bodyArea = monsterConfigData:GetMonsterArea(nSummonID)
        end
        local raceType = monsterConfigData:GetMonsterRaceType(nSummonID)
        blockFlag = blockFlag or self:_TransBlockByRaceType(raceType)
    elseif SkillEffectEnum_SummonType.Trap == nSummonType then
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type TrapConfigData
        local configTrap = cfgService:GetTrapConfigData()
        local configData = configTrap:GetTrapData(nSummonID)
        if bCheckIgnoreBodyArea then
            bodyArea = {Vector2(0,0)}
        else
            bodyArea = configTrap:ExplainTrapArea(configData.Area)
        end
        blockFlag = blockFlag or BlockFlag.SummonTrap
    end
    if nil == bodyArea then
        return nil
    end
    ---@type Vector2
    local position = boardServiceLogic:GetValidSummonPos(listPosPlan, bodyArea, listPosHaveDown, blockFlag, searchRing9,
        noRandom)
    return position
end

----------------------------------------------------------------

---@param skillEffectParam SkillEffectParam_ResetGridElement
function SkillEffectCalcService:CalcSkill_ResetGridElement(skillRangePos, casterEntity, skillEffectParam, isPreviewing)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    ---@type TrapServiceLogic
    local svcTrap = self._world:GetService("TrapLogic")

    local elementPool = {} --元素池，随机的元素从池里取，如果池里的某元素占比高于25%，则说明其随机出来的概率就更高
    local targetGridTypeList = {}
    for i, v in ipairs(skillEffectParam:GetTargetGridTypeList()) do
        targetGridTypeList[i] = v
    end
    if skillEffectParam:GetExcludeRangeColor() then
        ---@type PieceType
        local pieceType = boardServiceLogic:GetPieceType(skillRangePos[1])
        for k, v in pairs(targetGridTypeList) do
            if v == pieceType then
                table.remove(targetGridTypeList, k)
                table.sort(targetGridTypeList)
                break
            end
        end
    end
    if not isPreviewing then
        local tmpList = {}
        local count = #targetGridTypeList
        for i = 1, count do
            --local index = randomSvc:LogicRand(1, #targetGridTypeList)
            local index = randomSvc:BoardLogicRandSelectByMatchType(1, #targetGridTypeList)
            table.insert(tmpList, targetGridTypeList[index])
            table.remove(targetGridTypeList, index)
        end
        targetGridTypeList = tmpList
    end
    local convertGray = skillEffectParam:GetConvertGray() --是否可转灰色格子
    local canFlushTrap = skillEffectParam:GetCanFlushTrap() --是否可刷机关
    local protectElementTypeMap = skillEffectParam:GetProtectElementType()
    local ignoreBlock = skillEffectParam:GetIgnoreBlock() --是否无视转色阻挡
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    -- --真随机
    -- elementPool = self:_GetRandomElementPool(skillEffectParam)
    ---先查一下能洗板的格子数量再生成池子
    local validGridCount = 0
    for i = 1, #skillRangePos do
        local posWork = skillRangePos[i]
        local checkPosType = utilData:FindPieceElement(posWork)
        -- (not boardServiceLogic:IsPosBlock(posWork, BlockFlag.ChangeElement)) and
        if (convertGray or (checkPosType > PieceType.None and checkPosType <= PieceType.Any)) then
            if (not protectElementTypeMap[checkPosType]) then
                validGridCount = validGridCount + 1
            end
        end
    end
    --假随机
    elementPool = self:_GetAssignElementPool(validGridCount, skillEffectParam, targetGridTypeList)

    local lenPool = table.count(elementPool)

    local listGridArray = {}
    local listGridArrayNew = {}
    local flushTraps = {}
    -- MSG8904 与策划确认：刷版对宝宝脚下不生效的 2020/8/5
    -- if casterEntity:HasPetPstID() then --只有宝宝才会将脚下灰格子刷新
    --     local posCaster = casterEntity:GridLocation().Position --脚下位置
    --     local nNewColor = elementPool[self:_GetRandomNumber(1, lenPool, isPreviewing)] + PieceType.None ---格子颜色
    --     local resetGridData = SkillEffectResult_ResetGridData:New(posCaster.x, posCaster.y, nNewColor) ---格子颜色
    --     table.insert(listGridArray, resetGridData)
    -- end

    ---@type table<number,Entity>
    local traps = self._world:GetGroup(self._world.BW_WEMatchers.Trap):GetEntities()

    local excludeTrapIDList = skillEffectParam:GetExcludeTrapIDList()

    for i = 1, #skillRangePos do
        local posWork = skillRangePos[i]
        local checkPosType = utilData:FindPieceElement(posWork)
        -- 需求已确认：范围内所有格子都重置，保留火格子的位置信息
        -- 2021-7-16 修改：先洗版再转色，用于洗掉锁格子
        if canFlushTrap and #traps > 0 then
            for _, trap in ipairs(traps) do
                if not trap:HasDeadMark() then
                    local level = trap:Trap():GetTrapLevel()
                    local pos = trap:GetGridPosition()
                    local isFlushed = svcTrap:IsTrapFlushable(level)
                    local trapID = trap:Trap():GetTrapID()
                    if isFlushed and pos.x == posWork.x and pos.y == posWork.y and
                        not table.icontains(excludeTrapIDList, trapID)
                    then
                        trap:Attributes():Modify("HP", 0)
                        svcTrap:AddTrapDeadMark(trap, true)
                        flushTraps[#flushTraps + 1] = trap
                    end
                end
            end
        end

        --转色
        if (not boardServiceLogic:IsPosBlock(posWork, BlockFlag.ChangeElement) or ignoreBlock) and
            (convertGray or (checkPosType > PieceType.None and checkPosType <= PieceType.Any))
        then
            local nNewColor = checkPosType
            --假随机  池减少
            if (not protectElementTypeMap[checkPosType]) then
                nNewColor = self:_GetAssignNumber(elementPool, isPreviewing) + PieceType.None ---格子颜色
            end

            local resetGridData = SkillEffectResult_ResetGridData:New(posWork.x, posWork.y, nNewColor)
            table.insert(listGridArray, resetGridData)
            if not listGridArrayNew[posWork.x] then
                listGridArrayNew[posWork.x] = {}
            end
            if not listGridArrayNew[posWork.x][posWork.y] then
                listGridArrayNew[posWork.x][posWork.y] = {}
            end
            listGridArrayNew[posWork.x][posWork.y] = nNewColor
        end
    end

    local skillResult = SkillEffectResult_ResetGridElement:New(listGridArray, flushTraps, listGridArrayNew)
    return skillResult
end

---@param posList Vector2
---@return number[]
function SkillEffectCalcService:GetFlushTrap(posList, excludeTrapIDList)
    ---@type table<number,Entity>
    local traps = self._world:GetGroup(self._world.BW_WEMatchers.Trap):GetEntities()

    ---@type number[]
    local flushTrapList = {}
    ---@type TrapServiceLogic
    local svcTrap = self._world:GetService("TrapLogic")
    for _, trap in ipairs(traps) do
        local level = trap:Trap():GetTrapLevel()
        local pos = trap:GetGridPosition()
        local isFlushed = svcTrap:IsTrapFlushable(level)
        local trapID = trap:Trap():GetTrapID()
        if isFlushed and table.icontains(posList, pos) and not table.icontains(excludeTrapIDList, trapID) then
            flushTrapList[#flushTrapList + 1] = trap:GetID()
        end
    end
    return flushTrapList
end

---获得真随机的元素池
function SkillEffectCalcService:_GetRandomElementPool(skillEffectParam)
    local elementPool = {} --元素池，随机的元素从池里取，如果池里的某元素占比高于25%，则说明其随机出来的概率就更高
    local element = skillEffectParam:GetElement()
    if element then
        local percent = skillEffectParam:GetPercent()
        local count = 100
        for elementIdx = 1, 4 do
            local num = 0
            if element == elementIdx then
                num = math.floor(percent * count)
            else
                num = math.floor((1 - percent) * count / 3)
            end
            for j = 1, num do
                table.insert(elementPool, elementIdx)
            end
        end
    else --没有该参数说明四种元素的格子随机出来的概率一样
        elementPool = { 1, 2, 3, 4 }
    end

    return elementPool
end

---获得 指定数量 假随机的元素池
function SkillEffectCalcService:_GetAssignElementPool(count, skillEffectParam, elementList)
    local elementPool = {} --元素池，随机的元素从池里取，如果池里的某元素占比高于25%，则说明其随机出来的概率就更高
    local element = skillEffectParam:GetElement()
    local elementCount = #elementList
    if element then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local percentRange = skillEffectParam:GetPercent()
        local percent
        if #percentRange == 1 then
            percent = percentRange[1]
        elseif #percentRange == 2 then
            local sub = percentRange[2] - percentRange[1]
            local add = sub * randomSvc:BoardLogicRandSelectByMatchType(0, 10) / 10
            percent = percentRange[1] + add
        end
        local otherElementList = {}
        for _, elementIdx in ipairs(elementList) do
            local num = 0
            if element == elementIdx then
                num = math.floor(percent * count)
            else
                table.insert(otherElementList, elementIdx)
                num = math.floor((1 - percent) * count / (elementCount - 1))
            end
            for j = 1, num do
                table.insert(elementPool, elementIdx)
            end
        end
        while #elementPool < count do
            local randIndex = randomSvc:BoardLogicRandSelectByMatchType(1, #otherElementList)
            table.insert(elementPool, otherElementList[randIndex])
        end
        local logTabele = {}
        for i, v in ipairs(elementPool) do
            if not logTabele[v] then
                logTabele[v] = 0
            end
            logTabele[v] = logTabele[v] + 1
        end
        for type, count in pairs(logTabele) do
            self:LogNotice("ResetGrid PieceType:", type, " Count:", count)
        end
    else --没有该参数说明四种元素的格子随机出来的概率一样
        for elementIdx = 1, count do
            local mod = math.fmod(elementIdx, #elementList) -- 取余数
            table.insert(elementPool, elementList[mod + 1])
        end
    end

    return elementPool
end

-- 根据技能参数获得的元素池  逐个随机取出
function SkillEffectCalcService:_GetAssignNumber(elementPool, isPreviewing)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")

    local number
    local random
    local count = table.count(elementPool)
    if isPreviewing then
        random = math.random(1, count)
        number = elementPool[random]
    else
        random = randomSvc:BoardLogicRandSelectByMatchType(1, count)
        number = elementPool[random]
        table.remove(elementPool, random)
    end

    return number
end

function SkillEffectCalcService:NotifyDamageBegin(
    attacker,
    defender,
    attackPos,
    targetPos,
    skillID,
    effectType,
    damageStageIndex,
    randHalfDamageIndex)
    if not skillID then
        return
    end
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, attacker)
    local skillType = skillConfigData:GetSkillType()
    ---是宠物
    if attacker:HasPetPstID() then
        ---普攻的NTNormalEachAttackStart 在普攻计算器里NormalSkillCalculator通知

        if skillType == SkillType.Chain then
            ---@type SkillPetAttackDataComponent
            local petAttackDataCmpt = attacker:SkillPetAttackData()
            local chainSkillIndex = petAttackDataCmpt:GetCurChainSkillIndex()
            local nt = NTChainSkillEachAttackStart:New(attacker, defender, attackPos, targetPos)
            nt:SetEffectType(effectType)
            nt:SetSkillID(skillID)
            nt:SetSkillType(SkillType.Chain)
            nt:SetChainSkillIndex(chainSkillIndex)
            if randHalfDamageIndex then
                nt:SetRandHalfDamageIndex(randHalfDamageIndex)
            end
            triggerSvc:Notify(nt)
        end

        if skillType == SkillType.Active then
            local nt = NTActiveSkillEachAttackStart:New(attacker, defender, attackPos, targetPos)
            nt:SetEffectType(effectType)
            nt:SetSkillID(skillID)
            nt:SetSkillType(SkillType.Active)
            nt:SetSkillStageIndex(damageStageIndex)
            triggerSvc:Notify(nt)
        end
    elseif attacker:HasMonsterID() then
        local nt = NTMonsterEachAttackStart:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(SkillType.MonsterSkill)
        triggerSvc:Notify(nt)
    elseif attacker:HasTrap() then
        local nt = NTTrapEachAttackStart:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(SkillType.TrapSkill)
        triggerSvc:Notify(nt)
    elseif attacker:EntityType():IsSkillHolder() then
        ---@type NTBuffCastSkillEachAttackBegin
        local nt = NTBuffCastSkillEachAttackBegin:New(attacker, defender, attackPos, targetPos)
        nt:SetEffectType(effectType)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillType)
        triggerSvc:Notify(nt)
    end

    if defender:HasMonsterID() then
        local nt = NTMonsterBeHitStart:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillType)
        triggerSvc:Notify(nt)
    end
    if defender:HasPetPstID() or defender:HasTeam() then
        local nt = NTPlayerBeHitStart:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillType)
        triggerSvc:Notify(nt)
    end
end

---@param attacker Entity
function SkillEffectCalcService:NotifyDamageEnd(
    attacker,
    defender,
    attackPos,
    targetPos,
    skillID,
    damageInfo,
    effectType,
    damageStageIndex)
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    local battleSvc = self._world:GetService("Battle")
    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    local damage = damageInfo:GetDamageValue()
    local damageType = damageInfo:GetDamageType()

    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, attacker)
    local skillType = skillConfigData:GetSkillType()
    ---是宠物
    if attacker:HasPetPstID() then
        ---普攻的NTNormalEachAttackEnd 在普攻计算器里NormalSkillCalculator通知

        if skillType == SkillType.Chain then
            ---@type SkillPetAttackDataComponent
            local petAttackDataCmpt = attacker:SkillPetAttackData()
            local chainSkillIndex = petAttackDataCmpt:GetCurChainSkillIndex()

            local nt = NTChainSkillEachAttackEnd:New(attacker, defender, attackPos, targetPos)
            nt:SetEffectType(effectType)
            nt:SetSkillID(skillID)
            nt:SetSkillType(SkillType.Chain)
            nt:SetDamageValue(damage)
            nt:SetChainSkillIndex(chainSkillIndex)
            if damageInfo.GetRandHalfDamageIndex then
                local randHalfDamageIndex = damageInfo:GetRandHalfDamageIndex()
                if randHalfDamageIndex then
                    nt:SetRandHalfDamageIndex(randHalfDamageIndex)
                end
            end
            triggerSvc:Notify(nt)
        end

        if skillType == SkillType.Active then
            local nt = NTActiveSkillEachAttackEnd:New(attacker, defender, attackPos, targetPos)
            nt:SetSkillID(skillID)
            nt:SetSkillType(SkillType.Active)
            nt:SetEffectType(effectType)
            nt:SetDamageValue(damage)
            nt:SetDamageType(damageType)
            nt:SetSkillStageIndex(damageStageIndex)
            triggerSvc:Notify(nt)
        end
    elseif attacker:HasMonsterID() then
        if skillType == SkillType.Normal then
            local nt = NTMonsterEachAttackEnd:New(attacker, defender, attackPos, targetPos)
            nt:SetSkillID(skillID)
            nt:SetSkillType(SkillType.MonsterSkill)
            nt:SetDamageValue(damage)
            nt:SetDamageType(damageType)
            triggerSvc:Notify(nt)
        end

        local nt = NTMonsterEachDamageEnd:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(SkillType.MonsterSkill)
        nt:SetDamageValue(damage)
        nt:SetDamageType(damageType)
        triggerSvc:Notify(nt)
    elseif attacker:HasTrap() then
        local nt = NTTrapEachAttackEnd:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(SkillType.TrapSkill)
        nt:SetDamageValue(damage)
        nt:SetDamageType(damageType)
        triggerSvc:Notify(nt)
    elseif attacker:EntityType():IsSkillHolder() then
        ---@type NTBuffCastSkillEachAttackEnd
        local nt = NTBuffCastSkillEachAttackEnd:New(attacker, defender, attackPos, targetPos)
        nt:SetEffectType(effectType)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillType)
        nt:SetDamageValue(damage)
        nt:SetDamageType(damageType)
        triggerSvc:Notify(nt)
    end

    if defender:HasMonsterID() then
        local nt = NTMonsterBeHit:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillType)
        nt:SetDamageValue(damage)
        nt:SetDamageType(damageType)
        nt:SetDamageStageIndex(damageInfo:GetDamageStageIndex())
        nt:SetCurSkillDamageIndex(damageInfo:GetCurSkillDamageIndex())
        triggerSvc:Notify(nt)
    end
    if defender:HasPetPstID() or defender:HasTeam() then
        local nt = NTPlayerBeHit:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillType)
        nt:SetDamageValue(damage)
        nt:SetDamageType(damageType)
        nt:SetDamageIndex(damageStageIndex)
        triggerSvc:Notify(nt)
    end
    if defender:HasChessPet()then
        local nt = NTChessBeHit:New(attacker, defender, attackPos, targetPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillType)
        nt:SetDamageValue(damage)
        nt:SetDamageType(damageType)
        triggerSvc:Notify(nt)
    end
end

--endregion

function SkillEffectCalcService:ResetSkillContext(entityID)
    ---@type Entity
    local entity = self._world:GetEntityByID(entityID)
    if not entity:HasSkillContext() then
        Log.fatal("该Entity没有SkillContext组件，直接宕机")
    end
    entity:ReplaceSkillContext()
end

function SkillEffectCalcService:TriggerTrap(casterEntity, result)
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(casterEntity, TrapTriggerOrigin.Move)
    for i, e in ipairs(listTrapWork) do
        ---@type Entity
        local trapEntity = e
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)
        result:AddWalkTrap(trapEntity:GetID(), aiResult)
    end
end

----------------------------------------------------------------
