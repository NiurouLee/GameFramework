--[[------------------------------------------------------------------------------------------
    UtilDataServiceShare : 只读状态服务
    此对象里的服务只能查询逻辑数据，禁止修改逻辑数据
]] --------------------------------------------------------------------------------------------
_class("UtilDataServiceShare", BaseService)
---@class UtilDataServiceShare: BaseService
UtilDataServiceShare = UtilDataServiceShare

function UtilDataServiceShare:Constructor(world)
    self._world = world
end

function UtilDataServiceShare:Initialize()
    ---@type BoardServiceLogic
    self._boardLogicSvc = self._world:GetService("BoardLogic")
end

---获取状态机的当前状态的ID
---@return GameStateID
function UtilDataServiceShare:GetCurMainStateID()
    local gameFsmStateID = GameStateID.Invalid
    local hasGameFsm = self._world:HasGameFSM()
    if hasGameFsm then
        ---@type GameFSMComponent
        local gameFsmCmpt = self._world:GameFSM()
        gameFsmStateID = gameFsmCmpt:CurStateID()
    end

    return gameFsmStateID
end

function UtilDataServiceShare:GetMainStateInputEnable()
    local enable = false
    local hasGameFsm = self._world:HasGameFSM()
    if hasGameFsm then
        ---@type GameFSMComponent
        local gameFsmCmpt = self._world:GameFSM()
        enable = gameFsmCmpt:GetHandleInputEnable()
    end

    return enable
end

--region BoardEntity

function UtilDataServiceShare:GetReplicaGridEntityData()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()
    local gridEntityData = boardComponent:GetGridEntityData()

    if not gridEntityData then
        return
    end

    local extraBoardPosList = self:GetExtraBoardPosList()
    local replica = {}
    for k, v in pairs(gridEntityData) do
        local posWork = Vector2(k.x, k.y)
        --主棋盘面的额外棋盘位置不刷新格子颜色
        if not table.intable(extraBoardPosList, posWork) then
            replica[k] = v
        end
    end

    return replica
end

function UtilDataServiceShare:GetReplicaBoardPieces()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()

    local replica = {}
    for x, col in pairs(boardComponent.Pieces) do
        replica[x] = {}
        for y, grid in pairs(col) do
            replica[x][y] = grid
        end
    end

    return replica
end

function UtilDataServiceShare:GetGridEntityByPos(gridPos)

end

function UtilDataServiceShare:IsPrismPiece(gridPos)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()

    return boardComponent:IsPrismPiece(gridPos)
end

function UtilDataServiceShare:GetPrismPieceEffectType(gridPos)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()

    return boardComponent:GetPrismPieceEffectType(gridPos)
end

function UtilDataServiceShare:IsPrismPieceMultiBoard(boardIndex, gridPos)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardMultiComponent
    local boardMultiComponent = boardEntity:BoardMulti()

    return boardMultiComponent:IsPrismPiece(boardIndex, gridPos)
end

--endregion BoardEntity

function UtilDataServiceShare:PlayerIsDead(teamEntity)
    -- 这里只能引用battleSvc，因为battleSvc自己也是派生的，对应函数不能直接废除
    ---@type BattleService
    local battlesvc = self._world:GetService("Battle")
    return battlesvc:PlayerIsDead(teamEntity)
end

function UtilDataServiceShare:GetEntityIDByPstID(checkPstID)
    local casterPetEntityID = -1
    local petPstIDGroup = self._world:GetGroup(self._world.BW_WEMatchers.PetPstID)
    for _, e in ipairs(petPstIDGroup:GetEntities()) do
        ---@type PetPstIDComponent
        local petPstIDCmpt = e:PetPstID()
        local pstID = petPstIDCmpt:GetPstID()
        if pstID == checkPstID then
            casterPetEntityID = e:GetID()
        end
    end

    return casterPetEntityID
end

--region Board

function UtilDataServiceShare:GetPlayerArea()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetPlayerArea()
end

function UtilDataServiceShare:GetGridTiles()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetGridTiles()
end

---获取某个Entity的元素属性，要求目标身上挂有Element组件
---可能是主属性也可能是副属性
---@param entity Entity
function UtilDataServiceShare:GetEntityElementType(entity)
    ---@type ElementComponent
    local elementCmpt = entity:Element()
    if elementCmpt == nil then
        Log.fatal("GetEntityElementType failed,no element cmpt")
        return
    end

    local elementType = PieceType.None

    local useSecondary = elementCmpt:IsUseSecondaryType()
    if useSecondary == true then
        elementType = elementCmpt:GetSecondaryType()
    else
        elementType = elementCmpt:GetPrimaryType()
    end

    return elementType
end

---查找特定位置特定的Entity[击退的block数据和位置数据不一致，不能用这个函数]
---@param nEntityType EnumTargetEntity
function UtilDataServiceShare:FindEntityByPosAndType(pos, nEntityType, nTypeParam)
    local pieceBlockData = self:FindBlockByPos(pos)
    if nil == pieceBlockData then
        return {}
    end
    return pieceBlockData:FindEntity(self._world, nEntityType, nTypeParam)
end

---@param pos Vector2
---@return PieceType|nil
function UtilDataServiceShare:IsValidPiecePos(pos)
    ---@type Entity
    local eBoard = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = eBoard:Board()
    return cBoard:GetPieceData(pos)
end

---@param pos Vector2
---@return PieceBlockData|nil
function UtilDataServiceShare:FindBlockByPos(pos)
    local eBoard = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = eBoard:Board()
    return cBoard:FindBlockByPos(pos)
end

---@param pos Vector2
---@param blockFlag BlockFlag
---@return bool
function UtilDataServiceShare:IsPosBlock(pos, blockFlag)
    if not pos then
        return false
    end
    if not self:IsValidPiecePos(pos) then
        return true --棋盘外的位置一律阻挡
    end
    if not blockFlag then
        return false
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    if nil == pieceBlock then
        return true
    end
    return pieceBlock:CheckBlock(blockFlag)
end

---@param pos Vector2
---@param blockFlag BlockFlag
---@return bool
---判断玩家是否可以对该位置连线。连线专用（可以在怪物脚下移动）
function UtilDataServiceShare:IsPosBlockLinkLineForChain(pos)
    if not pos then
        return false
    end
    if not self:IsValidPiecePos(pos) then
        return true --棋盘外的位置一律阻挡
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    if nil == pieceBlock then
        return true
    end

    --只判断阻挡可能是机关导致的阻挡
    local isBlock = pieceBlock:CheckBlock(BlockFlag.LinkLine)
    --不阻挡就直接范围
    if isBlock == false then
        return false
    end

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    --连线可以穿过怪物脚下
    local chainAcrossMonster = logicChainPathCmpt:GetChainAcrossMonster()
    if chainAcrossMonster then
        --该位置有怪物
        local isHaveMonster = self:IsPosListHaveMonster({ pos })
        --如果可以穿怪，该位置又有怪物，则视为不阻挡。（写的时候不存在阻挡移动的机关和怪物在同一位置）
        if isHaveMonster then
            return false
        end
    end

    return isBlock
end

---@param pos Vector2
---@param canLinkMonster boolean
---@return boolean
---判断玩家是否可以对该位置连线。主动技预览阶段连线专用（可以在怪物脚下移动）
function UtilDataServiceShare:IsPosBlockForPreviewLinkLine(pos, canLinkMonster)
    if not pos then
        return false
    end
    if not self:IsValidPiecePos(pos) then
        return true --棋盘外的位置一律阻挡
    end

    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    if nil == pieceBlock then
        return true
    end

    --只判断阻挡可能是机关导致的阻挡
    local isBlock = pieceBlock:CheckBlock(BlockFlag.LinkLine)
    --不阻挡就直接返回
    if isBlock == false then
        return false
    end

    if canLinkMonster then
        --该位置有怪物
        local isHaveMonster = self:GetMonsterAtPos(pos)
        --如果可以穿怪，该位置又有怪物，则视为不阻挡
        if isHaveMonster then
            return false
        end
    end

    return isBlock
end

---判断玩家是否可以以该位置作为移动连线的终点
function UtilDataServiceShare:IsPosBlockLinkLineForChainChainEnd(pos)
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    local isBlock = pieceBlock:CheckBlock(BlockFlag.LinkLine)
    return isBlock
end

--该位置可以在连线阶段映射为其他颜色
function UtilDataServiceShare:IsPosCanMapOtherPiece(pos, chainPieceType, previewPieceType)
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()

    local mapByPieceType = boardComponent:GetMapByPieceType()
    if not mapByPieceType or table.count(mapByPieceType) == 0 then
        return false
    end

    for sourcePiece, targetPiece in pairs(mapByPieceType) do
        --连线位置的颜色 == 映射颜色的key
        if previewPieceType == sourcePiece then
            --映射的万色
            if targetPiece == PieceType.Any then
                return true
            end

            if targetPiece == chainPieceType then
                return true
            end

            break
        end
    end

    return false
end
function UtilDataServiceShare:GetMapForFirstChainPath()
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()

    local mapForFirstChainPath = boardComponent:GetMapForFirstChainPath()
    return mapForFirstChainPath
end

---@param pos Vector2
---@param blockFlag BlockFlag
---@param targetEntity Entity
---@return bool
---根据传入的Entiy阵营，判断是否被阻挡
function UtilDataServiceShare:IsPosBlockWithEntityRace(pos, blockFlag, targetEntity)
    if not self:IsValidPiecePos(pos) then
        return true --棋盘外的位置一律阻挡
    end
    local listTrap = self:GetTrapsAtPos(pos)
    for _, value in ipairs(listTrap) do
        ---@type Entity
        local entityTrap = value
        ---@type TrapComponent
        local trapCmp = entityTrap:Trap()

        local blockByRaceType = trapCmp:GetBlockByRaceType()
        if blockByRaceType then
            local curRaceType = TrapRaceType.All
            local curBlock = 0
            if targetEntity:HasTeam() then
                curRaceType = TrapRaceType.Team
            elseif targetEntity:HasMonsterID() then
                curRaceType = TrapRaceType.Monster
            elseif targetEntity:HasChessPet() then
                curRaceType = TrapRaceType.ChessPet
            end

            for _, blockRaceInfo in ipairs(blockByRaceType) do
                if curRaceType == blockRaceInfo.RaceType then
                    curBlock = blockRaceInfo.Block
                    break
                end
            end

            if curBlock > 0 then
                ---@type BoardServiceLogic
                local boardServiceL = self._world:GetService("BoardLogic")
                local curBlockFlag = boardServiceL:GetBlockFlagByBlockId(curBlock)
                if (blockFlag & curBlockFlag) > 0 then
                    return true
                end
            end
        end
    end

    return false
end

