--[[------------------
    技能表现的公共服务对象
--]] ------------------

_class("PlaySkillService", BaseService)
---@class PlaySkillService:BaseService
PlaySkillService = PlaySkillService

function PlaySkillService:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---固定的击退速度
    self._hitBackSpeed = 10

    ---最后一击的特效
    self._finalEffectEntity = nil

    self._curLoopAudioPlayingID = nil

    ---注册所有过程段执行
    self:RegistSkillPhaseFunc(world)

    self.m_listWaitTask = {}

    self._skillViewConditionHelper = SkillViewConditionHelper:New(self._world)
end

---@return SkillViewConditionHelper
function PlaySkillService:GetSkillViewConditionHelper()
    return self._skillViewConditionHelper
end

function PlaySkillService:CheckSourceCanTurn(source_entity)
    ---@type TrapRenderComponent
    local trapRenderCmpt = source_entity:TrapRender()
    if trapRenderCmpt then
        return false --是机关，不会转
    end

    ---@type BuffViewComponent
    local buff = source_entity:BuffView()
    if buff and buff:HasBuffEffect(BuffEffectType.Stun) then
        return false
        --有眩晕buff，不会转
    end

    if source_entity:HasTeam() then
        source_entity = source_entity:GetTeamLeaderPetEntity()
    end

    ---@type ConfigService
    local cfgsvc = self._world:GetService("Config")
    if source_entity:HasMonsterID() then
        ---@type MonsterConfigData
        local mstcfg = cfgsvc:GetMonsterConfigData()

        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local buffVal = utilData:GetEntityBuffValue(source_entity, "MONSTER_VIEW_CAN_TURN")
        if buffVal == nil then
            local cMonsterID = source_entity:MonsterID()
            if not mstcfg:CanTurn(cMonsterID:GetMonsterID()) then
                return false
            end
        elseif buffVal == 0 then
            return false
        end
    end

    if not source_entity:Location() then
        return false
    end

    return true
end

---启动技能表现过
function PlaySkillService:StartSkillRoutine(casterEntity, skillPhaseArray, skillId)
    local taskid =
    GameGlobal.TaskManager():CoreGameStartTask(self._SkillRoutineTask, self, casterEntity, skillPhaseArray, skillId)
    self:AddWaitFreeTask(taskid)
    return taskid
end

function PlaySkillService:_SkillRoutineTask(TT, casterEntity, skillPhaseArray, skillId)
    ---Buff释放技能之前的通知
    if casterEntity:EntityType():IsSkillHolder() then
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTBuffCastSkillAttackBegin:New(casterEntity, skillId))
    end

    --YIELD(TT)
    Log.notice("[skill] SkillRoutineTask start ", skillId, " Coroutine:", TaskManager:GetInstance().curTask.id)
    local phaseCount = #skillPhaseArray
    if phaseCount < 1 then
        Log.notice("phase count is ", phaseCount, Log.traceback())
        return
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    -- skillEffectResultContainer:SetSkillID(skillId)
    ---@type SkillPhaseDirectorBase
    local director = SkillPhaseDirectorBase:New(self._world)
    director:DoPlaySkillPhase(TT, casterEntity, skillPhaseArray, self._phaseFuncDic)
    if casterEntity:HasMonsterID() then --怪物普攻和释放技能播放成功
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTMonsterAttackOrSkillDamageEnd:New(casterEntity))
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTMonsterSkillDamageEnd:New(casterEntity, skillId))
    end
    ---Buff释放技能之后的通知
    if casterEntity:EntityType():IsSkillHolder() then
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTBuffCastSkillAttackEnd:New(casterEntity, skillId))
    end
    Log.notice("[skill] SkillRoutineTask End ", skillId, " Coroutine: ", TaskManager:GetInstance().curTask.id)
end

function PlaySkillService:_doSkillPosDirProc(casterEntity, PhaseData)
    ---@type SkillPhaseData
    ---@type SkillPosDirParam
    local posDirParam = PhaseData:GetPosDirParam()
    local gridlocation = casterEntity:GridLocation()

    local srcPos = gridlocation:GetGridPos()
    local srcDir = gridlocation:GetGridDir()

    if (posDirParam ~= nil) then
        local targetPos = srcPos
        local targetDir = srcDir
        if (posDirParam:GetPos() ~= nil) then
            targetPos = posDirParam:GetPos()
        end

        if (posDirParam:GetDir() ~= nil) then
            targetDir = posDirParam:GetDir()
        end
        casterEntity:SetLocation(targetPos, targetDir)
        --casterEntity:SetGridLocation(targetPos, targetDir)
        return srcPos, srcDir
    else
        return nil, nil
    end
end

function PlaySkillService:_SingleGridEffect(TT, gridEffectID, gridPos, bestEffectTime, targetGridType, bForbidFreshAll)
    ---@type BoardServiceRender
    local boardService = self._world:GetService("BoardRender")

    self._world:GetService("Effect"):CreateWorldPositionEffect(gridEffectID, gridPos)
    YIELD(TT, bestEffectTime)

    boardService:ReCreateGridEntity(targetGridType, gridPos, false)

    YIELD(TT)

    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")
    if piece_service then
        if nil == bForbidFreshAll or false == bForbidFreshAll then
            --刷新一次格子材质，针对有怪物占位的，这种等一帧，不合适，应该在view出来的时候做
            piece_service:RefreshPieceAnim()
        else
            local piecePos = Vector2.New(gridPos.x, gridPos.y)
            piece_service:SetPieceAnimNormal(piecePos)
        end
    end
