require "command_base_handler"
_class("MovePathDownCommandHandler", CommandBaseHandler)
---@class MovePathDownCommandHandler: CommandBaseHandler
MovePathDownCommandHandler = MovePathDownCommandHandler

---@param cmd MovePathDoneCommand
function MovePathDownCommandHandler:DoHandleCommand(cmd)
    --Log.notice("DoHandleCommand,move path done")
    local chainPath = cmd:GetChainPath()
    local elementType = cmd:GetElementType()

    ---收到客户端发来的抬手命令，需要进行普攻和连锁技的计算
    ---然后将状态同步给客户端
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---通知玩家抬手，触发自爆怪逻辑
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type NTPlayerMoveStart
    local ntPlayerMoveStart = NTPlayerMoveStart:New()
    ntPlayerMoveStart:SetChainCount(#chainPath)
    ntPlayerMoveStart:SetChainPathType(elementType)
    ntPlayerMoveStart:SetTeamEntity(teamEntity)
    triggerSvc:Notify(ntPlayerMoveStart)
    ---处理自爆怪死亡逻辑
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    sMonsterShowLogic:DoAllMonsterDeadLogic()

    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideWeakLine, {[1] = elementType, [2] = #chainPath})
    self:_DoLinkLineLogic(cmd)

    local st = {}
    for i, v in ipairs(chainPath) do
        st[#st + 1] = Vector2.Pos2Index(v)
    end
    local s = table.concat(st, " ")
    Log.debug("[chainPath] ", s)

    local valid = true
    if BattleConst.Kick then
        valid = self:_CheckMovePathValid(teamEntity, elementType, chainPath)
        if not valid then
            Log.fatal("move path command invalid")
            return
        end
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    ---累积连线次数
    battleStatCmpt:AddTotalChainNum()

    ---设置逻辑计算需要的chainpath数据
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    logicChainPathCmpt:SetLogicChainPath(chainPath, elementType)
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    logicChainPathCmpt:SetChainRateAtIndex(1, 0)
    for i = 2, #chainPath do
        local finalChainRate, superGridNum = utilCalcSvc:GetChainDamageRateAtIndex(chainPath, i)
        logicChainPathCmpt:SetChainRateAtIndex(i, finalChainRate)
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local allMonsterPos = utilDataSvc:GetAllMonsterPos()
    logicChainPathCmpt:SetChainMonsterPosList(allMonsterPos)

    ---@type Vector2
    local oldPos = teamEntity:GetGridPosition()
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    skillLogicService:UpdateTeamGridLocationByChainPath(teamEntity, chainPath)

    ---@type SyncMoveServiceLogic
    local syncMoveSvcLogic = self._world:GetService("SyncMoveLogic")
    if syncMoveSvcLogic then
        syncMoveSvcLogic:OnMovePathDone(chainPath)
    end

    local ntSelectRoundTeamNormalBefore = NTSelectRoundTeamNormalBefore:New(elementType, chainPath)
    triggerSvc:Notify(ntSelectRoundTeamNormalBefore)

    ---@type L2RService
    local l2RSvc = self._world:GetService("L2R")
    --这个通知仍然不可以用来做表现，因为当前设计下没有合理的地方提供状态机TT来让它执行表现
    --这里添加是因为用到它的是一个修改表现数据的位置
    l2RSvc:L2RNTSelectRoundTeamNormalBefore(elementType, chainPath)

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    self:_CalcNormal(teamEntity, elementType)
    self:_DoRevertCutPathPrism(cmd)

    ---通知表现层，划线队列更新
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RChainPathData(teamEntity)

    ---埋点
    local combo = self._world:GetService("Battle"):GetLogicComboNum()
    self._world:GetDataLogger():AddDataLog("OnChainPath", table.count(chainPath) - 1, combo)
    self._world:GetDataLogger():AddDataLog("OnLinkEnd")
    self._world:GetDataLogger():AddDataLog("OnShowStart")

    ---这里要重新取chainPath
    local logicChainPath = logicChainPathCmpt:GetLogicChainPath()
    local newPos = logicChainPath[#logicChainPath]
    boardServiceLogic:UpdateEntityBlockFlag(teamEntity, oldPos, newPos)

    --抬手就可以统计单次划线
    if #logicChainPath >= 2 then
        battleStatCmpt:AddChainIndex()
        battleStatCmpt:SetOneMatchMaxNum(teamEntity,elementType, #logicChainPath - 1)
    end

    --通知表现层逻辑死亡状态
    self:_UpdateDeadMark()

    --通知主状态机，输入结束，可以切到下个状态（角色移动）
    self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 1)
end

function MovePathDownCommandHandler:_UpdateDeadMark()
    local deadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)
    local data = DataDeadMarkResult:New()
    for _, e in ipairs(deadGroup:GetEntities()) do
        data:AddDeadEntityID(e:GetID())
    end
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

---根据连线命令计算普攻
function MovePathDownCommandHandler:_CalcNormal(teamEntity, elementType)
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    skillLogicService:SelectTeam(teamEntity, elementType)
    skillLogicService:SelectNormalAttackTarget(teamEntity)
    skillLogicService:CalcNormalSkillDamage(teamEntity)
end

function MovePathDownCommandHandler:_CheckMovePathElement(cmdElementType, chainPath)
    local moveStartPos = chainPath[1]
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    ---依次检查连线队列里的剩余格子
    local pathPointIndex = 2
    local pathPointCount = #chainPath
    ---上一个连线点
    local lastPathPointPos = moveStartPos
    while pathPointIndex <= pathPointCount do
        local pathPointPos = chainPath[pathPointIndex]
        -- 当连线终点为出口时，不检查该位置的颜色
        if pathPointIndex == pathPointCount and (boardCmpt:IsPosExit(pathPointPos)) then
            break
        end

        ---检查当前点的元素类型是否匹配
        ---@type PieceType
        local gridPieceType = boardCmpt:GetPieceType(pathPointPos)
        if pathPointIndex == 2 then--第一个连线格子
            local mapForFirstChainPath = utilDataSvc:GetMapForFirstChainPath()
            if mapForFirstChainPath then
                gridPieceType = mapForFirstChainPath
            end
        end
        --该位置可以映射的颜色数组
        ---@type PieceType[]
        local gridPieceTypeMapList = boardCmpt:GetPieceTypeMapList(pathPointPos)
        local isMatch =
            self:_CheckPieceTypeMatch(gridPieceType, cmdElementType, pathPointIndex, chainPath, gridPieceTypeMapList)
        if not isMatch then
            local errorMsg =
                "MovePathValid failed,grid element no match pos: x = " ..
                pathPointPos.x ..
                    " y = " ..
                        pathPointPos.y ..
                            " client element = " .. cmdElementType .. " server element = " .. gridPieceType

            self:_HandleServerSyncFailed(BattleFailedType.PositionElementNoMatch, errorMsg)
            return false
        end
        if
            (cmdElementType == PieceType.Any and not table.intable(gridPieceTypeMapList, cmdElementType) and
                gridPieceType ~= PieceType.Any)
         then
            local errorMsg =
                "MovePathValid failed,Chain element no match pos: x = " ..
                pathPointPos.x ..
                    " y = " ..
                        pathPointPos.y .. " Chain element = " .. cmdElementType .. " server element = " .. gridPieceType

            self:_HandleServerSyncFailed(BattleFailedType.PositionElementNoMatch, errorMsg)
            return false
        end

        ---检查当前点与上一个点是否邻接
        pathPointIndex = pathPointIndex + 1
    end
    return true
end

function MovePathDownCommandHandler:_CheckMovePathConnect(cmdElementType, chainPath)
    ---@type UtilDataServiceShare
    local utilDataService = self._world:GetService("UtilData")
    if #chainPath > 3 then
        for i = 2, #chainPath - 1 do
            local pos1 = chainPath[i]
            local pos2 = chainPath[i + 1]
            ----最后一个格子不是出口和任意门 就需要检测
            local needCheck = self:_IsNeedCheckConnect(i,pos2,chainPath)
            if needCheck then
                local ret, msg = utilDataService:Is2PosCanConnect(pos1, pos2, cmdElementType,i)
                if not ret then
                    local errorMsg = self:_MakeConnectFailedMsg(cmdElementType,pos1,pos2,msg)
                    self:_HandleServerSyncFailed(BattleFailedType.ChainPathConnectInvalid, errorMsg)
                    return false
                end
            end
        end
    end
    return true
end

function MovePathDownCommandHandler:_MakeConnectFailedMsg(cmdElementType,pos1,pos2,msg)
    local errorMsg =
         "MovePathValid failed,connect Invalid   client element = " ..
             cmdElementType .. "pos1:" .. tostring(pos1) .. " pos2 = " .. tostring(pos2) .. msg
    return errorMsg
end

function MovePathDownCommandHandler:_IsNeedCheckConnect(curIndex,nextPos,chainPath)
    local nextIndex = curIndex + 1

    local isTwoColorChain,firstElementType,firstElementIndex = self:_CalcTwoColorChainData(chainPath)

    if isTwoColorChain then 
        if firstElementIndex == curIndex or firstElementIndex == nextIndex then 
            ---双色连线时，第一个非万色格子的前后不需要检测
            return false
        end
    end

    
    if nextIndex ~= #chainPath then 
        ---不是最后一个点，都要检查
        return true
    end

    ---@type UtilDataServiceShare
    local utilDataService = self._world:GetService("UtilData")
    local isPosExit = utilDataService:IsPosExit(nextPos)
    if isPosExit then
        ---如果是最后一个点，并且是出口，可以不检查 
        return false
    end
    
    local isDimensionDoor = utilDataService:IsPosDimensionDoor(nextPos)
    if isDimensionDoor then 
        ---如果是最后一个点，并且是任意门，可以不检查
        return false
    end

    return true
end

---检查连线是否合法
---@param cmdElementType ElementType
---@param chainPath Vector2[]
function MovePathDownCommandHandler:_CheckMovePathValid(teamEntity, cmdElementType, chainPath)
    local playerPos = teamEntity:GridLocation().Position

    ---如果上传连线队列没有信息
    if chainPath == nil or #chainPath < 1 then
        local errorMsg = "CheckMovePathValid failed,chain path has no point"
        self:_HandleServerSyncFailed(BattleFailedType.MovePathNoPoint, errorMsg)
        return false
    end

    ---检查第一个位置是否合法
    ---是否是服务端玩家所在位置
    local moveStartPos = chainPath[1]
    if moveStartPos.x ~= playerPos.x or moveStartPos.y ~= playerPos.y then
        local errorMsg =
            "chain path start pos invalid,client pos: x = " ..
            moveStartPos.x .. " y = " .. moveStartPos.y .. " server: pos: x = " .. playerPos.x .. " y = " .. playerPos.y
        self:_HandleServerSyncFailed(BattleFailedType.StartPathPosInvalid, errorMsg)
        return false
    end
    
    local connectCheckRes = self:_CheckMovePathConnect(cmdElementType, chainPath)
    if not connectCheckRes then 
        return false
    end

    local elementCheckRes = self:_CheckMovePathElement(cmdElementType, chainPath)
    if not elementCheckRes then 
        return false
    end

    return true
end

---@param cmd MovePathDoneCommand
function MovePathDownCommandHandler:_DoLinkLineLogic(cmd)
    local chainPath = cmd:GetChainPath()
    local board = self._world:GetBoardEntity():Board()
    local boardService = self._world:GetService("BoardLogic")
    local len = #chainPath
    if len > 1 then
        for i = 2, len do
            local curPos = chainPath[i]
            if board:IsPrismPiece(curPos) then ---处理棱镜对格子的修改
                local prePos = chainPath[i - 1]
                boardService:ApplyPrism(prePos, curPos)
            end
        end
    end
end
---在普攻计算完后 把被切掉的路径（中途中弩箭）中的棱镜格还原
function MovePathDownCommandHandler:_DoRevertCutPathPrism()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local board = self._world:GetBoardEntity():Board()
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local logicCutPath = logicChainPathCmpt:GetCutChainPath()
    if logicCutPath then
        local indexArray = {}
        for index, pos in pairs(logicCutPath) do--初始index大于1
            table.insert(indexArray,index)
        end
        table.sort(indexArray, function(a, b)
            return a > b
         end)--需要从后向前回退
        for _, tarIndex in ipairs(indexArray) do
            local pos = logicCutPath[tarIndex]
            if board:IsPrismPiece(pos) then ---处理棱镜对格子的修改
                boardService:UnapplyPrism(pos)
            end
        end
    end
    boardService:ResetPrismChangeRecord()--每次处理后需要重置棱镜记录
end
---@param gridPieceType PieceType 当前服务器上存的对应连线点的格子颜色
---@param cmdElementType PieceType 当前客户端上行的命令的颜色
---@param pathPointIndex number 当前检查的连线点的索引
---@param chainPath Vector2[] 当前的连线队列
---@param gridPieceTypeMapList PieceType[] 可以映射的颜色
function MovePathDownCommandHandler:_CheckPieceTypeMatch(
    gridPieceType,
    cmdElementType,
    pathPointIndex,
    chainPath,
    gridPieceTypeMapList)
    local isMatch = CanMatchPieceType(gridPieceType, cmdElementType)

    if not isMatch then
        local isTwoColorChain, firstElementType, firstElementIndex = self:_CalcTwoColorChainData(chainPath)
        if firstElementIndex == pathPointIndex and firstElementType == gridPieceType then
            isMatch = true
        ---Log.fatal("Check path done ok--------------")
        end

        if table.intable(gridPieceTypeMapList, PieceType.Any) or table.intable(gridPieceTypeMapList, cmdElementType) then
            isMatch = true
        end
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local isFirstStepUseMapPiece = false
        if pathPointIndex == 2 then--第一个连线格子
            local mapForFirstChainPath = utilDataSvc:GetMapForFirstChainPath()
            if mapForFirstChainPath then
                isMatch = CanMatchPieceType(mapForFirstChainPath, cmdElementType)
                isFirstStepUseMapPiece = true
            end
        end
        if not isFirstStepUseMapPiece then
            --该位置可以映射为其他颜色
            if utilDataSvc:IsPosCanMapOtherPiece(chainPath[pathPointIndex], cmdElementType, gridPieceType) then
                isMatch = true
            end
        end
    end
    return isMatch
end


---@param chainPath Vector2[] 当前的连线队列
function MovePathDownCommandHandler:_CalcTwoColorChainData(chainPath)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type BuffComponent
    local buffCmpt = teamEntity:BuffComponent()
    local isTwoColorChain = buffCmpt:GetBuffValue("TwoColorChain")

    local firstElementType = PieceType.None
    local firstElementIndex = -1
    if isTwoColorChain then 
        ---@type Entity
        local boardEntity = self._world:GetBoardEntity()
        ---@type BoardComponent
        local boardCmpt = boardEntity:Board()

        ---双色连线环境下，如果当前检查的连线点索引是第一个非万色格子，那就可以通过检查
        for index=2, #chainPath do 
            local curPos = chainPath[index]
            local curPieceType = boardCmpt:GetPieceType(curPos)
            if index == 2 then --连线第一步视为某种颜色
                local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
                if firstLinkMapPiece then
                    curPieceType = firstLinkMapPiece
                end
            end
            if curPieceType ~= PieceType.Any then 
                firstElementType = curPieceType
                firstElementIndex = index
                break
            end
        end
    end

    return isTwoColorChain,firstElementType,firstElementIndex
end