---@return PieceType
function UtilDataServiceShare:FindPieceElement(pos)
    local board = self._world:GetBoardEntity():Board()
    if board.Pieces[pos.x] and board.Pieces[pos.x][pos.y] then
        return board.Pieces[pos.x][pos.y]
    else
        return PieceType.None
    end
end

---@return PieceType
---@param pos Vector2
function UtilDataServiceShare:GetPieceType(pos)
    local boardEntity = self._world:GetBoardEntity()
    return boardEntity:Board():GetPieceType(pos)
end

---@return Vector2[]
function UtilDataServiceShare:GetPiecePosByType(pieceTypeList)
    local boardEntity = self._world:GetBoardEntity()
    return boardEntity:Board():GetPiecePosByType(pieceTypeList)
end

function UtilDataServiceShare:IsPosExistNegtiveBlock(pos)
    local block = self:FindBlockByPos(pos)
    return block:IsExistNegative()
end

---是否在pos位置忽略元素匹配
function UtilDataServiceShare:IgnoreElementMatchOnPos(pos)
    local isExit = self:IsPosExit(pos)
    return isExit
end

---pos处是否有出口
function UtilDataServiceShare:IsPosExit(pos)
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = boardEntity:Board()
    return cBoard:IsPosExit(pos)
end

---pos处是否有任意门
function UtilDataServiceShare:IsPosDimensionDoor(pos)
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = boardEntity:Board()
    return cBoard:IsPosDimensionDoor(pos)
end

function UtilDataServiceShare:HasDimensionDoor()
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = boardEntity:Board()
    return cBoard:HasDimensionDoor()
end

--pos是否是center的邻居
function UtilDataServiceShare:IsAdjacentPos(center, pos)
    if math.abs(center.x - pos.x) > 1 or math.abs(center.y - pos.y) > 1 or center == pos then
        return false
    end
    return true
end

---@param posList Vector2[]
---@return boolean
function UtilDataServiceShare:IsPosListHaveMonster(posList)
    local monsterPosList = self:GetAllMonsterPos()
    for k, v in pairs(posList) do
        if table.icontains(monsterPosList, v) then
            return true
        end
    end
    return false
end

---@return Vector2[]
function UtilDataServiceShare:GetAllMonsterPos()
    local monsterPosList = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local monsterGridPos = e:GridLocation().Position
        if not e:HasDeadMark() then
            if e:HasBodyArea() then
                ---@type BodyAreaComponent
                local bodyAreaCmpt = e:BodyArea()
                local areaArray = bodyAreaCmpt:GetArea()
                for i = 1, #areaArray do
                    local curAreaPos = areaArray[i]
                    --Log.fatal("monsterPos:",monsterGridPos.x," ",monsterGridPos.y," area",curAreaPos.x," ",curAreaPos.y)
                    table.insert(monsterPosList, monsterGridPos + curAreaPos)
                end
            else
                table.insert(monsterPosList, monsterGridPos)
            end
        end
    end
    return monsterPosList
end

--取格子周围的8个格子
function UtilDataServiceShare:GetRoundGrid(grid, filter)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetRoundGrid(grid, filter)
end

---查找特定位置是否有特定的Entity
function UtilDataServiceShare:IsHaveEntity(pos, nEntityType, nTypeParam)
    local listFindEntity = self:FindEntityByPosAndType(pos, nEntityType, nTypeParam)
    if listFindEntity and table.count(listFindEntity) > 0 then
        return true
    end
    return false
end

---@return Entity
function UtilDataServiceShare:GetMonsterAtPos(pos)
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es =
        boardCmpt:GetPieceEntities(
        pos,
        function(e)
            if self._world:MatchType() == MatchType.MT_BlackFist then
                return e:HasTeam()
            else
                return e:HasMonsterID()
            end
        end
    )
    if #es > 0 then
        return es[1]
    end
end

function UtilDataServiceShare:GetAllMonstersAtPos(pos)
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es = boardCmpt:GetPieceEntities(
        pos,
        function(e)
            if self._world:MatchType() == MatchType.MT_BlackFist then
                return e:HasTeam()
            else
                return e:HasMonsterID()
            end
        end
    )
    return es
end

---@return Vector2
function UtilDataServiceShare:GetBoardCenterPos()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetBoardCenterPos()
end

--endregion Board

--region Monster
---获取出场技Id
---@param e Entity
function UtilDataServiceShare:GetAppearSkillId(e)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local monsterConfigData = configService:GetMonsterConfigData()
    local monsterId = e:MonsterID():GetMonsterID()
    local skillId = monsterConfigData:GetAppearSkillID(monsterId)
    return skillId
end

---@param monsterEntity Entity
---@return number
function UtilDataServiceShare:GetDropSkill(monsterEntity)
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local cMonsterID = monsterEntity:MonsterID()
    local skillId = nil
    if cMonsterID then
        skillId = monsterConfigData:GetDropSkillID(cMonsterID:GetMonsterID())
    end
    return skillId
end

---获取返场技能ID
---@param monsterEntity Entity
---@return number
function UtilDataServiceShare:GetMonsterBackSkill(monsterEntity)
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local cMonsterID = monsterEntity:MonsterID()
    local skillId = nil
    if cMonsterID then
        skillId = monsterConfigData:GetBackSkillID(cMonsterID:GetMonsterID())
    end
    return skillId
end

--endregion Monster

--region 机关
---获得机关的预览技能
function UtilDataServiceShare:GetTrapPreviewSkillID(entityTrap)
    local skillID = 0
    ---@type AIComponentNew
    local cAI = entityTrap:AI()
    if cAI then
        skillID = cAI:GetPreviewSkillID()
    else
        local cmptTrap = entityTrap:Trap()
        skillID = cmptTrap:GetTriggerSkillID()
    end
    return skillID
end

function UtilDataServiceShare:GetTrapTriggerSkillIDByTriggerEntity(trapEntity, triggerEntity)
    local skillID = 0
    ---@type TrapComponent
    local cTrap = trapEntity:Trap()
    if not cTrap then
        return skillID
    end

    --触发阵营检查
    local raceType = cTrap:GetTrapRaceType()
    ---@type TrapTargetSelector 机关目标选择器
    local trapTargetSelector = TrapTargetSelector:New(self._world)
    if not trapTargetSelector:CanSelectTargetByType(trapEntity, triggerEntity, raceType) then
        return skillID
    end

    --根据阵营选择触发技能
    local triggerSkillByRaceType = cTrap:GetTriggerSkillByRaceType()
    if triggerEntity and triggerSkillByRaceType then
        for _, triggerRaceInfo in ipairs(triggerSkillByRaceType) do
            if trapTargetSelector:CanSelectTargetByType(trapEntity, triggerEntity, triggerRaceInfo.RaceType) then
                skillID = triggerRaceInfo.SkillID
                return skillID
            end
        end
    end

    --没有则选择配置的触发技能
    skillID = cTrap:GetTriggerSkillID()

    return skillID
end

---@param eTrap Entity
---获取与eTrap同组的机关
function UtilDataServiceShare:GetGroupTrap(eTrap)
    ---@type TrapComponent
    local cTrap = eTrap:Trap()

    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local traps = {}

    local triggerTargetTrapID = cTrap:GetGroupTriggerTrapID()
    for _, trapEntity in ipairs(trapGroup:GetEntities()) do
        ---@type TrapComponent
        local cTrapInGroup = trapEntity:Trap()
        if
            eTrap:GetID() ~= trapEntity:GetID() and cTrap:GetGroupID() ~= 0 and cTrapInGroup:GetGroupID() ~= 0 and
                cTrap:GetGroupID() == cTrapInGroup:GetGroupID() and
                ((not triggerTargetTrapID) or (triggerTargetTrapID == cTrapInGroup:GetTrapID()))
         then
            table.insert(traps, trapEntity)
        end
    end
    return traps
end

---查找需要守护的机关  目前只有1个
function UtilDataServiceShare:GetProtectedTrap()
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)

    for _, trapEntity in ipairs(trapGroup:GetEntities()) do
        ---@type TrapComponent
        local trapComponent = trapEntity:Trap()
        if trapComponent:GetTrapType() == TrapType.Protected then
            return trapEntity
        end
    end
    return nil
end

local function Filter_GetTrapAndNoDeadMark(e)
    return e:HasTrapID() and not e:HasDeadMark()
end

--找到该位置所有的机关
---@return Entity[]
function UtilDataServiceShare:GetTrapsAtPos(pos)
    local board = self._world:GetBoardEntity():Board()
    local es = board:GetPieceEntities(pos, Filter_GetTrapAndNoDeadMark)

    return es
end

---查找特定位置特定类型的机关
function UtilDataServiceShare:FindTrapByTypeAndPos(nTrapType, pos)
    local listReturn = {}
    local listFindID = self:FindEntityByPosAndType(pos, EnumTargetEntity.Trap, nTrapType)
    for i = 1, #listFindID do
        local trapEntity = self._world:GetEntityByID(listFindID[i])
        if not trapEntity:HasDeadMark() then
            table.insert(listReturn, trapEntity)
        end
    end
    return listReturn
end

--endregion 机关

--region Maze

function UtilDataServiceShare:IsArchivedBattle()
    ---@type MazeService
    local mazeService = self._world:GetService("Maze")
    return mazeService:IsArchivedBattle()
end

function UtilDataServiceShare:GetArchivedBattle()
    ---@type MazeService
    local mazeService = self._world:GetService("Maze")
    return mazeService:GetBattleArchive()
end

function UtilDataServiceShare:GetLightCount()
    ---@type MazeService
    local mazeService = self._world:GetService("Maze")
    return mazeService:GetLightCount()
end

--endregion Maze

function UtilDataServiceShare:IsGridElementMatch(checkPos, convertGridTypeArray)
    local checkPosType = self:FindPieceElement(checkPos)
    for k, v in ipairs(convertGridTypeArray) do
        local curGridType = tonumber(v)
        if curGridType == checkPosType then
            return true
        end
    end
    return false
end

---用来计算出怪物所占区域
---@param monsterEntity Entity
function UtilDataServiceShare:GetMonsterGridAreaList(monsterEntity)
    local bodyArea = monsterEntity:BodyArea():GetArea()
    local monsterRenderPos = monsterEntity:GetRenderGridPosition()
    --local centerOffset = monsterEntity:GridLocation():GetGridOffset()
    local targetPos = monsterRenderPos
    -- monsterRenderPos-centerOffset
    local areaPosList = {}
    for i = 1, #bodyArea do
        local pos = targetPos + bodyArea[i]
        table.insert(areaPosList, pos)
    end
    return areaPosList
end

---@param entity Entity
---@return ElementType
function UtilDataServiceShare:GetEntityElementPrimaryType(entity)
    ---@type ElementComponent
    local elementCmpt = entity:Element()
    if elementCmpt then
        return elementCmpt:GetPrimaryType()
    end
