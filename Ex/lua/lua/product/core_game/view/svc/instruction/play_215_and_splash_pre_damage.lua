require("base_ins_r")

---@class Play215AndSplashPreDamageInstruction: BaseInstruction
_class("Play215AndSplashPreDamageInstruction", BaseInstruction)
Play215AndSplashPreDamageInstruction = Play215AndSplashPreDamageInstruction

function Play215AndSplashPreDamageInstruction:Constructor(paramList)
    -- self._startupFxID = tonumber(paramList.startupFxID)
    self._damageStageIndex =tonumber(paramList.damageStageIndex)
    self._splashDamageStageIndex =tonumber(paramList.splashDamageStageIndex)
    self._damageHitEffect = tonumber(paramList.damageHitEffect)
    self._splashHitEffect = tonumber(paramList.splashHitEffect)
    self._damageWaitTime = tonumber(paramList.damageWaitTime or 0 )
    self._beHitAudioID = tonumber(paramList.beHitAudioID)
    self._hitEffectWaitTime = tonumber(paramList.hitEffectWaitTime or 0 )

    self._hitAnimName = paramList.hitAnimName

    self._paramList = paramList
end

function Play215AndSplashPreDamageInstruction:GetCacheAudio()
    local t = {}
    if self._beHitAudioID and self._beHitAudioID > 0 then
        table.insert(t, self._beHitAudioID)
    end
    return t
end

function Play215AndSplashPreDamageInstruction:GetCacheResource()
    local t = {}

    local damageHitEffectPath = self:GetEffectResCacheInfo(self._damageHitEffect) -- 这个cache值可能会再调，最多20下，看同屏最多数量再改
    if damageHitEffectPath then
        table.insert(t, damageHitEffectPath)
    end

    local splashHitEffectPath = self:GetEffectResCacheInfo(self._splashHitEffect)
    if splashHitEffectPath then
        table.insert(t, splashHitEffectPath)
    end

    return t
end

function Play215AndSplashPreDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    self._world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local resContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillDamageEffectResult[]
    local damageResults = resContainer:GetEffectResultsAsArray(SkillEffectType.Damage,self._damageStageIndex)
    ---@type SkillEffectSplashDamageResult[]
    local splashResults = resContainer:GetEffectResultsAsArray(SkillEffectType.SplashDamage,self._splashDamageStageIndex)
    local skillID = resContainer:GetSkillID()
    ---@type PlaySkillService
    self._playSkillService = self._world:GetService("PlaySkill")
    ---@type PlayDamageService
    self._playDamageService = self._world:GetService("PlayDamage")
    ---@type EffectService
    self._effectService = self._world:GetService("Effect")
    local damageShowType = self._world:GetService("PlayDamage"):SingleOrGrid(skillID)
    local isFinalHit = resContainer:IsFinalAttack()
    local taskIDList ={}
    local maxDamageIndex =1
    for i, results in ipairs(damageResults) do
        if results:GetDamageIndex() > maxDamageIndex then
            maxDamageIndex = results:GetDamageIndex()
        end
    end
    for i = 1, maxDamageIndex do
        local playNormalDamageResult = {}
        local playSplashDamageResult = {}
        for _, results in ipairs(damageResults) do
            if results:GetDamageIndex() == i then
                table.insert(playNormalDamageResult,results)
            end
        end
        for _, splashResult in ipairs(splashResults) do
            local splashDamageResults =splashResult:GetDamageResults()
            for _, splashDamageResult in ipairs(splashDamageResults) do
                if splashDamageResult:GetDamageIndex() == i then
                    table.insert(playSplashDamageResult,splashDamageResult)
                end
            end
        end
        local taskIDs = self:_PlayDamageInfo(TT,playNormalDamageResult,playSplashDamageResult,casterEntity,
                isFinalHit and i == maxDamageIndex,skillID,damageShowType)
        table.appendArray(taskIDList,taskIDs)
        if self._damageWaitTime>0 then
            YIELD(TT,self._damageWaitTime)
        end
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

---@param casterEntity Entity
function Play215AndSplashPreDamageInstruction:PlayAudio(casterEntity)
    if self._beHitAudioID  then
        local playingID = AudioHelperController.PlayInnerGameSfx(self._beHitAudioID)
        ---@type EffectHolderComponent
        local effectCpmt = casterEntity:EffectHolder()
        if not effectCpmt then
            casterEntity:AddEffectHolder()
            effectCpmt = casterEntity:EffectHolder()
        end
        effectCpmt:AttachAudioID(self._beHitAudioID, playingID)
    end
