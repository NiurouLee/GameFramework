--[[----------------------------------------------------------
    ChessPickUpChessPetSystem_Render：战棋点选到我方棋子光灵
]] ------------------------------------------------------------
---@class PickUpChessPetSystem_Render:ReactiveSystem
_class("PickUpChessPetSystem_Render", ReactiveSystem)
PickUpChessPetSystem_Render = PickUpChessPetSystem_Render

---@param world World
function PickUpChessPetSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world World
function PickUpChessPetSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PickUpChessResult)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PickUpChessPetSystem_Render:Filter(entity)
    ---@type PickUpChessResultComponent
    local resCmpt = entity:PickUpChessResult()
    ---@type ChessPickUpTargetType
    local resType = resCmpt:GetChessPickUpResultType()
    if resType == ChessPickUpTargetType.ChessPet then
        return true
    end
    return false
end

---派生的ReactiveSystem执行体
function PickUpChessPetSystem_Render:ExecuteEntities(entities)
    ---清理预览
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ClearChessMonsterPreview()
    chessSvcRender:ClearChessPetPreview()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()

    local changed = resCmpt:IsChessPickUpTargetChanged()
    if not changed then
        ---结束棋子光灵的预览
        self:_FinishChessPetPreview()
        return
    end

    local entityID = resCmpt:GetPickUpChessPetEntityID()
    if not entityID then
        Log.fatal("not find pick chess pet id")
        return
    end

    ---@type Entity
    local chessPetEntity = self._world:GetEntityByID(entityID)
    ---------------------------
    ---这里需要通知UI显示友方血条
    self:_ShowChessPetUIHP(chessPetEntity)
    ---@type ChessPetComponent
    local chessPetCmpt = chessPetEntity:ChessPet()
    local finishTurn = chessPetCmpt:IsChessPetFinishTurn()
    if finishTurn then
        ---回合结束的棋子，需要进预览，但不显示移动范围
        self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 6)
        self._world:EventDispatcher():Dispatch(
            GameEventType.ChessUIStateTransit,
            UIBattleWidgetChessState.FinishTurnOnly
        )

        return
    end

    --通知主状态机切到下个状态（棋子光灵预览）
    local walkRange, attackRange, isRecover = self:_CalcChessPetWalkRange(entityID)
    resCmpt:SetChessPetWalkRange(walkRange)
    resCmpt:SetChessPetAttackRange(attackRange)
    resCmpt:SetSkillIsRecover(isRecover)

    chessSvcRender:ShowChessPetPreviewRange(walkRange, attackRange, {}, {}, isRecover)

    --选中特效
    chessSvcRender:RefreshChessPetSelectStateRender(chessPetEntity, true)

    self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 6)
    self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.Skip)
end

function PickUpChessPetSystem_Render:_FinishChessPetPreview()
    ---清理预览
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:ClearAllChessUnitPreview()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    resCmpt:ResetChessPickUp()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()
    if stateId == GameStateID.PreviewChessPet then
        self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish, 3)
    elseif stateId == GameStateID.PickUpChessPet then
        self._world:EventDispatcher():Dispatch(GameEventType.PickUpChessPetFinish, 5)
    end
end

