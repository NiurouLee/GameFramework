_class("SkillPreviewEffectCalcService", Object)
---@class SkillPreviewEffectCalcService:Object
SkillPreviewEffectCalcService = SkillPreviewEffectCalcService

function SkillPreviewEffectCalcService:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectParamParser
    self._skillEffectParamParser = SkillEffectParamParser:New()
end

function SkillPreviewEffectCalcService:Initialize()
    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type UtilDataServiceShare
    self._utilDataService = self._world:GetService("UtilData")
end

---@return SkillEffectCalcParam
function SkillPreviewEffectCalcService:_CreateSkillEffectCalcParam(casterID, targetIDArray, effectParam, range)
    local calcParam = SkillEffectCalcParam:New(casterID, targetIDArray, effectParam, 0, range)

    return calcParam
end

---@return SkillEffectParamBase
function SkillPreviewEffectCalcService:CreateSkillEffectParam(effectType, effectParam)
    local param = self._skillEffectParamParser:ParseSkillEffectParam(effectType, effectParam)
    return param
end

---@return SkillConvertGridElementEffectResult
function SkillPreviewEffectCalcService:CalcConvertGridElement(casterEntity, scopeGridList, param)
    ---@type SkillConvertGridElementEffectParam
    local skillConvertEffectParam = param
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
    local ignoreBlock = skillConvertEffectParam:IsIgnoreBlock()
    local targetGridDic = {}

    local hasEnoughTarget = false
    local currentTargetCount = 0
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    --有一些格子 不可以转色
    local skillRangePosList = {}
    local blockedPieces = {}
    for k, v in pairs(scopeGridList) do
        local cantConverPos = env:IsPosBlock(v, BlockFlag.ChangeElement)
        if ignoreBlock then
            cantConverPos = false
        end
        if cantConverPos then
            table.insert(blockedPieces, v)
        else
            table.insert(skillRangePosList, v)
        end
    end
    for _, gridPos in ipairs(skillRangePosList) do
        local isMatch = self:IsPreviewGridElementMatch(gridPos, sourceArray)
        if isMatch then
            targetGridDic[#targetGridDic + 1] = Vector2(gridPos.x, gridPos.y)
            currentTargetCount = currentTargetCount + 1
            if currentTargetCount >= targetMaxCount then
                hasEnoughTarget = true
                break
            end
        end
    end
    local skillConvertEffectResult =
        SkillConvertGridElementEffectResult:New(targetGridDic, targetElementType, blockedPieces)
    return skillConvertEffectResult
end

---@return SkillHitBackEffectResult
---@param param SkillHitBackEffectParam
---@param skillPreviewContext SkillPreviewContext
function SkillPreviewEffectCalcService:CalcHitBack(casterEntity, scopeGridList, targetID, skillPreviewContext, param)
    local attackerPos = skillPreviewContext:GetCasterPos()
    local attackerDir = skillPreviewContext:GetCasterDir()
    local attackerBodyArea = skillPreviewContext:GetCasterBodyArea()
    local hitBackDirType = skillPreviewContext:GetHitBackDirType()
    local ignorePlayerBlock = param:GetIgnorePlayerBlock() --skillPreviewContext:IsIgnorePlayerBlock()
    if not hitBackDirType then
        hitBackDirType = param:GetDirType()
    end

    local type = param:GetType()
    local hitBackDistance = param:GetDistance()
    local calcType = param:GetCalcType()
    local excludeCasterPos = param:ExcludeCasterPos()
    local backupDirectionPlan = param:GetBackupDirectionPlan()

    ---@type SkillHitBackEffectParam
    local enableByPickNum = param:GetEnableByPickNum()
    if enableByPickNum then
        local checkNum = tonumber(enableByPickNum)
        ---@type Entity
        local attacker = casterEntity
        ---@type PreviewPickUpComponent
        local component = attacker:PreviewPickUpComponent()
        if component then
            local curPickNum = component:GetAllValidPickUpGridPosCount()
            if curPickNum ~= checkNum then
                return
            end
        end
    end

    ---@type Entity
    local defender = self._world:GetEntityByID(targetID)
    if not defender then
        return nil --没有被击者，当然就不会有击退效果
    end
    if defender:HasTrapID() then
        ---@type TrapRenderComponent
        local trapRenderCmpt = defender:TrapRender()
        if TrapType.BombByHitBack ~= trapRenderCmpt:GetTrapType() then
            return
        end
    end
    local defenderPos = defender:GetGridPosition()
    local defenderBodyArea = defender:BodyArea()

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    --buff判定
    if env:IsImmuneHitback(defender) then
        return SkillHitBackEffectResult:New(targetID, defenderPos, defenderPos)
    end
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local dir = nil
    if hitBackDirType == HitBackDirectionType.Cross then
        dir = GameHelper.ComputeLogicDir(attackerDir)
    elseif hitBackDirType == HitBackDirectionType.SelectCanUseDir then
        dir, hitBackDistance = utilCalcSvc:_CalCanUseHitBackDir(defender, hitBackDistance)
    else
        dir = utilCalcSvc:_CalcHitBackDir(hitBackDirType, attackerPos, defenderPos, attackerBodyArea, defenderBodyArea)
    end
    if dir == nil or dir == Vector2.zero then
        -- 如果没有选到方向，又提供了plan b，可以继续击退计算
        if backupDirectionPlan then
            if backupDirectionPlan == HitBackDirectionBackupPlan.AlwaysUp then
                dir = Vector2.up
            end
        else
            Log.fatal("击退方向计算结果错误！")
            return SkillHitBackEffectResult:New(targetID, defenderPos, defenderPos)
        end
    end

    if type == HitBackType.PullBack then
        dir = -dir
    end

    local excludePosList = {}
    if excludeCasterPos then
        local casterBodyArea = attackerBodyArea:GetArea()
        if casterBodyArea and attackerPos then
            for i = 1, #casterBodyArea do
                excludePosList[#excludePosList + 1] = casterBodyArea[i] + attackerPos
            end
        end
    end

    local targetPos = defenderPos:Clone()
    local bodyArea = defenderBodyArea:GetArea()
    for i = 1, #bodyArea do
        excludePosList[#excludePosList + 1] = defenderPos + bodyArea[i]
    end
    local useCheckBlockFlag = BlockFlag.HitBack
    if defender:HasMonsterID() then
        local raceType = defender:MonsterID():GetMonsterRaceType()
        if MonsterRaceType.Fly == raceType then
            useCheckBlockFlag = BlockFlag.HitBackFly --MSG57290 深渊不阻挡击退飞行怪
        end
    end

    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    for i = 1, hitBackDistance do
        local tempPos = targetPos + dir
        ---确保撞墙的触发
        local needBreak = false
        for i = 1, #bodyArea do
            local tempBodyPos = tempPos + bodyArea[i]
            if not table.icontains(excludePosList, tempBodyPos) then
                if not utilData:IsValidPiecePos(tempBodyPos) then --到板边或GapTile边上
                    needBreak = true
                    break
                end
                if
                    env:IsPosBlock(tempBodyPos, useCheckBlockFlag) or
                        utilData:IsPosBlockWithEntityRace(tempBodyPos, useCheckBlockFlag, defender)
                 then
                    needBreak = true
                    break
                end
            end
        end
        if needBreak then
            break
        end
        targetPos = tempPos
    end

    ---判断是否是炸弹，炸弹被击退的位置要求后移一位
    ---@type TrapRenderComponent
    local trapRenderCmpt = defender:TrapRender()
    if trapRenderCmpt and TrapType.BombByHitBack == trapRenderCmpt:GetTrapType() then
        local posNext = targetPos + dir
        if utilData:IsHaveEntity(posNext, EnumTargetEntity.Pet | EnumTargetEntity.Monster) then
            targetPos = posNext
        end
    end

    ---算完一次击退，要更新一次被击退目标的blockedPieces位置；因为要算完所有怪物击退才Apply，所以需要在算的时候更新Block
    if targetPos ~= defenderPos then
        env:DelEntityBlockFlag(defender, defender:GridLocation():GetGridPos())
        env:AddEntityBlockFlag(defender, targetPos)
    end

    local hitbackResult = SkillHitBackEffectResult:New(targetID, defenderPos, targetPos, nil, calcType, dir)
    return hitbackResult
end

---@param casterEntity Entity
function SkillPreviewEffectCalcService:CalcMultiTraction(casterEntity, skillPreviewContext, param,transContextCenter)
    local centerPos = skillPreviewContext:GetCasterPos()
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    if previewPickUpComponent then
        local pickUpGridArray = previewPickUpComponent:GetAllValidPickUpGridPos()
        centerPos = pickUpGridArray[1]
    end
    if transContextCenter then
        centerPos = skillPreviewContext:GetScopeCenterPosList()
    end

    local scopeResult = skillPreviewContext:GetScopeResult(SkillEffectType.MultiTraction)

    local calcParam = self:_CreateSkillEffectCalcParam(casterEntity:GetID(), {}, param, scopeResult)
    calcParam:SetGridPos(centerPos)

    param._finalDamageIncreateRate = nil -- 防止可能配错的情况

    ---@type PreviewSkillEffectCalc_MultiTraction
    local skillEffectCalc = SkillEffectCalc_MultiTraction:New(self._world)
    local result = skillEffectCalc:DoSkillEffectCalculator(calcParam)
    return result
end

---@return SkillSerialKillerResult
function SkillPreviewEffectCalcService:CalcSerialKiller(casterEntityID, nearestEntityIDs, skillEffectParam, skillID)
    local attacker = self._world:GetEntityByID(casterEntityID)
    --计算指定区域的格子数量
    local serialScopeType = skillEffectParam:GetSerialScopeType()
    local radius = skillEffectParam:GetRadius()
    local pieceType = skillEffectParam:GetPieceType()
    local posCaster = attacker:GetGridPosition()
    local casterBodyArea = attacker:BodyArea():GetArea()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local scopeResult =
        scopeCalculator:ComputeScopeRange(serialScopeType, {[1] = radius, [2] = 0}, posCaster, casterBodyArea)
    ---@type Vector2[]
    local addPiecePosList = {}

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    if scopeResult then
        local array = scopeResult:GetAttackRange()
        for _, v in pairs(array) do
            local pt = env:GetPieceType(v)
            if pt == pieceType then
                table.insert(addPiecePosList, v)
            end
        end
    end
    local res = SkillSerialKillerResult:New()
    res:SetAddPiecePosList(addPiecePosList)
    return res
end

---@param casterEntity Entity
---@param skillPreviewContext SkillPreviewContext
---@param skillEffectParam SkillEffectParam_ForceMovement
---@return SkillEffectResult_ForceMovement
function SkillPreviewEffectCalcService:CalcForceMovement(casterEntity, skillPreviewContext, skillEffectParam)
    ---@type PreviewSkillEffectCalc_ForceMovement
    local skillEffectCalc = PreviewSkillEffectCalc_ForceMovement:New(self._world)
    local result = skillEffectCalc:Calculate(casterEntity, skillPreviewContext, skillEffectParam)
    return result
end
--计算目标四方向可以强制位移的步数
function SkillPreviewEffectCalcService:CalcTargetFourDirForceMovementStep(targetEntity, maxStep)
    --sjs_todo
    ---@type PreviewSkillEffectCalc_ForceMovement
    local skillEffectCalc = PreviewSkillEffectCalc_ForceMovement:New(self._world)
    local result = skillEffectCalc:CalcTargetFourDirForceMovementStep(targetEntity, skillPreviewContext, skillEffectParam)
    return result
end
function SkillPreviewEffectCalcService:CalcTargetForceMovementStep(casterEntity, v2Dir, maxStep)
    ---@type PreviewSkillEffectCalc_ForceMovement
    local skillEffectCalc = PreviewSkillEffectCalc_ForceMovement:New(self._world)
    local result = skillEffectCalc:CalcTargetForceMovementStep(casterEntity, v2Dir, maxStep)
    return result
end
---@param casterEntity Entity
---@param skillPreviewContext SkillPreviewContext
function SkillPreviewEffectCalcService:CalcTransportByRange(casterEntity, skillPreviewContext, effectParam,pickUpList)
    local targetIDs = skillPreviewContext:GetTargetEntityIDList(SkillEffectType.TransportByRange)
    local isPickUp = effectParam:IsPickUp()
    local isTransportTarget = effectParam:IsTransportTarget()
    ---@type SkillEffectResultTransportByRange
    local result = SkillEffectResultTransportByRange:New()
    local range,dirType
    if isPickUp then
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        range,dirType =utilScopeSvc:CalcRangeByPickUpPosList(pickUpList)
        ---@type UtilDataServiceShare
        local utilDataSvc =  self._world:GetService("UtilData")
        for i, v in ipairs(range) do
            local nextPos = self:GridGetNextPos(v,dirType)
            local pieceType =utilDataSvc:GetPieceType(v)
            local pieceData =TransportByRangePieceData:New(v,pieceType,nextPos)
            result:AddPieceData(pieceData)
        end
    end
    if isTransportTarget then
        local targetID =targetIDs[1]
        local targetEntity = self._world:GetEntityByID(targetID)
        ---@type UtilDataServiceShare
        local utilDatSvc = self._world:GetService("UtilData")
        if targetEntity and not utilDatSvc:CheckForceMoveImmunity(targetEntity) then
            local pos = targetEntity:GetGridPosition()
            local bodyAreaCount = targetEntity:BodyArea():GetAreaCount()
            if bodyAreaCount ==1 then
                local nextPos = self:GetNextPos(pos,dirType)
                ---@type UtilDataServiceShare
                local utilDataSvc = self._world:GetService("UtilData")
                if utilDataSvc:IsMonsterCanTel2TargetPos(targetEntity,nextPos) then
                    result:AddTargetData(targetID,pos,nextPos)
                end
            end
        end
    end
    return result
end


function SkillPreviewEffectCalcService:_GetNextPos(i,pos,dirType)
    local nextPos = nil
    if dirType ==DirectionType.Up then
        nextPos = Vector2(pos.x, pos.y+i)
    elseif dirType ==DirectionType.Down then
        nextPos = Vector2(pos.x, pos.y-i)
    elseif dirType ==DirectionType.Left then
        nextPos = Vector2(pos.x-i, pos.y)
    elseif dirType ==DirectionType.Right then
        nextPos = Vector2(pos.x+i, pos.y)
    end
    return nextPos
end

function SkillPreviewEffectCalcService:GetNextPos(pos,dirType)
    local max
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalcSvc = self._world:GetService("UtilScopeCalc")
    local nextPos = nil
    if dirType == DirectionType.Up or dirType == DirectionType.Down then
        max = utilScopeCalcSvc:GetCurBoardMaxY()
    elseif dirType == DirectionType.Left or dirType == DirectionType.Right then
        max = utilScopeCalcSvc:GetCurBoardMaxX()
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    for i = 1, max do
        local tmpPos = self:_GetNextPos(i,pos,dirType)
        local pieceType =utilDataSvc:GetPieceType(tmpPos)
        if not utilScopeSvc:IsValidPiecePos(tmpPos) then
            return tmpPos
        end
        if pieceType and  pieceType ~=PieceType.None then
            return tmpPos
        end
    end
    return nextPos
end

function SkillPreviewEffectCalcService:GridGetNextPos(pos,dirType)
    local max
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalcSvc = self._world:GetService("UtilScopeCalc")
    local nextPos = nil
    if dirType == DirectionType.Up or dirType == DirectionType.Down then
        max = utilScopeCalcSvc:GetCurBoardMaxY()
    elseif dirType == DirectionType.Left or dirType == DirectionType.Right then
        max = utilScopeCalcSvc:GetCurBoardMaxX()
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    for i = 1, max do
        local tmpPos = self:_GetNextPos(i,pos,dirType)
        local pieceType =utilDataSvc:GetPieceType(tmpPos)
        if not utilScopeSvc:IsValidPiecePos(tmpPos) then
            return tmpPos
        end
        if pieceType and  pieceType ~=PieceType.None and
                utilDataSvc:IsPosCanConvertGridElement(tmpPos)  then
            return tmpPos
        end
    end
    return nextPos
end

---@param casterEntity Entity
---@param skillPreviewContext SkillPreviewContext
---@param effectParam SkillEffectParam_PickUpGridTogether
---@return SkillEffectResult_PickUpGridTogether
function SkillPreviewEffectCalcService:CalcPickUpGridTogether(casterEntity, skillPreviewContext, effectParam,pickUpList)
    local skillRange = skillPreviewContext:GetScopeResult()
    local rangeCount = #skillRange
    local pickupPos = pickUpList[1]
    local pickupIndex = self:FindPickIndex(skillRange, pickupPos)
    local pieceType = effectParam:GetGridType()
    ---@type PickUpGridTogetherData[]
    local gridDataList = self:BuildData(skillRange)
    local replaceIndex = pickupIndex
    ---从下往上交换
    for i = pickupIndex , rangeCount do
        ---@type PickUpGridTogetherData
        local gridData = gridDataList[i]
        --找到一个可以聚拢的格子
        if pieceType == gridData:GetGridType() and
                gridData:IsCanConvert() and
                i ~= replaceIndex then
            local tmpData = gridData
            Log.info("ReplaceIndex:",replaceIndex,"Type:",gridData:GetGridType()," GridPos:",gridData:GetGridPos())
            local j =replaceIndex
            while j<=i do
                local tmpR = self:FindCanTogetherGrid(gridDataList, j, i,1)
                if tmpR then
                    Log.info("DownToUp Index:",tmpR,"Pos:",skillRange[tmpR]," NewType:",tmpData:GetGridType())
                    local tempGridData = gridDataList[tmpR]
                    gridDataList[tmpR] = tmpData
                    tmpData = tempGridData
                    j =tmpR
                end
                j = j + 1
            end
            replaceIndex = replaceIndex+1
        end
    end
    ---从下往上交换
    replaceIndex = pickupIndex
    for i = pickupIndex , 1,-1 do
        ---@type PickUpGridTogetherData
        local gridData = gridDataList[i]
        --找到一个可以聚拢的格子
        if pieceType == gridData:GetGridType() and
                gridData:IsCanConvert() and
                i ~= replaceIndex then
            Log.info("ReplaceIndex:",replaceIndex,"GridPos:",gridData:GetGridPos())
            local tmpData = gridData
            local j = replaceIndex
            while j>=i do
                local tmpR = self:FindCanTogetherGrid(gridDataList,j,i, -1)
                if tmpR then
                    Log.info("UpToDown Index:",tmpR,"Pos:",skillRange[tmpR]," NewType:",tmpData:GetGridType())
                    local tempGridData = gridDataList[tmpR]
                    --Log.fatal("UpToDown Index:",tmpR,"GridPos:",tempGridData:GetGridPos())
                    gridDataList[tmpR] = tmpData
                    tmpData = tempGridData
                    j =tmpR
                end
                j = j - 1
            end
            replaceIndex = replaceIndex -1
        end
    end
    for i, pos in ipairs(skillRange) do
        gridDataList[i]:SetGridPos(pos)
    end
    ---@type SkillEffectResult_PickUpGridTogether
    local results = SkillEffectResult_PickUpGridTogether:New(gridDataList)
    return results
end

---@param gridDataList PickUpGridTogetherData[]
---@param beginIndex number
---@param endIndex number
---@param step number
function SkillPreviewEffectCalcService:FindCanTogetherGrid(gridDataList, beginIndex, endIndex,step)
    for i = beginIndex, endIndex,step do
        local gridData = gridDataList[i]
        if gridData:IsCanConvert() then
            return i
        end
    end
end
---@param range Vector2[]
---@param pickPos Vector2
function SkillPreviewEffectCalcService:FindPickIndex(range, pickPos)
    for i, v in ipairs(range) do
        if v.x == pickPos.x and v.y == pickPos.y then
            return i
        end
    end
end
---@param skillRange Vector2[]
---@return PickUpGridTogetherData[]
function SkillPreviewEffectCalcService:BuildData(skillRange)
    ---@type PickUpGridTogetherData[]
    local ret = {}
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    for i, pos in ipairs(skillRange) do
        ---@type Entity
        local gridEntity = renderBoardCmpt:GetGridRenderEntity(pos)
        local pieceType = gridEntity:Piece():GetPieceType()
        local canConvert = utilDataSvc:IsPosCanConvertGridElement(pos)
        if pieceType == PieceType.None then
            canConvert = false
        end

        ---@type PickUpGridTogetherData
        local data = PickUpGridTogetherData:New(pieceType, pos, canConvert)
        table.insert(ret, data)

    end
    return ret
end


function SkillPreviewEffectCalcService:IsPreviewGridElementMatch(checkPos, convertGridTypeArray)
    local checkPosType = self:GetPreviewGridType(checkPos)
    for k, v in ipairs(convertGridTypeArray) do
        local curGridType = tonumber(v)
        if curGridType == checkPosType then
            return true
        end
    end
    return false
end

---@param pos Vector2
---@return PieceType
function SkillPreviewEffectCalcService:GetPreviewGridType(pos)
    local env = self._world:GetPreviewEntity():PreviewEnv()
    return env:GetPieceType(pos)
    -----@type Entity
    --local renderBoardEntity = self._world:GetRenderBoardEntity()
    -----@type RenderBoardComponent
    --local renderBoardCmpt = renderBoardEntity:RenderBoard()
    -----@type Entity
    --local gridEntity = renderBoardCmpt:GetGridRenderEntity(pos)
    --local pieceType = gridEntity:Piece():GetPieceType()
    --return pieceType
end