end

local OutlineDirType = { Up = 1, Down = 2, Left = 3, Right = 4, LeftUp = 5, RightUp = 6, RightDown = 7, LeftDown = 8 }
local OutlineType = { Short = 1, LeftShort = 2, RightShort = 3, Long = 4 }
function PlaySkillService:_SetOutlineEntityPosAndDir(pos, outlineEntity, outlineDirType)
    local gridOutlineRadius = 0.52
    local outlinePos = pos
    local outlineDir = Vector2(0, 0)
    if outlineDirType == OutlineDirType.Up then
        outlinePos = pos + Vector2(0, gridOutlineRadius)
        outlineDir = Vector2(0, 1)
    elseif outlineDirType == OutlineDirType.Down then
        outlinePos = pos + Vector2(0, -gridOutlineRadius)
        outlineDir = Vector2(0, -1)
    elseif outlineDirType == OutlineDirType.Left then
        outlinePos = pos + Vector2(-gridOutlineRadius, 0)
        outlineDir = Vector2(-1, 0)
    elseif outlineDirType == OutlineDirType.Right then
        outlinePos = pos + Vector2(gridOutlineRadius, 0)
        outlineDir = Vector2(1, 0)
    end
    outlineEntity:SetLocation(outlinePos, outlineDir)
end

--endregion

---静帧
function PlaySkillService:FreezeFrame(targetEntity)
    ---@type ViewComponent
    local targetViewCmpt = targetEntity:View()
    if targetViewCmpt == nil then
        return
    end

    local targetObj = targetViewCmpt:GetGameObject()
    local targetAttachPoint = self:GetEntityRenderHitTransform(targetEntity)
    if targetAttachPoint == nil then
        Log.fatal("not hit attach point", targetObj.name)
        return
    end

    local targetPos = targetAttachPoint.position
    local finalEffectEntity = self:GetFinalEffect()
    if not finalEffectEntity then
        Log.fatal("not find final effect")
        return
    end
    ---@type ViewComponent
    local viewCmpt = finalEffectEntity:View()
    if viewCmpt ~= nil then
        local viewObj = viewCmpt:GetGameObject()
        viewObj:SetActive(true)
        viewObj.transform.position = targetPos
        GameGlobal.TaskManager():CoreGameStartTask(self._WaitFreezeEnd, self)
    end
end

function PlaySkillService:_WaitFreezeEnd(TT)
    YIELD(TT, BattleConst.FreezeDuration)

    local finalEffectEntity = self:GetFinalEffect()
    ---@type ViewComponent
    local viewCmpt = finalEffectEntity:View()
    if viewCmpt ~= nil then
        local viewObj = viewCmpt:GetGameObject()
        viewObj:SetActive(false)
    end
    ---恢复速度
    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
end
function PlaySkillService:ShowCasterEntity(casterEntityID)
    if self._world:MatchType() == MatchType.MT_PopStar then
        return
    end
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    if casterEntity:HasView() == false then
        Log.fatal("_ShowCasterEntity not has view")
        return
    end

    ---@type ViewComponent
    local viewCmpt = casterEntity:View()
    local gameObj = viewCmpt:GetGameObject()
    if gameObj == nil then
        Log.fatal("_ShowCasterEntity game obj is null")
        return
    end

    --如果是星灵 才设置队友的显示隐藏 施法者到队长的位置和朝向
    if casterEntity:HasPetPstID() then
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        local pets = teamEntity:Team():GetTeamPetEntities()
        for _, e in ipairs(pets) do
            if e:GetID() == casterEntity:GetID() then
                e:SetViewVisible(true)
            else
                e:SetViewVisible(false)
            end
        end

        local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
        ---@type LocationComponent
        local playerGridLocationCmpt = teamLeaderEntity:Location()

        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        if not utilData:PlayerIsDead(teamEntity) then
            casterEntity:SetLocation(playerGridLocationCmpt.Position:Clone(), playerGridLocationCmpt.Direction:Clone())
        end
    end
end

function PlaySkillService:ShowPlayerEntity(teamEntity)
    if self._world:MatchType() == MatchType.MT_PopStar then
        return
    end
    local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
    self:ShowCasterEntity(teamLeaderEntityID)
end

