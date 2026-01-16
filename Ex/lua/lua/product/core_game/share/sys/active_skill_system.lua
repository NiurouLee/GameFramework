--[[------------------------------------------------------------------------------------------
    ActiveSkillSystem：
    1.主流程中的光灵主动技施法状态、机关主动技施法（风船、温蒂的羽毛）
    2.跨度是从玩家按下发动按钮后，直到技能施法完成
]] --------------------------------------------------------------------------------------------
require "main_state_sys"

---@class ActiveSkillSystem:MainStateSystem
_class("ActiveSkillSystem", MainStateSystem)
ActiveSkillSystem = ActiveSkillSystem

---重载函数，返回主动技状态标识码
---@return GameStateID 状态标识
function ActiveSkillSystem:_GetMainStateID()
    return GameStateID.ActiveSkill
end

---主动技的施法流程比较长，未来应该可以合并一些阶段
---@param TT token 协程识别码，服务端是nil
function ActiveSkillSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local casterEntity = self:_GetActiveSkillCasterEntity(teamEntity)

    self:_DoRenderCheckNoGhost(TT, teamEntity, casterEntity)
    ---主动技开始时的统一的表现行为，现在只做了两件事儿
    ---打开Effect相机
    ---重置技能等待协程ID的队列
    self:_DoRenderPreActiveSkillStart(TT)

    ---保存施法者位置，后面处理瞬移效果时会用到
    local posCasterOld = casterEntity:GetGridPosition()

    ---计算主动技效果，触发光灵BUFF，通知表现层结果
    self:_DoLogicCastActiveSkill(teamEntity, casterEntity)

    ---主动技的施法过程中，可能会导致某些机关的死亡，这里需要结算一次
    self:_DoLogicTrapDeadSkill()

    ---主动技的施法过程中，可能会导致某些怪物的死亡，这里结算死亡怪物逻辑
    self:_DoLogicActiveSkillMonsterDead(teamEntity, casterEntity)

    ---主动技开始的表现通知，里面做了判断，只会在光灵主动技时通知
    self:_DoRenderNotifyActiveSkillStart(TT, teamEntity, casterEntity)

    ---计算最后一击，应该是个表现函数，现在是作为逻辑函数在执行
    local isFinalAttack = self:_DoLogicCalcIsFinalAttack()

    ---播放主动技
    local castSkillTaskID = self:_DoRenderPlayActiveSkill(isFinalAttack, teamEntity, casterEntity)

    ---启动主动技引导
    local guideTaskID = self:_DoRenderGuidActiveSkill(TT, teamEntity, casterEntity)

    ---------------------------主动技施法的等待-------------------------------------
    ---以下可以合并成一个函数
    ---等待主动技引导协程结束
    self:_WaitTasksEnd(TT, {guideTaskID}, true)

    ---等待主动技施法结束
    self:_WaitTasksEnd(TT, {castSkillTaskID})

    ---等待技能施法协程结束
    self:_DoRenderWaitPlaySkillTaskFinish(TT)
    -------------------------------------------------------------------------------

    ---重置格子动画表现
    self:_DoRenderResetPieceAnim(TT, teamEntity, casterEntity)

    ---重置预览
    self:_DoRenderResetPreview(TT, teamEntity, casterEntity)

    ---设置统计数据
    self:_DoLogicUpdateBattleStat(teamEntity, casterEntity)

    ---抢在怪物死亡刷新之前，通知主动技施法结束，MSG25917
    self:_DoRenderNotifyActiveFinishBeforeMonsterDead(TT, teamEntity, casterEntity)

    ---怪物死亡刷新 表现
    self:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
    
    local skillID = self:_DoLogicGetActiveSkillID(teamEntity)
    ---通知表现主动技施法结束
    self:_DoRenderNotifyActiveSkillFinish(TT, teamEntity, casterEntity,skillID)

    ---触发技能结束的引导(已过期)
    self:_DoRenderGuideActiveSkillEnd(TT, teamEntity, casterEntity)

    ---需要在主动技流程结束后，做的表现
    ---取消暗屏等
    self:_DoRenderShowAfterActiveSkill(TT, teamEntity, casterEntity)
    ---消灭星星隐藏施法者
    self:_DoRenderPopStarHideCasterEntity(TT, casterEntity)

    ---逻辑 等待主动技瞬移完成  检查触发机关
    ---todo:需要检查下这个逻辑所对应的需求
    local listTrapTrigger = self:_DoLogicWaitTeleportFinish(teamEntity, casterEntity, posCasterOld)
    self:_DoLogicMonsterDead() ---怪物死亡刷新 逻辑
    self:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity, casterEntity) ---表现  等待主动技瞬移完成  检查触发机关

    -- 这里再刷一次，是因为主动技瞬移触发的机关会打死额外的怪物
    self:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
    ---机关死亡逻辑
    self:_DoLogicTrapDie()
    ---机关死亡表现
    self:_DoRenderTrapDie(TT)
    --------------------------反制buff----------------------------
    ---计算反制buff触发的逻辑
    self:_DoLogicCalcBuffAntiAttack(teamEntity, casterEntity)
    ---反制表现
    self:_DoRenderPlayBuffAntiAttack(TT, teamEntity, casterEntity)
    -- 这里再刷一次
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
    --------------------------------------------------------------

    ---------------------------主动技结束后刷怪-------------------------------------
    ---比如情报关，当玩家释放完主动技后，需要根据场上的怪物存量，决定是否要刷新怪出来
    ---刷怪逻辑
    local traps, monsters = self:_DoLogicSpawnInWaveMonsters(MonsterWaveInternalTime.ActiveSkill)
    ---刷怪表现
    self:_DoRenderInWave(TT, traps, monsters)
    ------------------------------------------------------------------------------

    ---------------------------反制AI-----------------------------
    ---玩家释放过主动技，斯叶特和夏尔会执行一次AI逻辑
    ---判断如果施法者不是光灵，不触发
    ---计算反制AI逻辑
    local monsterEntityIDArray, refreshAntiEntityIDList = self:_DoLogicCalcAntiAttack(casterEntity)
    ---反制表现
    self:_DoRenderPlayAntiAttack(TT, monsterEntityIDArray)
    self:_ClearShareSkillResult()
    ---刷新放了反制技能的
    self:_DoLogicRefreshAntiAttackParam(refreshAntiEntityIDList)
    self:_DoRenderRefreshAntiAttackParam(TT, refreshAntiEntityIDList)
    --------------------------------------------------------------

    -----------------------清除主动技组件信息---------------------------
    ---重置逻辑拾取组件数据
    self:_DoLogicResetPickUp(teamEntity)

    ---重置表现拾取组件
    self:_DoRenderResetPickUp()

    self:_DoLogicActiveSkillEnd(teamEntity, casterEntity)
    self:_DoRenderActiveSkillEnd(TT,teamEntity, casterEntity)

    --同步格子颜色
    self:_DoLogicSyncPieceType()

    --需求调整：阿克希亚不再需要清除扫描结果了
    --self:_DoLogicClearLastScan(casterEntity)

    -----------------------清除主动技组件信息---------------------------

    ---主状态机切换
    self:_DoLogicSwitchMainState(teamEntity)

    ---触发技能结束的引导
    self:_DoRenderGuideActiveSkillRealEnd(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoLogicActiveSkillMonsterDead(teamEntity, casterEntity)
    local deadMonsterList = self:_DoLogicMonsterDead()
end

function ActiveSkillSystem:_DoLogicCalcAntiAttack(casterEntity)
    local monsterEntityIDArray = {}
    if not casterEntity:HasPetPstID() then
        return monsterEntityIDArray
    end

    ---@type BuffLogicService
    local buffSvc = self.world:GetService("BuffLogic")
    if buffSvc:IsPetNotTriggerAntiAttack(casterEntity) then
        return monsterEntityIDArray
    end

    ---@type AIService
    local aiService = self.world:GetService("AI")
    local orderArray = aiService:StatLogicOrders(AILogicPeriodType.Anti)
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.Anti)

    local refreshAntiEntityIDList = {}

    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    for _, orderElement in ipairs(orderArray) do
        for _, aiEntity in ipairs(orderElement[2]) do
            local nt = NTMonsterPostAntiAttack:New(aiEntity)
            triggerSvc:Notify(nt)
            table.insert(monsterEntityIDArray, aiEntity:GetID())

            ---@type AIComponentNew
            local aiCmpt = aiEntity:AI()
            if aiCmpt:GetAntiSkill() then
                table.insert(refreshAntiEntityIDList, aiEntity:GetID())
            end
        end
    end

    ---@type BattleStatComponent
    local cBattleStat = self.world:BattleStat()

    if (#monsterEntityIDArray) > 0 then
        -- 如果本次触发了反制AI，则将反制触发者记录下来
        cBattleStat:SetLastAntiTriggerEntityID(casterEntity:GetID())
    else
        cBattleStat:SetLastAntiTriggerEntityID(nil)
    end

    return monsterEntityIDArray, refreshAntiEntityIDList
end
---返回主动技的施法者
---@return Entity
function ActiveSkillSystem:_GetActiveSkillCasterEntity(teamEntity)
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local casterPetEntityID = activeSkillCmpt:GetActiveSkillCasterEntityID()
    local casterEntity = self._world:GetEntityByID(casterPetEntityID)
    return casterEntity
end

---是否是星灵主动技施法
function ActiveSkillSystem:_IsPetCastActiveSkill(teamEntity)
    ---@type UtilDataServiceShare
    local shareDataSvc = self._world:GetService("UtilData")
    return shareDataSvc:IsPetCastActiveSkill(teamEntity)
end

----------------------------------------------------------------
---逻辑行为
---处理主动技计算逻辑的主流程
---如果有机会重构的话，应该拆成三个小函数
---计算主动技、针对宝宝的BUFF通知、通知表现层逻辑结果
----------------------------------------------------------------
function ActiveSkillSystem:_DoLogicCastActiveSkill(teamEntity, casterEntity)
    local ntBeforeActiveSkillAttackStart = NTBeforeActiveSkillAttackStart:New(casterEntity)
    self._world:GetService("Trigger"):Notify(ntBeforeActiveSkillAttackStart)

    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local activeSkillID = activeSkillCmpt:GetActiveSkillID()
    ---清理玩家身上的技能数据，有可能还挂着上一次放技能时的数据
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    skillEffectResultContainer:Clear()

    ---重置第二属性标记，到这里有可能玩家还在使用第二属性
    ---@type ElementComponent
    local playerElementCmpt = casterEntity:Element()
    if playerElementCmpt then
        playerElementCmpt:SetUseSecondaryType(false)
    end

    Log.debug("CastActiveSkill skillID=", activeSkillID, " entity=", casterEntity:GetID())

    ---实际的技能计算行为
    ---@type SkillLogicService
    local logicService = self._world:GetService("SkillLogic")
    logicService:CalcSkillEffect(casterEntity, activeSkillID, SkillType.Active)

    ---下面这些是只给光灵使用的通知类型，机关施放主动技的时候不做通知
    if casterEntity:HasPetPstID() then
        local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
        local totalDamage = 0
        if damageResultArray then
            for _, damageResult in ipairs(damageResultArray) do
                totalDamage = totalDamage + damageResult:GetTotalDamage()
            end
        end

        local notifyData = NTActiveSkillAttackEnd:New(casterEntity, activeSkillID)
        notifyData:InitSkillResult(activeSkillID, skillEffectResultContainer:GetScopeResult())
        self._world:GetService("Trigger"):Notify(notifyData)

        -- 下面这个和NTActiveSkillAttackEnd必须同步。加入通知的原因是MSG25917。
        local ntASAEBeforeMonsterDead = NTActiveSkillAttackEndBeforeMonsterDead:New(casterEntity, activeSkillID)
        ntASAEBeforeMonsterDead:InitSkillResult(activeSkillID, skillEffectResultContainer:GetScopeResult())
        self._world:GetService("Trigger"):Notify(ntASAEBeforeMonsterDead)

        self._world:GetService("Trigger"):Notify(NTActiveSkillDamageEnd:New(casterEntity, totalDamage))

        --主动技自己扣血的通知
        ---@type SkillEffectCostCasterHPResult[]
        local costCasterHPResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.CostCasterHP)
        local costCasterHP = 0
        if costCasterHPResultArray then
            for _, costResult in ipairs(costCasterHPResultArray) do
                local damageInfo = costResult:GetDamageInfo()
                local damageValue = damageInfo:GetDamageValue()
                local damageOnHpValue = damageInfo:GetChangeHP()--只看实际血量上的变化
                costCasterHP = costCasterHP + (-1 * damageOnHpValue)
            end
        end
        self._world:GetService("Trigger"):Notify(NTActiveSkillCostCasterHPEnd:New(casterEntity, costCasterHP))

        self._world:GetDataLogger():AddDataLog("OnActiveSkillEnd", casterEntity, activeSkillID, totalDamage)
    elseif casterEntity:HasTrapID() then
        local notifyData = NTTrapActiveSkillEnd:New(casterEntity, activeSkillID)
        self._world:GetService("Trigger"):Notify(notifyData)
    end

    ------------------通知表现层主动技结果 服务端不需要 可以改掉-------------------
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RActiveAttackData(casterEntity,activeSkillID)

    --主动技结束后的格子颜色变化同步表现
    svc:L2RBoardLogicData()
    ----------------------------------------------------------------------------
