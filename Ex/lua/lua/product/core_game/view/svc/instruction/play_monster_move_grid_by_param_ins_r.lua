require("base_ins_r")

---@class PlayMonsterMoveGridByParamInstruction: BaseInstruction
_class("PlayMonsterMoveGridByParamInstruction", BaseInstruction)
PlayMonsterMoveGridByParamInstruction = PlayMonsterMoveGridByParamInstruction

function PlayMonsterMoveGridByParamInstruction:Constructor(paramList)
    self._attackAnimName = paramList["attackAnimName"]
    self._attackEffectID = tonumber(paramList["attackEffectID"])
    self._attackAudioID = tonumber(paramList["attackAudioID"])
    self._attackAudioWaitTime = tonumber(paramList["attackAudioWaitTime"])

    self._hitDelayTime = tonumber(paramList.hitDelayTime) or 0
    self._hitAnimName = paramList["hitAnimName"] or "Hit"
    self._hitEffectID = tonumber(paramList["hitEffectID"])
end

function PlayMonsterMoveGridByParamInstruction:GetCacheAudio()
    local t = {}
    if self._attackAudioID and self._attackAudioID > 0 then
        table.insert(t, self._attackAudioID)
    end
    return t
end

function PlayMonsterMoveGridByParamInstruction:GetCacheResource()
    local t = {}
    if self._attackEffectID and self._attackEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._attackEffectID].ResPath, 1 })
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._hitEffectID].ResPath, 1 })
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMonsterMoveGridByParamInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    self._effectSvc = self._world:GetService("Effect")
    ---@type PlaySkillInstructionService
    self._playSkillInsSvc = self._world:GetService("PlaySkillInstruction")
    ---@type PlayBuffService
    self._playBuffSvc = self._world:GetService("PlayBuff")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectMonsterMoveGridByParamResult[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.MonsterMoveGridByParam)
    if not results then
        Log.fatal("no results")
        return
    end

    self._skillID = skillEffectResultContainer:GetSkillID()

    ---@type SkillEffectMonsterMoveGridByParamResult
    local result = results[1]
    ---@type MoveGridByParamResult[]
    local walkResultList = result:GetWalkResultList()
    local casterIsDead = result:IsCasterDead()

    self._waitTaskID = {}
    if #walkResultList > 0 then
        self:_DoWalk(TT, casterEntity, walkResultList, casterIsDead)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(self._waitTaskID) do
        YIELD(TT)
    end
end

---@param monsterEntity Entity
---@param walkResultList MoveGridByParamResult[]
function PlayMonsterMoveGridByParamInstruction:_DoWalk(TT, monsterEntity, walkResultList, casterIsDead)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    local moveSpeed = self:_GetMoveSpeed(monsterEntity)

    --走格子
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

        --取当前的渲染坐标
        local curPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)

        monsterEntity:AddGridMove(moveSpeed, walkPos, curPos)

        local walkDir = walkPos - curPos
        monsterEntity:SetDirection(walkDir)

        while monsterEntity:HasGridMove() do
            YIELD(TT)
        end

        self:_PlayArrivePos(TT, monsterEntity, walkRes)
        pieceSvc:SetPieceAnimMoveDone(walkPos)
    end

    for _, v in ipairs(walkResultList) do
        local walkRes = v
        ---@type Vector2
        local walkPos = walkRes:GetWalkPos()
        local newGridType = walkRes:GetNewGridType()
        local gridEntity = boardServiceRender:ReCreateGridEntity(newGridType, walkPos, false, false, true)
        pieceSvc:SetPieceEntityAnimNormal(gridEntity)
        pieceSvc:SetPieceEntityBirth(gridEntity)
    end

    if hasWalkPoint then
        self:StartMoveAnimation(monsterEntity, false)
        boardServiceRender:RefreshPiece(monsterEntity, false, true)
    end

    if casterIsDead then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = self._world:GetService("MonsterShowRender")
        sMonsterShowRender:_DoOneMonsterDead(TT, monsterEntity)
    end
end

---@param monsterEntity Entity
---@param walkRes MoveGridByParamResult
function PlayMonsterMoveGridByParamInstruction:_PlayArrivePos(TT, monsterEntity, walkRes)
    --触发机关的表现
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

    --普攻表现
    ---@type SkillDamageEffectResult
    local damageResult = walkRes:GetAttackResult()
    if damageResult then
        local pos = walkRes:GetWalkPos()

        local targetID = damageResult:GetTargetID()
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(targetID)
        local targetPos = targetEntity:GetGridPosition()
        local dir = targetPos - pos

        --转向
        monsterEntity:SetDirection(dir)
        --攻击动画
        monsterEntity:SetAnimatorControllerTriggers({ self._attackAnimName })
        --攻击特效
        if self._attackEffectID then
            ---@type Entity
            local attackEff = self._effectSvc:CreateEffect(self._attackEffectID, monsterEntity)
        end
        local audioTaskID = self._playSkillInsSvc:PlayAttackAudio(self._attackAudioWaitTime, monsterEntity,
            self._attackAudioID)
        table.insert(self._waitTaskID, audioTaskID)

        YIELD(TT, self._hitDelayTime)

        ---@type PlaySkillService
        local playSkillService = self._world:GetService("PlaySkill")
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        local damageGridPos = damageResult:GetGridPos()
        local hitAnimName = self._hitAnimName
        local hitEffectID = self._hitEffectID
        local skillID = self._skillID

        --目标被击表现
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(monsterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damageInfo)
            :SetHandleBeHitParam_DamagePos(damageGridPos)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(false)
            :SetHandleBeHitParam_SkillID(skillID)
        playSkillService:HandleBeHit(TT, beHitParam)

        self._playBuffSvc:PlayBuffView(TT, NTSE189NormalEachAttackEnd:New(monsterEntity))
    end
end

---@param casterEntity Entity
function PlayMonsterMoveGridByParamInstruction:_GetMoveSpeed(casterEntity)
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

---@param casterEntity Entity
function PlayMonsterMoveGridByParamInstruction:StartMoveAnimation(casterEntity, isMove)
    local curVal = casterEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        casterEntity:SetAnimatorControllerBools({ Move = isMove })
    end
end
