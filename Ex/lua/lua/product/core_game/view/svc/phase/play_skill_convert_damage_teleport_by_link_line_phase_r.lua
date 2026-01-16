require "play_skill_phase_base_r"

---@class PlaySkillConvertDamageTeleportByLinkLinePhase: PlaySkillPhaseBase
_class("PlaySkillConvertDamageTeleportByLinkLinePhase", PlaySkillPhaseBase)
PlaySkillConvertDamageTeleportByLinkLinePhase = PlaySkillConvertDamageTeleportByLinkLinePhase

function PlaySkillConvertDamageTeleportByLinkLinePhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseConvertDamageTeleportByLinkLineParam
    local param = phaseParam

    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectConvertAndDamageByLinkLineResult
    local skillResult = resultContainer:GetEffectResultByArray(SkillEffectType.ConvertAndDamageByLinkLine)
    if not skillResult then
        return
    end

    self._skillID = resultContainer:GetSkillID()

    ---连线路径
    ---@type Vector2[]
    self._chainPath = skillResult:GetChainPath()
    ---瞬移结果
    ---@type SkillEffectResult_Teleport
    self._teleportResult = skillResult:GetTeleportResult()
    ---转色结果
    ---@type SkillConvertGridElementEffectResult
    self._convertResult = skillResult:GetConvertResult()
    ---伤害结果
    ---@type SkillDamageEffectResult
    self._damageResult = skillResult:GetDamageResult()

    ---开场效果
    self:_PlayOpening(param)

    ---等待开始延时
    local beginDelayTime = param:GetBeginDelayTime()
    if beginDelayTime > 0 then
        YIELD(TT, beginDelayTime)
    end

    ---移动&转色表现
    self._convertInfoList = {}
    if #self._chainPath > 1 then
        self:_DoWalk(TT, casterEntity, param)
    end

    ---清除所有连线（主要针对连线终点为怪物时）
    self:_DestroyLinkLine()

    if self._damageResult then
        ---伤害表现
        self:_DoDamage(TT, casterEntity, param)
    else
        ---回起点
        self:_DoBack(TT, casterEntity, param)
    end

    ---攻击后处理瞬移结果
    if self._teleportResult then
        self:_DoTeleport(TT, casterEntity)
    end

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    local nt = NTGridConvert:New(casterEntity, self._convertInfoList)
    nt:SetConvertEffectType(SkillEffectType.ConvertAndDamageByLinkLine)
    playBuffSvc:PlayBuffView(TT, nt)

    ---结束表现
    self:_PlayEnding(TT, param)
end

---@param param SkillPhaseConvertDamageTeleportByLinkLineParam
function PlaySkillConvertDamageTeleportByLinkLinePhase:_PlayOpening(param)
    ---摄像机特效
    local cameraEffID = param:GetCameraEffID()
    if cameraEffID and cameraEffID > 0 then
        ---@type Entity
        self._cameraEff = self._effectService:CreateScreenEffPointEffect(cameraEffID)
    end

    ---场景特效
    local sceneEffID = param:GetSceneEffID()
    local sceneEffPos = param:GetSceneEffPos()
    if sceneEffID and sceneEffID > 0 then
        ---@type Entity
        self._sceneEff = self._effectService:CreateWorldPositionEffect(sceneEffID, sceneEffPos)
    end
    ---场景特效动画
    local animNames = { param:GetSceneEffAnimIn(), param:GetSceneEffAnimIdle() }
    self:_PlayAnimation(self._sceneEff, animNames)

    ---开场音效
    AudioHelperController.PlayInnerGameSfx(param:GetStartAudioID())
end

---@param casterEntity Entity
---@param param SkillPhaseConvertDamageTeleportByLinkLineParam
function PlaySkillConvertDamageTeleportByLinkLinePhase:_DoWalk(TT, casterEntity, param)
    local moveTime = param:GetMoveSpeedTime() / 1000
    local moveSpeed = 1 / moveTime

    local hasWalkPoint = false
    if #self._chainPath > 0 then
        hasWalkPoint = true
    end

    ---移动动作
    local walkAnim = param:GetMoveAnim()

    if hasWalkPoint then
        self:_StartMoveAnimation(casterEntity, walkAnim, true)
        ---移动效果（同精英怪效果）
        local moveTrailEffect = param:GetMoveTrailEffect()
        self:_PlayMoveTrailEffect(casterEntity, moveTrailEffect)
    end

    ---@type Entity[]
    self._convertEffList = {}

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local pathLength = #self._chainPath
    local hasAttack = (self._damageResult ~= nil)
    for index, walkPos in ipairs(self._chainPath) do
        ---取当前的渲染坐标
        local curPos = boardServiceRender:GetRealEntityGridPos(casterEntity)

        ---移动中
        if index ~= 1 then
            casterEntity:AddGridMove(moveSpeed, walkPos, curPos)

            local walkDir = walkPos - curPos
            casterEntity:SetDirection(walkDir)

            while casterEntity:HasGridMove() do
                YIELD(TT)
            end
        end

        ---转色特效
        local convertEff = self:_PlayConvertEff(index, pathLength, walkPos, hasAttack, param)
        if convertEff then
            table.insert(self._convertEffList, convertEff)
            ---音效
            AudioHelperController.PlayInnerGameSfx(param:GetConvertAudioID())
        end

        ---转色
        local pos, pieceType = self:_GetConvertPosAndType(index, pathLength, walkPos, hasAttack)
        if pos and pieceType then
            self:_PlayConvert(TT, pos, pieceType)
        end

        ---删除连线
        self:_DestroyLinkLine(walkPos)
    end

    if hasWalkPoint then
        self:_StartMoveAnimation(casterEntity, walkAnim, false)
        self:_PlayMoveTrailEffect(casterEntity)
    end
