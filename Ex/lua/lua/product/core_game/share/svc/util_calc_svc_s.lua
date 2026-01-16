--[[------------------------------------------------------------------------------------------
    UtilCalcServiceShare : 此service是纯算法计算函数集合，不依赖逻辑数据
]] --------------------------------------------------------------------------------------------
_class("UtilCalcServiceShare", BaseService)
---@class UtilCalcServiceShare: BaseService
UtilCalcServiceShare = UtilCalcServiceShare

function UtilCalcServiceShare:Constructor(world)
    self._world = world
end

--region Search

BoardQuadrant = {
    Center = 0,
    RightTop = 1,
    RightBottom = 2,
    LeftBottom = 3,
    LeftTop = 4
}
_enum("BoardQuadrant", BoardQuadrant)

function UtilCalcServiceShare:GetPosQuadrant(center, pos)
    if center == pos then
        return BoardQuadrant.Center
    end

    local relative = pos - center
    if relative.x >= 0 and relative.y >= 0 then
        return BoardQuadrant.RightTop
    elseif relative.x >= 0 and relative.y <= 0 then
        return BoardQuadrant.RightBottom
    elseif relative.x <= 0 and relative.y <= 0 then
        return BoardQuadrant.LeftBottom
    elseif relative.x <= 0 and relative.y >= 0 then
        return BoardQuadrant.LeftTop
    end
end

-- 规则：(0, x+)在第一象限内，(x+, 0)在第二象限内，(0, y-)在第三象限内，(x-, 0)在第四象限内
function UtilCalcServiceShare:DivideGridsByQuadrant(grids, center)
    center = center or Vector2.New(0, 0)
    local rightTop = {}
    local rightBottom = {}
    local leftBottom = {}
    local leftTop = {}

    -- Log.info("====================DivideGridsByQuadrant====================")
    -- Log.info("中心位置：", tostring(center))
    for i = 1, #grids do
        local absGridPos = grids[i]
        local gridPos = absGridPos - center
        if gridPos.x == 0 and gridPos.y == 0 then
            -- (0, 0)格子不在象限中
        else
            local quadrant = self:GetPosQuadrant(center, grids[i])
            if quadrant == BoardQuadrant.RightTop then
                -- Log.info("第一象限：相对[", gridPos, "]，绝对：[", grids[i], "]")
                table.insert(rightTop, absGridPos)
            elseif quadrant == BoardQuadrant.RightBottom then
                -- Log.info("第二象限：相对[", gridPos, "]，绝对：[", grids[i], "]")
                table.insert(rightBottom, absGridPos)
            elseif quadrant == BoardQuadrant.LeftBottom then
                -- Log.info("第三象限：相对[", gridPos, "]，绝对：[", grids[i], "]")
                table.insert(leftBottom, absGridPos)
            elseif quadrant == BoardQuadrant.LeftTop then
                table.insert(leftTop, absGridPos)
            -- Log.info("第四象限：相对[", gridPos, "]，绝对：[", grids[i], "]")
            end
        end
    end
    -- Log.info("====================DivideGridsByQuadrant====================")

    return rightTop, rightBottom, leftBottom, leftTop
end

function UtilCalcServiceShare:GetGridRingNum(grid, center, bodyArea)
    local nearest = grid
    local relative = nearest - center
    return math.max(math.abs(relative.x), math.abs(relative.y))
end

function UtilCalcServiceShare:GetGridRingNumWithBodyArea(grid, center, bodyArea)
    local nearest = grid
    local nearestRelative = Vector2(0,0)
    local distance = Vector2.Distance(grid, center)
    local minDis = distance
    for _, v2Relative in ipairs(bodyArea) do
        local v2 = grid + v2Relative
        local curDis = Vector2.Distance(v2, center)
        if curDis < minDis then
            minDis = curDis
            nearest = v2
            nearestRelative = v2Relative--使用的坐标点是逻辑的加上哪个偏移
        end
    end
    local relative = nearest - center
    return math.max(math.abs(relative.x), math.abs(relative.y)),nearest,nearestRelative
end

function UtilCalcServiceShare:GetGridsByRing(gridList, center, ringNum)
    local resultArray = {}

    for i = 1, #gridList do
        local gridPos = gridList[i]
        local gridRing = self:GetGridRingNum(gridPos, center)
        if gridRing <= ringNum then
            table.insert(resultArray, gridPos)
        end
    end

    return resultArray
end

function UtilCalcServiceShare:GetFirstObstacleInPath(
    path,
    additionalObstaclePosArray,
    isAbyssAllow,
    isPlayerPosAllow,
    blockFlag,
    entity)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    local playerEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = playerEntity:GetGridPosition()

    ---@type BoardComponent
    local boardComponent = self._world:GetBoardEntity():Board()

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local areaArray = {}
    if entity and entity:HasBodyArea() then
        areaArray = entity:BodyArea():GetArea()
    end
    for i = 1, #path do
        local pathPos = path[i]

        local targetPosList = {}
        if #areaArray > 0 then
            for _, p in ipairs(areaArray) do
                table.insert(targetPosList, Vector2(pathPos.x + p.x, pathPos.y + p.y))
            end
        else
            table.insert(targetPosList, Vector2(pathPos.x, pathPos.y))
        end
        for _, gridPos in ipairs(targetPosList) do
            if (not utilData:IsValidPiecePos(gridPos)) then
                return gridPos, i
            end
            if blockFlag and utilData:IsPosBlock(gridPos, blockFlag) then
                local blockData = utilData:FindBlockByPos(gridPos)
                -- 无视掉同类单位的阻挡，避免已经算到的单位 在其当前位置上的阻挡 被认为是牵引路线的阻碍
                local trapBlockVal = 0
                for entityID, blockVal in pairs(blockData.m_listBlock) do--不能改ipairs
                    local blockEntity = self._world:GetEntityByID(entityID)
                    if not blockEntity then
                        Log.error("not find block entity !!! entityID=",entityID)
                        goto CONTINUE
                    end
                    if (entity:HasMonsterID() and (blockEntity:HasMonsterID())) then
                        goto CONTINUE
                    elseif (entity:HasPetPstID() or entity:HasTeam()) and (blockEntity:HasPetPstID() or blockEntity:HasTeam()) then
                        goto CONTINUE
                    end

                    trapBlockVal = trapBlockVal | blockVal

                    ::CONTINUE::
                end
                if (trapBlockVal & blockFlag) ~= 0 then
                    return gridPos, i
                end
            end
            if not isAbyssAllow then
                if  boardComponent:GetPieceType(gridPos) == PieceType.None and utilData:IsPosBlock(gridPos, BlockFlag.LinkLine) then
                    return gridPos, i
                end
            end
            if not isPlayerPosAllow then
                if gridPos == playerPos then
                    return gridPos, i
                end
            end
            if additionalObstaclePosArray and table.icontains(additionalObstaclePosArray, gridPos) then
                return gridPos, i
            end

            ---@type table<number, Entity>
            -- local traps = utilData:GetTrapsAtPos(gridPos)
            -- for _, trap in ipairs(traps) do
            --     local trapComponent = trap:Trap()
            --     local trapType = trapComponent:GetTrapType()
            --     if trapType == TrapType.Obstacle or trapType == TrapType.ObstacleMove then
            --         return gridPos, i
            --     end
            -- end
        end
    end
end

--根据pieceType类型找到最近centerPos的maxCount个数的格子坐标
---@param centerPos Vector2
---@param pieceTypeList PieceType[]
---@param maxCount number
---@param bound table 边界范围
---@param boundInNum number 内圈数量
---@param excludeTrap number 内圈数量
function UtilCalcServiceShare:FindPieceElementByTypeCountAndCenter(
    centerPos,
    pieceTypeList,
    maxCount,
    bound,
    boundInNum,
    excludeTrap,
    excludePosList)
    if type(pieceTypeList) ~= "table" then
        pieceTypeList = {pieceTypeList}
    end
    local boardService = self._world:GetService("BoardLogic")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    local board = boardEntity:Board()
    ---@type Vector2[]
    local pieceList = {}
    local IsTrapOnPos = function(pos)
        ---@type UtilDataServiceShare
        local sUtilData = self._world:GetService("UtilData")
        local traps = sUtilData:GetTrapsAtPos(pos)
        for _, trap in ipairs(traps) do
            if table.icontains(excludeTrap, trap:Trap():GetTrapID()) then
                return true
            end
        end
        return false
    end

    local IsExcludePos = function(pos)
        if table.icontains(excludePosList, pos) then
            return true
        end
        return false
    end

    if bound then
        for x = bound.xMin, bound.xMax do
            for y = bound.yMin, bound.yMax do
                -- boundInNum 为0 也判断脚底转色格子
                if boundInNum == 0 then
                    if board.Pieces[x] and board.Pieces[x][y] and table.icontains(pieceTypeList, board.Pieces[x][y]) then
                        table.insert(pieceList, Vector2(x, y))
                    end
                else
                    if
                        x >= centerPos.x - boundInNum and x <= centerPos.x + boundInNum and
                            y >= centerPos.y - boundInNum and
                            y <= centerPos.y + boundInNum
                     then
                    else
                        if board.Pieces[x] and board.Pieces[x][y] and table.icontains(pieceTypeList, board.Pieces[x][y]) then
                            table.insert(pieceList, Vector2(x, y))
                        end
                    end
                end
            end
        end
    else
        local area = boardService.PlayerArea
        for x = area.minX, area.maxX do
            for y = area.minY, area.maxY do
                local pos = Vector2(x, y)
                if
                    board.Pieces[x] and board.Pieces[x][y] and table.icontains(pieceTypeList, board.Pieces[x][y]) and
                        not IsTrapOnPos(pos) and
                        not IsExcludePos(pos)
                 then
                    table.insert(pieceList, pos)
                end
            end
        end
    end
    HelperProxy:SortPosByCenterPosDistance(centerPos, pieceList)

    for i = maxCount + 1, #pieceList do
        pieceList[i] = nil
    end
    return pieceList
end

--在给定的格子areaGridList内根据pieceType类型选出所有格子坐标
---@param areaGridList Vector2[]
---@param pieceTypeList PieceType[]
---@param maxCount number
---@param excludeTrap number
function UtilCalcServiceShare:FindPieceElementByTypeAndArea(
    areaGridList,
    pieceTypeList,
    excludeTrap)
    if type(pieceTypeList) ~= "table" then
        pieceTypeList = {pieceTypeList}
    end

    local IsTrapOnPos = function(pos)
        ---@type UtilDataServiceShare
        local sUtilData = self._world:GetService("UtilData")
        local traps = sUtilData:GetTrapsAtPos(pos)
        for _, trap in ipairs(traps) do
            if table.icontains(excludeTrap, trap:Trap():GetTrapID()) then
                return true
            end
        end
        return false
    end

    local boardService = self._world:GetService("BoardLogic")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    local board = boardEntity:Board()
    ---@type Vector2[]
    local pieceList = {}
    
    if areaGridList then
        for _, gridPos in ipairs(areaGridList) do
            if board.Pieces[gridPos.x] and board.Pieces[gridPos.x][gridPos.y] and 
                table.icontains(pieceTypeList, board.Pieces[gridPos.x][gridPos.y]) and
                not IsTrapOnPos(gridPos)
            then
                table.insert(pieceList, gridPos)
            end
        end
    end
    return pieceList
end

---获取正前方的格子坐标，如果是多格实体，获取前方的格子坐标数组，从左到右排列
---@param e Entity
function UtilCalcServiceShare:GetFrontPieces(e)
    ---@type GridLocationComponent
    local gridLocation = e:GridLocation()
    local center = gridLocation:Center()
    local direction = gridLocation.Direction
    ---@type BodyAreaComponent
    local area = e:BodyArea():GetArea()
    if #area == 1 then
        return center + direction
    else
        local arr = {}
        local pos = center + direction * 1.5
        if direction.x < 0 then
            table.insert(arr, pos + Vector2(0, -0.5))
            table.insert(arr, pos + Vector2(0, 0.5))
        elseif direction.x > 0 then
            table.insert(arr, pos + Vector2(0, 0.5))
            table.insert(arr, pos + Vector2(0, -0.5))
        end
        if direction.y < 0 then
            table.insert(arr, pos + Vector2(0.5, 0))
            table.insert(arr, pos + Vector2(-0.5, 0))
        elseif direction.y > 0 then
            table.insert(arr, pos + Vector2(-0.5, 0))
            table.insert(arr, pos + Vector2(0.5, 0))
        end
        return arr
    end
end

--endregion Search

--选择一个可以使用的方向，按照上、右、下、左的顺序选择
function UtilCalcServiceShare:_CalCanUseHitBackDir(defenderEntity, distance)
    local defenderPos = defenderEntity:GridLocation().Position
    for i = 0, 5 do
        --向上
        local targetPos = defenderPos + Vector2(0, distance + i)
        if self:CanHitBackToPos(defenderEntity, targetPos) then
            return Vector2(0, 1), distance + i
        end
        --向右
        targetPos = defenderPos + Vector2(distance + i, 0)
        if self:CanHitBackToPos(defenderEntity, targetPos) then
            return Vector2(1, 0), distance + i
        end
        --向下
        targetPos = defenderPos + Vector2(0, -distance - i)
        if self:CanHitBackToPos(defenderEntity, targetPos) then
            return Vector2(0, -1), distance + i
        end
        --向左
        targetPos = defenderPos + Vector2(-distance - i, 0)
        if self:CanHitBackToPos(defenderEntity, targetPos) then
            return Vector2(-1, 0), distance + i
        end
    end
    return Vector2(0, 0), 0
end

