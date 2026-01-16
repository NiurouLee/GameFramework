require("base_ins_r")
---@class PlayTrapMoveAndDamageInstruction: BaseInstruction
_class("PlayTrapMoveAndDamageInstruction", BaseInstruction)
PlayTrapMoveAndDamageInstruction = PlayTrapMoveAndDamageInstruction

function PlayTrapMoveAndDamageInstruction:Constructor(paramList)
    self._time = tonumber(paramList.time)
    self._speed = tonumber(paramList.speed)
    assert(self._time or self._speed, "PlayTrapMoveAndDamage指令需要配置移动参数")

    self._moveAni = paramList.moveAni
    self._moveEffID = tonumber(paramList.moveEffID)
    self._idleAni = paramList.idleAni
    self._idleEffID = tonumber(paramList.idleEffID)
    self._outAni = paramList.outAni
    self._outEffID = tonumber(paramList.outEffID)

    self._attackAnimName = paramList.attackAni
    self._attackEffectID = tonumber(paramList.attackEffectID)
    self._attackAudioID = tonumber(paramList.attackAudioID)
    self._attackAudioWaitTime = tonumber(paramList.attackAudioWaitTime)

    self._hitDelayTime = tonumber(paramList.hitDelayTime) or 0
    self._hitAnimName = paramList.hitAni or "Hit"
    self._hitEffectID = tonumber(paramList.hitEffectID)
end

function PlayTrapMoveAndDamageInstruction:GetCacheResource()
    local t = {}
    if self._moveEffID and self._moveEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._moveEffID].ResPath, 1 })
    end
    if self._idleEffID and self._idleEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._idleEffID].ResPath, 1 })
    end
    if self._outEffID and self._outEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._outEffID].ResPath, 1 })
    end
    if self._attackEffectID and self._attackEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._damageEffID].ResPath, 1 })
    end
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._hitEffectID].ResPath, 1 })
    end
    return t
end

function PlayMonsterMoveGridByParamInstruction:GetCacheAudio()
    local t = {}
    if self._attackAudioID and self._attackAudioID > 0 then
        table.insert(t, self._attackAudioID)
    end
    return t
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTrapMoveAndDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectTrapMoveAndDamageResult
    local skillResult = routineComponent:GetEffectResultByArray(SkillEffectType.TrapMoveAndDamage)

    ---@type EffectService
    self._effSvc = world:GetService("Effect")
    self._skillID = routineComponent:GetSkillID()

    --@type MonsterWalkResult[]
    local walkResultList = skillResult:GetWalkResultList()

    if #walkResultList > 0 then
        self:_DoWalk(TT, casterEntity, walkResultList)
    end

    self._waitTaskID = {}
    ---@type SkillDamageEffectResult
    local damageResult = skillResult:GetDamageResult()
    self:_PlayDamage(TT, casterEntity, damageResult)
    while not TaskHelper:GetInstance():IsAllTaskFinished(self._waitTaskID) do
        YIELD(TT)
    end

    local isOut = skillResult:IsOutBoard()
    if isOut then
        casterEntity:SetAnimatorControllerTriggers({ self._outAni })
        if self._outEffID and self._outEffID ~= 0 then
            self._effSvc:CreateEffect(self._outEffID, casterEntity)
        end
    end

    if isOut or damageResult then
        ---@type TrapServiceRender
        local trapServiceRender = world:GetService("TrapRender")
        trapServiceRender:PlayTrapDieSkill(TT, { casterEntity }, 1)
    end
end

---@param monsterEntity Entity
---@param walkResultList MonsterWalkResult[]
function PlayTrapMoveAndDamageInstruction:_DoWalk(TT, trapEntity, walkResultList)
    ---@type MainWorld
    local world = trapEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")

    local moveSpeed = self._speed
    if self._time then
        moveSpeed = 1 / self._time * 1000
    end

    --走格子
    local hasWalkPoint = false
    if #walkResultList > 0 then
        hasWalkPoint = true
    end

    if hasWalkPoint then
        trapEntity:SetAnimatorControllerTriggers({ self._moveAni })
        if self._moveEffID and self._moveEffID ~= 0 then
            self._effSvc:CreateEffect(self._moveEffID, trapEntity)
        end
    end

    for _, v in ipairs(walkResultList) do
        local walkRes = v
        local walkPos = walkRes:GetWalkPos()

        --取当前的渲染坐标
        local curPos = boardServiceRender:GetRealEntityGridPos(trapEntity)

        trapEntity:AddGridMove(moveSpeed, walkPos, curPos)

        local walkDir = walkPos - curPos
        trapEntity:SetDirection(walkDir)

        while trapEntity:HasGridMove() do
            YIELD(TT)
        end        
    end

    if hasWalkPoint then
        trapEntity:SetAnimatorControllerTriggers({ self._idleAni })
        if self._idleEffID and self._idleEffID ~= 0 then
            self._effSvc:CreateEffect(self._idleEffID, trapEntity)
        end
    end
end

---@param trapEntity Entity
---@param damageResult SkillDamageEffectResult
function PlayTrapMoveAndDamageInstruction:_PlayDamage(TT, trapEntity, damageResult)
    ---@type MainWorld
    local world = trapEntity:GetOwnerWorld()
    if damageResult then
        local targetID = damageResult:GetTargetID()
        ---@type Entity
        local targetEntity = world:GetEntityByID(targetID)

        --攻击动画
        trapEntity:SetAnimatorControllerTriggers({ self._attackAnimName })
        --攻击特效
        if self._attackEffectID then
            ---@type Entity
            local attackEff = self._effSvc:CreateEffect(self._attackEffectID, trapEntity)
        end
        ---@type PlaySkillInstructionService
        local playSkillInsSvc = world:GetService("PlaySkillInstruction")
        local audioTaskID = playSkillInsSvc:PlayAttackAudio(self._attackAudioWaitTime, trapEntity,
            self._attackAudioID)
        table.insert(self._waitTaskID, audioTaskID)

        YIELD(TT, self._hitDelayTime)

        ---@type PlaySkillService
        local playSkillService = world:GetService("PlaySkill")
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        local damageGridPos = damageResult:GetGridPos()
        local hitAnimName = self._hitAnimName
        local hitEffectID = self._hitEffectID
        local skillID = self._skillID

        --目标被击表现
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(trapEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damageInfo)
            :SetHandleBeHitParam_DamagePos(damageGridPos)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(false)
            :SetHandleBeHitParam_SkillID(skillID)
        playSkillService:HandleBeHit(TT, beHitParam)
    end
end
