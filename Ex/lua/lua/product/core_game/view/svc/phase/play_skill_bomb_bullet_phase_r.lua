require "play_skill_phase_base_r"
---@class PlaySkillBombBulletPhase: PlaySkillPhaseBase
_class("PlaySkillBombBulletPhase", PlaySkillPhaseBase)
PlaySkillBombBulletPhase = PlaySkillBombBulletPhase

---@param casterEntity Entity
---@param phaseParam SkillPhaseBombBulletParam
---播放音效语音表现
function PlaySkillBombBulletPhase:PlayFlight(TT, casterEntity, phaseParam)
    local bulletEffectId = phaseParam:GetBulletEffectId()
    local oneGridFlyTime = phaseParam:GetOnGridFlyTime()
    local bombEffectId = phaseParam:GetBombEffectId()
    local bombDelayTime = phaseParam:GetBombDelayTime()
    local bombEffectId2 = phaseParam:GetBombEffectId2()
    local damageDelayTime = phaseParam:GetDamageDelayTime()
    local hitAnimName = phaseParam:GetHitAnimName()
    local hitEffectID = phaseParam:GetHitEffectId()
    local delayTime = phaseParam:GetDelayTime()
    local audioId = phaseParam:GetAudioId()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    ---@type SkillDamageEffectResult[]
    local damageResultArr = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if not damageResultArr then
        return
    end
    local effectService = self._world:GetService("Effect")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    --提取施法位置
    ---@param castPos UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position
    local castRenderPos = boardServiceRender:GridPos2RenderPos(castPos)

    local bombPos = scopeResult:GetCenterPos()
    local bombRenderPos = boardServiceRender:GridPos2RenderPos(bombPos)
    if bulletEffectId > 0 then
        --子弹飞行方向
        local flyDir = bombPos - castPos
        local bulletEffectEntity = effectService:CreateWorldPositionDirectionEffect(bulletEffectId, castPos, flyDir)
        YIELD(TT)
        --子弹飞行
        local distance = Vector3.Distance(castRenderPos, bombRenderPos)
        local flyTime = distance * oneGridFlyTime
        local bulletGo = bulletEffectEntity:View():GetGameObject()
        local dotween = nil
        bulletGo.transform:DOMove(bombRenderPos, flyTime / 1000, false)
        YIELD(TT, flyTime)
        --销毁子弹
        self._world:DestroyEntity(bulletEffectEntity)
    end
    --创建爆炸特效
    local bombEffectEntity = effectService:CreatePositionEffect(bombEffectId, bombRenderPos)
    YIELD(TT, bombDelayTime)
    --创建爆炸特效2
    local bombEffectEntity2 = nil
    if bombEffectId2 > 0 then
        bombEffectEntity2 = effectService:CreatePositionEffect(bombEffectId2, bombRenderPos)
    end
    --等待爆炸
    YIELD(TT, damageDelayTime)
    --播放音效
    AudioHelperController.PlayInnerGameSfx(audioId)
    --播放伤害特效
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()

    for i = 1, #damageResultArr do
        ---@type SkillDamageEffectResult
        local damageResult = damageResultArr[i]
        local targetEntity = self._world:GetEntityByID(damageResult:GetTargetID())
        self:_ShowDamage(
            damageResult:GetDamageInfo(1),
            targetEntity,
            isFinalAttack,
            hitAnimName,
            hitEffectID,
            casterEntity,
            damageResult:GetGridPos(),
            false,
            skillID
        )
    end

    YIELD(TT, delayTime)
    --销毁爆炸特效
    if bombEffectEntity then
        self._world:DestroyEntity(bombEffectEntity)
    end
    if bombEffectEntity2 then
        self._world:DestroyEntity(bombEffectEntity2)
    end
end

function PlaySkillBombBulletPhase:_ShowDamage(
    damageInfo,
    targetEntity,
    isFinalAttack,
    hitAnimName,
    hitEffectID,
    casterEntity,
    gridPos,
    hitTurnToTarget,
    skillID)
    if targetEntity ~= nil then
        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damageInfo)
            :SetHandleBeHitParam_DamagePos(gridPos)
            :SetHandleBeHitParam_HitTurnTarget(hitTurnToTarget)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(isFinalAttack)
            :SetHandleBeHitParam_SkillID(skillID)

        GameGlobal.TaskManager():CoreGameStartTask(
            self:SkillService().HandleBeHit,
            self:SkillService(),
            beHitParam
        )
    end
