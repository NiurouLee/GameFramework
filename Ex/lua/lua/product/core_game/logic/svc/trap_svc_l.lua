--[[------------------------------------------------------------------------------------------
    TrapServiceLogic : 机关逻辑
]] --------------------------------------------------------------------------------------------

_class("TrapServiceLogic", BaseService)
---@class TrapServiceLogic: BaseService
TrapServiceLogic = TrapServiceLogic

function TrapServiceLogic:Constructor(world)
    ---@type TrapTargetSelector 机关目标选择器
    self._trapTargetSelector = TrapTargetSelector:New(world)

    --触发的机关
    self._triggerTraps = {}

    -- 哪些层的机关会被洗版刷掉
    self._flushLayer = {
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true
    }
    ---只有表现没有逻辑用来做标记的机关所在层
    self._onlyViewTrapLayer = -1
end

function TrapServiceLogic:GetTrapGroup()
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    return trapGroup
end

local function Filter_CanSummonTrapOnPos(e, trapData, onlyViewTrap, ignoreAbyss, hasSticker)
    if e:HasTrap() then
        --策划说0层机关上不能召唤其他机关
        if e:Trap():GetTrapLevel() == 0 and not e:HasDeadMark() then
            if onlyViewTrap then
                return false
            end
            --深渊上有贴纸，或者无视深渊，就可以召唤
            if e:Trap():GetTrapType() == TrapType.TerrainAbyss then
                if ignoreAbyss or hasSticker then
                    return false
                end
            end
            return true
        end
        --如果有互斥机关且等级较高不能替换
        if not e:HasDeadMark() and e:Trap():GetTrapLevel() == trapData.TrapLevel and not onlyViewTrap and
            e:Trap():GetReplaceLevel() > trapData.ReplaceLevel
        then
            return true
        end
        return false
    end
end

function TrapServiceLogic:CanSummonTrapOnPos(pos, trapId, blockFlag, ignoreAbyss)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if not utilDataSvc:IsValidPiecePos(pos) then
        return false
    end
    blockFlag = blockFlag or BlockFlag.SummonTrap
    if utilDataSvc:IsPosBlock(pos, blockFlag) then
        return false
    end

    local boardCmpt = self._world:GetBoardEntity():Board()

    ---@type TrapConfigData
    local trapConfigData = self._configService:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(trapId)

    local sticker =
    boardCmpt:GetPieceEntities(
        pos,
        function(e)
            return e:HasTrap() and e:Trap():IsSticker() and not e:HasDeadMark()
        end
    )
    local hasSticker = #sticker > 0
    local onlyViewTrap = self:IsViewTrapLevel(trapData.TrapLevel)
    local es = boardCmpt:GetPieceEntities(pos, Filter_CanSummonTrapOnPos, trapData, onlyViewTrap, ignoreAbyss, hasSticker)
    return #es == 0
end

function TrapServiceLogic:_GetTransferTrapAtPos(trapID, pos)
    ---@type TrapConfigData
    local trapConfigData = self._configService:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(trapID)
    local transferTrapIDs = trapData.TransferTrapIDs

    if not transferTrapIDs then
        return
    end

    local transferTrapIndex = {}
    for k, v in ipairs(transferTrapIDs) do
        transferTrapIndex[v] = k
    end

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local samePosTraps = utilSvc:GetTrapsAtPos(pos)

    local replaceTrap = nil
    for _, e in ipairs(samePosTraps) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        if transferTrapIndex[trapCmpt:GetTrapID()] then
            local idx = transferTrapIndex[trapCmpt:GetTrapID()] + 1 --改为召唤更高优先级的机关
            return transferTrapIDs[idx], e
        end
    end
end

