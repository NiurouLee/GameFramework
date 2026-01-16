--[[------------------------------------------------------------------------------------------
    MirageServiceRender: 幻境下的各种表现函数
]] --------------------------------------------------------------------------------------------

_class("MirageServiceRender", BaseService)
---@class MirageServiceRender:BaseService
MirageServiceRender = MirageServiceRender

function MirageServiceRender:DoMirageShowTraps(TT, eTraps)
    local taskIDList = {}
    if eTraps and table.count(eTraps) > 0 then
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        local taskID = GameGlobal.TaskManager():CoreGameStartTask(trapServiceRender.ShowTraps, trapServiceRender, eTraps)
        table.insert(taskIDList, taskID)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

function MirageServiceRender:DoMiragePlayTrapSkill(TT, eTraps)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    local taskIDList = {}
    if eTraps and table.count(eTraps) > 0 then
        for _, e in ipairs(eTraps) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            local skillID = trapRenderCmpt:GetMoveSkillID()
            if skillID and skillID > 0 then
                local taskId = playSkillService:PlaySkillView(e, skillID)
                if taskId then
                    table.insert(taskIDList, taskId)
                end
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

function MirageServiceRender:DoMiragePlayTrapWarningSkill(TT, eTraps)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    local taskIDList = {}
    if eTraps and table.count(eTraps) > 0 then
        for _, e in ipairs(eTraps) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            local skillID = trapRenderCmpt:GetWarningSkillID()
            if skillID and skillID > 0 then
                local taskId = playSkillService:PlaySkillView(e, skillID)
                if taskId then
                    table.insert(taskIDList, taskId)
                end
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

function MirageServiceRender:DoMiragePlayTrapDieSkill(TT, eTraps)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    local taskIDList = {}
    if eTraps and table.count(eTraps) > 0 then
        for _, e in ipairs(eTraps) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            local skillID = trapRenderCmpt:GetDieSkillID()
            if skillID and skillID > 0 then
                local taskId = playSkillService:PlaySkillView(e, skillID)
                if taskId then
                    table.insert(taskIDList, taskId)
                end
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

function MirageServiceRender:DoMiragePlayBossReturn(TT, bossEntity)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    local taskIDList = {}
    if bossEntity then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local skillID = utilDataSvc:GetMonsterBackSkill(bossEntity)
        if skillID and skillID > 0 then
            local taskId = playSkillService:PlaySkillView(bossEntity, skillID)
            if taskId then
                table.insert(taskIDList, taskId)
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

---清除子弹机关预警
function MirageServiceRender:DoMirageClearWarningArea()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.DamageWarningAreaElement)
    local pubListEntity = group:GetEntities()
    local listEntity = {}
    for _, entity in ipairs(pubListEntity) do
        ---@type DamageWarningAreaElementComponent
        local cmpt = entity:DamageWarningAreaElement()
        ---这里原始实现有问题 会删掉所有的预警区  先简单判断下只删有主的预警区
        if cmpt:GetOwnerEntityID() and cmpt:GetOwnerEntityID() ~= 0 then
            table.insert(listEntity, entity)
        end
    end
    ---@type EntityPoolServiceRender
    local entityPoolSvcR = self._world:GetService("EntityPool")
    for i = 1, #listEntity do
        ---@type Entity
        local entityWork = listEntity[i]
        ---@type DamageWarningAreaElementComponent
        local cmpt = entityWork:DamageWarningAreaElement()
        local entityConfigID = cmpt:GetEntityConfigID()
        if entityConfigID then
            entityPoolSvcR:DestroyCacheEntity(entityWork, entityConfigID)
        else
            entityPoolSvcR:DestroyCacheEntity(entityWork, EntityConfigIDRender.WarningArea)
        end
        cmpt:ClearOwnerEntityID()
    end
end

--region 移动
function MirageServiceRender:DoMiragePlayTeamMove(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2RMirageMoveResult
    local mirageMoveResult = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.MirageMove)
    local walkRes = mirageMoveResult:GetWalkResult()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    self:StartMoveAnimation(teamEntity, true)
    boardServiceRender:RefreshPiece(teamEntity, true, true)

    --移动目标位置
    local walkPos = walkRes:GetWalkPos()
    --取当前的渲染坐标
    local curPos = boardServiceRender:GetRealEntityGridPos(teamEntity)
    teamEntity:AddGridMove(BattleConst.MoveSpeed, walkPos, curPos)

    local walkDir = walkPos - curPos
    teamEntity:SetDirection(walkDir)

    while teamEntity:HasGridMove() do
        YIELD(TT)
    end

    local oldColor = walkRes:GetOldPosColor()
    local gridEntityOld = boardServiceRender:ReCreateGridEntity(oldColor, curPos, false, false, true)
    pieceSvc:SetPieceEntityAnimNormal(gridEntityOld)
    pieceSvc:SetPieceEntityBirth(gridEntityOld)

    local newColor = walkRes:GetNewPosColor()
    local gridEntity = boardServiceRender:ReCreateGridEntity(newColor, walkPos, false, false, true)
    pieceSvc:SetPieceEntityAnimNormal(gridEntity)
    pieceSvc:SetPieceEntityBirth(gridEntity)

    self:_PlayArrivePos(TT, teamEntity, walkRes)

    self:StartMoveAnimation(teamEntity, false)
    boardServiceRender:RefreshPiece(teamEntity, false, true)
