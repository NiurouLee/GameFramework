require("base_ins_r")

---@class PlayConductDamageInstruction: BaseInstruction
_class("PlayConductDamageInstruction", BaseInstruction)
PlayConductDamageInstruction = PlayConductDamageInstruction

function PlayConductDamageInstruction:Constructor(paramList)
    self._hitEffectID = tonumber(paramList.hitEffectID)
    self._hitAnimName = paramList.hitAnimName
    self._turnToTarget = tonumber(paramList.turnToTarget)
    self._deathClear = tonumber(paramList.deathClear)

    self._chainEffectID = tonumber(paramList.chainEffectID)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayConductDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectConductDamageResult[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ConductDamage)
    if not results then
        return
    end

    for _, result in ipairs(results) do
        self:PlaySingleResult(TT, casterEntity, phaseContext, result)
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
---@param result SkillEffectConductDamageResult
function PlayConductDamageInstruction:PlaySingleResult(TT, casterEntity, phaseContext, result)
    local atomDataArray = result:GetAtomDataArray()
    if #atomDataArray == 0 then
        return
    end

    local world = casterEntity:GetOwnerWorld()

    ---@type EffectService
    local fxsvc = world:GetService("Effect")

    -- 初始起点为传导核心伤害被击者
    local lastBeginnerID = result:GetCenterTargetID()
    local eCenterEntity = world:GetEntityByID(lastBeginnerID)
    fxsvc:CreateBeHitEffect(self._hitEffectID, eCenterEntity)

    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    for _, atom in ipairs(atomDataArray) do
        ---@type SkillDamageEffectResult
        local damageResult = atom:GetDamageResult()
        local targetID = damageResult:GetTargetID()

        local eLast = world:GetEntityByID(lastBeginnerID)
        local eTarget = world:GetEntityByID(targetID)

        if eLast:HasView() and eTarget:HasView() then
            local goLast = eLast:View():GetGameObject()
            local goTarget = eTarget:View():GetGameObject()
            if  (goLast and (tostring(goLast) ~= "null")) and (goTarget and (tostring(goTarget) ~= "null")) then
                -- 挂载连线特效
                local eLineFx = fxsvc:CreateEffect(self._chainEffectID, eLast)
                YIELD(TT)
                if eLineFx and eLineFx:View() and eLineFx:View():GetGameObject() then
                    local goLine = eLineFx:View():GetGameObject()
                    ---@type UnityEngine.LineRenderer
                    local csLineRenderer = goLine:GetComponentInChildren(typeof(UnityEngine.LineRenderer))
                    csLineRenderer.useWorldSpace = true
                    csLineRenderer:SetPosition(0, goLast.transform.position)
                    csLineRenderer:SetPosition(1, goTarget.transform.position)
                end
            end
        end

        local playFinalAttack = playSkillService:GetFinalAttack(world, casterEntity, phaseContext)

        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(eTarget)
            :SetHandleBeHitParam_HitAnimName(self._hitAnimName)
            :SetHandleBeHitParam_HitEffectID(self._hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damageResult:GetDamageInfo(1))
            :SetHandleBeHitParam_DamagePos(damageResult:GetGridPos())
            :SetHandleBeHitParam_HitTurnTarget(self._turnToTarget)
            :SetHandleBeHitParam_DeathClear(self._deathClear)
            :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
            :SetHandleBeHitParam_SkillID(skillID)
    
        playSkillService:HandleBeHit(TT, beHitParam)

        -- 记录上一个人作为下一个连线的起点
        lastBeginnerID = targetID
    end
end