end

---提取AI当前的预览技能ID
---@param aiEntity Entity
function UtilDataServiceShare:GetAIPreviewSkillID(aiEntity)
    ---@type AIComponentNew
    local aiCmpt = aiEntity:AI()
    return aiCmpt:GetPreviewSkillID()
end

---提取AI的移动力配置
---@param aiEntity Entity
function UtilDataServiceShare:GetAIMobilityConfig(aiEntity)
    ---@type AIComponentNew
    local aiCmpt = aiEntity:AI()
    return aiCmpt:GetMobilityConfig()
end

---提取AI当前的技能范围
---@param aiEntity Entity
function UtilDataServiceShare:GetAISkillScopeResult(aiEntity)
    ---@type AIComponentNew
    local aiCmpt = aiEntity:AI()
    return aiCmpt:GetSkillScopeResult()
end

---检查是否是棱镜
function UtilDataServiceShare:GetIsPrismPiece(pos)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    return boardCmpt:IsPrismPiece(pos)
end

function UtilDataServiceShare:GetBoardIsPosNil(pos)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    return boardCmpt:IsPosNil(pos)
end

function UtilDataServiceShare:GetCloneBoardGridPos()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    return boardCmpt:CloneBoardPosList()
end

function UtilDataServiceShare:Is2PosCanConnect(pos1, pos2, pieceType,chainPathIndex1)
    local bConnect = false
    local pieceType1 = 99
    local pieceType2 = 99
    local canLinkLine = false
    for i = -1, 1 do
        for j = -1, 1 do
            if pos1.x + i == pos2.x and pos1.y + j == pos2.y then
                if self:IsValidPiecePos(pos2) then
                    pieceType1 = self._boardLogicSvc:GetPieceType(pos1)
                    if chainPathIndex1 and chainPathIndex1 == 2 then--连线第一格
                        local mapForFirstChainPath = self:GetMapForFirstChainPath()
                        if mapForFirstChainPath then
                            pieceType1 = mapForFirstChainPath
                        end
                    end
                    pieceType2 = self._boardLogicSvc:GetPieceType(pos2)
                    canLinkLine = not self:IsPosBlockLinkLineForChain(pos2) --pos是否可连线
                    if
                        CanMatchPieceType(pieceType, pieceType2) and CanMatchPieceType(pieceType1, pieceType2) and
                            canLinkLine
                     then
                        bConnect = true
                    end
                    --没有通过再判断
                    if bConnect == false then
                        --该位置可以映射的颜色数组
                        local gridPieceTypeMapList1 = self._boardLogicSvc:GetPieceTypeMapList(pos1)
                        local gridPieceTypeMapList2 = self._boardLogicSvc:GetPieceTypeMapList(pos2)
                        if
                            table.intable(gridPieceTypeMapList1, PieceType.Any) or
                                table.intable(gridPieceTypeMapList2, PieceType.Any)
                         then
                            bConnect = true
                        end
                        if
                            table.intable(gridPieceTypeMapList1, pieceType2) or
                                table.intable(gridPieceTypeMapList2, pieceType1)
                         then
                            bConnect = true
                        end
						
                        if pieceType1 ~= pieceType and self:IsPosCanMapOtherPiece(pos1, pieceType, pieceType1) then
                            bConnect = true
                        end
                        if pieceType2 ~= pieceType and self:IsPosCanMapOtherPiece(pos2, pieceType, pieceType2) then
                            bConnect = true
                        end
                    end
                end
                break
            end
        end
    end
    local msg = "pieceType1=" .. pieceType1 .. " pieceType2=" .. pieceType2 .. " canLinkLine=" .. tostring(canLinkLine)
    return bConnect, msg
end

---region Buff
------@param defenderEntity Entity
function UtilDataServiceShare:UpdateRenderHPLockInfoByLogic(defenderEntity)
    ---@type BuffComponent
    local buffComponent = defenderEntity:BuffComponent()
    ---@type  BuffViewComponent
    local buffViewComponent = defenderEntity:BuffView()
    if buffComponent and buffViewComponent then
        buffViewComponent:AddHpLockState(
            buffComponent:GetLockHPRoundIndex(),
            buffComponent:GetHPLockIndex(),
            buffComponent:GetLockGSMState(),
            buffComponent:IsAlwaysLock(),
            buffComponent:GetBuffValue("LockHPType"),
            buffComponent:GetUnlockHPIndex()
        )
    end
end

--endregion Buff
---提取AI的是否可移动标记
---@param aiEntity Entity
function UtilDataServiceShare:GetAICanMove(aiEntity)
    ---@type AIComponentNew
    local aiCmpt = aiEntity:AI()
    if aiCmpt == nil then
        return false
    end

    return aiCmpt:CanMove()
end

---获取当前的波次的索引
function UtilDataServiceShare:GetStatCurWaveIndex()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:GetCurWaveIndex()
end

---获取当前波次回合数
function UtilDataServiceShare:GetStatCurWaveRoundNum()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:GetCurWaveRoundNum()
end

---获取当前波次累计的回合数
function UtilDataServiceShare:GetStatCurWaveTotalRoundCount()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:GetCurWaveTotalRoundCount()
end

function UtilDataServiceShare:GetStatIsRoundAuroraTime()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:IsRoundAuroraTime()
end
function UtilDataServiceShare:GetStatIsReEnterAuroraTime()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:IsReEnterAuroraTime()
end
function UtilDataServiceShare:GetStatBossWaveInfo()
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()

    local battleStatCmpt = self._world:BattleStat()

    ---@type number
    local waveNum = battleStatCmpt:GetCurWaveIndex()

    local isBossWave = levelConfigData:GetIsBoss(waveNum)
    local bossIDs = {}
    if isBossWave then
        bossIDs = levelConfigData:GetBossID(waveNum)
    end

    return isBossWave, bossIDs
end

---获取逻辑上是否是自动战斗
function UtilDataServiceShare:GetStatAutoFight()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:GetAutoFight()
end

---是否是第一波次
function UtilDataServiceShare:GetStatIsFirstWave()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type number
    local waveNum = battleStatCmpt:GetCurWaveIndex()

    if waveNum == 1 then
        return true
    end

    return false
end

---是否回合用尽
function UtilDataServiceShare:GetStatIsRealZeroRound()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    return battleStatCmpt:IsRealZeroRound()
end

function UtilDataServiceShare:GetStatIsZeroRound()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:GetCurWaveRound() == 0 and battleStatCmpt:GetCurWavePunishmentRoundCount() > 0
end

function UtilDataServiceShare:GetCurWavePunishmentRoundCount()
    return self._world:BattleStat():GetCurWavePunishmentRoundCount()
end

function UtilDataServiceShare:GetStatLevelCompleteLimitAllRoundCount()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    return battleStatCmpt:LevelCompleteLimitAllRoundCount()
end

function UtilDataServiceShare:GetStatIsAssignWaveResult()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    return battleStatCmpt:AssignWaveResult()
end

function UtilDataServiceShare:PosIsSingleMonster(pos)
    ---@type Entity
    local e = self:GetMonsterAtPos(pos)
    ---@type BodyAreaComponent
    local areaCmpt = e:BodyArea()
    return #areaCmpt:GetArea() == 1
end

---@param monsterEntity Entity
---@param targetPos Vector2
function UtilDataServiceShare:IsMonsterCanTel2TargetPos(monsterEntity, targetPos)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local entity = monsterEntity
    if  monsterEntity:HasSuperEntity() and monsterEntity:GetSuperEntity() then
        entity = monsterEntity:GetSuperEntity()
    end
    if entity:HasTeam() or entity:HasPet()  then
        return not boardServiceLogic:IsPosBlock(targetPos, BlockFlag.LinkLine)
    end
    local monsterRaceType = entity:MonsterID():GetMonsterRaceType()
    local raceBlockFlag

    local hitBackBlockFlag = BlockFlag.HitBack
    if monsterRaceType == MonsterRaceType.Land then
        raceBlockFlag = BlockFlag.MonsterLand
    elseif monsterRaceType == MonsterRaceType.Fly then
        raceBlockFlag = BlockFlag.MonsterFly
        hitBackBlockFlag = BlockFlag.HitBackFly--MSG57290 深渊不阻挡击退飞行怪
    end
    return not boardServiceLogic:IsMonsterPosBlock(entity, targetPos, raceBlockFlag) and
        not boardServiceLogic:IsMonsterPosBlock(entity, targetPos, hitBackBlockFlag) and
        not self:IsPosBlockWithEntityRace(targetPos, hitBackBlockFlag, entity)
end

function UtilDataServiceShare:IsFinalAttack()
    ---@type BattleService
    local battlesvc = self._world:GetService("Battle")
    return battlesvc:IsFinalAttack()
end

function UtilDataServiceShare:IsTeamLeaderCanAttack(teamEntity, pieceType)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    return affixService:IsTeamLeaderCanAttack(teamEntity, pieceType)
end

function UtilDataServiceShare:GetFirstWaveMonsterIDList()
    return self._world:BattleStat():GetFirstWaveMonsterIDList()
end

function UtilDataServiceShare:GetFirstWaveTrapIDList()
    return self._world:BattleStat():GetFirstWaveTrapIDList()
end

function UtilDataServiceShare:IsCloseAuroraTime()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    return affixService:IsCloseAuroraTime()
end
function UtilDataServiceShare:IsNoAuroraTimeLimit()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    return affixService:IsNoAuroraTimeLimit()
end
function UtilDataServiceShare:GetWorldBossEntity()
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    return battleSvc:GetWorldBossEntity()
end
function UtilDataServiceShare:GetWorldBossEntityArray()
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    return battleSvc:GetWorldBossEntityArray()
end

---根据传入的pstID,检查是否是最后一个光灵[UI用]
function UtilDataServiceShare:IsFifthPetInTeamOrder(petPstID)
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local petPstIDArray = teamEntity:Team():GetTeamOrder()

    local lastPetPstID = petPstIDArray[5]

    if petPstID == lastPetPstID then
        return true
    end

    return false
end
function UtilDataServiceShare:IsFourthPetInTeamOrder(petPstID)
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local petPstIDArray = teamEntity:Team():GetTeamOrder()

    local lastPetPstID = petPstIDArray[4]

    if petPstID == lastPetPstID then
        return true
    end

    return false
end

function UtilDataServiceShare:IsFourthOrEightPetInTeamOrder(petPstID)
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local petPstIDArray = teamEntity:Team():GetTeamOrder()

    local lastPetPstID = petPstIDArray[4]

    if petPstID == lastPetPstID then
        return true
    end
    if #petPstIDArray ==8 then
        return petPstID == petPstIDArray[8]
    end

    return false
end


function UtilDataServiceShare:GetLatestEffectParamArray(eid, skillId)
    ---@type ConfigDecorationService
    local svcCfgDeco = self._world:GetService("ConfigDecoration")
    local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(eid, skillId)
    return skillEffectArray
