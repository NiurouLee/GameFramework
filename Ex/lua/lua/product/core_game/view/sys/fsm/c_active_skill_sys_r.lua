--[[------------------------------------------------------------------------------------------
    ClientActiveSkillSystem_Render：客户端实现主动技状态的表现部分
]] --------------------------------------------------------------------------------------------

require "active_skill_system"

---@class ClientActiveSkillSystem_Render:ActiveSkillSystem
_class("ClientActiveSkillSystem_Render", ActiveSkillSystem)
ClientActiveSkillSystem_Render = ClientActiveSkillSystem_Render

function ClientActiveSkillSystem_Render:_DoRenderCheckNoGhost(TT, teamEntity, casterEntity)
    if not EDITOR then
        return
    end

    ---删掉创建的玩家虚影
    local ghostEntities = self._world:GetGroup(self._world.BW_WEMatchers.Ghost):GetEntities()
    if #ghostEntities > 0 then
        Log.exception("[GhostDestroyCheck] Ghost still alive. current skillID: ")
    end
end

function ClientActiveSkillSystem_Render:_DoRenderPreActiveSkillStart(TT)
    --启动effect相机
    self._world:MainCamera():EnableEffectCamera(true)

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ResetWaitFreeList()
end

function ClientActiveSkillSystem_Render:_DoRenderNotifyActiveSkillStart(TT, teamEntity, casterEntity)
    --技能是星灵主动技
    local isPetActiveSkill = self:_IsPetCastActiveSkill(teamEntity)
    if isPetActiveSkill then
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTActiveSkillAttackStart:New(casterEntity))
    end
end

function ClientActiveSkillSystem_Render:_DoRenderGuidActiveSkill(TT, teamEntity, casterEntity)
    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    guideService:FinishGuideWeakLine() -- 重置弱连线
    local guideTaskId =
        guideService:Trigger(GameEventType.GuidePlayerHandleFinish, GuidePlayerHandle.MainSkillFinish, casterEntity)
    return guideTaskId
end

function ClientActiveSkillSystem_Render:_DoRenderWaitPlaySkillTaskFinish(TT)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    local listWaitTask = playSkillService:GetWaitFreeList()
    self:_WaitTasksEnd(TT, listWaitTask)
end

---@param listTrapTrigger Entity[]
function ClientActiveSkillSystem_Render:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity, casterEntity)
    ---@type PlaySkillInstructionService
    local sPlaySkillInstruction = self._world:GetService("PlaySkillInstruction")
    local listTrapTask = sPlaySkillInstruction:PlayTrapTrigger(TT, casterEntity, listTrapTrigger)
    self:_WaitTasksEnd(TT, listTrapTask)
end

function ClientActiveSkillSystem_Render:_DoRenderResetPieceAnim(TT, teamEntity, casterEntity)
    ---战斗结束
    --格子刷新一次材质
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()
    pieceService:RefreshMonsterAreaOutLine(TT)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_ResetGridElement
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ResetGridElement)
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    if result then
        local array = result:GetResetGridData()
        playBuffService:PlayBuffView(TT, NTResetGridElement:New(array, casterEntity))
        playBuffService:PlayBuffView(TT, NTResetGridFlushTrap:New())
    end
end

function ClientActiveSkillSystem_Render:_DoRenderResetPreview(TT, teamEntity, casterEntity)
    ---@type PreviewConvertElementComponent
    local previewConvertElementCmpt = casterEntity:PreviewConvertElement()
    if previewConvertElementCmpt ~= nil then
        previewConvertElementCmpt:SetTempConvertElementDic({})
    else
        Log.notice("Clear Convert Element no cmpt")
    end
end

function ClientActiveSkillSystem_Render:_DoRenderNotifyActiveSkillFinish(TT, teamEntity, casterEntity,activeSkillID)
    local isPetActiveSkill = self:_IsPetCastActiveSkill(teamEntity)
    if isPetActiveSkill then
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTActiveSkillAttackEnd:New(casterEntity))
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTActiveSkillDamageEnd:New(casterEntity))
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTActiveSkillCostCasterHPEnd:New(casterEntity))
    end
    if casterEntity:HasTrapID() then
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTTrapActiveSkillEnd:New(casterEntity, activeSkillID))
    end
end

--MSG25917，这个必须和_DoRenderNotifyActiveSkillFinish同步修改
function ClientActiveSkillSystem_Render:_DoRenderNotifyActiveFinishBeforeMonsterDead(TT, teamEntity, casterEntity)
    local isPetActiveSkill = self:_IsPetCastActiveSkill(teamEntity)
    if isPetActiveSkill then
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTActiveSkillDamageEnd:New(casterEntity))
        self._world:GetService("PlayBuff"):PlayBuffView(TT, NTActiveSkillAttackEndBeforeMonsterDead:New(casterEntity))
    end
end