---@param TT TaskToken
---@param param HandleBeHitParam
function PlaySkillService:HandleBeHit(TT, param)
    local casterEntity = param:GetHandleBeHitParam_CasterEntity()
    local targetEntity = param:GetHandleBeHitParam_TargetEntity()
    local hitAnimName = param:GetHandleBeHitParam_HitAnimName()
    local hitEffectID = param:GetHandleBeHitParam_HitEffectID()
    local damageInfo = param:GetHandleBeHitParam_DamageInfo()
    local damageTextPos = param:GetHandleBeHitParam_DamagePos()
    local hitTurnTarget = param:GetHandleBeHitParam_HitTurnTarget()
    local deathClear = param:GetHandleBeHitParam_DeathClear()
    local isFinalHit = param:GetHandleBeHitParam_IsFinalHit()
    local skillID = param:GetHandleBeHitParam_SkillID()
    local hitBackSpeed = param:GetHandleBeHitParam_HitBackSpeed()
    local damageIndex = param:GetHandleBeHitParam_DamageIndex()
    local isPlayHitBack = param:GetHandleBeHitParam_PlayHitBack()
    local hitCasterEntity = param:GetHandleBeHitParam_HitCasterEntity() or casterEntity
    if not targetEntity then
        return
    end

    ---@type Entity
    local defenderHPMaster
    ---@type Entity
    local defenderEntity
    if targetEntity:HasTeam() then
        defenderHPMaster = targetEntity
        defenderEntity = targetEntity:GetTeamLeaderPetEntity()
    else
        defenderHPMaster = targetEntity
        defenderEntity = targetEntity
    end

    --buff通知
    local attackPos = damageInfo:GetAttackPos()
    if not attackPos then
        attackPos = casterEntity:GetRenderGridPosition()
    end

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:_OnAttackStart(TT, skillID, casterEntity, targetEntity, attackPos, damageTextPos, damageInfo)

    --静帧
    if isFinalHit then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        local finalAttackEntityID = skillEffectResultContainer:GetFinalAttackEntityID()
        if finalAttackEntityID then
            if finalAttackEntityID == targetEntity:GetID() then
                self:FreezeFrame(targetEntity)
            end
        else
            self:FreezeFrame(targetEntity)
        end
    end

    ---2020-04-25 韩玉信， 处理deathClear类型扩展为boolean 和 number两种
    local bEnabelDeathClear = false
    if deathClear then
        if type(deathClear) == "boolean" then
            bEnabelDeathClear = deathClear
        elseif type(deathClear) == "number" then
            if deathClear > 0 then
                bEnabelDeathClear = true
            end
        end
    end
    if bEnabelDeathClear then
        ---2020-02-21 韩玉信增加判断：如果是已经死亡的角色
        if nil == defenderHPMaster or defenderHPMaster:GetWhiteHP() <= 0 then
            return
        end
    end

    --被击转向没参数表示默认转向
    if hitTurnTarget == nil then
        hitTurnTarget = TurnToTargetType.Caster
    end

    if hitTurnTarget ~= TurnToTargetType.None then
        ---@type RenderEntityService
        local resvc = self._world:GetService("RenderEntity")
        resvc:TurnToTarget(defenderHPMaster, casterEntity, nil, nil, hitTurnTarget)
    end

    --1 被击动画(护盾 Miss 蓄力中不播放)
    self:_OnPlayHitAnim(targetEntity, defenderEntity, damageInfo, hitAnimName)

    --2 被击特效(除了闪避 都要播放)
    self:_OnPlayHitEffect(
        TT,
        casterEntity,
        defenderEntity,
        damageInfo,
        skillID,
        hitEffectID,
        damageTextPos,
        hitTurnTarget,
        hitCasterEntity
    )

    --2.1 被击特效补充（机关娜露在用-在被怪物打后，除了攻击技能自带的被击特效，然后一个自己的被击特效表现）
    ---@type TrapRenderComponent
    local trapRenderCmpt = targetEntity:TrapRender()
    if trapRenderCmpt then
        local hitSkillId = trapRenderCmpt:GetHitSkillID()
        if hitSkillId and hitSkillId > 0 and damageInfo:GetDamageValue() > 0 then
            ---@type PlaySkillService
            local playSkillService = self._world:GetService("PlaySkill")
            local tskId = playSkillService:PlaySkillView(targetEntity, hitSkillId)
        end
    end

    --3 伤害飘字
    local playDamageService = self._world:GetService("PlayDamage")

    local showType = playDamageService:SingleOrGrid(skillID)
    damageInfo:SetRenderGridPos(damageTextPos)
    damageInfo:SetShowType(showType)
    playDamageService:AsyncUpdateHPAndDisplayDamage(targetEntity, damageInfo, damageTextPos)
    --显示combo
    self:_ShowCombo(casterEntity, targetEntity, damageInfo)

    --4 爆点播放buff
    self:_OnPlayAddBuff(TT, casterEntity, targetEntity, damageInfo)

    --5 击退表现
    if isPlayHitBack then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        ---@type SkillHitBackEffectResult
        local hitbackResult =
        skillEffectResultContainer:GetEffectResultByTargetID(SkillEffectType.HitBack, defenderHPMaster:GetID())
        local processHitTaskID = nil
        if hitbackResult and not targetEntity:HasHitback() and not hitbackResult:GetHadPlay() then
            hitbackResult:SetHadPlay(true)
            processHitTaskID = self:ProcessHit(casterEntity, targetEntity, hitbackResult, hitBackSpeed)
        end
        ---等待击退/撞墙等处
        if processHitTaskID then
            while not TaskHelper:GetInstance():IsTaskFinished(processHitTaskID) do
                YIELD(TT)
            end
        end
        YIELD(TT)
        if hitbackResult then
            local pieceService = self._world:GetService("Piece")
            pieceService:RemovePrismAt(hitbackResult:GetPosTarget())
        end
    end

    --死亡清理[不能用deadflag判断，可能有多段伤害]
    if bEnabelDeathClear and targetEntity:GetWhiteHP() <= 0 then
        local nTaskID =
        GameGlobal.TaskManager():CoreGameStartTask(self._ClearDeathBody, self, casterEntity, targetEntity)
        self:AddWaitFreeTask(nTaskID)
    end

    --buff通知
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:_OnAttackEnd(TT, skillID, casterEntity, targetEntity, attackPos, damageTextPos, damageIndex, damageInfo)

    --机关死亡 --防止有些宝宝打碎石，碎石的被击表现会阻塞宝宝技能表现
    local nTaskID = GameGlobal.TaskManager():CoreGameStartTask(self.PlayHitTrap, self, casterEntity, targetEntity)
    self:AddWaitFreeTask(nTaskID)
