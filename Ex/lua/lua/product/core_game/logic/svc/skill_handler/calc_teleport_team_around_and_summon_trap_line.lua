--[[
    TeleportTeamAroundAndSummonTrapLine = 197, ---瞬移位置到队伍周围一圈，朝向目标。从旧坐标连线到新坐标中心召唤机关，如果没有空位位置可以往外面找格子
]]
---@class SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine : SkillEffectCalc_Base
_class("SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine", SkillEffectCalc_Base)
SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine = SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine

function SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamTeleportTeamAroundAndSummonTrapLine
    local skillParam = skillEffectCalcParam.skillEffectParam
    local squareRingStart = skillParam:GetSquareRingStart()

    local caster = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterBodyArea = caster:BodyArea():GetArea()
    local casterPos = caster:GetGridPosition()
    local casterDir = caster:GetGridDirection()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = teamEntity:GetGridPosition()
    local playerBodyArea = teamEntity:BodyArea():GetArea()

    --先从第一圈最近的找，找不到会返回原坐标
    local posNew, dirNew, bodyAreaNew = self:_CalcPosAndDir(skillEffectCalcParam, squareRingStart)

    if not posNew then
        posNew = casterPos
        dirNew = casterDir
        bodyAreaNew = casterBodyArea
    end

    --加血结果入SkillRoutine
    local skillEffectResultContainer = caster:SkillContext():GetResultContainer()
    ---@type SkillEffectCalcService
    local sSkillEffectCalc = self._world:GetService("SkillEffectCalc")

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local colorOld = utilData:FindPieceElement(casterPos)

    local stageIndex = skillEffectCalcParam.skillEffectParam:GetSkillEffectDamageStageIndex()

    ---@type SkillEffectResult_Teleport
    local skillEffectResult_Teleport =
        SkillEffectResult_Teleport:New(
        skillEffectCalcParam.casterEntityID,
        casterPos,
        colorOld,
        posNew,
        dirNew,
        stageIndex
    )
    skillEffectResultContainer:AddEffectResult(skillEffectResult_Teleport)

    if dirNew ~= casterDir then
        ---@type SkillRotateEffectResult
        local skillRotateEffectResult = SkillRotateEffectResult:New(caster:GetID(), casterDir, dirNew)
        skillEffectResultContainer:AddEffectResult(skillRotateEffectResult)

        ---@type SkillEffectResultChangeBodyArea
        local skillEffectResultChangeBodyArea = SkillEffectResultChangeBodyArea:New(caster:GetID(), bodyAreaNew)
        skillEffectResultContainer:AddEffectResult(skillEffectResultChangeBodyArea)
    end

    ------------------------------------------
    ----计算可以召唤机关的坐标

    local trapID = skillParam:GetTrapID()
    if not trapID then
        return
    end
    local limitCount = skillParam:GetLimitCount()

    local summonPosList = {}

    --优先选择连线两侧补充
    local widthThreshold = 0.7
    summonPosList = self:_CalcSummonPosWithAngleFreeLine(caster, posNew, skillParam, widthThreshold)

    --扩宽
    if table.count(summonPosList) < limitCount then
        widthThreshold = 1.414
        summonPosList = self:_CalcSummonPosWithAngleFreeLine(caster, posNew, skillParam, widthThreshold)
    end

    --玩家周围一圈补充，一圈没有就继续扩圈
    if table.count(summonPosList) < limitCount then
        for i = 1, BattleConst.DefaultMaxX do
            local ringCount = i
            local summonPosAroundTeam = {}
            summonPosAroundTeam = self:_CalcSummonPosAroundTeam(caster, posNew, skillParam, ringCount)
            for _, pos in ipairs(summonPosAroundTeam) do
                if not table.intable(summonPosList, pos) and utilData:IsValidPiecePos(pos) then
                    table.insert(summonPosList, pos)
                end
                if table.count(summonPosList) >= limitCount then
                    break
                end
            end
            if table.count(summonPosList) >= limitCount then
                break
            end
        end
    end

    if table.count(summonPosList) > 0 then
        table.sort(
            summonPosList,
            function(a, b)
                local disA = Vector2.Distance(posNew, a)
                local disB = Vector2.Distance(posNew, b)
                return disA > disB
            end
        )
    end

    for _, pos in ipairs(summonPosList) do
        ---@type SkillSummonTrapEffectResult
        local skillSummonTrapEffectResult = SkillSummonTrapEffectResult:New(trapID, pos)
        skillEffectResultContainer:AddEffectResult(skillSummonTrapEffectResult)
    end
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine:_CalcPosAndDir(skillEffectCalcParam, ringCount)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = teamEntity:GetGridPosition()
    local playerBodyArea = teamEntity:BodyArea():GetArea()

    local caster = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterBodyArea = caster:BodyArea():GetArea()
    local casterPos = caster:GetGridPosition()
    local casterDir = caster:GetGridDirection()

    local casterBodyAreaPosList = {}
    for _, area in ipairs(casterBodyArea) do
        local workPos = area + casterPos
        table.insert(casterBodyAreaPosList, workPos)
    end

    --队伍周围一圈
    local rangCoungMin = math.max(1, ringCount - 1)
    local attackRangeOne = {}
    local attackRangeTwo = {}
    if ringCount == 1 then
        attackRangeTwo = ComputeScopeRange.ComputeRange_SquareRing(playerPos, #playerBodyArea, ringCount)
        attackRangeOne = attackRangeTwo
    else
        local attackRangeMax = ComputeScopeRange.ComputeRange_SquareRing(playerPos, #playerBodyArea, 9)
        local attackRangeMin = ComputeScopeRange.ComputeRange_SquareRing(playerPos, #playerBodyArea, ringCount)
        for _, pos in ipairs(attackRangeMin) do
            table.removev(attackRangeMax, pos)
        end
        attackRangeTwo = attackRangeMax
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local centerAndDirList = {}

    --计算两圈内的点是否可以移动
    for _, pos in ipairs(attackRangeTwo) do
        --基础四方向
        local dirs = {Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)}
        --但是因为要朝向玩家，所以不能有背对玩家的方向

        if rangCoungMin == 1 then
            -----
            -- if pos.y >= playerPos.y and pos.x >= playerPos.x then
            --     dirs = {Vector2(0, -1), Vector2(-1, 0)}
            -- elseif pos.y >= playerPos.y and pos.x < playerPos.x then
            --     dirs = {Vector2(0, -1), Vector2(1, 0)}
            -- elseif pos.y < playerPos.y and pos.x >= playerPos.x then
            --     dirs = {Vector2(0, 1), Vector2(-1, 0)}
            -- elseif pos.y < playerPos.y and pos.x < playerPos.x then
            --     dirs = {Vector2(0, 1), Vector2(1, 0)}
            -- end
            if pos.y >= playerPos.y then
                dirs = {Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)}
            elseif pos.y <= playerPos.y then
                dirs = {Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)}
            elseif pos.x >= playerPos.x then
                dirs = {Vector2(0, -1), Vector2(0, 1), Vector2(1, 0)}
            elseif pos.x <= playerPos.x then
                dirs = {Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0)}
            end
        else
            --计算施法者坐标和队伍坐标的朝向
            local vectors = {Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)}
            local minIdx, minAngle = 1, 180
            local vec = playerPos - pos
            for i, v in ipairs(vectors) do
                local angle = Vector2.Angle(vec, v)
                if minAngle > angle then
                    minAngle = angle
                    minIdx = i
                end
            end
            local newDir = vectors[minIdx]
            dirs = {newDir}
        end

        for i, dir in ipairs(dirs) do
            if table.count(casterBodyArea) == 6 then
                local newBodyArea = casterBodyArea

                if dir == Vector2(0, -1) then
                    newBodyArea = {
                        Vector2(0, 0),
                        Vector2(1, 0),
                        Vector2(-1, 0),
                        Vector2(0, 1),
                        Vector2(1, 1),
                        Vector2(-1, 1)
                    }
                elseif dir == Vector2(1, 0) then
                    newBodyArea = {
                        Vector2(0, 0),
                        Vector2(0, 1),
                        Vector2(0, -1),
                        Vector2(-1, 0),
                        Vector2(-1, 1),
                        Vector2(-1, -1)
                    }
                elseif dir == Vector2(-1, 0) then
                    newBodyArea = {
                        Vector2(0, 0),
                        Vector2(0, 1),
                        Vector2(0, -1),
                        Vector2(1, 0),
                        Vector2(1, 1),
                        Vector2(1, -1)
                    }
                elseif dir == Vector2(0, 1) then
                    newBodyArea = {
                        Vector2(0, 0),
                        Vector2(-1, 0),
                        Vector2(1, 0),
                        Vector2(0, -1),
                        Vector2(-1, -1),
                        Vector2(1, -1)
                    }
                end

                casterBodyArea = newBodyArea
            end

            local canMove = true
            local posInTargetAround = false

            --每一个点计算4个方向能否放下新的身形
            for k, area in ipairs(casterBodyArea) do
                local workPos = area + pos

                if
                    utilDataSvc:IsPosBlock(workPos, BlockFlag.MonsterLand) and
                        not table.intable(casterBodyAreaPosList, workPos)
                 then
                    canMove = false
                    break
                end

                --rangCoungMin=1是1技能的，~=1是给3技能判断的
                if rangCoungMin ~= 1 or table.intable(attackRangeOne, workPos) then
                    posInTargetAround = true
                end
            end

            --该位置有一个方向可以位置就可以了  不用考虑朝向(优先了正面超左下)
            if canMove and posInTargetAround then
                table.insert(centerAndDirList, {pos = pos, dir = dir, bodyArea = casterBodyArea})
                break
            end
        end
    end

    local targetPos = casterPos
    local targetDir = casterDir
    local bodyAreaNew = casterBodyArea

    --目标周围有位置可以瞬移
    if table.count(centerAndDirList) > 0 then
        table.sort(
            centerAndDirList,
            function(a, b)
                local disA = Vector2.Distance(casterPos, a.pos)
                local disB = Vector2.Distance(casterPos, b.pos)
                return disA > disB
            end
        )

        targetDir = centerAndDirList[1].dir
        targetPos = centerAndDirList[1].pos
        bodyAreaNew = centerAndDirList[1].bodyArea
    else
        --找不到就交给下一轮计算
    end

    if not targetPos and ringCount < BattleConst.DefaultMaxX then
        local newRingCount = ringCount + 1
        return self:_CalcPosAndDir(skillEffectCalcParam, newRingCount)
    end

    return targetPos, targetDir, bodyAreaNew