end

function ActiveSkillSystem:_DoLogicUpdateBattleStat(teamEntity, casterEntity)
    --统计主动技杀怪
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetOneActiveSkillKillCount(teamEntity,#monsterGroup:GetEntities())

    ---统计主动技能转色
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local resultDic = skillEffectResultContainer:GetEffectResultDict()
    for k, v in pairs(resultDic) do --不能改ipairs
        battleStatCmpt:StatisticsColorSkillCount(teamEntity,k)
    end
end

function ActiveSkillSystem:_DoLogicCalcIsFinalAttack()
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local isFinalAttack = battleService:IsFinalAttack()
    return isFinalAttack
end

---主动技计算完毕后单独结算伤害打死的机关的死亡技
function ActiveSkillSystem:_DoLogicTrapDeadSkill()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:CalcActiveSkillDeadTrapDeadSkill()
    self:_DoLogicTrapDie()
end

function ActiveSkillSystem:_DoLogicResetPickUp(teamEntity)
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    logicPickUpCmpt:ResetLogicPickUp()
end

function ActiveSkillSystem:_DoLogicSwitchMainState(teamEntity)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local isTriggerDimension = boardServiceLogic:IsPlayerOnDimension(teamEntity)
    --local levelFinish = battleService:CheckLevelFinish()

    local nextState = self:_DoCheckNextState(teamEntity)

    ---触发任意门
    if isTriggerDimension then
        if nextState == 2 then
            self._world:BattleStat():SetTriggerDimensionFlag(TriggerDimensionFlag.RoundResult)
        elseif nextState == 1 then
            self._world:BattleStat():SetTriggerDimensionFlag(TriggerDimensionFlag.WaitInput)
        end
        self._world:EventDispatcher():Dispatch(GameEventType.ActiveSkillFinish, 3)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.ActiveSkillFinish, nextState)
    end
