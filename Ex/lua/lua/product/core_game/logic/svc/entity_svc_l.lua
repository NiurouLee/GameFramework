--[[------------------------------------------------------------------------------------------
    LogicEntityService 处理实体的公共服务对象 
    此对象也会封装一些创建类型Entity的函数
]] --------------------------------------------------------------------------------------------
require("entity_assemble_extension")
_class("LogicEntityService", BaseService)
---@class LogicEntityService:BaseService
LogicEntityService = LogicEntityService

function LogicEntityService:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param entityConstId number EntityConfigIDConst或EntityConfigIDRender
---@param bShow boolean 默认是否显示；不传默认显示
---@return Entity
function LogicEntityService:CreateLogicEntity(entityConstId, bShow)
    local ctx = EntityCreationContext:New()
    ctx.entity_config_id = entityConstId
    if bShow == nil then
        ctx.bShow = true
    else
        ctx.bShow = bShow
    end

    ---@type Entity
    local entity = self._world:CreateEntity()
    self._world:SetEntityIdByEntityConfigId(entity, entityConstId)
    EntityAssembler.AssembleEntityComponents(entity, ctx)
    self:LogNotice("CreateEntity entityConfigID=", entityConstId, " entityID=", entity:GetID())
    self._world:GetSyncLogger():Trace({key = "CreateEntity", entityConstId = entityConstId, entityID = entity:GetID()})
    return entity
end

---@return Entity 棋盘本身的Entity
function LogicEntityService:CreateBoardEntity()
    local eBoard = self:CreateLogicEntity(EntityConfigIDConst.Board)
    self._world:SetBoardEntity(eBoard)
    return eBoard
end

---@return Entity 网络处理的Entity
function LogicEntityService:CreateNetworkEntity()
    local networkEntity = self:CreateLogicEntity(EntityConfigIDConst.Network)
    self._world:Player():SetNetworkEntity(networkEntity)
    return networkEntity
end

---生成棋盘上的信息，包括棋盘上每个位置上的颜色等格子信息
---用这些信息来填充board component
function LogicEntityService:GenerateBoardData()
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    --棋盘使用的格子类型ID
    local gridGenID = levelConfigData:GetGridGenID()

    self:GenerateBoardDataByID(gridGenID)

    --多面棋盘
    local multiBoard = levelConfigData:GetMultiBoard()
    self:GenerateMultiBoardDataByID(multiBoard)
	
    --拼接棋盘
    self:GenerateSpliceBoardDataByID(gridGenID)
end
---生成棋盘上的信息，包括棋盘上每个位置上的颜色等格子信息
---用这些信息来填充board component
function LogicEntityService:GenerateBoardDataByID(gridGenID, teamEntity)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()

    local boardConfig = Cfg.cfg_board[gridGenID]
    --无格子
    if boardConfig.GapTiles then
        local cloneGapTiles = {}
        for idx, GapTile in pairs(boardConfig.GapTiles) do
            cloneGapTiles[idx] = GapTile
        end
        boardServiceLogic:ChangeGapTiles(cloneGapTiles)
    end
    --棋盘中心
    if boardConfig.BoardCenterPos then
        local v = Vector2(boardConfig.BoardCenterPos[1], boardConfig.BoardCenterPos[2])
        boardServiceLogic:SetBoardCenterPos(v)
    end
    --额外的棋盘,只有攻击单体的技能效果才可以攻击到的范围
    if boardConfig.ExtraBoard then
        boardServiceLogic:SetExtraBoardPosList(boardConfig.ExtraBoard)
    end

    --生成棋盘
    local pieceTable = boardServiceLogic:GenerateBoard(gridGenID, teamEntity)
    local isRefresh = teamEntity and true or false

    ---@type BoardComponent
    local boardComponent = boardEntity:Board()
    if boardComponent then
        boardComponent:ClearGridEntityData()
        boardComponent:InitPieceTableData(pieceTable, isRefresh)
        local changePosArray = boardComponent:GetChangePosAndClear()
        if changePosArray then
            for i = 1, #changePosArray do
                local pos = changePosArray[i]
                local pieceType = boardComponent:GetPieceType(pos)
                if boardServiceLogic:IsPosBlock(pos, BlockFlag.Skill | BlockFlag.SkillSkip) then
                    pieceType = PieceType.None
                end
                --生成格子
                if
                    boardServiceLogic:IsValidPiecePos(pos) and not boardServiceLogic:IsObstacleTrapTile(pos) and
                        pieceType ~= nil
                 then
                    boardComponent:AddGridEntityData(Vector2(pos.x, pos.y), pieceType)
                end
            end
        end
    end

    boardServiceLogic:SetGapTilesBlock()
end

---生成多面棋盘信息
function LogicEntityService:GenerateMultiBoardDataByID(multiBoard)
    if not multiBoard or table.count(multiBoard) == 0 then
        return
    end

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    ---@type BoardMultiServiceLogic
    local boardMultiServiceLogic = self._world:GetService("BoardMultiLogic")

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()

    for i, boardInfo in ipairs(multiBoard) do
        local boardIndex = boardInfo.index
        local gridGenID = boardInfo.board

        local boardConfig = Cfg.cfg_board[gridGenID]

        --无格子
        if boardConfig.GapTiles then
            boardMultiServiceLogic:ChangeGapTiles(boardIndex, boardConfig.GapTiles)
        end
        --棋盘中心
        if boardConfig.BoardCenterPos then
            local v = Vector2(boardConfig.BoardCenterPos[1], boardConfig.BoardCenterPos[2])
            boardMultiServiceLogic:SetBoardCenterPos(boardIndex, v)
        end

        --生成棋盘
        local pieceTable = boardMultiServiceLogic:GenerateBoard(boardIndex, gridGenID)

        ---@type BoardMultiComponent
        local boardMultiComponent = boardEntity:BoardMulti()
        if boardMultiComponent then
            boardMultiComponent:InitPieceTableData(pieceTable, boardIndex)
            local changePosArray = boardMultiComponent:GetChangePosAndClear(boardIndex)
            if changePosArray then
                for i = 1, #changePosArray do
                    local pos = changePosArray[i]
                    local pieceType = boardMultiComponent:GetPieceType(pos, boardIndex)
                    if boardServiceLogic:IsPosBlock(pos, BlockFlag.Skill | BlockFlag.SkillSkip) then
                        pieceType = PieceType.None
                    end
                    --生成格子
                    if
                        boardServiceLogic:IsValidPiecePos(pos) and not boardServiceLogic:IsObstacleTrapTile(pos) and
                            pieceType ~= nil
                     then
                        boardMultiComponent:AddGridEntityData(Vector2(pos.x, pos.y), pieceType, boardIndex)
                    end
                end
            end
        end
    end