end

---@param casterEntity Entity
function PlaySkillConvertDamageTeleportByLinkLinePhase:_StartMoveAnimation(casterEntity, anim, isMove)
    local curVal = casterEntity:GetAnimatorControllerBoolsData(anim)
    if curVal ~= isMove then
        local statTable = {}
        statTable[anim] = isMove
        casterEntity:SetAnimatorControllerBools(statTable)
    end
end

---@param casterEntity Entity
function PlaySkillConvertDamageTeleportByLinkLinePhase:_PlayMoveTrailEffect(casterEntity, trailEffect)
    if casterEntity and casterEntity:HasView() then
        ---@type UnityEngine.GameObject
        local go = casterEntity:View():GetGameObject()
        local rootTF = go.transform:Find("Root")
        local trailEffectExCmpt = rootTF.gameObject:GetComponent(typeof(TrailsFX.TrailEffectEx))
        if trailEffectExCmpt then
            UnityEngine.Object.Destroy(trailEffectExCmpt)
        end
        casterEntity:RemoveTrailEffectEx()

        if trailEffect then
            --trailEffect = "eff_jingying_01.asset"
            trailEffectExCmpt = rootTF.gameObject:AddComponent(typeof(TrailsFX.TrailEffectEx))

            local resServ = self._world.BW_Services.ResourcesPool
            local containerTrailEffect = resServ:LoadAsset(trailEffect)
            if not containerTrailEffect then
                resServ:CacheAsset(trailEffect, 1)
                containerTrailEffect = resServ:LoadAsset(trailEffect)
            end
            assert(containerTrailEffect)

            casterEntity:AddTrailEffectEx(containerTrailEffect, trailEffectExCmpt)
        end
    end
end

---@param index number
---@param maxCount number
---@param pos Vector2
---@param hasAttack boolean
---@param param SkillPhaseConvertDamageTeleportByLinkLineParam
---@return Entity
function PlaySkillConvertDamageTeleportByLinkLinePhase:_PlayConvertEff(index, maxCount, pos, hasAttack, param)
    local needConvertEff = false
    if hasAttack then
        if index ~= maxCount then
            needConvertEff = true
        end
    else
        if index ~= 1 then
            needConvertEff = true
        end
    end

    if not needConvertEff then
        return
    end

    local convertEffID = param:GetConvertEffID()
    if convertEffID and convertEffID > 0 then
        local convertEff = self._effectService:CreateWorldPositionEffect(convertEffID, pos)
        return convertEff
    end
end

---@param index number
---@param maxCount number
---@param pos Vector2
---@param hasAttack boolean
---@return Vector2, PieceType
function PlaySkillConvertDamageTeleportByLinkLinePhase:_GetConvertPosAndType(index, maxCount, pos, hasAttack)
    if hasAttack then
        ---有伤害，但不需要瞬移，则无需转色
        if not self._teleportResult then
            return
        end

        ---有瞬移结果，且目标位置在连线头部和尾部，则提取瞬移结果中的转色
        if index == 1 then
            return self._teleportResult:GetPosOld(), self._teleportResult:GetColorOld()
        elseif index == maxCount then
            return self._teleportResult:GetPosNew(), self._teleportResult:GetColorNew()
        end
    end

    ---提取转色结果中的转色
    if self._convertResult then
        local convertPosList = self._convertResult:GetTargetGridArray()
        local convertType = self._convertResult:GetTargetElementType()
        for _, convertPos in ipairs(convertPosList) do
            if convertPos == pos then
                return pos, convertType
            end
        end
    end
end