end

---@param trapEntity Entity
---@param monsterEntity Entity
function UtilDataServiceShare:IsTrapPosCanMoveMonster(trapEntity, monsterEntity)
    local ownerPos = trapEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local areaCmpt = trapEntity:BodyArea()
    local areaList = areaCmpt:GetArea()
    local beValid = true
    for i, area in ipairs(areaList) do
        local pos = Vector2(ownerPos.x + area.x, ownerPos.y + area.y)
        if not self:IsMonsterCanTel2TargetPos(monsterEntity, pos) then
            beValid = false
        end
    end
    return beValid
end

---@param entity  Entity
function UtilDataServiceShare:GetHPBarTypeByEntity(entity)
    if entity:HasMonsterID() then
        if entity:HasBoss() then
            if entity:MonsterID():IsEliteMonster() then
                return HPBarType.EliteBoss
            else
                return HPBarType.Boss
            end
        else
            if entity:MonsterID():IsEliteMonster() then
                return HPBarType.EliteMonster
            else
                return HPBarType.NormalMonster
            end
        end
    end
    if entity:HasTrapID() then
        return HPBarType.Trap
    end
end

---提取AI当前的预览技能ID
---@param aiEntity Entity
function UtilDataServiceShare:IsAIChangePreviewSkillID(aiEntity)
    ---@type AIComponentNew
    local aiCmpt = aiEntity:AI()
    return aiCmpt:IsReplacePreviewSkill()
end

function UtilDataServiceShare:OnCheckPetForceChain(petEntity)
    ---@type BuffComponent
    local buffComponent = petEntity:BuffComponent()
    local petForceChain = buffComponent:GetBuffValue("PetForceChain") or 0
    return petForceChain == 1
end

---创建一个全场的阻挡信息白板，支持扣除指定单位的阻挡
---@return table<number, table<number, PieceBlockData>>
function UtilDataServiceShare:CreatePieceBlockBlackboard(tPawnEntityID)
    tPawnEntityID = tPawnEntityID or {}

    local isEntityPawn = {}
    for _, id in ipairs(tPawnEntityID) do
        isEntityPawn[id] = true
    end

    -- 注意：currentBlockFlags是逻辑数据，使用时绝对不可以修改
    ---@type table<number, table<number, PieceBlockData>>
    local currentBlockFlags = self._world:GetBoardEntity():Board():GetBlockFlagArray()

    local blockDataByGridPos = {}
    -- local pawnBlockDataByEntityID = {}

    for x, ty in pairs(currentBlockFlags) do
        if not blockDataByGridPos[x] then
            blockDataByGridPos[x] = {}
        end

        for y, logicBlockData in pairs(ty) do
            local blockData = PieceBlockData:New() -- 构造里的参数就没用
            for eid, blockVal in pairs(logicBlockData.m_listBlock) do
                if not isEntityPawn[eid] then
                    blockData:AddBlock(eid, blockVal)
                else
                    -- pawnBlockDataByEntityID[eid] = pawnBlock
                    -- 棋子的阻挡单独存
                    -- if not pawnBlockDataByEntityID[eid] then
                    --     pawnBlockDataByEntityID[eid] = {}
                    -- end

                    -- blockServiceLogic:UpdateEntityBlockFlag(e, posOld, posNew)的阻挡信息来源是BlockFlagComponent
                    -- 设计上不存在一个单位在不同位置上阻挡不一致的状态
                    -- 所以这里也直接取blockFlagComponent的值记录
                    local pawnBlock = PieceBlockData:New() -- 构造里的参数就没用
                    local val = self._world:GetEntityByID(eid):BlockFlag():GetBlockFlag()
                    pawnBlock:AddBlock(eid, val)
                end
            end
            blockDataByGridPos[x][y] = blockData
        end
    end

    return blockDataByGridPos --[[, pawnBlockDataByEntityID]]
end

--AI的目标
function UtilDataServiceShare:OnGetAITargetType(entity)
    local aiTargetType = AITargetType.Normal
    ---@type AIComponentNew
    local aiCmpt = entity:AI()
    if aiCmpt then
        aiTargetType = aiCmpt:GetAITargetType()
    end
    return aiTargetType
end

--AI的目标是普通模式（有守护机关打守护机关，没守护机关打队伍）
function UtilDataServiceShare:EntityAITargetTypeIsNormal(entity)
    local aiTargetType = self:OnGetAITargetType(entity)
    return aiTargetType == AITargetType.Normal
end

function UtilDataServiceShare:GetEntityByPstID(checkPstID)
    ----@type Entity
    local casterPetEntity = nil
    local petPstIDGroup = self._world:GetGroup(self._world.BW_WEMatchers.PetPstID)
    for i, e in ipairs(petPstIDGroup:GetEntities()) do
        ---@type PetPstIDComponent
        local petPstIDCmpt = e:PetPstID()
        local pstID = petPstIDCmpt:GetPstID()
        if pstID == checkPstID then
            casterPetEntity = e
        end
    end

    return casterPetEntity
end

function UtilDataServiceShare:CheckActiveSkillCastCondition(petPstID, skillID)
    local castPetEntity = self:GetEntityByPstID(petPstID)
    --主动技释放条件校验日志信息
    local log = {
        tostring(BattleConst.Kick),
        tostring(self:GetEntityByPstID(petPstID) ~= nil),
        tostring((castPetEntity and castPetEntity:HasSkillInfo()) and (castPetEntity:SkillInfo():GetActiveSkillID())),
        tostring(
            (castPetEntity and castPetEntity:HasAttributes()) and (castPetEntity:Attributes():GetAttribute("Ready"))
        ),
        tostring(
            (castPetEntity and castPetEntity:HasAttributes()) and
                (castPetEntity:Attributes():GetAttribute("LegendPower"))
        ),
        tostring(
            (castPetEntity and castPetEntity:HasAttributes()) and (castPetEntity:Attributes():GetAttribute("Power"))
        ),
        tostring((castPetEntity and castPetEntity:HasPetPstID()) and (castPetEntity:PetPstID():GetPstID())),
        tostring((castPetEntity and castPetEntity:HasPetPstID()) and (castPetEntity:PetPstID():GetTemplateID())),
        tostring(petPstID),
        tostring(skillID)
    }

    ---如果不踢人的话，就不需要检查合法性了
    if not BattleConst.Kick then
        return true, log
    end

    if not castPetEntity then
        return false, log
    end

    --UI技能ID和逻辑技能ID一致
    local localSkillID = castPetEntity:SkillInfo():GetActiveSkillID()
    local extraActiveSkillIDList = castPetEntity:SkillInfo():GetExtraActiveSkillIDList()
    if extraActiveSkillIDList and table.icontains(extraActiveSkillIDList,skillID) then
        localSkillID = skillID
    else
        --变体
        local variantActiveSkillInfo = castPetEntity:SkillInfo():GetVariantActiveSkillInfo()
        if variantActiveSkillInfo then
            local variantList = variantActiveSkillInfo[localSkillID]
            if variantList and table.icontains(variantList,skillID) then
                localSkillID = skillID
            end
        end
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(localSkillID, castPetEntity)

    --检查是否存在子技能列表，若存在并包含传入，则修改主动技ID
    local subSkillList = skillConfigData:GetSubSkillIDList()
    local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
    if cfgExtraParam then
        if #subSkillList > 0 and table.icontains(subSkillList, skillID) then
            localSkillID = skillID
            skillConfigData = configService:GetSkillConfigData(localSkillID, castPetEntity)

            --判断是否存在机关ID
            local trapID = cfgExtraParam[SkillTriggerTypeExtraParam.TrapID]
            if trapID then
                ---@type TrapServiceLogic
                local trapServiceLogic = self._world:GetService("TrapLogic")
                if trapServiceLogic:IsTrapCovered(trapID, petPstID) then
                    return false, log
                end
            end
        end

        local paramHPVal = cfgExtraParam[SkillTriggerTypeExtraParam.HPValPercent]
        if paramHPVal then
            local eTeam = castPetEntity:Pet():GetOwnerTeamEntity()
            local maxHPPercent = paramHPVal[1]
            local remainHPPercent = paramHPVal[2]
            local casterCurrentHP = eTeam:Attributes():GetCurrentHP()
            local casterMaxHP = eTeam:Attributes():CalcMaxHp()
            local requiredMaxVal = math.ceil(casterMaxHP * maxHPPercent)
            local remainHP = casterCurrentHP - requiredMaxVal
            if remainHP <= 0 then
                return false, log, BattleUIActiveSkillCannotCastReason.HPValPercent
            end
            local requiredRemainHP = math.ceil(remainHP * remainHPPercent)
            if requiredRemainHP >= remainHP then
                return false, log, BattleUIActiveSkillCannotCastReason.HPValPercent
            end
        end
        local paramHPVal = cfgExtraParam[SkillTriggerTypeExtraParam.HPValPercent]
        if paramHPVal then
            local maxHPPercent = paramHPVal[1]
            local remainHPPercent = paramHPVal[2]
            local casterCurrentHP = castPetEntity:Attributes():GetCurrentHP()
            local casterMaxHP = castPetEntity:Attributes():CalcMaxHp()
            local requiredMaxVal = casterMaxHP * maxHPPercent
            local remainHP = casterCurrentHP - requiredMaxVal
            if remainHP <= 0 then
                return false, log, BattleUIActiveSkillCannotCastReason.HPValPercent
            end
            local requiredRemainHP = remainHP * remainHPPercent
            if requiredRemainHP >= remainHP then
                return false, log, BattleUIActiveSkillCannotCastReason.HPValPercent
            end
        end
    end

    if localSkillID ~= skillID then
        return false, log, BattleUIActiveSkillCannotCastReason.NotReady
    end
    local ready = self:GetPetSkillReadyAttr(castPetEntity,skillID)
    --local ready = castPetEntity:Attributes():GetAttribute("Ready")
    ---ready需要是1
    if ready == 0 then
        return false, log, BattleUIActiveSkillCannotCastReason.NotReady
    end

    if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        --传说光灵
        local legendPower = castPetEntity:Attributes():GetAttribute("LegendPower")
        local costLegendPower = skillConfigData:GetSkillTriggerParam()
        --罗伊 根据点选不同 消耗能量不同
        costLegendPower = self:_GetLegendPowerConstByExtraParam(costLegendPower, skillConfigData, petPstID)

        if legendPower < costLegendPower then
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end
    elseif skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer then
        local extraParam = skillConfigData:GetSkillTriggerExtraParam()
        local buffEffectType = extraParam.buffEffectType
        ---@type BuffLogicService
        local blsvc = self._world:GetService("BuffLogic")
        local currentVal = blsvc:GetBuffLayer(castPetEntity, buffEffectType)
        local requiredVal = skillConfigData:GetSkillTriggerParam()

        if currentVal < requiredVal then
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end
    else
        --其他主动技：星灵，机关主动技
        local power = self:GetPetPowerAttr(castPetEntity,skillID)
        --local power = castPetEntity:Attributes():GetAttribute("Power")
        ---CD值需要是0
        if power ~= 0 then
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end
    end

    return true, log
