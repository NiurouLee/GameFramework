--[[------------------
    创建怪物位置逻辑
--]] ------------------
---@class CreateMonsterPosService:Object
_class("CreateMonsterPosService", Object)
CreateMonsterPosService = CreateMonsterPosService

function CreateMonsterPosService:Constructor(world)
    ---@type World
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---注册所有过程段执行器
    self._monsterRefreshFunc = {}

    self._monsterRefreshFunc[MonsterRefreshPosType.Position] = self._PositionRefresh
    self._monsterRefreshFunc[MonsterRefreshPosType.Random] = self._RandomRefresh
    self._monsterRefreshFunc[MonsterRefreshPosType.PositionTable] = self._PositionRandomRefresh
    self._monsterRefreshFunc[MonsterRefreshPosType.PositionHitBack] = self._PositionHitBackRefresh
    self._monsterRefreshFunc[MonsterRefreshPosType.PositionAndOffSet] = self._PositionAndOffSet
    self._monsterRefreshFunc[MonsterRefreshPosType.SelectFirstCanUse] = self._SelectFirstCanUsePos
    self._monsterRefreshFunc[MonsterRefreshPosType.PlayerCentered] = self._PlayerCentered
    self._monsterRefreshFunc[MonsterRefreshPosType.MonsterCentered] = self._MonsterCentered
    self._monsterRefreshFunc[MonsterRefreshPosType.PositionAndOffSetMultiBoard] = self._PositionAndOffSetMultiBoard
    self._monsterRefreshFunc[MonsterRefreshPosType.PositionOnExtraBoard] = self._PositionOnExtraBoard

    self._monsterRefreshExceptionFunc = {}
    self._monsterRefreshExceptionFunc[MonsterRefreshExceptionType.Random] = self._ExceptionRandom
    self._monsterRefreshExceptionFunc[MonsterRefreshExceptionType.ValidRing] = self._ExceptionValidRing
    self._monsterRefreshExceptionFunc[MonsterRefreshExceptionType.BackupTable] = self._ExceptionBackupTable
end