end

---检查下一个切换过的状态机
function ActiveSkillSystem:_DoCheckNextState(teamEntity)
    local battleStatCmpt = self._world:BattleStat()

    local nextState = 0
    if battleStatCmpt:AssignWaveResult() then
        nextState = 1
    else
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        local allMonsterDead = battleService:CheckAllMonstersDead(teamEntity)
        local specificTrapDead = battleService:CheckSpecificTrapDead()

        if allMonsterDead and specificTrapDead then
            local isLastWave = battleStatCmpt:IsLastWave()
            if isLastWave then
                nextState = 1
            else
                nextState = 2
            end
        else
            nextState = 1
        end

        local waveFinish = battleService:BattleCalculation(teamEntity)
        if waveFinish then
            nextState = 2
        end
    end

    return nextState
end

function ActiveSkillSystem:_DoLogicActiveSkillEnd(teamEntity, casterEntity)
    --清理拾取组件
    casterEntity:RemoveActiveSkillPickUpComponent()

    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    activeSkillCmpt:SetActiveSkillID(nil, nil)
end

---@return Entity[]
function ActiveSkillSystem:_DoLogicWaitTeleportFinish(teamEntity, casterEntity, posCasterOld)
    ---触发瞬移后的机关表现
    local posCasterNew = casterEntity:GetGridPosition()
    local bHaveTeleport = posCasterNew ~= posCasterOld
    if not bHaveTeleport then
        local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
        ---@type SkillEffectResult_Teleport
        local teleportResultNew = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, 1)
        if teleportResultNew then--只有自己队伍瞬移需要在这里触发机关
            local targetEntityID = teleportResultNew:GetTargetID()
            local targetEntity = self._world:GetEntityByID(targetEntityID)
            if targetEntity and (targetEntity:HasTeam() or targetEntity:HasPet()) then
                local targetTeamEntity = targetEntity
                if targetTeamEntity:HasPet() then
                    targetTeamEntity = targetEntity:Pet():GetOwnerTeamEntity()
                end
                local isLocalTeam = self._world:Player():IsLocalTeamEntity(targetTeamEntity)
                if isLocalTeam then
                    bHaveTeleport = true
                end
            end
        end
    end
    local listTrapTrigger = nil
    if bHaveTeleport then
        ---@type TrapServiceLogic
        local sTrapLogic = self._world:GetService("TrapLogic")
        listTrapTrigger = sTrapLogic:TriggerTrapByTeleport(teamEntity, true) --宝宝瞬移触发机关时只传队伍实体
    end
    return listTrapTrigger
