require("base_ins_r")
---@class PlayHookTractionTargetInstruction: BaseInstruction
_class("PlayHookTractionTargetInstruction", BaseInstruction)
PlayHookTractionTargetInstruction = PlayHookTractionTargetInstruction

function PlayHookTractionTargetInstruction:Constructor(paramList)
    self._paramList = paramList

    self._chainEffectID = tonumber(paramList.chainEffectID)
    self._hookEffectID = tonumber(paramList.hookEffectID)

    self._hookUnitGridTime = tonumber(paramList.hookUnitGridTime)
    self._tractionUnitGridTime = tonumber(paramList.tractionUnitGridTime)

    self._hookUnitFullTime = tonumber(paramList.hookUnitFullTime)
    self._tractionUnitFullTime = tonumber(paramList.tractionUnitFullTime)

    self._afterHookHitDelay = tonumber(paramList.afterHookHitDelay)

    self._chainBeginGameObjectName = paramList.ChainBeginName
end

function PlayHookTractionTargetInstruction:GetCacheResource()
    local t = {}
    if self._chainEffectID and self._chainEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._chainEffectID].ResPath, 1})
    end
    if self._hookEffectID and self._hookEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hookEffectID].ResPath, 1})
    end
    return t
end

local function GetTargetHitBinderGameObject(entity)
    if not entity then
        return nil
    end

    if not entity:HasView() then
        return nil
    end

    local world = entity:GetOwnerWorld()
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    local csoHitBinderGo = playSkillService:GetEntityRenderHitTransform(entity)

    if not csoHitBinderGo then
        Log.exception("PlayHookTractionTargetInstruction: no hit binder find: ", entity:GetID(), Log.traceback())
    end

    return csoHitBinderGo
end

---@param entity Entity
local function GetTargetCustomBinderGameObject(entity, name)
    if not entity then
        return nil
    end

    if not entity:HasView() then
        return nil
    end

    local csoGameObject = entity:View():GetGameObject()
    local csoTargetObject = GameObjectHelper.FindChild(csoGameObject.transform, name)

    if not csoTargetObject then
        Log.exception("PlayHookTractionTargetInstruction: no custom binder find: ", entity:GetID(), " ", name, " ", Log.traceback())
    end

    return csoTargetObject
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayHookTractionTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    -- 牵引已有约定: 同一个技能内只能包含一个牵引结果
    -- 结果内部可能有多个目标受到影响
    ---@type SkillEffectMultiTractionResult
    local result = resultContainer:GetEffectResultByArray(SkillEffectType.MultiTraction, 1)
    if not result then
        return
    end

    local world = casterEntity:GetOwnerWorld()

    ---@type UnityEngine.GameObject
    local csoChainBind = GetTargetHitBinderGameObject(casterEntity)
    if self._chainBeginGameObjectName then
        csoChainBind = GetTargetCustomBinderGameObject(casterEntity, self._chainBeginGameObjectName)
    end
    local v3BeginPos = csoChainBind.transform.position

    local taskIDs = {}

    local tSingleTargetPossession = result:GetResultArray()
    for _, single in ipairs(tSingleTargetPossession) do
        table.insert(
            taskIDs,
            GameGlobal.TaskManager():CoreGameStartTask(
                self._SingleHook,
                self,
                world,
                single,
                v3BeginPos,
                casterEntity,
                phaseContext,
                result
            )
        )
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end
end

local function GetFlyTimeMS(v2BeginPos, v2EndPos, unitGridTime)
    local nDistance = Vector2.Distance(v2BeginPos, v2EndPos)
    return nDistance * unitGridTime
end

