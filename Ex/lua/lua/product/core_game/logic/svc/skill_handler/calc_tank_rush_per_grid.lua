_class("SkillEffectCalc_TankRushPerGrid", SkillEffectCalc_Base)
---@class SkillEffectCalc_TankRushPerGrid: SkillEffectCalc_Base
SkillEffectCalc_TankRushPerGrid = SkillEffectCalc_TankRushPerGrid

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TankRushPerGrid:DoSkillEffectCalculator(skillEffectCalcParam)
    local resultArray = {}

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterPos = casterEntity:GetGridPosition()
    local casterBodyArea = casterEntity:BodyArea():GetArea()

    local targetTeamID = skillEffectCalcParam.targetEntityIDs[1]
    local targetEntity = self._world:GetEntityByID(targetTeamID)

    if not targetEntity then
        return {}
    end

    local targetPos = targetEntity:GetGridPosition()

    if table.Vector2Include(skillEffectCalcParam.skillRange, targetPos) then
        --模式一：冲向玩家
        local r = self:_RushToTarget(targetEntity, targetPos, skillEffectCalcParam, true)
        if r then
            table.insert(resultArray, r)
        end
    else
        --[[
            位置优先级规则：
            * 没有阻挡的位置优先
            * 阻挡状况相同的情况下，优先竖方向的位置
        ]]
        ---@type Entity
        local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

        local nearestGridArray = {}
        local nearestDistance = 999
        for _, v2 in ipairs(skillEffectCalcParam.skillRange) do
            local dis = Vector2.Distance(v2, targetPos)
            if self:IsPosAccessibleForEntity(casterEntity, v2) then
                if nearestDistance > dis then
                    nearestGridArray = {v2}
                    nearestDistance = dis
                elseif nearestDistance == dis then
                    table.insert(nearestGridArray, v2)
                end
            end
        end
        if #nearestGridArray > 0 then
            --根据身形取最大最小的x y值，以此确定哪些格子属于“竖放向”
            local minX = casterPos.x
            local minY = casterPos.y
            local maxX = casterPos.x
            local maxY = casterPos.y
            for _, v in ipairs(casterBodyArea) do
                local v2 = casterPos + v
                if v2.x < minX then
                    minX = v2.x
                end
                if v2.x > maxX then
                    maxX = v2.x
                end
                if v2.y < minY then
                    minY = v2.y
                end
                if v2.y > maxY then
                    maxY = v2.y
                end
            end
            local nearestGrid
            local secondaryGrid
            for _, v2 in ipairs(nearestGridArray) do
                if v2.x >= minX and v2.x <= maxX then
                    nearestGrid = v2
                else
                    secondaryGrid = v2
                end
            end
            local selectedGridPos = nearestGrid or secondaryGrid
            local r = self:_RushToTarget(targetEntity, selectedGridPos, skillEffectCalcParam, false)
            if r then
                table.insert(resultArray, r)
            end
        end
    end

    return resultArray
end

local function isPosSafeForBody(v2, bodyArea, range)
    for _, body in ipairs(bodyArea) do
        local v = v2 + body
        if not table.Vector2Include(range, v) then
            return false
        end
    end

    return true
end

local searchDirs = {
    Vector2.down, Vector2.up, Vector2.left, Vector2.right,
    Vector2.New(-1, -1), Vector2.New(1, 1), Vector2.New(-1, 1), Vector2.New(1, -1)
}