end

function ActiveSkillSystem:_DoLogicCalcBuffAntiAttack(teamEntity, casterEntity)
    --技能是星灵主动技
    local isPetActiveSkill = self:_IsPetCastActiveSkill(teamEntity)
    if isPetActiveSkill then
        local ntActiveSkillAntiAttack = NTActiveSkillAntiAttack:New(casterEntity)
        self._world:GetService("Trigger"):Notify(ntActiveSkillAntiAttack)
    end
end

function ActiveSkillSystem:_DoLogicGetActiveSkillID(teamEntity)
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local activeSkillID = activeSkillCmpt:GetActiveSkillID()
    return activeSkillID
end

function ActiveSkillSystem:_DoLogicRefreshAntiAttackParam(refreshAntiEntityIDList)
    if not refreshAntiEntityIDList or table.count(refreshAntiEntityIDList) == 0 then
        return
    end

    for _, entityID in ipairs(refreshAntiEntityIDList) do
        local entity = self._world:GetEntityByID(entityID)
        ---@type AttributesComponent
        local attributeCmpt = entity:Attributes()

        local roundCount = "MaxAntiSkillCountPerRound"
        local curValue = attributeCmpt:GetAttribute(roundCount)
        local newValue = curValue - 1
        if newValue < 0 then
            newValue = 0
        end

        attributeCmpt:Modify(roundCount, newValue)

        --放完主动技当前CD回复到最大CD
        local curAntiCount = attributeCmpt:GetAttribute("WaitActiveSkillCount")
        if curAntiCount == 0 then
            local originalAntiCount = attributeCmpt:GetAttribute("OriginalWaitActiveSkillCount")
            attributeCmpt:Modify("WaitActiveSkillCount", originalAntiCount)
        end
    end