---@param refreshPosType MonsterRefreshPosType
---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:GetMonsterRefreshPos(refreshPosType, monsterRefreshParam)
    local pFunc = self._monsterRefreshFunc[refreshPosType]
    if not pFunc then --有的波次可能不刷怪
        return {}
    end
    return pFunc(self, monsterRefreshParam)
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_PositionRefresh(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local createMonsterAreaList = {}
    for i, monsterID in ipairs(monsterIDArray) do
        ---怪物实际占的格子坐标
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] MonsterID:", monsterID)
        local bodyAreaPosition = {}
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
        if i > #monsterPosArray then
            break
        end
        local monsterPosition = monsterPosArray[i]
        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        for _, p in ipairs(areaArray) do
            table.insert(bodyAreaPosition, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
        end
        --判断格子坐标位置是否可以放怪物
        if self:CheckPositionCanPlaceMonster(bodyAreaPosition, createMonsterAreaList, monsterRaceType) then
            for k, areaPos in ipairs(bodyAreaPosition) do
                table.insert(createMonsterAreaList, areaPos)
            end
            monsterArray[#monsterArray + 1] =
                self:_FillMonsterTransformParam(
                monsterRotationArray,
                i,
                monsterPosition,
                monsterID,
                monsterTransformParam
            )
            --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
            --monsterTransformParam:SetPosition(monsterPosition)
            --monsterTransformParam:SetForward(monsterForward)
            --monsterArray[#monsterArray + 1] = monsterTransformParam
            self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] Create MonsterID:", monsterID, "Pos:", tostring(monsterPosition))
        else
            Log.fatal("[[CreateMonsterPos] MonsterID:", monsterID, "Pos Invalid")
        end
    end
    return monsterArray
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_RandomRefresh(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    --用来存储已经刷了怪的坐标合集
    ---@type Vector2[]
    local monsterBodyPosArray = {}
    ---@type TrapTransformParam[]
    local trapArray = monsterRefreshParam:GetTrapArray()
    for k, v in ipairs(trapArray) do
        local posList = v:GetPositionList()
        for i = 1, #posList do
            table.insert(monsterBodyPosArray, posList[i])
        end
    end
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    for i, monsterID in ipairs(monsterIDArray) do
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] MonsterID:", monsterID)
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
        --判断格子坐标位置是否可以放怪物
        ---@type Vector2
        local monsterPosition = boardServiceLogic:GetRandomPiecePos(areaArray, monsterBodyPosArray, monsterRaceType)
        if monsterPosition then
            monsterArray[#monsterArray + 1] =
                self:_FillMonsterTransformParam(
                monsterRotationArray,
                i,
                monsterPosition,
                monsterID,
                monsterTransformParam
            )
            --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
            --monsterTransformParam:SetPosition(monsterPosition)
            --monsterTransformParam:SetForward(monsterForward)
            --monsterArray[#monsterArray + 1] = monsterTransformParam
            --把怪物占地面积放进去
            for k, p in ipairs(areaArray) do
                table.insert(monsterBodyPosArray, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
            end
            self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] Create MonsterID:", monsterID, "Pos:", tostring(monsterPosition))
        else
            Log.fatal("No Valid PiecePos in board ID", monsterID)
        end
    end
    return monsterArray
end
---@return Vector2[]
function CreateMonsterPosService:_MonsterPosAndOffsetArray2MonsterPos(monsterPosAndOffSetArray)
    local playPos = self:_GetPlayerPos()
    ---@param Vector2[]
    local ret = {}
    for i, v in ipairs(monsterPosAndOffSetArray) do
        local monsterPosition
        local monsterPosType = v[1]
        if monsterPosType == MonsterPosType.Position then
            monsterPosition = v[2]
        elseif monsterPosType == MonsterPosType.OffSet then
            monsterPosition = playPos + v[2]
        end
        table.insert(ret,monsterPosition)
    end
    return ret
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_PositionRandomRefresh(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    --用来存储已经刷了怪的坐标合集
    ---@type Vector2[]
    local monsterBodyPosArray = {}
    ---@type TrapTransformParam[]
    local trapArray = monsterRefreshParam:GetTrapArray()
    for k, v in ipairs(trapArray) do
        local posList = v:GetPositionList()
        for i = 1, #posList do
            table.insert(monsterBodyPosArray, posList[i])
        end
    end
    --local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    --local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    local monsterPosAndOffSetArray = monsterRefreshParam:GetMonsterPosAndOffSetArray()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local monsterPosArray = self:_MonsterPosAndOffsetArray2MonsterPos(monsterPosAndOffSetArray)
    for i, monsterID in ipairs(monsterIDArray) do
        local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] MonsterID:", monsterID)
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        --判断格子坐标位置是否可以放怪物
        ---@type Vector2
        local monsterPosition =
            boardServiceLogic:CreateMonsterGetValidPos(monsterPosArray, areaArray, monsterBodyPosArray, monsterRaceType)
        if monsterPosition then
            monsterArray[#monsterArray + 1] =
                self:_FillMonsterTransformParam(
                monsterRotationArray,
                i,
                monsterPosition,
                monsterID,
                monsterTransformParam
            )
            --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
            --monsterTransformParam:SetForward(monsterForward)
            --monsterTransformParam:SetPosition(monsterPosition)
            --monsterArray[#monsterArray + 1] = monsterTransformParam
            --把怪物占地面积放进去
            for k, p in ipairs(areaArray) do
                table.insert(monsterBodyPosArray, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
            end
            self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] Create MonsterID:", monsterID, "Pos:", tostring(monsterPosition))
        else
            if monsterRefreshParam:GetExceptionType() ~= MonsterRefreshExceptionType.None then
                monsterPosition =
                    self:_DoException(
                    monsterRefreshParam:GetExceptionType(),
                    areaArray,
                    monsterBodyPosArray,
                    monsterRaceType
                )
                if monsterPosition then
                    monsterArray[#monsterArray + 1] =
                        self:_FillMonsterTransformParam(
                        monsterRotationArray,
                        i,
                        monsterPosition,
                        monsterID,
                        monsterTransformParam
                    )
                    --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
                    --monsterTransformParam:SetForward(monsterForward)
                    --monsterTransformParam:SetPosition(monsterPosition)
                    --monsterArray[#monsterArray + 1] = monsterTransformParam
                    --把怪物占地面积放进去
                    for k, p in ipairs(areaArray) do
                        table.insert(monsterBodyPosArray, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
                    end
                    self:PrintCreateMonsterPosSvcLog(
                        "[[CreateMonsterPos] UseDoException Create MonsterID:",
                        monsterID,
                        "Pos:",
                        tostring(monsterPosition)
                    )
                else
                    Log.fatal("No Valid PiecePos in board After DoException")
                end
            else
                Log.fatal("No Valid PiecePos in board No DoException")
            end
        end
    end
    return monsterArray
end

function CreateMonsterPosService:_DoException(exceptionType, areaArray, monsterBodyPosArray, monsterRaceType,index,invalidPos,exceptionData)
    exceptionType = exceptionType or MonsterRefreshExceptionType.Random
    return self._monsterRefreshExceptionFunc[exceptionType](self, areaArray, monsterBodyPosArray, monsterRaceType,index,invalidPos,exceptionData)
end

function CreateMonsterPosService:_ExceptionRandom(areaArray, monsterBodyPosArray, monsterRaceType)
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    return boardService:GetRandomPiecePos(areaArray, monsterBodyPosArray, monsterRaceType)
end

function CreateMonsterPosService:_ExceptionValidRing(areaArray, monsterBodyPosArray, monsterRaceType,index,invalidPos)
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    for i=1,10 do
        local ringList = ComputeScopeRange.ComputeRange_SquareRing(invalidPos,#areaArray,i)
        local retPos =boardService:_GetValidPos(ringList,areaArray,monsterBodyPosArray,monsterRaceType)
        if retPos then
            return retPos
        end
    end
end

function CreateMonsterPosService:_ExceptionBackupTable(areaArray, monsterBodyPosArray, monsterRaceType, index, invalidPos, exceptionData)
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local posArray = exceptionData[index]
    local monsterPosArray = self:_MonsterPosAndOffsetArray2MonsterPos(posArray)
    local retPos =boardService:_GetValidPos(monsterPosArray,areaArray,monsterBodyPosArray,monsterRaceType)
    if not retPos then
        return boardService:GetRandomPiecePos(areaArray, monsterBodyPosArray, monsterRaceType)
    end
    return retPos
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
---即使怪物出场位置有人，也会计算位置，与MonsterRefreshPosType.Position区别
function CreateMonsterPosService:_PositionHitBackRefresh(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local createMonsterAreaList = {}
    for i, monsterID in ipairs(monsterIDArray) do
        local bodyAreaPosition = {}
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local monsterPosition = monsterPosArray[i]
        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        for _, p in ipairs(areaArray) do
            table.insert(bodyAreaPosition, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
        end
        for k, areaPos in ipairs(bodyAreaPosition) do
            table.insert(createMonsterAreaList, areaPos)
        end

        monsterArray[#monsterArray + 1] =
            self:_FillMonsterTransformParam(monsterRotationArray, i, monsterPosition, monsterID, monsterTransformParam)
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] Create MonsterID:", monsterID, "Pos:", tostring(monsterPosition))
    end
    return monsterArray
end
---@param monsterPos Vector2
---@return Vector2
function CreateMonsterPosService:_GetMonsterForward(forwardArray, index, monsterPos, monsterID)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    local canTurn = monsterConfigData:CanTurn(monsterID)
    if forwardArray and #forwardArray >= index then
        return forwardArray[index]
    else
        ---不能转向的怪默认Vector(0,0)
        if canTurn then
            local playerPos = self:_GetPlayerPos()
            return playerPos - monsterPos
        else
            return Vector2(0, -1)
        end
    end
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_PositionAndOffSet(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    local monsterPosAndOffSetArray = monsterRefreshParam:GetMonsterPosAndOffSetArray()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local exceptionData = monsterRefreshParam:GetExceptionData()
    --存储已经创建成功的怪物的占地面积
    ---@type Vector2[]
    local createMonsterAreaList = {}
    for i, monsterID in ipairs(monsterIDArray) do
        ---怪物实际占的格子坐标
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] MonsterID:", monsterID)
        local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
        ---@type Vector2[]
        local bodyAreaPosition = {}
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local monsterPosition = Vector2(0, 0)
        local monsterPosType = monsterPosAndOffSetArray[i][1]
        if monsterPosType == MonsterPosType.Position then
            monsterPosition = monsterPosAndOffSetArray[i][2]
        elseif monsterPosType == MonsterPosType.OffSet then
            local playPos = self:_GetPlayerPos()
            monsterPosition = playPos + monsterPosAndOffSetArray[i][2]
        end

        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        for _, p in ipairs(areaArray) do
            table.insert(bodyAreaPosition, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
        end
        --判断格子坐标位置是否可以放怪物
        if self:CheckPositionCanPlaceMonster(bodyAreaPosition, createMonsterAreaList, monsterRaceType) then
            for k, areaPos in ipairs(bodyAreaPosition) do
                table.insert(createMonsterAreaList, areaPos)
            end
            monsterArray[#monsterArray + 1] =
                self:_FillMonsterTransformParam(
                monsterRotationArray,
                i,
                monsterPosition,
                monsterID,
                monsterTransformParam
            )
            --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
            --monsterTransformParam:SetPosition(monsterPosition)
            --monsterTransformParam:SetForward(monsterForward)
            --monsterArray[#monsterArray + 1] = monsterTransformParam
            self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] Create MonsterID:", monsterID, "Pos:", tostring(monsterPosition))
        else
            if monsterRefreshParam:GetExceptionType() ~= MonsterRefreshExceptionType.None then
                monsterPosition =
                    self:_DoException(
                    monsterRefreshParam:GetExceptionType(),
                    areaArray,
                    createMonsterAreaList,
                    monsterRaceType,
                    i,
                    monsterPosition,
                    exceptionData
                )
                if monsterPosition then
                    monsterArray[#monsterArray + 1] =
                        self:_FillMonsterTransformParam(
                        monsterRotationArray,
                        i,
                        monsterPosition,
                        monsterID,
                        monsterTransformParam
                    )
                    --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
                    --monsterTransformParam:SetForward(monsterForward)
                    --monsterTransformParam:SetPosition(monsterPosition)
                    --monsterArray[#monsterArray + 1] = monsterTransformParam
                    --把怪物占地面积放进去
                    for k, p in ipairs(areaArray) do
                        table.insert(createMonsterAreaList, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
                    end
                    self:PrintCreateMonsterPosSvcLog(
                        "[[CreateMonsterPos] UseDoException Create MonsterID:",
                        monsterID,
                        "Pos:",
                        tostring(monsterPosition)
                    )
                else
                    Log.fatal("No Valid PiecePos in board After DoException")
                end
            else
                Log.fatal("No Valid PiecePos in board No DoException")
            end
            Log.fatal("[[CreateMonsterPos] MonsterID:", monsterID, "Pos Invalid")
        end
    end
    return monsterArray
end

function CreateMonsterPosService:_FillMonsterTransformParam(
    monsterRotationArray,
    index,
    monsterPosition,
    monsterID,
    monsterTransformParam)
    local monsterForward = self:_GetMonsterForward(monsterRotationArray, index, monsterPosition, monsterID)
    monsterTransformParam:SetForward(monsterForward)
    monsterTransformParam:SetPosition(monsterPosition)
    return monsterTransformParam
end

---@return Vector2
function CreateMonsterPosService:_GetPlayerPos()
    local boardEntity = self._world:GetBoardEntity()
    ---@type Vector2
    local playerPos = Vector2(0, 0)
    --已经创建棋盘了
    if boardEntity then
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        --存在玩家的时候取玩家的坐标
        if teamEntity then
            playerPos = teamEntity:GridLocation():GetGridPos()
        end
    else
        local levelConfigData = self._configService:GetLevelConfigData()
        playerPos = levelConfigData:GetPlayerBornPos()
    end
    return playerPos
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_SelectFirstCanUsePos(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local createMonsterAreaList = {}
    for i, monsterID in ipairs(monsterIDArray) do
        ---怪物实际占的格子坐标
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] MonsterID:", monsterID)
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
        if i > #monsterPosArray then
            break
        end
        --怪物的位置集合
        local monsterPosList = monsterPosArray[i]
        --怪物朝向集合
        local monsterRotationList = monsterRotationArray[i]
        --怪物身体区域
        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        --寻找第一个可用的位置
        for j = 1, #monsterPosList do
            local bodyAreaPosition = {}
            local monsterPosition = monsterPosList[j]
            for _, p in ipairs(areaArray) do
                table.insert(bodyAreaPosition, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
            end
            --判断格子坐标位置是否可以放怪物
            if self:CheckPositionCanPlaceMonster(bodyAreaPosition, createMonsterAreaList, monsterRaceType) then
                for k, areaPos in ipairs(bodyAreaPosition) do
                    table.insert(createMonsterAreaList, areaPos)
                end
                monsterArray[#monsterArray + 1] =
                    self:_FillMonsterTransformParam(
                    monsterRotationList,
                    j,
                    monsterPosition,
                    monsterID,
                    monsterTransformParam
                )
                self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] Create MonsterID:", monsterID, "Pos:", tostring(monsterPosition))
                break
            end
        end
    end
    return monsterArray
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_PlayerCentered(monsterRefreshParam)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        Log.exception("cfg_refresh_monster.MonsterRefreshType=8不适用于黑拳赛")
        return {}
    end

    local options = monsterRefreshParam:GetRefreshPosOptions()
    local preferRadius = options.preferRadius

    ---@type Entity
    local ePlayerTeam = self._world:Player():GetLocalTeamEntity()

    ---@type CreateMonsterPosTargetCenteredUnit
    local computer = CreateMonsterPosTargetCenteredUnit:New(self._world)
    computer:InitGridList(ePlayerTeam:GetGridPosition(), BlockFlag.MonsterLand & BlockFlag.MonsterFly)

    ---@type MonsterConfigData
    local monsterConfigData = self._world:GetService("Config"):GetMonsterConfigData()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local tMonsterTransformParam = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    for index, id in ipairs(monsterIDArray) do
        local cfgMonsterClass = monsterConfigData:GetMonsterClass(id)
        local area = cfgMonsterClass.Area
        local explainedArea = monsterConfigData:ExplainMonsterArea(area)
        local blockFlag = cfgMonsterClass.RaceType == MonsterRaceType.Fly and BlockFlag.MonsterFly or BlockFlag.MonsterLand
        local v2SummonPos = computer:GetPosByBlockFlag(blockFlag, preferRadius, explainedArea)
        if v2SummonPos then
            local genParam = MonsterTransformParam:New(id)
            self:_FillMonsterTransformParam(monsterRotationArray, index, v2SummonPos, id, genParam)
            table.insert(tMonsterTransformParam, genParam)
            computer:RemovePosFromCache(v2SummonPos, explainedArea)
        end
    end

    return tMonsterTransformParam
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_MonsterCentered(monsterRefreshParam)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        Log.exception("cfg_refresh_monster.MonsterRefreshType=9不适用于黑拳赛")
        return {}
    end

    local options = monsterRefreshParam:GetRefreshPosOptions()
    local preferRadius = options.preferRadius
    local centerMonsterID = options.centerMonsterID

    local tv2Center = {}
    for _, e in ipairs(self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)) do
        local cMonsterID = e:MonsterID()
        local monsterID = cMonsterID:GetMonsterID()
        if monsterID == centerMonsterID then
            table.insert(tv2Center, e:GetGridPosition())
        end
    end

    local tMonsterTransformParam = {}

    -- 符合要求的怪物周围都刷，对每个中心位置都要重新计算
    -- 前一次计算之后，要记住最终选定的格子，下一次计算时需要抠掉
    local tv2Possessed = {}
    for _, v2 in ipairs(tv2Center) do
        ---@type CreateMonsterPosTargetCenteredUnit
        local computer = CreateMonsterPosTargetCenteredUnit:New(self._world)
        computer:InitGridList(v2, BlockFlag.MonsterLand & BlockFlag.MonsterFly)

        -- 之前用掉的位置需要在计算前移除
        for _, v2Possessed in ipairs(tv2Possessed) do
            computer:RemovePosFromCache(v2Possessed)
        end

        ---@type MonsterConfigData
        local monsterConfigData = self._world:GetService("Config"):GetMonsterConfigData()
        local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
        local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
        for index, id in ipairs(monsterIDArray) do
            local cfgMonsterClass = monsterConfigData:GetMonsterClass(id)
            local area = cfgMonsterClass.Area
            local explainedArea = monsterConfigData:ExplainMonsterArea(area)
            local blockFlag = cfgMonsterClass.RaceType == MonsterRaceType.Fly and BlockFlag.MonsterFly or BlockFlag.MonsterLand
            local v2SummonPos = computer:GetPosByBlockFlag(blockFlag, preferRadius, explainedArea)
            if v2SummonPos then
                local genParam = MonsterTransformParam:New(id)
                self:_FillMonsterTransformParam(monsterRotationArray, index, v2SummonPos, id, genParam)
                table.insert(tMonsterTransformParam, genParam)
                computer:RemovePosFromCache(v2SummonPos, explainedArea)
                for _, v2Area in ipairs(explainedArea) do
                    local v2AbsBody = v2SummonPos + v2Area
                    table.insert(tv2Possessed, v2AbsBody)
                end
            end
        end
    end

    return tMonsterTransformParam
end

---判断格子队列上是否可以放置怪物
---@param posList Vector2[] 要检查合法性的目标格子
---@param extendMonsterAreaPosList Vector2[] 指定不能刷新的位置
---@param monsterRaceType MonsterRaceType 陆地怪还是飞行怪
---@return boolean
function CreateMonsterPosService:CheckPositionCanPlaceMonster(posList, extendMonsterAreaPosList, monsterRaceType)
    ---检查是否包含玩家位置，如果包含了玩家位置，说明该格子不能放怪
    local containPlayerPos = self:IsPosListContainPlayerPos(posList)
    if containPlayerPos then 
        return false
    end

    ---检查是否包括了指定的列表
    local containExtendPos = self:IsPosListContainExtendMonsterList(posList,extendMonsterAreaPosList)
    if containExtendPos then 
        return false
    end

    ---检查目标格子是否都有颜色
    local isAllValid = self:IsPosListAllHaveValidPieceType(posList)
    if not isAllValid then 
        return false
    end

    ---检查怪物类型是否会被阻挡，如果被阻挡了，不能放怪
    if self:IsPosListBlockMonsterRace(posList, monsterRaceType) then
        return false
    end

    return true    
end

---检查目标格子队列是否包括玩家位置
---@param posList Vector2[] 要检查合法性的目标格子
function CreateMonsterPosService:IsPosListContainPlayerPos(posList)
    local playerPosition = Vector2(0, 0)
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    --存在玩家的时候取玩家的坐标
    if teamEntity then
        local playerGridLocation = teamEntity:GridLocation()
        playerPosition = playerGridLocation.Position
    else
        --主角脚下格子变为灰色
        ---@type LevelConfigData
        local levelConfigData = self._configService:GetLevelConfigData()
        playerPosition = levelConfigData:GetPlayerBornPos()
    end

    for _, pos in ipairs(posList) do
        ---不能放到玩家的位置
        if playerPosition.x == pos.x and playerPosition.y == pos.y then
            self:PrintCreateMonsterPosSvcLog("Player In MonsterArea")
            return true
        end
    end
    return false
end

---检查指定的格子列表里是否全部都是有颜色的格子
---只要有一个无效，就返回false，全部有效，返回true
---@param posList Vector2[] 要检查的目标格子
function CreateMonsterPosService:IsPosListAllHaveValidPieceType(posList)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    for _, pos in ipairs(posList) do
        if not utilData:IsValidPiecePos(pos) then
            return false
        end
    end
    return true
end

---检查指定位置是否阻挡了指定的怪物类型
---@param posList Vector2[] 要检查的目标格子
---@param monsterRaceType MonsterRaceType 陆地怪还是飞行怪
function CreateMonsterPosService:IsPosListBlockMonsterRace(posList, monsterRaceType)
    if not monsterRaceType then
        Log.fatal("function Param monsterRaceType is Nil ")
        return true
    end

    ---@type BoardServiceLogic
    local boardLogicSvc = self._world:GetService("BoardLogic")

    for _, pos in ipairs(posList) do
        if monsterRaceType == MonsterRaceType.Land and boardLogicSvc:IsPosBlock(pos, BlockFlag.MonsterLand) then
            return true
        end
        if monsterRaceType == MonsterRaceType.Fly and boardLogicSvc:IsPosBlock(pos, BlockFlag.MonsterFly) then
            return true
        end
    end
    return false
end


---检查目标格子队列是否包括指定的一个位置列表
---@param posList Vector2[] 要检查合法性的目标格子
function CreateMonsterPosService:IsPosListContainExtendMonsterList(posList,extendMonsterAreaPosList)
    for _, pos in ipairs(posList) do
        if extendMonsterAreaPosList then
            for k, v in ipairs(extendMonsterAreaPosList) do
                if v == pos then
                    self:PrintCreateMonsterPosSvcLog("NewMonsterIn pos：", tostring(v))
                    return true
                end
            end
        end
    end
    return false
end

function CreateMonsterPosService:PrintCreateMonsterPosSvcLog(...)
    if self._world and self._world:IsDevelopEnv() then 
        Log.debug(...)
    end
end


--region 多面棋盘
---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_PositionAndOffSetMultiBoard(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    local monsterPosAndOffSetArray = monsterRefreshParam:GetMonsterPosAndOffSetArray()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local exceptionData = monsterRefreshParam:GetExceptionData()
    local boardIndex = monsterRefreshParam:GetBoardIndex()

    --存储已经创建成功的怪物的占地面积
    ---@type Vector2[]
    local createMonsterAreaList = {}
    for i, monsterID in ipairs(monsterIDArray) do
        ---怪物实际占的格子坐标
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] MonsterID:", monsterID)
        local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
        ---@type Vector2[]
        local bodyAreaPosition = {}
        ---@type MonsterTransformParam
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local monsterPosition = Vector2(0, 0)
        local monsterPosType = monsterPosAndOffSetArray[i][1]
        if monsterPosType == MonsterPosType.Position then
            monsterPosition = monsterPosAndOffSetArray[i][2]
        end

        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        for _, p in ipairs(areaArray) do
            table.insert(bodyAreaPosition, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
        end
        --判断格子坐标位置是否可以放怪物
        if
            self:CheckPositionCanPlaceMonsterMultiBoard(
                boardIndex,
                bodyAreaPosition,
                createMonsterAreaList,
                monsterRaceType
            )
         then
            monsterTransformParam:SetBoardIndex(boardIndex)

            for k, areaPos in ipairs(bodyAreaPosition) do
                table.insert(createMonsterAreaList, areaPos)
            end
            monsterArray[#monsterArray + 1] =
                self:_FillMonsterTransformParam(
                monsterRotationArray,
                i,
                monsterPosition,
                monsterID,
                monsterTransformParam
            )
            --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
            --monsterTransformParam:SetPosition(monsterPosition)
            --monsterTransformParam:SetForward(monsterForward)
            --monsterArray[#monsterArray + 1] = monsterTransformParam
            self:PrintCreateMonsterPosSvcLog(
                "[[CreateMonsterPos] Create MonsterID:",
                monsterID,
                "Pos:",
                tostring(monsterPosition)
            )
        else
            if monsterRefreshParam:GetExceptionType() ~= MonsterRefreshExceptionType.None then
                monsterPosition =
                    self:_DoException(
                    monsterRefreshParam:GetExceptionType(),
                    areaArray,
                    createMonsterAreaList,
                    monsterRaceType,
                    i,
                    monsterPosition,
                    exceptionData
                )
                if monsterPosition then
                    monsterArray[#monsterArray + 1] =
                        self:_FillMonsterTransformParam(
                        monsterRotationArray,
                        i,
                        monsterPosition,
                        monsterID,
                        monsterTransformParam
                    )
                    --local monsterForward= self:_GetMonsterForward(monsterRotationArray,i,monsterPosition,monsterID)
                    --monsterTransformParam:SetForward(monsterForward)
                    --monsterTransformParam:SetPosition(monsterPosition)
                    --monsterArray[#monsterArray + 1] = monsterTransformParam
                    --把怪物占地面积放进去
                    for k, p in ipairs(areaArray) do
                        table.insert(createMonsterAreaList, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
                    end
                    self:PrintCreateMonsterPosSvcLog(
                        "[[CreateMonsterPos] UseDoException Create MonsterID:",
                        monsterID,
                        "Pos:",
                        tostring(monsterPosition)
                    )
                else
                    Log.fatal("No Valid PiecePos in board After DoException")
                end
            else
                Log.fatal("No Valid PiecePos in board No DoException")
            end
            Log.fatal("[[CreateMonsterPos] MonsterID:", monsterID, "Pos Invalid")
        end
    end
    return monsterArray
end

---判断格子队列上是否可以放置怪物
---@param posList Vector2[] 要检查合法性的目标格子
---@param extendMonsterAreaPosList Vector2[] 指定不能刷新的位置
---@param monsterRaceType MonsterRaceType 陆地怪还是飞行怪
---@return boolean
function CreateMonsterPosService:CheckPositionCanPlaceMonsterMultiBoard(
    boardIndex,
    posList,
    extendMonsterAreaPosList,
    monsterRaceType)
    ---检查是否包括了指定的列表
    local containExtendPos = self:IsPosListContainExtendMonsterList(posList, extendMonsterAreaPosList)
    if containExtendPos then
        return false
    end

    ---检查目标格子是否都有颜色
    local isAllValid = self:IsPosListAllHaveValidPieceTypeMultiBoard(boardIndex, posList)
    if not isAllValid then
        return false
    end

    ---检查怪物类型是否会被阻挡，如果被阻挡了，不能放怪
    if self:IsPosListBlockMonsterRaceMultiBoard(boardIndex, posList, monsterRaceType) then
        return false
    end

    return true
end

---检查指定的格子列表里是否全部都是有颜色的格子
---只要有一个无效，就返回false，全部有效，返回true
---@param posList Vector2[] 要检查的目标格子
function CreateMonsterPosService:IsPosListAllHaveValidPieceTypeMultiBoard(boardIndex, posList)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    for _, pos in ipairs(posList) do
        if not utilData:IsValidPiecePosMultiBoard(boardIndex, pos) then
            return false
        end
    end
    return true
end

---检查指定位置是否阻挡了指定的怪物类型
---@param posList Vector2[] 要检查的目标格子
---@param monsterRaceType MonsterRaceType 陆地怪还是飞行怪
function CreateMonsterPosService:IsPosListBlockMonsterRaceMultiBoard(boardIndex, posList, monsterRaceType)
    if not monsterRaceType then
        Log.fatal("function Param monsterRaceType is Nil ")
        return true
    end

    ---@type BoardMultiServiceLogic
    local boardMultiServiceLogic = self._world:GetService("BoardMultiLogic")

    for _, pos in ipairs(posList) do
        if
            monsterRaceType == MonsterRaceType.Land and
                boardMultiServiceLogic:IsPosBlockMultiBoard(boardIndex, pos, BlockFlag.MonsterLand)
         then
            return true
        end
        if
            monsterRaceType == MonsterRaceType.Fly and
                boardMultiServiceLogic:IsPosBlockMultiBoard(boardIndex, pos, BlockFlag.MonsterFly)
         then
            return true
        end
    end
    return false
end
--endregion 多面棋盘

--region 扩展棋盘
---@param monsterRefreshParam LevelMonsterRefreshParam
---@return MonsterTransformParam[]
function CreateMonsterPosService:_PositionOnExtraBoard(monsterRefreshParam)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type MonsterTransformParam[]
    local monsterArray = {}
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local createMonsterAreaList = {}
    for i, monsterID in ipairs(monsterIDArray) do
        ---怪物实际占的格子坐标
        self:PrintCreateMonsterPosSvcLog("[[CreateMonsterPos] MonsterID:", monsterID)
        local bodyAreaPosition = {}
        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
        if i > #monsterPosArray then
            break
        end
        local monsterPosition = monsterPosArray[i]
        local areaArray = monsterConfigData:GetMonsterArea(monsterID)
        for _, p in ipairs(areaArray) do
            table.insert(bodyAreaPosition, Vector2(monsterPosition.x + p.x, monsterPosition.y + p.y))
        end
        --判断格子坐标位置是否可以放怪物
        if self:CheckPositionCanPlaceMonsterOnExtraBoard(bodyAreaPosition, createMonsterAreaList, monsterRaceType) then
            for k, areaPos in ipairs(bodyAreaPosition) do
                table.insert(createMonsterAreaList, areaPos)
            end
            monsterArray[#monsterArray + 1] =
                self:_FillMonsterTransformParam(
                monsterRotationArray,
                i,
                monsterPosition,
                monsterID,
                monsterTransformParam
            )

            self:PrintCreateMonsterPosSvcLog(
                "[[CreateMonsterPos] Create MonsterID:",
                monsterID,
                "Pos:",
                tostring(monsterPosition)
            )
        else
            --也要支持类型5的刷新
            if self:CheckPositionCanPlaceMonster(bodyAreaPosition, createMonsterAreaList, monsterRaceType) then
                for k, areaPos in ipairs(bodyAreaPosition) do
                    table.insert(createMonsterAreaList, areaPos)
                end
                monsterArray[#monsterArray + 1] =
                    self:_FillMonsterTransformParam(
                    monsterRotationArray,
                    i,
                    monsterPosition,
                    monsterID,
                    monsterTransformParam
                )

                self:PrintCreateMonsterPosSvcLog(
                    "[[CreateMonsterPos] Create MonsterID:",
                    monsterID,
                    "Pos:",
                    tostring(monsterPosition)
                )
            else
                Log.fatal("[[CreateMonsterPos] MonsterID:", monsterID, "Pos Invalid")
            end
        end
    end
    return monsterArray
end

---判断格子队列上是否可以放置怪物
---@param posList Vector2[] 要检查合法性的目标格子
---@param extendMonsterAreaPosList Vector2[] 指定不能刷新的位置
---@param monsterRaceType MonsterRaceType 陆地怪还是飞行怪
---@return boolean
function CreateMonsterPosService:CheckPositionCanPlaceMonsterOnExtraBoard(
    posList,
    extendMonsterAreaPosList,
    monsterRaceType)
    ---检查是否包括了指定的列表
    local containExtendPos = self:IsPosListContainExtendMonsterList(posList, extendMonsterAreaPosList)
    if containExtendPos then
        return false
    end

    ---检查目标格子是在额外棋盘内
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()
    for _, pos in ipairs(posList) do
        if not table.intable(extraBoardPosRange, pos) then
            return false
        end
    end

    return true
end

--endregion 扩展棋盘
