require "play_skill_phase_base_r"
_class("PlaySkillTrajectoryAnimationPhase", PlaySkillPhaseBase)
PlaySkillTrajectoryAnimationPhase = PlaySkillTrajectoryAnimationPhase

function PlaySkillTrajectoryAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseTrajectoryParam
    local trajectoryParam = phaseParam
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --提取施法位置
    ---@param castPos UnityEngine.Vector3
    local castPos = casterEntity:Location().Position
    local absorbResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.AbsorbPiece)
    if not absorbResult then
        return
    end
    local absorbPieceList = absorbResult:GetAbsorbPieceList()

    if not absorbPieceList or #absorbPieceList == 0 then
        return
    end

    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local gridEffectID = trajectoryParam:GetGridEffectID()
    local effectEntityList = {}
    for k, v in pairs(absorbPieceList) do
        local renderPos = boardServiceRender:GridPos2RenderPos(v)
        local effectEntity = effectService:CreatePositionEffect(gridEffectID, renderPos)
        table.insert(effectEntityList, {entity = effectEntity, position = renderPos})
    end
    local ballHigh = trajectoryParam:GetBallHigh()
    YIELD(TT)
    local flyTime = trajectoryParam:GetUpTime()
    for k, v in pairs(effectEntityList) do
        local view = v.entity:View()
        local go = view:GetGameObject()
        self:_CalcTrajectory(v.entity, go, flyTime, casterEntity, ballHigh, trajectoryParam)
    end
end

function PlaySkillTrajectoryAnimationPhase:_CalcTrajectory(effectEntity, go, flyTime, casterEntity, ballHigh, phaseParam)
    ---@type UnityEngine.Transform
    local transform = go.transform
    transform:DOMoveY(ballHigh, flyTime / 1000):OnComplete(
        function()
            GameGlobal.TaskManager():CoreGameStartTask(self._BallFly, self, effectEntity, casterEntity, phaseParam)
        end
    )
end
---@param phaseParam SkillPhaseTrajectoryParam
---@param position Vector3
---@param go UnityEngine.GameObject
function PlaySkillTrajectoryAnimationPhase:_BallFly(TT, effectEntity, casterEntity, phaseParam)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local effectBallID = phaseParam:GetGridEffectID()
    local config = Cfg.cfg_effect[effectBallID]
    local casterTranform = casterEntity:View():GetGameObject().transform
    local bindTf = GameObjectHelper.FindChild(casterEntity:View():GetGameObject().transform, config.BindPos)
    local destPoint = bindTf.position
    destPoint.y = phaseParam:GetBallHigh()
    ---@type UnityEngine.Transform
    local effectTransFrom = effectEntity:View():GetGameObject().transform
    local ballPos = effectTransFrom.position
    local distance = Vector3.Distance(ballPos, destPoint)
    local flyTime = 2000
    -- phaseParam:FlyTime()
    local a = distance
    local b = phaseParam:GetFlyRadius()
    local t = self:_GetRadian(ballPos, destPoint)
    local s = (distance / flyTime) / 1000
    local maxPoint = flyTime
    local pointList = {}
    local i = 1
    local ballPoint = effectTransFrom.position
    while Vector3.Distance(ballPoint, destPoint) > phaseParam:GetHideDistance() do
        local x = (a + b * t) * Mathf.Cos(t)
        local y = (a + b * t) * Mathf.Sin(t)
        t = t + i * s
        b = b - i * s
        local deltaPos = Vector3(x, 0, y)
        ballPoint = destPoint + deltaPos
        if i > maxPoint then
            break
        end
        table.insert(pointList, ballPoint)
        i = i + 1
    end
    table.insert(pointList, destPoint)
    local beginTime = self._timeService:GetCurrentTimeMs()
    while Vector3.Distance(effectTransFrom.position, destPoint) > phaseParam:GetHideDistance() do
        local now = self._timeService:GetCurrentTimeMs()
        local deltaTime = now - beginTime
        deltaTime = math.floor(deltaTime)
        if deltaTime < #pointList then
            if deltaTime ~= 0 then
                effectTransFrom.position = pointList[deltaTime]
            end
        else
            effectTransFrom.position = pointList[#pointList]
            break
        end
        YIELD(TT)
    end

    effectEntity:View():GetGameObject():SetActive(false)
    self._world:DestroyEntity(effectEntity)
end

function PlaySkillTrajectoryAnimationPhase:_GetRadian(from, to)
    local subVector = from - to
    local deltaAngle = 0
    local radian = Mathf.Atan(subVector.z, subVector.x)
    local angle = radian * Mathf.Rad2Deg
    return radian
    --local retRadian
    --if subVector.x== 0 and subVector.z == 0 then
    --	retRadian = 0
    --elseif  subVector.x== 0 and subVector.z < 0 then
    --	--270
    --	retRadian = 1.5* Mathf.PI
    --elseif  subVector.x== 0 and subVector.z > 0 then
    --	--90
    --	retRadian =  0.5* Mathf.PI
    --elseif  subVector.x< 0 and subVector.z == 0 then
    --	return Mathf.PI
    --elseif  subVector.x> 0 and subVector.z == 0 then
    --	return 0
    --elseif  subVector.x> 0 and subVector.z < 0 then
    --	return 	2*Mathf.PI - radian
    --	--return (360-angle)* Mathf.Deg2Rad
    --elseif  subVector.x> 0 and subVector.z > 0 then
    --	return radian
    --elseif subVector.x <0 and subVector.z >0 then
    --	return Mathf.PI - radian
    --	--return (180-angle) * Mathf.Deg2Rad
    --elseif subVector.x <0 and subVector.z <0 then
    --	return Mathf.PI + radian
    --	--return (180+angle) * Mathf.Deg2Rad
    --end
end