end

function ActiveSkillSystem:_ClearShareSkillResult()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    boardEntity:ReplaceShareSkillResult()
end

--需求调整：阿克希亚不再需要清除扫描结果了
--function ActiveSkillSystem:_DoLogicClearLastScan(casterEntity)
--    if not casterEntity:HasMatchPet() then
--        return
--    end
--
--    local matchPet = casterEntity:MatchPet():GetMatchPet()
--    local featureList = matchPet:GetFeatureList() or {feature = {}}
--    if featureList.feature[FeatureType.Scan] then
--        -- 释放过后要清除上次的扫描结果
--        local eBoard = self._world:GetBoardEntity()
--        local cLogicFeature = eBoard:LogicFeature()
--        cLogicFeature:ClearLastScan()
--
--        local cLogicFeature = self._world:GetBoardEntity():LogicFeature()
--        casterEntity:SkillInfo():SetActiveSkillID(cLogicFeature:GetScanEmptySkillID())
--    end
--end

--------------------------------------表现接口-----------------------------------------
---
function ActiveSkillSystem:_DoRenderCheckNoGhost(TT, teamEntity, casterEntity)
end
function ActiveSkillSystem:_DoRenderPreActiveSkillStart(TT)
end

function ActiveSkillSystem:_DoRenderNotifyActiveSkillStart(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderGuidActiveSkill(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderWaitPlaySkillTaskFinish(TT)
end

function ActiveSkillSystem:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderResetPieceAnim(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderResetPreview(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderNotifyActiveSkillFinish(TT, teamEntity, casterEntity,skillID)
end

function ActiveSkillSystem:_DoRenderNotifyActiveFinishBeforeMonsterDead(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderGuideActiveSkillEnd(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderGuideActiveSkillRealEnd(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderShowAfterActiveSkill(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderPlayActiveSkill(isFinalAttack, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderInWave(TT, traps, monsters)
end

function ActiveSkillSystem:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderPlayAntiAttack(TT, monsterEntityIDArray)
end

function ActiveSkillSystem:_DoRenderResetPickUp()
end
function ActiveSkillSystem:_DoRenderActiveSkillEnd(TT,teamEntity, casterEntity)
end
function ActiveSkillSystem:_DoRenderPlayBuffAntiAttack(TT, teamEntity, casterEntity)
end

function ActiveSkillSystem:_DoRenderRefreshAntiAttackParam(TT, refreshAntiEntityIDList)
end

function ActiveSkillSystem:_DoRenderPopStarHideCasterEntity(TT, casterEntity)
end