end

---多阶段伤害型受击时的流
---@param casterEntity Entity 发起攻击
---@param targetEntity Entity 被击
---@param hitAnimName string 被击动画
---@param hitEffectID number 被击特效ID
---@param damageInfoList DamageInfo[] 伤害数据
---@param damageTextPos Vector2 伤害坐标
---@param hitTurnTarget number 受击后是否转向攻方
---@param isFinalHit bool 是否最后一
---@param skillID number 技能ID 用来判断技能是单体伤害还是格子伤害
function PlaySkillService:HandleBeHitMultiStage(
    TT,
    casterEntity,
    targetEntity,
    hitAnimName,
    hitEffectID,
    damageInfoList,
    damageTextPos,
    hitTurnTarget,
    isFinalHit,
    skillID,
    damageStageValueList,
    intervalTime)
    if not targetEntity then
        return
    end

    local listTask = {}

    local damageInfo = damageInfoList[1]
    local multiStageCount = table.count(damageInfoList)

    ---@type Entity
    local defenderHPMaster
    ---@type Entity
    local defenderEntity
    if targetEntity:HasTeam() then
        defenderHPMaster = targetEntity
        defenderEntity = targetEntity:GetTeamLeaderPetEntity()
    else
        defenderHPMaster = targetEntity
        defenderEntity = targetEntity
    end

    --buff通知
    local attackPos = casterEntity:GetRenderGridPosition()
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:_OnAttackStart(TT, skillID, casterEntity, targetEntity, attackPos, damageTextPos, damageInfo)

    --静帧
    local freezeFrame = false
    if isFinalHit then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        local finalAttackEntityID = skillEffectResultContainer:GetFinalAttackEntityID()
        if finalAttackEntityID then
            if finalAttackEntityID == targetEntity:GetID() then
                freezeFrame = true
            end
        else
            freezeFrame = true
        end
    end
    if freezeFrame then
        local nTask =
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                YIELD(TT, intervalTime * (multiStageCount - 1))
                self:FreezeFrame(targetEntity)
            end
        )
        table.insert(listTask, nTask)
    end

    --被击转向没参数表示默认转向
    if hitTurnTarget == nil then
        hitTurnTarget = true
    end
    if hitTurnTarget then
        ---@type RenderEntityService
        local resvc = self._world:GetService("RenderEntity")
        resvc:TurnToTarget(defenderHPMaster, casterEntity)
    end

    ---@type Entity
    local defenderHPMaster
    ---@type Entity
    local defenderEntity
    if targetEntity:HasTeam() then
        defenderHPMaster = targetEntity
        defenderEntity = targetEntity:GetTeamLeaderPetEntity()
    else
        defenderHPMaster = targetEntity
        defenderEntity = targetEntity
    end

    --1 被击动画(护盾 Miss 蓄力中不播放)
    local nTaskHitAnim =
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            for i = 1, multiStageCount do
                self:_OnPlayHitAnim(targetEntity, defenderEntity, damageInfo, hitAnimName)
                YIELD(TT, intervalTime)
            end
        end
    )
    table.insert(listTask, nTaskHitAnim)
    --2 被击特效(除了闪避 都要播放)
    if hitEffectID then
        local nTaskPlayHitEffect =
        GameGlobal.TaskManager():CoreGameStartTask(
                function(TT)
                    for i = 1, multiStageCount do
                        self:_OnPlayHitEffect(TT, casterEntity, defenderEntity, damageInfo, skillID, hitEffectID, damageTextPos)
                        YIELD(TT, intervalTime)
                    end
                end
        )
        table.insert(listTask, nTaskPlayHitEffect)
    end

    --2.1 被击特效补充（机关娜露在用-在被怪物打后，除了攻击技能自带的被击特效，然后一个自己的被击特效表现）
    ---@type TrapRenderComponent
    local trapRenderCmpt = targetEntity:TrapRender()
    if trapRenderCmpt then
        local hitSkillId = trapRenderCmpt:GetHitSkillID()
        if hitSkillId and hitSkillId > 0 and damageInfo:GetDamageValue() > 0 then
            ---@type PlaySkillService
            local playSkillService = self._world:GetService("PlaySkill")
            local tskId = playSkillService:PlaySkillView(targetEntity, hitSkillId)
        end
    end

    --3 多段伤害飘字
    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    for _, _damageInfo in ipairs(damageInfoList) do
        local showType = playDamageService:SingleOrGrid(skillID)
        _damageInfo:SetShowType(showType)
        _damageInfo:SetRenderGridPos(damageTextPos)
    end
    playDamageService:AsyncUpdateHPAndDisplayDamageMultiStage(
        targetEntity,
        damageInfoList,
        damageStageValueList,
        intervalTime
    )
    --显示combo
    self:_ShowCombo(casterEntity, defenderEntity, damageInfo)

    --4 爆点播放buff
    self:_OnPlayAddBuff(TT, casterEntity, targetEntity, damageInfo)

    --5 击退表现
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillHitBackEffectResult
    local hitbackResult =
    skillEffectResultContainer:GetEffectResultByTargetID(SkillEffectType.HitBack, defenderHPMaster:GetID())
    local processHitTaskID = nil
    if hitbackResult then
        processHitTaskID = self:ProcessHit(casterEntity, targetEntity, hitbackResult)
    end
    ---等待击退/撞墙等处
    if processHitTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(processHitTaskID) do
            YIELD(TT)
        end
    end
    YIELD(TT)
    if hitbackResult then
        local pieceService = self._world:GetService("Piece")
        pieceService:RemovePrismAt(hitbackResult:GetPosTarget())
    end

    --buff通知
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:_OnAttackEnd(TT, skillID, casterEntity, targetEntity, attackPos, damageTextPos, damageInfo)

    --6 机关死亡
    GameGlobal.TaskManager():CoreGameStartTask(self.PlayHitTrap, self, casterEntity, targetEntity) --防止有些宝宝打碎石，碎石的被击表现会阻塞宝宝技能表现

    while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
        YIELD(TT)
    end