function ClientActiveSkillSystem_Render:_DoRenderGuideActiveSkillEnd(TT, teamEntity, casterEntity)
    local guideService = self._world:GetService("Guide")
    local guideTaskId =
        guideService:Trigger(GameEventType.GuidePlayerSkillFinish, GuidePlaySkillFinish.MainSkillFinish, casterEntity)
    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
end

function ClientActiveSkillSystem_Render:_DoRenderGuideActiveSkillRealEnd(TT, teamEntity, casterEntity)
    local guideService = self._world:GetService("Guide")
    local guideTaskId =
        guideService:Trigger(GameEventType.GuidePlayerSkillRealFinish, GuidePlaySkillFinish.MainSkillFinish, casterEntity)
    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
end

function ClientActiveSkillSystem_Render:_DoRenderShowAfterActiveSkill(TT, teamEntity, casterEntity)
    local isPetActiveSkill = self:_IsPetCastActiveSkill(teamEntity)
    --如果释放主动技的是机关
    if not isPetActiveSkill then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowCanMoveArrow)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.TrapPowerVisible, true)
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ShowPlayerEntity(teamEntity)

    --隐藏effect相机
    self._world:MainCamera():EnableEffectCamera(false)

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    --关闭暗屏
    previewActiveSkillService:StopDarkScreenImmediately()

    self:_RefreshAllHpPos()
end
function ClientActiveSkillSystem_Render:_RefreshAllHpPos()
    local hpGroup = self._world:GetGroup(self._world.BW_WEMatchers.HP)
    if hpGroup then
        local targetEntitys = hpGroup:GetEntities()
        if targetEntitys then
            for i, e in ipairs(targetEntitys) do
                ---@type HPComponent
                local hpCmpt = e:HP()
                if hpCmpt then
                    hpCmpt:SetHPPosDirty(true)
                end
            end
        end
    end
end
function ClientActiveSkillSystem_Render:_DoRenderPlayActiveSkill(isFinalAttack, teamEntity, casterEntity)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2RActiveAttackResult
    local result = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ActiveAttack)
    local skillResult = result:GetSkillResult()

    local activeSkillID = result:GetL2RActiveAttackResult_SkillID()
    if casterEntity:HasPetPstID() then
        GameGlobal.UAReportForceGuideEvent(
            "FightSpellMainSkill",
            {
                activeSkillID,
                casterEntity:PetPstID():GetTemplateID()
            },
            false,
            true
        )
    end

    --技能演播
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local skinId = 1
    if casterEntity:MatchPet() then
        skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
    end
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, casterEntity)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray(skinId)

    --显示自己隐藏其他人
    --胆小鬼赫伯（赫柏？）的功能：策划不希望因为个别宝宝的功能，在cfg_pet_battle_skill表上增加新列，协商后同意用常量表控制
    if not table.icontains(BattleConst.NoShowCasterEntityOnPreview, activeSkillID) then
        playSkillService:ShowCasterEntity(casterEntity:GetID())
    end

    casterEntity:SkillRoutine():ClearSkillRoutine()
    casterEntity:SkillRoutine():SetResultContainer(skillResult)
    ---检查静帧效果，内部会判断是否是玩家施法，这个方法更适合放在玩家阶段去做
    self:_CheckFreezeTime(casterEntity, isFinalAttack)

    local waitTaskID = playSkillService:StartSkillRoutine(casterEntity, skillPhaseArray, activeSkillID)

    return waitTaskID
end

---@param casterEntity Entity 施法者
---@param targetIDArray Array 目标列表
function ClientActiveSkillSystem_Render:_CheckFreezeTime(casterEntity, isFinalAttack)
    if not casterEntity:HasPetPstID() then
        return
    end

    if not isFinalAttack then
        return
    end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local targetIDArray = scopeResult:GetTargetIDs()
    if table.count(targetIDArray) <= 0 then
        return
    end

    skillEffectResultContainer:SetFinalAttack(true)

    ---有些特殊的效果，需要在这里选择最后一击的目标，例如米亚
    self:_SelectFinalAttackEntityID(skillEffectResultContainer)

    self:_PatchFinalAttackForSpecificPet(casterEntity, skillEffectResultContainer)
end

---@param skillEffectResultContainer SkillRoutineComponent
function ClientActiveSkillSystem_Render:_SelectFinalAttackEntityID(skillEffectResultContainer)
    ---米亚大招特殊处理
    ---@type SkillEffectResult_RandAttack
    local results = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.RandAttack)
    if results ~= nil then
        local count = results:GetListDefenderCount()
        if count > 0 then
            skillEffectResultContainer:SetFinalAttackEntityID(-1)
        end
    end
end