---
function PickUpChessPetSystem_Render:_CalcChessPetWalkRange(entityID)
    ---@type Entity
    local entity = self._world:GetEntityByID(entityID)
    ---@type GridLocationComponent
    local gridLocCmpt = entity:GridLocation()
    local curPos = gridLocCmpt:GetGridPos()
    ---@type ChessPetComponent
    local chessPetCmpt = entity:ChessPet()
    local chessPetID = chessPetCmpt:GetChessPetID()
    local blockData = chessPetCmpt:GetChessPetBlockData()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local chessPetList, chessPetPosList = utilScopeSvc:SelectAllChessPet()

    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgSvc:GetChessPetConfigData()
    local bodyArea = chessPetConfigData:GetChessPetArea(chessPetID)

    --buff修改移动步数
    local walkStep = chessPetConfigData:GetChessPetWalkStep(chessPetID)

    local dirs = {Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)}
    --每一步的移动
    local eachMovePosList = {}
    --移动完的点（用于显示的，对于四格棋子并不是真实的移动范围）
    local walkRange = {}
    --真实的移动范围，用于计算的。用于解决四格棋子的范围计算
    local walkRangeCalc = {}

    for i, area in ipairs(bodyArea) do
        local posWork = curPos + area
        table.insert(walkRange, posWork)
    end
    table.insert(walkRangeCalc, curPos)

    for i = 1, walkStep do
        eachMovePosList[i] = {}
        local curMovePosList = {}
        local lastMovePosList = {}
        if i == 1 then
            lastMovePosList = {curPos}
        else
            lastMovePosList = eachMovePosList[i - 1]
        end

        --上一轮成功移动的点再向四方向移动
        for _, pos in ipairs(lastMovePosList) do
            for _, dir in ipairs(dirs) do
                local moveTargetPos = pos + dir
                self:_OnCalcWalkRangeBodyArea(
                    bodyArea,
                    moveTargetPos,
                    blockData,
                    curMovePosList,
                    walkRange,
                    walkRangeCalc,
                    chessPetPosList,
                    entity
                )
            end
        end

        for _, pos in ipairs(curMovePosList) do
            if not table.intable(walkRange, pos) then
                table.insert(eachMovePosList[i], pos)
                if not table.intable(chessPetPosList, pos) then
                    table.insert(walkRange, pos)
                end
            end
        end
    end

    local canMoveCenterPosList = {}
    if table.count(bodyArea) == 1 then
        table.appendArray(canMoveCenterPosList, walkRange)
    else
        table.appendArray(canMoveCenterPosList, walkRangeCalc)
    end

    local hasTargetAttackRange, isRecover = self:_OnCalcAttackRange(entity, canMoveCenterPosList)

    return walkRange, hasTargetAttackRange, isRecover
end

---
function PickUpChessPetSystem_Render:_OnCalcWalkRangeBodyArea(
    bodyArea,
    moveTargetPos,
    blockData,
    curMovePosList,
    walkRange,
    walkRangeCalc,
    chessPetPosList,
    entity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local isBlocked = false
    if table.count(bodyArea) == 1 then
        --单格
        isBlocked = utilDataSvc:IsPosBlock(moveTargetPos, blockData)
        -- local isPosBlockWithEntityRace = utilDataSvc:IsPosBlockWithEntityRace(moveTargetPos, blockData, entity)
        --可能是被己方棋子阻挡
        if isBlocked or isPosBlockWithEntityRace then
            if table.intable(chessPetPosList, moveTargetPos) then
                isBlocked = false
            end
        end

        if isBlocked == false then
            table.insert(curMovePosList, moveTargetPos)
            if not table.intable(walkRangeCalc, moveTargetPos) then
                table.insert(walkRangeCalc, moveTargetPos)
            end
        end
    elseif table.count(bodyArea) > 1 then
        --多格
        local moveAreaPosList = {}
        for _, area in ipairs(bodyArea) do
            local posWork = area + moveTargetPos
            isBlocked = utilDataSvc:IsPosBlock(posWork, blockData)
            local isPosBlockWithEntityRace = utilDataSvc:IsPosBlockWithEntityRace(moveTargetPos, blockData, entity)
            --不在选中的格子中 and 阻挡    (选中格子被阻挡表示是自己身形下)
            if not table.intable(walkRange, posWork) and (isBlocked or isPosBlockWithEntityRace) then
                break
            end

            --在身形下的点是被阻挡的 这里需要重置
            isBlocked = false
            table.insert(moveAreaPosList, posWork)
        end

        if isBlocked == false then
            table.appendArray(curMovePosList, moveAreaPosList)
            if not table.intable(walkRangeCalc, moveTargetPos) then
                table.insert(walkRangeCalc, moveTargetPos)
            end
        end
    end
end

---计算出有目标在的攻击范围
function PickUpChessPetSystem_Render:_OnCalcAttackRange(entity, walkRange)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ChessPetComponent
    local chessPetCmpt = entity:ChessPet()
    local attackSkill = chessPetCmpt:GetPreviewSkillID()
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = cfgSvc:GetSkillConfigData(attackSkill, entity)

    local isRecover = false
    local skillEffectArray = skillConfigData:GetSkillEffect()
    for _, skillEffect in ipairs(skillEffectArray) do
        if skillEffect:GetEffectType() == SkillEffectType.AddBlood then
            isRecover = true
            break
        end
    end

    local skillTargetType = skillConfigData:GetSkillTargetType()
    local skillTargetTypeParam = skillConfigData:GetSkillTargetTypeParam()

    local selector = SkillScopeTargetSelector:New(self._world)

    --攻击范围
    local attackRange = {}
    local skillTargetIDs = {}
    for _, walkPos in ipairs(walkRange) do
        ---@type SkillScopeResult
        local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, walkPos, entity)
        local scopeList = scopeResult:GetAttackRange()
        local targetIDs =
            selector:DoSelectSkillTarget(entity, skillTargetType, scopeResult, attackSkill, skillTargetTypeParam)

        for _, pos in ipairs(scopeList) do
            if not table.intable(attackRange, pos) then
                table.insert(attackRange, pos)
            end
        end

        --自己不添加进目标可选格子（钩子）
        for _, targetID in ipairs(targetIDs) do
            if not table.intable(skillTargetIDs, targetID) and targetID ~= entity:GetID() then
                table.insert(skillTargetIDs, targetID)
            end
        end
    end

    local hasTargetAttackRange = {}
    for _, targetID in ipairs(skillTargetIDs) do
        local targetEntity = self._world:GetEntityByID(targetID)
        local bodyAreaList = targetEntity:BodyArea():GetArea()
        local gridPos = targetEntity:GridLocation():GetGridPos()
        for _, bodyArea in ipairs(bodyAreaList) do
            local workPos = gridPos + bodyArea
            if table.intable(attackRange, workPos) then
                table.insert(hasTargetAttackRange, workPos)
            end
        end
    end

    return hasTargetAttackRange, isRecover