end

---@param targetEntity Entity
function MirageServiceRender:StartMoveAnimation(targetEntity, isMove)
    local curVal = targetEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        targetEntity:SetAnimatorControllerBools({ Move = isMove })
    end
end

---@param monsterEntity Entity
---@param walkRes MonsterWalkResult
function MirageServiceRender:_PlayArrivePos(TT, monsterEntity, walkRes)
    ---@type TrapServiceRender
    local trapSvc = self._world:GetService("TrapRender")
    ---触发机关的表现
    local trapResList = walkRes:GetWalkTrapResultList()
    for _, v in ipairs(trapResList) do
        ---@type WalkTriggerTrapResult
        local walkTrapRes = v
        local trapEntityID = walkTrapRes:GetTrapEntityID()
        local trapEntity = self._world:GetEntityByID(trapEntityID)
        ---@type AISkillResult
        local trapSkillRes = walkTrapRes:GetTrapResult()
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = trapSkillRes:GetResultContainer()
        trapEntity:SkillRoutine():SetResultContainer(skillEffectResultContainer)

        trapSvc:PlayTrapTriggerSkill(TT, trapEntity, false, monsterEntity)
    end
end

--endregion 移动

function MirageServiceRender:ClearMiragePick()
    --压暗所有格子
    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")
    piece_service:SetAllPieceDark()
    --高亮玩家周围格子
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local roundGrids = utilData:GetRoundGrid(teamEntity:GetGridPosition())
    for _, gridPos in ipairs(roundGrids) do
        piece_service:SetPieceAnimNormal(gridPos)
    end

    self._world:EventDispatcher():Dispatch(GameEventType.RefreshMiragePickUpGrid, false)
end

function MirageServiceRender:SetMirageStepVisible(show)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---@type HPComponent
    local hpComponent = teamEntity:HP()
    if not hpComponent then
        return
    end

    local sliderEntityId = hpComponent:GetHPSliderEntityID()
    local sliderEntity = self._world:GetEntityByID(sliderEntityId)
    if not sliderEntity then
        return
    end

    local gameObj = sliderEntity:View():GetGameObject()
    local uiView = gameObj:GetComponent("UIView")
    local mirageRoot = uiView:GetGameObject("mirageRoot")
    if mirageRoot then
        mirageRoot:SetActive(show)
    end
end

function MirageServiceRender:RefreshMirageStepNum(stepNum)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---@type HPComponent
    local hpComponent = teamEntity:HP()
    if not hpComponent then
        return
    end

    local sliderEntityId = hpComponent:GetHPSliderEntityID()
    local sliderEntity = self._world:GetEntityByID(sliderEntityId)
    if not sliderEntity then
        return
    end

    local gameObj = sliderEntity:View():GetGameObject()
    local uiView = gameObj:GetComponent("UIView")
    local txtMirageStep = uiView:GetUIComponent("UILocalizationText", "txtMirageStep")
    txtMirageStep:SetText(tostring(stepNum))
end

function MirageServiceRender:GetMirageAutoFightPickUpPos()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local roundGrids = utilData:GetRoundGrid(teamEntity:GetGridPosition())

    ---获取warning的格子
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2RMirageWarningResult
    local mirageWarningResult = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.MirageWarning)
    local warningPosList = mirageWarningResult:GetWarningPosList()

    local roundGridPosList = {}
    for _, grid in ipairs(roundGrids) do
        local pos = Vector2(grid.x, grid.y)
        if not table.icontains(warningPosList, pos) and
            utilData:IsValidPiecePos(pos) and
            not utilData:IsPosBlock(pos, BlockFlag.LinkLine)
        then
            table.insert(roundGridPosList, pos)
        end
    end

    if table.count(roundGridPosList) > 0 then
        ---@type RandomServiceRender
        local randomSvc = self._world:GetService("RandomRender")
        local n = randomSvc:RenderRand(1, table.count(roundGridPosList))
        if roundGridPosList[n] then
            return roundGridPosList[n]
        end
    end
    
    return Vector2.zero
end