end

function UtilDataServiceShare:IsSkillDisabledWhenCasterIsTeamLeader(petPstID, skillID)
    local castPetEntity = self:GetEntityByPstID(petPstID)
    if not castPetEntity then
        return false
    end

    ---@type ConfigDecorationService
    local configDecoSvc = self._world:GetService("ConfigDecoration")
    ---@type SkillEffectParamBase[]
    local skillConfig = configDecoSvc:GetLatestEffectParamArray(castPetEntity:GetID(), skillID)
    for index, config in ipairs(skillConfig) do
        if config:IsDisableTeamLeaderActiveSkill() then
            return true
        end
    end

    return false
end

function UtilDataServiceShare:IsPetCurrentTeamLeader(petPstID)
    ---@type Entity
    local castPetEntity = self:GetEntityByPstID(petPstID)
    if (not castPetEntity) or (not castPetEntity:HasPet()) then
        return false
    end

    local eTeam = castPetEntity:Pet():GetOwnerTeamEntity()
    if (not eTeam) or (not eTeam:HasTeam()) then
        return false
    end

    local cTeam = eTeam:Team()
    local teamLeaderPstID = cTeam:GetTeamLeaderPetPstID()

    return petPstID == teamLeaderPstID
end

function UtilDataServiceShare:CheckCanCastActiveSkillBySwapPetTeamOrder(petPstID, skillID)
    local castPetEntity = self:GetEntityByPstID(petPstID)
    if not castPetEntity then
        return false
    end

    ---@type ConfigDecorationService
    local configDecoSvc = self._world:GetService("ConfigDecoration")
    ---@type SkillEffectParamBase[]
    local skillConfig = configDecoSvc:GetLatestEffectParamArray(castPetEntity:GetID(), skillID)
    for index, config in ipairs(skillConfig) do
        if
            (config:GetEffectType() == SkillEffectType.SwapPetTeamOrder and
                config:GetTargetOrderType() == SwapPetTeamOrderType.CASTER_SELECT_TEAM_POS)
         then
            local validSelectPos, validSelectTarget
            local cTeam = castPetEntity:Pet():GetOwnerTeamEntity():Team()
            local selected = cTeam:GetSelectedTeamOrderPosition()
            local isSelfTeamLeader = cTeam:GetTeamLeaderEntity():GetID() == castPetEntity:GetID()
            local GLOBALteamOrder = cTeam:GetTeamOrder()
            validSelectPos = (selected > 0) and (selected <= #GLOBALteamOrder)
            local pstID = GLOBALteamOrder[selected]
            local selectedPetEntity = pstID and cTeam:GetPetEntityByPetPstID(pstID)
            if selectedPetEntity and (not selectedPetEntity:PetPstID():IsHelpPet()) then
                -- 如果自己当前是队长，需要判断被换的人是不是队长，不过目前来说只要是队长都应该放不出来
                validSelectTarget =
                    (not isSelfTeamLeader) or (not selectedPetEntity:BuffComponent():HasFlag(BuffFlags.SealedCurse))
            end

            return (validSelectPos and validSelectTarget)
        end
    end

    return true
end

function UtilDataServiceShare:IsSilenceState(petPstID)
    local castPetEntity = self:GetEntityByPstID(petPstID)
    if not castPetEntity then
        return false
    end
    local isSilence = castPetEntity:BuffComponent():HasFlag(BuffFlags.Silence)
    return isSilence
end

function UtilDataServiceShare:IsBuffSetActiveSkillCanNotReady(petPstID)
    local castPetEntity = self:GetEntityByPstID(petPstID)
    if not castPetEntity then
        return false
    end
    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local canNotReady,reason = blsvc:IsPetActiveSkillCanNotReadyByBuff(castPetEntity)
    return canNotReady,reason
end
function UtilDataServiceShare:IsBuffSetExtraActiveSkillCanNotReady(petPstID,skillID)
    local castPetEntity = self:GetEntityByPstID(petPstID)
    if not castPetEntity then
        return false
    end
    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local canNotReady,reason = blsvc:IsPetExtraActiveSkillCanNotReadyByBuff(castPetEntity,skillID)
    return canNotReady,reason
end

---@param trapType TrapType
---@param posList Vector2
---判断坐标上是否包含
function UtilDataServiceShare:IsPosHasSpTrap(pos, trapType)
    ---@type Entity
    local traps = self:GetTrapsAtPos(pos)
    if traps then
        local hasBadGrid = false
        for index, e in ipairs(traps) do
            if e:Trap():GetTrapType() == trapType then
                return true
            end
        end
    end
    return false
end

---当前地图最大x
function UtilDataServiceShare:GetCurBoardMaxX()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetCurBoardMaxX()
end

---当前地图最大y
function UtilDataServiceShare:GetCurBoardMaxY()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetCurBoardMaxY()
end

---当前地图最大长度（x或y）
function UtilDataServiceShare:GetCurBoardMaxLen()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetCurBoardMaxLen()
end

---当前地图镂空格子GapTiles
function UtilDataServiceShare:GetCurBoardGapTiles()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetGapTiles()
end

---当前地图中心坐标
function UtilDataServiceShare:GetCurBoardCenterPos()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetBoardCenterPos()
end

---@param skillConfigData SkillConfigData
function UtilDataServiceShare:_GetLegendPowerConstByExtraParam(defaultCost, skillConfigData, castSkillPetPstID)
    local cost = defaultCost
    local castPetEntity = self:GetEntityByPstID(castSkillPetPstID)
    if castPetEntity and skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        ---@type ActiveSkillPickUpComponent
        local pickCmpt = castPetEntity:ActiveSkillPickUpComponent()
        if not pickCmpt then
            pickCmpt = castPetEntity:PreviewPickUpComponent()--sjs_todo 
        end
        if cfgExtraParam and pickCmpt then
            if cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap] then --罗伊 点机关和空格子消耗能量不同
                if pickCmpt:HasPickExtraParam(SkillTriggerTypeExtraParam.PickPosNoCfgTrap) then
                    cost = cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap]
                end
            end
        end
    end
    return cost
end

---临时 获取模块 ui初始化信息
function UtilDataServiceShare:GetFeatureUiInitData()
    local featureInitList = {}
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = boardEntity:LogicFeature()
    if logicFeatureCmpt then
        local typeList = logicFeatureCmpt:GetFeatureTypeList()
        for i, featureType in ipairs(typeList) do
            local featureData = logicFeatureCmpt:GetFeatureData(featureType)
            if featureData then
                table.insert(featureInitList, featureData)
            end
        end
    end
    return featureInitList
end

function UtilDataServiceShare:IsUseCurHPInitRedHP(entity)
    local useCur = entity:Attributes():GetAttribute("InitRedHPUseCurHP")
    if useCur then
        return true
    end

    return false
end

---@param entity Entity
function UtilDataServiceShare:GetCurrentLogicHP(entity)
    local v = 0

    if entity:HasPet() then
        local matchType = self._world:MatchType()
        if matchType ~= MatchType.MT_Maze then
            v = entity:Pet():GetOwnerTeamEntity():Attributes():GetCurrentHP()
        else
            v = entity:Attributes():GetCurrentHP()
        end
    else
        v = entity:Attributes():GetCurrentHP()
    end

    return v
end

---@param entity Entity
function UtilDataServiceShare:GetCurrentLogicMaxHP(entity)
    local v = 0

    if entity:HasPet() then
        local matchType = self._world:MatchType()
        if matchType ~= MatchType.MT_Maze then
            v = entity:Pet():GetOwnerTeamEntity():Attributes():CalcMaxHp()
        else
            v = entity:Attributes():CalcMaxHp()
        end
    else
        v = entity:Attributes():CalcMaxHp()
    end

    return v
end

---目标坐标上的怪物做buff匹配
function UtilDataServiceShare:OnCalcTargetPosMonsterBuffEffectMatch(targetPos, buffEffect, casterEntity)
    local targetMonster = nil
    if self._world:MatchType() == MatchType.MT_BlackFist then
        if casterEntity:HasSuperEntity() then
            casterEntity = casterEntity:SuperEntityComponent():GetSuperEntity()
        end
        ---@type Entity
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        local enemyEntity = teamEntity:Team():GetEnemyTeamEntity()
        local enemyPos = enemyEntity:GetGridPosition()
        if targetPos == enemyPos then
            targetMonster = enemyEntity
        end
    else
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(monsterGroup:GetEntities()) do
            if not e:HasDeadMark() then
                local pos = e:GetGridPosition()
                ---@type BodyAreaComponent
                local bodyArea = e:BodyArea()
                local bodyAreaList = bodyArea:GetArea()
                for _, area in ipairs(bodyAreaList) do
                    if (area.x + pos.x) == targetPos.x and (area.y + pos.y) == targetPos.y then
                        targetMonster = e
                        break
                    end
                end
            end
            if targetMonster then
                break
            end
        end
    end

    if not targetMonster then
        return false
    end

    ---@type BuffComponent
    local buffCmp = targetMonster:BuffComponent()
    if not buffCmp then
        return false
    end

    if buffCmp:HasBuffEffect(buffEffect) then
        return true
    end

    return false
end

--指定位置上是否存在特定ID的机关
function UtilDataServiceShare:IsPosHasTrapByTrapID(pos, trapID)
    ---@type Entity[]
    local traps = self:GetTrapsAtPos(pos)
    if traps then
        for _, trap in ipairs(traps) do
            if trap:TrapID():GetTrapID() == trapID then
                return true
            end
        end
    end

    return false
end

---@param pos Vector2
---@param trapID number
---@return number
function UtilDataServiceShare:GetTrapAtPosByTrapID(pos, trapID)
    ---@type Entity[]
    local traps = self:GetTrapsAtPos(pos)
    if traps then
        for _, trap in ipairs(traps) do
            if trap:TrapID():GetTrapID() == trapID then
                return trap:GetID()
            end
        end
    end
end

---@param pos Vector2
---@param trapID number
---@return Entity[]
function UtilDataServiceShare:GetAllTrapEntitiesAtPosByTrapID(pos, trapID)
    local t = {}
    ---@type Entity[]
    local traps = self:GetTrapsAtPos(pos)
    if traps then
        for _, trap in ipairs(traps) do
            if trap:TrapID():GetTrapID() == trapID then
                table.insert(t, trap)
            end
        end
    end

    return t
end

