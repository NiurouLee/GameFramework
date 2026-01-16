require("base_ins_r")
---@class PlayPetMinosGhostDamageInstruction: BaseInstruction
_class("PlayPetMinosGhostDamageInstruction", BaseInstruction)
PlayPetMinosGhostDamageInstruction = PlayPetMinosGhostDamageInstruction

function PlayPetMinosGhostDamageInstruction:Constructor(paramList)
    self._ghostEffectID = tonumber(paramList["ghostEffectID"])
    self._ghostAttackWaitTime = tonumber(paramList["ghostAttackWaitTime"])
    self._ghostLineEffectID = tonumber(paramList["ghostLineEffectID"])
    self._ghostHitEffectID = tonumber(paramList["ghostHitEffectID"])
    self._hitAnimName = paramList["hitAnimName"] or "Hit"
    self._lineSpeed = tonumber(paramList["lineSpeed"])
    self._ghostAttackAudioID = tonumber(paramList["ghostAttackAudioID"])
    self._ghostAttackAudioWaitTime = tonumber(paramList["ghostAttackAudioWaitTime"])
    self._ghostLineOffsetX =  tonumber(paramList["ghostLineOffsetX"])
    self._ghostLineOffsetY =  tonumber(paramList["ghostLineOffsetY"])
    self._ghostLineOffsetZ =  tonumber(paramList["ghostLineOffsetZ"])
end
function PlayPetMinosGhostDamageInstruction:GetCacheAudio()
    local t= {}
    if self._ghostAttackAudioID and self._ghostAttackAudioID > 0 then
        table.insert(t,self._ghostAttackAudioID)
    end
    return t
end

function PlayPetMinosGhostDamageInstruction:GetCacheResource()
    local t = {}
    if self._ghostEffectID and self._ghostEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._ghostEffectID].ResPath, 1 })
    end
    if self._ghostLineEffectID and self._ghostLineEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._ghostEffectID].ResPath, 1 })
    end
    if self._ghostHitEffectID and self._ghostHitEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._ghostEffectID].ResPath, 1 })
    end

    return t
end
---@param casterEntity Entity
function PlayPetMinosGhostDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    self._world =world
    ---@type EffectService
    self._effectSvc = self._world:GetService("Effect")
    ---@type PlaySkillInstructionService
    self._playSkillInsSvc = self._world:GetService("PlaySkillInstruction")
    ---@type Entity[]
    self._attackGhostEntityList = {}
    self._waitTaskID = {}
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultPetMinosGhostDamage[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.PetMinosGhostDamage)
    self._skillID = skillEffectResultContainer:GetSkillID()
    self.casterEntity= casterEntity
    if not results then
        return
    end
    ---@type SkillEffectResultPetMinosGhostDamage
    local result = results[1]
    if not result then
        return
    end
    local hostPet = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        hostPet = cSuperEntity:GetSuperEntity()
    end
    local petRenderCmpt = nil
    local usedPosList = {}
    if hostPet then
        petRenderCmpt = hostPet:PetRender()
        if petRenderCmpt then
            usedPosList = petRenderCmpt:GetPetMinosGhostUsedPosList()
        end
    end

    local centerPos = result:GetCastCenterPos()
    local movePath = result:GetCurMovePath()
    local damageResults = result:GetDamageResults()
    local ghostPos = centerPos
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local bFind = false
    local posUsed = false
    if table.Vector2Include(usedPosList,centerPos) then
        posUsed = true
    end
    if not posUsed and not utilData:IsPosBlock(centerPos,BlockFlag.MonsterLand) and not table.Vector2Include(movePath,centerPos) then
        ghostPos = centerPos
        bFind = true
    end
    if not bFind then
        for i = 1,8 do
            ---@type Vector2[]
            local ringPosList = ComputeScopeRange.ComputeRange_SquareRing(centerPos,1,i)
            for _, newPos in ipairs(ringPosList) do
                local newPosUsed = false
                if table.Vector2Include(usedPosList,newPos) then
                    newPosUsed = true
                end
                if not newPosUsed and not utilData:IsPosBlock(newPos,BlockFlag.MonsterLand) and not table.Vector2Include(movePath,newPos) then
                    ghostPos = newPos
                    bFind = true
                    break
                end
            end
            if bFind then
                break
            end
        end
    end
    if damageResults and #damageResults > 0 then
        if petRenderCmpt then
            petRenderCmpt:RecordPetMinosGhostUsedPos(ghostPos)--记录使用位置，避免重叠
        end
        local damageResult = damageResults[1] --需求只有一个目标
        local targetID = damageResult:GetTargetID()
        ---@type Entity
        local targetEntity= self._world:GetEntityByID(targetID)
        local targetPos = targetEntity:GetGridPosition()
        local dir =  targetPos - ghostPos
        local ghostEntity = self._effectSvc:CreateCommonGridEffect(self._ghostEffectID,ghostPos,dir)
        self._playSkillInsSvc:PlayAttackAudio(self._ghostAttackAudioWaitTime,casterEntity,self._ghostAttackAudioID)
        table.insert(self._attackGhostEntityList,ghostEntity)
        ---@type Vector3
        local lineEffectPos =ghostEntity:View():GetGameObject().transform:TransformPoint(Vector3(self._ghostLineOffsetX,self._ghostLineOffsetY,self._ghostLineOffsetZ))
        local ghostAttackTaskID = TaskManager:GetInstance():CoreGameStartTask(
                self.PlayBeHit,
                self,
                ghostEntity,
                targetEntity,
                self._ghostLineEffectID,
                self._ghostHitEffectID,
                damageResult,
                self._ghostAttackWaitTime,lineEffectPos)
        table.insert(self._waitTaskID,ghostAttackTaskID)
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(self._waitTaskID) do
        YIELD(TT)
    end
    if petRenderCmpt then
        petRenderCmpt:ClearPetMinosGhostUsedPos(ghostPos)--删除记录的使用位置
    end