end

---销毁可立即销毁的机关
function PlaySkillService:PlayHitTrap(TT, casterEntity, targetEntity)
    ---@type TrapRenderComponent
    local trapRenderCmpt = targetEntity:TrapRender()
    if not trapRenderCmpt then
        return
    end

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    if trapServiceRender:CanDestroyAtOnce(targetEntity) then
        trapServiceRender:PlayOneTrapDead(TT, targetEntity)
    end
end


--被击动画(护盾 Miss 蓄力中不播放)
---@param targetEntity Entity
function PlaySkillService:_OnPlayHitAnim(targetEntity, defenderEntity, damageInfo, hitAnimName)
    local performanceEntity = defenderEntity
    local performanceTargetEntity = targetEntity
    if defenderEntity:HasRenderPerformanceByAgent() then--N29Boss钻探者 本体隐藏，被击表现传递给底座怪
        ---@type RenderPerformanceByAgentComponent
        local agentCmpt = defenderEntity:RenderPerformanceByAgent()
        local agentEntityID = agentCmpt:GetAgentEntityID()
        local agentEntity = self._world:GetEntityByID(agentEntityID)
        if agentEntity then
            performanceEntity = agentEntity
            performanceTargetEntity = agentEntity
        end
    end
    local nDamageType = damageInfo:GetDamageType()
    if nDamageType == DamageType.Guard then
        --护盾受击特效
        if targetEntity:HasTrapID() and targetEntity:TrapRender():GetTrapType() == TrapType.Protected then
            self._world:GetService("Effect"):CreateEffect(BattleConst.AircraftHitShieldEffect, targetEntity)
        end
    elseif nDamageType == DamageType.Miss then
    else
        --蓄力中 不播放受击动画
        local playingSkill
        ---@type RenderStateComponent
        local renderState = targetEntity:RenderState()
        playingSkill = renderState and renderState:GetRenderStateType() == RenderStateType.PlayingSkill

        --眩晕中 不播放受击动画
        local isStun = performanceTargetEntity:GetAnimatorControllerBoolsData("Stun")

        if hitAnimName and not damageInfo:IsHPShieldGuard() and not playingSkill and not isStun then
            performanceEntity:SetAnimatorControllerTriggers({ hitAnimName })
        end
        --闪白效果
        local mtrAni = performanceEntity:MaterialAnimationComponent()
        if mtrAni and performanceEntity:BuffView() and
            not performanceEntity:BuffView():HasBuffEffect(BuffEffectType.NotPlayMaterialAnimation) and
            not mtrAni:IsPlayingCommonInvalid()
        then
            mtrAni:PlayHit()
        end

        if targetEntity:MonsterID() and targetEntity:MonsterID():GetDamageSyncMonsterID() then
            ---@type UtilDataServiceShare
            local utilDataSvc = self._world:GetService("UtilData")
            local damageSyncEntityList =  utilDataSvc:FindMonsterByMonsterID(targetEntity:MonsterID():GetDamageSyncMonsterID())
            for i, entity in ipairs(damageSyncEntityList) do
                local pos = entity:GetRenderGridPosition()
                ---@type DamageInfo
                local newDamageInfo = DamageInfo:New()
                newDamageInfo:Clone(damageInfo)
                newDamageInfo:SetShowPosition(pos)
                newDamageInfo:SetRenderGridPos(pos)
                newDamageInfo:SetTargetEntityID(entity:GetID())
                self:_OnPlayHitAnim(entity,entity,newDamageInfo, hitAnimName)
            end
        end
    end
end