end

function LogicEntityService:GenerateSpliceBoardDataByID(gridGenID)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    local boardConfig = Cfg.cfg_board[gridGenID]
    --可以拼接的棋盘
    if not boardConfig.SpliceBoard then
        return
    end
    boardServiceLogic:SetSpliceBoardPosList(boardConfig.SpliceBoard)
    --生成棋盘
    local pieceTable = boardServiceLogic:GenerateSpliceBoard(gridGenID)
    ---@type BoardSpliceComponent
    local boardSpliceComponent = boardEntity:BoardSplice()
    if boardSpliceComponent then
        boardSpliceComponent:InitPieceTableData(pieceTable)
        local changePosArray = boardSpliceComponent:GetChangePosAndClear()
        if changePosArray then
            for i = 1, #changePosArray do
                local pos = changePosArray[i]
                local pieceType = boardSpliceComponent:GetPieceType(pos)
                --生成格子
                if pieceType ~= nil then
                    boardSpliceComponent:AddGridEntityData(Vector2(pos.x, pos.y), pieceType)
                end
            end
        end
    end
end

---创建指定波次的怪物entity
function LogicEntityService:CreateWaveMonsters(waveNum)
    --存在玩家的时候取玩家的坐标
    local playerPos = nil
    if self._world:MatchType() ~= MatchType.MT_Chess then
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        playerPos = teamEntity:GridLocation():GetGridPos()
    end

    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type MonsterTransformParam
    local monsterArray = nil

    ---@type CreateMonsterPosService
    local createMonsterPosService = self._world:GetService("CreateMonsterPos")
    ---@type LevelMonsterRefreshParam
    local monsterRefreshParam = levelConfigData:GetLevelWaveBeginRefreshMonsterParam(waveNum, playerPos)
    if (monsterRefreshParam == nil) then
        Log.error("[wave] _CreateMonsters error ", waveNum)
    end
    ---@type MonsterRefreshPosType
    local monsterRefreshPosType = monsterRefreshParam:GetMonsterRefreshPosType()
    monsterArray = createMonsterPosService:GetMonsterRefreshPos(monsterRefreshPosType, monsterRefreshParam)
    if not monsterArray then
        ---TODO 获取关卡ID打印错误日志
        Log.fatal("CreateMonsterArray Failed LevelID:")
    end

    ---创建的怪物如果是强制创建并击退身形内的玩家MonsterRefreshPosType.PositionHitBack 需要表现击退过程
    local hitbackResult
    if monsterRefreshPosType == MonsterRefreshPosType.PositionHitBack then
        hitbackResult = self:_DoLogicRefreshMonsterHitBackTeam(monsterArray)
    end

    local eMonsters = {}
    local monsterIds = {}
    ---@type MonsterCreationServiceLogic
    local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")
    for _, v in ipairs(monsterArray) do
        local eMonster, monsterId = monsterCreationSvc:CreateMonster(v)
        table.insert(eMonsters, eMonster)
        table.insert(monsterIds, monsterId)
        self._world:GetSyncLogger():Trace(
            {
                key = "CreateWaveMonsters",
                waveNum = waveNum,
                monsterID = monsterId,
                entityID = eMonster:GetID(),
                pos = tostring(v:GetPosition())
            }
        )
    end
    return eMonsters, hitbackResult
end

function LogicEntityService:_DoLogicRefreshMonsterHitBackTeam(monsterArray)
    local targetPos = nil
    local needHitBack = false
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    local scopeMonsterBodyArea = {}
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    for _, monsterTransform in ipairs(monsterArray) do
        local monsterPosition = monsterTransform:GetPosition()
        local monsterID = monsterTransform:GetMonsterID()
        local areaArray = monsterConfigData:GetMonsterArea(monsterID)

        for _, area in ipairs(areaArray) do
            local workPos = monsterPosition + area
            table.insert(scopeMonsterBodyArea, workPos)
        end
    end

    if table.icontains(scopeMonsterBodyArea, teamPos) then
        needHitBack = true
    end

    if not needHitBack then
        return
    end

    --计算击退坐标
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local scopeResult = scopeCalculator:ComputeScopeRange(SkillScopeType.CanMovePos, {}, teamPos, {Vector2(0, 0)})
    local attackRange = scopeResult:GetAttackRange()
    local scopeFilter = {}
    for _, pos in ipairs(attackRange) do
        if not table.icontains(scopeMonsterBodyArea, pos) then
            table.insert(scopeFilter, pos)
        end
    end
    local nearestPos = Vector2(1000, 1000)
    for _, pos in ipairs(scopeFilter) do
        local lastPosToTargetPosDistance = Vector2.Distance(nearestPos, teamPos)
        local curPosToTargetPosDistance = Vector2.Distance(pos, teamPos)

        if curPosToTargetPosDistance < lastPosToTargetPosDistance then
            nearestPos = pos
        end
    end
    targetPos = nearestPos
    local dir = targetPos - teamPos
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()

    ---@type SkillEffectCalcService
    local skillEffectService = self._world:GetService("SkillEffectCalc")
    local hitbackResult =
        skillEffectService:CalcHitbackEffectResultProcess(
        teamEntity:GetID(),
        HitBackCalcType.Instant,
        boardEntity,
        dir,
        targetPos
    )

    return hitbackResult