---根据id列表 查找机关
function UtilDataServiceShare:GetTrapByID(trapID)
    local idList = {}
    if type(trapID) == "number" then
        idList[#idList + 1] = trapID
    elseif type(trapID) == "table" then
        idList = trapID
    end
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)

    local entityList = {}
    for _, trapEntity in ipairs(trapGroup:GetEntities()) do
        ---@type TrapComponent
        local trapComponent = trapEntity:Trap()
        local tID = trapComponent:GetTrapID()
        if table.icontains(idList, tID) then
            table.insert(entityList, trapEntity)
        end
    end
    return entityList
end

--region 多面棋盘
function UtilDataServiceShare:GetReplicaBoardMultiGridEntityData()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardMultiComponent
    local boardMultiComponent = boardEntity:BoardMulti()
    local gridEntityData = boardMultiComponent:GetGridEntityData()

    if not gridEntityData then
        return
    end

    local replica = {}
    for k, v in pairs(gridEntityData) do
        replica[k] = v
    end

    return replica
end
function UtilDataServiceShare:GetMultiBoardInfo(boardIndex)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    return levelConfigData:GetMultiBoardInfo(boardIndex)
end
---@param pos Vector2
---@return PieceType|nil
function UtilDataServiceShare:IsValidPiecePosMultiBoard(boardIndex, pos)
    ---@type Entity
    local eBoard = self._world:GetBoardEntity()
    ---@type BoardMultiComponent
    local cBoard = eBoard:BoardMulti()
    return cBoard:GetPieceData(pos, boardIndex)
end
function UtilDataServiceShare:GetCloneMultiBoardGridPos()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardMultiComponent
    local boardCmpt = boardEntity:BoardMulti()
    return boardCmpt:CloneBoardPosList()
end

--endregion 多面棋盘

--region 额外棋盘格子，只有攻击单体的技能效果才可以攻击到的范围

---获得额外棋盘坐标数据
function UtilDataServiceShare:GetExtraBoardPosList()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local posList = {}
    local extraBoard = boardServiceLogic:GetExtraBoardPosList()
    for i = 1, table.count(extraBoard) do
        local posWork = Vector2(extraBoard[i][1], extraBoard[i][2])
        table.insert(posList, posWork)
    end

    return posList
end

---该位置是棋盘额外坐标，逻辑存在，表现不存在
function UtilDataServiceShare:IsExtraBoardPos(pos)
    local posList = self:GetExtraBoardPosList()
    return table.intable(posList, pos)
end

--endregion 额外棋盘格子，只有攻击单体的技能效果才可以攻击到的范围

---获得该技能效果的目标选择类型
---@param skillEffectParam SkillEffectParamBase
function UtilDataServiceShare:GetSkillEffectTargetSelectionMode(skillID, skillEffectParam)
    ---技能配置数据
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    --技能的目标选择
    local scopeFilterParam = skillConfigData:GetScopeFilterParam()
    ---@type SkillEffectType
    local skillEffectType = skillEffectParam:GetEffectType()
    --技能效果的目标选择
    local effectScopeFilterParam = skillEffectParam:GetScopeFilterParam()
    local finalScopeFilterParam = effectScopeFilterParam:IsDefault() and scopeFilterParam or effectScopeFilterParam

    return finalScopeFilterParam:GetTargetSelectionMode()
end

---该位置有坏格子
function UtilDataServiceShare:IsBadGridPos(pos)
    local hasBadGrid = false
    local traps = self:GetTrapsAtPos(pos)
    if traps then
        for index, e in ipairs(traps) do
            if e:Trap():GetTrapType() == TrapType.BadGrid then
                hasBadGrid = true
                break
            end
        end
    end
    return hasBadGrid
end

---根据当前回合查询AI是否是附身状态
---@param entity Entity 被查询的实体
function UtilDataServiceShare:IsAIAttachState(entity,round)
    if not entity then 
        return false
    end

    if not entity:HasAI() then
        return false
    end

    return entity:AI():IsAttachState(round)
end

---检查是否光灵在释放主动技
---@param teamEntity Entity
function UtilDataServiceShare:IsPetCastActiveSkill(teamEntity)
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local activeSkillID = activeSkillCmpt:GetActiveSkillID()
    local activeSkillData = BattleSkillCfg(activeSkillID)
    local isPetActiveSkill = activeSkillData.Type == SkillType.Active
    return isPetActiveSkill
end

---根据名字获取指定Entity身上Attribute组件里的数据
---有一些属性数据不是从这里取的，走的是单独的接口，比如攻击力，血量等
---@param entity Entity 被查询的实体
function UtilDataServiceShare:GetEntityAttributeByName(entity,attributeName)
    ---@type AttributesComponent
    local attributeCmpt = entity:Attributes()
    if not attributeCmpt then 
        Log.fatal("can not find attr cmpt ")
        return nil
    end

    local attributeVal = attributeCmpt:GetAttribute(attributeName)

    return attributeVal
end

---查询entity的攻击力
---@param entity Entity 被查询的实体
function UtilDataServiceShare:GetEntityAttack(entity)
    ---@type AttributesComponent
    local attributeCmpt = entity:Attributes()
    if not attributeCmpt then 
        Log.fatal("can not find attr cmpt ")
        return nil
    end

    return attributeCmpt:GetAttack()
end

---根据key查询entity身上buff值，默认返回的是0
---@param entity Entity 被查询的实体
function UtilDataServiceShare:GetEntityBuffValue(entity,key)
    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    if not buffCmpt then 
        Log.fatal("entity not have buff cmpt")
        return nil
    end

    local buffValue = buffCmpt:GetBuffValue(key)
    if not buffValue then 
        ---这里可以根据参数，返回nil或者0
        return nil
    end

    return buffValue
end

function UtilDataServiceShare:OnCheckEntityHasBuffFlag(entity, BuffFlag)
    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    if not buffCmpt then
        return nil
    end

    local hasBuffFlag = buffCmpt:HasFlag(BuffFlag)
    if hasBuffFlag then
        return true
    end
    return false
end

---根据key查询entity身上AI组件里运行时的值
function UtilDataServiceShare:GetEntityAIRuntimeData(entity,key)
    ---@type AIComponentNew
    local aiCmpt = entity:AI()
    if not aiCmpt then 
        return nil
    end

    local runTimeData = aiCmpt:GetRuntimeData(key)
    return runTimeData
end

---@param entity Entity
function UtilDataServiceShare:GetTrapCurseTowerState(entity)
    ---@type CurseTowerComponent
    local curseTowerCmpt = entity:CurseTower()
    if curseTowerCmpt == nil then 
        return nil
    end

    local state = curseTowerCmpt:GetTowerState()
    return state
end

---@param pos Vector2
---@return PieceType|nil
function UtilDataServiceShare:GetPieceType(pos)
    ---@type Entity
    local eBoard = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = eBoard:Board()
    return cBoard:GetPieceData(pos)
end
function UtilDataServiceShare:GetBuffLayer(entity,buffEffectType)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local buffLayer = buffLogicService:GetBuffLayer(entity, buffEffectType)
    return buffLayer
end
function UtilDataServiceShare:HasBuffEffect(entity,buffEffectType)
    local buffCmp = entity:BuffComponent()
    return buffCmp and buffCmp:HasBuffEffect(buffEffectType)
end
---@param entity Entity
function UtilDataServiceShare:IsEntityLogicDead(entity)
    return entity:HasDeadMark()
end
-- ---@param entity Entity
-- function UtilDataServiceShare:IsPetSkillReady(petEntity)
--     if petEntity then
--         local attr = petEntity:Attributes()
--         if attr then
--             local ready = attr:GetAttribute("Ready")
--             if ready  then
--                 if ready == 1 then
--                     return true
--                 end
--             end
--         end
--     end
--     return false
-- end
function UtilDataServiceShare:IsPetExtraActiveSkill(petEntity,skillID)
    if petEntity then
        ---@type SkillInfoComponent
        local skillInfoCmpt = petEntity:SkillInfo()
        local extraSkillIDList = skillInfoCmpt:GetExtraActiveSkillIDList()
        if extraSkillIDList then
            for extraSkillIndex, extraSkillID in ipairs(extraSkillIDList) do
                if extraSkillID == skillID then
                    return true,extraSkillIndex
                end
            end
        end
        -- if extraSkillIDList and table.icontains(extraSkillIDList,skillID) then
        --     return true
        -- end
    end
    return false
end
--只在附加技能初始化时使用
function UtilDataServiceShare:SetPetSkillReadyAttr(petEntity,ready,skillID)
    if petEntity then
        local isExtraSkill,extraSkillIndex = self:IsPetExtraActiveSkill(petEntity,skillID)
        if isExtraSkill then
            local attr = petEntity:Attributes()
            if attr then
                local extraKey = "Ready"..tostring(extraSkillIndex)
                attr:SetSimpleAttribute(extraKey, ready)
            end
        else
            local attr = petEntity:Attributes()
            if attr then
                attr:Modify("Ready",ready)
            end
        end
    end
end
---@param entity Entity
function UtilDataServiceShare:GetPetSkillReadyAttr(petEntity,skillID)
    if petEntity then
        local isExtraSkill,extraSkillIndex = self:IsPetExtraActiveSkill(petEntity,skillID)
        if isExtraSkill then
            local attr = petEntity:Attributes()
            if attr then
                local readyKey = "Ready"..tostring(extraSkillIndex)
                local ready = attr:GetAttribute(readyKey)
                if not ready then
                    ready = 0
                end
                return ready
            end
        else
            local attr = petEntity:Attributes()
            if attr then
                local ready = attr:GetAttribute("Ready")
                return ready
            end
        end
    end
end
---@param e Entity
function UtilDataServiceShare:ChangePetActiveSkillReady(e, ready,skillID)
    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    buffSvc:ChangePetActiveSkillReady(e, ready,skillID)
end
---@param entity Entity
function UtilDataServiceShare:GetPetPowerAttr(petEntity,skillID)
    if petEntity then
        local isExtraSkill,extraSkillIndex = self:IsPetExtraActiveSkill(petEntity,skillID)
        if isExtraSkill then
            local attr = petEntity:Attributes()
            if attr then
                local extraKey = "Power"..tostring(extraSkillIndex)
                local power = attr:GetAttribute(extraKey)
                if not power then
                    power = 0
                end
                return power
            end
        else
            local attr = petEntity:Attributes()
            if attr then
                local power = attr:GetAttribute("Power")
                return power
            end
        end
    end
end
function UtilDataServiceShare:SetPetPowerAttr(petEntity,power,skillID)
    if petEntity then
        local isExtraSkill,extraSkillIndex = self:IsPetExtraActiveSkill(petEntity,skillID)
        if isExtraSkill then
            local attr = petEntity:Attributes()
            if attr then
                local extraKey = "Power"..tostring(extraSkillIndex)
                attr:SetSimpleAttribute(extraKey, power)
            end
        else
            local attr = petEntity:Attributes()
            if attr then
                attr:Modify("Power",power)
            end
        end
    end
