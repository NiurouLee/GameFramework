--[[------------------------------------------------------------------------------------------
    ChessPetCreationServiceLogic 创建棋子光灵的逻辑Service
]] --------------------------------------------------------------------------------------------

_class("ChessPetCreationServiceLogic", BaseService)
---@class ChessPetCreationServiceLogic:BaseService
ChessPetCreationServiceLogic = ChessPetCreationServiceLogic

---根据传入的Entity列表生成表现层需要的
function ChessPetCreationServiceLogic:GenerateChessPetCreationResult()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    local chessPetList = group:GetEntities()

    local creationResultList = {}
    for _, v in ipairs(chessPetList) do
        local res = self:GenerateOneChessPetResult(v)
        creationResultList[#creationResultList + 1] = res
    end

    return creationResultList
end

---@param chessPetEntity Entity
function ChessPetCreationServiceLogic:GenerateOneChessPetResult(chessPetEntity)
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgSvc:GetChessPetConfigData()

    ---@type DataChessPetCreationResult
    local res = DataChessPetCreationResult:New()

    -- ---@type UtilDataServiceShare
    -- local utilDataSvc = self._world:GetService("UtilData")
    -- local appearSkillId = utilDataSvc:GetAppearSkillId(chessPetEntity)
    -- res:SetMonsterAppearSkillID(appearSkillId)

    local eid = chessPetEntity:GetID()
    res:SetChessPetEntityID(eid)

    ---@type ElementComponent
    local elementCmpt = chessPetEntity:Element()
    local elementType = elementCmpt:GetPrimaryType()
    res:SetChessPetElement(elementType)

    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local chessPetTemplateID = chessPetCmpt:GetChessPetClassID()
    local chessPetID = chessPetCmpt:GetChessPetID()
    res:SetChessPetTemplateID(chessPetTemplateID)

    local chessPetResPath = chessPetConfigData:GetChessPetResPath(chessPetID)
    res:SetChessPetResPath(chessPetResPath)

    local hpOffset = chessPetConfigData:GetChessPetHPHeightOffset(chessPetID)
    res:SetChessPetHPOffset(hpOffset)

    ---@type AttributesComponent
    local attrCmpt = chessPetEntity:Attributes()
    local maxhp = attrCmpt:CalcMaxHp()
    res:SetChessPetMaxHP(maxhp)
    local curHp = attrCmpt:GetCurrentHP()
    res:SetChessPetHP(curHp)

    ---@type GridLocationResult
    local gridLocRes = self:GetChessPetCreationGridLocResult(chessPetEntity)
    res:SetChessPetGridLocResult(gridLocRes)

    return res
end

---@param monsterEntity Entity
function ChessPetCreationServiceLogic:GetChessPetCreationGridLocResult(chessPetEntity)
    ---@type GridLocationComponent
    local gridLocCmpt = chessPetEntity:GridLocation()
    ---@type DataGridLocationResult
    local gridLocRes = DataGridLocationResult:New()
    gridLocRes:SetGridLocResultBornPos(gridLocCmpt:GetGridPos())
    gridLocRes:SetGridLocResultBornDir(gridLocCmpt:GetGridDir())
    gridLocRes:SetGridLocResultBornHeight(gridLocCmpt:GetGridLocHeight())
    gridLocRes:SetGridLocResultBornOffset(gridLocCmpt:GetGridOffset())
    gridLocRes:SetGridLocResultDamageOffset(gridLocCmpt:GetDamageOffset())

    return gridLocRes
end

---获取怪物创建时的基础属性攻防血
function ChessPetCreationServiceLogic:GetCreateADH(monsterID)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    local attack = monsterConfigData:GetMonsterAttack(monsterID)
    local defense = monsterConfigData:GetMonsterDefense(monsterID)
    local hp = monsterConfigData:GetMonsterHealth(monsterID)
    return attack, defense, hp
end

---根据方位信息创建一只怪物
---@param monsterTransform MonsterTransformParam
---@return Entity,number,boolean
function ChessPetCreationServiceLogic:CreateMonster(monsterTransform)
    return self:__createMonster(monsterTransform, nil)
end

---根据方位信息创建一只怪物并初始化 攻、防、血
---@param monsterTransform MonsterTransformParam
---@param attack number
---@param defense number
---@param hp number
---@return Entity,number,boolean
function ChessPetCreationServiceLogic:CreateMonsterWithInitADH(
    monsterTransform,
    attack,
    defense,
    maxhp,
    curhp,
    airt,
    bindeff,
    buffrt)
    attack = attack ~= nil and math.floor(attack) or nil
    defense = defense ~= nil and math.floor(defense) or nil
    maxhp = maxhp ~= nil and math.floor(maxhp) or nil
    curhp = curhp ~= nil and math.floor(curhp) or nil

    return self:__createMonster(
        monsterTransform,
        {
            attack = attack,
            defense = defense,
            maxhp = maxhp,
            curhp = curhp,
            airt = airt,
            bindeff = bindeff,
            buffrt = buffrt
        }
    )
end

---私有函数禁止外部直接调用 请使用 CreateMonster 或 CreateMonsterWithInitADH
---@return Entity,number,boolean
function ChessPetCreationServiceLogic:__createMonster(monsterTransform, _InitMonsterAttributes)
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgSvc:GetChessPetConfigData()

    local chessPetID = monsterTransform:GetMonsterID()
    local chessPetPosition = monsterTransform:GetPosition()
    local dir = monsterTransform:GetForward()
    -- local areaArray = monsterTransform:GetBodyArea()
    -- local positionOffset = monsterTransform:GetOffset()

    local chessPetConfig = Cfg.cfg_chesspet[chessPetID]
    if not chessPetConfig then
        Log.fatal("Cfg chessPetConfig Not Find ID:", chessPetID)
        return
    end

    local chessPetClassID = chessPetConfigData:GetChessPetClassID(chessPetID)
    local areaArray = chessPetConfigData:GetChessPetArea(chessPetID)
    local positionOffset = chessPetConfigData:GetChessPetOffset(chessPetID)
    local damageOffset = chessPetConfigData:GetChessPetDamageOffset(chessPetID)
    local block = chessPetConfigData:Block(chessPetID)
    local chessPetRaceType = chessPetConfigData:GetChessPetRaceType(chessPetID)
    local chessPetSkillIDs = chessPetConfigData:GetSkillIDs(chessPetID)

    --
    local attack = chessPetConfigData:GetChessPetAttack(chessPetID)
    local defense = chessPetConfigData:GetChessPetDefense(chessPetID)
    local maxhp = chessPetConfigData:GetChessPetHealth(chessPetID)
    local curhp = maxhp
    local elementType = chessPetConfigData:GetChessPetElementType(chessPetID)

    ---@type LogicEntityService
    local sEntity = self._world:GetService("LogicEntity")
    ---@type Entity
    local chessPetEntity = sEntity:CreateLogicEntity(EntityConfigIDConst.ChessPet)

    chessPetEntity:ReplaceChessPet(chessPetID, chessPetClassID, chessPetRaceType)
    ---@type ChessPetComponent
    local chessPetComponent = chessPetEntity:ChessPet()
    chessPetComponent:SetSkillID(chessPetSkillIDs)

    chessPetEntity:ReplaceBodyArea(areaArray) --重置格子占位
    chessPetEntity:SetGridLocationAndOffset(chessPetPosition, dir, positionOffset, damageOffset) --位置信息

    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local blockFlag = boardService:GetBlockFlagByBlockId(block)
    chessPetEntity:ReplaceBlockFlag(blockFlag)
    boardService:UpdateEntityBlockFlag(chessPetEntity, chessPetPosition, chessPetPosition)

    ---攻防血还得被词条处理一次
    -- attack = affixService:ChangeMonsterAttr(monsterID, attack, AffixAttrType.Attack)
    -- defense = affixService:ChangeMonsterAttr(monsterID, defense, AffixAttrType.Defence)
    -- maxhp = affixService:ChangeMonsterAttr(monsterID, maxhp, AffixAttrType.HP)
    ---只有最大血量小于当前血量 再刷否则存档会有bug
    if curhp > maxhp then
        curhp = maxhp
    end

    --重置数值
    local attributeCmpt = chessPetEntity:Attributes()
    attributeCmpt:Modify("Attack", attack)
    attributeCmpt:Modify("HP", curhp)
    attributeCmpt:Modify("MaxHP", maxhp)

    --设置元素类型
    chessPetEntity:ReplaceElement(elementType, nil)
    attributeCmpt:SetSimpleAttribute("Element", elementType)

    -- self._world:GetService("Trigger"):Notify(NTMonsterShow:New(monster_entity))

    ---这种非对象化传递context的做法很不好，计划N9版本改成确定的对象化
    local monsterBornBuffContext = {isMonsterBornBuff = true}
    --怪物初始化时需要挂的buff，只给自己挂
    local buffList = chessPetConfigData:GetBornBuffList(chessPetID)
    if buffList and #buffList > 0 then
        ---@type BuffLogicService
        local buffLogic = self._world:GetService("BuffLogic")
        if not chessPetEntity:HasBuff() then
            chessPetEntity:AddBuffComponent()
        end
        for _, buffId in ipairs(buffList) do
            buffLogic:AddBuff(buffId, chessPetEntity, monsterBornBuffContext)
        end
    end

    return chessPetEntity, chessPetID
end

---双端共同执行
function ChessPetCreationServiceLogic:CreateInternalRefreshMonsterLogic(monsterRefreshParamArray)
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")

    local eMonsterList = {}
    for _, monsterRefreshParam in ipairs(monsterRefreshParamArray) do
        local monsterPosList = self:_CalcInternalRefreshMonsterPos(monsterRefreshParam) ---处理怪物刷新
        local eMonsters, monsterIds = self:CreateMonsters(monsterPosList) ---先根据位置创建出所有的怪物
        table.appendArray(eMonsterList, eMonsters)
    end
    return eMonsterList
end

---提取波次内刷怪的配置数据
---@return MonsterRefreshData[]
function ChessPetCreationServiceLogic:_GetInternalRefreshConfigData()
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    --当前波次
    ---@type number
    local waveNum = self:_GetBattleStatComponent():GetCurWaveIndex()

    local monsterConfigDataArray = levelConfigData:GetLevelWaveInternalRefreshData(waveNum)
    return monsterConfigDataArray
end

---计算波次内刷怪的怪物位置
function ChessPetCreationServiceLogic:_CalcInternalRefreshMonsterPos(monsterRefreshParam)
    ---@type CreateMonsterPosService
    local createMonsterPosService = self._world:GetService("CreateMonsterPos")
    -- ---@type MonsterRefreshPosType
    -- local monsterRefreshPosType = monsterRefreshParam:GetMonsterRefreshPosType()
    -- local monsterArray = createMonsterPosService:GetMonsterRefreshPos(monsterRefreshPosType, monsterRefreshParam)

    --在怪物创建前，直接根据配置坐标创建

    ---@type MonsterTransformParam[]
    local chessPetArray = {}
    local chessPetIDArray = monsterRefreshParam:GetChessPetIDArray()
    local chessPetPosArray = monsterRefreshParam:GetChessPetPosArray()
    local chessPetRotationArray = monsterRefreshParam:GetChessPetRotationArray()

    for i, monsterID in ipairs(chessPetIDArray) do
        ---怪物实际占的格子坐标

        local monsterPosition = chessPetPosArray[i]
        local monsterDir = Vector2(0, 0)
        if chessPetRotationArray then
        -- monsterDir =   chessPetRotationArray[i]
        end

        local monsterTransformParam = MonsterTransformParam:New(monsterID)
        monsterTransformParam:SetPosition(monsterPosition)
        monsterTransformParam:SetRotation(monsterDir)
        monsterTransformParam:SetForward(monsterDir)

        chessPetArray[#chessPetArray + 1] = monsterTransformParam
    end

    return chessPetArray
end

---根据传进来的位置列表，创建一组怪物
---@param monsterArray MonsterTransformParam 数组
function ChessPetCreationServiceLogic:CreateMonsters(monsterArray)
    local eMonsters = {}
    local monsterIds = {}
    for _, v in ipairs(monsterArray) do
        local eMonster, monsterId = self:CreateMonster(v)
        table.insert(eMonsters, eMonster)
        table.insert(monsterIds, monsterId)

        self._world:GetSyncLogger():Trace(
            {
                key = "CreateInternalMonsters",
                monsterID = monsterId,
                entityID = eMonster:GetID(),
                pos = tostring(v:GetPosition())
            }
        )
    end
    return eMonsters, monsterIds
end

---计算出场技
---@param e Entity
function ChessPetCreationServiceLogic:CalcAppearSkill(e)
    ---@type SkillLogicService
    local sSkillLogic = self._world:GetService("SkillLogic")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local appearSkillId = utilDataSvc:GetAppearSkillId(e)
    if appearSkillId and appearSkillId > 0 then
        sSkillLogic:CalcSkillEffect(e, appearSkillId)
        sSkillLogic:UpdateRenderSkillRoutine(e)
    end
end
--endregion

function ChessPetCreationServiceLogic:_DoRefreshBoardGapTiles(fillPieceList)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local oldGapTiles = boardServiceLogic:GetGapTiles()
    local newGapTiles = {}
    ---TODO 暂时支持中途添加格子
    for i = 1, #oldGapTiles do
        local bFind = false
        for j = 1, #fillPieceList do
            if fillPieceList[j][1] == oldGapTiles[i][1] and fillPieceList[j][2] == oldGapTiles[i][2] then
                bFind = true
            end
        end
        if bFind ~= true then
            table.insert(newGapTiles, {oldGapTiles[i][1], oldGapTiles[i][2]})
        end
    end
    boardServiceLogic:ChangeGapTiles(newGapTiles)
    local addPiecePos = {}
    for i = 1, #fillPieceList do
        table.insert(addPiecePos, Vector2(fillPieceList[i][1], fillPieceList[i][2]))
    end
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    local pieceFillTable = boardServiceLogic:SupplyPieceList(addPiecePos)
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    boardCmpt:FillPieces(pieceFillTable)
    for i, grid in ipairs(pieceFillTable) do
        local gridPos = Vector2(grid.x, grid.y)
        boardServiceRender:CreateGridEntity(grid.color, gridPos, false)
    end
end

--应用制造1个幻象逻辑
---@param result SkillMakePhantomEffectResult
---@return entity
function ChessPetCreationServiceLogic:MakePhantomLogic(result)
    ---@type MonsterTransformParam
    local monsterTransformParam = MonsterTransformParam:New(result:GetTargetID())
    monsterTransformParam:SetPosition(result:GetBornPos())
    monsterTransformParam:SetRotation(result:GetBornRot())
    ---@type Entity
    local phantomEntity, id = self:CreateMonster(monsterTransformParam)
    phantomEntity:AddPhantomComponent(result:GetOwnerID())

    ---@type AttributesComponent
    local attributeCmpt = phantomEntity:Attributes()
    local maxHp = attributeCmpt:CalcMaxHp()
    local hp = math.floor(maxHp * result:GetHPPercent())
    --这里直接更改属性，而不modify
    attributeCmpt:SetSimpleAttribute("MaxHP", hp)
    attributeCmpt:SetSimpleAttribute("HP", hp)

    return phantomEntity
end

---@param entity Entity
function ChessPetCreationServiceLogic:InitWorldBossHPData(entity, monsterID)
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local stage = monsterConfigData:GetWorldBossConfig(monsterID)
    ---@type MonsterIDComponent
    local monsterIDCmpt = entity:MonsterID()
    monsterIDCmpt:InitWorldBossStageData(stage)
    monsterIDCmpt:SetWorldBossState(true)
end