--选择一个可以使用的方向，按照目标点周围一圈8个格子，距离施法者最远的顺序选择
function UtilCalcServiceShare:_CalSelectSquareRingFarest(defenderEntity, casterEntity)
    local defenderPos = defenderEntity:GridLocation().Position
    local casterPos = casterEntity:GridLocation().Position

    --如果施法者有瞬移的技能结果，施法者坐标取瞬移结果的旧坐标
    --（这个击退类型是给象棋马做的，马要先瞬移到玩家位置，再拿瞬移前的坐标计算击退朝向）
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillEffectResult_Teleport[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Teleport)
    if resultArray and table.count(resultArray) > 0 then
        casterPos = resultArray[1]:GetPosOld()
    end

    local bodyArea = defenderEntity:BodyArea():GetArea()
    --默认周围一圈
    local attackRange = ComputeScopeRange.ComputeRange_SquareRing(defenderPos, #bodyArea, 1)

    if table.count(attackRange) > 0 then
        table.sort(
            attackRange,
            function(a, b)
                local disA = Vector2.Distance(casterPos, a)
                local disB = Vector2.Distance(casterPos, b)
                return disA > disB
            end
        )

        for _, pos in ipairs(attackRange) do
            if self:CanHitBackToPos(defenderEntity, pos) then
                local dir = pos - defenderPos
                return dir
            end
        end
    end

    return Vector2(0, 0)
end

--判断位置是否可以击退至指定位置
function UtilCalcServiceShare:CanHitBackToPos(defenderEntity, pos)
    local defenderLocation = defenderEntity:GridLocation()
    local bodyArea = defenderEntity:BodyArea():GetArea()
    --击退到的目标位置
    local targetPosList = {}
    for _, p in ipairs(bodyArea) do
        table.insert(targetPosList, Vector2(pos.x + p.x, pos.y + p.y))
    end
    local useCheckBlockFlag = BlockFlag.HitBack
    if defenderEntity:HasMonsterID() then
        local raceType = defenderEntity:MonsterID():GetMonsterRaceType()
        if MonsterRaceType.Fly == raceType then
            useCheckBlockFlag = BlockFlag.HitBackFly --MSG57290 深渊不阻挡击退飞行怪
        end
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    --判断击退位置是否可用
    for _, p in ipairs(targetPosList) do
        if
            utilData:IsPosBlock(p, useCheckBlockFlag) or
                utilData:IsPosBlockWithEntityRace(p, useCheckBlockFlag, defenderEntity)
         then
            return false
        end
    end
    return true
end

function UtilCalcServiceShare:_CalcHitBack2SpecifyXCoordinate(defenderEntity, xCoordinate)
    local defenderLocation = defenderEntity:GetGridPosition()
    local newPos = Vector2(xCoordinate, defenderLocation.y)
    if not self:CanHitBackToPos(defenderEntity, newPos) then
        newPos = defenderLocation:Clone()
    end
    local dir = Vector2.Normalize(newPos - defenderLocation)
    local distance = math.abs(defenderLocation.x - xCoordinate)
    return dir, distance
end

function UtilCalcServiceShare:_CalcHitBackDir(dirType, attackerPos, defenderPos, attackerBodyArea, defenderBodyArea)
    local dir = nil
    if dirType == HitBackDirectionType.Up then
        dir = Vector2.up
    elseif dirType == HitBackDirectionType.Right then
        dir = Vector2.right
    elseif dirType == HitBackDirectionType.Down then
        dir = Vector2.down
    elseif dirType == HitBackDirectionType.Left then
        dir = Vector2.left
    elseif dirType == HitBackDirectionType.UpDown then
        ---同排时向上 未考虑多格怪对玩家击退的情况 需补充
        if attackerPos.y > defenderPos.y then
            dir = Vector2.down
        else
            dir = Vector2.up
        end
    elseif dirType == HitBackDirectionType.LeftRight then
        ---同列时向左 未考虑多格怪对玩家击退的情况 需补充
        if attackerPos.x > defenderPos.x then
            dir = Vector2.left
        else
            dir = Vector2.right
        end
    elseif dirType == HitBackDirectionType.EightDir then
        ---未考虑玩家对多格怪击退的情况 需补充
        if attackerBodyArea:GetAreaCount() == 1 then
            local posDir = defenderPos - attackerPos
            local victimAreaCount = defenderBodyArea:GetAreaCount()
            if victimAreaCount == 1 then
                dir = Vector2(lmathext.sign(posDir.x), lmathext.sign(posDir.y))
            else
                dir = self:_CalcMultiAreaVictimHitbackDir(attackerPos, defenderPos, attackerBodyArea, defenderBodyArea)
            end
        else
            local bodyArea = attackerBodyArea:GetArea()
            local x, y =
                defenderPos.x - (attackerPos.x + bodyArea[1].x),
                defenderPos.y - (attackerPos.y + bodyArea[1].y)
            for i = 1, #bodyArea do
                if defenderPos.x == attackerPos.x + bodyArea[i].x then
                    x = 0
                end
                if defenderPos.y == attackerPos.y + bodyArea[i].y then
                    y = 0
                end
            end
            dir = Vector2(lmathext.sign(x), lmathext.sign(y))
        end
    elseif dirType == HitBackDirectionType.RightUp then
        dir = Vector2(1, 1)
    elseif dirType == HitBackDirectionType.RightDown then
        dir = Vector2(1, -1)
    elseif dirType == HitBackDirectionType.LeftUp then
        dir = Vector2(-1, 1)
    elseif dirType == HitBackDirectionType.LeftDown then
        dir = Vector2(-1, -1)
    elseif dirType == HitBackDirectionType.AntiEightDir then
        ---未考虑玩家对多格怪击退的情况 需补充
        if attackerBodyArea:GetAreaCount() == 1 then
            local posDir = defenderPos - attackerPos
            local victimAreaCount = defenderBodyArea:GetAreaCount()
            if victimAreaCount == 1 then
                dir = Vector2(lmathext.sign(posDir.x), lmathext.sign(posDir.y))
            else
                dir = self:_CalcMultiAreaVictimHitbackDir(attackerPos, defenderPos, attackerBodyArea, defenderBodyArea)
            end
        else
            local bodyArea = attackerBodyArea:GetArea()
            local x, y =
                defenderPos.x - (attackerPos.x + bodyArea[1].x),
                defenderPos.y - (attackerPos.y + bodyArea[1].y)
            for i = 1, #bodyArea do
                if defenderPos.x == attackerPos.x + bodyArea[i].x then
                    x = 0
                end
                if defenderPos.y == attackerPos.y + bodyArea[i].y then
                    y = 0
                end
            end
            dir = Vector2(lmathext.sign(x), lmathext.sign(y))
        end
    end
    return dir
end
---计算对多格怪8方向的击退
function UtilCalcServiceShare:_CalcMultiAreaVictimHitbackDir(
    attackerPos,
    defenderPos,
    attackerBodyArea,
    defenderBodyArea)
    ---先算四方向
    local targetDirArray = {
        Vector2(0, 1),
        Vector2(1, 0),
        Vector2(0, -1),
        Vector2(-1, 0)
    }

    for _, targetDir in ipairs(targetDirArray) do
        local isMatch = self:_IsMultiAreaVictimInDir(attackerPos, defenderPos, defenderBodyArea, targetDir)
        if isMatch == true then
            return targetDir
        end
    end

    ---再算斜方向
    targetDirArray = {
        Vector2(1, 1),
        Vector2(1, -1),
        Vector2(-1, -1),
        Vector2(-1, 1)
    }
    for _, targetDir in ipairs(targetDirArray) do
        local isMatch = self:_IsMultiAreaVictimInDir(attackerPos, defenderPos, defenderBodyArea, targetDir)
        if isMatch == true then
            return targetDir
        end
    end
    return nil
end
---检查多格怪是否在指定的朝向上
---@param defenderBodyArea BodyAreaComponent
function UtilCalcServiceShare:_IsMultiAreaVictimInDir(attackerPos, defenderPos, defenderBodyArea, targetDir)
    local area = defenderBodyArea:GetArea()
    for _, v in ipairs(area) do
        local curAreaGridPos = defenderPos + v
        local curAreaGridDir = curAreaGridPos - attackerPos
        if curAreaGridDir.x > 0 then
            curAreaGridDir.x = 1
        elseif curAreaGridDir.x < 0 then
            curAreaGridDir.x = -1
        end

        if curAreaGridDir.y > 0 then
            curAreaGridDir.y = 1
        elseif curAreaGridDir.y < 0 then
            curAreaGridDir.y = -1
        end

        if curAreaGridDir == targetDir then
            return true
        end
    end

    return false
end

--计算连线到某个位置的连锁数，依赖机关状态，只能在预览阶段用，逻辑和表现里都不能用！
function UtilCalcServiceShare:GetChainDamageRateAtIndex(chainPath, index)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    local chainRate = 0
    local superGrid = 0
    local poorGrid = 0

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    for i = 2, math.min(index, #chainPath) do
        chainRate = chainRate + 1
        local traps = utilSvc:GetTrapsAtPos(chainPath[i])
        for ii = 1, #traps do
            if not traps[ii]:HasDeadMark() then
                local e = traps[ii]
                ---@type TrapComponent
                local trapComponent = traps[ii]:Trap()
                --碎格子不计数
                if trapComponent:IsBrokenGrid() then
                    chainRate = chainRate - 1
                end
                --强化格子会延迟删除，极光时刻划线需要判断机关是否标记删除了
                if trapComponent:IsSuperGrid() and not e:HasDeadMark() then
                    superGrid = superGrid + 1
                end
                --弱化格子：连线倍率不增加
                if trapComponent:IsPoorGrid() and not e:HasDeadMark() then
                    poorGrid = poorGrid + 1
                end
            end
        end
    end

    --词条修改连线数 在乘以 ChainRate之前
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    if affixService:HasAddChainPathNum() then
        chainRate = affixService:ProcessAddChainPathNum(chainRate)
    end
	
    --buff修改连锁数
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type BuffComponent
    local buffCmpt = teamEntity:BuffComponent()
    local fixChainRate = buffCmpt:GetBuffValue("ChainRate")
    if fixChainRate then
        --向下取整
        chainRate = math.floor(chainRate * fixChainRate)
    end
    
    return chainRate, superGrid, poorGrid
end

---@param damageInfo DamageInfo 伤害数据
--将一个damageInfo 拆分成 damageInfo[]数组
---优先满足后面的伤害，伤害向下取整。
function UtilCalcServiceShare:DamageInfoSplitMultiStage(damageInfo, stageCount, random, randomPercent)
    --每一个变化的数值 （3个伤害，这里存111）
    local damageInfoNewList = {}
    --逐次显示的数值（10个伤害，这里存123）
    local damageStageValueList = {}

    --统一不变的
    local damageType = damageInfo:GetDamageType()
    local attackerEntityId = damageInfo:GetAttackerEntityID() --伤害来源
    local targetEntityId = damageInfo:GetTargetEntityID() --伤害目标
    local isHpShieldGuard = damageInfo:IsHPShieldGuard() --是否血条盾抵挡全部伤害
    local hpShield = damageInfo:GetHPShield() --当前剩余血条盾
    local singlePet = damageInfo:GetSinglePet() --秘境中是否只对一个星灵生效
    local showPosition = damageInfo:GetShowPosition() --伤害飘字的渲染坐标
    local elementType = damageInfo:GetElementType() --元素类型
    local showType = damageInfo:GetShowType() --单体还是格子飘字

    --需要拆分的
    local damageValue = damageInfo:GetDamageValue() --原始伤害,不是显示的掉血值
    -- local changeHP = damageInfo:GetChangeHP() --实际造成的目标血量变化值,显示
    local changeHP = damageInfo:GetDamageValue() --实际造成的目标血量变化值,显示

    local mazeDamageList = damageInfo:GetMazeDamageList() --秘境中对队伍造成伤害后几个星灵的不同伤害值

    --最后一击才显示
    local dropAssetList = damageInfo:GetDropAssetList() --造成的掉落
    local isTriggerHPLock = damageInfo:IsTriggerHPLock() --是否触发锁血
    local isTriggerSecKill = damageInfo:IsTriggerSecKill() --是否触发即死
    local beHitRefreshBuff = damageInfo:GetBeHitRefreshBuff() --在通用被击HandleBeHit的时候可以刷新buff，默认可以刷新
    local playBuffResult = damageInfo:GetPlayBuffResult() --在通用被击的时候 只播放指定的buffResult，而不是播放所有

    --处理存在疑问，目前不处理，保持不变
    local comboCount = damageInfo:GetComboCount() --当时的combo数
    local shieldLayer = damageInfo:GetShieldLayer() --当时的盾层数

    -------

    --每一份变化的
    local changeHPEach = math.floor(changeHP / stageCount)
    --变化HP列表
    local changeHPList = {}
    --剩余的HP
    local changeHPremain = changeHP

    for i = 1, stageCount - 1 do
        --本次改变的血量
        local changeHpNew = changeHPEach

        if random == 1 then
            local randomHp = math.floor(changeHPEach * math.random(-randomPercent, randomPercent) / 100)
            changeHpNew = changeHpNew + randomHp
        end

        --如果本次的伤害大于剩余所有血量
        --因为这个表现是做给伤害的 伤害是负值 所以用小于
        if changeHpNew > changeHPremain then
            changeHpNew = changeHPremain
        end

        changeHPremain = changeHPremain - changeHpNew
        table.insert(changeHPList, changeHpNew)

        local showDamage = math.abs(changeHP - changeHPremain)
        if showDamage < 1 then
            showDamage = 1
        end

        table.insert(damageStageValueList, showDamage)
    end

    table.insert(changeHPList, changeHPremain)
    table.insert(damageStageValueList, damageInfo:GetDamageValue())

    --[[
    for i = 1, stageCount do
        --本次改变的血量
        local changeHpNew = changeHPList[i]
        ---@type DamageInfo
        local damageInfoNew = DamageInfo:New(changeHpNew, damageType)
        damageInfoNew:SetChangeHP(-changeHpNew)
        local setChangeHp = -changeHpNew
        damageInfoNew:SetMazeDamageList(mazeDamageList)
        damageInfoNew:SetAttackerEntityID(attackerEntityId)
        damageInfoNew:SetTargetEntityID(targetEntityId)
        damageInfoNew:SetHPShield(hpShield)
        damageInfoNew:SetHPShieldGuard(isHpShieldGuard)

        if hpShield and hpShield > 0 then
            --算血
            local damageOnHP = changeHpNew
            --血条盾
            local shieldCostDamage

            local curShield = hpShield - changeHpNew
            if curShield > 0 then
                shieldCostDamage = changeHpNew
            else
                shieldCostDamage = hpShield
            end

            --护盾被减到0，移除
            if curShield <= 0 then
                curShield = 0
            end

            --因为是阶段伤害 血条盾要赋值
            hpShield = curShield

            local isHPShieldGuard = shieldCostDamage == damageOnHP
            damageOnHP = damageOnHP - shieldCostDamage

            damageInfoNew:SetHPShield(curShield)
            damageInfoNew:SetHPShieldGuard(isHPShieldGuard)
            damageInfoNew:SetChangeHP(-damageOnHP)
        end

        damageInfoNew:SetSinglePet(singlePet)
        damageInfoNew:SetElementType(elementType)
        damageInfoNew:SetShowPosition(showPosition)
        damageInfoNew:SetShowType(showType)

        damageInfoNew:SetComboCount(comboCount)
        damageInfoNew:SetShieldLayer(shieldLayer)

        table.insert(damageInfoNewList, damageInfoNew)
    end
    ---@type DamageInfo
    local damageInfoLast = damageInfoNewList[stageCount]
    damageInfoLast:SetDropAssetList(dropAssetList)
    damageInfoLast:SetTriggerHPLock(isTriggerHPLock)
    damageInfoLast:SetTriggerSecKill(isTriggerSecKill)
    damageInfoLast:SetBeHitRefreshBuff(beHitRefreshBuff)
    damageInfoLast:SetPlayBuffResult(playBuffResult)
]]
    --最新处理 只显示最后一个伤害
    damageInfoNewList = {}
    table.insert(damageInfoNewList, damageInfo)

    return damageInfoNewList, damageStageValueList
end

---@param casterPosList Vector2[]
---@param targetPos Vector2
---@param hitBackType HitBackDirectionType
---@return Vector2
function UtilCalcServiceShare:GetHitBackPlayerFarthestPos(casterPosList,casterEntity,hitBackType, teamEntity)
    if table.count(casterPosList) == 1 then
        return casterPosList[1]
    end
    ---@type SkillEffectCalcService
    local  skillEffectService = self._world:GetService("SkillEffectCalc")
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local sortHitBackDistanceList = {}
    local playerPos = teamEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = casterEntity:BodyArea()
    ---@type BodyAreaComponent
    local defenderBodyAreaCmpt = teamEntity:BodyArea()
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    local maxLen = boardSvc:GetCurBoardMaxLen()
    local casterPos = casterEntity:GetGridPosition()
    ---这里要先去掉施法者的阻挡保证计算结果的正确，计算完再加回去
    local bodyArea, blockFlag = boardSvc:RemoveEntityBlockFlag(casterEntity, casterPos)
    for i,  attackerPos in ipairs(casterPosList) do
        local dir = utilCalcSvc:_CalcHitBackDir(hitBackType, attackerPos, playerPos, bodyAreaCmpt, defenderBodyAreaCmpt)
        local targetPos = skillEffectService:CalHitbackPosByEntityDir(playerPos,defenderBodyAreaCmpt,dir,maxLen,{},nil,teamEntity)
        table.insert(sortHitBackDistanceList,{dis = Vector2.Distance(targetPos,attackerPos),pos=attackerPos })
    end
    boardSvc:SetEntityBlockFlag(casterEntity, casterPos, blockFlag)
    boardSvc:RemoveEntityBlockFlag(casterEntity,casterPos)
    table.sort(sortHitBackDistanceList,function(a,b)
        return a.dis > b.dis
    end )
    return sortHitBackDistanceList[1].pos
end

function UtilCalcServiceShare:CalcBattleResult(matchType,victory)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    return battleService:CalcBattleResultLogic(matchType,victory)
end

function UtilCalcServiceShare:GetDirAndGetDistance(dirType,distance,i)
    --向上
    if dirType == HitBackDirectionType.Up then
        return Vector2(0, 1),Vector2(0, distance + i)
    end
    --左上
    if dirType == HitBackDirectionType.LeftUp then
        return Vector2(-1, 1),Vector2(-distance - i, distance + i)
    end
    --右上
    if dirType == HitBackDirectionType.RightUp then
        return Vector2(1, 1),Vector2(distance + i, distance + i)
    end

    --向左
    if dirType == HitBackDirectionType.Left then
        return Vector2(-1, 0),Vector2(-distance - i, 0)
    end
    --向右
    if dirType == HitBackDirectionType.Right then
        return Vector2(1, 0),Vector2(distance + i, 0)
    end
    --左下
    if dirType == HitBackDirectionType.LeftDown then
        return Vector2(-1, -1),Vector2(-distance - i, -distance - i)
    end
    --右下
    if dirType == HitBackDirectionType.RightDown then
        return Vector2(1, -1),Vector2(distance + i, -distance - i)
    end
    --向下
    if dirType == HitBackDirectionType.Down then
        return Vector2(0, -1),Vector2(0, -distance - i)
    end
end

function UtilCalcServiceShare:_VectorDirToHitBackEnum(dirVector)
    if dirVector == Vector2(0, 1) then
        return HitBackDirectionType.Up
    end
    if dirVector == Vector2(0, -1) then
        return HitBackDirectionType.Down
    end
    if dirVector == Vector2(-1, 0) then
        return HitBackDirectionType.Left
    end
    if dirVector == Vector2(1, 0) then
        return HitBackDirectionType.Right
    end
    if dirVector == Vector2(1, 1) then
        return HitBackDirectionType.RightUp
    end
    if dirVector == Vector2(-1, 1) then
        return HitBackDirectionType.LeftUp
    end
    if dirVector == Vector2(-1, -1) then
        return HitBackDirectionType.LeftDown
    end
    if dirVector == Vector2(1, -1) then
        return HitBackDirectionType.RightDown
    end
    return HitBackDirectionType.None
end

--选择一个可以使用的方向，上,左上,右上,左,右,左下,右下,下,的顺序选择
function UtilCalcServiceShare:_CalCanUseHitBackDir8(attackDir,defenderEntity, distance)
    local List= {}
    List[HitBackDirectionType.Up] = {HitBackDirectionType.Up,HitBackDirectionType.LeftUp,HitBackDirectionType.RightUp,HitBackDirectionType.Left,HitBackDirectionType.Right,HitBackDirectionType.LeftDown,HitBackDirectionType.RightDown,HitBackDirectionType.Down}
    List[HitBackDirectionType.Down] = {HitBackDirectionType.Down,HitBackDirectionType.RightDown,HitBackDirectionType.LeftDown,HitBackDirectionType.Right,HitBackDirectionType.Left,HitBackDirectionType.RightUp,HitBackDirectionType.LeftUp,HitBackDirectionType.Up}
    List[HitBackDirectionType.Left] = {HitBackDirectionType.Left,HitBackDirectionType.LeftDown,HitBackDirectionType.LeftUp,HitBackDirectionType.Down,HitBackDirectionType.Up,HitBackDirectionType.RightDown,HitBackDirectionType.RightUp,HitBackDirectionType.Right}
    List[HitBackDirectionType.Right] = {HitBackDirectionType.Right,HitBackDirectionType.RightUp,HitBackDirectionType.RightDown,HitBackDirectionType.Up,HitBackDirectionType.Down,HitBackDirectionType.LeftUp,HitBackDirectionType.LeftDown,HitBackDirectionType.Left}
    local defenderPos = defenderEntity:GridLocation().Position
    local dirEnum = self:_VectorDirToHitBackEnum(attackDir)
    if not List[dirEnum] then
        Log.exception("Attack Dir:", tostring(attackDir)," Invalid")
        return Vector2(0, 0), 0
    end

    for i = 0, 5 do
        for index, v in ipairs(List[dirEnum]) do
            local dir,add = self:GetDirAndGetDistance(v,distance,i)
            local targetPos = defenderPos + add
            if self:CanHitBackToPos(defenderEntity, targetPos) then
                Log.debug("Attack Dir:",tostring(attackDir),"HitBack Dir:", tostring(dir)," Index:",index)
                return dir, distance+i
            end
        end

    end
    return Vector2(0, 0), 0
end

--初始化攻击方向，然后选择一个可以使用的方向
function UtilCalcServiceShare:CalSelectCanUseDirAndDis(attackDir, defenderEntity, distance)
    local tempDir = HitBackDirectionTypeHelper.NormalizeDirType(attackDir)
    local List = {}
    List[HitBackDirectionType.Up] = { HitBackDirectionType.Up, HitBackDirectionType.LeftUp, HitBackDirectionType.RightUp, HitBackDirectionType.Left, HitBackDirectionType.Right, HitBackDirectionType.LeftDown, HitBackDirectionType.RightDown, HitBackDirectionType.Down }
    List[HitBackDirectionType.Down] = { HitBackDirectionType.Down, HitBackDirectionType.RightDown, HitBackDirectionType.LeftDown, HitBackDirectionType.Right, HitBackDirectionType.Left, HitBackDirectionType.RightUp, HitBackDirectionType.LeftUp, HitBackDirectionType.Up }
    List[HitBackDirectionType.Left] = { HitBackDirectionType.Left, HitBackDirectionType.LeftDown, HitBackDirectionType.LeftUp, HitBackDirectionType.Down, HitBackDirectionType.Up, HitBackDirectionType.RightDown, HitBackDirectionType.RightUp, HitBackDirectionType.Right }
    List[HitBackDirectionType.Right] = { HitBackDirectionType.Right, HitBackDirectionType.RightUp, HitBackDirectionType.RightDown, HitBackDirectionType.Up, HitBackDirectionType.Down, HitBackDirectionType.LeftUp, HitBackDirectionType.LeftDown, HitBackDirectionType.Left }
    List[HitBackDirectionType.LeftUp] = { HitBackDirectionType.LeftUp, HitBackDirectionType.Left, HitBackDirectionType.Up, HitBackDirectionType.LeftDown, HitBackDirectionType.RightUp, HitBackDirectionType.Down, HitBackDirectionType.Right, HitBackDirectionType.RightDown }
    List[HitBackDirectionType.RightUp] = { HitBackDirectionType.RightUp, HitBackDirectionType.Up, HitBackDirectionType.Right, HitBackDirectionType.LeftUp, HitBackDirectionType.RightDown, HitBackDirectionType.Left, HitBackDirectionType.Down, HitBackDirectionType.LeftDown }
    List[HitBackDirectionType.LeftDown] = { HitBackDirectionType.LeftDown, HitBackDirectionType.Down, HitBackDirectionType.Left, HitBackDirectionType.RightDown, HitBackDirectionType.LeftUp, HitBackDirectionType.Right, HitBackDirectionType.Up, HitBackDirectionType.RightUp }
    List[HitBackDirectionType.RightDown] = { HitBackDirectionType.RightDown, HitBackDirectionType.Right, HitBackDirectionType.Down, HitBackDirectionType.RightUp, HitBackDirectionType.LeftDown, HitBackDirectionType.Up, HitBackDirectionType.Left, HitBackDirectionType.leftup }
    local defenderPos = defenderEntity:GridLocation().Position
    local dirEnum = self:_VectorDirToHitBackEnum(tempDir)
    if not List[dirEnum] then
        Log.exception("Attack Dir:", tostring(tempDir), " Invalid")
        return Vector2(0, 0), 0
    end

    for i = 0, 9 do
        for index, v in ipairs(List[dirEnum]) do
            local dir, add = self:GetDirAndGetDistance(v, distance, i)
            local targetPos = defenderPos + add
            if self:CanHitBackToPos(defenderEntity, targetPos) then
                Log.debug("Attack Dir:", tostring(tempDir), "HitBack Dir:", tostring(dir), " Index:", index)
                return dir, distance + i
            end
        end

    end
    return Vector2(0, 0), 0
end

---N23棺材娘技能专用，参见https://wiki.h3d.com.cn/pages/viewpage.action?pageId=74768251
---初版需要计算，后来发现其实不需要，attackDir就是施法者的逻辑方向，在技能范围为三行十字，且击退前先转身的需求下，不需要额外处理
---@param attackerPos Vector2
---@param attackDir Vector2
---@param defenderEntity Entity
---@param distance number
function UtilCalcServiceShare:CalCoffinMusumeHitbackDirAndDis(attackerPos, attackDir, defenderEntity, distance)
    return attackDir, distance
end

---@param attackerPos Vector2
---@param attackDir Vector2
---@param defender Entity
---@param distance number
function UtilCalcServiceShare:CalcHitBackFront3Dir(attackerPos, attackerDir, defender, distance, casterEntity)
    local hitBackDirList
    if attackerDir == Vector2.up then
        hitBackDirList = { Vector2.up, Vector2.left, Vector2.right}
    elseif attackerDir == Vector2.left then
        hitBackDirList = { Vector2.up, Vector2.left, Vector2.down}
    elseif attackerDir == Vector2.down then
        hitBackDirList = { Vector2.down, Vector2.left, Vector2.right}
    elseif attackerDir == Vector2.right then
        hitBackDirList = { Vector2.up, Vector2.down, Vector2.right}
    end

    --if attackerDir == Vector2(0,1) then
    --    hitBackDirList = { Vector2(0,1), Vector2(-1,0),Vector2(0,-1)}
    --elseif attackerDir == Vector2(-1,0) then
    --    hitBackDirList = { Vector2(0,1), Vector2(-1,0), Vector2(1,0)}
    --elseif attackerDir == Vector2(0,-1) then
    --    hitBackDirList = { Vector2(1,0), Vector2(-1,0), Vector2(0,-1)}
    --elseif attackerDir == Vector2(1,0) then
    --    hitBackDirList = { Vector2(0,1), Vector2(1,0), Vector2(0,-1)}
    --end

    ---@type UtilScopeCalcServiceShare
    local utilScope =  self._world:GetService("UtilScopeCalc")

    local defenderPos = defender:GetGridPosition()
    for i, dir in ipairs(hitBackDirList) do
       local hitbackPos = defenderPos + dir
        if not utilScope:IsPosBlock(hitbackPos,BlockFlag.HitBack) then
            Log.fatal("Return Dir:",dir,"hitbackPos:",hitbackPos)
            return dir
        end
    end
    Log.fatal("Return Dir Nil")
end

--初始化攻击方向，然后选择一个可以使用的方向
---@param attackerPos Vector2
---@param attackerBodyArea BodyAreaComponent
---@param defenderPos Vector2
---@return Vector2
function UtilCalcServiceShare:CalcHitBackAttackFront2Edge(attackerPos, attackerBodyArea, defenderPos)
    local posMain = defenderPos
    local endPos = attackerPos
    local bodyArea = attackerBodyArea:GetArea()
    local posList = {}
    for _, v in ipairs(bodyArea) do
        table.insert(posList, endPos + v)
    end
    --确定朝向
    local preDashDir = { Vector2(0, -1), Vector2(-1, 0), Vector2(0, 1), Vector2(1, 0) } --上右下左位置时的方向
    for _, pos in ipairs(posList) do
        local mountDir = Vector2.Normalize(posMain - pos)
        for i, v in ipairs(preDashDir) do
            if v.x == mountDir.x and v.y == mountDir.y then
                return v
            end
        end
    end
    Log.fatal("未确定朝向！！！！！！！！")
    return preDashDir[1]
end

function UtilCalcServiceShare:CalEightDirAndCasterAround(casterEntity, defenderEntity, distance)
    local casterPos = casterEntity:GridLocation().Position
    local casterBodyArea = casterEntity:BodyArea():GetArea()

    local defenderPos = defenderEntity:GridLocation().Position
    local bodyArea = defenderEntity:BodyArea():GetArea()

    --默认周围一圈
    local attackRange = ComputeScopeRange.ComputeRange_SquareRing(defenderPos, #bodyArea, 1)
    if table.count(attackRange) > 0 then
        table.sort(
            attackRange,
            function(a, b)
                local disA = Vector2.Distance(defenderPos, a)
                local disB = Vector2.Distance(defenderPos, b)
                return disA < disB
            end
        )

        for _, pos in ipairs(attackRange) do
            if self:CanHitBackToPos(defenderEntity, pos) then
                local dir = pos - defenderPos
                return dir, distance
            end
        end
    end

    --目标周围一圈没有可以击退的点,从施法者周围找一圈
    local attackRange = ComputeScopeRange.ComputeRange_SquareRing(casterPos, #casterBodyArea, 1)
    if table.count(attackRange) > 0 then
        table.sort(
            attackRange,
            function(a, b)
                local disA = Vector2.Distance(defenderPos, a)
                local disB = Vector2.Distance(defenderPos, b)
                return disA < disB
            end
        )

        for _, pos in ipairs(attackRange) do
            if self:CanHitBackToPos(defenderEntity, pos) then
                local dir = pos - defenderPos
                local newDistance = Vector2.Distance(defenderPos, pos)
                return dir, newDistance
            end
        end
    end

    return Vector2(0, 0), 0
end

local crossDirs = { Vector2.left, Vector2.right, Vector2.up, Vector2.down }
local rotateCrossDirs = { Vector2.New(1, 1), Vector2.New(1, -1), Vector2.New(-1, 1), Vector2(-1, -1) }

---@param defenderEntity Entity
function UtilCalcServiceShare:CalButterflyHitBackDirAndDistance(casterEntity, defenderEntity)
    local defenderEntityPos = defenderEntity:GetGridPosition()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    --优先情况1：十字找一个格子，距离为1
    for _, dir in ipairs(crossDirs) do
        local v2 = defenderEntityPos + dir
        if utilData:IsValidPiecePos(v2) and (not utilData:IsPosBlock(v2, BlockFlag.LinkLine)) then
            return dir, 1
        end
    end
    --优先情况2：斜四向找一个格子，距离还是1
    for _, dir in ipairs(rotateCrossDirs) do
        local v2 = defenderEntityPos + dir
        if utilData:IsValidPiecePos(v2) and (not utilData:IsPosBlock(v2, BlockFlag.LinkLine)) then
            return dir, 1
        end
    end
    --保底情况(据说基本不会出现)：去外圈找一个位置，距离以目标点为准
    local maxEdge = math.max(utilData:GetCurBoardMaxX(), utilData:GetCurBoardMaxY())
    for i = 2, maxEdge do
        for _, dir in ipairs(crossDirs) do
            local v2 = defenderEntityPos + dir * i
            if utilData:IsValidPiecePos(v2) and (not utilData:IsPosBlock(v2, BlockFlag.LinkLine)) then
                return dir, i
            end
        end
        for _, dir in ipairs(rotateCrossDirs) do
            local v2 = defenderEntityPos + dir * i
            if utilData:IsValidPiecePos(v2) and (not utilData:IsPosBlock(v2, BlockFlag.LinkLine)) then
                return dir, i
            end
        end
    end

    return Vector2.zero, 0
end

---@param monsterEntity Entity
function UtilCalcServiceShare:GetMonsterMove2PlayerNearestPath(monsterEntity,enableAnyPiece)
    ---@type Entity
    local teamEntity = monsterEntity:AI():GetTargetTeamEntity()
    ---@type Vector2
    local playerPos = teamEntity:GetGridPosition()
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    local monsterPos = monsterEntity:GetGridPosition()
    local retPath ={}
    local retPieceType = nil
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    for x = -1, 1 do
        for y = -1, 1 do
            local startPos = Vector2(monsterPos.x+x,monsterPos.y+y)
            if (startPos.x ~=monsterPos.x or startPos.y ~=monsterPos.y)
                    and utilDataSvc:IsValidPiecePos(startPos) and
                    not boardSvc:IsPosBlock(startPos,BlockFlag.LinkLine) then
                local pieceType = board:GetPieceType(startPos)
                if not enableAnyPiece and pieceType == PieceType.Any then
                    goto CONTINUE
                end
                local getPosValidAroundFunc = function(pos, type)
                    return self:GetPosValidAround(pos, type, enableAnyPiece)
                end
                local path = self:CalcPos2PosShortestPath(startPos, playerPos, pieceType, getPosValidAroundFunc, getPosValidAroundFunc)
                if path and #path > 0 then
                    if #retPath == 0 then
                        retPath = path
                        retPieceType = pieceType
                    end
                    if #path < #retPath then
                        retPath = path
                        retPieceType = pieceType
                    end
                end
                ::CONTINUE::
            end
        end
    end
    return retPath,retPieceType
end

---@param pos Vector2
---@param targetPos Vector2
---@return number
function UtilCalcServiceShare:CalcH(pos,targetPos)
    ---@type number
    local ret = Vector2.Distance(pos,targetPos)
    return math.floor(ret*10)
end

_class("AStarInfo", Object)
---@class AStarInfo: Object
AStarInfo = AStarInfo
function AStarInfo:Constructor(myPos,value,prePos)
    self._prePos = prePos
    self._myPos = myPos
    self._value = value
end

function AStarInfo:GetPrePoint()
    return self._prePos
end

function AStarInfo:GetMyPos()
    return self._myPos
end
---@param info1 AStarInfo
---@param info2 AStarInfo
function AStarInfo.Sort(info1,info2)
    if  info1._value <info2._value then
        return 1
    elseif info1._value > info2._value then
        return -1
    elseif info1._value == info2._value then
        local pos1= Vector2.Pos2Index(info1:GetMyPos())
        local pos2= Vector2.Pos2Index(info2:GetMyPos())
        if pos1 < pos2 then
            return 1
        elseif pos1 < pos2 then
            return -1
        else
            return 0
        end
    end

    return 0
end

---@param pos Vector2
---@param pieceType PieceType
---@return Vector2[]
function UtilCalcServiceShare:GetPosValidAround(pos,pieceType,enableAnyPiece)
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    local aroundList = ComputeScopeRange.ComputeRange_SquareRing(pos, 1, 1)
    ----@type Vector2
    local ret={}
    for i, aroundPos  in ipairs(aroundList) do

        local posPieceType = board:GetPieceType(aroundPos)
        if utilDataSvc:IsValidPiecePos(aroundPos)
                and not boardSvc:IsPosBlock(aroundPos,BlockFlag.LinkLine)
        then
            if enableAnyPiece then
                if posPieceType ~= pieceType and posPieceType ~= PieceType.Any then
                    goto CONTINUE
                end
            else
                if posPieceType ~= pieceType then
                    goto CONTINUE
                end
            end
            table.insert(ret,aroundPos)
        end
        ::CONTINUE::
    end
    return ret
end

function UtilCalcServiceShare:IsInOpenList(pos, startList)
    for i, info in ipairs(startList.elements) do
        if info:GetMyPos() == pos then
            return true
        end
    end
    return false
end

---@param aStarInfo AStarInfo
---@param closeList AStarInfo[]
function UtilCalcServiceShare:PosInList(aStarInfo,pos2,pieceType,openList,closeList,GetPosValidAroundFunc)
    local pos1 = aStarInfo:GetMyPos()

    local pos1Around = GetPosValidAroundFunc(pos1,pieceType)
    for i, pos in ipairs(pos1Around) do
        local canInsert = true
        for i, info  in ipairs(closeList) do
            local myPos =info:GetMyPos()
            if myPos.x == pos.x and myPos.y == pos.y then
                canInsert =false
                break
            end
        end
        if canInsert and not self:IsInOpenList(pos,openList)  then
            ---@type AStarInfo
            local info = AStarInfo:New(pos,self:CalcH(pos,pos2),aStarInfo)
            openList:Insert(info)
            --Log.fatal("Ins OpenList:",pos)
        end
    end
end

---@return Vector2[]
---@param endPos AStarInfo
function UtilCalcServiceShare:GetPath(endPos)
    local tmp = endPos
    ---@type Vector2[]
    local ret = {}
    while tmp do
        local pos = tmp:GetMyPos()
        table.insert(ret,1,pos)
        tmp = tmp:GetPrePoint()
    end
    return ret
end

---计算两个点之间最短可连通的连线
---@param pos1 Vector2
---@param pos2 Vector2
function UtilCalcServiceShare:CalcPos2PosShortestPath(pos1, pos2, pieceType, GetFinalPosValidAroundFunc,GetPosValidAroundFunc)
    ---@type SortedArray
    local openList =SortedArray:New(Algorithm.COMPARE_CUSTOM,AStarInfo.Sort)
    ---@type AStarInfo[]
    local closeList = {}

    local find = false

    local startInfo = AStarInfo:New(pos1,self:CalcH(pos1,pos2),nil)
    local endInfo = nil
    openList:Insert(startInfo)


    local finalPosList = GetFinalPosValidAroundFunc(pos2,pieceType)
    if #finalPosList ==0 then
        return {}
    end

    ---for i, pos in ipairs(finalPosList) do
    ----    Log.fatal("FinalPosList:",pos)
    ----end

    ---Log.fatal("StartInfoPos:",startInfo:GetMyPos())
    while not openList:Empty() do
        for i, info in ipairs(openList.elements) do
            if  table.Vector2Include(finalPosList, info:GetMyPos()) then
                find= true
                endInfo = info
                break
            end
        end
        if find then
            break
        end
        ---@type AStarInfo
        local info = openList:GetFirstElement()
        ---Log.fatal("RemoveInfoPos:",info:GetMyPos())
        openList:Remove(info)
        table.insert(closeList,info)
        self:PosInList(info,pos2,pieceType,openList,closeList, GetPosValidAroundFunc)
    end
    local retList =self:GetPath(endInfo)
    return retList
end
---@param skillRange Vector2[]
---@param defender Entity
function UtilCalcServiceShare:_CalcNearestPosOutOfRange(skillRange,defender)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local boardMaxLen = boardServiceLogic:GetCurBoardMaxLen()
    local defenderPos = defender:GridLocation().Position
    for i = 0,boardMaxLen do
        for x =-1, 1 do
            for y =1, -1 , -1 do
                local pos = Vector2(defenderPos.x+x*i,defenderPos.y+y*i)
                if not table.Vector2Include(skillRange,pos) then
                    if self:CanHitBackToPos(defender,pos) then
                        local dir = pos -defenderPos
                        --Log.fatal("SourceDir:",dir,"Distance: ",i)
                        dir = Vector2(dir.x/i,dir.y/i)
                        --Log.fatal("Dir:", tostring(dir))
                        return dir,i
                    end
                end
            end
        end
    end
    Log.exception("Not Find Dir And Distance")
end

function UtilCalcServiceShare:GetGridPathByVectorLerp(posBegin, posEnd)
    local beginX = posBegin.x
    local endX = posEnd.x
    local beginY = posBegin.y
    local endY = posEnd.y

    local vFirst = Vector2.New(posBegin.x, posBegin.y)
    local vLast = Vector2.New(posEnd.x, posEnd.y)

    local vDirection = vLast - vFirst
    local lerpXToY = (math.abs(vDirection.x) >= math.abs(vDirection.y))

    local independentVar = 0
    local maxIndependentVar = 0
    
    -- 向量插值需要确定x和y哪个是自变量，通过自变量来插值出每个点的另一个坐标
    local step = 1
    if lerpXToY then
        if beginX < endX then
            independentVar = beginX + 0.5
            maxIndependentVar = endX - 0.5

            step = 1
        else
            independentVar = beginX - 0.5
            maxIndependentVar = endX + 0.5

            step = -1
        end
    else
        if beginY < endY then
            independentVar = beginY + 0.5
            maxIndependentVar = endY - 0.5

            step = 1
        else
            independentVar = beginY - 0.5
            maxIndependentVar = endY + 0.5

            step = -1
        end
    end

    ---@type MathService
    local mathService = self._world:GetService("Math")

    local intersections = {}
    for idv = independentVar, maxIndependentVar, step do
        if lerpXToY then
            table.insert(intersections, {x = idv, y = mathService:LerpGetY(vFirst, vLast, idv)})
        else
            table.insert(intersections, {x = mathService:LerpGetX(vFirst, vLast, idv), y = idv})
        end
    end

    local path = {vFirst}
    for index = 1, #intersections - 1 do
        local intersection1 = intersections[index]
        local intersection2 = intersections[index + 1]

        local points = self:_GetPassedGridPositionByIntersections(intersection1, intersection2)
        for _, pos in ipairs(points) do
            if not table.icontains(path, pos) then
                table.insert(path, pos)
            end
        end
    end

    table.insert(path, vLast)

    local snappedPath = self:_SnapContinuousPath(path)

    local t = {}
    for _, v2 in ipairs(snappedPath) do
        if not table.icontains(t, v2) then
            table.insert(t, v2)
        end
    end
    return t
end

function UtilCalcServiceShare:_GetPassedGridPositionByIntersections(intersection1, intersection2)
    local x1 = intersection1.x
    local y1 = intersection1.y
    local x2 = intersection2.x
    local y2 = intersection2.y

    local grid1 = Vector2.zero
    local grid2 = Vector2.zero

    ---MSG56257 四舍五入导致路线不符合预期，改为根据交点坐标差决定连线各点的收缩方位
    if (x2 - x1) > 0 then
        grid1.x = math.floor(x1 + 0.5)
        grid2.x = math.floor(x2 + 0.5)
    else
        grid1.x = math.ceil(x1 - 0.5)
        grid2.x = math.ceil(x2 - 0.5)
    end

    if (y2 - y1) > 0 then
        grid1.y = math.floor(y1 + 0.5)
        grid2.y = math.floor(y2 + 0.5)
    else
        grid1.y = math.ceil(y1 - 0.5)
        grid2.y = math.ceil(y2 - 0.5)
    end

    local blocks = {}

    if (grid1 == grid2) then
        table.insert(blocks, grid1)
    else
        table.insert(blocks, grid1)
        table.insert(blocks, grid2)
    end

    return blocks
end

---@param dir Vector2
local function GetLogicDirection(dir)
    local ret = Vector2.zero
    if dir.x > 0 then
        ret.x = 1
    elseif dir.x < 0 then
        ret.x = -1
    end

    if dir.y > 0 then
        ret.y = 1
    elseif dir.y < 0 then
        ret.y = -1
    end

    return ret
end

-- 保证路线中不出现斜向移动
function UtilCalcServiceShare:_SnapContinuousPath(path)
    local finalPath = {}
    for index, pos in ipairs(path) do
        if index ~= 1 then
            local lastPos = finalPath[#finalPath]
            local distance = Vector2.Distance(lastPos, pos)
            if distance <= 1 then
                table.insert(finalPath, pos)
            else
                local dir = GetLogicDirection(lastPos - pos)
                while (dir ~= Vector2.zero) do
                    if dir.x ~= 0 and dir.y ~= 0 then
                        table.insert(finalPath, Vector2.New(pos.x, lastPos.y))
                    else
                        table.insert(finalPath, lastPos - dir)
                    end

                    lastPos = finalPath[#finalPath]
                    dir = GetLogicDirection(lastPos - pos)
                end
            end
        else
            table.insert(finalPath, pos)
        end
    end
    return finalPath
end

function UtilCalcServiceShare:SaveSyncLog()
    local syncSvc = self._world:GetService("SyncLogic")
    syncSvc:DumpSyncLog()
    self._world:GetMatchLogger():SaveMatchLog()
end

---可连万色格子，会被阻挡连线和坏格子阻挡
---@param pos Vector2
---@param pieceType PieceType
---@return Vector2[]
function UtilCalcServiceShare:ChessMonsterMoveGetFinalPosValidAround(pos,pieceType)
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    local aroundList = {}--ComputeScopeRange.ComputeRange_SquareRing(pos, 1, 1)
    ----@type Vector2
    local ret={}
    table.insert(aroundList,Vector2(pos.x+1,pos.y))
    table.insert(aroundList,Vector2(pos.x-1,pos.y))
    table.insert(aroundList,Vector2(pos.x,pos.y+1))
    table.insert(aroundList,Vector2(pos.x,pos.y-1))
    ---Log.fatal("FinalPos SourcePos:",pos)
    for i, aroundPos  in ipairs(aroundList) do
        if utilDataSvc:IsValidPiecePos(aroundPos)
                and (board:GetPieceType(aroundPos) == pieceType or board:GetPieceType(aroundPos) == PieceType.Any)
                and not boardSvc:IsPosBlock(aroundPos,BlockFlag.LinkLine)
                and not utilDataSvc:IsPosHasSpTrap(aroundPos,TrapType.BadGrid)
        then
            table.insert(ret,aroundPos)
            ---Log.fatal("FinalPos AddAroundPos:",aroundPos)
        end
    end
    return ret
end

---可连万色格子，会被阻挡连线和坏格子阻挡
---@param pos Vector2
---@param pieceType PieceType
---@return Vector2[]
function UtilCalcServiceShare:ChessMonsterMoveGetPosValidAround(pos,pieceType)
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    local aroundList = ComputeScopeRange.ComputeRange_SquareRing(pos, 1, 1)
    ----@type Vector2
    local ret={}

   --- Log.fatal("SourcePos:",pos)
    for i, aroundPos  in ipairs(aroundList) do
        if utilDataSvc:IsValidPiecePos(aroundPos)
                and (board:GetPieceType(aroundPos) == pieceType or board:GetPieceType(aroundPos) == PieceType.Any)
                and not boardSvc:IsPosBlock(aroundPos,BlockFlag.LinkLine)
                and not utilDataSvc:IsPosHasSpTrap(aroundPos,TrapType.BadGrid)
        then
            table.insert(ret,aroundPos)
            ---Log.fatal("AddAroundPos:",aroundPos)
        end
    end
    return ret
end



---@param casterEntity Entity
---@param targetID number
---@param element PieceType
function UtilCalcServiceShare:GetMonster2TargetNearestPathByElement(casterEntity, targetID, element)
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    ---@type Vector2
    local targetCenterPos    = targetEntity:GetGridPosition()
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    local casterPos = casterEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = targetEntity:BodyArea()
    local monsterPosList = {}
    for i, area in ipairs(bodyAreaCmpt:GetArea()) do
        local pos = Vector2(targetCenterPos.x+area.x, targetCenterPos.y+area.y)
        table.insert(monsterPosList,pos)
    end
    local retPath ={}
    local retPieceType = nil
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc= self._world:GetService("UtilScopeCalc")

    local bTargetCanConnect = false

    for i, pos in ipairs(monsterPosList) do
        local ret =  self:ChessMonsterMoveGetFinalPosValidAround(pos,type)
        if #ret >0 then
            bTargetCanConnect = true
            break
        end
    end


    ---尝试用A*找一条能连通的路
    if bTargetCanConnect then
        local getFinalValidPosFunc = function(pos,type)
            return self:ChessMonsterMoveGetFinalPosValidAround(pos,type)
        end
        local getAroundValidPosFunc = function(pos,type)
            return self:ChessMonsterMoveGetPosValidAround(pos,type)
        end
        for i, targetPos in ipairs(monsterPosList) do
            for x = -1, 1 do
                for y = -1, 1 do
                    local startPos = Vector2(casterPos.x+x,casterPos.y+y)
                    if (startPos.x ~=casterPos.x or startPos.y ~=casterPos.y)
                            and utilDataSvc:IsValidPiecePos(startPos) and
                            not boardSvc:IsPosBlock(startPos,BlockFlag.LinkLine) and
                            not utilDataSvc:IsPosHasSpTrap(startPos,TrapType.BadGrid) then
                        local pieceType = board:GetPieceType(startPos)
                        if pieceType == PieceType.Any or pieceType == element then
                            local path = self:CalcPos2PosShortestPath(startPos,targetPos,pieceType,getFinalValidPosFunc,getAroundValidPosFunc)
                            if path and #path >0 then
                                if #retPath == 0 then
                                    retPath = path
                                    retPieceType = pieceType
                                end
                                if #path< #retPath then
                                    retPath = path
                                    retPieceType = pieceType
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    ---说明到目标没有连通区域了
    if #retPath ==0 then
        retPath = self:FindNearestGirdInChessLine(casterEntity,targetEntity,element)
    end
    return retPath
end



---@param chessEntity Entity
---@param targetEntity Entity
---@param element PieceType
function UtilCalcServiceShare:FindNearestGirdInChessLine(chessEntity,targetEntity,element)
    local retPath = {}
    ---@type Vector2[]
    local allConnectPath = self:ChessMonsterFindAllPath(chessEntity,element)
    local targetPos = targetEntity:GetGridPosition()
    local startPos = chessEntity:GetGridPosition()
    local nearDis = 1000000
    local nearIndex,nearPos
    local start2TargetDis =Vector2.Distance(startPos,targetPos)
    for index, pos in pairs(allConnectPath) do
        local tDis = Vector2.Distance(pos,targetPos)
        ---Log.fatal("TargetPos:",targetPos,"pos:", tostring(pos),"Dis:",tDis,"NearDis:",nearDis)
        if tDis< nearDis then
            nearDis = tDis
            nearIndex = index
            nearPos = pos
            --Log.fatal("Start Pos:", tostring(startPos),"NearPos:", tostring(nearPos))
        elseif tDis == nearDis then
            local nearDis2Caster = Vector2.Distance(nearPos,startPos)
            local tDis2Caster = Vector2.Distance(pos,startPos)
            if nearDis2Caster> tDis2Caster then
                nearDis = tDis
                nearIndex = index
                nearPos = pos
                --Log.fatal("Start Pos:", tostring(startPos),"NearPos:", tostring(nearPos))
            end
        end
    end
    if start2TargetDis<= nearDis then
        return {}
    end
    local path={}

    if not self:IsPosAround(startPos, nearPos) then
        local getFinalValidPosFunc = function(pos,type)
            return { pos }
        end
        local getAroundValidPosFunc = function(pos,type)
            return self:ChessMonsterMoveGetPosValidAround(pos,type)
        end
        path = self:CalcPos2PosShortestPath(startPos,nearPos,element,getFinalValidPosFunc,getAroundValidPosFunc)
    end
    table.insert(path,nearPos)
    --if #path== 0 then
    --    Log.exception("Fuck Error")
    --end
    return path

end
---判断两个坐标是否八方向相连
function UtilCalcServiceShare:IsPosAround(pos1,pos2)
    if math.abs(pos1.x - pos2.x) <=1 and math.abs(pos1.y-pos2.y) <=1 then
        return true
    end
    return false
end

---@param chessEntity Entity
---@param element PieceType
function UtilCalcServiceShare:ChessMonsterFindAllPath(chessEntity,element)
    local monsterPos = chessEntity:GetGridPosition()
    local retPath ={}
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc= self._world:GetService("UtilScopeCalc")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    for x = -1, 1 do
        for y = -1, 1 do
            local newPos = Vector2(monsterPos.x+x,monsterPos.y+y)
            if (newPos.x ~=monsterPos.x or newPos.y ~=monsterPos.y)
                    and utilDataSvc:IsValidPiecePos(newPos) and
                    not boardSvc:IsPosBlock(newPos,BlockFlag.LinkLine) and
                    not utilDataSvc:IsPosHasSpTrap(newPos,TrapType.BadGrid) then
                local pieceType = board:GetPieceType(newPos)
                if pieceType == PieceType.Any or pieceType == element then
                    local index = Vector2.Pos2Index(newPos)
                    if not retPath[index] then
                        retPath[index] = newPos
                    end
                    self:GetConnectPosList(newPos,element,retPath)
                end
            end
        end
    end
    return retPath
end

function UtilCalcServiceShare:GetConnectPosList(pos,element,list)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc= self._world:GetService("UtilScopeCalc")
    ---@type Vector2[]
    local newPosAroundPosList = utilScopeSvc:GetPosAroundSameTypePosList(pos,element)
    for _, newPos in ipairs(newPosAroundPosList) do
        local index = Vector2.Pos2Index(newPos)
        --Log.fatal("GetConnectPosList Index:",index,"NewPos:", tostring(newPos),"Element:",element,"SourcePos:", tostring(pos))
        if not list[index] then
            list[index] = newPos
            --Log.fatal("GetConnectPosList Insert NewPos:", tostring(newPos),"Element:",element,"SourcePos:", tostring(pos))
            self:GetConnectPosList(newPos,element,list)
        end
    end
end


---@param monsterEntity Entity
---@param element PieceType
function UtilCalcServiceShare:CheckChessMonsterCanMove(monsterEntity,element)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc= self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    local boardSvc = self._world:GetService("BoardLogic")
    local aroundPosList =  utilScopeSvc:GetTargetSquareRing(monsterEntity:GetID(),1)
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local ret =false
    for _, pos in ipairs(aroundPosList) do
        if utilDataSvc:IsValidPiecePos(pos) and
                not boardSvc:IsPosBlock(pos,BlockFlag.LinkLine) and
                not utilDataSvc:IsPosHasSpTrap(pos,TrapType.BadGrid) then
            local type = board:GetPieceType(pos)
            if type == element or type == PieceType.Any then
                ret = true
                ----Log.debug("ChessMonsterCanMove Pos:", tostring(pos),"Type:",type)
                break
            end
        end
    end
    return ret
end
function UtilCalcServiceShare:CalSyncMovePreviewPos(startPos,chainPath)
    ---@type SyncMoveServiceLogic
    local syncMoveSvcLogic = self._world:GetService("SyncMoveLogic")
    if syncMoveSvcLogic then
        return syncMoveSvcLogic:CalcSyncMovePreviewPos(startPos,chainPath)
    end
end
--region SkillEffectType.MonsterMoveGridToSkillRangeFar
--从当前位置出发，八方向延伸，找到所有可到达的点
function UtilCalcServiceShare:MonsterFindAllPosCanLink(startPos)
    local monsterPos = startPos
    local retCanLink ={}
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc= self._world:GetService("UtilScopeCalc")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    for x = -1, 1 do
        for y = -1, 1 do
            local newPos = Vector2(monsterPos.x+x,monsterPos.y+y)
            if (newPos.x ~=monsterPos.x or newPos.y ~=monsterPos.y)
                    and utilDataSvc:IsValidPiecePos(newPos) and
                    --not boardSvc:IsPosBlock(newPos,BlockFlag.LinkLine) and
                    not boardSvc:IsPosBlock(newPos,BlockFlag.MonsterLand) and
                    not utilDataSvc:IsPosHasSpTrap(newPos,TrapType.BadGrid) then
                local pieceType = board:GetPieceType(newPos)
                local startElement
                if pieceType == PieceType.Any then
                    for eleType = PieceType.Blue, PieceType.Yellow do
                        startElement = eleType
                        local index = Vector2.Pos2Index(newPos)
                        if not retCanLink[index] then
                            retCanLink[index] = newPos
                        end
                        self:MonsterGetConnectPosList(newPos,startElement,retCanLink)
                    end
                elseif pieceType ~= PieceType.None then
                    startElement = pieceType
                    local index = Vector2.Pos2Index(newPos)
                    if not retCanLink[index] then
                        retCanLink[index] = newPos
                    end
                    self:MonsterGetConnectPosList(newPos,startElement,retCanLink)
                end
            end
        end
    end
    return retCanLink
end
function UtilCalcServiceShare:MonsterGetConnectPosList(pos,element,list)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc= self._world:GetService("UtilScopeCalc")
    ---@type Vector2[]
    local newPosAroundPosList = utilScopeSvc:MonsterGetPosAroundSameTypePosList(pos,element)
    for _, newPos in ipairs(newPosAroundPosList) do
        local index = Vector2.Pos2Index(newPos)
        --Log.fatal("MonsterGetConnectPosList Index:",index,"NewPos:", tostring(newPos),"Element:",element,"SourcePos:", tostring(pos))
        if not list[index] then
            list[index] = newPos
            --Log.fatal("MonsterGetConnectPosList Insert NewPos:", tostring(newPos),"Element:",element,"SourcePos:", tostring(pos))
            self:MonsterGetConnectPosList(newPos,element,list)
        end
    end
end
---@param casterEntity Entity
---@param targetID number
---@param pieceType PieceType
function UtilCalcServiceShare:GetMonster2PosByLink(casterPos, targetPos, pieceType)
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    local retPath ={}
    local retPieceType = nil
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc= self._world:GetService("UtilScopeCalc")
    local bTargetCanConnect = true
    ---尝试用A*找一条能连通的路
    if bTargetCanConnect then
        local getFinalValidPosFunc = function(pos,type)
            local posList = {}
            table.insert(posList,pos)
            return posList
        end
        local getAroundValidPosFunc = function(pos,type)
            return self:MonsterLinkMoveGetPosValidAround(pos,type)
        end
        local path = self:CalcPos2PosShortestPath(casterPos,targetPos,pieceType,getFinalValidPosFunc,getAroundValidPosFunc)
        if path and #path >0 then
            if #retPath == 0 then
                retPath = path
                retPieceType = pieceType
            end
            if #path< #retPath then
                retPath = path
                retPieceType = pieceType
            end
        end
    end
    return retPath
end
---@param pos Vector2
---@param pieceType PieceType
---@return Vector2[]
function UtilCalcServiceShare:MonsterLinkMoveGetPosValidAround(pos,pieceType)
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    ---@type Vector2[]
    local aroundList = {}
    for x = -1, 1 do
        for y = -1, 1 do
            local newPos = Vector2(pos.x + x, pos.y + y)
            if (newPos.x ~= pos.x or newPos.y ~= pos.y) then
                if utilDataSvc:IsValidPiecePos(newPos)
                    and (board:GetPieceType(newPos) == pieceType or board:GetPieceType(newPos) == PieceType.Any)
                    --and not boardSvc:IsPosBlock(newPos,BlockFlag.LinkLine)
                    and not boardSvc:IsPosBlock(newPos,BlockFlag.MonsterLand)
                    and not utilDataSvc:IsPosHasSpTrap(newPos,TrapType.BadGrid)
                then
                    table.insert(aroundList,newPos)
                    ---Log.fatal("AddAroundPos:",newPos)
                end
            end
        end
    end
    return aroundList
end
--endregion SkillEffectType.MonsterMoveGridToSkillRangeFar

function UtilCalcServiceShare:FindMonsterLongestGridPathByTrapID(casterEntity,maxLen,trapID)
    if not maxLen then
        maxLen = 1000
    end
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    local casterPosIndex = Vector2.Pos2Index(casterPos)
    ---@type Vector2[]
    local beginPosList =utilScopeSvc:GetMonsterAroundCanMovePosList(casterEntity,Offset4)
    ---@type BoardComponent
    self._boardCmpt = self._world:GetBoardEntity():Board()
    self._chainPath={}
    self._connectMap = self:_BuildMonsterConnectMapNoPieceType(casterEntity)
    ---@type TrapServiceLogic
    local trapSvcLogic = self._world:GetService("TrapLogic")
    self._trapPosList = trapSvcLogic:FindTrapPosByTrapID(trapID)
    self._chainPathTmp = {}
    self._chainPath= {}
    for i, beginPos in ipairs(beginPosList) do
        local posIndex =Vector2.Pos2Index(beginPos)
        local deep =2
        self._chainPathTmp[posIndex] ={posIndex}
        self._chainPath[#self._chainPath+1]= {trapCount=0,trapDis=0,chainPath= {posIndex}}
        self:_FindLongPathByDeep(posIndex,posIndex,deep,maxLen,casterPosIndex,trapID)
    end

    local count = #self._chainPath
    if count == 0 then
        return {}
    end
    for _, v in ipairs(self._chainPath) do
        local chainPath = v.chainPath
        local trapCount = 0
        for _, posIndex in ipairs(chainPath) do
            local pos = self._boardCmpt:GetCloneVector2PosByPosIndex(posIndex)
            if table.Vector2Include(self._trapPosList,pos) then
                trapCount= trapCount+1
            end
        end
        v.trapCount = trapCount
        if v.trapCount ==0 then
            local beginPosIndex = chainPath[#chainPath]
            local beginPos = self._boardCmpt:GetCloneVector2PosByPosIndex(beginPosIndex)
            local dis = 100000
            for _, pos in ipairs(self._trapPosList) do
                local tDis = Vector2.Distance(beginPos,pos)
                if tDis< dis then
                    dis = tDis
                end
            end
            v.trapDis = dis
        end
    end
    self._trapPosList=nil
    self._connectMap=nil
    self._boardCmpt=nil
    local funcByTrapIDCount = function (a,b)
        return a.trapCount > b.trapCount
    end
    local funcByTrapDis =function (a,b)
        return a.trapDis < b.trapDis
    end
    table.sort(self._chainPath,funcByTrapIDCount)
    if self._chainPath[1].trapCount >0 then
        local path  = self._chainPath[1].chainPath
        if #path < maxLen then
            Log.fatal("1111")
        end
        self._chainPath=nil
        self._chainPathTmp=nil
        return self:PosIndexList2VectorList(path )
    end
    table.sort(self._chainPath,funcByTrapDis)
    local path  = self._chainPath[1].chainPath
    self._chainPath=nil
    self._chainPathTmp=nil
    return self:PosIndexList2VectorList(path )
end

function UtilCalcServiceShare:_CheckMinosMonsterMove(posIndex)
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    boardCmpt:GetCloneVector2PosByPosIndex(posIndex)
end

function UtilCalcServiceShare:_FindLongPathByDeep(posIndex,beginPosIndex,deep,maxLen,casterPosIndex,trapID)
    local ct = self._connectMap[posIndex]
    if not ct then
        return false
    end
    if deep>maxLen then
        return false
    end
    for i=1,4 do
        local chainPath = self._chainPathTmp[beginPosIndex]
        local newPosIndex = ct[i]
        if newPosIndex and not table.icontains(chainPath,newPosIndex) then
            table.insert(chainPath,newPosIndex)
            if #chainPath == maxLen then
                local t= {}
                for i, v in ipairs(chainPath) do
                    t[i] = v
                end
                self._chainPath[#self._chainPath+1]= {trapCount=0,trapDis=0,chainPath=t}
            end
            self:_FindLongPathByDeep(newPosIndex,beginPosIndex,deep+1,maxLen,casterPosIndex,trapID)
            chainPath = self._chainPathTmp[beginPosIndex]
            ---回退了要清理
            if #chainPath >=deep then
                --for j = deep, #chainPath do
                --    --Log.fatal("BeginPosIndex:",beginPosIndex," CurPosIndex: ",posIndex," Clear ChainPath Index:",j," PosIndex:",chainPath[j]," CurDeep:",deep," CurI:",i)
                --    --chainPath[j] = nil
                --    --table.remove(chainPath,j)
                --end
                self._chainPathTmp[beginPosIndex]=table.sub(chainPath,1,deep-1)
            end
        end
    end
end
---@return Vector2[]
function UtilCalcServiceShare:PosIndexList2VectorList(posIndexList)
    local boardCmpt= self._world:GetBoardEntity():Board()
    ---@type Vector2[]
    local ret ={}
    for i, posIndex in ipairs(posIndexList) do
        ---@type Vector2
        ret[i]=boardCmpt:GetCloneVector2PosByPosIndex(posIndex)
        ---Log.fatal("Index: ",i," PosIndex: ",posIndex)
    end
    return ret
end
---@param dir table<number, number>
---@param offset number
function UtilCalcServiceShare:IsOffsetPathValid(dir,offset,sourcePos,hasPath)
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    local boardSvc = self._world:GetService("BoardLogic")
    ---@type Vector2[]
    local retPath = {}
    for i = 1, offset do
        local newPos = Vector2(sourcePos.x+dir[1]*i,sourcePos.y+dir[2]*i)
        if utilDataSvc:IsValidPiecePos(newPos)
                and not boardSvc:IsPosBlock(newPos,BlockFlag.MonsterLand)
                and not utilDataSvc:IsPosHasSpTrap(newPos,TrapType.BadGrid)
                and not table.Vector2Include(hasPath,newPos) then
            table.insert(retPath,newPos)
        else
            return false,retPath
        end
    end
    return true,retPath
end

---@param casterEntity Entity
---
function UtilCalcServiceShare:FindMinosMoveGridPath(casterEntity,runCountList)
    ---@type Vector2
    local beginPos = casterEntity:GetGridPosition()
    ---@type Vector2[]
    local retPosList = {beginPos}
    local dirList = table.clone(Offset8)
    ---@type RandomServiceLogic
    local randomServiceLogic = self._world:GetService("RandomLogic")
    for i, v in ipairs(runCountList) do
        dirList= randomServiceLogic:Shuffle(dirList)
        for _, offset in ipairs(dirList) do
            ---@type boolean,Vector2[]
            local isValid,path = self:IsOffsetPathValid(offset,v,retPosList[#retPosList],retPosList)
            if isValid then
                table.appendArray(retPosList, path)
                break
            end
        end
    end
    table.remove(retPosList,1)
    return retPosList
end
---效率差有bug后面需求了，这个就没优化
function UtilCalcServiceShare:FindMonsterLongestGridPath(casterEntity)
    self._connectMap = self:_BuildMonsterConnectMap(casterEntity)
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Vector2[]
    local beginPosList =utilScopeSvc:GetMonsterAroundCanMovePosList(casterEntity)
    ---@type BoardComponent
    self._boardCmpt= self._world:GetBoardEntity():Board()
    self._chainPath={}
    self._chainPathTmp={}
    self._chainPathType = {}
    for i, beginPos in ipairs(beginPosList) do
        local posIndex =Vector2.Pos2Index(beginPos)
        local pieceType =self._boardCmpt:GetPieceTypeByIndex(posIndex)
        if not pieceType then
            Log.fatal("")
        end
        self._chainPath[posIndex]={posIndex}
        self._chainPathTmp[posIndex]={posIndex}
        local deep =2
        local finalPieceType =  self:_FindLongPath(posIndex,posIndex,pieceType,deep)
        self._chainPathType[posIndex]=finalPieceType
    end
    local retTmp ={}
    local pieceType = nil
    for posIndex, chainPath in pairs(self._chainPath) do
        if #chainPath >#retTmp then
            retTmp= chainPath
            pieceType = self._chainPathType[posIndex]
        end
    end
    ---@type Vector2[]
    local ret =self:PosIndexList2VectorList(retTmp)
    ---@type UtilDataServiceShare
    local utilDataService = self._world:GetService("UtilData")
    if #ret > 3 then
        for i = 2, #ret - 1 do
            local pos1 = ret[i]
            local pos2 = ret[i + 1]
            local ret, msg = utilDataService:Is2PosCanConnect(pos1, pos2, pieceType)
            if not ret then
                Log.fatal("1")
            end
        end
    end
    self._chainPath={}
    self._chainPathTmp={}
    self._boardCmpt= nil
    self._connectMap =nil
    return ret
end

function UtilCalcServiceShare:_FindLongPath(posIndex,beginPosIndex,pieceType,deep)
    local ct = self._connectMap[posIndex]
    if not ct then
        return
    end
    if #(self._chainPath[beginPosIndex]) >1 then
        local curPieceType = self._boardCmpt:GetPieceTypeByIndex(posIndex)
        if pieceType == PieceType.Any then
            pieceType = curPieceType
        end
    end
    if deep > 30 then
        return
    end
    for i = 1, 8 do
        local chainPath = self._chainPathTmp[beginPosIndex]
        local newPosIndex = ct[i]
        if newPosIndex then
            local posPieceType = self._boardCmpt:GetPieceTypeByIndex(newPosIndex)
            if not pieceType then
                Log.fatal("")
            end
            if CanMatchPieceType(posPieceType, pieceType) and not table.icontains(chainPath, newPosIndex) then
                if pieceType == PieceType.Any then
                    pieceType = posPieceType
                end
                --Log.fatal("BeginPosIndex:",beginPosIndex," CurPosIndex: ",posIndex," Insert ChainPath Index:",#chainPath+1," PosIndex:",newPosIndex)
                table.insert(chainPath,newPosIndex)
                if #chainPath > #(self._chainPath[beginPosIndex] )then
                    self._chainPath[beginPosIndex]={}
                    for i, v in ipairs(chainPath) do
                        self._chainPath[beginPosIndex][i] =v
                    end
                end
                self:_FindLongPath(newPosIndex,beginPosIndex,pieceType,deep+1)
                chainPath = self._chainPathTmp[beginPosIndex]
                ---回退了要清理
                if #chainPath >=deep then
                    --for j = deep, #chainPath do
                    --    --Log.fatal("BeginPosIndex:",beginPosIndex," CurPosIndex: ",posIndex," Clear ChainPath Index:",j," PosIndex:",chainPath[j]," CurDeep:",deep," CurI:",i)
                    --    --chainPath[j] = nil
                    --    --table.remove(chainPath,j)
                    --end
                    self._chainPathTmp[beginPosIndex]=table.sub(chainPath,1,deep-1)
                end
            end

        end
    end
    return pieceType
end

function UtilCalcServiceShare:_BuildMonsterConnectMapNoPieceType(entity)
    local connectMap = {}
    local pos = entity:GetGridPosition()
    local posIndex = Vector2.Pos2Index(pos)
    local blockFlag = BlockFlag.MonsterLand
    if entity:MonsterID():GetMonsterRaceType() == MonsterRaceType.Fly then
        blockFlag = BlockFlag.MonsterFly
    end
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local blockCanMoveMap = board:GetBlockFlagCanMoveMap(blockFlag)
    for i, offset in ipairs(Offset4) do
        local newPosIndex = posIndex + offset[1] * 100 + offset[2]
        self:_ConnectMapNoPieceType(newPosIndex,connectMap,board,blockCanMoveMap,posIndex)
    end
    board:ClearBlockFlagCanMoveMap(blockFlag)
    --for sPosIndex, conneceList in pairs(connectMap) do
    --    --Log.fatal("SourcePosIndex:",sPosIndex," Begin")
    --    for k, posIndex in pairs(conneceList) do
    --        --Log.fatal("ConnectPosIndex:",posIndex)
    --    end
    --    --Log.fatal("SourcePosIndex:",sPosIndex," End")
    --end
    return connectMap
end

function UtilCalcServiceShare:_ConnectMapNoPieceType(posIndex,connectMap, boardCmpt, blockCanMoveMap,beginPosIndex)
    if connectMap[posIndex] then
        return
    end

    local ct = {}
    connectMap[posIndex] = ct

    for index, offset in ipairs(Offset4) do
        local i, j = offset[1], offset[2]
        local surroundIndex = posIndex + offset[1] * 100 + offset[2]
        if blockCanMoveMap[surroundIndex] then
            ct[index] = surroundIndex
            self:_ConnectMapNoPieceType(surroundIndex, connectMap, boardCmpt, blockCanMoveMap)
        end
    end
end

---@param entity Entity
function UtilCalcServiceShare:_BuildMonsterConnectMap(entity,needPieceType)
    local connectMap = {}
    local pos = entity:GetGridPosition()
    local posIndex = Vector2.Pos2Index(pos)
    local blockFlag = BlockFlag.MonsterLand
    if entity:MonsterID():GetMonsterRaceType() == MonsterRaceType.Fly then
        blockFlag = BlockFlag.MonsterFly
    end
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local blockCanMoveMap = board:GetBlockFlagCanMoveMap(blockFlag)
    local ringPosList = ComputeScopeRange.ComputeRange_SquareRing(pos,1,1)
    for i, v in ipairs(ringPosList) do
        local pieceType = board:GetPieceType(v)
        local beginIndex = Vector2.Pos2Index(v)
        self:_ConnectMap(beginIndex, pieceType, connectMap,board,blockCanMoveMap,posIndex)
    end
    board:ClearBlockFlagCanMoveMap(blockFlag)
    --for sPosIndex, conneceList in pairs(connectMap) do
    --    --Log.fatal("SourcePosIndex:",sPosIndex," Begin")
    --    for k, posIndex in pairs(conneceList) do
    --        --Log.fatal("ConnectPosIndex:",posIndex)
    --    end
    --    --Log.fatal("SourcePosIndex:",sPosIndex," End")
    --end
    return connectMap
end

function UtilCalcServiceShare:_Offset2Index(i, j)
    local t = {
        [1] = {6, 7, 8},
        [2] = {5, 0, 1},
        [3] = {4, 3, 2}
    }
    return t[i + 2][j + 2]
end

---@param boardCmpt BoardComponent
function UtilCalcServiceShare:_ConnectMap(posIndex, pieceType, connectMap, boardCmpt, blockCanMoveMap,beginPosIndex)
    if connectMap[posIndex] then
        return
    end

    local ct = {}
    connectMap[posIndex] = ct

    for _, offset in ipairs(Offset8) do
        local i, j = offset[1], offset[2]
        local surroundIndex =posIndex + offset[1] * 100 + offset[2]
        if blockCanMoveMap[surroundIndex] then
            local surroundPiece = boardCmpt:GetPieceTypeByIndex(surroundIndex)
            if CanMatchPieceType(surroundPiece, pieceType) and surroundIndex ~= beginPosIndex then
                --Log.fatal("PosIndex:",posIndex," surroundIndex:",surroundIndex, " Type:", pieceType," SurType:",surroundPiece)
                if surroundPiece == PieceType.Any then
                    surroundPiece = pieceType
                end
                ct[self:_Offset2Index(i, j)] = surroundIndex
                self:_ConnectMap(surroundIndex, surroundPiece, connectMap,boardCmpt,blockCanMoveMap)
            end
        end
    end
end

----贪吃蛇头寻路
function UtilCalcServiceShare:SnakeHeadCheckBlock(pos,ignoreBlockPos)
    if ignoreBlockPos and pos.x == ignoreBlockPos.x and pos.y == ignoreBlockPos.y then
        return true
    end
    local boardSvc = self._world:GetService("BoardLogic")
    return not boardSvc:IsPosBlock(pos,BlockFlag.MonsterLand)
end

---@param pos Vector2
---@param pieceType PieceType
---@return Vector2[]
function UtilCalcServiceShare:SnakeGetPosValidAroundByOffset(pos,ignoreBlockPos,offset)
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    local aroundList = ComputeScopeRange.ComputeRange_SquareRing(pos, 1, 1)
    ----@type Vector2
    local ret={}
    for i, v  in ipairs(offset) do
        local aroundPos = Vector2(pos.x+v[1],pos.y+v[2])
        if utilDataSvc:IsValidPiecePos(aroundPos) and self:SnakeHeadCheckBlock(aroundPos,ignoreBlockPos) then
            table.insert(ret,aroundPos)
        end
    end
    return ret
end

---@param aStarInfo AStarInfo
---@param closeList AStarInfo[]
function UtilCalcServiceShare:SnakeHeadPosInList(aStarInfo,pos2,openList,closeList,ignoreBlockPos)
    local pos1 = aStarInfo:GetMyPos()
    local pos1Around = self:SnakeGetPosValidAroundByOffset(pos1,ignoreBlockPos,Offset4)
    for i, pos in ipairs(pos1Around) do
        local canInsert = true
        for i, info  in ipairs(closeList) do
            local myPos =info:GetMyPos()
            if myPos.x == pos.x and myPos.y == pos.y then
                canInsert =false
                break
            end
        end
        if canInsert and not self:IsInOpenList(pos,openList)  then
            ---@type AStarInfo
            local info = AStarInfo:New(pos,self:CalcH(pos,pos2),aStarInfo)
            openList:Insert(info)
            --Log.fatal("Ins OpenList:",pos)
        end
    end
end
---@param pos1 Vector2
---@param pos2 Vector2
function UtilCalcServiceShare:SnakeHeadCalcPos2PosShortestPath(pos1, pos2,ignoreBlockPos)
    ---@type SortedArray
    local openList =SortedArray:New(Algorithm.COMPARE_CUSTOM,AStarInfo.Sort)
    ---@type AStarInfo[]
    local closeList = {}

    local find = false

    local startInfo = AStarInfo:New(pos1,self:CalcH(pos1,pos2),nil)
    local endInfo = nil
    openList:Insert(startInfo)


    local finalPosList = self:SnakeGetPosValidAroundByOffset(pos2,ignoreBlockPos,Offset8)
    if #finalPosList ==0 then
        return {}
    end

    ---for i, pos in ipairs(finalPosList) do
    ----    Log.fatal("FinalPosList:",pos)
    ----end

    ---Log.fatal("StartInfoPos:",startInfo:GetMyPos())
    while not openList:Empty() do
        for i, info in ipairs(openList.elements) do
            if  table.Vector2Include(finalPosList, info:GetMyPos()) then
                find= true
                endInfo = info
                break
            end
        end
        if find then
            break
        end
        ---@type AStarInfo
        local info = openList:GetFirstElement()
        ---Log.fatal("RemoveInfoPos:",info:GetMyPos())
        openList:Remove(info)
        table.insert(closeList,info)
        self:SnakeHeadPosInList(info,pos2,openList,closeList,ignoreBlockPos)
    end
    local retList =self:GetPath(endInfo)
    return retList
end

---@param monsterEntity Entity
function UtilCalcServiceShare:SnakeFindPathMove2PlayerNearestPath(monsterEntity,ignoreBlockPos)
    ---@type Entity
    local teamEntity = monsterEntity:AI():GetTargetTeamEntity()
    ---@type Vector2
    local playerPos = teamEntity:GetGridPosition()
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local boardSvc = self._world:GetService("BoardLogic")
    ---@type Vector2
    local monsterPos = monsterEntity:GetGridPosition()
    ---@type Vector2
    local monsterDir = monsterEntity:GetGridDirection()
    ---蛇头后面的一格位置
    local underMonsterPos = monsterPos-monsterDir
    local retPath ={}
    ---@type UtilDataServiceShare
    local utilDataSvc= self._world:GetService("UtilData")
    for i, v in ipairs(Offset4) do
        local startPos = Vector2(monsterPos.x+v[1],monsterPos.y+v[2])
                if utilDataSvc:IsValidPiecePos(startPos) and
                self:SnakeHeadCheckBlock(startPos,ignoreBlockPos) then
            local path = self:SnakeHeadCalcPos2PosShortestPath(startPos,playerPos)
            if path and #path >0 then
                if #retPath == 0 then
                    retPath = path
                end
                if #path< #retPath then
                    retPath = path
                end
            end
        end
    end
    return retPath
end
---贪吃蛇头寻路完毕

--region N25吸血鬼Boss移动
---@param casterEntity Entity 移动者
---@param targetEntity Entity 目标
---@param pieceTypeList PieceType[] 可移动的颜色格子
---@param moveType MovePathType 移动策略
function UtilCalcServiceShare:FindPath_MonsterMoveGridByParam(casterEntity, targetEntity, pieceTypeList, moveType)
    local movePath = {}
    --N25吸血鬼Boss移动环境
    self._n25BChainPaths = {}
    self._n25BChainIndexPaths = {}
    self._n25MoveForward = false
    self._n25BConnectMap = {}
    self._HighConnectRateCutLen = 0
    self._maxlen = 0
    self._cutlen = 0

    --构建联通地图
    self:_BuildConnectMapByPieceTypeList(casterEntity, pieceTypeList)

    self._HighConnectRateCutLen = self:_CalcHighConnectRateCutLen(casterEntity)

    --计算所有联通路线
    self:_CalcAllMovePathByPieceTypeList(casterEntity, pieceTypeList)

    --根据移动策略，找到最佳路线
    if moveType == MovePathType.Far then
        movePath = self:_FindPath_FarFromTarget(targetEntity)
    elseif moveType == MovePathType.NearCross or moveType == MovePathType.NearAround then
        movePath = self:_FindPath_NearToTarget(targetEntity, moveType)
    end

    if #movePath <= 1 then
        --怪物周围随意找一个方向行走一格
        movePath = self:_MoveOneStep(casterEntity)
    end

    --重置N25吸血鬼Boss移动环境
    self._n25BChainPaths = {}
    self._n25BChainIndexPaths = {}
    self._n25MoveForward = false
    self._n25BConnectMap = {}
    self._HighConnectRateCutLen = 0
    self._maxlen = 0
    self._cutlen = 0

    return movePath
end

---@param entity Entity
---@param pieceTypeList PieceTypy[] 可连通的颜色，默认包含万色格子
function UtilCalcServiceShare:_BuildConnectMapByPieceTypeList(entity, pieceTypeList)
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()

    local pos = entity:GetGridPosition()
    local posIndex = Vector2.Pos2Index(pos)

    --构建当前可移动范围
    local blockFlag = BlockFlag.MonsterLand
    if entity:MonsterID():GetMonsterRaceType() == MonsterRaceType.Fly then
        blockFlag = BlockFlag.MonsterFly
    end
    local blockCanMoveMap = boardCmpt:GetBlockFlagCanMoveMap(blockFlag)

    --构建需求颜色联通地图
    self:_ConnectMapByPieceTypeList(posIndex, pieceTypeList, boardCmpt, blockCanMoveMap)

    --清除可移动范围缓存
    boardCmpt:ClearBlockFlagCanMoveMap(blockFlag)
end

---@param boardCmpt BoardComponent
function UtilCalcServiceShare:_ConnectMapByPieceTypeList(posIndex, pieceTypeList, boardCmpt, blockCanMoveMap)
    if self._n25BConnectMap[posIndex] then
        return
    end

    local ct = {}
    self._n25BConnectMap[posIndex] = ct

    for _, offset in ipairs(Offset8) do
        local offsetVec = Vector2(offset[1], offset[2])
        local surroundIndex = posIndex + Vector2.Pos2Index(offsetVec)
        if blockCanMoveMap[surroundIndex] then
            local surroundPiece = boardCmpt:GetPieceTypeByIndex(surroundIndex)
            if CanMatchPieceTypeList(surroundPiece, pieceTypeList) then
                ct[self:_Offset2Index(offsetVec.x, offsetVec.y)] = surroundIndex
                self:_ConnectMapByPieceTypeList(surroundIndex, pieceTypeList, boardCmpt, blockCanMoveMap)
            end
        end
    end
end

--计算所有连线情况
function UtilCalcServiceShare:_CalcAllMovePathByPieceTypeList(casterEntity, pieceTypeList)
    local pos = casterEntity:GetGridPosition()
    local startPosIndex = Vector2.Pos2Index(pos)
    local chainPathIdx = { startPosIndex }

    local depth = 100
    self:_NextMoveByPieceTypeList(chainPathIdx, pieceTypeList, depth)
end

function UtilCalcServiceShare:_NextMoveByPieceTypeList(chainPathIdx, pieceTypeList, depth)
    if depth == 0 then
        return
    end

    local startPosIdx = chainPathIdx[#chainPathIdx]
    --不能联通则回退
    local ct = self._n25BConnectMap[startPosIdx]
    if not ct or table.count(ct) == 0 then
        return
    end

    for i = 1, 8 do
        --长度优化导致裁剪了部分路径，不尝试这部分了
        if startPosIdx ~= chainPathIdx[#chainPathIdx] then
            return
        end
        local posIdx = ct[i]
        if posIdx and not table.icontains(chainPathIdx, posIdx) then
            chainPathIdx[#chainPathIdx + 1] = posIdx
            local s = table.concat(chainPathIdx, " ")
            Log.fatal("KZY: path+: ", s)
            self._n25MoveForward = true
            self:_NextMoveByPieceTypeList(chainPathIdx, pieceTypeList, depth - 1)

            if self._n25MoveForward and #chainPathIdx > 1 then
                self._n25MoveForward = false
                --结果
                local chainPath = {}
                for n = 1, #chainPathIdx do
                    chainPath[#chainPath + 1] = Vector2.Index2Pos(chainPathIdx[n])
                end
                if table.icontains(self._n25BChainIndexPaths, chainPathIdx) then
                    return
                end
                self._n25BChainPaths[#self._n25BChainPaths + 1] = chainPath
                self._n25BChainIndexPaths[#self._n25BChainIndexPaths + 1] = table.cloneconf(chainPathIdx)
                local s = table.concat(chainPathIdx, " ")
                Log.fatal("KZY: find sucess: 第", #self._n25BChainIndexPaths, "条路径: ", s)

                --计算裁剪路径
                self._maxlen = #chainPathIdx
                self._cutlen = self:_CalcChainPathComplexityLen(chainPathIdx)
            end

            --逐步撤回
            if startPosIdx == chainPathIdx[#chainPathIdx - 1] then
                local len = #chainPathIdx
                chainPathIdx[len] = nil
                local s = table.concat(chainPathIdx, " ")
                Log.fatal("KZY: path-: ", s)
            end

            --无论如何回溯最后4步
            if self._maxlen - #chainPathIdx == 4 then
                for n = #chainPathIdx, self._cutlen, -1 do
                    local len = #chainPathIdx
                    chainPathIdx[len] = nil
                    local s = table.concat(chainPathIdx, " ")
                    Log.fatal("KZY: path-: ", s)
                end
            end
        end
    end
end

function UtilCalcServiceShare:_FindPath_FarFromTarget(targetEntity)
    local retPath = {}
    local disMax = 0
    local chainPathIndex = 0
    local chainPosIndex = 0
    local targetPos = targetEntity:GetGridPosition()

    for i, chainPath in ipairs(self._n25BChainPaths) do
        for j, chainPos in ipairs(chainPath) do
            local dis = Vector2.Distance(chainPos, targetPos)
            if dis > disMax then
                disMax = dis
                chainPathIndex = i
                chainPosIndex = j
            end
        end
    end

    if chainPathIndex > 0 and chainPosIndex > 0 then
        retPath = self._n25BChainPaths[chainPathIndex]
        --截取路径
        retPath = table.sub(retPath, 1, chainPosIndex)
    end

    return retPath
end

---@param targetEntity Entity
---@param moveType MovePathType
function UtilCalcServiceShare:_FindPath_NearToTarget(targetEntity, moveType)
    --获取目标周围点
    local offsetList = Offset4
    if moveType == MovePathType.NearAround then
        offsetList = Offset8
    end

    local targetPos = targetEntity:GetGridPosition()
    local posIndex = Vector2.Pos2Index(targetPos)
    local highValuePosIdxList = self:_GetPosIndexListByOffset(posIndex, offsetList)

    local retPath = {}

    --寻找目标周围可攻击位置最多的路径
    local unionCount = 0
    local retIndex = 0
    for i, chainPathIdx in ipairs(self._n25BChainIndexPaths) do
        local targetInPath = table.union(chainPathIdx, highValuePosIdxList)
        if unionCount < #targetInPath then
            unionCount = #targetInPath
            retIndex = i
            if unionCount == #highValuePosIdxList then
                break
            end
        end
    end

    local disMin = MAX_INT_32
    local chainPathIndex = 0
    local chainPosIndex = 0

    if retIndex > 0 then
        chainPathIndex = retIndex
        for j, chainPos in ipairs(self._n25BChainPaths[retIndex]) do
            local dis = Vector2.Distance(chainPos, targetPos)
            if dis <= disMin then
                disMin = dis
                chainPosIndex = j
            end
        end
    else
        --目标位置可攻击点均无法抵达，则寻找距离目标的最近路径
        for i, chainPath in ipairs(self._n25BChainPaths) do
            for j, chainPos in ipairs(chainPath) do
                local dis = Vector2.Distance(chainPos, targetPos)
                if dis < disMin then
                    disMin = dis
                    chainPathIndex = i
                    chainPosIndex = j
                end
            end
        end
    end

    if chainPathIndex > 0 and chainPosIndex > 0 then
        retPath = self._n25BChainPaths[chainPathIndex]
        --截取路径
        retPath = table.sub(retPath, 1, chainPosIndex)
    end

    return retPath
end

---@param posIndex Vector2
---@return number[]
function UtilCalcServiceShare:_GetPosIndexListByOffset(posIndex, offsetList)
    local posIndexList = {}
    for _, offset in ipairs(offsetList) do
        local offsetVec = Vector2(offset[1], offset[2])
        local index = posIndex + Vector2.Pos2Index(offsetVec)
        table.insert(posIndexList, index)
    end
    return posIndexList
end

function UtilCalcServiceShare:_MoveOneStep(casterEntity)
    local pos = casterEntity:GetGridPosition()
    local chainPath = { pos }

    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local blockFlag = BlockFlag.MonsterLand
    if casterEntity:MonsterID():GetMonsterRaceType() == MonsterRaceType.Fly then
        blockFlag = BlockFlag.MonsterFly
    end

    local randPosList = {}
    for _, offset in ipairs(Offset8) do
        local offsetVec = Vector2(offset[1], offset[2])
        local newPos = pos + offsetVec
        if not boardCmpt:IsPosBlock(newPos, blockFlag) then
            table.insert(randPosList, newPos)
        end
    end

    if #randPosList > 0 then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local randIdx = randomSvc:LogicRand(1, #randPosList)
        chainPath[#chainPath + 1] = randPosList[randIdx]
    end

    return chainPath
end

---@param casterEntity Entity
function UtilCalcServiceShare:_CalcHighConnectRateCutLen(casterEntity)
    local connectMap = self._n25BConnectMap
    local playerPos = casterEntity:GetGridPosition()
    local playerPosIndex = Vector2.Pos2Index(playerPos)

    local touchIdx = {}
    local totalConnect = 0
    local totalPosNum = 0

    local search
    search = function(posIndex)
        touchIdx[posIndex] = true
        totalPosNum = totalPosNum + 1
        local ct = connectMap[posIndex]
        for i = 1, 8 do
            local nextIdx = ct[i]
            if nextIdx then
                totalConnect = totalConnect + 1
                if not touchIdx[nextIdx] then
                    search(nextIdx)
                end
            end
        end
    end

    search(playerPosIndex)
    local rate = totalConnect / totalPosNum
    local cutlen = 0
    local idx = BattleConst.AutoFightMoveEnhanced and 2 or 1
    if totalPosNum > BattleConst.AutoFightPathLengthCutPosNum and
        rate > BattleConst.AutoFightPathLengthCutConnectRate[idx] then
        cutlen = BattleConst.AutoFightPathLengthCut
    end
    Log.debug("[AutoFight] _CalcHighConnectRateCutLen() totalPosNum=", totalPosNum, " ConnectRate=", rate)
    return cutlen
end

function UtilCalcServiceShare:_CalcChainPathComplexityLen(chainPathIdx)
    if self._HighConnectRateCutLen > 0 then
        return self._HighConnectRateCutLen
    end
    local m = BattleConst.AutoFightMoveEnhanced and 2 or 1
    local cc = 1
    local len = #chainPathIdx
    for i, idx in ipairs(chainPathIdx) do
        cc = cc * table.count(self._n25BConnectMap[idx])
        if cc > BattleConst.AutoFightPathComplexity[m] then
            len = i - 1
            break
        end
    end
    return len
end

---@param casterEntity Entity 移动者
---@param targetEntity Entity 目标
---@param pieceTypeList PieceType[] 可移动的颜色格子
---@param moveType MovePathType 移动策略
function UtilCalcServiceShare:FindPath_MonsterMoveGridByParam2(casterEntity, targetEntity, pieceTypeList, moveType)
    ---@type Vector2
    local targetCenterPos = targetEntity:GetGridPosition()
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()

    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    --构建当前可移动范围
    local blockFlag = BlockFlag.MonsterLand
    if casterEntity:MonsterID():GetMonsterRaceType() == MonsterRaceType.Fly then
        blockFlag = BlockFlag.MonsterFly
    end
    self._n25BossBlockCanMoveMap = boardCmpt:GetBlockFlagCanMoveMap(blockFlag)

    --首先从boss位置出发，八方向延伸，找到所有可到达的点，保存
    ---@type table<int,Vector2>
    local posCanLink = self:_MonsterFindAllPosCanLinkByPieceTypeList(casterPos, pieceTypeList)
    local movePath = {}

    --根据移动策略，找到可移动点
    local tarMovePos
    if moveType == MovePathType.Far then
        tarMovePos = self:_FindPos_FarFromTarget(targetCenterPos, posCanLink)
    elseif moveType == MovePathType.NearCross or moveType == MovePathType.NearAround then
        local offsetList = moveType == MovePathType.NearCross and Offset4 or Offset8
        tarMovePos = self:_FindPos_NearToTarget(targetCenterPos, posCanLink, offsetList)
    end

    if tarMovePos then
        movePath = self:_GetMonster2PosLinkPathByPieceTypeList(casterPos, tarMovePos, pieceTypeList)
    end

    --极限情况处理
    if table.count(movePath) == 0 then
        local compareType = AiSortByDistance._ComparerByFar
        if moveType ~= MovePathType.Far then
            compareType = AiSortByDistance._ComparerByNear
        end
        local targetPos = self:_FindPos_AroundPosByCompare(casterPos, targetCenterPos, compareType)
        if targetPos and targetPos ~= casterPos then
            movePath = { casterPos, targetPos }
        end
    end

    --清除可移动范围缓存
    boardCmpt:ClearBlockFlagCanMoveMap(blockFlag)
    self._n25BossBlockCanMoveMap = {}
    return movePath
end

function UtilCalcServiceShare:_FindPos_AroundPosByCompare(pos, targetCenterPos, compare)
    local validSkillRange = { pos }

    for _, offset in ipairs(Offset8) do
        local offsetVec = Vector2(offset[1], offset[2])
        local newPos = pos + offsetVec
        local newPosIndex = Vector2.Pos2Index(newPos)
        if self._n25BossBlockCanMoveMap[newPosIndex] then
            table.insert(validSkillRange, newPos)
        end
    end

    local targetPos = self:FindPosToTarget(targetCenterPos, validSkillRange, compare)

    return targetPos
end

function UtilCalcServiceShare:_FindPos_FarFromTarget(targetCenterPos, posCanLink)
    --范围取全屏所有格子
    local skillRange = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local boardMaxX = boardServiceLogic:GetCurBoardMaxX()
    local boardMaxY = boardServiceLogic:GetCurBoardMaxY()
    for x = 1, boardMaxX do
        for y = 1, boardMaxY do
            local pos = Vector2(x, y)
            table.insert(skillRange, pos)
        end
    end

    --筛选技能范围，需要在可到达范围内
    local validSkillRange = self:FilterSkillRangePos(skillRange, posCanLink)
    local tarMovePos
    --可用的技能范围位置列表
    if #validSkillRange > 0 then
        --技能范围位置列表不为空，则选中距离玩家最远的点作为目标位置
        tarMovePos = self:FindPosToTarget(targetCenterPos, validSkillRange, AiSortByDistance._ComparerByFar)
    else
        --技能范围位置列表列表为空（说明走不到可放技能的位置），则试图移动到距离玩家最近的点
        tarMovePos = self:FindPosToTarget(targetCenterPos, posCanLink, AiSortByDistance._ComparerByFar)
    end
    return tarMovePos
end

function UtilCalcServiceShare:_FindPos_NearToTarget(targetCenterPos, posCanLink, offsetList)
    --范围取目标周围八格
    local skillRange = {}
    for _, offset in ipairs(offsetList) do
        local offsetVec = Vector2(offset[1], offset[2])
        local newPos = targetCenterPos + offsetVec
        table.insert(skillRange, newPos)
    end

    --筛选技能范围，需要在可到达范围内
    local validSkillRange = self:FilterSkillRangePos(skillRange, posCanLink)
    local tarMovePos
    --可用的技能范围位置列表
    if #validSkillRange > 0 then
        --技能范围位置列表不为空，则选中距离玩家最远的点作为目标位置
        tarMovePos = self:FindPosToTarget(targetCenterPos, validSkillRange, AiSortByDistance._ComparerByFar)
    else
        --技能范围位置列表列表为空（说明走不到可放技能的位置），则试图移动到距离玩家最近的点
        tarMovePos = self:FindPosToTarget(targetCenterPos, posCanLink, AiSortByDistance._ComparerByFar)
    end
    return tarMovePos
end

---@param skillRange Vector2[]
---@param posCanLink table<int,Vector2>
function UtilCalcServiceShare:FilterSkillRangePos(skillRange, posCanLink)
    local retRange = {}
    for _, pos in ipairs(skillRange) do
        local posIndex = Vector2.Pos2Index(pos)
        if posCanLink[posIndex] then
            table.insert(retRange, pos)
        end
    end
    return retRange
end

function UtilCalcServiceShare:_MonsterFindAllPosCanLinkByPieceTypeList(startPos, pieceTypeList)
    local monsterPos = startPos
    local retCanLink = {}

    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    --寻找连通点
    for _, offset in ipairs(Offset8) do
        local offsetVec = Vector2(offset[1], offset[2])
        local newPos = monsterPos + offsetVec
        local newPosIndex = Vector2.Pos2Index(newPos)
        if self._n25BossBlockCanMoveMap[newPosIndex] then
            local surroundPiece = boardCmpt:GetPieceTypeByIndex(newPosIndex)
            if CanMatchPieceTypeList(surroundPiece, pieceTypeList) then
                if not retCanLink[newPosIndex] then
                    retCanLink[newPosIndex] = newPos
                end
                self:_MonsterGetConnectPosListByPieceTypeList(newPos, pieceTypeList, retCanLink)
            end
        end
    end
    return retCanLink
end

function UtilCalcServiceShare:_MonsterGetConnectPosListByPieceTypeList(pos, pieceTypeList, list)
    local newPosAroundPosList = self:_GetPosValidAround(pos, pieceTypeList)
    for _, newPos in ipairs(newPosAroundPosList) do
        local index = Vector2.Pos2Index(newPos)
        if not list[index] then
            list[index] = newPos
            self:_MonsterGetConnectPosListByPieceTypeList(newPos, pieceTypeList, list)
        end
    end
end

---@param targetCenterPos Vector2
---@param validSkillRange Vector2[]
function UtilCalcServiceShare:FindPosToTarget(targetCenterPos, validRange, compare)
    local posReturn
    ---@type SortedArray
    local posList = SortedArray:New(Algorithm.COMPARE_CUSTOM, compare)
    posList:AllowDuplicate()
    ---注意这里的排序函数，不同需求应当不同
    posList:Clear()
    for index, validPos in ipairs(validRange) do
        self:InsertSortedArray(posList, targetCenterPos, validPos, index)
    end
    if posList and posList:Size() > 0 then
        ---@type AiSortByDistance
        local sortData = posList:GetAt(1)
        posReturn = sortData.data
    end
    return posReturn
end

---@param sortedArray SortedArray
---@param centerPos Vector2 圆心
---@param workPos Vector2
function UtilCalcServiceShare:InsertSortedArray(sortedArray, centerPos, workPos, nIndex)
    ---@type AiSortByDistance
    local posData = AiSortByDistance:New(centerPos, workPos, nIndex)
    sortedArray:Insert(posData)
end

---@param casterEntity Entity
---@param targetID number
---@param pieceTypeList PieceType[]
function UtilCalcServiceShare:_GetMonster2PosLinkPathByPieceTypeList(casterPos, targetPos, pieceTypeList)
    local retPath = {}

    local bTargetCanConnect = true
    ---尝试用A*找一条能连通的路
    if bTargetCanConnect then
        local getFinalValidPosFunc = function(pos)
            local posList = {}
            table.insert(posList, pos)
            return posList
        end
        local getAroundValidPosFunc = function(pos, pieceTypeList)
            return self:_GetPosValidAround(pos, pieceTypeList)
        end
        local path = self:CalcPos2PosShortestPath(casterPos, targetPos, pieceTypeList, getFinalValidPosFunc,
            getAroundValidPosFunc)
        if path and #path > 0 then
            if #retPath == 0 then
                retPath = path
            end
            if #path < #retPath then
                retPath = path
            end
        end
    end
    return retPath
end

---@param pos Vector2
---@param pieceType PieceType
---@return Vector2[]
function UtilCalcServiceShare:_GetPosValidAround(pos, pieceTypeList)
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local newPosAroundPosList = {}
    for _, offset in ipairs(Offset8) do
        local offsetVec = Vector2(offset[1], offset[2])
        local newPos = pos + offsetVec
        local newPosIndex = Vector2.Pos2Index(newPos)
        if self._n25BossBlockCanMoveMap[newPosIndex] then
            local surroundPiece = boardCmpt:GetPieceTypeByIndex(newPosIndex)
            if CanMatchPieceTypeList(surroundPiece, pieceTypeList) then
                table.insert(newPosAroundPosList, newPos)
            end
        end
    end
    return newPosAroundPosList
end

--endregion N25吸血鬼Boss移动策略

--region 计算技能效果
function UtilCalcServiceShare:CalcSkillTargetEffect(casterEntityID, skillID, skillEffectType)
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local casterPos = casterEntity:GetGridPosition()

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(skillID)
    local skillTargetType = skillConfigData:GetSkillTargetType()
    local skillEffectArray = skillConfigData:GetSkillEffect()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillEffectCalcService
    local skillEffectCalcService = self._world:GetService("SkillEffectCalc")

    local skillResultList = {}

    for _, skillEffect in ipairs(skillEffectArray) do
        if skillEffect:GetEffectType() == skillEffectType then
            ---@type SkillScopeResult
            local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, casterEntity)
            local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, skillTargetType, scopeResult)

            ---@type SkillEffectCalcParam
            local skillEffectCalcParam = SkillEffectCalcParam:New(casterEntityID, targetIDList, skillEffect, skillID)

            local skillResult = skillEffectCalcService:CalcSkillEffectByType(skillEffectCalcParam)
            if skillResult then
                table.appendArray(skillResultList, skillResult)
            end
        end
    end

    return skillResultList
end
--endregion 计算技能效果