--被击特效(除了闪避 都要播放)
function PlaySkillService:_OnPlayHitEffect(
    TT,
    casterEntity,
    defenderEntity,
    damageInfo,
    skillID,
    hitEffectID,
    damageTextPos,
    hitTurnTarget,
    hitCasterEntity)
    if not damageInfo or not damageInfo.GetDamageType then
        Log.fatal("11111")
    end
    local performanceEntity = defenderEntity
    if defenderEntity:HasRenderPerformanceByAgent() then--N29Boss钻探者 本体隐藏，被击表现传递给底座怪
        ---@type RenderPerformanceByAgentComponent
        local agentCmpt = defenderEntity:RenderPerformanceByAgent()
        local agentEntityID = agentCmpt:GetAgentEntityID()
        local agentEntity = self._world:GetEntityByID(agentEntityID)
        if agentEntity then
            performanceEntity = agentEntity
        end
    end
    local nDamageType = damageInfo:GetDamageType()
    if nDamageType == DamageType.Miss then
    else
        if hitEffectID then
            local damageShowType = self:GetService("PlayDamage"):SingleOrGrid(skillID)
            if type(hitEffectID) == "number" and hitEffectID > 0 then
                hitEffectID = { hitEffectID }
            end
            if type(hitEffectID) == "table" and #hitEffectID > 0 then
                for _, effID in ipairs(hitEffectID) do
                    ---@type Entity
                    local beHitEffectEntity =
                    self._world:GetService("Effect"):CreateBeHitEffect(
                        effID,
                        performanceEntity,
                        damageShowType,
                        damageTextPos
                    )
                    --设置被击特效方向 不能默认跟随被击者的朝向 因为被击者有的不会转向
                    if beHitEffectEntity and hitTurnTarget ~= TurnToTargetType.None then
                        --while (not beHitEffectEntity:HasView()) do
                        --    YIELD(TT)
                        --end
                        --
                        --YIELD(TT)

                        ---@type Vector3
                        local castPos = casterEntity:GetRenderGridPosition()
                        if not castPos then
                            if casterEntity:HasSuperEntity() then
                                -- skillHolder
                                castPos = casterEntity:GetSuperEntity():GetRenderGridPosition()
                            elseif casterEntity:HasSummoner() then
                                castPos = casterEntity:GetSummonerEntity():GetRenderGridPosition()
                            else
                                -- 容错
                                castPos = damageTextPos
                            end
                        end
                        local gridDir = damageTextPos - castPos
                        if hitTurnTarget == TurnToTargetType.PickupPos then
                            ----@type RenderPickUpComponent
                            local renderPickUpComponent = casterEntity:RenderPickUpComponent()
                            local firstPickUpPos = renderPickUpComponent:GetFirstValidPickUpGridPos()
                            --伤害格子和点选坐标的方向
                            gridDir = firstPickUpPos - damageTextPos
                        end
                        --local go = beHitEffectEntity:View():GetGameObject()
                        local view, go
                        if beHitEffectEntity then
                            view = beHitEffectEntity:View()
                        end
                        if view then
                            go = view:GetGameObject()
                        end

                        if go then
                            ---@type UnityEngine.Transform
                            local effectTransform = go.transform
                            --注意！这里设置的时候 entity还没有location组件，如果直接SetDirection，会导致存入一个0的position，所以需要连当前的position一起设置
                            beHitEffectEntity:SetLocation(effectTransform.position, gridDir)
                        end
                    end

                    if beHitEffectEntity ~= nil then
                        ---@type EffectControllerComponent
                        local effectCtrl = beHitEffectEntity:EffectController()
                        if effectCtrl ~= nil and casterEntity ~= nil then
                            if hitCasterEntity then
                                effectCtrl:SetEffectCasterID(hitCasterEntity:GetID())
                            else
                                effectCtrl:SetEffectCasterID(casterEntity:GetID())
                            end
                        end
                    end
                end
            end
        end
    end
end

--爆点播放buff
function PlaySkillService:_OnPlayAddBuff(TT, casterEntity, targetEntity, damageInfo)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    local damageStageIndex = damageInfo:GetDamageStageIndex()
    local buffResultArray =
    skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBuff, damageStageIndex)
    --这个damageInfo只播放指定的buffResult
    local beHitRefreshBuff = damageInfo:GetBeHitRefreshBuff()
    local selectPlayBuffResult = damageInfo:GetPlayBuffResult()
    if buffResultArray then
        ---@param v SkillBuffEffectResult
        for _, v in pairs(buffResultArray) do
            local buffArray = v:GetAddBuffResult()
            if buffArray then
                for _, seq in pairs(buffArray) do
                    local buffTargetEntityID = v:GetEntityID()
                    if targetEntity:GetID() == buffTargetEntityID then
                        local buffViewInstance = targetEntity:BuffView():GetBuffViewInstance(seq)
                        if buffViewInstance then --技能挂buff不一定有表现
                            if beHitRefreshBuff == false then
                                if selectPlayBuffResult == v then
                                    playBuffService:PlayAddBuff(TT, buffViewInstance, casterEntity:GetID())
                                end
                            else
                                playBuffService:PlayAddBuff(TT, buffViewInstance, casterEntity:GetID())
                            end
                        end
                    end
                end
            end
        end
    end
end

function PlaySkillService:_ClearDeathBody(TT, casterEntity, targetEntity)
    if targetEntity:HasMonsterID() then
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTCollectSouls:New(casterEntity, 1, { targetEntity }))
    end
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:_DoOneMonsterDead(TT, targetEntity)
end