---notCreateTrapShow 标识是否不创建TrapShow 由外部自己控制时机
---@param attrParam table<string,number>
---@param ownerEntity Entity
function TrapServiceLogic:CreateTrap(trapID, pos, dir, isHideOnBegin, inheritAttrParam, ownerEntity, transferDisabled, aiOrder)
    -- 这个地方不能判断是否可召唤，现在可召唤逻辑是各个机关自己的逻辑，这里需要考虑下是否重构
    -- local canSummon = self:CanSummonTrapOnPos(pos, trapID)
    -- if not canSummon then
    --     Log.info("can not create trap:,",trapID," at pos:",pos)
    --     return
    -- end

    local newTrapID, transferOldEntity
    if not transferDisabled then
        newTrapID, transferOldEntity = self:_GetTransferTrapAtPos(trapID, pos)
        if transferOldEntity then
            self:LogWarn(
                "transfer trap: formerID=",
                trapID,
                "<nullable>newID=",
                newTrapID,
                "pos=",
                tostring(pos),
                "oldTrapEntityID=",
                transferOldEntity:GetID()
            )
            if newTrapID then
                trapID = newTrapID
            end
            transferOldEntity:Attributes():Modify("HP", 0)
            self:AddTrapDeadMark(transferOldEntity)
            self:LogWarn("transfer group trap: ", pos)
        end
    end

    ---@type TrapConfigData
    local trapConfigData = self._configService:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(trapID)
    local isOnlyViewTrap = self:IsViewTrapLevel(trapData.TrapLevel)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local samePosTraps = utilSvc:GetTrapsAtPos(pos)
    local replaceTrap = nil
    if #samePosTraps > 0 then
        for _, e in ipairs(samePosTraps) do
            ---@type TrapComponent
            local trapCmpt = e:Trap()
            if trapCmpt:GetTrapType() == TrapType.GapTileTrap then
                ---镂空地板机关，阻挡一切机关的召唤，
                ---加在此处是因为有技能效果不判定位置是否可召唤机关，就直接使用CreateTrap接口创建机关
                ---例如：SkillEffectType.AddGridEffect
                return
            end
            if trapCmpt:GetTrapLevel() == trapData.TrapLevel and not isOnlyViewTrap then
                if trapCmpt:GetReplaceLevel() <= trapData.ReplaceLevel then
                    if not e:HasDeadMark() then
                        --同层机关，高优先级替换低或相等的
                        e:Attributes():Modify("HP", 0)
                        self:AddTrapDeadMark(e)
                        replaceTrap = e
                        self:LogWarn("Replace trap at: ", pos)
                        --同层只会有一个，处理完可以直接跳出循环
                        break
                    end
                else
                    --同位置机关同层但优先级低，所以不创建
                    self:LogWarn(
                        "该位置有相同层但更高优先级的机关，所以不创建。pos:",
                        pos,
                        " NewTrap:",
                        trapID,
                        " OldTrap:",
                        trapCmpt:GetTrapID()
                    )
                    return
                end
            end
        end
    end

    --创建Entity
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---@type Entity
    local trapEntity = entityService:CreateLogicEntity(EntityConfigIDConst.Trap)
    trapEntity:ReplaceTrapID(trapID)
    Log.debug("CreateTrap entityID=", trapEntity:GetID(), " trapID=", trapID, " pos=", pos)

    if replaceTrap then
        ---@type DeadMarkComponent
        local deadMarkCmpt = replaceTrap:DeadMark()
        deadMarkCmpt:SetDeadCasterID(trapEntity:GetID())
    end

    --机关增加宿主和阵营
    if ownerEntity then
        trapEntity:ReplaceAlignment(ownerEntity:Alignment():GetAlignmentType())
        trapEntity:ReplaceGameTurn(ownerEntity:GameTurn():GetGameTurn())
        trapEntity:AddSummoner(ownerEntity:GetID())
    end
    --BodyArea
    local areaArray = {}
    if trapData.Area then
        for i, str in ipairs(trapData.Area) do
            local numStr = string.split(str, ",")
            local vec2 = Vector2(tonumber(numStr[1]), tonumber(numStr[2]))
            table.insert(areaArray, vec2)
        end
    else
        table.insert(areaArray, Vector2.zero)
    end
    trapEntity:ReplaceBodyArea(areaArray)

    --GridLocation  逻辑坐标
    local trapRotation = dir
    trapEntity:SetGridLocation(pos, trapRotation)

    if trapData.PositionOffset then
        local strArraypositionOffset = string.split(trapData.PositionOffset, ",")
        local positionOffset = Vector2(tonumber(strArraypositionOffset[1]), tonumber(strArraypositionOffset[2]))
        trapEntity:SetGridOffset(positionOffset)
    end

    --AI
    if trapData.AIID then --如果该陷阱有AIID，就给它加AI组件
        ---若使用召唤顺序，则此处配置的AIID个数不能超过1
        if aiOrder and table.count(trapData.AIID) > 1 then
            self:ThrowException("该机关创建时使用的是召唤顺序作为AI顺序，配置的AI数量不能超过1，TrapID:", trapID)
        end
        trapEntity:InitAI(self._world, trapID, 1, trapData.AITargetType)
        trapEntity:AddNewAIByConfig(trapID, trapData.AIID, aiOrder)
    end

    if trapData.TrapType == TrapType.CurseTower then
        trapEntity:AddCurseTower()
    end
    if trapData.TrapType == TrapType.TrapExtendSkillScope then
        trapEntity:AddTrapExtendSkillScope(trapData.TrapTypeComponentParam)
    end

    --trap效果类型
    ---@type TrapComponent
    local cTrap = trapEntity:Trap()
    cTrap:SetTrapID(trapID)
    cTrap:SetTrapType(trapData.TrapType)
    cTrap:SetTypeParam(trapData.TypeParam)
    cTrap:SetTrapEffect(trapData.TrapEffectType, trapData.TrapEffectParam)
    cTrap:SetTrapRaceType(trapData.RaceType, trapData.RaceParams)
    cTrap:SetTrapDestroy(trapData.DestroyType, trapData.DestroyParam)
    cTrap:SetOrgDir(trapRotation)
    cTrap:SetTrapLevel(trapData.TrapLevel)
    cTrap:SetReplaceLevel(trapData.ReplaceLevel)
    cTrap:SetSkillType(trapData.SkillType)
    cTrap:SetTriggerByRace(trapData.TriggerByRace)
    cTrap:SetGroupID(trapData.GroupID)
    cTrap:SetGroupTriggerTrapID(trapData.GroupTriggerTrapID)
    cTrap:SetCanBePurified(trapData.CanBePurified)
    cTrap:SetSpecialDestroy(trapData.SpecialDestroy)
    cTrap:SetFallWithGrid(trapData.FallWithGrid)
    cTrap:SetTrapBornRound(self._world:BattleStat():GetLevelTotalRoundCount())
    cTrap:SetCantAutoSkill(trapData.CantAutoSkill)
    -- cTrap:SetSkillID(trapData.SkillID)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    local trapDataSkillID = trapData.SkillID
    if trapDataSkillID then
        local newTrapDataSkillID = {}
        for k, v in pairs(trapDataSkillID) do
            local value = affixService:ChangeTrapSkill(trapID, v, k)
            newTrapDataSkillID[k] = value
        end
        cTrap:SetSkillID(newTrapDataSkillID)
    end

    ---@type BoardServiceLogic
    local boardServiceL = self._world:GetService("BoardLogic")

    local oldPieceType = boardServiceL:GetPieceType(pos)
    cTrap:SetRecordPieceType(oldPieceType)

    if trapData.GridPieceElement then
        for _, areaPos in ipairs(areaArray) do
            local workPos = pos + areaPos
            if utilSvc:IsValidPiecePos(workPos) then
                boardServiceL:SetPieceTypeLogic(trapData.GridPieceElement, workPos)
            end
        end
    end

    cTrap:SetBlockByRaceType(trapData.BlockByRace)
    local block = trapData.Block or 0
    local blockFlag = boardServiceL:GetBlockFlagByBlockId(block)
    trapEntity:ReplaceBlockFlag(blockFlag)
    boardServiceL:UpdateEntityBlockFlag(trapEntity, pos, pos) --机关阻挡信息

    --回合数
    local round = 1
    if trapData.ShowParam then
        round = trapData.ShowParam.roundTotal or 1
    end

    if trapData.DestroyType == TrapDestroyType.DestroyByRound then
        local trapCmpt = trapEntity:Trap()
        round = trapCmpt:GetTrapDestroyParam():GetNum()
    end
    trapEntity:Attributes():Modify("TotalRound", round)

    --符文的初始回合是0
    local currentRound = 1
    if trapData.TrapEffectType == TrapEffectType.RuneChange or
        trapData.TrapEffectType == TrapEffectType.ShowCountDownType then
        if trapData.TrapEffectType == TrapEffectType.RuneChange then
            if trapData.DestroyParam and trapData.DestroyParam[2] then
                currentRound = tonumber(trapData.DestroyParam[2])
            else
                currentRound = 0
            end
        end
        trapEntity:Attributes():Modify("CurrentRound", currentRound)
    end

    local res = DataAttributeResult:New(trapEntity:GetID(), "CurrentRound", currentRound)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)

    res = DataAttributeResult:New(trapEntity:GetID(), "TotalRound", round)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)

    --设置机关属性
    ---@type AttributesComponent
    local attr = trapEntity:Attributes()
    local attrParam = trapData.Attributes
    if attrParam then
        for k, v in pairs(attrParam) do
            local value = affixService:ChangeTrapAttr(trapID, v, k)
            if inheritAttrParam and inheritAttrParam[k] then
                value = inheritAttrParam[k]
            end
            attr:Modify(k, value)
            if k == "OpenState" then
                res = DataAttributeResult:New(trapEntity:GetID(), "OpenState", value)
                self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            end
        end
    end

    attr:Modify("Mobility", 1, 1, MultModifyOperator.PLUS)
    attr:Modify("MaxMobility", 99)

    if trapData.CanBeAttack then
        attr:Modify("CanBeAttacked", 1)
    end
    --设置记录的释放技能回合默认值
    attr:Modify("CastSkillRound", {})

    --添加机关属性，影响伤害结算，暂不考虑副属性 -jince
    if trapData.TrapElement then
        local elementType = trapData.TrapElement
        if inheritAttrParam and inheritAttrParam["Element"] then
            elementType = inheritAttrParam["Element"]
        end
        trapEntity:AddElement(elementType, nil)
        attr:SetSimpleAttribute("Element", elementType)
    end

    --光环类机关需要计算光环范围并设置给机关组件
    if cTrap:GetTrapType() == TrapType.Auras then
        local skillID = trapData.TypeParam.rangeSkillID
        ---@type SkillConfigData
        local skillConfigData = self._configService:GetSkillConfigData(skillID)
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        ---@type SkillScopeResult
        local skillScopeRes = utilScopeSvc:CalcSkillScope(skillConfigData, pos, trapEntity, dir)
        cTrap:SetAuraRange(skillScopeRes:GetAttackRange())

        self:AddAuraRange(cTrap:GetAuraGroupID(), skillScopeRes:GetAttackRange())
    end

    ---计算机关的出场技
    self:_CalcTrapAppearSkill({ trapEntity })
    --机关出生buff
    self:_CalcTrapAddBuff(trapEntity, trapData.BuffID, trapID)

    local groupId = cTrap:GetScopeCenterGroupId()
    if groupId > 0 then
        trapEntity:AddScopeCenter(groupId)
    end

    self._world:GetSyncLogger():Trace({ key = "CreateTrap", trapID = trapID, entityID = trapEntity:GetID(), pos = pos })

    --添加Entity到BoardComponent中
    self:AddTrapToBoardComponent(pos, trapEntity)
    if cTrap:GetTrapType() == TrapType.Protected then
        self._world:BattleStat():SaveProtectTrap(trapID, pos, dir)
    end

    --记录结果通知表现层
    local data = DataTrapCreationResult:New()
    data:SetTrapCreationResult_TrapID(trapID)
    data:SetTrapEntityID(trapEntity:GetID())
    data:SetTrapHP(trapEntity:Attributes():GetCurrentHP())
    data:SetTrapHPMax(trapEntity:Attributes():CalcMaxHp())
    if replaceTrap then
        data:SetReplaceTrapID(replaceTrap:GetID())
    end
    if transferOldEntity then
        data:SetTransferTrapID(transferOldEntity:GetID())
    end
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type NTTrapShow
    local nt = NTTrapShow:New(trapEntity, ownerEntity)
    local cBattleStat = self._world:BattleStat()
    if ownerEntity then
        nt:SetIsFirstSummon(not cBattleStat:IsTrapSummonedByCasterBefore(trapID, ownerEntity:GetID()))
    end
    triggerSvc:Notify(nt)

    --首先是单逻辑内可能计算多次技能的处理：resultContainer拿出来通过L2R发给表现
    local resultContainer = trapEntity:SkillRoutine():GetResultContainer()

    ---@type DataTrapAppearSkill
    local dataTrapAppearSkill = DataTrapAppearSkill:New()
    dataTrapAppearSkill:SetTrapEntity(trapEntity):SetResultContainer(resultContainer)
    self._world:EventDispatcher():Dispatch(GameEventType.DataTrapAppearSkill, dataTrapAppearSkill)

    if trapData.TriggerWhileSpawn then
        self:DoTriggerWhileSpawn(trapEntity, pos)
    end

    --扫描模块：只记录我方召唤或不区分召唤者的机关
    ---@type CfgTrapScan
    local cfgTrapScan = Cfg.cfg_trap_scan[trapID]
    if cfgTrapScan then
        local eLocalTeam = self._world:Player():GetLocalTeamEntity()
        if (not cfgTrapScan.PetID) or (ownerEntity and ownerEntity:HasPet() and eLocalTeam:GetID() == ownerEntity:Pet():GetOwnerTeamEntity():GetID()) then
            cBattleStat:AddScanTrapIDInMatch(trapID)
        end
    end
    if ownerEntity then
        cBattleStat:AddTrapIDByCasterEntityID(trapID, ownerEntity:GetID())
    end

    ---@type NTTrapShowEnd
    local ntTrapShowEnd = NTTrapShowEnd:New(trapEntity, ownerEntity,pos,areaArray)
    if ownerEntity then
        ntTrapShowEnd:SetIsFirstSummon(not cBattleStat:IsTrapSummonedByCasterBefore(trapID, ownerEntity:GetID()))
    end
    triggerSvc:Notify(ntTrapShowEnd)

    return trapEntity