end
function UtilDataServiceShare:GetPetMaxPowerAttr(petEntity,skillID)
    if petEntity then
        local isExtraSkill,extraSkillIndex = self:IsPetExtraActiveSkill(petEntity,skillID)
        if isExtraSkill then
            local attr = petEntity:Attributes()
            if attr then
                local extraKey = "MaxPower"..tostring(extraSkillIndex)
                local maxPower = attr:GetAttribute(extraKey)
                if not maxPower then
                    maxPower = 0
                end
                return maxPower
            end
        else
            local attr = petEntity:Attributes()
            if attr then
                local maxPower = attr:GetAttribute("MaxPower")
                return maxPower
            end
        end
    end
end
function UtilDataServiceShare:SetPetMaxPowerAttr(petEntity,maxPower,skillID)
    if petEntity then
        local isExtraSkill,extraSkillIndex = self:IsPetExtraActiveSkill(petEntity,skillID)
        if isExtraSkill then
            local attr = petEntity:Attributes()
            if attr then
                local extraKey = "MaxPower"..tostring(extraSkillIndex)
                attr:SetSimpleAttribute(extraKey, maxPower)
            end
        else
            local attr = petEntity:Attributes()
            if attr then
                attr:Modify("MaxPower",maxPower)
            end
        end
    end
end
---@param entity Entity
function UtilDataServiceShare:GetPetLegendPowerAttr(petEntity,skillID)
    if petEntity then
        --目前共用一个属性
        local attr = petEntity:Attributes()
        if attr then
            local legendPower = attr:GetAttribute("LegendPower")
            return legendPower
        end
    end
    return 0
end
function UtilDataServiceShare:GetPreviousReadyRoundCount(petPstID)
    local petEntity = self:GetEntityByPstID(petPstID)
    if petEntity then
        ---@type Entity
        local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        if teamEntity then
            local readyCount = teamEntity:ActiveSkill():GetPreviousReadyRoundCount(petEntity:GetID())--改成GetPreviousReadyRoundCount
            return readyCount
        end
    end
    return 0
end

function UtilDataServiceShare:FindMonsterByMonsterID(monsterID)
    ---@type Entity[]
    local monsterEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    local retEntity = {}
    for _, e in ipairs(monsterEntities) do
        ---@type MonsterIDComponent
        local monsterIDCmpt = e:MonsterID()
        if monsterIDCmpt:GetMonsterClassID() == monsterID then
            table.insert(retEntity,e)
        end
    end
    return retEntity
end

function UtilDataServiceShare:GetMapByPosition()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()
    local mapByPosition = boardComponent:GetMapByPosition()
    return mapByPosition
end

function UtilDataServiceShare:CheckForceMoveImmunity(entity)
    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    return buffSvc:CheckForceMoveImmunity(entity)
end

function UtilDataServiceShare:IsEntityForceMovementTarget(e,includeMultiSize,includeTrap)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        if includeTrap then
            if e:HasTrapID() then
                return true
            end
        end
        return e:HasTeam() or e:HasPet()
    end
    local isTrap = false
    if not e:HasMonsterID() then
        if includeTrap and e:HasTrapID() then
            isTrap = true
        else
            return false
        end
    end

    if not isTrap then
        ---@type ConfigService
        local cfgsvc = self._world:GetService("Config")
        local monsterConfigData = cfgsvc:GetMonsterConfigData()
        local monsterID = e:MonsterID():GetMonsterID()
        if monsterConfigData:IsBoss(monsterID) then
            return false
        end
    end

    if (not includeMultiSize) and (e:BodyArea():GetAreaCount() ~= 1) then
        return false
    end

    ---@type BuffComponent
    local buffComponent = e:BuffComponent()
    if buffComponent and buffComponent:HasBuffEffect(BuffEffectType.NotBeSelectedAsSkillTarget) then
        return false
    end

    -- 免疫 强制位移（及牵引的强制效果）
    ---@type BuffLogicService
    local bufflsvc = self._world:GetService("BuffLogic")
    if bufflsvc:CheckForceMoveImmunity(e) then
        return false
    end

    return true
end

--region 阿克希亚-扫描模块支持
function UtilDataServiceShare:ScanTrapOnBoard()
    local trapTemplateID = {}
    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, entity in ipairs(globalTrapEntities) do
        local trapID = entity:TrapID():GetTrapID()
        if entity:HasDeadMark() then
            goto CONTINUE
        end

        if not Cfg.cfg_trap_scan[trapID] then
            goto CONTINUE
        end

        table.insert(trapTemplateID, trapID)

        ::CONTINUE::
    end

    return trapTemplateID
end

function UtilDataServiceShare:ScanTrapInMatch()
    local trapTemplateID = {}

    local trapIDInMatch = self._world:BattleStat():GetAllScanTrapIDInMatch()
    for _, id in ipairs(trapIDInMatch) do
        if not Cfg.cfg_trap_scan[id] then
            goto CONTINUE
        end

        table.insert(trapTemplateID, id)

        ::CONTINUE::
    end

    return trapTemplateID
end

function UtilDataServiceShare:GetScanSelection()
    local boardEntity = self._world:GetBoardEntity()
    local cLogicFeature = boardEntity:LogicFeature()
    local info = {
        skillType = cLogicFeature:GetScanActiveSkillType(),
        trapID = cLogicFeature:GetScanTrapID()
    }
    return info
end

---@return MatchPet|nil
function UtilDataServiceShare:GetLocalMatchPetByTemplateID(tid)
    ---@type Entity
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    local cTeam = eLocalTeam:Team()
    ---@type Entity[]
    local pets = cTeam:GetTeamPetEntities()
    for _, e in ipairs(pets) do
        local petPstID = e:PetPstID():GetTemplateID()
        if tid == petPstID then
            return e:MatchPet():GetMatchPet()
        end
    end
end
--endregion

function UtilDataServiceShare:IsPosCanConvertGridElement(pos)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetCanConvertGridElement(pos)
end

function UtilDataServiceShare:CalcZhongxuForceMovementCostByPick(casterEntity,skillID)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
    if skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        ---@type ActiveSkillPickUpComponent
        local pickCmpt = casterEntity:ActiveSkillPickUpComponent()
        if not pickCmpt then
            pickCmpt = casterEntity:PreviewPickUpComponent()--sjs_todo 
        end
        if cfgExtraParam and pickCmpt then
            if cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep] then--仲胥，能量消耗需要根据位移步数（回合内累加）计算
                local costParamTb = cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep]
                --每回合移动的格字数累计 在buffValue
                local recordBuffCmpt = casterEntity:BuffComponent()
                local buffValueKey = "CurRoundForceMoveStep"
                local curRoundForceMoveStep = recordBuffCmpt:GetBuffValue(buffValueKey) or 0
                local eachMoveCostParam = costParamTb[1]--scopeParam.eachMoveCostParam --第n格(n需要加上curRoundForceMoveStep) eachMoveCostParam*n 累加
                local trapMoveCostExtraParam = costParamTb[2]--scopeParam.trapMoveCostExtraParam --原来是乘法系数，后改为机关的每格消耗
                local specificTrapID = costParamTb[3]--可点的机关
                local curLegendPower = casterEntity:Attributes():GetAttribute("LegendPower")
                local allPickGrids = pickCmpt:GetAllValidPickUpGridPos()
                if allPickGrids then
                    if #allPickGrids == 2 then
                        local firstPickGrid = allPickGrids[1]
                        local secondPickGrid = allPickGrids[2]

                        local foundTrapEntity = nil
                        local foundMonsterEntity = nil
                        local foundEnemyTeamEntity = nil
                        local centerPos = firstPickGrid
                        local traps = self:GetTrapsAtPos(centerPos)
                        if traps then
                            for index, e in ipairs(traps) do
                                local trapId = e:Trap():GetTrapID()
                                if specificTrapID == trapId then
                                    foundTrapEntity = e
                                    break
                                end
                            end
                        end
                        local moveEntity = nil
                        local isTrap = false
                        if foundTrapEntity then
                            isTrap = true
                            moveEntity = foundTrapEntity
                        else
                            if self._world:MatchType() == MatchType.MT_BlackFist then
                                if casterEntity:HasPet() then
                                    local enemy = casterEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
                                    local enemyPos = enemy:GetGridPosition()
                                    if enemyPos == centerPos then
                                        foundEnemyTeamEntity = enemy
                                        moveEntity = foundEnemyTeamEntity
                                    end
                                end
                            else
                                ----@type UtilScopeCalcServiceShare
                                local utilScopeSvc = self._world:GetService("UtilScopeCalc")
                                local isHasMonster, monsterID = utilScopeSvc:IsPosHasMonster(centerPos)
                                if isHasMonster then
                                    local monsterEntity = self._world:GetEntityByID(monsterID)--配合点选，这个怪默认是可强制位移的
                                    if monsterEntity then
                                        foundMonsterEntity = monsterEntity
                                        moveEntity = foundMonsterEntity
                                    end
                                end
                            end
                        end
                        if moveEntity then
                            local moveDirAnti,moveStep = self:_CalcFroceMoveDirByTargetAndPick(moveEntity,firstPickGrid,secondPickGrid,0,true)
                            local totalCost = 0
                            for i = 1, moveStep do
                                local eachCost = eachMoveCostParam
                                if isTrap then
                                    eachCost = trapMoveCostExtraParam
                                end
                                local curStep = curRoundForceMoveStep + i
                                local curStepCost = eachCost * curStep
                                totalCost = totalCost + curStepCost
                            end
                            return totalCost,moveStep
                        end
                    end
                end
            end
        end
    end
    return -1
