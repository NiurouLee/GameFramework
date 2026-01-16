--[[
    孔雀专用指令，施法者身边指定位置放特效，被击格子也放一个特效，特效方向指向施法者身边的那个
    被击格子特效触发时，同时进行受击表现
]]
require("base_ins_r")

---@class PlayPeacockChainHitInstruction: BaseInstruction
_class("PlayPeacockChainHitInstruction", BaseInstruction)
PlayPeacockChainHitInstruction = PlayPeacockChainHitInstruction

function PlayPeacockChainHitInstruction:Constructor(paramList)
    self._casterEffectID = tonumber(paramList.casterEffectID)
    self._characterEffectSlots = {}
    local characterSlots = string.split(paramList.characterSlots, "|")
    for _, slot in ipairs(characterSlots) do
        local v = string.split(slot, "/")
        table.insert(self._characterEffectSlots, Vector3.New(tonumber(v[1]), tonumber(v[2]), tonumber(v[3])))
    end
    self._hitPosTrailEffectID = tonumber(paramList.hitPosTrailEffectID)
    self._trailDelay = tonumber(paramList.trailDelay)
    self._hitAnimName = paramList["hitAnimName"]
    self._turnToTarget = tonumber(paramList["turnToTarget"])
    self._deathClear = tonumber(paramList["deathClear"])
    self._hitGridEffectID = tonumber(paramList.hitGridEffectID)
    self._hitDelay = tonumber(paramList.hitDelay)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayPeacockChainHitInstruction:DoInstruction(TT, casterEntity, phaseContext)
    -- UnityEngine.Time.timeScale = 0.2
    TaskManager:GetInstance():CoreGameStartTask(self.TaskFunc, self, casterEntity, phaseContext)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayPeacockChainHitInstruction:TaskFunc(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local container = casterEntity:SkillRoutine():GetResultContainer()
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local curDamageIndex = phaseContext:GetCurDamageResultIndex()
    local damageResultArray = container:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)
    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[curDamageIndex]

    local slot = self._characterEffectSlots[curDamageIndex]
    ---@type UnityEngine.Transform
    local csTransform = casterEntity:View():GetGameObject().transform
    local v3CasterEffect = csTransform:TransformPoint(slot)

    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local fxsvc = world:GetService("Effect")
    local fxCaster = fxsvc:CreatePositionEffect(self._casterEffectID, v3CasterEffect)

    local targetEntityID = phaseContext:GetCurTargetEntityID()
    if targetEntityID == nil or targetEntityID < 0 then
        return
    end
    local targetEntity = world:GetEntityByID(targetEntityID)
    local curDamageInfoIndex = phaseContext:GetCurDamageInfoIndex()
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    local playFinalAttack = playSkillService:GetFinalAttack(world, casterEntity, phaseContext)
    local skillID = container:GetSkillID()

    YIELD(TT, self._trailDelay)
    local v2HitPos = damageResult:GetGridPos()
    
    ---@type BoardServiceRender
    local brsvc = world:GetService("BoardRender")
    local targetPos = brsvc:BoardRenderPos2FloatGridPos(v3CasterEffect)

    local dir = targetPos - v2HitPos
    local fxTargetPosTrail = fxsvc:CreateWorldPositionEffect(self._hitPosTrailEffectID, v2HitPos)
    local v3Dir = v3CasterEffect - brsvc:GridPos2RenderPos(v2HitPos)
    fxTargetPosTrail:SetDirection(v3Dir)

    YIELD(TT, self._hitDelay)
    local fxTargetPosGrid = fxsvc:CreateWorldPositionEffect(self._hitGridEffectID, v2HitPos)

    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(casterEntity)
        :SetHandleBeHitParam_TargetEntity(targetEntity)
        :SetHandleBeHitParam_HitAnimName(self._hitAnimName)
        :SetHandleBeHitParam_HitEffectID(0)
        :SetHandleBeHitParam_DamageInfo(damageInfo)
        :SetHandleBeHitParam_DamagePos(v2HitPos)
        :SetHandleBeHitParam_HitTurnTarget(self._turnToTarget)
        :SetHandleBeHitParam_DeathClear(self._deathClear)
        :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
        :SetHandleBeHitParam_SkillID(skillID)
    
    playSkillService:HandleBeHit(TT, beHitParam)
end

function PlayPeacockChainHitInstruction:GetCacheResource()
    local t = {}
    if self._casterEffectID and self._casterEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._casterEffectID].ResPath, 1})
    end
    if self._hitPosTrailEffectID and self._hitPosTrailEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitPosTrailEffectID].ResPath, 1})
    end
    if self._hitGridEffectID and self._hitGridEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitGridEffectID].ResPath, 1})
    end
    return t
end
