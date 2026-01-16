--[[------------------------------------------------------------------------------------------
    MainStateSystem：主状态机的状态处理基类
]] --------------------------------------------------------------------------------------------

require "unique_reactive_system"

_class("MainStateSystem", UniqueReactiveSystem)
---@class MainStateSystem:UniqueReactiveSystem
MainStateSystem = MainStateSystem

function MainStateSystem:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end
    if (not GameFSMComponent:IsInstanceOfType(component)) then
        --Log.fatal('battle enter system intreasted==false componsent.name=',component._className)
        return false
    end
    if (component:CurStateID() == self:_GetMainStateID()) then
        return true
    end
    return false
end

function MainStateSystem:Filter(world)
    return true
end

---------------------------------定义主流程----------------------------------------
---@param world MainWorld
function MainStateSystem:ExecuteWorld(world)
    self._world = world
    --Log.debug("HandleGameFsm:", GetEnumKey("GameStateID", self:_GetMainStateID()))
    ---@type RenderBattleService
    self._renderBattleService = self._world:GetService("RenderBattle")
    if self._world:RunAtServer() then
        self:MainStateEnter()
    else
        GameGlobal.TaskManager():CoreGameStartTask(self.MainStateEnter, self)
    end
end

function MainStateSystem:MainStateEnter(TT)
    self:_OnMainStateEnter(TT)
    --处理命令
    self:_HandleEntityCommand()
    --清理buff
    self:_DoLogicAutoRemoveBuff()
    --处理同步
    self:_DoLogicBattleSync()
end
---------------------------------定义主流程 End---------------------------------------

---------------------------------子状态继承的方法--------------------------------------
---状态处理必须重写此方法
---@return GameStateID 状态标识
function MainStateSystem:_GetMainStateID()
end

---状态处理必须重写此方法
---客户端这个函数为协程函数；服务端没有协程，TT参数是nil
function MainStateSystem:_OnMainStateEnter(TT)
end
---------------------------------子状态继承的方法 End----------------------------------

---对局中很多地方都有“如果波次战斗结束则直接进入波次结算”的逻辑
---@return boolean true表示波次战斗结束
function MainStateSystem:_IsBattleEnd()
    local isBattleEnd, isWaveFinished = self:IsBattleEnded()
    self:SetStatBattleWaveResult(isWaveFinished)

    return isBattleEnd
end

function MainStateSystem:SetStatBattleWaveResult(isWaveFinished)
    ---@type BattleStatComponent
    local cBattleStat = self._world:BattleStat()
    cBattleStat:SetBattleWaveResult(isWaveFinished)
end

function MainStateSystem:_WaitTasksEnd(TT, waitTaskIDList, notCheckTimeOut)
    if waitTaskIDList == nil then
        return
    end

    if not self._world:RunAtServer() then
        while not TaskHelper:GetInstance():IsAllTaskFinished(waitTaskIDList, notCheckTimeOut) do
            YIELD(TT)
        end
    end
end

---服务端立即返回
function MainStateSystem:_WaitTime(TT, msTime)
    if not self._world:RunAtServer() then
        YIELD(TT, msTime)
    end
end

function MainStateSystem:_DoLogicAutoRemoveBuff()
    ---@type BuffLogicService
    local buffLogic = self._world:GetService("BuffLogic")
    buffLogic:AutoRemoveUnloadedBuff()
end

function MainStateSystem:_DoLogicBattleSync()
    ---@type SyncLogicService
    local syncService = self._world:GetService("SyncLogic")
    syncService:DoBattleSync()
end

function MainStateSystem:_DoLogicSyncPieceType()
    local svc = self._world:GetService("L2R")
    svc:L2RSyncPieceType()
end

function MainStateSystem:_CompareLogicRenderHP(enable)
    local ignoreEntityIds = {}
    if self._world:MatchType() == MatchType.MT_Maze then
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        ignoreEntityIds[teamEntity:GetID()] = 1
    end

    local st = self:_GetMainStateID()
    local hpLog = {}
    local attrGroup = self._world:GetGroup(self._world.BW_WEMatchers.Attributes)
    for i, e in ipairs(attrGroup:GetEntities()) do
        if not ignoreEntityIds[e:GetID()] then
            local val = e:Attributes():GetCurrentHP()
            if val and e:HP() then
                local var = e:HP():GetRedHP()
                if val ~= var then
                    hpLog[e:GetID()] = {logicHP = val, renderHP = var}
                    if ForceSyncHP then
                        Log.debug("ForceSyncHP entityID=", e:GetID(), " logicHP=", val, " renderHP=", var)
                        self:_RefreshRenderHP(e, val)
                    end
                end
            end
        end
    end
    ---自动测试环境下需要关闭血量不同步报警，如果血量同步足够稳定，才能去掉，不然自动测试会一直卡主
    if enable and next(hpLog) then
        hpLog[1] = {fsm = GetEnumKey("GameStateID", st)}
        Log.exception(echo(hpLog))
        self._world:GetService("AutoFight"):EnableAutoMove(false)
    end