end

---@param skillParam SkillEffectParamTeleportTeamAroundAndSummonTrapLine
function SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine:_CalcSummonPosWithAngleFreeLine(
    casterEntity,
    targetPos,
    skillParam,
    widthThreshold)
    local trapID = skillParam:GetTrapID()
    local limitCount = skillParam:GetLimitCount()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    ---@type TrapServiceLogic
    local trapServerLogic = self._world:GetService("TrapLogic")
    local tarpPosList = trapServerLogic:FindTrapPosByTrapID(trapID)

    --先使用范围46计算一个基础范围
    local curPos = casterEntity:GetGridPosition()
    local curBodyArea = casterEntity:BodyArea():GetArea()
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local scopeParam = {
        widthThreshold = widthThreshold,
        noExtend = 1
    }
    local scopeResult =
        scopeCalculator:ComputeScopeRange(
        SkillScopeType.AngleFreeLine,
        scopeParam,
        targetPos,
        curBodyArea,
        nil,
        nil,
        curPos
    )

    local attackRange = scopeResult:GetAttackRange()

    --范围的坐标是乱序的，是先计算了直线上再计算扩充。需要先排序
    local function CmpDistancefunc(pos1, pos2)
        local dis1 = Vector2.Distance(curPos, pos1)
        local dis2 = Vector2.Distance(curPos, pos2)
        return dis1 > dis2
    end
    table.sort(attackRange, CmpDistancefunc)

    --任意2个挨着的斜向格子，在其2x2的的范围内，最多只能有一个空余的格子在范围外
    local supplementPosList = {}
    for k, pos in ipairs(attackRange) do
        local nextPos = attackRange[k + 1]
        if not nextPos then
            break
        end

        if math.abs(pos.x - nextPos.x) == 1 and math.abs(pos.y - nextPos.y) == 1 then
            local remainPosList = {}
            local intableCount = 0
            local diffX = nextPos.x - pos.x
            local diffY = nextPos.y - pos.y
            for i = pos.x, nextPos.x, diffX do
                for j = pos.y, nextPos.y, diffY do
                    local workPos = Vector2(i, j)

                    if table.intable(attackRange, workPos) then
                        intableCount = intableCount + 1
                    else
                        if workPos ~= pos and workPos ~= nextPos then
                            local isValidGrid = utilData:IsValidPiecePos(workPos)
                            if isValidGrid then
                                table.insert(remainPosList, workPos)
                            end
                        end
                    end
                end
            end

            if table.count(remainPosList) > 0 and intableCount == 2 then
                table.insert(supplementPosList, remainPosList[1])
            end
        end
    end

    table.appendArray(attackRange, supplementPosList)

    local summonPosList = {}
    for _, pos in ipairs(attackRange) do
        if not table.intable(summonPosList, pos) and not table.intable(tarpPosList, pos) and pos ~= teamPos then
            table.insert(summonPosList, pos)
        end
    end

    return summonPosList
