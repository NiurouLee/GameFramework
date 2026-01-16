--[[
    用来发送逻辑数据给表现层
]]
_class("L2RService", BaseService)
---@class L2RService:BaseService
L2RService = L2RService

function L2RService:Constructor(world)
    ---@type MainWorld
    self._world = world
end

--棋盘数据更新
function L2RService:L2RBoardLogicData()
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end

    ---@type DataBoardLogicResult
    local data = DataBoardLogicResult:New()
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local prismPieces = boardCmpt:ClonePrismPieces()
    data:SetPrismPieces(prismPieces)
    local prismEntityIDs = boardCmpt:ClonePrismEntityIDs()
    data:SetPrismEntityIDs(prismEntityIDs)
    local pieceTable = boardCmpt:ClonePieceTable()
    data:SetPieceTable(pieceTable)
    local pieceTypes = self:_CalcBoardPosPieceType(pieceTable)
    data:SetPieceTypes(pieceTypes)
    local blockFlags = self:_CalcBoardBlockFlags()
    data:SetBlockFlags(blockFlags)
    local immuneHitbackEIDs = self:_CalcImmuneHitbackEntities()
    data:SetImmuneHitbacks(immuneHitbackEIDs)
    local pieceEntities = boardCmpt:ClonePieceEntities()
    data:SetPieceEntities(pieceEntities)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

--颜色同步
function L2RService:L2RSyncPieceType()
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local data = DataPieceTypeResult:New()
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local pieceTable = boardCmpt:ClonePieceTable()
    data:SetPieceTable(pieceTable)
    local pieceTypes = self:_CalcBoardPosPieceType(pieceTable)
    data:SetPieceTypes(pieceTypes)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

function L2RService:_CalcBoardPosPieceType(pieceTable)
    local posColor = {}
    for x, row in pairs(pieceTable) do
        for y, color in pairs(row) do
            local posIdx = x * 100 + y
            posColor[posIdx] = color
        end
    end
    return posColor
end

function L2RService:_CalcBoardBlockFlags()
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local arr = board:GetBlockFlagArray()
    local posBlockData = {}
    for x, row in pairs(arr) do
        for y, data in pairs(row) do
            local posIdx = x * 100 + y
            posBlockData[posIdx] = table_to_class(data)
        end
    end
    return posBlockData
end

function L2RService:_CalcImmuneHitbackEntities()
    ---@type BuffLogicService
    local BuffLogicSvc = self._world:GetService("BuffLogic")
    local es = {}
    local group = self._world:GetGroup(self._world.BW_WEMatchers.AI)
    for i, e in ipairs(group:GetEntities()) do
        if not BuffLogicSvc:CheckCanBeHitBack(e) then
            es[#es + 1] = e:GetID()
        end
    end
    return es
end

function L2RService:L2RLoadingData()
    ---@type L2R_LoadingResult
    local res = L2R_LoadingResult:New()

    if self._world:MatchType() == MatchType.MT_Chess then
        local creationResult = self:_GetChessPetCreationResult()
        res:SetChessPetCreationResult(creationResult)
    end

    if self._world:MatchType() ~= MatchType.MT_Chess then
        local teamRes = self:_GetTeamCreationResult()
        res:SetTeamCreationResult(teamRes)
    end

    ---@type MonsterCreationServiceLogic
    local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")
    local monsterResList = monsterCreationSvc:GenerateMonsterCreationResult()
    res:SetLoadMonsterResultList(monsterResList)

    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.Loading, res)
end

function L2RService:_GetTeamCreationResult()
    local teamRes = {}
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    teamRes[1] = self:_CalcTeamCreationResult(teamEntity)

    local petResList = self:_CalcPetCreationResultList(teamEntity)
    teamRes[1]:SetPetCreationResultList(petResList)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local remoteTeamEntity = self._world:Player():GetRemoteTeamEntity()
        teamRes[2] = self:_CalcTeamCreationResult(remoteTeamEntity)
        local petResList = self:_CalcPetCreationResultList(remoteTeamEntity)
        teamRes[2]:SetPetCreationResultList(petResList)
    end
    return teamRes
