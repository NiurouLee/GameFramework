require "play_skill_phase_base_r"

---@class PlaySkillTranspositionPhase: PlaySkillPhaseBase
_class("PlaySkillTranspositionPhase", PlaySkillPhaseBase)
PlaySkillTranspositionPhase = PlaySkillTranspositionPhase

function PlaySkillTranspositionPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseTranspositionParam
    local effectParam = phaseParam

    self._flyEffectID = effectParam:GetFlyEffectID()
    local anim1 = effectParam:GetAnim1()
    local anim2 = effectParam:GetAnim2()
    local materialAnim1 = effectParam:GetMaterialAnim1()
    local materialAnim2 = effectParam:GetMaterialAnim2()
    local mainEffectID1 = effectParam:GetMainEffectID1()
    local mainEffectID2 = effectParam:GetMainEffectID2()
    local delayFlyTime = effectParam:GetDelayFlyTime()
    self._oneGridFlyTime = effectParam:GetOneGridFlyTime()
    local finishTime = effectParam:GetFinishTime()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillEffectResult_Teleport[]
    local teleportEffectResultAll = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Teleport)
    if not teleportEffectResultAll then
        return
    end

    ---@type SkillEffectResult_Teleport
    local casterResult = teleportEffectResultAll[1]
    ---@type SkillEffectResult_Teleport
    local targetResult = teleportEffectResultAll[2]

    if not casterResult or not targetResult then
        return
    end

    local targetEntityID = targetResult:GetTargetID()
    local targetEntity = self._world:GetEntityByID(targetEntityID)
    ---[KZY:SkillHolder去Self]
    if effectParam:IsUseSuper() and casterEntity:HasSuperEntity() then
        casterEntity = casterEntity:GetSuperEntity()
    end

    casterEntity:SetAnimatorControllerTriggers({anim1})
    targetEntity:SetAnimatorControllerTriggers({anim1})

    casterEntity:PlayMaterialAnim(materialAnim1)
    targetEntity:PlayMaterialAnim(materialAnim1)

    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    effectService:CreateEffect(mainEffectID1, casterEntity)
    effectService:CreateEffect(mainEffectID1, targetEntity)

    YIELD(TT, delayFlyTime)

    --弹道

    ---@type PlaySkillInstructionService
    local playSkillInstructionService = self._world:GetService("PlaySkillInstruction")
    --消失
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportHide, false, casterResult)
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportHide, false, targetResult)

    self:_ShowShowLineRenderer(casterEntity, false)
    self:_ShowShowLineRenderer(targetEntity, false)

    ---第二阶段 贝塞尔运动
    self:_OnPlayBezier(casterEntity, targetEntity, 1)
    self:_OnPlayBezier(targetEntity, casterEntity, -1)

    YIELD(TT, self._flyTime)

    ---瞬移
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportMove, false, casterResult)
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportMove, false, targetResult)
    ---出现
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportShow, false, casterResult)
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportShow, false, targetResult)

    --朝向玩家
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
    ---@type RenderEntityService
    local resvc = self._world:GetService("RenderEntity")
    resvc:TurnToTarget(casterEntity, teamLeaderEntity)
    resvc:TurnToTarget(targetEntity, teamLeaderEntity)

    self:_ShowShowLineRenderer(casterEntity, true)
    self:_ShowShowLineRenderer(targetEntity, true)
    effectService:CreateEffect(mainEffectID2, casterEntity)
    effectService:CreateEffect(mainEffectID2, targetEntity)

    ---buff
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.BuffNotify, false, casterResult)
    playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.BuffNotify, false, targetResult)

    casterEntity:SetAnimatorControllerTriggers({anim2})
    targetEntity:SetAnimatorControllerTriggers({anim2})

    casterEntity:PlayMaterialAnim(materialAnim2)
    targetEntity:PlayMaterialAnim(materialAnim2)

    YIELD(TT, finishTime)
end