end

function LogicEntityService:CreateArchivedMonsters(monsters)
    local t = {}
    for k, v in ipairs(monsters) do
        local param = MonsterTransformParam:New(v.monsterID)
        param:SetPosition(v.pos)
        param:SetForward(v.dir)
        param:SetBodyArea(v.bodyArea)
        param:SetOffset(v.offset)
        param._hp = v.hp
        param._airt = v.aiData
        param._bindeff = v.effect
        param._buffrt = v.buffData
        t[#t + 1] = param
    end

    local eMonsters = {}
    local monsterIds = {}
    ---@type MonsterCreationServiceLogic
    local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")
    for _, v in ipairs(t) do
        local eMonster, monsterId =
        monsterCreationSvc:CreateMonsterWithInitADH(
            v,
            {
                curhp = v._hp,
                airt = v._airt,
                bindeff = v._bindeff,
                buffrt = v._buffrt
            }
        )
        table.insert(eMonsters, eMonster)
        table.insert(monsterIds, monsterId)
        self._world:GetSyncLogger():Trace(
            {
                key = "CreateArchivedMonsters",
                waveNum = 1,
                monsterID = monsterId,
                entityID = eMonster:GetID(),
                pos = tostring(v:GetPosition())
            }
        )
    end
    return eMonsters
end

---创建波次机关
function LogicEntityService:CreateWaveTraps(waveNum)
    --存在玩家的时候取玩家的坐标
    local playerPos = nil
    if self._world:MatchType() ~= MatchType.MT_Chess then
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        playerPos = teamEntity:GridLocation().Position
    end

    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    ---目前只做了第一波怪的关卡信息
    local refreshParam = levelConfigData:GetLevelWaveBeginRefreshMonsterParam(waveNum, playerPos)
    local trapIDArray = refreshParam:GetTrapArray()

    ---根据装配类型，重新组织机关刷新的数据
    self:ModifyTrapTransformByAssembleType(refreshParam, trapIDArray)

    local eTraps = {}
    for index, v in ipairs(trapIDArray) do
        local trapPos, eTrap = self:_CreateTrap(v, playerPos)
        if eTrap and eTrap:HasCurseTower() then
            ---@type CurseTowerComponent
            local curseTowerCmpt = eTrap:CurseTower()
            curseTowerCmpt:SetTowerIndex(index)
        end

        if trapPos and eTrap then
            table.insert(eTraps, eTrap)
        end
        --Log.fatal("trapID:",monsterID," pos",monsterPos.x," ",monsterPos.y," area count",#areaArray)
    end
    return eTraps
end

---@param refreshParam LevelMonsterRefreshParam
---@param trapTransformArray TrapTransformParam[]
function LogicEntityService:ModifyTrapTransformByAssembleType(refreshParam, trapTransformArray)
    local assembleType = refreshParam:GetTrapAssembleType()
    if assembleType == TrapAssembleType.Default then
        return
    end

    if assembleType == TrapAssembleType.CurseTower then
        local towerElementList, towerTrapIDList = self:CalcCurseTowerAssembleResult(trapTransformArray)
        for towerIndex, v in ipairs(trapTransformArray) do
            ---@type TrapTransformParam
            local trapParam = v
            ---取出当前塔的颜色，也就是序号
            local elementType = towerElementList[towerIndex]
            local towerTrapID = towerTrapIDList[elementType]
            trapParam:SetTrapID(towerTrapID)
        end
    end
end

function LogicEntityService:CalcCurseTowerAssembleResult(trapTransformArray)
    local towerElementList = {}
    local towerTrapIDList = {}

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()

    local teamOrder = teamEntity:Team():GetTeamOrder()
    local teamCount = #teamOrder
    local teamMemberCount = teamCount - 1

    for towerIndex, v in ipairs(trapTransformArray) do
        local petPstID = -1
        if teamCount == 1 then
            ---如果队伍里，只有队长一个人，就取队长属性
            petPstID = teamOrder[1]
        else
            if towerIndex <= teamMemberCount then
                ---队伍数量大于等于塔的数量
                local teamMemberIndex = towerIndex + 1
                petPstID = teamOrder[teamMemberIndex]
            else
                ---队伍数量小于塔的数量时，取队长的属性
                petPstID = teamOrder[1]
            end
        end

        local elementType = ElementType.ElementType_Blue
        ---@type Entity
        local petEntity = self:GetPetEntityByPstID(petPstID)
        if petEntity ~= nil then
            ---@type ElementComponent
            local elementCmpt = petEntity:Element()
            elementType = elementCmpt:GetPrimaryType()
        end

        towerElementList[#towerElementList + 1] = elementType

        ---@type TrapTransformParam
        local trapParam = v
        towerTrapIDList[#towerTrapIDList + 1] = trapParam:GetTrapID()
    end

    return towerElementList, towerTrapIDList
end

function LogicEntityService:GetPetEntityByPstID(petPstID)
    local petEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.PetPstID)
    for _, e in ipairs(petEntities) do
        ---@type PetPstIDComponent
        local petPstIDCmpt = e:PetPstID()
        if petPstIDCmpt:GetPstID() == petPstID then
            return e
        end
    end

    return nil
end

function LogicEntityService:CreateArchivedTraps(traps)
    local eTraps = {}
    local trapServiceLogic = self._world:GetService("TrapLogic")

    for k, v in ipairs(traps) do
        local eTrap = trapServiceLogic:CreateTrap(v.trapID, v.pos, v.dir, true)
        if eTrap then
            table.insert(eTraps, eTrap)
        end
    end
    return eTraps
end

---创建波内刷新机关
---@return Entity[]
function LogicEntityService:CreateWaveRefreshTraps(levelMonsterWaveParam, inheritAttributes)
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    --存在玩家的时候取玩家的坐标
    local playerPos = teamEntity:GridLocation().Position
    local trapPosTable = {}
    local eTraps = {}
    for _, v in ipairs(levelMonsterWaveParam) do
        local trapPos, eTrap = self:_CreateTrap(v, playerPos, inheritAttributes)
        if trapPos and eTrap then
            table.insert(trapPosTable, trapPos)
            table.insert(eTraps, eTrap)
        end
        --Log.fatal("trapID:",monsterID," pos",monsterPos.x," ",monsterPos.y," area count",#areaArray)
    end
    return trapPosTable, eTraps
end

---根据方位信息创建一个机关
---@param trapTransform TrapTransformParam
---@return Vector2
function LogicEntityService:_CreateTrap(trapTransform, playerPos, inheritAttributes)
    local trapID = trapTransform._trapID
    local posList = trapTransform._trapPositionList
    local rotList = trapTransform._trapRotationList
    local checkBlock = trapTransform._trapCheckBlock

    local playerPosIndex = 0
    for i = 1, #posList do
        if playerPos == posList[i] then
            playerPosIndex = i
            break
        end
    end

    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local randomRes = randomSvc:LogicRand(1, #posList)
    ---如果随机结果是玩家位置 则取下一个位置为实际结果
    if randomRes == playerPosIndex then
        if #posList == 1 then
            Log.fatal("[CreateTrap] all trap born pos occupied by player")
            return
        end
        randomRes = randomRes + 1
        if randomRes > #posList then
            randomRes = 1
        end
    end
    local trapPosition = posList[randomRes]
    local trapRotation
    if rotList then
        if #rotList < randomRes then
            Log.fatal("[CreateTrap] trap refresh confit rotation count less than position")
            trapRotation = Vector2(0, -1)
        else
            trapRotation = rotList[randomRes]
        end
    else
        trapRotation = Vector2(0, -1)
    end
    --Log.fatal("create trap ",trapID," ",trapPosition.x," ",trapPosition.y)

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type TrapConfigData
    local configTrap = cfgService:GetTrapConfigData()
    local configData = configTrap:GetTrapData(trapID)
    local bodyArea = configTrap:ExplainTrapArea(configData.Area)

    if checkBlock then
        ---@type Vector2
        local posSummon = boardServiceLogic:GetValidSummonPos(posList, bodyArea, {}, BlockFlag.SummonTrap, false)
        if not posSummon then
            return
        end
    end

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local trapEntity = trapServiceLogic:CreateTrap(trapID, trapPosition, trapRotation, true, inheritAttributes)
    return trapPosition, trapEntity
end

---创建进入对局的星灵
------@param teamEntity Entity
---@param listMatchPet MatchPet[]
---@return Array
function LogicEntityService:Handle_CreateBattleTeamLogic(teamEntity, listMatchPet)
    local petEntities = {}
    ---@type table<number,number>
    local teamOrder = {}
    local leader = nil
    ---@param matchPet MatchPet
    for petIndex, matchPet in ipairs(listMatchPet) do
        local petPstID = matchPet:GetPstID()
        local petEntity = self:_CreateTeamMemberLogic(matchPet, petPstID, teamEntity)
        self:LogNotice(
            "CreateTeamMember() index=",
            petIndex,
            " petID=",
            matchPet:GetTemplateID(),
            " petPstID=",
            matchPet:GetPstID(),
            " petEntityID=",
            petEntity:GetID(),
            " awake=",
            matchPet:GetPetGrade(),
            " grade=",
            matchPet:GetPetAwakening()
        )
        ---默认第一个就是队长
        if petIndex == 1 then
            leader = petEntity
        end
        table.insert(petEntities, petEntity)
        teamOrder[petIndex] = petPstID
    end
    teamEntity:Team():SetTeamOrder(teamOrder)
    teamEntity:Team():SetTeamPetEntities(petEntities)
    teamEntity:SetTeamLeaderPetEntity(leader)
    return petEntities
end

function LogicEntityService:CreateBattleTeamLogic()
    --读取关卡数据 获得队长出生点
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    local teamPos = levelConfigData:GetPlayerBornPos()
    local teamRotation = levelConfigData:GetPlayerBornRotation()
    --秘境存档位置
    if self._world:MatchType() == MatchType.MT_Maze then
        local battle_archive = self:GetService("Maze"):GetBattleArchive()
        if battle_archive then
            teamPos = battle_archive.team.pos
            teamRotation = battle_archive.team.dir
        end
    end
    local teamEntity
    ---非战棋才需要队长和队员
    if self._world:MatchType() ~= MatchType.MT_Chess then
        ---@type Entity
        teamEntity = self:_CreateTeamLogic(teamPos, teamRotation)
        local localHelpPetPstID = self._world:GetLocalHelpPetPstID()
        if localHelpPetPstID then
            teamEntity:Team():SetHelpPetPstID(localHelpPetPstID)
        end
        self._world:Player():SetLocalTeamEntity(teamEntity)

        --创建队员
        ---@type MatchPet[]
        local listMatchPet = self._world.BW_WorldInfo:GetLocalMatchPetList()
        self:Handle_CreateBattleTeamLogic(teamEntity, listMatchPet)
    end

    ---战棋模式下，没有队员
    if self._world:MatchType() == MatchType.MT_Chess then
        self:_CreateChessPetList()
    end

    --黑拳赛创建敌方队伍
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local teamPos = levelConfigData:GetRemotePlayerBornPos()
        local teamRotation = levelConfigData:GetRemotePlayerBornRotation()
        local teamEntity2 = self:_CreateTeamLogic(teamPos, teamRotation)
        teamEntity2:ReplaceAlignment(AlignmentType.Monster)
        teamEntity2:ReplaceGameTurn(GameTurnType.RemotePlayerTurn)
        local listMatchPet = self._world.BW_WorldInfo:GetRemoteMatchPetList()
        local petEntities = self:Handle_CreateBattleTeamLogic(teamEntity2, listMatchPet)
        ---@param e Entity
        for _, e in ipairs(petEntities) do
            e:ReplaceAlignment(AlignmentType.Monster)
            e:ReplaceGameTurn(GameTurnType.RemotePlayerTurn)
        end
        self._world:Player():SetRemoteTeamEntity(teamEntity2)
        teamEntity2:Team():SetEnemyTeamEntity(teamEntity)
        teamEntity:Team():SetEnemyTeamEntity(teamEntity2)
    end
end

---@param entity Entity
---@param petData MatchPet
function LogicEntityService:_InitPetAttributes(entity, petData, maxCastPower, attackFix, defenseFix, healthFix)
    local maxHP = petData:GetPetHealth()
    local defense = petData:GetPetDefence()
    local attack = petData:GetPetAttack()
    -- if self._world:MatchType() == MatchType.MT_BlackFist then
    --     attack = attack * (1 + attackFix)
    --     defense = defense * (1 + defenseFix)
    --     maxHP = maxHP * (1 + healthFix)
    -- end
    local curHP = maxHP

    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    curHP, maxHP, defense = affixSvc:ChangePetAttr(maxHP, defense)
    local afterDamage = petData:GetAfterDamage()
    local power = petData:GetPetPower()
    local legendPower = petData:GetPetLegendPower()

    if power == -1 then
        power = maxCastPower
    end
    local ready = 0
    if power == 0 then
        ready = 1
    end
    ---装备提供的属性克制系数
    local exElementParam = petData:GetPropertyRestraint()
    ---@type AttributesComponent
    local attributeComponent = entity:Attributes()

    attributeComponent:Modify("Attack", attack)
    attributeComponent:Modify("Defense", defense)
    attributeComponent:Modify("MaxPower", maxCastPower)
    attributeComponent:Modify("Power", power)
    attributeComponent:Modify("LegendPower", legendPower)
    attributeComponent:Modify("Ready", ready)
    attributeComponent:Modify("HP", curHP)
    attributeComponent:Modify("MaxHP", maxHP)
    attributeComponent:Modify("AfterDamage", afterDamage)
    attributeComponent:Modify("ExElementParam", exElementParam)

    --附加技出cd初始化
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraActiveSkill = petData:GetPetExtraActiveSkill()
    if extraActiveSkill and #extraActiveSkill > 0 then
        ---@type ConfigService
        local configService = self._configService
        for index, extraSkillID in ipairs(extraActiveSkill) do
            --附加技能
            ---@type SkillConfigData
            local activeSkillConfigData = configService:GetSkillConfigData(extraSkillID)
            if activeSkillConfigData then
                local skillTriggerType = activeSkillConfigData:GetSkillTriggerType()
                if skillTriggerType == SkillTriggerType.Energy then
                    local skillTriggerParam = activeSkillConfigData:GetSkillTriggerParam()
                    utilData:SetPetMaxPowerAttr(entity,skillTriggerParam,extraSkillID)
                    utilData:SetPetPowerAttr(entity,skillTriggerParam,extraSkillID)
                    local extraReady = 0
                    if skillTriggerParam == 0 then
                        extraReady = 1
                    end
                    utilData:SetPetSkillReadyAttr(entity,extraReady,extraSkillID)
                end
            end
        end
    end

    return curHP, maxHP, defense
end

---@param teamEntity Entity
function LogicEntityService:_ModifyTeamHP(teamEntity, hp, maxhp)
    ---@type AttributesComponent
    local attributeComponent = teamEntity:Attributes()

    local newHeroineHp = attributeComponent:GetCurrentHP() + hp
    attributeComponent:Modify("HP", newHeroineHp)

    local maxTeamHp = attributeComponent:GetAttribute("MaxHP") + maxhp
    attributeComponent:Modify("MaxHP", maxTeamHp)

    return maxTeamHp
end

function LogicEntityService:_ModifyTeamDefense(teamEntity, delta, modType)
    modType = modType or AttrModifyType.Default

    ---@type AttributesComponent
    local attributeComponent = teamEntity:Attributes()

    local newHeroineDefense = attributeComponent:GetAttribute("Defense") + delta
    attributeComponent:Modify("Defense", newHeroineDefense, modType)
    return newHeroineDefense
end
---@return Entity
function LogicEntityService:_CreateTeamLogic(teamPos, teamRotation)
    ---@type Entity
    local teamEntity = self:CreateLogicEntity(EntityConfigIDConst.Team)

    --换队长次数
    ---@type AttributesComponent
    local teamAttrConmpt = teamEntity:Attributes()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local leftCount = configService:GetChangeTeamLeaderCount()
    teamAttrConmpt:Modify("ChangeTeamLeaderCount", leftCount)

    --设置逻辑坐标
    teamEntity:SetGridPosition(teamPos)
    teamEntity:SetGridDirection(teamRotation)

    if self._world:MatchType() == MatchType.MT_PopStar then
        ---消灭星星模式不设置队伍阻挡及脚下格子变灰
        return teamEntity
    end

    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local blockFlag = sBoard:GetBlockFlagByBlockId(BattleConst.BlockFlagCfgIDPet)
    teamEntity:ReplaceBlockFlag(blockFlag)
    sBoard:UpdateEntityBlockFlag(teamEntity, teamEntity:GetGridPosition(), teamEntity:GetGridPosition())

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    boardCmpt:SetPieceElement(teamPos, PieceType.None)

    return teamEntity
end

local passiveCountType = {[2] = true, [3] = true, [4] = true}

---创建队员
---@param petData MatchPet
---@param teamEntity Entity
function LogicEntityService:_CreateTeamMemberLogic(petData, petPstID, teamEntity)
    ---@type Entity
    local petEntity = self:CreateLogicEntity(EntityConfigIDConst.Pet)
    petEntity:ReplaceMatchPet(petData)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    --重置技能信息
    local normalSkillID = petData:GetNormalSkill()
    local chainSkill = affixService:ChangePetSkillChainCount(petData:GetChainSkillInfo())
    local activeSkill = petData:GetPetActiveSkill()
    local extraActiveSkill = petData:GetPetExtraActiveSkill()
    local passiveSkillID = petData:GetPetPassiveSkill()
    local intensifyBuffList = petData:GetPetIntensifyBuffList()
    local equipIntensifyParam = petData:GetEquipIntensifyParams()

    ---装备精炼组件初始化
    self:_InitPetEquipRefine(petData,petEntity)

    local equipRefineChainSkill = petEntity:EquipRefine():GetEquipRefineExtraChainSkillList()
    if equipRefineChainSkill ~= nil then
        for i, v in ipairs(equipRefineChainSkill) do
            if v > 0 then
                local chainSkillData = {Skill = v, Chain = BattleSkillCfg(v).TriggerParam}
                chainSkill[#chainSkill + 1] = chainSkillData
            end
        end
    end

    petEntity:ReplaceSkillInfo(normalSkillID, chainSkill, activeSkill,extraActiveSkill)
    petEntity:SkillInfo():SetPassiveSkillID(passiveSkillID)
    petEntity:SkillInfo():SetIntensifyBuffList(intensifyBuffList)

    local countActiveSkillEnergy = true
    local passiveCountBuffIDArray = {}
    local cfgPassiveSkill = Cfg.cfg_passive_skill[passiveSkillID]
    if cfgPassiveSkill then
        local showMethod = cfgPassiveSkill.ShowMethod
        if showMethod then
            local type = tonumber(showMethod[1])
            if passiveCountType[type] then
                local metaSpecificBuff = showMethod[3]
                if metaSpecificBuff then
                    local arr = string.split(metaSpecificBuff, "|")
                    for _, buffID in ipairs(arr) do
                        table.insert(passiveCountBuffIDArray, tonumber(buffID))
                    end
                else
                    for _, id in ipairs(cfgPassiveSkill.BuffID) do
                        table.insert(passiveCountBuffIDArray, id)
                    end
                end
            end

            if type == 4 then
                countActiveSkillEnergy = false
            end
        end
    end

    local cSkillInfo = petEntity:SkillInfo()
    cSkillInfo:SetPassiveCountBuffIDArray(passiveCountBuffIDArray)
    cSkillInfo:SetCountActiveSkillEnergy(countActiveSkillEnergy)

    ---装备精炼里可以配置对BUFF参数的修改，可能会对原有的装备强化进行替换
    if equipIntensifyParam and type(equipIntensifyParam) == "table" then  
        local cloneEquipIntensifyParam = table.clone(equipIntensifyParam)
        ---@type BuffIntensifyParam[]
        local equipRefineIntensifyParams = petEntity:EquipRefine():GetEquipRefineIntensifyParam()
        if equipRefineIntensifyParams then 
            ---遍历装备强化参数列表
            for equipKey, equipParam in ipairs(cloneEquipIntensifyParam) do
                local curEquipBuffID = equipParam.BuffID
                for _,equipRefineParam in ipairs(equipRefineIntensifyParams) do
                    if curEquipBuffID == equipRefineParam.BuffID then 
                        cloneEquipIntensifyParam[equipKey] = equipRefineParam
                    end
                end 
            end
        end
        petEntity:SkillInfo():SetEquipIntensifyParam(cloneEquipIntensifyParam)
    end
    --时装 修改buff参数 与装备精炼修改已有的装备强化不同，可以新增
    self:_HandlePetSkinChangeBuff(petData,petEntity)

    ---如果装备精炼有额外主动技，就替换原始的
    local equipRefineActiveSkill = petEntity:EquipRefine():GetEquipRefineExtraActiveSkillList()
    if equipRefineActiveSkill ~= nil then 
        petEntity:SkillInfo():SetExtraActiveSkillIDList(equipRefineActiveSkill)
    end
    --装备精炼的变体技能处理
    local equipRefineVariantActiveSkillInfo = petEntity:EquipRefine():GetEquipRefineVariantActiveSkillInfo()
    if equipRefineVariantActiveSkillInfo ~= nil then 
        petEntity:SkillInfo():SetVariantActiveSkillInfo(equipRefineVariantActiveSkillInfo)
    end

    ---@type ConfigService
    local configService = self._configService
    ---@type SkillConfigData
    local activeSkillConfigData = configService:GetSkillConfigData(activeSkill)
    local castPower = activeSkillConfigData:GetSkillTriggerParam()
    local attackFix = 0
    local defenseFix = 0
    local healthFix = 0
    -- if self._world:MatchType() == MatchType.MT_BlackFist then
    --     if teamEntity:Alignment():GetAlignmentType() == AlignmentType.LocalPlayer then
    --         local arr = blackFistConfig:GetTeamAttrFixParam()
    --         attackFix, defenseFix, healthFix = arr[1], arr[2], arr[3]
    --     else
    --         local arr = blackFistConfig:GetEnemyAttrFixParam()
    --         attackFix, defenseFix, healthFix = arr[1], arr[2], arr[3]
    --     end
    -- end
    --设置数值
    local attributeCmpt = petEntity:Attributes()
    local hp, maxhp, defense = self:_InitPetAttributes(petEntity, petData, castPower, attackFix, defenseFix, healthFix)

    ---设置位置
    petEntity:SetGridPosition(teamEntity:GetGridPosition())
    petEntity:SetGridDirection(teamEntity:GetGridDirection())

    ---统计队长血量，如果队长有加血的被动技，需要在这里计算
    local newTeamHp = self:_ModifyTeamHP(teamEntity, hp, maxhp)
    ---更新队长防御力
    local teamDefense = self:_ModifyTeamDefense(teamEntity, defense)

    --设置元素类型
    local firstElement = petData:GetPetFirstElement()
    local secondElement = petData:GetPetSecondElement()
    attributeCmpt:SetSimpleAttribute("Element", firstElement)
    petEntity:ReplaceElement(firstElement, secondElement)

    local bodyAreaArray = {}
    bodyAreaArray[#bodyAreaArray + 1] = Vector2(0, 0)
    petEntity:ReplaceBodyArea(bodyAreaArray)
    petEntity:ReplacePetPstID(petPstID, petData:GetTemplateID(), petData:GetPetCamp(), petData:IsLegendPet())
    petEntity:Pet():SetOwnerTeamEntity(teamEntity)

    local helpPetPstID = teamEntity:Team():GetHelpPetPstID()
    if helpPetPstID and (petPstID == helpPetPstID) then
        Log.info("helpPstID: ", helpPetPstID, " logicEntityID:", petEntity:GetID())
        petEntity:PetPstID():SetHelpPet(true)
    end

    --时装 修改技能参数
    self:_HandlePetSkinChangeSkillParam(petData,petEntity)

    return petEntity
end
function LogicEntityService:_HandlePetSkinChangeBuff(petData, petEntity)
    --时装 修改buff参数 与装备精炼修改已有的装备强化不同，可以新增
    local skinID = petData:GetSkinId()
    local equipIntensifyParam = petData:GetEquipIntensifyParams()
    local skinCfg = Cfg.cfg_pet_skin[skinID]
    if skinCfg then
        ---@type BuffIntensifyParam[]
        local skinIntensifyParam = skinCfg.elementParam
        if skinIntensifyParam then
            local cloneSkinIntensifyParam = table.clone(skinIntensifyParam)
            local curIntensifyParam = equipIntensifyParam
            local equipIntensifyParamInSkillInfo = petEntity:SkillInfo():GetEquipIntensifyParam()
            if equipIntensifyParamInSkillInfo then
                curIntensifyParam = equipIntensifyParamInSkillInfo
            end
            if curIntensifyParam and type(curIntensifyParam) == "table" then  
                local cloneEquipIntensifyParam = table.clone(curIntensifyParam)
                local appendList = {}
                for _, skinParam in ipairs(cloneSkinIntensifyParam) do
                    local skinBuffID = skinParam.BuffID
                    local findInOldParam = false
                    ---遍历装备强化参数列表 有相同的buffID，则添加到buffID下的param中
                    for _, equipParam in ipairs(cloneEquipIntensifyParam) do
                        local curEquipBuffID = equipParam.BuffID
                        if curEquipBuffID == skinBuffID then
                            findInOldParam = true
                            table.appendArray(equipParam,skinParam)
                            break
                        end
                    end
                    --没有相同buffID的，则追加到大列表中
                    if not findInOldParam then
                        table.insert(appendList,skinParam)
                    end
                end
                table.appendArray(cloneEquipIntensifyParam,appendList)
                petEntity:SkillInfo():SetEquipIntensifyParam(cloneEquipIntensifyParam)
            end
        end
    end
end
function LogicEntityService:_HandlePetSkinChangeSkillParam(petData, petEntity)
    local skinChangeSkillParamConstID = 555--代替buff seqId，实际用不到，不要与buffSeqID重复就可以
    local skinID = petData:GetSkinId()
    ---@type ConfigDecorationService
    local cfgdecorsvc = self._world:GetService("ConfigDecoration")
    local skinCfg = Cfg.cfg_pet_skin[skinID]
    if skinCfg then
        local skinChangeSkillParam = skinCfg.ChangeSkillParam
        if skinChangeSkillParam and type(skinChangeSkillParam) == "table" then  
            local cloneSkinChangeSkillParam = table.clone(skinChangeSkillParam)
            for index, changeSkillParam in ipairs(cloneSkinChangeSkillParam) do
                local skillIDList = nil
                if type(changeSkillParam.skillID) == "number" then
                    skillIDList = {changeSkillParam.skillID}
                else
                    skillIDList = changeSkillParam.skillID
                end
                local effectIndex = changeSkillParam.effectIndex
                local appendTb = changeSkillParam.append or {}
                local setTb = changeSkillParam.set or {}
                local removeTb = changeSkillParam.remove or {}
                local appendArray = changeSkillParam.appendArray or {}
                for _, skillID in ipairs(skillIDList) do
                    cfgdecorsvc:DecorateSkillEffect(
                        skinChangeSkillParamConstID,
                        petEntity,
                        skillID,
                        effectIndex,
                        appendTb,
                        setTb,
                        removeTb,
                        appendArray
                    )
                end
            end
        end
    end
end
---@param petData MatchPet
---@param petEntity Entity
function LogicEntityService:_InitPetEquipRefine(petData,petEntity)
    local equipRefineExtraActiveSkill = petData:GetEquipRefineExtraActiveSkill()
    local equipIntensifyRefineParam = petData:GetEquipRefineIntensifyParams()

    local extraChainSkillListData = petData:GetPetExtraChainSkillList()
    if extraChainSkillListData then
        local chainSkillList = table.clone(extraChainSkillListData)
        petEntity:EquipRefine():SetEquipRefineExtraChainSkillList(chainSkillList)
    end

    local equipRefineBuffListData = petData:GetEquipRefineBuffListData()
    if equipRefineBuffListData then 
        local equipRefineBuffList = table.clone(equipRefineBuffListData)
        petEntity:EquipRefine():SetEquipRefineBuffList(equipRefineBuffList)
    end

    local equipRefineFeatureData = petData:GetEquipRefineFeatureList()
    if equipRefineFeatureData then 
        local equipRefineFeatureList = table.clone(equipRefineFeatureData)
        petEntity:EquipRefine():SetEquipRefineFeatureList(equipRefineFeatureList)
    end

    petEntity:EquipRefine():SetEquipRefineIntensifyParam(equipIntensifyRefineParam)
    petEntity:EquipRefine():SetEquipRefineExtraActiveSkillList(equipRefineExtraActiveSkill)

    local equipRefineVariantActiveSkillData = petData:GetEquipRefineVariantActiveSkillInfo()
    if equipRefineVariantActiveSkillData then 
        local equipRefineVariantActiveSkillInfo = table.clone(equipRefineVariantActiveSkillData)
        petEntity:EquipRefine():SetEquipRefineVariantActiveSkillInfo(equipRefineVariantActiveSkillInfo)
    end
end

function LogicEntityService:_CreateTeamMemberShadow(petEntity)
    ---创建一个shadow
    ---@type Entity
    local shadowEntity = self:CreateLogicEntity(EntityConfigIDConst.PetShadow)

    local enemyPos = petEntity:GridLocation().Position
    local enemyDir = petEntity:GridLocation().Direction
    local enemyOffset = petEntity:GridLocation().Offset

    local ghostPos = Vector2(enemyPos.x, enemyPos.y)
    local ghostDir = Vector2(enemyDir.x, enemyDir.y)
    local ghostOffset = Vector2(enemyOffset.x, enemyOffset.y)
    shadowEntity:SetGridLocationAndOffset(ghostPos, ghostDir, ghostOffset)
    shadowEntity:ReplaceAlignment(petEntity:Alignment():GetAlignmentType())
    return shadowEntity
end

function LogicEntityService:_CreateChessPetList()
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    local chessPetRefreshIDs = levelConfigData:GetChessPetRefreshID()

    local monsterRefreshParamArray = {}

    for _, chessPetRefreshID in ipairs(chessPetRefreshIDs) do
        local chessPetRefreshConfig = Cfg.cfg_refresh_chesspet[chessPetRefreshID]
        if not chessPetRefreshConfig then
            Log.fatal("Cfg ChessPetRefreshID Not Find ID:", chessPetRefreshID)
        end

        ---本次波次内刷新的怪物数据
        local levelMonsterRefreshParam = LevelMonsterRefreshParam:New(self._world)
        levelMonsterRefreshParam:ParseChessPetRefreshParam(chessPetRefreshConfig)

        table.insert(monsterRefreshParamArray, levelMonsterRefreshParam)
    end

    ---@type ChessPetCreationServiceLogic
    local chessPetCreationSvc = self._world:GetService("ChessPetCreationLogic")
    local chessPets = chessPetCreationSvc:CreateInternalRefreshMonsterLogic(monsterRefreshParamArray)

    return chessPets
end

---创建指定波次的怪物entity
function LogicEntityService:CreateWaveMonstersMultiBoard(waveNum)
    local eMonsters = {}
    local playerPos = nil

    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()

    ---@type CreateMonsterPosService
    local createMonsterPosService = self._world:GetService("CreateMonsterPos")
    ---@type MonsterCreationServiceLogic
    local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")

    local multiBoard = levelConfigData:GetMultiBoard()

    for i, boardInfo in ipairs(multiBoard) do
        local boardIndex = boardInfo.index

        ---@type LevelMonsterRefreshParam
        local monsterRefreshParam =
            levelConfigData:GetLevelWaveBeginRefreshMonsterParamMultiBoard(boardIndex, waveNum, playerPos)

        if monsterRefreshParam then
            ---@type MonsterRefreshPosType
            local monsterRefreshPosType = monsterRefreshParam:GetMonsterRefreshPosType()

            ---@type MonsterTransformParam
            local monsterArray =
                createMonsterPosService:GetMonsterRefreshPos(monsterRefreshPosType, monsterRefreshParam)
            if monsterArray then
                for _, v in ipairs(monsterArray) do
                    local eMonster, monsterId = monsterCreationSvc:CreateMonster(v)

                    eMonster:AddOutsideRegion(boardIndex)

                    table.insert(eMonsters, eMonster)
                    self._world:GetSyncLogger():Trace(
                        {
                            key = "CreateWaveMonstersMultiBoard",
                            waveNum = waveNum,
                            monsterID = monsterId,
                            entityID = eMonster:GetID(),
                            pos = tostring(v:GetPosition())
                        }
                    )
                end
            end
        end
    end

    return eMonsters
end

---创建波次机关
function LogicEntityService:CreateWaveTrapsMultiBoard(waveNum)
    --存在玩家的时候取玩家的坐标
    local playerPos = nil
    local eTraps = {}

    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()

    local multiBoard = levelConfigData:GetMultiBoard()

    for i, boardInfo in ipairs(multiBoard) do
        local boardIndex = boardInfo.index

        ---@type LevelMonsterRefreshParam
        local refreshParam =
            levelConfigData:GetLevelWaveBeginRefreshMonsterParamMultiBoard(boardIndex, waveNum, playerPos)
        local trapIDArray = refreshParam:GetTrapArray()

        ---根据装配类型，重新组织机关刷新的数据
        self:ModifyTrapTransformByAssembleType(refreshParam, trapIDArray)

        for index, v in ipairs(trapIDArray) do
            local trapPos, eTrap = self:_CreateTrap(v, playerPos)
            if eTrap then
                eTrap:AddOutsideRegion(boardIndex)
            end

            if trapPos and eTrap then
                table.insert(eTraps, eTrap)
            end
        end
    end

    return eTraps
end

