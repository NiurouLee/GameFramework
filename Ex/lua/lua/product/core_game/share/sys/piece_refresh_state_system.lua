--[[------------------------------------------------------------------------------------------
    PieceRefreshSystem：刷新格子
]] --------------------------------------------------------------------------------------------

---@class PieceRefreshSystem:MainStateSystem
_class("PieceRefreshSystem", MainStateSystem)
PieceRefreshSystem = PieceRefreshSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PieceRefreshSystem:_GetMainStateID()
    return GameStateID.PieceRefresh
end

---@param TT token 协程识别码，服务端是nil
function PieceRefreshSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---逻辑上替换格子
    local result = self:_DoLogicFillPiece(teamEntity)
    ---表现上替换格子
    self:_DoRenderFillPiece(TT, result)
    --同步格子颜色
    self:_DoLogicSyncPieceType()
    self:_DoRenderShowStoryTips(TT)
    ---切换主状态机
    self:_DoLogicSwitchState()
end

--region 逻辑接口
function PieceRefreshSystem:_DoLogicSwitchState()
    self._world:EventDispatcher():Dispatch(GameEventType.PieceRefreshFinish, 1)
end

---刷新格子
---返回一个参数代表本次刷新改的格子列表
---@type LogicChainPathComponent
function PieceRefreshSystem:_DoLogicFillPiece(teamEntity)
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    if #logicChainPathCmpt:GetLogicChainPath() == 0 then
        return
    end
    local result = {}
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    local pieceRefreshType, fallingDir, param = affixSvc:ReplacePieceRefreshType()
    result.pieceRefreshType = pieceRefreshType
    
    if pieceRefreshType == PieceRefreshType.Inplace then
        self:CalcPieceRefreshInplace(teamEntity, result) --计算连线新刷的格子颜色
    elseif pieceRefreshType == PieceRefreshType.FallingDown then
        self:CalcPieceFallingDown(teamEntity, fallingDir, result)
    elseif pieceRefreshType == PieceRefreshType.Destroy then
        local trapID = param:GetGapTrapID()
        self:CalcPieceDestroy(teamEntity, trapID, result)
    end

    return result
end

