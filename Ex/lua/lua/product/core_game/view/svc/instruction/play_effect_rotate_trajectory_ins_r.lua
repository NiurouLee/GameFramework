--[[
    旋转轨迹特效表现
]]
---@class PlayEffectRotateTrajectoryInstruction:BaseInstruction
_class("PlayEffectRotateTrajectoryInstruction", BaseInstruction)
PlayEffectRotateTrajectoryInstruction = PlayEffectRotateTrajectoryInstruction

function PlayEffectRotateTrajectoryInstruction:Constructor(paramList)
    self.moveSpeed = tonumber(paramList["moveSpeed"]) --移动速度
    self.rotateSpeed = tonumber(paramList["rotateSpeed"]) --旋转速度

    self.block = tonumber(paramList["block"]) or 1 --是否阻塞 默认阻塞
    self.eftID = tonumber(paramList["effectID"])
    self.startEntity = paramList["start"]
    self.endEntity = paramList["end"]
    self.startWait = tonumber(paramList["startWait"]) or 0
end

function PlayEffectRotateTrajectoryInstruction:GetCacheResource()
    local t = {}
    if self.eftID and self.eftID > 0 then
        table.insert(t, {Cfg.cfg_effect[self.eftID].ResPath, 1})
    end
    return t
end

function PlayEffectRotateTrajectoryInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if self.block == 1 then
        self:_ShowDamageTask(TT, casterEntity, phaseContext)
    else
        GameGlobal.TaskManager():CoreGameStartTask(self._ShowDamageTask, self, casterEntity, phaseContext)
    end
end

function PlayEffectRotateTrajectoryInstruction:_ShowDamageTask(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)
    --检测是否有攻击目标 没有就返回
    if damageResultArray == nil then
        return
    end

    local hasTargetDamageResultArray = {}

    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = world:GetEntityByID(targetEntityID)
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        if targetEntity then
            table.insert(hasTargetDamageResultArray, damageResult)
        end
    end

    --有伤害结果，但是没有实际造成伤害
    if table.count(hasTargetDamageResultArray) == 0 then
        return
    end

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type EffectService
    local effectService = world:GetService("Effect")

    --根据配置找到对应实体的Hit坐标
    local _start = self:_GetEntityHitPos(TT, casterEntity, phaseContext, self.startEntity)
    local _end = self:_GetEntityHitPos(TT, casterEntity, phaseContext, self.endEntity)
    if not _start then
        Log.exception("PlayEffectTrajectory not find Entity hit  :", self.startEntity)
        return
    end
    if not _end then
        Log.exception("PlayEffectTrajectory not find Entity hit  :", self.endEntity)
        return
    end

    ---@type Entity
    local eftEntity = effectService:CreatePositionEffect(self.eftID, _start)

    if not eftEntity:HasView() then
        YIELD(TT)
    end

    local eftTansform = eftEntity:View():GetGameObject().transform
    --设置初始角度
    --不加偏移是0/180，直线不转
    -- local offset = Vector3(math.random(), math.random(), math.random())
    local offset = Vector3(0, math.random(), 0)

    local dir = _start - _end + offset
    eftEntity:SetDirection(dir)

    ---等待特效动画成型
    YIELD(TT, self.startWait)

    local moveSpeed = self.moveSpeed / 30 --移动速度
    local moveSpeedMin = 1 --移动速度
    local moveSpeedMax = 15 --移动速度
    local rotateSpeed = self.rotateSpeed / 30 --旋转速度

    local lastFrameNormalized = eftTansform.forward --上一帧的向量

    local finalForwardBefore = (_end - eftTansform.position).normalized
    local finalAngle = Vector3.Angle(eftTansform.forward, finalForwardBefore) --总旋转角度

    --计算起点和终点在同一高度下的水平距离
    local _startHorizontal = Vector3(_start.x, 0, _start.z)
    local _endHorizontal = Vector3(_end.x, 0, _end.z)
    local endToStartDistance = Vector3.Distance(_startHorizontal, _endHorizontal)
    --

    local move = true

    local frameCount = 0
    while move do
        local finalForward = (_end - eftTansform.position).normalized
        --如果当前向量 不等 最终向量
        if finalForward ~= eftTansform.forward then
            local angleOffset = Vector3.Angle(eftTansform.forward, finalForward)
            --这个最初转角慢了
            -- local t = rotateSpeed / angleOffset / 30
            local t = (frameCount * rotateSpeed) / finalAngle

            eftTansform.forward = Vector3.Lerp(lastFrameNormalized, finalForward, t)
        else
            moveSpeed = moveSpeed + 5
        end

        local changeSpeed = moveSpeed / 30
        eftTansform.position =
            eftTansform.position +
            Vector3(
                eftTansform.forward.x * changeSpeed,
                eftTansform.forward.y * changeSpeed,
                eftTansform.forward.z * changeSpeed
            )

        lastFrameNormalized = eftTansform.forward

        frameCount = frameCount + 1

        YIELD(TT)

        local currentDist = Vector3.Distance(eftTansform.position, _end)
        local curPosOverEndPos = self:_CheckEffectPos(_start, _end, eftTansform.position)
        if currentDist < 0.7 or eftTansform.position.y < 0 or curPosOverEndPos then
            move = false
            break
        end
    end

    world:DestroyEntity(eftEntity)
end

---根据配置找到对应实体的Hit坐标
function PlayEffectRotateTrajectoryInstruction:_GetEntityHitPos(TT, casterEntity, phaseContext, entityName)
    local targetEntity
    if entityName == "Target" then
        ---@type MainWorld
        local world = casterEntity:GetOwnerWorld()
        local targetEntityID = phaseContext:GetCurTargetEntityID()
        targetEntity = world:GetEntityByID(targetEntityID)
    elseif entityName == "Caster" then
        targetEntity = casterEntity
    end
    if not targetEntity then
        return
    end
    ---@type PlaySkillService
    local playSkillService = targetEntity:GetOwnerWorld():GetService("PlaySkill")
    --默认Hit点
    local rootTransform = playSkillService:GetEntityRenderHitTransform(targetEntity)
    local workPos = rootTransform.position
    return workPos
end

function PlayEffectRotateTrajectoryInstruction:_CheckEffectPos(_start, _end, curPos)
    -- local curHorizontalPos = Vector3(eftTansform.position.x, 0, eftTansform.position.z)
    -- local curToStartDistance = Vector3.Distance(_startHorizontal, curHorizontalPos)
    -- return curToStartDistance > endToStartDistance
    if _start.x <= _end.x and _start.z <= _end.z then
        return curPos.x >= _end.x and curPos.z >= _end.z
    elseif _start.x <= _end.x and _start.z >= _end.z then
        return curPos.x >= _end.x and curPos.z <= _end.z
    elseif _start.x >= _end.x and _start.z <= _end.z then
        return curPos.x <= _end.x and curPos.z >= _end.z
    elseif _start.x >= _end.x and _start.z >= _end.z then
        return curPos.x <= _end.x and curPos.z <= _end.z
    end
    return false
end