end

function PlaySkillBombBulletPhase:_GetFlyTargetPos(chainGrid, castPos)
    local leftup = nil
    local leftbottom = nil
    local rightbottom = nil
    local rightup = nil
    local up = nil
    local bottom = nil
    local right = nil
    local left = nil
    local maxLength = 0
    for i, pos in pairs(chainGrid) do
        local dis = pos - castPos
        if (math.abs(dis.x) > maxLength) then
            maxLength = math.abs(dis.x)
        end
        if (math.abs(dis.y) > maxLength) then
            maxLength = math.abs(dis.y)
        end
        if dis.x > 0 and dis.y > 0 then
            if rightbottom == nil or rightbottom.x < pos.x then
                rightbottom = pos
            end
        elseif dis.x > 0 and dis.y < 0 then
            if leftbottom == nil or leftbottom.x < pos.x then
                leftbottom = pos
            end
        elseif dis.x < 0 and dis.y < 0 then
            if leftup == nil or leftup.x > pos.x then
                leftup = pos
            end
        elseif dis.x < 0 and dis.y > 0 then
            if rightup == nil or rightup.x > pos.x then
                rightup = pos
            end
        elseif dis.x == 0 and dis.y > 0 then
            if right == nil or right.y < pos.y then
                right = pos
            end
        elseif dis.x == 0 and dis.y < 0 then
            if left == nil or left.y > pos.y then
                left = pos
            end
        elseif dis.x > 0 and dis.y == 0 then
            if bottom == nil or bottom.x < pos.x then
                bottom = pos
            end
        elseif dis.x < 0 and dis.y == 0 then
            if up == nil or up.x > pos.x then
                up = pos
            end
        end
    end
    local targets = {
        {gridpos = leftup},
        {gridpos = leftbottom},
        {gridpos = rightbottom},
        {gridpos = rightup},
        {gridpos = up},
        {gridpos = bottom},
        {gridpos = right},
        {gridpos = left}
    }
    return targets, maxLength
end

function PlaySkillBombBulletPhase:_GetGridList(pet_entity)
    ---@type SkillEffectResultContainer
    local chainGrid = {}

    ---@type ActiveSkillMutilSelectGridComponent
    local selectComponent = pet_entity:ActiveSkillMutilSelectGridComponent()
    if selectComponent ~= nil then
        chainGrid = selectComponent:GetDirectGridPosArray()
    end
    return chainGrid
end

function PlaySkillBombBulletPhase:_GetSkillScope(chainGrid, petSkillRoutine)
    local tmpChainGrid = {}
    --考虑施法范围阻挡
    local skillScope = chainGrid
    for index, value in ipairs(chainGrid) do
        table.insert(tmpChainGrid, value)
    end
    return tmpChainGrid
    -- end
end

---@param boardServiceRender BoardServiceRender
function PlaySkillBombBulletPhase:_StartFly(
    TT,
    pet_entity,
    targets,
    boardServiceRender,
    castPos,
    worldPos,
    maxLength,
    phaseParam)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local bulletEffectId = phaseParam:GetBulletEffectId()
    if bulletEffectId <= 0 then
        return
    end
    local oneGridFlyTime = phaseParam:GetOnGridFlyTime()
    local waitTime = 0
    --创建子弹
    for k, v in pairs(targets) do
        if v.gridpos ~= nil then
            local posDirectory = v.gridpos - castPos
            local effectEntity = effectService:CreateWorldPositionDirectionEffect(bulletEffectId, castPos, posDirectory)
            v.entity = effectEntity
        end
    end
    YIELD(TT)
    --子弹飞行
    for k, v in pairs(targets) do
        local effectEntity = v.entity
        if effectEntity ~= nil then
            local gridpos = v.gridpos
            local go = effectEntity:View():GetGameObject()
            local gridWorldpos = boardServiceRender:GridPos2RenderPos(gridpos)
            local dis = Vector2.Distance(gridpos, castPos)
            local flyTime = dis * oneGridFlyTime / 1000.0
            go.transform:DOMove(gridWorldpos, flyTime, false)
            if flyTime > waitTime then
                waitTime = flyTime
            end
        end
    end
    YIELD(TT, waitTime)
end