end

---@param teamEntity Entity
function L2RService:_CalcPetCreationResultList(teamEntity)
    local creationResList = {}
    local petEntityList = teamEntity:Team():GetTeamPetEntities()
    ---@param petEntity Entity
    for petIndex, petEntity in ipairs(petEntityList) do
        ---@type PetCreationResult
        local petRes = DataPetCreationResult:New()
        local matchPet = petEntity:MatchPet():GetMatchPet()

        local eid = petEntity:GetID()
        petRes:SetPetCreationLogicEntityID(eid)

        local tplID = matchPet:GetTemplateID()
        petRes:SetPetCreationTemplateID(tplID)

        local pstID = matchPet:GetPstID()
        petRes:SetPetCreationPstID(pstID)

        local firstElement = matchPet:GetPetFirstElement()
        local secondElement = matchPet:GetPetSecondElement()
        petRes:SetPetCreationElementType(firstElement, secondElement)

        local petPrefab = matchPet:GetPetPrefab(PetSkinEffectPath.MODEL_INGAME)
        petRes:SetPetCreationRes(petPrefab)

        ---@type GridLocationComponent
        local gridLocCmpt = petEntity:GridLocation()
        local gridPos = gridLocCmpt:GetGridPos()
        petRes:SetPetCreationGridPos(gridPos)

        ---@type AttributesComponent
        local attrCmpt = petEntity:Attributes()
        local hp = attrCmpt:GetCurrentHP()
        local maxHP = attrCmpt:CalcMaxHp()

        petRes:SetPetCreation_CurHp(hp)
        petRes:SetPetCreation_MaxHp(maxHP)

        creationResList[#creationResList + 1] = petRes
    end

    return creationResList
end

---@param teamEntity Entity
function L2RService:_CalcTeamCreationResult(teamEntity)
    ---@type TeamCreationResult
    local teamRes = DataTeamCreationResult:New()
    teamRes:SetCreationResultTeamEntityID(teamEntity:GetID())

    ---出生位置
    local heroPos = teamEntity:GetGridPosition()
    local heroRotation = teamEntity:GridLocation():GetGridDir()
    teamRes:SetCreationResultBornPos(heroPos)
    teamRes:SetCreationResultBornRotation(heroRotation)

    ---元素类型
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local firstElement = utilDataSvc:GetEntityElementPrimaryType(teamEntity)
    teamRes:SetCreationResultElement(firstElement)

    ---血条的偏移
    ---@type Entity
    local leader = teamEntity:Team():GetTeamLeaderEntity()
    local petData = leader:MatchPet():GetMatchPet()
    --血条高度
    local hpOffset = petData:GetHPOffset()
    teamRes:SetCreationResultHPOffset(hpOffset)

    ---@type AttributesComponent
    local attributesComponent = teamEntity:Attributes()
    local hp = attributesComponent:GetCurrentHP()
    local maxHP = attributesComponent:CalcMaxHp()
    teamRes:SetCreationResultHP(hp)
    teamRes:SetCreationResultMaxHP(maxHP)

    teamRes:SetCreationResultFirstPetEntityID(leader:GetID())

    return teamRes
end

---@param normalSkillCalcor NormalSkillCalculator
function L2RService:L2RNormalAttackData(normalSkillCalcor, teamEntity)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end

    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    local isFinalAtk = battleSvc:IsPlayerTurnFinalAttack()

    local playNormalSkillSequence = normalSkillCalcor:GetPlayNormalSkillSequence()
    local pathTriggerTrapsDic = normalSkillCalcor:GetTriggerTraps()
    local pathNormalSkillWaitTimeDic = normalSkillCalcor:GetPathNormalSkillWaitTimes()
    local pathMoveStartWaitTime = normalSkillCalcor:GetPathMoveStartWaitTime()
    local normalAtkData = self:_CloneNormalAtkData(teamEntity)

    local res = L2R_NormalAttackResult:New()
    res:SetPlayNormalSkillSequence(playNormalSkillSequence)
    res:SetChainPathTriggerTrap(pathTriggerTrapsDic)
    res:SetNormalSkillWaitTimeDic(pathNormalSkillWaitTimeDic)
    res:SetPathMoveStartWaitTime(pathMoveStartWaitTime)
    res:SetPetNormalAttackResultList(normalAtkData)
    res:SetPlayNormalAttackFinalAttack(isFinalAtk)

    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.NormalAttack, res)