end

--MSG45699: 机关召唤后，如果上面有怪物，且机关会被怪物触发时，在这里触发一次
function TrapServiceLogic:DoTriggerWhileSpawn(trapEntity, pos)
    --接下来判断是否计算触发技，如果有多个怪物（目前只想到乘骑），此处视为由坐骑（被骑方）触发
    local potentialTriggerEntity
    ---@type Entity[]
    local globalMonsterGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        globalMonsterGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Team)
    end
    for _, e in ipairs(globalMonsterGroupEntities) do
        local bodyArea, gridPos, isRightPos
        if e:HasDeadMark() then
            goto TRIGGER_WHILE_SPAWN_CONTINUE
        end
        gridPos = e:GetGridPosition()
        bodyArea = e:BodyArea():GetArea()
        for _, v2Relative in ipairs(bodyArea) do
            local v2 = gridPos + v2Relative
            if v2 == pos then
                isRightPos = true
                break
            end
        end
        if not isRightPos then
            goto TRIGGER_WHILE_SPAWN_CONTINUE
        end

        if self:CanPlayTriggerSkill(trapEntity, e) then
            --如果没有乘骑状态，因为目前没有其他的导致同格多怪物的状况，此处认为已找到触发者
            potentialTriggerEntity = e
            --如果是乘骑状态，触发机关的单位是坐骑
            if (e:HasRide()) and (e:Ride():GetMountID() ~= e:GetID()) then
                potentialTriggerEntity = self._world:GetEntityByID(e:Ride():GetRiderID())
            end
            break
        end

        ::TRIGGER_WHILE_SPAWN_CONTINUE::
    end

    if potentialTriggerEntity then
        self:CalcTrapTriggerSkill(trapEntity, potentialTriggerEntity)
    end
end