end

function MainStateSystem:_RefreshRenderHP(e, val)
    --HUD血条
    e:ReplaceRedHPAndWhitHP(val)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local greyVal = utilDataSvc:GetEntityBuffValue(e,"GreyHPValue") or 0

    e:ReplaceGreyHP(greyVal)
    --Boss UI 血条
    local curShowBossHP = e:BuffView():HasBuffEffect(BuffEffectType.CurShowBossHP)
    if e:HasBoss() or curShowBossHP then
        local maxhp = e:HP():GetMaxHP()
        local redhp = e:HP():GetRedHP()
        local hpPercent = redhp / maxhp
        --当血量<1%时，显示1%
        if redhp > 0 and hpPercent < 0.01 then
            hpPercent = 0.01
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossRedHp, e:GetID(), hpPercent, redhp, maxhp)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossWhiteHp, e:GetID(), hpPercent, redhp, maxhp)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossGreyHP, e:GetID(), greyVal, redhp, maxhp)
        local showCurseHp = e:HP():GetShowCurseHp()
        local curseHpValue = e:HP():GetCurseHpValue()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossCurseHP, e:GetID(), showCurseHp, curseHpValue, redhp, maxhp)
    end
    --刷新队伍UI血条
    if e:HasTeam() then
        ---@type HPComponent
        local hpCmpt = e:HP()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.TeamHPChange,
            {
                isLocalTeam = self._world:Player():IsLocalTeamEntity(e),
                currentHP = hpCmpt:GetRedHP(),
                maxHP = hpCmpt:GetMaxHP(),
                hitpoint = hpCmpt:GetWhiteHP(),
                shield = hpCmpt:GetShieldValue(),
                entityID = e:GetID(),
                showCurseHp = hpCmpt:GetShowCurseHp(),
                curseHpVal = hpCmpt:GetCurseHpValue()
            }
        )
    end
end

function MainStateSystem:_DoLogicTrapDie()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:CalcAllTrapDeadMark()

    local data = DataDeadMarkResult:New()
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if e:HasDeadMark() then
            data:AddDeadEntityID(e:GetID())
        end
    end
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