end
function UtilDataServiceShare:CalcZhongxuForceMovementMoveStepByPick(casterEntity,skillID)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
    if skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        ---@type ActiveSkillPickUpComponent
        local pickCmpt = casterEntity:ActiveSkillPickUpComponent()
        if not pickCmpt then
            pickCmpt = casterEntity:PreviewPickUpComponent()--sjs_todo 
        end
        if cfgExtraParam and pickCmpt then
            if cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep] then--仲胥，能量消耗需要根据位移步数（回合内累加）计算
                local costParamTb = cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep]
                --每回合移动的格字数累计 在buffValue
                local recordBuffCmpt = casterEntity:BuffComponent()
                local buffValueKey = "CurRoundForceMoveStep"
                local curRoundForceMoveStep = recordBuffCmpt:GetBuffValue(buffValueKey) or 0
                local eachMoveCostParam = costParamTb[1]--scopeParam.eachMoveCostParam --第n格(n需要加上curRoundForceMoveStep) eachMoveCostParam*n 累加
                local trapMoveCostExtraParam = costParamTb[2]--scopeParam.trapMoveCostExtraParam--原来是乘法系数，后改为机关的每格消耗
                local specificTrapID = costParamTb[3]--可点的机关
                local curLegendPower = casterEntity:Attributes():GetAttribute("LegendPower")
                local allPickGrids = pickCmpt:GetAllValidPickUpGridPos()
                if allPickGrids then
                    if #allPickGrids == 2 then
                        local firstPickGrid = allPickGrids[1]
                        local secondPickGrid = allPickGrids[2]

                        local foundTrapEntity = nil
                        local foundMonsterEntity = nil
                        local foundEnemyTeamEntity = nil
                        local centerPos = firstPickGrid
                        local traps = self:GetTrapsAtPos(centerPos)
                        if traps then
                            for index, e in ipairs(traps) do
                                local trapId = e:Trap():GetTrapID()
                                if specificTrapID == trapId then
                                    foundTrapEntity = e
                                    break
                                end
                            end
                        end
                        local moveEntity = nil
                        local isTrap = false
                        if foundTrapEntity then
                            isTrap = true
                            moveEntity = foundTrapEntity
                        else
                            if self._world:MatchType() == MatchType.MT_BlackFist then
                                if casterEntity:HasPet() then
                                    local enemy = casterEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
                                    local enemyPos = enemy:GetGridPosition()
                                    if enemyPos == centerPos then
                                        foundEnemyTeamEntity = enemy
                                        moveEntity = foundEnemyTeamEntity
                                    end
                                end
                            else
                                ----@type UtilScopeCalcServiceShare
                                local utilScopeSvc = self._world:GetService("UtilScopeCalc")
                                local isHasMonster, monsterID = utilScopeSvc:IsPosHasMonster(centerPos)
                                if isHasMonster then
                                    local monsterEntity = self._world:GetEntityByID(monsterID)--配合点选，这个怪默认是可强制位移的
                                    if monsterEntity then
                                        foundMonsterEntity = monsterEntity
                                        moveEntity = foundMonsterEntity
                                    end
                                end
                            end
                        end
                        if moveEntity then
                            local moveDirAnti,moveStep = self:_CalcFroceMoveDirByTargetAndPick(moveEntity,firstPickGrid,secondPickGrid,0,true)
                            local totalCost = 0
                            for i = 1, moveStep do
                                local eachCost = eachMoveCostParam
                                if isTrap then
                                    eachCost = trapMoveCostExtraParam
                                end
                                local curStep = curRoundForceMoveStep + i
                                local curStepCost = eachCost * curStep
                                totalCost = totalCost + curStepCost
                            end
                            return totalCost
                        end
                    end
                end
            end
        end
    end
    return -1
end
function UtilDataServiceShare:CalcZhongxuForceMovementMinCost(casterEntity,skillID,moveStepNotRecoreded,forAutoFight)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
    if skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        if cfgExtraParam then
            if cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep] then--仲胥，能量消耗需要根据位移步数（回合内累加）计算
                local costParamTb = cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep]
                --每回合移动的格字数累计 在buffValue
                local recordBuffCmpt = casterEntity:BuffComponent()
                local buffValueKey = "CurRoundForceMoveStep"
                local curRoundForceMoveStep = recordBuffCmpt:GetBuffValue(buffValueKey) or 0
                if moveStepNotRecoreded then
                    curRoundForceMoveStep = curRoundForceMoveStep + moveStepNotRecoreded
                end
                local eachMoveCostParam = costParamTb[1]--scopeParam.eachMoveCostParam --第n格(n需要加上curRoundForceMoveStep) eachMoveCostParam*n 累加
                local trapMoveCostExtraParam = costParamTb[2]--scopeParam.trapMoveCostExtraParam--原来是乘法系数，后改为机关的每格消耗
                local specificTrapID = costParamTb[3]--可点的机关
                local moveStep = 1
                local totalCost = 0
                for i = 1, moveStep do
                    local curStep = curRoundForceMoveStep + i
                    local eachCost = eachMoveCostParam
                    if forAutoFight then--自动战斗 只算机关
                        if trapMoveCostExtraParam then--容错
                            eachCost = trapMoveCostExtraParam
                        end
                    end
                    local curStepCost = eachCost * curStep
                    totalCost = totalCost + curStepCost
                end
                return totalCost
            end
        end
    end
    return -1
end
function UtilDataServiceShare:CalcMinCostLegendPowerByExtraParam(entity,defaultCost,skillConfigData,zhongxuForceMoveStep,forAutoFight)
    local cost = defaultCost
    if skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        if cfgExtraParam then
            if cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep] then--仲胥，能量消耗需要根据位移步数（回合内累加）计算
                --取本次最低消耗（位移怪物一格）
                cost = self:CalcZhongxuForceMovementMinCost(entity,skillConfigData:GetID(),zhongxuForceMoveStep,forAutoFight)
                if cost < 0 then
                    cost = defaultCost
                end
            end
        end
    end
    return cost
end

function UtilDataServiceShare:_CalcFroceMoveDirByTargetAndPick(targetEntity, pickPos,dirPos,defaultStep,isCalcStepByPick)
    local dir
    local step = defaultStep
    local targetPos = targetEntity:GetGridPosition()
    local bodyArea = targetEntity:BodyArea():GetArea()
    if bodyArea then
        if #bodyArea == 1 then
            dir = dirPos - pickPos
            step = math.abs(dir.x) + math.abs(dir.y)
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
        else
            local upMaxY = nil
            local downMinY = nil
            local rightMaxX = nil
            local leftMinX = nil
            for index, off in ipairs(bodyArea) do
                local bodyPos = targetPos + off
                if not upMaxY then
                    upMaxY = bodyPos.y
                elseif bodyPos.y > upMaxY then
                    upMaxY = bodyPos.y
                end
                if not downMinY then
                    downMinY = bodyPos.y
                elseif bodyPos.y < downMinY then
                    downMinY = bodyPos.y
                end
                if not rightMaxX then
                    rightMaxX = bodyPos.x
                elseif bodyPos.x > rightMaxX then
                    rightMaxX = bodyPos.x
                end
                if not leftMinX then
                    leftMinX = bodyPos.x
                elseif bodyPos.x < leftMinX then
                    leftMinX = bodyPos.x
                end
            end
            if dirPos.y > upMaxY then--上
                dir = Vector2.up
                if isCalcStepByPick then
                    step = dirPos.y - upMaxY
                end
            elseif dirPos.y < downMinY then
                dir = Vector2.down
                if isCalcStepByPick then
                    step = downMinY - dirPos.y
                end
            elseif dirPos.x > rightMaxX then
                dir = Vector2.right
                if isCalcStepByPick then
                    step = dirPos.x - rightMaxX
                end
            elseif dirPos.x < leftMinX then
                dir = Vector2.left
                if isCalcStepByPick then
                    step = leftMinX - dirPos.x
                end
            end
        end
    end
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
    --注意方向与移动方向相反
    dir = dir * -1
    return dir,step
end

function UtilDataServiceShare:GetPrismCustomScopeConfig(entityID)
    ---@type Entity
    local entity = self._world:GetEntityByID(entityID)
    if not entity then
        return
    end

    if not entity:HasTrap() then
        return
    end

    local cTrap = entity:Trap()
    if not cTrap:IsPrismGrid() then
        return
    end

    return cTrap:GetCustomPrismGridScopeType(), cTrap:GetCustomPrismGridScopeParam()
end
function UtilDataServiceShare:CalcZhongxuForceMovementNextMinCostForUI(entity,skillID)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, entity)
    local minCost = skillConfigData:GetSkillTriggerParam()
    --UI用的时候 根据当前点选信息计算出本次移动的步数（此时这部分还没有记录到buffvalue里)
    local cost,zhongxuForceMoveStep = self:CalcZhongxuForceMovementCostByPick(entity,skillID)
    if cost < 0 then
        cost = minCost
    end
    if zhongxuForceMoveStep < 0 then
        zhongxuForceMoveStep = 0
    end
    minCost = self:CalcMinCostLegendPowerByExtraParam(entity,minCost,skillConfigData,zhongxuForceMoveStep,false)
    return minCost
end
function UtilDataServiceShare:GetSummonMeantimeLimitEntityID(trapID)
    ---@type BattleFlagsComponent
    local battleFlags = self._world:BattleFlags()
    local entityIDList = battleFlags:GetSummonMeantimeLimitEntityID(trapID)
    return entityIDList
end

function UtilDataServiceShare:IsPieceRefreshTypeDestroy()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    local refreshType = affixService:ReplacePieceRefreshType()
    if refreshType == PieceRefreshType.Destroy then
        return true
    end
    return false
end

--region SpliceBoard
function UtilDataServiceShare:GetReplicaSpliceGridEntityData()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardSpliceComponent
    local boardSpliceComponent = boardEntity:BoardSplice()
    local gridEntityData = boardSpliceComponent:GetGridEntityData()

    if not gridEntityData then
        return
    end

    local replica = {}
    for k, v in pairs(gridEntityData) do
        replica[k] = v
    end

    return replica
end

function UtilDataServiceShare:GetReplicaSpliceBoardPieces()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardSpliceComponent
    local boardSpliceComponent = boardEntity:BoardSplice()

    local replica = {}
    for x, col in pairs(boardSpliceComponent.Pieces) do
        replica[x] = {}
        for y, grid in pairs(col) do
            replica[x][y] = grid
        end
    end

    return replica
end

function UtilDataServiceShare:GetCloneBoardSpliceGridPos()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardSpliceComponent
    local boardSpliceComponent = boardEntity:BoardSplice()
    return boardSpliceComponent:CloneBoardPosList()
end
function UtilDataServiceShare:GetCurrentTeamSuperChainCount()
    local count = BattleConst.SuperChainCount
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if teamEntity then
        ---@type AttributesComponent
        local teamAttr = teamEntity:Attributes()
        if teamAttr then
            local superChainCountAddValue = teamAttr:GetAttribute("SuperChainCountAddValue")
            if superChainCountAddValue then
                count = count + superChainCountAddValue
            end
        end
    end
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    if affixService:HasAddChainPathNum() then
        local affixAddNum = affixService:GetAddChainPathNum()
        if affixAddNum then
            count = count - affixAddNum
        end
    end
    return count
end
--endregion SpliceBoard

function UtilDataServiceShare:GetRoundBeginPlayerPos()
    return self._world:BattleStat():GetRoundBeginPlayerPos()
end


---@return PieceType
---@param pos Vector2
function UtilDataServiceShare:GetRenderPieceType(pos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type Entity
    local gridEntity = renderBoardCmpt:GetGridRenderEntity(pos)
    local pieceType = gridEntity:Piece():GetPieceType()
    return pieceType
end