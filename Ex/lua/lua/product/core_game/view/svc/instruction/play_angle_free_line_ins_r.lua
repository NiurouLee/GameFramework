require("base_ins_r")

---@class PlayAngleFreeLineInstruction : BaseInstruction
_class("PlayAngleFreeLineInstruction", BaseInstruction)
PlayAngleFreeLineInstruction = PlayAngleFreeLineInstruction

function PlayAngleFreeLineInstruction:Constructor(paramList)
    self._hitAnimName = paramList["hitAnimName"]
    self._hitEffectID = tonumber(paramList["hitEffectID"])
    self._turnToTarget = tonumber(paramList["turnToTarget"])
    self._deathClear = tonumber(paramList["deathClear"])

    self._lineEffectID = tonumber(paramList.lineEffectID)
    self._hitTime = tonumber(paramList.hitTime)
end

function PlayAngleFreeLineInstruction:GetCacheResource()
    local t = {}
    if self._lineEffectID and self._lineEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._lineEffectID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAngleFreeLineInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local resultIndex = phaseContext:GetCurResultIndexByType(SkillEffectType.AngleFreeLineDamage)

    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectAngleFreeLineDamageResult[]
    local resultArray = routineCmpt:GetEffectResultsAsArray(SkillEffectType.AngleFreeLineDamage)

    if ((not resultArray) or (not resultArray[resultIndex])) then
        Log.error("PlayAngleFreeLine需要正确的数据操作指令，当前index为: ", resultIndex)
        return
    end

    ---@type SkillEffectAngleFreeLineDamageResult
    local result = resultArray[resultIndex]

    if not result:GetPickupPos() then
        Log.info(self._className, "没有对应的点选，跳过播放。")
        return
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type Vector3
    local renderPos = boardServiceRender:GridPos2RenderPos(result:GetPickupPos())

    ---@type EffectService
    local fxSvc = world:GetService("Effect")
    local fxEntity = fxSvc:CreateEffect(self._lineEffectID, casterEntity)

    YIELD(TT)

    ---@type UnityEngine.GameObject
    local fxGo = fxEntity:View():GetGameObject()
    ---@type UnityEngine.Transform
    local fxTransform = fxGo.transform
    ---@type UnityEngine.Vector3
    local fxRenderPos = fxGo.transform.position

    local relative = renderPos - fxRenderPos
    fxTransform.rotation = Quaternion.LookRotation(relative, Vector3.up)

    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    if self._hitTime then
        YIELD(TT, self._hitTime)
    end

    --这个技能造成的所有伤害
    local damageResultArrayAll = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    ---@type SkillDamageEffectResult[]
    local damageResultArray = result:GetDamageResults()
    for _, damageResult in ipairs(damageResultArray) do
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = world:GetEntityByID(targetEntityID)
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        local damageGridPos = damageResult:GetGridPos()
        local playFinalAttack =
            skillEffectResultContainer:IsFinalAttack() and damageResult == damageResultArrayAll[#damageResultArrayAll]
        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(self._hitAnimName)
            :SetHandleBeHitParam_HitEffectID(self._hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damageInfo)
            :SetHandleBeHitParam_DamagePos(damageGridPos)
            :SetHandleBeHitParam_HitTurnTarget(self._turnToTarget)
            :SetHandleBeHitParam_DeathClear(self._deathClear)
            :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
            :SetHandleBeHitParam_SkillID(skillID)

        playSkillService:HandleBeHit(TT, beHitParam)
    end
end