local function generateLogicGridPosMap(range, casterBodyArea)
    local logicGridPosMap = {}

    for _, v2 in ipairs(range) do
        local index = Vector2.Pos2Index(v2)

        if isPosSafeForBody(v2, casterBodyArea, range) then
            logicGridPosMap[index] = v2
        else
            for _, dir in ipairs(searchDirs) do
                local v = v2 + dir
                if isPosSafeForBody(v, casterBodyArea, range) then
                    logicGridPosMap[index] = v
                    break
                end
            end
        end
    end

    return logicGridPosMap
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TankRushPerGrid:_RushToTarget(targetEntity, targetPos, skillEffectCalcParam, calcDamage)
    ---@type SkillEffectParam_TankRushPerGrid
    local effectParam = skillEffectCalcParam:GetSkillEffectParam()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterPos = casterEntity:GetGridPosition()
    local casterBodyArea = casterEntity:BodyArea():GetArea()

    --对于范围内的任意格子，只有能够容纳完整身形且与该点距离最近的位置，才是可以用来设置逻辑坐标的位置
    local logicGridPosMap = generateLogicGridPosMap(skillEffectCalcParam.skillRange, casterBodyArea)

    local targetPosIndex = Vector2.Pos2Index(targetPos)
    --转成施法者直线移动路径上的点，方便后面计算
    local targetLogicGridPos = logicGridPosMap[targetPosIndex]
    if not targetLogicGridPos then
        Log.error("TankRushPerGrid: bad target pos index: ", targetPosIndex)
        return
    end
    local dir = targetLogicGridPos - casterPos
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
    if dir == Vector2.zero then
        return
    end

    local fullCasterBodyPos = {}
    for _, v in ipairs(casterBodyArea) do
        table.insert(fullCasterBodyPos, casterPos + v)
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local blockFlag = casterEntity:HasMonsterID() and casterEntity:MonsterID():GetMonsterBlockData() or BlockFlag.LinkLine

    local targetRushPos = casterPos
    Log.error("TankRushPerGrid: casterPos: ", tostring(casterPos), " dir: ", tostring(dir))
    while (true) do
        local v2 = targetRushPos + dir
        Log.error("TankRushPerGrid: checking pos ", tostring(v2))
        local isPosSafe = isPosSafeForBody(v2, casterBodyArea, skillEffectCalcParam.skillRange)
        isPosSafe = isPosSafe and (table.Vector2Include(fullCasterBodyPos, v2) or utilData:IsPosBlock(v2, blockFlag))
        if isPosSafeForBody(v2, casterBodyArea, skillEffectCalcParam.skillRange) then
            targetRushPos = v2
        else
            break
        end
    end
    Log.error("TankRushPerGrid: targetRushPos: ", tostring(targetRushPos), " dir: ", tostring(dir))

    local walkResArray = {}

    local isCasterDead = false
    local isRushFinished = true

    local utilScope = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator_DirectLine
    local directLineCalc = SkillScopeCalculator_DirectLineExpand:New(utilScope)
    local targetSelector = SkillScopeTargetSelector:New(self._world)

    local damageScopeResult, damageTargetIDArray
    local currentPos = casterPos:Clone()
    if currentPos ~= targetRushPos then
        --这里不用考虑玩家就在自己身边的状况，设计如此
        while (currentPos ~= targetRushPos) do
            currentPos = currentPos + dir
            Log.error("TankRushPerGrid: rushing new pos: ", tostring(currentPos))

            if not self:IsPosAccessibleForEntity(casterEntity, currentPos) then
                isRushFinished = false
                break
            end

            if calcDamage then
                --需求就是这个范围
                local scopeResult = directLineCalc:CalcRange(
                        SkillScopeType.DirectLineExpand,
                        {0, 1},
                        currentPos,
                        casterBodyArea,
                        dir
                )
                local selectResult = targetSelector:DoSelectSkillTarget(
                    casterEntity, SkillTargetType.Pet, scopeResult, skillEffectCalcParam.skillID
                )
                if #selectResult > 0 then
                    damageScopeResult = scopeResult
                    damageTargetIDArray = selectResult
                end
            end

            local walkRes, isDead = self:MoveAndGenerateWalkResult(casterEntity, currentPos)
            table.insert(walkResArray, walkRes)

            if isDead then
                isCasterDead = true
                break
            end
        end
    end

    if #walkResArray == 0 then
        return
    end

    casterEntity:SetGridDirection(dir)

    local damageResults, hitbackResults

    if calcDamage and damageScopeResult and damageTargetIDArray then
        local damageCalc = SkillEffectCalc_Damage:New(self._world)
        local damageCalcParam = SkillEffectCalcParam:New(
            skillEffectCalcParam.casterEntityID,
            damageTargetIDArray,
            effectParam:GetDamageParam(),
            skillEffectCalcParam.skillID,
            damageScopeResult:GetAttackRange(),
            currentPos,
            currentPos
        )

        damageResults = damageCalc:DoSkillEffectCalculator(damageCalcParam)
        if damageResults and (#damageResults > 0) then
            local hitbackCalc = SkillEffectCalc_HitBack:New(self._world)
            local hitbackCalcParam = SkillEffectCalcParam:New(
                skillEffectCalcParam.casterEntityID,
                skillEffectCalcParam.targetEntityIDs,
                effectParam:GetHitBackParam(),
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange,
                currentPos,
                currentPos
            )

            hitbackResults = hitbackCalc:DoSkillEffectCalculator(hitbackCalcParam)
        end
    end

    return SkillEffectResult_TankRushPerGrid:New(walkResArray, damageResults, hitbackResults, isCasterDead)
end

function SkillEffectCalc_TankRushPerGrid:IsPosAccessibleForEntity(e, pos)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local monsterIDCmpt = e:MonsterID()
    local nMonsterBlockData = monsterIDCmpt:GetMonsterBlockData() --陆行/飞行
    local coverList = e:GetCoverAreaList(pos)
    local coverListSelf = e:GetCoverAreaList(e:GetGridPosition())
    for i = 1, #coverList do
        local posWork = coverList[i]
        if not table.icontains(coverListSelf, posWork) then
            if boardServiceLogic:IsPosBlock(posWork, nMonsterBlockData) then
                return false
            end
        end
    end

    return true
end

---@return MonsterMoveGridResult, boolean
function SkillEffectCalc_TankRushPerGrid:MoveAndGenerateWalkResult(e, pos)
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    local selfPos = e:GetGridPosition()
    local walkRes = MonsterMoveGridResult:New()
    sBoard:UpdateEntityBlockFlag(e, e:GetGridPosition(), pos)
    e:SetGridPosition(pos)
    e:SetGridDirection(pos - selfPos)
    walkRes:SetWalkPos(pos)

    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(e, TrapTriggerOrigin.MonsterGridMove)
    for i, trapEntity in ipairs(listTrapWork) do
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)
        walkRes:AddWalkTrap(trapEntity:GetID(), aiResult)
    end

    return walkRes, e:HasDeadMark()
end