---@param pos Vector2
---@param pieceType PieceType
function PlaySkillConvertDamageTeleportByLinkLinePhase:_PlayConvert(TT, pos, pieceType)
    ---收集转色信息
    local oldGridType = PieceType.None
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    local gridEntity = pieceSvc:FindPieceEntity(pos)
    ---@type PieceComponent
    local pieceCmpt = gridEntity:Piece()
    if pieceCmpt then
        oldGridType = pieceCmpt:GetPieceType()
    end
    local convertInfo = NTGridConvert_ConvertInfo:New(pos, oldGridType, pieceType)
    table.insert(self._convertInfoList, convertInfo)

    ---转色
    ---@type BoardServiceRender
    local boardService = self._world:GetService("BoardRender")
    boardService:ReCreateGridEntity(pieceType, pos, false)

    --YIELD(TT)

    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")
    if piece_service then
        piece_service:SetPieceAnimNormal(pos)
    end
end

---删除对应点的连线，若不传参数，则代表全部删除
---@param moveInPos Vector2
function PlaySkillConvertDamageTeleportByLinkLinePhase:_DestroyLinkLine(moveInPos)
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    local removeList = {}

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    for _, linkLineEntity in ipairs(allEntities) do
        local pos = boardServiceRender:GetRealEntityGridPos(linkLineEntity)
        if not moveInPos or pos == moveInPos then
            table.insert(removeList, linkLineEntity)
        end
    end

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    for _, e in ipairs(removeList) do
        linkageRenderService:DestroyLinkLine(e)
    end
end

---@param casterEntity Entity
---@param param SkillPhaseConvertDamageTeleportByLinkLineParam
function PlaySkillConvertDamageTeleportByLinkLinePhase:_DoDamage(TT, casterEntity, param)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---转向怪物
    local targetPos = self._damageResult:GetGridPos()
    local curPos = boardServiceRender:GetRealEntityGridPos(casterEntity)
    local attackDir = targetPos - curPos
    casterEntity:SetDirection(attackDir)

    ---攻击动作
    local attackAnim = param:GetAttackAnim()
    casterEntity:SetAnimatorControllerTriggers({ attackAnim })
    ---音效
    AudioHelperController.PlayInnerGameSfx(param:GetAttackAudioID())
    ---蓄力特效
    local gatherEffIDList = param:GetGatherEffIDList()
    if gatherEffIDList then
        for _, effID in ipairs(gatherEffIDList) do
            self._effectService:CreateEffect(effID, casterEntity)
        end
    end

    ---攻击特效延时
    local attackEffDelayTime = param:GetAttackEffDelayTime()
    if attackEffDelayTime then
        YIELD(TT, attackEffDelayTime)
    end

    ---攻击特效
    local attackEffID = param:GetAttackEffID()
    if attackEffID and attackEffID > 0 then
        self._effectService:CreateEffect(attackEffID, casterEntity)
    end

    ---被击延时
    local hitDelayTime = param:GetHitDelayTime()
    if hitDelayTime then
        hitDelayTime = hitDelayTime - attackEffDelayTime
        if hitDelayTime > 0 then
            YIELD(TT, hitDelayTime)
        end
    end

    ---目标被击表现
    local targetID = self._damageResult:GetTargetID()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    ---@type DamageInfo
    local damageInfo = self._damageResult:GetDamageInfo(1)
    local hitAnimName = param:GetHitAnim()
    local skillID = self._skillID

    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(casterEntity)
        :SetHandleBeHitParam_TargetEntity(targetEntity)
        :SetHandleBeHitParam_HitAnimName(hitAnimName)
        :SetHandleBeHitParam_DamageInfo(damageInfo)
        :SetHandleBeHitParam_DamagePos(targetPos)
        :SetHandleBeHitParam_DeathClear(false)
        :SetHandleBeHitParam_IsFinalHit(false)
        :SetHandleBeHitParam_SkillID(skillID)
    self._skillService:HandleBeHit(TT, beHitParam)

    ---攻击表现完成延时
    local attackEffTime = param:GetAttackEffTime()
    if attackEffTime then
        local delayTime = attackEffTime - hitDelayTime
        YIELD(TT, delayTime)
    end
end

---@param casterEntity Entity
---@param param SkillPhaseConvertDamageTeleportByLinkLineParam
function PlaySkillConvertDamageTeleportByLinkLinePhase:_DoBack(TT, casterEntity, param)
    ---回到起点延时
    local teleportDelayTime = param:GetTeleportDelayTime()
    if teleportDelayTime then
        YIELD(TT, teleportDelayTime)
    end

    ---音效
    AudioHelperController.PlayInnerGameSfx(param:GetTeleportAudioID())

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local curPos = boardServiceRender:GetRealEntityGridPos(casterEntity)

    if #self._chainPath == 0 then
        return
    end
    local targetPos = self._chainPath[1]

    ---角色消失
    self:_RoleShow(casterEntity, false, false)
    ---消失特效
    local disappearEffID = param:GetDisappearEffID()
    if disappearEffID and disappearEffID > 0 then
        self._effectService:CreateWorldPositionEffect(disappearEffID, curPos)
    end

    ---消失时长
    local disappearTime = param:GetDisappearTime()
    if disappearTime then
        YIELD(TT, disappearTime)
    end

    ---出现特效
    local appearEffID = param:GetAppearEffID()
    if appearEffID and appearEffID > 0 then
        self._effectService:CreateWorldPositionEffect(appearEffID, targetPos)
    end

    ---角色出现延时
    local appearDelayTime = param:GetAppearDelayTime()
    if appearDelayTime then
        YIELD(TT, appearDelayTime)
    end
    casterEntity:SetPosition(targetPos)
    self:_RoleShow(casterEntity, true, true)
