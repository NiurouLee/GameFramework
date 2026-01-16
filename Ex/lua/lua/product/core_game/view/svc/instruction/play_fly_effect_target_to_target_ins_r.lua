require("base_ins_r")
---@class PlayFlyEffectTargetToTargetInstruction: BaseInstruction
_class("PlayFlyEffectTargetToTargetInstruction", BaseInstruction)
PlayFlyEffectTargetToTargetInstruction = PlayFlyEffectTargetToTargetInstruction

function PlayFlyEffectTargetToTargetInstruction:Constructor(paramList)
    self._flyEffectID = tonumber(paramList["flyEffectID"])
    self._flyTime = tonumber(paramList["flyTime"])
    self._flyTrace = tonumber(paramList["flyTrace"])

    self._casterType = tonumber(paramList["casterType"])
    self._casterParam = tonumber(paramList["casterParam"])
    self._targetType = tonumber(paramList["targetType"])
    self._targetParam = tonumber(paramList["targetParam"])
end

function PlayFlyEffectTargetToTargetInstruction:GetCacheResource()
    local t = {}
    if self._flyEffectID and self._flyEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._flyEffectID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayFlyEffectTargetToTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalHit = skillEffectResultContainer:IsFinalAttack()
    ---@type Vector2
    local posCaster = casterEntity:GetGridPosition()
    ---@type Vector2
    local posTarget = Vector2.New(0, 0)
    ---@type Vector2
    local posStart = self:_PhaseWorkPos(self._casterType, self._casterParam, posCaster, posTarget)
    ---@type Vector2
    local posEnd = self:_PhaseWorkPos(self._targetType, self._targetParam, posCaster, posTarget)

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type EffectService
    local effectService = world:GetService("Effect")

    ---创建抛射体
    ---@type Entity
    local entityEffect = nil
    ---@type Vector2
    local posDirectory = posEnd - posStart

    entityEffect = effectService:CreateWorldPositionDirectionEffect(self._flyEffectID, posStart, posDirectory)
    YIELD(TT)

    ---飞行时长
    local disx = math.abs(posEnd.x - posStart.x)
    local disy = math.abs(posEnd.y - posStart.y)
    local dis = math.sqrt(disx * disx + disy * disy)
    local nTotalTime = self._flyTime
    local nFlyTime = nTotalTime / 1000.0

    local nEndTime = GameGlobal:GetInstance():GetCurrentTime() + nTotalTime
    ---開始彈道
    ---@type UnityEngine.Transform
    local trajectoryObject = entityEffect:View():GetGameObject()
    local transWork = trajectoryObject.transform
    local gridWorldpos = boardServiceRender:GridPos2RenderPos(posEnd)
    local easeWork = nil
    if SkillPhaseParam_TrajectoryType.Line == self._flyTrace then ---直线
        easeWork = transWork:DOMove(gridWorldpos, nFlyTime, false):SetEase(DG.Tweening.Ease.InOutSine)
    elseif SkillPhaseParam_TrajectoryType.Parabola == self._flyTrace then ---抛物线
        transWork.position = transWork.position + Vector3.up * 1 --抛射起点高度偏移
        local jumpPower = math.sqrt(disx + disy)
        ---@type DG.Tweening.Sequence
        local sequence = transWork:DOJump(gridWorldpos, jumpPower, 1, nFlyTime, false)
        easeWork = sequence:SetEase(DG.Tweening.Ease.InOutSine)
    elseif SkillPhaseParam_TrajectoryType.Laser == self._flyTrace then ---直线激光表现
        ---@type DG.Tweening.Sequence
        local sequence = transWork:DOScaleZ(dis, nFlyTime)
        easeWork = sequence:SetEase(DG.Tweening.Ease.InOutSine)
    end

    ---等待飞行结束
    while GameGlobal:GetInstance():GetCurrentTime() < nEndTime do
        YIELD(TT)
    end

    self:_DelEffectEntity(TT, world, trajectoryObject, entityEffect)
end

function PlayFlyEffectTargetToTargetInstruction:_PhaseWorkPos(posType, posParam, posCaster, posTarget)
    local posReturn = Vector2.New(0, 0)
    if SkillPhaseParam_PointType.CasterPos == posType then
        posReturn = posCaster
    elseif SkillPhaseParam_PointType.CasterX == posType then
        posReturn.x = posCaster.x
        posReturn.y = posParam
    elseif SkillPhaseParam_PointType.CasterY == posType then
        posReturn.x = posParam
        posReturn.y = posCaster.y
    end
    return posReturn
end

function PlayFlyEffectTargetToTargetInstruction:_DelEffectEntity(TT, world, trajectoryObject, entityEffect)
    trajectoryObject:SetActive(false)
    world:DestroyEntity(entityEffect)
end