function PlaySkillService:GetFinalAttack(world, casterEntity, phaseContext)
    local playFinalAttack = false

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local curDamageIndex = phaseContext:GetCurDamageResultIndex()
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
    skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)
    local damageResultStageCount = skillEffectResultContainer:GetEffectResultsStageCount(SkillEffectType.Damage)

    if skillEffectResultContainer:IsFinalAttack() and curDamageIndex == self:_GetFinalAttackIndex(damageResultArray) and
        curDamageResultStageIndex == damageResultStageCount
    then
        playFinalAttack = true
    end

    --可能在连线过程中触发机关，机关打死怪物。但是后面还有普攻没有播放出来，最后一下普攻也有静帧，则播放普攻的静帧
    if playFinalAttack and not casterEntity:HasPetPstID() then
        ---如果有星灵普攻是最后一击  取消本次的最后一击表现
        local teamEntity = world:Player():GetCurrentTeamEntity()
        local pets = teamEntity:Team():GetTeamPetEntities()
        ---@param petEntity Entity
        for i, petEntity in ipairs(pets) do
            ---@type SkillEffectResultContainer
            local petskillEffectResultContainer = petEntity:SkillRoutine():GetResultContainer()
            --星灵有技能结果
            if petskillEffectResultContainer and petskillEffectResultContainer:IsFinalAttack() then
                local petDamageResultArray =
                petskillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
                --技能中有伤害结果
                if petDamageResultArray and table.count(petDamageResultArray) > 0 then
                    playFinalAttack = false
                    return playFinalAttack
                end
            end
        end

        ---如果连线后面的机关有最后一击  取消本次的最后一次表现
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        local chainPathData = renderBoardEntity:RenderChainPath():GetRenderChainPath()

        if chainPathData then
            local triggerTrapList = {}
            local trapGroup = world:GetGroup(world.BW_WEMatchers.Trap)
            for i = 1, #chainPathData do
                for _, e in ipairs(trapGroup:GetEntities()) do
                    ---@type TrapRenderComponent
                    local trapRenderCmpt = e:TrapRender()
                    if trapRenderCmpt:GetTriggerSkillID() then
                        local pos = e:GridLocation().Position
                        if pos == chainPathData[i] then
                            table.insert(triggerTrapList, e)
                        end
                    end
                end
            end

            local finalTrap
            for i = #triggerTrapList, 1, -1 do
                local trapEntity = triggerTrapList[i]
                ---@type SkillEffectResultContainer
                local trapskillEffectResultContainer = trapEntity:SkillRoutine():GetResultContainer()
                if trapskillEffectResultContainer then
                    --不能用IsFinalAttack 判断  这是在每个机关播放技能前设置的。第一个播放的时候，第二个还没有设置
                    ---@type SkillDamageEffectResult[]
                    local damageResultAll =
                    trapskillEffectResultContainer:GetEffectResultsAsArray(
                        SkillEffectType.Damage,
                        curDamageResultStageIndex
                    )
                    if damageResultAll then
                        for _, result in ipairs(damageResultAll) do
                            local beAttackEntityID = result:GetTargetID()
                            local targetEntity = world:GetEntityByID(beAttackEntityID)
                            if targetEntity and targetEntity:HasMonsterID() then--beAttackEntityID可能是-1 技能空放
                                finalTrap = trapEntity
                                break
                            end
                        end
                    end
                end

                if finalTrap then
                    break
                end
            end

            if finalTrap and finalTrap:GetID() ~= casterEntity:GetID() then
                playFinalAttack = false
            end
        end
    end

    return playFinalAttack
end

function PlaySkillService:_GetFinalAttackIndex(damageResultArray)
    if not damageResultArray then
        return -1
    end
    for i = #damageResultArray, 1, -1 do
        local result = damageResultArray[i]
        local targetId = result:GetTargetID()
        if targetId ~= nil and targetId > 0 then
            return i
        end
    end
    return -1
end

---@param damageInfo DamageInfo
function PlaySkillService:_ShowCombo(casterEntity, defenderEntity, damageInfo)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer ~= nil then
        local isNormalAttack = skillEffectResultContainer:IsNormalAttack()
        if isNormalAttack == true then
            ---@type RenderBattleService
            local renderBattleService = self._world:GetService("RenderBattle")
            local curComboNum = renderBattleService:GetComboNum()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.DisplayCombo, curComboNum)
        end
    end
end

function PlaySkillService:_ClearCombo()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DisplayCombo, 0)
end

function PlaySkillService:GetFinalEffect()
    if self._finalEffectEntity ~= nil then
        return self._finalEffectEntity
    end

    local group = self._world:GetGroup(self._world.BW_WEMatchers.EntityType)
    for _, entity in ipairs(group:GetEntities()) do
        if entity:EntityType().Value == EntityType.FinalAttackEffect then
            self._finalEffectEntity = entity
        end
    end

    return self._finalEffectEntity
end

function PlaySkillService:GetLoopAudioPlayingID()
    return self._curLoopAudioPlayingID
end

function PlaySkillService:SetLoopAudioPlayingID(playingID)
    self._curLoopAudioPlayingID = playingID
end

function PlaySkillService:GetWaitFreeList()
    return self.m_listWaitTask