end

function PlaySkillConvertDamageTeleportByLinkLinePhase:_RoleShow(entity, showRole, showBloodSlider)
    entity:SetViewVisible(showRole)

    local sliderEntityID = 0
    if entity:HasPetPstID() then
        ---@type Entity
        local captainEntity = entity:Pet():GetOwnerTeamEntity()
        sliderEntityID = captainEntity:HP():GetHPSliderEntityID()
    else
        sliderEntityID = entity:HP():GetHPSliderEntityID()
    end
    local sliderEntity = self._world:GetEntityByID(sliderEntityID)
    if sliderEntity then
        sliderEntity:SetViewVisible(showBloodSlider)
    end
end

---@param casterEntity Entity
---@param param SkillPhaseConvertDamageTeleportByLinkLineParam
function PlaySkillConvertDamageTeleportByLinkLinePhase:_DoTeleport(TT, casterEntity)
    local newDir = self._teleportResult:GetDirNew()
    local newPos = self._teleportResult:GetPosNew()
    local oldPos = self._teleportResult:GetPosOld()

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    if casterEntity:HasPetPstID() then
        trapServiceRender:ShowHideTrapAtPos(newPos, false)

        ---@type Entity
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        local teamLeaderEntity = teamEntity:Team():GetTeamLeaderEntity()
        local pets = teamEntity:Team():GetTeamPetEntities()
        ---@param petEntity Entity
        for _, petEntity in ipairs(pets) do
            petEntity:SetPosition(newPos)
        end
        teamEntity:SetLocation(newPos, newDir)
        teamLeaderEntity:SetLocation(newPos, newDir)

        --处理棱镜格
        pieceService:RemovePrismAt(newPos)
    end

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    local nt = NTTeleport:New(casterEntity, oldPos, newPos)
    playBuffSvc:PlayBuffView(TT, nt)
end

---@param param SkillPhaseConvertDamageTeleportByLinkLineParam
function PlaySkillConvertDamageTeleportByLinkLinePhase:_PlayEnding(TT, param)
    ---摄像机特效消失动画
    local cameraOutAnim = param:GetCameraEffAnimOut()
    if cameraOutAnim then
        self:_PlayAnimation(self._cameraEff, { cameraOutAnim })
    end

    ---音效
    AudioHelperController.PlayInnerGameSfx(param:GetStartAudioID())

    ---场景特效和转色特效消失动画延时
    local sceneOutDelayTime = param:GetSceneOutDelayTime()
    if sceneOutDelayTime then
        YIELD(TT, sceneOutDelayTime)
    end

    ---场景特效消失动画
    local sceneOutAnim = param:GetSceneEffAnimOut()
    if sceneOutAnim then
        self:_PlayAnimation(self._sceneEff, { sceneOutAnim })
    end

    ---转色消失动画
    local convertOutAnim = param:GetConvertEffAnimOut()
    if self._convertEffList then
        for _, entity in ipairs(self._convertEffList) do
            self:_PlayAnimation(entity, { convertOutAnim })
        end
    end

    local endDelayTime = param:GetEndDelayTime()
    if endDelayTime then
        YIELD(TT, endDelayTime)
    end

    ---删除特效实体
    self._world:DestroyEntity(self._cameraEff)
    self._world:DestroyEntity(self._sceneEff)
    if self._convertEffList then
        for _, entity in ipairs(self._convertEffList) do
            self._world:DestroyEntity(entity)
        end
    end
end

---@param entity Entity
function PlaySkillConvertDamageTeleportByLinkLinePhase:_PlayAnimation(entity, animNames)
    if entity and entity:HasView() then
        local go = entity:View():GetGameObject()
        ---@type UnityEngine.Animation
        local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
        if anim == nil then
            Log.fatal("Cant play legacy animation, animation not found in ", go.name)
            return
        end
        if table.count(animNames) > 1 then
            anim:Stop()
            for i = 1, #animNames do
                anim:PlayQueued(animNames[i])
            end
        else
            anim:Play(animNames[1])
        end
    end
end