end

function PickUpChessPetSystem_Render:_ShowChessPetUIHP(entity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type HPComponent
    local HPCmpt = entity:HP()
    local maxHP = HPCmpt:GetMaxHP()
    local HP = HPCmpt:GetRedHP()
    local hpPercent = HP / maxHP
    local shieldValue = HPCmpt:GetShieldValue()
    local templateID
    local hpBarType
    local elementType
    local sepHPList = entity:HP():GetHPLockSepList()

    if entity:MonsterID() then
        templateID = entity:MonsterID():GetMonsterID()
        if entity:HasBoss() then
            if entity:MonsterID():IsEliteMonster() then
                hpBarType = HPBarType.EliteBoss
            else
                hpBarType = HPBarType.Boss
            end
        else
            if entity:MonsterID():IsEliteMonster() then
                hpBarType = HPBarType.EliteMonster
            else
                hpBarType = HPBarType.NormalMonster
            end
        end
        elementType = utilDataSvc:GetEntityAttributeByName(entity,"Element")
    elseif entity:HasChessPet() then
        templateID = entity:ChessPet():GetChessPetID()
        local cfgChessPet = Cfg.cfg_chesspet[templateID]
        elementType = cfgChessPet.ElementType
        hpBarType = HPBarType.ChessPet
    end
    local greyVal = utilDataSvc:GetEntityBuffValue(entity,"GreyHPValue") or 0

    local hpEnergyBuffEffectType = utilDataSvc:GetEntityBuffValue(entity, "HPEnergyBuffEffectType")
    local hpEnergyVal = 0
    if hpEnergyBuffEffectType then
        hpEnergyVal = utilDataSvc:GetBuffLayer(entity, hpEnergyBuffEffectType)
    end
    ---@class UIBossHPInfoData
    local info = {
        pstId = entity:GetID(),
        tplId = templateID,
        HPBarType = hpBarType,
        sepHPList = sepHPList,
        entity = entity,
        percent = hpPercent,
        hP = HP,
        HP = HP,
        maxHP = maxHP,
        shieldValue = shieldValue,
        curElement = elementType,
        attack = utilDataSvc:GetEntityAttack(entity) or 0, -- 如果不判断，GetAttack内部会nil * number
        greyVal = greyVal,
        hpEnergyVal = hpEnergyVal
    }
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreviewMonsterReplaceHPBar, info)
end