end
---@param casterEntity Entity
---@param playSplashDamageResult SkillDamageEffectResult[]
---@param playSplashDamageResult SkillDamageEffectResult[]
function Play215AndSplashPreDamageInstruction:_PlayDamageInfo(TT,playNormalDamageResult,playSplashDamageResult, casterEntity, finalAttack, skillID,damageShowType)

    local casterPos =  casterEntity:GetRenderGridPosition()
    for _, damageResult in ipairs(playNormalDamageResult) do
        local targetID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetID)
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        local damageGridPos = damageResult:GetGridPos()
        self:PlayBeHitEffect(targetEntity,casterEntity,damageInfo,damageShowType)
    end
    if self._hitEffectWaitTime >0 then
        YIELD(TT,self._hitEffectWaitTime)
    end
    local totalTaskID = {}
    local hasFinalAttack = false
    self:PlayAudio(casterEntity)
    for _, damageResult in ipairs(playNormalDamageResult) do
        local targetID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetID)
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        local damageGridPos = damageResult:GetGridPos()
        ---@type PlayBuffService
        local playBuffSvc = self._world:GetService("PlayBuff")
        playBuffSvc:_OnAttackStart(TT, skillID, casterEntity, targetEntity, casterPos, damageGridPos, damageInfo)
        --静帧
        if finalAttack and not hasFinalAttack then
            hasFinalAttack = true
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
            local finalAttackEntityID = skillEffectResultContainer:GetFinalAttackEntityID()
            if finalAttackEntityID then
                if finalAttackEntityID == targetEntity:GetID() then
                    self._playSkillService:FreezeFrame(targetEntity)
                end
            else
                self._playSkillService:FreezeFrame(targetEntity)
            end
        end
        self:TurnToTarget(casterEntity,targetEntity)
        self:PlayDamageText(damageResult,damageInfo,targetEntity,skillID)
        local nTaskID=self:PlayBeHitAnim(TT,damageResult,damageInfo,targetEntity,casterEntity,skillID)
        table.insert(totalTaskID,nTaskID)
    end
    for _, damageResult in ipairs(playSplashDamageResult) do
        local targetID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetID)
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        local damageGridPos = damageResult:GetGridPos()
        ---@type PlayBuffService
        local playBuffSvc = self._world:GetService("PlayBuff")
        playBuffSvc:_OnAttackStart(TT, skillID, casterEntity, targetEntity, casterPos, damageGridPos, damageInfo)
        --静帧
        if finalAttack and not hasFinalAttack then
            hasFinalAttack = true
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
            local finalAttackEntityID = skillEffectResultContainer:GetFinalAttackEntityID()
            if finalAttackEntityID then
                if finalAttackEntityID == targetEntity:GetID() then
                    self._playSkillService:FreezeFrame(targetEntity)
                end
            else
                self._playSkillService:FreezeFrame(targetEntity)
            end
        end
        self:TurnToTarget(casterEntity,targetEntity)
        self:PlayDamageText(damageResult,damageInfo,targetEntity,skillID)
        local nTaskID=self:PlayBeHitAnim(TT,damageResult,damageInfo,targetEntity,casterEntity,skillID)
        table.insert(totalTaskID,nTaskID)
    end
    return totalTaskID
end
function Play215AndSplashPreDamageInstruction:PlayBeHitEffect(targetEntity,casterEntity,damageGridPos,damageShowType)
    local beHitEffectEntity =self._effectService:CreateBeHitEffect(self._damageHitEffect, targetEntity, damageShowType, damageGridPos)
    if beHitEffectEntity ~= nil then
        ---@type EffectControllerComponent
        local effectCtrl = beHitEffectEntity:EffectController()
        if effectCtrl ~= nil and casterEntity ~= nil then
            effectCtrl:SetEffectCasterID(casterEntity:GetID())
        end
    end
end

function Play215AndSplashPreDamageInstruction:PlayBeHitAnim(TT,damageResult,damageInfo,targetEntity,casterEntity,skillID)
    local guard = damageInfo:GetDamageType() == DamageType.Guard
    local miss = damageInfo:GetDamageType() == DamageType.Miss
    if not guard and not miss and self._hitAnimName and not damageInfo:IsHPShieldGuard() then
        targetEntity:SetAnimatorControllerTriggers({self._hitAnimName})
    end

    -- --buff通知
    -- local pos = targetEntity:GridLocation():GetGridPos()
    local scopeResult = damageResult:GetSkillEffectScopeResult()
    -- local attackPos = scopeResult:GetCenterPos()
    local attackPos = casterEntity:GetRenderGridPosition()
    local beAttackPos = damageResult:GetGridPos()

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:_OnAttackEnd(TT, skillID, casterEntity, targetEntity, attackPos, beAttackPos,damageInfo)

    local nTaskID = GameGlobal.TaskManager():CoreGameStartTask(self._playSkillService.PlayHitTrap,self._playSkillService, casterEntity, targetEntity)
    return nTaskID
end
function Play215AndSplashPreDamageInstruction:TurnToTarget(casterEntity,targetEntity)
    ---@type RenderEntityService
    local resvc = self._world:GetService("RenderEntity")
    resvc:TurnToTarget(targetEntity, casterEntity)
end

function Play215AndSplashPreDamageInstruction:PlayDamageText(damageResult,damageInfo,targetEntity,skillID)
    local damageGridPos = damageResult:GetGridPos()
    local damageShowType = self._playDamageService:SingleOrGrid(skillID)
    damageInfo:SetShowType(damageShowType)
    damageInfo:SetRenderGridPos(damageGridPos)
    --伤害飘字
    self._playDamageService:AsyncUpdateHPAndDisplayDamage(targetEntity, damageInfo)

    --闪白效果
    ---@type MaterialAnimationComponent
    local mtrAni = targetEntity:MaterialAnimationComponent()
    if mtrAni then
        mtrAni:PlayHit()
    end
end