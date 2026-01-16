--[[------------------------------------------------------------------------------------------
    PlayAIService AI行为播放器
]] --------------------------------------------------------------------------------------------

---@class PlayAIService:BaseService
_class("PlayAIService", BaseService)
PlayAIService = PlayAIService

---播放常规流程，怪物行走过程比较特殊，不包含在这个过程里
---@param entityIDList Array 施法者ID队列

function PlayAIService:DoCommonRountine(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type AIRecorderComponent
    local recorderCmpt = renderBoardEntity:AIRecorder()
    local orderList = recorderCmpt:GetOrderList()
    for i, order in ipairs(orderList) do
        recorderCmpt:SetCurrentOrder(order)
        local entityIDList = recorderCmpt:GetAIWalkerIDList()

        local waitTaskList = {}

        ---先普攻
        for _, entityID in ipairs(entityIDList) do
            ---@type Entity
            local casterEntity = self._world:GetEntityByID(entityID)
            ---@type AIResultCollection
            local collection = recorderCmpt:GetAIResultCollection(entityID)
            if collection and collection:HasNormalAttackResult() then
                local resList = collection:GetNormalAttackResultList()
                local taskID =
                GameGlobal.TaskManager():CoreGameStartTask(self._PlayAISkillResultList, self, casterEntity, resList)
                waitTaskList[#waitTaskList + 1] = taskID
            end
        end

        ---等待所有怪物的普攻流程结束
        if #waitTaskList > 0 then
            while not TaskHelper:GetInstance():IsAllTaskFinished(waitTaskList) do
                YIELD(TT)
            end
        end

        entityIDList = recorderCmpt:GetAICasterIDList()
        ---再怪物施法
        for _, entityID in ipairs(entityIDList) do
            ---@type Entity
            local casterEntity = self._world:GetEntityByID(entityID)
            ---@type AIResultCollection
            local collection = recorderCmpt:GetAIResultCollection(entityID)
            if collection and collection:HasSpellResult() then
                local resList = collection:GetSpellResultList()

                ---施法阶段，必须要等上一个的施法过程结束后，才能开始下一个
                local taskID =
                GameGlobal.TaskManager():CoreGameStartTask(self._PlayAISkillResultList, self, casterEntity, resList)
                while not TaskHelper:GetInstance():IsTaskFinished(taskID) do
                    YIELD(TT)
                end

            end
        end
    end
    recorderCmpt:ClearAIRecorder()
end

---播放某个施法者的一组技能
---@param casterEntity Entity
---@param resList AISkillResult[]
function PlayAIService:_PlayAISkillResultList(TT, casterEntity, resList)
    for _, v in ipairs(resList) do
        if not v:IsHadPlay() then
            local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._DoCastSkill, self, casterEntity, v)
            ---单个施法者的普攻是播完一次，再播下一次
            while not TaskHelper:GetInstance():IsTaskFinished(taskID) do
                YIELD(TT)
            end
            v:HadPlay()
        end
    end
end

---播放某个施法者的单次技能
---@param casterEntity Entity
---@param aiSkillResult AISkillResult
function PlayAIService:_DoCastSkill(TT, casterEntity, aiSkillResult)
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = aiSkillResult:GetResultContainer()
    casterEntity:SkillRoutine():SetResultContainer(skillEffectResultContainer)
    casterEntity:SetDirection(aiSkillResult:GetCastSkillDir())
    local aiSkillID = skillEffectResultContainer:GetSkillID()

    --幻象怪物 要使用星灵的技能配置
    ---@type BuffViewComponent
    local buffCmpt = casterEntity:BuffView()
    local petEID = buffCmpt:GetBuffValue("ChangeModelWithPetIndex")
    if petEID then
        local petEntity = self._world:GetEntityByID(petEID)
        aiSkillID = petEntity:SkillInfo():GetNormalSkillID()
        ---@type SkillConfigData
        local skillConfigDataPet = configService:GetSkillConfigData(aiSkillID, casterEntity)

        --为幻影小怪做容错(如果光灵普攻没有攻击效果，但是怪物有攻击逻辑还要用光灵的普攻表现，就要替换普攻表现)
        local needUseNormalAttackView = false
        local skillEffectArray = skillConfigDataPet:GetSkillEffect()
        for _, effect in ipairs(skillEffectArray) do
            if effect:GetEffectType() == SkillEffectType.TransferTarget then
                needUseNormalAttackView = true
                break
            end
        end
        if needUseNormalAttackView then
            --新规则是光灵模版ID+"01"
            local petEntity = self._world:GetEntityByID(petEID)
            aiSkillID = tonumber(petEntity:PetPstID():GetTemplateID() .. "01")
        end
    end

    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(aiSkillID, casterEntity)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray()

    Log.debug(
        "[PlayAI]Entity:",
        casterEntity:GetID(),
        " cast skill:",
        aiSkillID,
        ",frame:",
        UnityEngine.Time.frameCount
    )

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    local waitTaskID = playSkillService:StartSkillRoutine(casterEntity, skillPhaseArray, aiSkillID)
    while not TaskHelper:GetInstance():IsTaskFinished(waitTaskID) do
        YIELD(TT)
    end


    ---播放完技能后，可以播放战棋目标的死亡表现了
    self:_PlayChessPetDead(TT, aiSkillResult)

    Log.debug(
        "[PlayAI]Entity:",
        casterEntity:GetID(),
        " finish cast,skill:",
        aiSkillID,
        ",frame:",
        UnityEngine.Time.frameCount
    )
end

function PlayAIService:PlayParallelSpellResult(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type AIRecorderComponent
    local recorderCmpt = renderBoardEntity:AIRecorder()
    ----@type table<number,table<number,AISkillResult[]>>
    local parallelResultList = recorderCmpt:GetAllParallelSpellResultList()

    for _, aiSkillResultListByCasterID in HelperProxy:GetInstance():pairsByKeys(parallelResultList) do
        local taskList ={}
        for casterEntityID, aiSkillResultList in pairs(aiSkillResultListByCasterID) do
            ---@type Entity
            local monsterEntity = self._world:GetEntityByID(casterEntityID)
            ---施法阶段，必须要等上一个的施法过程结束后，才能开始下一个
            local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(
                    self._PlayAISkillResultList,
                    self,
                    monsterEntity,
                    aiSkillResultList
            )
            table.insert(taskList,taskID)
        end
        while not TaskHelper:GetInstance():IsAllTaskFinished(taskList) do
            YIELD(TT)
        end
    end
end

---主AI的播放，先所有人移动和普攻，再逐个播放技能
function PlayAIService:DoMainAIRountine(TT)
    local waitTaskList = {}
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type AIRecorderComponent
    local recorderCmpt = renderBoardEntity:AIRecorder()
    local orderList = recorderCmpt:GetOrderList()

    self:PlayParallelSpellResult(TT)

    for i, order in ipairs(orderList) do
        recorderCmpt:SetCurrentOrder(order)
        local entityIDList = recorderCmpt:GetAIWalkerIDList()
        ---开始所有人的移动和普攻
        for _, entityID in ipairs(entityIDList) do
            ---@type Entity
            local e = self._world:GetEntityByID(entityID)
            if not e:HasMonsterID() then
                Log.error("DoMainAIRountine() NOT MONSTER!!")
            end
            ---@type AIResultCollection
            local collection = recorderCmpt:GetAIResultCollection(e:GetID())
            local walkResultList = collection:GetWalkResultList()
            local normalResultList = collection:GetNormalAttackResultList()
            local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(
                self._DoWalkAttack,
                self,
                e,
                walkResultList,
                normalResultList
            )
            if taskID > 0 then
                waitTaskList[#waitTaskList + 1] = taskID
            end
        end

        ---等待所有怪物的普攻流程结束
        if #waitTaskList > 0 then
            while not TaskHelper:GetInstance():IsAllTaskFinished(waitTaskList) do
                YIELD(TT)
            end
        end

        entityIDList = recorderCmpt:GetAICasterIDList()
        ---最后怪物施法
        for _, entityID in ipairs(entityIDList) do
            ---@type Entity
            local monsterEntity = self._world:GetEntityByID(entityID)
            ---@type AIResultCollection
            local collection = recorderCmpt:GetAIResultCollection(entityID)
            if collection and collection:HasSpellResult() then
                local resList = collection:GetSpellResultList()
                ---施法阶段，必须要等上一个的施法过程结束后，才能开始下一个
                local taskID =
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._PlayAISkillResultList,
                    self,
                    monsterEntity,
                    resList
                )
                while not TaskHelper:GetInstance():IsTaskFinished(taskID) do
                    YIELD(TT)
                end
            end
        end
    end

    recorderCmpt:ClearAIRecorder()
end

---播放怪物行走和普攻
---@param monsterEntity Entity 怪物Entity
function PlayAIService:_DoWalkAttack(TT, monsterEntity, walkResultList, normalResultList)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local moveSpeed = self:_GetMoveSpeed(monsterEntity)
    ---走格子
    local hasWalkPoint = false
    if #walkResultList > 0 then
        hasWalkPoint = true
    end

    if hasWalkPoint then
        self:StartMoveAnimation(monsterEntity, true)
        boardServiceRender:RefreshPiece(monsterEntity, true, true)
    end

    for _, v in ipairs(walkResultList) do
        local walkRes = v
        local walkPos = walkRes:GetWalkPos()

        ---取当前的渲染坐标
        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        local curPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)

        monsterEntity:AddGridMove(moveSpeed, walkPos, curPos)

        local walkDir = walkPos - curPos
        ---@type BodyAreaComponent
        local bodyAreaCmpt = monsterEntity:BodyArea()
        local areaCount = bodyAreaCmpt:GetAreaCount()
        ---普攻阶段多格的只有四格，以后如果有别的，再处理
        if areaCount == 4 then
            ---取左下位置坐标
            local leftDownPos = Vector2(curPos.x - 0.5, curPos.y - 0.5)
            walkDir = walkPos - leftDownPos
        end

        monsterEntity:SetDirection(walkDir)

        Log.debug("[PlayAI]Entity:", monsterEntity:GetID(), ",CurPos:", curPos, " WalkTo,", walkPos)
        while monsterEntity:HasGridMove() do
            YIELD(TT)
        end

        self:_PlayArrivePos(TT, monsterEntity, walkRes)
    end

    if hasWalkPoint then
        self:StartMoveAnimation(monsterEntity, false)
        boardServiceRender:RefreshPiece(monsterEntity, false, true)
    end

    Log.debug("[PlayAI]Entity:", monsterEntity:GetID(), ",finish walk")
    ---普攻
    self:_PlayAISkillResultList(TT, monsterEntity, normalResultList)
end

---@param monsterEntity Entity
---@param walkRes MonsterWalkResult
function PlayAIService:_PlayArrivePos(TT, monsterEntity, walkRes)
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

        Log.debug(
            "[AIMove] PlayArrivePos() monster=",
            monsterEntity:GetID(),
            " pos=",
            walkRes:GetWalkPos(),
            " play trapid=",
            trapEntity:GetID(),
            " defender=",
            skillEffectResultContainer:GetScopeResult():GetTargetIDs()[1]
        )

        ---@type TrapServiceRender
        local trapSvc = self._world:GetService("TrapRender")
        trapSvc:PlayTrapTriggerSkill(TT, trapEntity, false, monsterEntity)
    end

    local passGrids = walkRes:GetWalkPassedGrid()
    local nt = NTMonsterMoveOneFinish:New(monsterEntity, passGrids, walkRes:GetWalkPos())
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayBuffView(TT, nt)
end

---@param casterEntity Entity
function PlayAIService:_GetMoveSpeed(casterEntity)
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type MonsterConfigData 怪物配置数据
    local configData = cfgSvc:GetMonsterConfigData()

    ---@type MonsterIDComponent
    local monsterIDCmpt = casterEntity:MonsterID()
    local monsterID = monsterIDCmpt:GetMonsterID()

    local speed = configData:GetMonsterSpeed(monsterID)
    speed = speed or 1

    return speed
end

---@param targetEntity Entity
function PlayAIService:StartMoveAnimation(targetEntity, isMove)
    local curVal = targetEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        targetEntity:SetAnimatorControllerBools({ Move = isMove })
    end
end

---播放死亡棋子的死亡表现
---@param TT token
---@param aiSkillResult AISkillResult 技能结果
function PlayAIService:_PlayChessPetDead(TT, aiSkillResult)
    if self._world:MatchType() ~= MatchType.MT_Chess then
        return
    end

    local deadIDList = aiSkillResult:GetAISkillResult_DeadChessList()
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    chessSvcRender:DoChessPetListDeadRender(TT, deadIDList)

    --反击效果
    local resultList = aiSkillResult:GetAISkillResult_AntiChessResultList()
    if resultList then
        for _, v in ipairs(resultList) do
            local targetEntityID = v.entityID
            local skillID = v.skillID
            local skillResult = v.skillResult

            local targetEntity = self._world:GetEntityByID(targetEntityID)

            local configSvc = self._world:GetService("Config")
            local skillConfigData = configSvc:GetSkillConfigData(skillID, targetEntity)
            local skillPhaseArray = skillConfigData:GetSkillPhaseArray()

            targetEntity:SkillRoutine():SetResultContainer(skillResult)

            ---@type PlaySkillService
            local playSkillService = self._world:GetService("PlaySkill")
            playSkillService:_SkillRoutineTask(TT, targetEntity, skillPhaseArray, skillID)
        end
    end
end