end

function PlaySkillService:AddWaitFreeTask(nTaskID)
    if nTaskID > 0 then
        self.m_listWaitTask[#self.m_listWaitTask + 1] = nTaskID
    end
end

function PlaySkillService:ResetWaitFreeList()
    table.clear(self.m_listWaitTask)
end

---@param dropAssetList table<number,RoleAsset,number>
---@param gridPos Vector2
function PlaySkillService:DoDropAnimation(dropAssetList, gridPos)
    if dropAssetList and #dropAssetList > 0 then
        for k, v in pairs(dropAssetList) do
            if v.asset.assetid == RoleAssetID.RoleAssetGold then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowDropCoinInfo, v.asset.count)
                ---@type EffectService
                local effectService = self._world:GetService("Effect")
                if v.effect and v.effect ~= 0 then
                    effectService:CreateWorldPositionEffect(v.effect, gridPos, true)
                end
                Log.warn(
                    "DropGold Count：",
                    v.asset.count,
                    "GridPos:",
                    tostring(gridPos),
                    "EffectID:",
                    v.effect,
                    "DebugTrack:",
                    Log.traceback()
                )
            elseif v.asset.assetid == RoleAssetID.RoleAssetMazeCoin then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowDropMazeCoinInfo)
                ---@type EffectService
                local effectService = self._world:GetService("Effect")
                if v.effect and v.effect ~= 0 then
                    effectService:CreateWorldPositionEffect(v.effect, gridPos, true)
                end
                Log.warn(
                    "DropGold Count：",
                    v.asset.count,
                    "GridPos:",
                    tostring(gridPos),
                    "EffectID:",
                    v.effect,
                    "DebugTrack:",
                    Log.traceback()
                )
            end
        end
    end
end

---2020-04-21 播放技能预览
function PlaySkillService:IsTaskFinished(taskID)
    local task = TaskManager:GetInstance():FindTask(taskID)
    if task ~= nil then
        --Log.fatal("task not finished ",taskID)
        return false
    else
        --Log.fatal("task has finished ",taskID)
    end
    return true
end

---启动技能的播放过程，纯表现函数
---skillID是个逻辑ID，这里播放的是这个逻辑ID对应的ViewID
---技能播放时需要的逻辑数据都在施法者身上
---@param casterEntity Entity 施法者
---@return number 技能播放的协程ID
function PlaySkillService:PlaySkillView(casterEntity, skillID)
    local waitTaskID = -1
    local skinId = 1
    if casterEntity:MatchPet() then
        skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
    end
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, casterEntity)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray(skinId)
    waitTaskID = self:StartSkillRoutine(casterEntity, skillPhaseArray, skillID)
    return waitTaskID
end

function PlaySkillService:PlaySkillViewSync(TT, casterEntity, skillID)
    local skinId = 1
    if casterEntity:MatchPet() then
        skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
    end
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, casterEntity)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray(skinId)
    self:_SkillRoutineTask(TT, casterEntity, skillPhaseArray, skillID)
end

function PlaySkillService:PlayCastAudio(TT, audioID, waitTime)
    if waitTime and waitTime > 0 then
        YIELD(TT, waitTime)
    end
    if audioID and audioID ~= 0 then
        AudioHelperController.PlayInnerGameSfx(audioID)
    end
end

---@return UnityEngine.Transform|nil
function PlaySkillService:GetEntityRenderHitTransform(e)
    ---@type ViewComponent
    local cView = e:View()
    if not cView then
        Log.error("entity has no ViewComponent")
        return
    end

    ---@type UnityEngine.GameObject|nil
    local go = cView:GetGameObject()
    if (not go) or (tostring(go) == "null") then
        Log.error("entity has ViewComponent, but no GameObject inside. ")
        return
    end

    local cstsfm = GameObjectHelper.FindChild(go.transform, "Hit")
    if cstsfm then
        return cstsfm
    end

    -- 兼容代码：因资源上有时会出现拼写错误，当大写的Hit未找到时，尝试用易错拼写查找
    cstsfm = GameObjectHelper.FindChild(go.transform, "hit")
    if cstsfm then
        return cstsfm
    end

    -- 如果到这里还没找到，直接报错，没hit点还了得，HOW DARE YOU
    Log.error("entity has ViewComponent and GameObject, but no Hit node here. GameObject name: ", tostring(go.name))
end

---@return UnityEngine.Transform|nil
function PlaySkillService:GetEntityRenderSelectBoneTransform(e, boneName)
    if not boneName then
        return self:GetEntityRenderHitTransform(e)
    end

    ---@type ViewComponent
    local cView = e:View()
    if not cView then
        Log.error("entity has no ViewComponent")
        return
    end

    ---@type UnityEngine.GameObject|nil
    local go = cView:GetGameObject()
    if (not go) or (tostring(go) == "null") then
        Log.error("entity has ViewComponent, but no GameObject inside. ")
        return
    end

    local cstsfm = GameObjectHelper.FindChild(go.transform, boneName)
    if cstsfm then
        return cstsfm
    end

    Log.error(
        "entity has ViewComponent and GameObject, but no ",
        boneName,
        " node here. GameObject name: ",
        tostring(go.name)
    )

    --找不到就返回根节点
    return go.transform
end