function PlayHookTractionTargetInstruction:_SingleHook(
    TT,
    world,
    singleTargetResult,
    v3BeginPos,
    casterEntity,
    phaseContext,
    result)
    local brsvc = world:GetService("BoardRender")
    local fxsvc = world:GetService("Effect")

    local eidTarget = singleTargetResult:GetTargetEntityID()
    local eTarget = world:GetEntityByID(eidTarget)
    local csoTargetHitGo = GetTargetHitBinderGameObject(eTarget)

    local v3EndPos = csoTargetHitGo.transform.position

    local v2BeginPos = brsvc:BoardRenderPos2FloatGridPos_New(v3BeginPos)
    local v2EndPos = brsvc:BoardRenderPos2FloatGridPos_New(v3EndPos)

    -- 阶段1 勾住
    local v2GridDir = v2EndPos - v2BeginPos
    local nHookTimeMs = self._hookUnitFullTime or GetFlyTimeMS(v2BeginPos, v2EndPos, self._hookUnitGridTime)
    local nDOTweenTrajectoryTime = nHookTimeMs * 0.001

    --region 钩子飞出
    ---@type Entity
    local eHookFx = fxsvc:CreateWorldPositionDirectionEffect(self._hookEffectID, v2BeginPos, v2GridDir)
    ---@type UnityEngine.Transform
    local csoTransformHookFx = eHookFx:View():GetGameObject().transform
    csoTransformHookFx:LookAt(csoTargetHitGo, Vector3.up)

    -- csoHookTweener:Play()
    --endregion

    --region 链条跟随
    local eChainFx = fxsvc:CreateWorldPositionDirectionEffect(self._chainEffectID, v2BeginPos, v2GridDir)
    -- YIELD(TT)
    local csoGoChainFx = eChainFx:View():GetGameObject()

    local csoLineRenderer = csoGoChainFx:GetComponentInChildren(typeof(UnityEngine.LineRenderer), true)
    csoLineRenderer.useWorldSpace = true
    csoLineRenderer:SetPosition(0, v3BeginPos)
    csoLineRenderer:SetPosition(1, v3BeginPos)
    --endregion

    ---@type TimeService
    local timeService = world:GetService("Time")
    local nHookBeginTime = timeService:GetCurrentTimeMs()
    while (true) do
        local progress = (timeService:GetCurrentTimeMs() - nHookBeginTime) / nHookTimeMs
        local v3 = Vector3.Lerp(v3BeginPos, v3EndPos, progress)
        csoTransformHookFx.position = v3
        csoLineRenderer:SetPosition(1, csoTransformHookFx.position)

        YIELD(TT)
        if progress >= 1 then
            break
        end
    end
    csoLineRenderer:SetPosition(1, v3EndPos)

    world:DestroyRenderEntity(eHookFx)

    local dmgIns = PlayCommonBeHitInstruction:New(self._paramList)
    local dmgTask = GameGlobal.TaskManager():CoreGameStartTask(dmgIns.DoInstruction, dmgIns, casterEntity, phaseContext)

    while (not TaskHelper:GetInstance():IsTaskFinished(dmgTask)) do
        YIELD(TT)
    end

    --region 钩中后蓄力
    if self._afterHookHitDelay then
        YIELD(TT, self._afterHookHitDelay)
    end
    --endregion

    -- 阶段2 拉回
    local tractionIns = PlayMultiTractionInstruction:New(self._paramList)
    local nTractionTimeMs = self._tractionUnitFullTime or GetFlyTimeMS(v2EndPos, v2BeginPos, self._tractionUnitGridTime)
    local nTractionBeginTime = timeService:GetCurrentTimeMs()
    csoLineRenderer:SetPosition(0, v3BeginPos)
    GameGlobal.TaskManager():CoreGameStartTask(tractionIns.DoInstruction, tractionIns, casterEntity, phaseContext)
    while (true) do
        local progress = (timeService:GetCurrentTimeMs() - nTractionBeginTime) / nTractionTimeMs
        -- local v3 = Vector3.Lerp(v3EndPos, v3BeginPos, progress)
        csoLineRenderer:SetPosition(1, csoTargetHitGo.transform.position)

        YIELD(TT)
        if progress >= 1 then
            break
        end
    end

    local array = result:GetResultArray()
    -- 触发型机关的触发
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    for _, info in ipairs(array) do
        local entity = world:GetEntityByID(info.entityID)
        if entity and (info.beginPos ~= info.finalPos) then -- 没能移动的目标不会重复触发机关
            local listTrapTrigger = info:GetTriggerTraps()
            trapServiceRender:PlayTrapTriggerSkillTasks(TT, listTrapTrigger, false, entity)
        end
    end

    world:DestroyRenderEntity(eChainFx)
end