function TrapServiceLogic:CalcTrapState(destoryType)
    local trapGroup = self:GetTrapGroup()
    local taskIDList = {}

    local trapEntityIDList = {}
    for _, trapEntity in ipairs(trapGroup:GetEntities()) do
        if self._world:MatchType() == MatchType.MT_BlackFist then
            if trapEntity:GameTurn():GetGameTurn() == self._world:GetGameTurn() then
                trapEntityIDList[#trapEntityIDList + 1] = trapEntity:GetID()
            end
        else
            trapEntityIDList[#trapEntityIDList + 1] = trapEntity:GetID()
        end
    end
    table.sort(trapEntityIDList, table.ACS)

    local calcStateTraps = {}
    for _, trapEntityID in ipairs(trapEntityIDList) do
        local e = self._world:GetEntityByID(trapEntityID)
        ---MSG70164
        if not e:HasDeadMark() then
            ---@type TrapComponent
            local trapCmpt = e:Trap()
            ---@type TrapDestroyType
            local trapDestroyType = trapCmpt:GetTrapDestroyType()
            ---@type TrapRaceType
            local trapType = trapCmpt:GetTrapType()

            if trapDestroyType == destoryType then
                ---@type TrapSelfDestroyParam
                local trapDestroyParam = trapCmpt:GetTrapDestroyParam()
                if trapDestroyParam ~= nil then
                    trapDestroyParam:NextNum()
                    if not trapCmpt:IsRuneChange() then
                        local curTrapRoundNum = trapDestroyParam:GetNum()
                        if curTrapRoundNum <= 0 then
                            trapCmpt:SetNeedDestory(true)

                            ---计算离场技能
                            self:_CalcTrapDisappearSkill({ e })
                            table.insert(calcStateTraps, e)
                            --机关死亡
                            e:Attributes():Modify("HP", 0)
                            self:AddTrapDeadMark(e)
                        end
                    end
                end
            end
        end
    end

    return calcStateTraps
end

---@param pos Vector2
---@param entity Entity
function TrapServiceLogic:AddTrapToBoardComponent(pos, entity)
    --添加Entity到BoardComponent中
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = boardEntity:Board()
    ---@type TrapComponent
    local cTrap = entity:Trap()
    if cTrap:IsDimensionDoor() then
        cBoard:AddDimensionDoor(pos, entity)
    elseif cTrap:IsExit() then
        cBoard:AddExit(pos, entity)
    elseif cTrap:IsBenumbTrigger() then
        cBoard:AddBenumbTrigger(pos, entity)
    end
end

---@param pos Vector2
---@param entity Entity
function TrapServiceLogic:RemoveTrapFromBoardComponent(pos, entity)
    --添加Entity到BoardComponent中
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = boardEntity:Board()
    ---@type TrapComponent
    local cTrap = entity:Trap()
    if cTrap:IsDimensionDoor() then
        cBoard:RemoveDimensionDoor(pos)
    elseif cTrap:IsExit() then
        cBoard:RemoveExit(pos)
    end
end

---触发并执行机关的触发效果逻辑
---@param trapEntity Entity trapEntity
---@param triggerEntity Entity 触发者
function TrapServiceLogic:CalcTrapTriggerSkill(trapEntity, triggerEntity)
    local canTrigger, cTrap, triggerSkillId = self:CanPlayTriggerSkill(trapEntity, triggerEntity)
    if not canTrigger then
        return

    end
    local maxTriggerCount = cTrap:GetTriggerMaxCount()
    if (maxTriggerCount > 0) and (cTrap:GetCurrentTriggerCount() >= maxTriggerCount) then
        return
    end

    --已经死亡的机关不可以再触发
    if trapEntity:HasDeadMark() then
        return
    end

    local isSuperGrid = cTrap:IsSuperGrid()
    local isPoorGrid = cTrap:IsPoorGrid()
    local pos = trapEntity:GetGridPosition()

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local triggerTraps = {}
    local triggerResults = {}
    ---启动一次机关技能
    triggerTraps[#triggerTraps + 1] = trapEntity
    local res = self:_DoTrapSkill(trapEntity, triggerEntity, triggerSkillId)
    triggerResults[#triggerResults + 1] = res
    cTrap:AddCurrentTriggerCount()

    --组合机关
    local traps = utilSvc:GetGroupTrap(trapEntity)
    if traps and table.count(traps) > 0 then
        for _, e in ipairs(traps) do
            local cTriggeredTrap = e:Trap()
            local skillId = cTriggeredTrap:GetTriggerSkillID()
            if skillId then
                triggerTraps[#triggerTraps + 1] = e
                res = self:_DoTrapSkill(e, triggerEntity, skillId)
                triggerResults[#triggerResults + 1] = res
                cTriggeredTrap:AddCurrentTriggerCount()
            end
        end
    end

    if isSuperGrid then
        local nt = NTSuperGridTriggerEnd:New(pos)
        self._world:GetService("Trigger"):Notify(nt)
    end

    if isPoorGrid then
        local nt = NTPoorGridTriggerEnd:New(pos)
        self._world:GetService("Trigger"):Notify(nt)
    end

    --MSG45699：因可能同时计算两套技能，触发技的技能结果被拿出来单独保存
    local resultContainer = trapEntity:SkillRoutine():GetResultContainer()
    ---@type DataTrapTriggerSkill
    local dataTrapTriggerSkill = DataTrapTriggerSkill:New()
    dataTrapTriggerSkill:SetTrapEntity(trapEntity):SetTriggerEntity(triggerEntity):SetResultContainer(resultContainer)
    self._world:EventDispatcher():Dispatch(GameEventType.DataTrapTriggerSkill, dataTrapTriggerSkill)

    return triggerTraps, triggerResults
end

---@param trapEntity Entity
function TrapServiceLogic:_DoTrapSkill(trapEntity, triggerEntity, skillId)
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    ---@type BattleService
    local battlesvc = self._world:GetService("Battle")
    triggerService:Notify(NTTrapSkillStart:New(trapEntity, skillId, triggerEntity))
    local isFinalAttackBeforeSkill = battlesvc:IsPlayerTurnFinalAttack()
    skillLogicService:CalcSkillEffect(trapEntity, skillId)
    local isFinalAttackAfterSkill = battlesvc:IsPlayerTurnFinalAttack()
    ---@type SkillEffectResultContainer
    local resultContainer = trapEntity:SkillContext():GetResultContainer()
    resultContainer:SetSkillID(skillId)
    if (not isFinalAttackBeforeSkill) and isFinalAttackAfterSkill and
        table.icontains(BattleConst.FinalAttackSkillIdListOfTriggerTrap, skillId)
    then
        resultContainer:SetFinalAttack(true)
    end

    local triggerEntityID = nil
    if triggerEntity then
        triggerEntityID = triggerEntity:GetID()
    end

    self:LogNotice(
        "CalcTrapTriggerSkill：TrapEntityID = ",
        trapEntity:GetID(),
        ", TrapSkillID = ",
        skillId,
        " TriggerEntityID=",
        triggerEntityID
    )

    triggerService:Notify(NTTrapSkillEnd:New(trapEntity, skillId, triggerEntity))
    --任意门触发的时候禁用自动战斗UI
    if trapEntity:Trap():IsDimensionDoor() then
        self._world:EventDispatcher():Dispatch(GameEventType.BanAutoFightBtn, true)
    end
    --结果通知表现层
    skillLogicService:UpdateRenderSkillRoutine(trapEntity)
    return resultContainer
end

--挂出生buff
function TrapServiceLogic:_CalcTrapAddBuff(entity, buffIDs, trapID)
    ---@type AffixService
    local affixSvc = self:GetService("Affix")
    buffIDs = affixSvc:ReplaceTrapBuff(trapID, buffIDs)
    buffIDs = affixSvc:AddTrapBuff(trapID, buffIDs)
    if not buffIDs then
        return
    end
    ---@type BuffLogicService
    local svcBuffLogic = self:GetService("BuffLogic")
    for i, buffID in ipairs(buffIDs) do
        svcBuffLogic:AddBuff(buffID, entity)
    end
end

--根据机关的RaceType判断可不可以被目标触发
function TrapServiceLogic:CanSelectByRaceType(trap, target)
    if trap:Trap():GetTrapType() == TrapType.BombByHitBack then
        return true
    end
    return self._trapTargetSelector:CanSelectTarget(trap, target)
end

---@param e Entity
---@param triggerEntity Entity
function TrapServiceLogic:CanPlayTriggerSkill(e, triggerEntity)
    local canTrigger = false
    local triggerSkillId = 0

    ---@type TrapComponent
    local cTrap = e:Trap()
    if not cTrap then
        return false
    end

    local autofight = self._world:BattleStat():GetAutoFight()
    if autofight and cTrap:IsDimensionDoor() then
        return false
    end
    --触发阵营检查
    local raceType = cTrap:GetTrapRaceType()
    if not self:CanSelectByRaceType(e, triggerEntity) then
        return false
    end

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    triggerSkillId = utilSvc:GetTrapTriggerSkillIDByTriggerEntity(e, triggerEntity)
    if triggerSkillId and triggerSkillId > 0 then
        return true, cTrap, triggerSkillId
    end

    triggerSkillId = cTrap:GetTriggerSkillID()
    if triggerSkillId and triggerSkillId > 0 then
        canTrigger = true
    end

    if not canTrigger then
        self:LogNotice("机关无触发技能，无法执行机关触发表现, ID =", e:GetID(), "SkillID =",
            triggerSkillId)
    end
    return canTrigger, cTrap, triggerSkillId
end

---计算机关的出场技逻辑效果，纯逻辑函数
---@param traps Array 机关列表
function TrapServiceLogic:_CalcTrapAppearSkill(traps)
    if not traps or table.count(traps) <= 0 then
        return
    end

    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    for _, e in ipairs(traps) do
        ---@type TrapComponent
        local cTrap = e:Trap()
        local skillId = cTrap:GetAppearSkillID()
        if skillId and skillId > 0 and not cTrap:IsSkillHadCalc(skillId) then
            skillLogicService:CalcSkillEffect(e, skillId)
            skillLogicService:UpdateRenderSkillRoutine(e)
            cTrap:SetHadCalcSkill(skillId)
        end
    end
end

---计算离场技能效果
function TrapServiceLogic:_CalcTrapDisappearSkill(traps)
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    for _, e in ipairs(traps) do
        local cTrap = e:Trap()
        local skillId = cTrap:GetDisappearSkillID()

        ---@type DeadMarkComponent
        local deadMarkCmpt = e:DeadMark()
        local deadNotPlayDisappear = cTrap:GetDeadNotPlayDisappear()
        local canPlayDisappear = true
        if deadNotPlayDisappear == 1 and deadMarkCmpt and deadMarkCmpt:GetDeadCasterID() ~= nil then
            canPlayDisappear = false
        end

        if skillId and skillId > 0 and canPlayDisappear then
            skillLogicService:CalcSkillEffect(e, skillId)
            skillLogicService:UpdateRenderSkillRoutine(e)
        end
    end
end

---计算死亡技
function TrapServiceLogic:CalcTrapDieSkill(traps)
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    for _, e in ipairs(traps) do
        ---@type TrapComponent
        local cTrap = e:Trap()
        local skillId = cTrap:GetDieSkillID()
        if skillId and skillId > 0 and not cTrap:IsHadCalcDead() then
            ---设置计算过死亡技能标记 为了主动技单独结算死亡技使用
            cTrap:SetHadCalcDead()
            skillLogicService:CalcSkillEffect(e, skillId)
            skillLogicService:UpdateRenderSkillRoutine(e, "TrapDieSkill")
        end
    end
end

---执行机关的连锁前技能逻辑
---@param trapEntity Entity trapEntity
function TrapServiceLogic:CalcTrapPreChainSkill()
    ---@type SkillLogicService
    local sSkillLogic = self._world:GetService("SkillLogic")
    local trapIds = {}
    local g = self:GetTrapGroup()
    for i, e in ipairs(g:GetEntities()) do
        local cTrap = e:Trap()
        local preChainSkillId = cTrap:GetPreChainSkillID()
        if preChainSkillId and preChainSkillId > 0 then
            table.insert(trapIds, e:GetID())
            sSkillLogic:CalcSkillEffect(e, preChainSkillId)
            sSkillLogic:UpdateRenderSkillRoutine(e)
        end
    end
    return trapIds
end

------------------------------------------------------------------------------------------技能

---将需要立即销毁的目标销毁 TODO之后可优化成在算技能效果的时候将目标的技能效果一并算出来
function TrapServiceLogic:DestroyTrapAtOnce(targetID, casterEntity, isDieSkillDisabled)
    local eTarget = self._world:GetEntityByID(targetID)
    if self:CanDestroyAtOnce(eTarget) then --如果是可立即销毁的机关
        self:AddTrapDeadMark(eTarget, isDieSkillDisabled)

        -- 统计是否是被玩家击碎的机关
        if casterEntity:HasPetPstID() then
            local battleStatComponent = self._world:BattleStat()
            ---@type TrapComponent
            local cTrap = eTarget:Trap()
            local trapId = cTrap:GetTrapID()
            -- 设置击碎机关的数量
            battleStatComponent:AddSmashTrapCount(trapId, 1)
        end
    end
end

---主动技伤害打死的机关在主动技计算完毕后单独结算死亡技
function TrapServiceLogic:CalcActiveSkillDeadTrapDeadSkill()
    local entityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for i, entity in ipairs(entityList) do
        ---@type TrapComponent
        local trapComponent = entity:Trap()
        if trapComponent and entity:HasDeadMark() and not trapComponent:IsHadCalcDead() then
            self:CalcTrapDieSkill({ entity })
        end
    end
end

---@param e Entity
---机关是否可立即销毁
function TrapServiceLogic:CanDestroyAtOnce(e)
    ---@type TrapComponent
    local cTrap = e:Trap()
    if not cTrap then
        return false
    end
    if cTrap:GetTrapType() == TrapType.Protected then
        return false
    end
    ---@type AttributesComponent
    local cAttributes = e:Attributes()
    local hp = cAttributes:GetCurrentHP()
    if hp and hp <= 0 then
        return true
    end
    return false
end

------------------------------------------------------------------------------------------

function TrapServiceLogic:StartBeforeMainAI()
    ---@type AIService
    local aiService = self._world:GetService("AI")
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.BeforeMain)
end

function TrapServiceLogic:TrapActionRoundResult()
    -- local aiService, aliveTraps = self:_InitAIOnceLogic(AILogicPeriodType.RoundResult)
    -- if aiService and aliveTraps then
    --     aiService:RunAiLogic_OneOrder(aliveTraps, AILogicPeriodType.RoundResult)
    -- end
    ---@type AIService
    local aiService = self._world:GetService("AI")
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.RoundResult)
end

---计算符文
function TrapServiceLogic:TrapActionAfterAI()
    -- local aiService, aliveTraps = self:_InitAIOnceLogic(AILogicPeriodType.AfterMain)
    -- if aiService and aliveTraps then
    --     aiService:RunAiLogic_OneOrder(aliveTraps, AILogicPeriodType.AfterMain)
    -- end
    ---@type AIService
    local aiService = self._world:GetService("AI")
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.AfterMain)
end

---RoundEnter里，在玩家行动前
function TrapServiceLogic:TrapActionBeforePlayer()
    -- local aiService, aliveTraps = self:_InitAIOnceLogic(AILogicPeriodType.RoundEnterBeforePlayer)
    -- if aiService and aliveTraps then
    --     aiService:RunAiLogic_OneOrder(aliveTraps, AILogicPeriodType.RoundEnterBeforePlayer)
    -- end
    ---@type AIService
    local aiService = self._world:GetService("AI")
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.RoundEnterBeforePlayer)
end

---@return AIService, Entity[]
function TrapServiceLogic:_InitAIOnceLogic(aiLogicPeriodType)
    local aliveTraps = self:_FindAliveTraps()
    if table.count(aliveTraps) <= 0 then
        return
    end
    local aiService = self._world:GetService("AI")
    ---@param v Entity
    for i, v in ipairs(aliveTraps) do
        v:AI():InitAiLogic(AINewNodeStatus.Ready, v, aiLogicPeriodType, 1000)
    end
    return aiService, aliveTraps
end

---找到所有带AI的trap
function TrapServiceLogic:_FindAliveTraps()
    local curGameTurn = self._world:GetGameTurn()
    local trapGroup = self:GetTrapGroup()
    ---@type Entity[]
    local allTrapList = trapGroup:GetEntities()
    local aliveTraps = {}
    for i = 1, #allTrapList do
        ---@type TrapComponent
        local trapCmpt = allTrapList[i]:Trap()
        local trapTurn = allTrapList[i]:GameTurn():GetGameTurn()
        if allTrapList[i]:HasAI() and trapCmpt:GetNeedDestory() == false and trapTurn == curGameTurn then
            table.insert(aliveTraps, allTrapList[i])
        end
    end

    return aliveTraps
end

---添加逻辑死亡标记，并结算死亡技
---@param entity Entity
function TrapServiceLogic:AddTrapDeadMark(entity, isDieSkillDisabled)
    ---@type TrapComponent
    local trapCmpt = entity:Trap()
    if not trapCmpt then
        return
    end

    ---血量大于0，说明还没死
    local cAttributes = entity:Attributes()
    local curHp = cAttributes:GetCurrentHP()
    if curHp > 0 then
        return
    end

    ---如果已经挂上过逻辑死亡标记，不用再挂了
    if entity:HasDeadMark() then
        return
    end


    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    ---@type NTTrapDeadStart
    local ntTrapDeadStart =NTTrapDeadStart:New(entity)
    local ownEntity = entity:GetSummonerEntity()
    if ownEntity then
        ntTrapDeadStart:SetOwnerEntity(ownEntity)
    end
    triggerService:Notify(ntTrapDeadStart)

    entity:AddDeadMark()

    --光环类机关死亡时更新结界范围
    if trapCmpt:GetTrapType() == TrapType.Auras then
        self:RemoveAuraRange(trapCmpt:GetAuraGroupID(), trapCmpt:GetAuraRange())
    end

    --限制同时存在的机关，死亡的时候修改现存机关ID列表
    ---@type BattleFlagsComponent
    local battleFlags = self._world:BattleFlags()
    local entityIDList = battleFlags:GetSummonMeantimeLimitEntityID(trapCmpt:GetTrapID())
    if table.intable(entityIDList, entity:GetID()) then
        table.removev(entityIDList, entity:GetID())
        battleFlags:SetSummonMeantimeLimitEntityID(trapCmpt:GetTrapID(), entityIDList)
    end

    --SummonFixPosLimit，死亡的时候修改现存机关ID列表
    local trapIDList = battleFlags:GetSummonOnFixPosLimitEntityID(trapCmpt:GetTrapID())
    if table.intable(trapIDList, entity:GetID()) then
        table.removev(trapIDList, entity:GetID())
        battleFlags:SetSummonOnFixPosLimitEntityID(trapCmpt:GetTrapID(), trapIDList)
    end

    -- 清除阻挡
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local pos = entity:GetGridPosition()
    boardService:RemoveEntityBlockFlag(entity, pos)

    --如果是棱镜机关，必须执行死亡技能
    local needCalcTrapDieSkill = false
    if trapCmpt:IsPrismGrid() then
        needCalcTrapDieSkill = true
    end

    if not isDieSkillDisabled or needCalcTrapDieSkill then
        self:CalcTrapDieSkill({ entity })
    end
    ---@type NTTrapDead
    local nt = NTTrapDead:New(entity, trapCmpt:GetTrapID())
    if ownEntity then
        nt:SetOwnerEntity(ownEntity)
    end
    --buff失活
    triggerService:Notify(nt)
    entity:BuffComponent():SetActive(false)
    --移除机关缓存
    self:RemoveTrapFromBoardComponent(pos, entity)

    return entity:DeadMark()
end

function TrapServiceLogic:CalcAllTrapDeadMark()
    local gTrap = self:GetTrapGroup()
    if not gTrap then
        return
    end

    for _, e in ipairs(gTrap:GetEntities()) do
        self:AddTrapDeadMark(e)
    end
end

---实际清理死亡怪物的Entity
function TrapServiceLogic:ClearTrapDeadEntity()
    ---取出所有带了DeadFlag标签的
    local toDestroyList = {}
    local trapGroup = self:GetTrapGroup()
    for _, trapEntity in ipairs(trapGroup:GetEntities()) do
        if trapEntity:HasDeadMark() then
            toDestroyList[#toDestroyList + 1] = trapEntity
        end
    end

    --清除buff
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")

    for _, entity in ipairs(toDestroyList) do
        buffLogicService:RemoveAllBuffInstance(entity) --清除buff
        self._world:DestroyEntity(entity)
    end
end

------------------------------------------------------------------------------------------

--- @class TrapTriggerOrigin
local TrapTriggerOrigin = {
    Move = 1, --移动
    Teleport = 2, --瞬移
    Hitback = 3, --击退
    Eddy = 4, ---传送漩涡
    MonsterGridMove = 5, --怪物延格子移动
    ChessMonsterGridMoveByElement = 6 --棋子怪物按照属性延格子移动
}
_enum("TrapTriggerOrigin", TrapTriggerOrigin)

---瞬移触发机关
---@param entityObject Entity
---@param triggerOrigin number 触发来源，作为触发机关的例外数据
function TrapServiceLogic:TriggerTrapByTeleport(entityWork, bEnableEddy)
    local listTrapTrigger = nil
    ---传送漩涡引起的传送是不允许继续触发传送机关的
    if bEnableEddy then
        listTrapTrigger = self:TriggerTrapByEntity(entityWork, TrapTriggerOrigin.Teleport)
    else
        listTrapTrigger = self:TriggerTrapByEntity(entityWork, TrapTriggerOrigin.Eddy)
    end
    return listTrapTrigger
end

---按照entityObject的体型触发所有机关
---@param entityObject Entity
---@param triggerOrigin number 触发来源，作为触发机关的例外数据
---@return Entity[], SkillEffectResultContainer[]
function TrapServiceLogic:TriggerTrapByEntity(entityObject, triggerOrigin)
    local areas = entityObject:BodyArea():GetArea()
    local pos = entityObject:GetGridPosition()
    local listTrapAll_Work = {}
    local listTrapSkillResult = {}
    for _, area in ipairs(areas) do
        local listWork, listResult = self:_TriggerTrapAtPos(pos + area, entityObject, triggerOrigin)
        table.appendArray(listTrapAll_Work, listWork)
        table.appendArray(listTrapSkillResult, listResult)
    end
    return listTrapAll_Work, listTrapSkillResult
end

---触发目标位置的机关 逻辑
---@param pos Vector3 目标位置
---@param target Entity 触发单位
---@return table<int, Entity> 触发的机关entity列表
function TrapServiceLogic:_TriggerTrapAtPos(position, target, triggerOrigin)
    ---@type SortedArray
    local sortLevel = SortedArray:New(Algorithm.COMPARE_GREATER, nil)
    local listTrapFind = {}
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local listTrap = utilSvc:GetTrapsAtPos(position)
    for _, value in ipairs(listTrap) do
        ---@type Entity
        local entityTrap = value
        ---@type TrapComponent
        local trapCmp = entityTrap:Trap()
        local triggerException = trapCmp:GetTriggerException()
        local isException = table.icontains(triggerException, triggerOrigin)
        ---TODO 因为是否销毁及销毁时机可能不统一 暂时不支持有AI的机关执行触发技能流程 待完善
        local nTrapType = trapCmp:GetTrapType()
        local nCanSelect = self._trapTargetSelector:CanSelectTarget(entityTrap, target)
        local bSelect = false

        if not isException and nCanSelect then
            if nTrapType == TrapType.GroudTrigger then
                bSelect = true
            end
        end
        ---怪物走格子只触发伤害类型的机关
        if triggerOrigin == TrapTriggerOrigin.MonsterGridMove then
            if trapCmp:GetTriggerSkillType() and trapCmp:GetTriggerSkillType() ~= TrapSkillType.Attack then
                bSelect = false
            end
        end
        ---这种不会被触发
        local onlyViewTrap = self:IsViewTrapLevel(trapCmp:GetTrapLevel())
        if onlyViewTrap then
            bSelect = false
        end
        if bSelect then
            --同level只会有一个
            local level = trapCmp:GetTrapLevel()
            sortLevel:Insert(level)
            listTrapFind[level] = entityTrap
        end
    end

    local trapListWork = {}
    local trapSkillResults = {}
    for i = 1, sortLevel:Size() do
        ---@type Entity
        local entityTrap = listTrapFind[sortLevel:GetAt(i)]
        if entityTrap and not entityTrap:HasDeadMark() then
            --触发当前机关 会同步触发同组机关
            local triggerTraps, triggerResults = self:CalcTrapTriggerSkill(entityTrap, target)
            if triggerTraps then
                for _, e in ipairs(triggerTraps) do
                    trapListWork[#trapListWork + 1] = e
                end
                for i, v in ipairs(triggerResults) do
                    trapSkillResults[#trapSkillResults + 1] = v
                end
            end
        end
    end

    return trapListWork, trapSkillResults
end

---触发特定位置上炸弹的触发技能
function TrapServiceLogic:TriggerBomb(pos, defender)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local trapEntities = trapGroup:GetEntities()
    for _, e in ipairs(trapEntities) do
        ---@type Entity
        local trapEntity = e
        if not trapEntity:HasDeadMark() then
            ---@type TrapComponent
            local trapCmpt = trapEntity:Trap()
            if trapCmpt:GetTrapType() == TrapType.BombByHitBack and trapEntity:GetGridPosition() == pos then
                self:CalcTrapTriggerSkill(trapEntity, defender)
                return trapEntity
            end
        end
    end
end

function TrapServiceLogic:IsTrapFlushable(layer)
    return self._flushLayer[layer]
end

function TrapServiceLogic:DamageTrap(curHP, targetID)
end

---是否有炸弹
function TrapServiceLogic:HasLiveBomb(pos)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local trapEntities = trapGroup:GetEntities()
    for _, e in ipairs(trapEntities) do
        ---@type Entity
        local trapEntity = e
        if not trapEntity:HasDeadMark() then
            ---@type TrapComponent
            local trapCmpt = trapEntity:Trap()
            if trapCmpt:GetTrapType() == TrapType.BombByHitBack then
                if pos then
                    if trapEntity:GetGridPosition() == pos then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end

    return false
end

function TrapServiceLogic:CanCastTrapSkill(trapEntity)
    ---@type AttributesComponent
    local attributesComponent = trapEntity:Attributes()
    local power = attributesComponent:GetAttribute("TrapPower")
    local skillCount = attributesComponent:GetAttribute("SkillCount")

    return power > 0 and skillCount > 0
end

function TrapServiceLogic:GetTrapActiveSkillList(trapEntity)
    ---@type TrapComponent
    local trapCmpt = trapEntity:Trap()
    local skillList = trapCmpt:GetActiveSkillID()
    return skillList
end

---@param nTrapType TrapType
---@param nGroupID number
---通过TrapType来查找对应的TrapEntity列表   ---如果nGroupID非空，则会过滤特定GroupID的机关
function TrapServiceLogic:FindTrapByType(nTrapType, nGroupID)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)

    local listReturn = {}
    local listTraps = trapGroup:GetEntities()
    for i = 1, #listTraps do
        local trap = listTraps[i]
        if trap and not trap:HasDeadMark() then
            ---@type TrapComponent
            local trapComponent = trap:Trap()
            if trapComponent and trapComponent:GetTrapType() == nTrapType then
                local bFind = true
                if nGroupID and trapComponent:GetGroupID() ~= nGroupID then
                    bFind = false
                end
                if bFind then
                    table.insert(listReturn, trap)
                end
            end
        end
    end

    return listReturn
end

---@param findPos Vector2
---@return number[]
function TrapServiceLogic:FindTrapIDByPos(findPos)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)

    local listIDRet = {}
    local listTraps = trapGroup:GetEntities()
    for i = 1, #listTraps do
        local trap = listTraps[i]
        if trap and not trap:HasDeadMark() then
            local pos = trap:GetGridPosition()
            ---@type BodyAreaComponent
            local bodyArea = trap:BodyArea()
            local bodyAreaList = bodyArea:GetArea()
            for _, area in ipairs(bodyAreaList) do
                if (area.x + pos.x) == findPos.x and (area.y + pos.y) == findPos.y then
                    ---@type TrapComponent
                    local trapComponent = trap:Trap()
                    if trapComponent and trapComponent:GetTrapID() then
                        table.insert(listIDRet, trapComponent:GetTrapID())
                    end
                end
            end
        end
    end
    return listIDRet
end

---@param findPos Vector2
---@return number[]
function TrapServiceLogic:FindTrapByPos(findPos)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)

    local listIDRet = {}
    local listTraps = trapGroup:GetEntities()
    for i = 1, #listTraps do
        local trap = listTraps[i]
        if trap and not trap:HasDeadMark() then
            local pos = trap:GetGridPosition()
            ---@type BodyAreaComponent
            local bodyArea = trap:BodyArea()
            local bodyAreaList = bodyArea:GetArea()
            for _, area in ipairs(bodyAreaList) do
                if (area.x + pos.x) == findPos.x and (area.y + pos.y) == findPos.y then
                    ---@type TrapComponent
                    local trapComponent = trap:Trap()
                    if trapComponent and trapComponent:GetTrapID() then
                        table.insert(listIDRet, trap:GetID())
                    end
                end
            end
        end
    end
    return listIDRet
end

---@return Vector2
function TrapServiceLogic:FindTrapPosByTrapID(trapID, canMove, monsterEntity)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local listPosRet = {}
    local listTraps = trapGroup:GetEntities()
    for i = 1, #listTraps do
        local trap = listTraps[i]
        if trap and not trap:HasDeadMark() then
            ---@type TrapComponent
            local trapComponent = trap:Trap()
            if trapComponent and trapComponent:GetTrapID() == trapID then
                local pos = trap:GetGridPosition()
                ---@type BodyAreaComponent
                local bodyArea = trap:BodyArea()
                local bodyAreaList = bodyArea:GetArea()
                for _, area in ipairs(bodyAreaList) do
                    local pos = Vector2(pos.x + area.x, pos.y + area.y)
                    if canMove then
                        if utilDataSvc:IsMonsterCanTel2TargetPos(monsterEntity, pos) then
                            table.insert(listPosRet, pos)
                        end
                    else
                        table.insert(listPosRet, pos)
                    end
                end
            end
        end
    end
    return listPosRet
end

function TrapServiceLogic:FindTrapByTrapID(trapID)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local listRet = {}
    local listTraps = trapGroup:GetEntities()
    for i = 1, #listTraps do
        local trap = listTraps[i]
        if trap and not trap:HasDeadMark() then
            ---@type TrapComponent
            local trapComponent = trap:Trap()
            if trapComponent and trapComponent:GetTrapID() == trapID then
                table.insert(listRet,trap:GetID())
            end
        end

    end
    return listRet
end

function TrapServiceLogic:FindTrapByTrapIDAndRange(trapID,range)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local listRet = {}
    local listTraps = trapGroup:GetEntities()
    for i = 1, #listTraps do
        local trap = listTraps[i]
        if trap and not trap:HasDeadMark() then
            ---@type TrapComponent
            local trapComponent = trap:Trap()
            if trapComponent and trapComponent:GetTrapID() == trapID then
                local pos = trap:GetGridPosition()
                ---@type BodyAreaComponent
                local bodyArea = trap:BodyArea()
                local bodyAreaList = bodyArea:GetArea()
                for _, area in ipairs(bodyAreaList) do
                    local newPos = Vector2(pos.x + area.x, pos.y + area.y)
                    if table.Vector2Include(range,newPos) then
                        table.insert(listRet,trap:GetID())
                    end
                end
            end
        end
    end
    return listRet
end

--召唤者的机关是否被怪物或玩家踩住
function TrapServiceLogic:IsTrapCovered(trapID, petPstId)
    local ownerEntityID = nil
    if petPstId then
        ---@type Entity
        local petEntity = self._world:Player():GetPetEntityByPetPstID(petPstId)
        if petEntity then
            ownerEntityID = petEntity:GetID()
        end
    end

    local trapEntitys = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:TrapID():GetTrapID() == trapID then
            if not ownerEntityID then
                table.insert(trapEntitys, e)
            elseif e:HasSummoner() then
                local summonEntityID = e:Summoner():GetSummonerEntityID()
                ---@type Entity
                local summonEntity = e:GetSummonerEntity()
                --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
                if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                    summonEntityID = summonEntity:GetSuperEntity():GetID()
                end
                if summonEntityID == ownerEntityID then
                    table.insert(trapEntitys, e)
                end
            end
        end
    end

    --场上无机关时，也需要返回被覆盖
    if #trapEntitys == 0 then
        return true
    end

    local trapEntity = trapEntitys[1]
    local pos = trapEntity:GetGridPosition()

    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es =
    boardCmpt:GetPieceEntities(
        pos,
        function(e)
            return e:HasTeam() or e:HasMonsterID()
        end
    )

    --没有被覆盖
    if #es == 0 then
        return false
    end

    return true
end

---添加逻辑死亡标记，并结算死亡技
---@param entity Entity
function TrapServiceLogic:DoTrapFeatureDead(entity)
    ---@type TrapComponent
    local trapCmpt = entity:Trap()
    if not trapCmpt then
        return
    end

    ---如果已经挂上过逻辑死亡标记，不用再挂了
    if entity:HasDeadMark() then
        return
    end

    entity:AddDeadMark()

    -- 清除阻挡
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local pos = entity:GetGridPosition()
    boardService:RemoveEntityBlockFlag(entity, pos)

    entity:BuffComponent():SetActive(false)
    --移除机关缓存
    self:RemoveTrapFromBoardComponent(pos, entity)

    return entity:DeadMark()
end

function TrapServiceLogic:GetOnlyViewTrapLayer()
    return self._onlyViewTrapLayer
end

function TrapServiceLogic:IsViewTrapLevel(level)
    return self._onlyViewTrapLayer == level
end

function TrapServiceLogic:GetTotalAuraRangeByGroupID(auraGroupID)
    ---@type Vector2[]
    local totalRange = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local trapEntities = trapGroup:GetEntities()
    for _, e in ipairs(trapEntities) do
        ---@type Entity
        local trapEntity = e
        if not trapEntity:HasDeadMark() then
            ---@type TrapComponent
            local trapCmpt = trapEntity:Trap()
            if trapCmpt:GetTrapType() == TrapType.Auras and auraGroupID == trapCmpt:GetAuraGroupID() then
                local auraRange = trapCmpt:GetAuraRange()
                for _, pos in ipairs(auraRange) do
                    if not table.Vector2Include(totalRange, pos) then
                        table.insert(totalRange, pos)
                    end
                end
            end
        end
    end
    return totalRange
end

function TrapServiceLogic:AddAuraRange(groupID, range)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    if not boardEntity:HasAuraRange() then
        return
    end

    ---@type AuraRangeComponent
    local auraRangeCmpt = boardEntity:AuraRange()
    auraRangeCmpt:AddRange(groupID, range)
end

function TrapServiceLogic:RemoveAuraRange(groupID, range)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    if not boardEntity:HasAuraRange() then
        return
    end

    ---@type AuraRangeComponent
    local auraRangeCmpt = boardEntity:AuraRange()
    auraRangeCmpt:RemoveRange(groupID, range)
end

function TrapServiceLogic:GetAuraSuperposedCount(groupID, pos)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    if not boardEntity:HasAuraRange() then
        return
    end

    ---@type AuraRangeComponent
    local auraRangeCmpt = boardEntity:AuraRange()
    return auraRangeCmpt:GetAuraSuperposedCount(groupID, pos)
end

---获取机关的召唤机关数量
---@param entity Entity
---@return number
function TrapServiceLogic:GetSummonTrapCount(entity)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local count = 0
    for _, trap in ipairs(trapGroup:GetEntities()) do
        if trap and not trap:HasDeadMark() then
            ---@type SummonerComponent
            local summonerCmpt = trap:Summoner()
            if summonerCmpt and summonerCmpt:GetSummonerEntityID() == entity:GetID() then
                count = count + 1
            end
        end
    end
    return count
end

---检查机关的召唤机关数量是否达到上限
---@param entity Entity
function TrapServiceLogic:IsSummonCountLimit(entity)
    ---@type AttributesComponent
    local attributesComponent = entity:Attributes()
    local limitCount = attributesComponent:GetAttribute("SummonTrapLimit")
    --光灵不具备SummonTrapLimit属性，会返回nil
    if not limitCount or limitCount == 0 then
        return false
    end

    local curCount = self:GetSummonTrapCount(entity)
    if curCount < limitCount then
        return false
    end

    return true
end

--region PrismEffectTrap
function TrapServiceLogic:HasPrismEffectTrap(pos)
    -- local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    -- local trapEntities = trapGroup:GetEntities()

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local trapEntities = utilSvc:GetTrapsAtPos(pos)

    for _, e in ipairs(trapEntities) do
        ---@type Entity
        local trapEntity = e
        ---@type TrapComponent
        local trapCmpt = trapEntity:Trap()
        if trapCmpt:IsPrismGrid() and trapCmpt:GetCustomPrismGridScopeType() then
            if trapEntity:GetGridPosition() == pos then
                return true
            end
        end
    end

    return false
end
--endregion PrismEffectTrap