end
---@param damageResult SkillDamageEffectResult
---@param targetEntity Entity
function PlayPetMinosGhostDamageInstruction:PlayBeHit(TT,casterEntity,targetEntity,lineEffectID,hitEffectID,damageResult,waitTime,casterPos)
    if waitTime > 0 then
        YIELD(TT,waitTime)
    end
    local targetPos = targetEntity:GetPosition()

    local holderTf = targetEntity:View().ViewWrapper.Transform

    ---@type UnityEngine.Transform
    local bindTf = GameObjectHelper.FindChild(holderTf, "Hit")
    if bindTf then
        targetPos = bindTf.position
    end
    local dis = Vector3.Distance(casterPos, targetPos)
    local dir = targetPos - casterPos


    if dis > 1.4 then
        local effectEntity = self._effectSvc:CreatePositionEffect(lineEffectID, casterPos)
        effectEntity:SetDirection(dir)
        local go = effectEntity:View():GetGameObject()
        --go.transform.forward = dir
        ---@type DG.Tweening.Tweener
        local dotween = go.transform:DOMove(targetPos, self._lineSpeed / 1000.0, false):OnComplete(
            function()
                go:SetActive(false)
                self._world:DestroyEntity(effectEntity)
            end
        )
        if self._flyEaseType then
            local easyType = DG.Tweening.Ease[self._flyEaseType]
            dotween:SetEase(easyType)
        end
        YIELD(TT,self._lineSpeed)
    end
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(1)
    local damageGridPos = damageResult:GetGridPos()
    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
                                       :SetHandleBeHitParam_CasterEntity(self.casterEntity)
                                       :SetHandleBeHitParam_TargetEntity(targetEntity)
                                       :SetHandleBeHitParam_HitAnimName(self._hitAnimName)
                                       :SetHandleBeHitParam_HitEffectID(hitEffectID)
                                       :SetHandleBeHitParam_DamageInfo(damageInfo)
                                       :SetHandleBeHitParam_DamagePos(damageGridPos)
                                       :SetHandleBeHitParam_HitTurnTarget(false)
                                       :SetHandleBeHitParam_DeathClear(false)
                                       :SetHandleBeHitParam_IsFinalHit(false)
                                       :SetHandleBeHitParam_SkillID(self._skillID)
                                       :SetHandleBeHitParam_DamageIndex(1)
                                       :SetHandleBeHitParam_HitCasterEntity(casterEntity)
    playSkillService:HandleBeHit(TT, beHitParam)
end