function MainStateSystem:_DoLogicMonsterDead()
    local drops = {}
    local deadEntityIDList = {}
    self:_DoLogicRecursMonsterDead(drops, deadEntityIDList)

    --表现立即刷死亡标记
    local data = DataDeadMarkResult:New(deadEntityIDList)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
    local deadEntityList = {}
    for _, id in ipairs(deadEntityIDList) do
        deadEntityList[#deadEntityList + 1] = self._world:GetEntityByID(id)
    end
    return deadEntityList
end

function MainStateSystem:_DoLogicRecursMonsterDead(drops, deadEntityIDList)
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        sMonsterShowLogic:AddMonsterDeadMark(e)
    end
    local tmpDrops, tmpDeadEntityIDList = sMonsterShowLogic:DoAllMonsterDeadLogic()
    table.appendArray(drops, tmpDrops)
    table.appendArray(deadEntityIDList, tmpDeadEntityIDList)

    local hasNewDead = self:_DoLogicCheckNewDead()
    if hasNewDead then
        self:_DoLogicRecursMonsterDead(drops, deadEntityIDList)
    end
end

function MainStateSystem:_DoLogicCheckNewDead()
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        ---血量大于0，说明还没死
        local cAttributes = e:Attributes()
        local curHp = cAttributes:GetCurrentHP()
        if curHp <= 0 and not e:HasDeadMark() then
            return true
        end
    end

    return false
end

---棋子死亡
function MainStateSystem:_DoLogicChessPetDead()
    ---@type ChessServiceLogic
    local chessSvc = self._world:GetService("ChessLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    local chessPetEntityIDList = {}
    for _, e in ipairs(monsterGroup:GetEntities()) do
        chessPetEntityIDList[#chessPetEntityIDList + 1] = e:GetID()
    end

    -- 这里的逻辑和怪物死亡一致，传入所有entityID，在DoChessPetListDeadLogic内部添加DeadMarkComponent
    chessSvc:DoChessPetListDeadLogic(chessPetEntityIDList)
    local hadDeadEntityIDList = chessSvc:GetHasDeadMarkChessPetList()
    self._world:BattleStat():SetChessDeadPlayerPawnCount(hadDeadEntityIDList)

    --表现立即刷死亡标记
    local data = DataDeadMarkResult:New(hadDeadEntityIDList)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

function MainStateSystem:_DoRenderTrapDie(TT)
    if self._world:RunAtClient() then
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        trapServiceRender:PlayAllTrapDead(TT)
    end
end

function MainStateSystem:_DoRenderMonsterDead(TT)
    if self._world:RunAtClient() then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = self._world:GetService("MonsterShowRender")
        sMonsterShowRender:DoAllMonsterDeadRender(TT)
    end
end

---
function MainStateSystem:_DoRenderChessPetDead(TT)
    if self._world:RunAtClient() then
        ---@type ChessServiceRender
        local chessSvcRender = self._world:GetService("ChessRender")
        chessSvcRender:DoAllChessPetListDeadRender(TT)
    end
end

function MainStateSystem:_DoRenderWaitDeathEnd(TT)
    while self:_CheckShowDeathNotEnd() do
        YIELD(TT)
    end
end

function MainStateSystem:_CheckShowDeathNotEnd()
    ---@type Group
    local deathGroup = self._world:GetGroup(self._world.BW_WEMatchers.ShowDeath)
    for _, v in ipairs(deathGroup:GetEntities()) do
        ---@type Entity
        local entity = v
        ---@type ShowDeathComponent
        local showDeathCmpt = entity:ShowDeath()
        if not showDeathCmpt:IsShowDeathEnd() then
            return true
        end
    end

    return false
end

function MainStateSystem:_DoLogicClearDeadEntity()
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    sMonsterShowLogic:ClearMonsterDeadEntity()

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:ClearTrapDeadEntity()
end

---逻辑波次内刷怪
---@param monsterWaveInternalTime MonsterWaveInternalTime
function MainStateSystem:_DoLogicSpawnInWaveMonsters(monsterWaveInternalTime)
    ---@type MonsterCreationServiceLogic
    local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")
    local traps, monsters = monsterCreationSvc:CreateInternalRefreshMonsterLogic(monsterWaveInternalTime)

    return traps, monsters
end

--主相机开启/关闭
function MainStateSystem:BlinkMainCamera(isShow)
    ---@type CameraService
    local sCamera = self._world:GetService("Camera")
    sCamera:BlinkMainCamera(isShow)
end

function MainStateSystem:_DoLogicCalcBonusObjective()
    ---@type BonusCalcService
    local bonusService = self._world:GetService("BonusCalc")
    bonusService:CalcBonusObjective()
end

function MainStateSystem:_HandleEntityCommand()
    ---@type PlayerCommandHandler
    local cmdHandler = self._world:GetPlayerCommandHandler()
    cmdHandler:ClearHandlerState()
    cmdHandler:HandleCommand()
end

---@return bool, bool 战斗是否结束, 波次是否胜利
function MainStateSystem:IsBattleEnded()
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    --玩家死亡战斗结束
    if teamEntity and self:IsPlayerDead(teamEntity) then
        return true, false
    end

    --如果是守护机关死亡 战斗结束
    local protectedTrapDead = self:IsProtectedTrapDead()
    if protectedTrapDead then
        return true, false
    end

    ---诅咒塔全部点亮
    local curseTowerAllActive = self:IsCurseTowerAllActive()
    if curseTowerAllActive then
        return true, false
    end

    local chessPetDead = self:IsChessCalculation()
    if chessPetDead then
        return true, false
    end

    local monsterEscapeTooMuch = self:IsMonsterEscapeTooMuch()
    if monsterEscapeTooMuch then 
        return true, false
    end

    ---@type BattleStatComponent
    local cBattleStat = self._world:BattleStat()
    local waveCount = cBattleStat:GetCurWaveIndex()
    local cfgSvc = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = cfgSvc:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParm = levelConfigData:GetWaveCompleteConditionParam(waveCount)
    ---@type CompleteConditionService
    local completeService = self._world:GetService("CompleteCondition")
    local combinedConditionArguments = levelConfigData:GetWaveCombinedCompleteConditionArguments(waveCount)
    local isComplete =
        completeService:IsDoneCompleteCondition(
        completeConditionType,
        completeConditionParm,
        combinedConditionArguments
    )
    return isComplete, isComplete
end

function MainStateSystem:IsPlayerDead(teamEntity)
    local battleSvc = self._world:GetService("Battle")
    return battleSvc:HandlePlayerCalculation(teamEntity)
end

function MainStateSystem:IsProtectedTrapDead()
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelCfgData = cfgSvc:GetLevelConfigData()
    local ingore = levelCfgData:GetIgnoreProtectedTrapDead()
    if ingore == 1 then 
        ---不需要检查守护机关是否死亡
        return false
    end

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    if utilSvc:GetProtectedTrap() then
        local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
        local protectedTrap = nil
        for _, e in ipairs(trapGroup:GetEntities()) do
            ---@type TrapComponent
            local trapCmpt = e:Trap()
            if trapCmpt:GetTrapType() == TrapType.Protected then
                protectedTrap = e

                local curHP = e:Attributes():GetCurrentHP()
                if curHP <= 0 then
                    return true
                end
            end
        end

        if not protectedTrap then
            return true
        end
    end

    return false
end

function MainStateSystem:IsCurseTowerAllActive()
    -- 白舒摩尔专属需求：场上有塔，且所有塔全激活时，按战败处理
    local curseTowerGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.CurseTower)
    if (curseTowerGroupEntities) and (#curseTowerGroupEntities > 0) then
        local isAllActive = true
        for _, eTower in ipairs(curseTowerGroupEntities) do
            local isActive = eTower:CurseTower():GetTowerState() == CurseTowerState.Active
            isAllActive = isAllActive and isActive
        end

        if isAllActive then
            return true
        end
    end

    return false
end

---检查棋子是否死亡
function MainStateSystem:IsChessCalculation()
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    return battleSvc:HandleChessCalculation()
end
function MainStateSystem:IsMonsterEscapeTooMuch()
    ---@type BattleStatComponent
    local cmptBattleStat = self._world:BattleStat()
    local waveCount = cmptBattleStat:GetCurWaveIndex()
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = cfgSvc:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParm = levelConfigData:GetWaveCompleteConditionParam(waveCount)

    if completeConditionType == CompleteConditionType.RoundCountLimitAndCheckMonsterEscape then
        local limit = completeConditionParm[1][2]
        -- local entityGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterEscape)
        -- local es = entityGroup:GetEntities()
        -- local nEscape = 0
        -- ---@param e Entity
        -- for _, e in ipairs(es) do
        --     ---@type MonsterEscapeComponent
        --     local monsterEscapeComponent = e:MonsterEscape()
        --     if monsterEscapeComponent and monsterEscapeComponent:IsEscapeSuccess() then
        --         nEscape = nEscape + 1
        --     end
        -- end
        local nEscape = cmptBattleStat:GetMonsterEscapeNum()
        local escapeTooMuch = (nEscape >= limit)
        return escapeTooMuch
    end

    return false
end
function MainStateSystem:_DoLogicPetDead(teamEntity)
    ---@type BattleService_Maze
    local battleService = self._world:GetService("Battle")
    return battleService:UnloadPetLogic(teamEntity)
end

---@param ntTeamOrderChange NTTeamOrderChange
function MainStateSystem:_DoRenderPetDead(TT, teamEntity, ntTeamOrderChange)
    if self._world:RunAtClient() then
        ---@type RenderBattleService
        local renderBattleService = self.world:GetService("RenderBattle")
        renderBattleService:ChangeTeamLeaderRender(TT, teamEntity)
        if ntTeamOrderChange then
            local viewRequest =
                BattleTeamOrderViewRequest:New(
                ntTeamOrderChange:GetOldTeamOrder(),
                ntTeamOrderChange:GetNewTeamOrder(),
                BattleTeamOrderViewType.FillVacancies_MazePetDead
            )

            local renderBattleSvc = self._world:GetService("RenderBattle")
            renderBattleSvc:RequestUIChangeTeamOrderView(viewRequest)
            local seqNo = viewRequest:GetRequestSequenceNo()
            while (not self._world:RenderBattleStat():IsChangeTeamOrderRequestFinished(seqNo)) do
                YIELD(TT)
                -- 有些情况下右侧光灵列表是不显示的，这里判断一下，如果是这个状况就不等了
                if (self._world:RenderBattleStat():IsChangeTeamOrderViewDisabled()) then
                    break
                end
            end

            self._world:GetService("PlayBuff"):PlayBuffView(TT, ntTeamOrderChange)
        end
    end
end

---逻辑上关闭极光时刻
function MainStateSystem:_DoLogicCloseAuroraTime(isReEnterClose)
    if not self._world:BattleStat():IsRoundAuroraTime() then
        return
    end
    if isReEnterClose then
        --极光时刻中再进入极光时刻 中途执行一次关闭
    else
        self._world:BattleStat():SetRoundAuroraTime(false)
        self._world:BattleStat():SetReEnterAuroraTime(false)
    end
    
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    triggerSvc:Notify(NTExitAuroraTime:New())
end

function MainStateSystem:_DoRenderCloseAuroraTime(TT)
    if self._world:RunAtServer() then
        return
    end

    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()
    self._world:EventDispatcher():Dispatch(GameEventType.ShowHideAuroraTime, false)
    self._world:MainCamera():ToggleAuroraTime(false)
    battleRenderCmpt:SetWaitInputAuroraTime(false)
    battleRenderCmpt:SetReEnterAuroraTimePlayed(false)

    YIELD(TT, BattleConst.AuroraFxExitTimeMs)
    self._world:MainCamera():SetAuroaTimeObjActive(false)

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayBuffView(TT, NTExitAuroraTime:New())
end