function PlaySkillTranspositionPhase:_OnPlayBezier(casterEntity, targetEntity, dir)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    local casterBoneTransform = playSkillService:GetEntityRenderSelectBoneTransform(casterEntity, "Hit")
    local casterPos = casterBoneTransform.position

    local targetBoneTransform = playSkillService:GetEntityRenderSelectBoneTransform(targetEntity, "Hit")
    local targetPos = targetBoneTransform.position

    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type Entity
    local effectEntity = effectService:CreatePositionEffect(self._flyEffectID, casterPos)
    local go = effectEntity:View():GetGameObject()

    local path = {}
    --第一个 当前位置
    table.insert(path, go.transform.position)

    local flyDis = Vector3.Distance(targetPos, casterPos)
    local flyDir = targetPos - casterPos
    --当前的向量
    local curNormalized = (targetPos - casterPos).normalized

    local verticalNormalized = Vector3(-curNormalized.z / curNormalized.x, 0, 1).normalized
    local verticalDis = verticalNormalized * flyDis

    local pathFirstPos = Vector3.Lerp(casterPos, targetPos, 0.25)
    pathFirstPos = pathFirstPos + (verticalDis / 4) * dir
    table.insert(path, pathFirstPos)

    local pathSecondPos = Vector3.Lerp(casterPos, targetPos, 0.5)
    table.insert(path, pathSecondPos)

    local pathThirdPos = Vector3.Lerp(casterPos, targetPos, 0.8)
    pathThirdPos = pathThirdPos - (verticalDis / 4) * dir
    table.insert(path, pathThirdPos)

    table.insert(path, targetPos)

    local pathBezier = {}
    for i = 0, 1, 0.1 do
        table.insert(pathBezier, self:_BezierMethod(i, path))
    end
    table.insert(pathBezier, targetPos)

    self._flyTime = flyDis * self._oneGridFlyTime

    local curve = DG.Tweening.Ease.Linear
    ---@type AnimationCurveHolder
    local animationCurveHolder = go.gameObject:GetComponent(typeof(AnimationCurveHolder))
    if animationCurveHolder then
        local curveList = animationCurveHolder.acurveList
        if curveList and curveList.Length > 0 then
            curve = curveList[0]
        end
    end

    go.transform:DOLocalPath(
        pathBezier,
        self._flyTime / 1000,
        DG.Tweening.PathType.CatmullRom,
        DG.Tweening.PathMode.Full3D
    ):SetEase(curve)

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            YIELD(TT, self._flyTime)

            self._world:DestroyEntity(effectEntity)
        end
    )
end

function PlaySkillTranspositionPhase:_BezierMethod(t, foceList)
    if table.count(foceList) < 2 then
        return foceList[1]
    end

    local temp = {}

    for i = 1, table.count(foceList) - 1 do
        -- local proportion = (1 - t) * foceList[i] + t * foceList[i + 1]
        local proportion =
            Vector3(
            (1 - t) * foceList[i].x + t * foceList[i + 1].x,
            (1 - t) * foceList[i].y + t * foceList[i + 1].y,
            (1 - t) * foceList[i].z + t * foceList[i + 1].z
        )

        table.insert(temp, proportion)
    end

    return self:_BezierMethod(t, temp)
end

function PlaySkillTranspositionPhase:_ShowShowLineRenderer(entity, show)
    ---@type EffectHolderComponent
    local effectHolderCmpt = entity:EffectHolder()
    if effectHolderCmpt then
        local effectList = effectHolderCmpt:GetPermanentEffect()

        for i, eff in ipairs(effectList) do
            -- if effectID and effectID == eff then
            local e = self._world:GetEntityByID(eff)
            if e and e:HasView() then
                local go = e:View():GetGameObject()

                local renderers = go:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)

                for i = 0, renderers.Length - 1 do
                    local line = renderers[i]
                    if line then
                        line.gameObject:SetActive(show)
                    end
                end
            end
            -- end
        end
    end
end