end

function L2RService:_CloneNormalAtkData(teamEntity)
    local normalAttackDataList = {}
    local petRoundTeam = teamEntity:LogicRoundTeam():GetPetRoundTeam()
    for petIndex = 1, #petRoundTeam do
        local petEntityID = petRoundTeam[petIndex]
        ---@type Entity
        local petEntity = self._world:GetEntityByID(petEntityID)
        ---@type SkillPetAttackDataComponent
        local petAttackCmpt = petEntity:SkillPetAttackData()
        ---@type SkillPathNormalAttackData
        local normalAtkData = petAttackCmpt:GetNormalAttackData()

        ---复制一份
        local newData = table_to_class(normalAtkData)
        normalAttackDataList[petEntityID] = newData
    end
    return normalAttackDataList
end

function L2RService:L2RChainAttackData(teamEntity)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end

    local resultList = {}

    ---@type LogicRoundTeamComponent
    local logicTeamCmpt = teamEntity:LogicRoundTeam()
    local petRoundTeam = logicTeamCmpt:GetPetRoundTeam()
    local roundTeam = {}
    for _, v in ipairs(petRoundTeam) do
        roundTeam[#roundTeam + 1] = v
    end

    ---统计Result
    for petIndex = 1, #petRoundTeam do
        local petEntityID = petRoundTeam[petIndex]
        ---@type Entity
        local petEntity = self._world:GetEntityByID(petEntityID)
        ---@type SkillPetAttackDataComponent
        local petAtkDataCmpt = petEntity:SkillPetAttackData()

        ---@type DataChainAttackResult
        local chainResData = DataChainAttackResult:New()
        resultList[petEntityID] = chainResData

        local atkData = petAtkDataCmpt:GetChainAttackDataList()
        local newAtkData = table_to_class(atkData)
        chainResData:SetChainAttackResultAtkDataList(newAtkData)
        local shadowAtkData = petAtkDataCmpt:GetShadowChainAttackDataList()
        local newShadowAtkData = table_to_class(shadowAtkData)
        chainResData:SetChainAttackResultShadowAtkDataList(newShadowAtkData)
        local agentAtkData = petAtkDataCmpt:GetAgentChainAttackDataList()
        local newAgentAtkData = table_to_class(agentAtkData)
        chainResData:SetChainAttackResultAgentAtkDataList(newAgentAtkData)
        local deadEntityIds = self:_CalcDeadEntityIDListByPet(petEntityID, #atkData)
        local deadEntityIdsShadow = self:_CalcDeadEntityIDListByPet(petEntityID, #shadowAtkData)
        local deadEntityIdsAgent = self:_CalcDeadEntityIDListByPet(petEntityID, #agentAtkData)
        table.appendArray(deadEntityIds, deadEntityIdsShadow)
        table.appendArray(deadEntityIds, deadEntityIdsAgent)
        chainResData:SetDeadEntityIDList(deadEntityIds)
        chainResData:SetChainAttackResultCastSkillFlag(petAtkDataCmpt:GetCastChainSkill())
        chainResData:SetChainAttackResultSkillID(petAtkDataCmpt:GetChainSkillID())
    end
    local res = L2R_ChainAttackResult:New(resultList)
    res:SetChainTeamResult(roundTeam)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.ChainAttack, res)
end

function L2RService:_CalcDeadEntityIDListByPet(petEntityID, chainCount)
    local res = {}
    for chainIdx = 1, chainCount do
        local list = {}
        local deadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)
        for _, e in ipairs(deadGroup:GetEntities()) do
            ---@type DeadMarkComponent
            local deadMarkCmpt = e:DeadMark()
            local chainIndex = deadMarkCmpt:GetChainAttackIndex()
            if petEntityID == nil then
                table.insert(list, e:GetID())
            else
                if deadMarkCmpt:GetDeadCasterID() == petEntityID and chainIdx == chainIndex then
                    table.insert(list, e:GetID())
                end
            end
        end
        res[#res + 1] = list
    end
    return res
end

--主动技计算结果
function L2RService:L2RActiveAttackData(casterEntity,activeSkillID)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end

    local eid = casterEntity:GetID()
    local res = casterEntity:SkillContext():GetResultContainer()

    ---@type L2RActiveAttackResult
    local data = L2RActiveAttackResult:New(eid, res)
    data:SetL2RActiveAttackResult_SkillID(activeSkillID)

    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.ActiveAttack, data)
end
--模块技计算结果
function L2RService:L2RFeatureAttackData(casterEntity,featureSkillID)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end

    local eid = casterEntity:GetID()
    local res = casterEntity:SkillContext():GetResultContainer()
    local data = L2RFeatureAttackResult:New(eid, res)
    data:SetL2RFeatureAttackResult_SkillID(featureSkillID)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.FeatureAttack, data)
end

--AI计算结果
function L2RService:L2RAILogicData()
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local recordCmpt = self._world:GetBoardEntity():AIRecorder()
    local res = DataAILogicResult:New(recordCmpt)
    self._world:GetBoardEntity():ReplaceAIRecorder()
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
end

function L2RService:L2ROneSkillData(casterEntity, key)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local skillResult = casterEntity:SkillContext():GetResultContainer()
    local data = DataSkillRoutineResult:New(casterEntity:GetID(), skillResult, key)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
    --casterEntity:ReplaceSkillContext()
end

--划线数据
function L2RService:L2RChainPathData(teamEntity)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local logicPath = logicChainPathCmpt:GetLogicChainPath()

    local logicElementType = logicChainPathCmpt:GetLogicPieceType()

    local pathRes = {}
    for _, v in ipairs(logicPath) do
        local point = Vector2(v.x, v.y)
        pathRes[#pathRes + 1] = point
    end

    ---@type LogicRoundTeamComponent
    local logicTeamCmpt = teamEntity:LogicRoundTeam()
    local petList = logicTeamCmpt:GetPetRoundTeam()

    local roundTeam = {}
    for _, v in ipairs(petList) do
        roundTeam[#roundTeam + 1] = v
    end

    local cutChainPath = logicChainPathCmpt:GetCutChainPath()
    local cutChainPathRes = {}
    for index, v in pairs(cutChainPath) do --不能改ipairs
        local point = Vector2(v.x, v.y)
        cutChainPathRes[index] = point
    end

    local pathChainRate = table_to_class(logicChainPathCmpt._pathChainRate)

    ---@type DataChainPathResult
    local res = DataChainPathResult:New()
    res:SetChainPathResult(pathRes)
    res:SetChainElementResult(logicElementType)
    res:SetChainTeamResult(roundTeam)
    res:SetCutChainPathResult(cutChainPathRes)
    res:SetPathChainRate(pathChainRate)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
end

---获取棋子光灵的逻辑创建结果
function L2RService:_GetChessPetCreationResult()
    ---@type ChessPetCreationServiceLogic
    local chessPetCreationSvc = self._world:GetService("ChessPetCreationLogic")
    local chessPetResList = chessPetCreationSvc:GenerateChessPetCreationResult()
    return chessPetResList
end

--划线数据
function L2RService:L2RChessPathData()
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type LogicChessPathComponent
    -- local logicChessPathComponent = chessEntity:LogicChessPath()
    local logicChessPathComponent = boardEntity:LogicChessPath()
    local chessPath = logicChessPathComponent:GetLogicChessPath()
    local chessPetEntityID = logicChessPathComponent:GetLogicChessPetEntityID()
    local walkResultList = logicChessPathComponent:GetLogicWalkResultList()
    local pickUpPos = logicChessPathComponent:GetLogicPickUpPos()

    local pathRes = {}
    for _, v in ipairs(chessPath) do
        local point = Vector2(v.x, v.y)
        pathRes[#pathRes + 1] = point
    end

    ---@type DataChessPathResult
    local res = DataChessPathResult:New()
    res:SetChessPathResult(pathRes)
    res:SetChessPetEntityID(chessPetEntityID)
    res:SetChessWalkResultList(walkResultList)
    res:SetChessPickUpPos(pickUpPos)

    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
end

--棋子攻击数据
function L2RService:L2RChessAttackData(casterEntity,activeSkillID)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local eid = casterEntity:GetID()
    local res = casterEntity:SkillContext():GetResultContainer()
    local data = L2RActiveAttackResult:New(eid, res)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.ActiveAttack, data)
end
---San值 每回合降低
function L2RService:L2RSanRoundDecrease(curVal,oldVal,modifyValue,debtVal,modifyTimes)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local data = DataSanRoundDecreaseResult:New(curVal,oldVal,modifyValue,debtVal,modifyTimes)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end
---昼夜 回合数变化
function L2RService:L2RDayNightRoundChange(curState,oldState,restRound)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local data = DataDayNightRoundChangeResult:New(curState,oldState,restRound)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end
---通知 同步移动数据
function L2RService:L2RSyncMoveData(entityID,syncMovePath)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local data = DataSyncMovePathResult:New(entityID,syncMovePath)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

---同步 小秘境创建伙伴
-- function L2RService:L2RAddPartnerData(partnerID,petInfo,matchPet,petRes,hp,maxHP)
--     ---服务端不需要逻辑到表现的数据传递
--     if self._world:RunAtServer() then 
--         return 
--     end
--     local data = DataAddPartnerResult:New(partnerID,petInfo,matchPet,petRes,hp,maxHP)
--     Log.debug("[MiniMaze] L2RAddPartnerData ")

--     self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
-- end

-- function L2RService:L2RAddRelicData(relicID, buffSeqs, switchState)
--     ---服务端不需要逻辑到表现的数据传递
--     if self._world:RunAtServer() then
--         return
--     end
--     Log.debug("[MiniMaze] L2RAddRelicData")
--     local data = DataAddRelicResult:New(relicID, buffSeqs, switchState)
--     self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
-- end

function L2RService:L2RNTSelectRoundTeamNormalBefore(elementType, chainPath)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then
        return
    end

    self._world:EventDispatcher():Dispatch(GameEventType.DataRenderNTSelectRoundTeamNormalBefore, elementType, chainPath)
end

function L2RService:L2RMirageWalkData(mirageWalkRes)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then
        return
    end

    local res = L2RMirageMoveResult:New(mirageWalkRes)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.MirageMove, res)
end

function L2RService:L2RMirageWarningData(warningPosList)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then
        return
    end

    local res = L2RMirageWarningResult:New(warningPosList)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, LogicStepType.MirageWarning, res)
end
function L2RService:L2RPickUpComponentData(entityID,pickUpGridList,directionPickupData,reflectDir,pickUpExtraParam)
    ---服务端不需要逻辑到表现的数据传递
    if self._world:RunAtServer() then 
        return 
    end
    local data = DataPickUpComponentResult:New(entityID,pickUpGridList,directionPickupData,reflectDir,pickUpExtraParam)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end