---@param container SkillEffectResultContainer
function ClientActiveSkillSystem_Render:_PatchFinalAttackForSpecificPet(casterEntity, container)
    if not casterEntity:HasPetPstID() then
        return
    end

    ---@type PetPstIDComponent
    local cPetPstID = casterEntity:PetPstID()
    if cPetPstID:GetTemplateID() == 1600271 then
        ---@type BuffViewComponent
        local buffViewCmpt = casterEntity:BuffView()
        if buffViewCmpt:HasBuffByID(4300271) or buffViewCmpt:HasBuffByID(4300272) then
            --判断一下连锁技是否有伤害结果,有就最后一击是连锁技,没有就最后一击是主动技
            local skillHolderName = "default" --这里是因为buff里没有配置  所以默认名字
            local skillHolderID = casterEntity:GetSkillHolder(skillHolderName)
            ---@type Entity
            local skillHolder = self._world:GetEntityByID(skillHolderID)
            if not skillHolder then
                return
            end

            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = skillHolder:SkillRoutine():GetResultContainer()
            local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
            local hasTargetDamageResultArray = {}
            if damageResultArray then
                for _, v in ipairs(damageResultArray) do
                    ---@type SkillDamageEffectResult
                    local damageResult = v
                    local targetEntityID = damageResult:GetTargetID()
                    local targetEntity = self._world:GetEntityByID(targetEntityID)
                    --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
                    if targetEntity then
                        table.insert(hasTargetDamageResultArray, damageResult)
                    end
                end
            end

            if table.count(hasTargetDamageResultArray) > 0 then
                container:SetFinalAttack(false)
            end
        end
    end
end

function ClientActiveSkillSystem_Render:_DoRenderInWave(TT, traps, monsters)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:PlaySpawnInWave(TT, traps, monsters)
end

function ClientActiveSkillSystem_Render:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
    --通知怪物被主动技能杀死后洗手灵魂消息
    local monsterDeadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadFlag)
    for i, e in ipairs(monsterDeadGroup:GetEntities()) do
        if e:HasMonsterID() and not e:HasShowDeath() then
            self._world:GetService("PlayBuff"):PlayBuffView(TT, NTCollectSouls:New(casterEntity, 1, {e}))
        end
    end

    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:DoAllMonsterDeadRender(TT)
end

function ClientActiveSkillSystem_Render:_DoRenderPlayAntiAttack(TT, monsterEntityIDArray)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end


    --放了反制技能表现的，反制技能表现结束会清除AIRecorderComponent
    local refreshAntiEntityIDList = {}
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type AIRecorderComponent
    local recorderCmpt = renderBoardEntity:AIRecorder()
    local orderList = recorderCmpt:GetOrderList()

    playAISvc:PlayParallelSpellResult(TT)
    for i, order in ipairs(orderList) do
        recorderCmpt:SetCurrentOrder(order)
        --放技能的
        local entityIDList = recorderCmpt:GetAICasterIDList()
        for _, entityID in ipairs(entityIDList) do
            table.insert(refreshAntiEntityIDList, entityID)
        end
    end

    --刷新血条上的反制CD
    for _, entityID in ipairs(monsterEntityIDArray) do
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, entityID)
    end

    playAISvc:DoCommonRountine(TT)

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    for _, id in ipairs(monsterEntityIDArray) do
        local nt = NTMonsterPostAntiAttack:New(self._world:GetEntityByID(id))
        playBuffSvc:PlayBuffView(TT, nt)
    end

    return refreshAntiEntityIDList
end

function ClientActiveSkillSystem_Render:_DoRenderResetPickUp()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    pickUpTargetCmpt:Reset()
end

function ClientActiveSkillSystem_Render:_DoRenderPlayBuffAntiAttack(TT, teamEntity, casterEntity)
    --技能是星灵主动技
    local isPetActiveSkill = self:_IsPetCastActiveSkill(teamEntity)
    if isPetActiveSkill then
        local ntActiveSkillAntiAttack = NTActiveSkillAntiAttack:New(casterEntity)
        self._world:GetService("PlayBuff"):PlayBuffView(TT, ntActiveSkillAntiAttack)
    end
end

function ClientActiveSkillSystem_Render:_DoRenderRefreshAntiAttackParam(TT, refreshAntiEntityIDList)
    if not refreshAntiEntityIDList or table.count(refreshAntiEntityIDList) == 0 then
        return
    end

    for _, entityID in ipairs(refreshAntiEntityIDList) do
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, entityID)
    end
end
function ClientActiveSkillSystem_Render:_DoRenderActiveSkillEnd(TT,teamEntity, casterEntity)
    if casterEntity then
        casterEntity:RemoveRenderPickUpComponent()
    end
end

---@param casterEntity Entity
function ClientActiveSkillSystem_Render:_DoRenderPopStarHideCasterEntity(TT, casterEntity)
    if self._world:MatchType() ~= MatchType.MT_PopStar then
        return
    end
    if casterEntity:HasPetPstID() then
        casterEntity:SetViewVisible(false)
    end
end