end

---@param skillParam SkillEffectParamTeleportTeamAroundAndSummonTrapLine
function SkillEffectCalc_TeleportTeamAroundAndSummonTrapLine:_CalcSummonPosAroundTeam(
    casterEntity,
    posNew,
    skillParam,
    ringCount)
    local trapID = skillParam:GetTrapID()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = teamEntity:GetGridPosition()
    local playerBodyArea = teamEntity:BodyArea():GetArea()

    --队伍周围一圈
    local attackRangeOutSide = ComputeScopeRange.ComputeRange_SquareRing(playerPos, #playerBodyArea, ringCount)

    if ringCount > 1 then
        local attackRangeInSide = ComputeScopeRange.ComputeRange_SquareRing(playerPos, #playerBodyArea, ringCount - 1)
        for _, pos in ipairs(attackRangeInSide) do
            table.removev(attackRangeOutSide, pos)
        end
    end

    ---@type TrapServiceLogic
    local trapServerLogic = self._world:GetService("TrapLogic")
    local tarpPosList = trapServerLogic:FindTrapPosByTrapID(trapID)

    local summonPosList = {}
    for _, pos in ipairs(attackRangeOutSide) do
        if not table.intable(summonPosList, pos) and not table.intable(tarpPosList, pos) then
            table.insert(summonPosList, pos)
        end
    end

    if table.count(summonPosList) > 0 then
        table.sort(
            summonPosList,
            function(a, b)
                local disA = Vector2.Distance(posNew, a)
                local disB = Vector2.Distance(posNew, b)
                return disA < disB
            end
        )
    end

    return summonPosList
end