---计算连线后的格子填充列表
function PieceRefreshSystem:CalcPieceRefreshInplace(teamEntity, result)
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local newPiecePosList = {}
    local chainPath = logicChainPathCmpt:GetLogicChainPath()
    for _, v in ipairs(chainPath) do
        newPiecePosList[#newPiecePosList + 1] = Vector2(v.x, v.y)
    end
    local lastPos = chainPath[#chainPath]
    --刷格子计数
    self._world:BattleStat():AddPieceRefreshCount(1)

    ---@type BoardServiceLogic
    local boardLogicSvc = self._world:GetService("BoardLogic")
    boardLogicSvc:RemoveEntityBlockFlag(teamEntity, lastPos)
    ---计算出要填充的列表
    local pieceFillTable = boardLogicSvc:SupplyPieceList(newPiecePosList)
    ---连线最后一个点是角色将要站立的目标点，判断是否能转灰色
    local lastGrid = pieceFillTable[#pieceFillTable]
    local posBlockChangeColor = boardLogicSvc:IsPosBlock(Vector2(lastGrid.x, lastGrid.y), BlockFlag.ChangeElement) --目标点是否阻挡变色
    if not posBlockChangeColor then
        lastGrid.color = PieceType.None
    end
    boardLogicSvc:SetEntityBlockFlag(teamEntity, lastPos)
    result.inplaceResult = pieceFillTable

    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    ---@type table<Vector2,PieceType>
    local oldGridList = {}
    for index, pos in ipairs(pieceFillTable) do
        ---@type PieceType
        if index > 1 then
            local pieceType = boardCmpt:GetPieceType(pos)
            oldGridList[pos] = pieceType
        end
    end

    boardCmpt:FillPieces(pieceFillTable)

    ---@type table<number,Vector2,PieceType>
    local newGridList = {}
    for index, v in ipairs(pieceFillTable) do
        if index < #pieceFillTable then
            newGridList[index] = {pos = Vector2(v.x, v.y), pieceType = v.color}
        end
    end

    local ntRefreshGridOnPetMoveDone = NTRefreshGridOnPetMoveDone:New(oldGridList, newGridList, teamEntity)
    local ntGridConvert
    local tConvertInfo = {}
    for _, grid in ipairs(result.inplaceResult) do
        local convertInfo = NTGridConvert_ConvertInfo:New(Vector2(grid.x, grid.y), PieceType.None, grid.color)
        table.insert(tConvertInfo, convertInfo)
    end
    ntGridConvert = NTGridConvert:New(boardEntity, tConvertInfo)

    triggerSvc:Notify(ntRefreshGridOnPetMoveDone)
    triggerSvc:Notify(ntGridConvert)

    result.ntRefreshGridOnPetMoveDone = ntRefreshGridOnPetMoveDone
    result.ntGridConvert = ntGridConvert
end

--连线后掉落格子
function PieceRefreshSystem:CalcPieceFallingDown(teamEntity, fallingDir, result)
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local posList = {}
    local chainPath = logicChainPathCmpt:GetLogicChainPath()
    for _, v in ipairs(chainPath) do
        posList[#posList + 1] = Vector2(v.x, v.y)
    end

    ---@type BoardServiceLogic
    local boardLogicSvc = self._world:GetService("BoardLogic")
    boardLogicSvc:SyncGridTilesColor()
    local delset, newset, movset, rolegrid = boardLogicSvc:FallGrids(posList, fallingDir, teamEntity)
    result.delset = delset
    result.newset = newset
    result.movset = movset
    result.rolegrid = rolegrid

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    for _, v in ipairs(movset) do
        boardCmpt.Pieces[v.to.x][v.to.y] = v.color
    end
    for _, v in ipairs(newset) do
        boardCmpt.Pieces[v.pos.x][v.pos.y] = v.color
    end
    if rolegrid.color then
        boardCmpt.Pieces[rolegrid.pos.x][rolegrid.pos.y] = rolegrid.color
    end

    local oldGridList = {}
    for i, v in ipairs(delset) do
        if i > 1 then
            local pieceType = boardCmpt:GetPieceType(v.pos)
            oldGridList[v.pos] = v.color
        end
    end
    local newGridList = {}
    for i, v in ipairs(newset) do
        newGridList[i] = {pos = Vector2(v.x, v.y), pieceType = v.color}
    end

    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    local ntRefreshGridOnPetMoveDone = NTRefreshGridOnPetMoveDone:New(oldGridList, newGridList, teamEntity)
    local ntGridConvert
    local tConvertInfo = {}
    for _, v in ipairs(newset) do
        local convertInfo = NTGridConvert_ConvertInfo:New(v.pos, PieceType.None, v.color)
        table.insert(tConvertInfo, convertInfo)
    end
    ntGridConvert = NTGridConvert:New(boardEntity, tConvertInfo)

    triggerSvc:Notify(ntRefreshGridOnPetMoveDone)
    triggerSvc:Notify(ntGridConvert)

    result.ntRefreshGridOnPetMoveDone = ntRefreshGridOnPetMoveDone
    result.ntGridConvert = ntGridConvert

    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    --可以移动的机关
    local filter = function(e)
        return e:HasTrapID() and e:Trap():FallWithGrid() and not e:HasDeadMark()
    end
    --怪物
    local filter2 = function(e)
        return e:HasMonsterID()
    end
    local moveTraps = {}
    local triggerTraps = {}
    local movePrisms = {}
    for _, v in ipairs(movset) do
        local isPrism = boardCmpt:IsPrismPiece(v.from)
        local prismEntityID = boardCmpt:GetPrismEntityIDAtPos(v.from)
        if isPrism then
            boardCmpt:RemovePrismPiece(v.from)
            boardCmpt:AddPrismPiece(v.to, prismEntityID)
            movePrisms[#movePrisms + 1] = {from = v.from, to = v.to}
        end
        local es = boardCmpt:GetPieceEntities(v.from, filter)
        local ms = boardCmpt:GetPieceEntities(v.to, filter2)
        for i, e in ipairs(es) do
            moveTraps[#moveTraps + 1] = {entity = e, from = v.from, to = v.to}
            --修改棋盘数据
            e:SetGridPosition(v.to)
            boardLogicSvc:UpdateEntityBlockFlag(e, v.from, v.to)
            if #ms > 0 then
                local triggerEntity = ms[1]
                local tps, triggerResults = trapSvc:CalcTrapTriggerSkill(e, triggerEntity)
                if tps then
                    for i, trap in ipairs(tps) do
                        local skillResult = triggerResults[i]
                        triggerTraps[#triggerTraps + 1] = {trap, skillResult, triggerEntity}
                    end
                end
            end
        end
    end

    result.movePrisms = movePrisms
    result.moveTraps = moveTraps
    result.triggerTraps = triggerTraps
end

---连线后删除格子
---实现机制：连线路径上的所有机关删除，然后召唤阻挡除飞行怪之外的其他一切的机关
---备注：连线路径上若有怪物【歌尔蒂连线可穿过怪物】，则此格子不做处理，同原地刷新的方式一样处理
function PieceRefreshSystem:CalcPieceDestroy(teamEntity, trapID, result)
    local isUseInPlaceType = false
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainPath = logicChainPathCmpt:GetLogicChainPath()
    if #chainPath < 2 then
        ---原地双击不销毁格子 
        isUseInPlaceType = true
    end

    ---极光时刻不销毁连线格子 连线刷新格子
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if (battleStatCmpt:IsRoundAuroraTime()) then
        isUseInPlaceType = true
        result.pieceRefreshType = PieceRefreshType.Inplace
    end

    ---走正常连线刷新格子
    if (isUseInPlaceType) then
        result.pieceRefreshType = PieceRefreshType.Inplace
        self:CalcPieceRefreshInplace(teamEntity, result)
        return
    end

    --筛选机关使用
    local trapFilter = function(e)
        if e:HasTrapID() and not e:HasDeadMark() then
            return true
        end
        return false
    end
    
    --筛选怪物使用
    local monsterFilter = function(e)
        if e:HasMonsterID() and not e:HasDeadMark() then
            return true
        end

        ---@type OutsideRegionComponent
        local outsideRegion = e:OutsideRegion()
        if outsideRegion and outsideRegion:GetMonsterID() then
            return true
        end

        return false
    end

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()

    local refreshPiecePosList = {}
    local destroyPosList = {}
    local destroyTrapList = {}
    for i = 1, #chainPath - 1 do
        local pos = Vector2(chainPath[i].x, chainPath[i].y)

        local trapList = boardCmpt:GetPieceEntities(pos, trapFilter)
        local monsterList = boardCmpt:GetPieceEntities(pos, monsterFilter)
        if #monsterList > 0 then
            ---格子上有怪物，则需要刷新转色
            refreshPiecePosList[#refreshPiecePosList + 1] = pos
        else
            if #trapList > 0 then
                ---格子上只有机关，则需要删掉机关
                table.appendArray(destroyTrapList, trapList)
            end
            ---删格子
            destroyPosList[#destroyPosList + 1] = pos
        end
    end
    
    ---删除机关
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local destroyTrapIDList = {}
    for _, trapEntity in ipairs(destroyTrapList) do
        trapEntity:Attributes():Modify("HP", 0)
        ---添加死亡标记并关闭死亡技能
        trapServiceLogic:AddTrapDeadMark(trapEntity, true)
        destroyTrapIDList[#destroyTrapIDList + 1] = trapEntity:GetID()
    end
    if #destroyTrapIDList > 0 then
        result.destroyTrapIDList = destroyTrapIDList
    end

    ---在需删除的格子位置创建特殊机关
    local newTrapIDList = {}
    for _, pos in ipairs(destroyPosList) do
        local trapEntity = trapServiceLogic:CreateTrap(trapID, pos, Vector2.up)
        if trapEntity then
            newTrapIDList[#newTrapIDList + 1] = trapEntity:GetID()
        end
    end
    if #newTrapIDList > 0 then
        result.newTrapIDList = newTrapIDList
    end

    ---连线终点处理
    local lastPos = chainPath[#chainPath]
    refreshPiecePosList[#refreshPiecePosList + 1] = lastPos

    self._world:BattleStat():AddPieceRefreshCount(1)

    ---@type BoardServiceLogic
    local boardLogicSvc = self._world:GetService("BoardLogic")
    boardLogicSvc:RemoveEntityBlockFlag(teamEntity, lastPos)
    ---计算出要填充的列表
    local pieceFillTable = boardLogicSvc:SupplyPieceList(refreshPiecePosList)
    ---连线最后一个点是角色将要站立的目标点，判断是否能转灰色
    local lastGrid = pieceFillTable[#pieceFillTable]
    ---是否阻挡变色
    local posBlockChangeColor = boardLogicSvc:IsPosBlock(Vector2(lastGrid.x, lastGrid.y), BlockFlag.ChangeElement) 
    if not posBlockChangeColor then
        lastGrid.color = PieceType.None
    end
    boardLogicSvc:SetEntityBlockFlag(teamEntity, lastPos)
    result.inplaceResult = pieceFillTable

    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type table<Vector2,PieceType>
    local oldGridList = {}
    for _, pos in ipairs(pieceFillTable) do
        ---@type PieceType
        local pieceType = boardCmpt:GetPieceType(pos)
        oldGridList[pos] = pieceType
    end

    boardCmpt:FillPieces(pieceFillTable)

    ---@type table<number,Vector2,PieceType>
    local newGridList = {}
    for index, v in ipairs(pieceFillTable) do
        if index < #pieceFillTable then
            newGridList[index] = { pos = Vector2(v.x, v.y), pieceType = v.color }
        end
    end

    local ntRefreshGridOnPetMoveDone = NTRefreshGridOnPetMoveDone:New(oldGridList, newGridList, teamEntity)
    local tConvertInfo = {}
    for _, grid in ipairs(result.inplaceResult) do
        local convertInfo = NTGridConvert_ConvertInfo:New(Vector2(grid.x, grid.y), PieceType.None, grid.color)
        table.insert(tConvertInfo, convertInfo)
    end
    local ntGridConvert = NTGridConvert:New(boardEntity, tConvertInfo)

    triggerSvc:Notify(ntRefreshGridOnPetMoveDone)
    triggerSvc:Notify(ntGridConvert)

    result.ntRefreshGridOnPetMoveDone = ntRefreshGridOnPetMoveDone
    result.ntGridConvert = ntGridConvert
end

--endregion

-------------------------表现接口----------------------------------

function PieceRefreshSystem:_DoRenderFillPiece(TT, result)
end

function PieceRefreshSystem:_DoRenderShowStoryTips(TT)
end
