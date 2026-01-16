--[[------------------------------------------------------------------------------------------
    主状态机：连锁状态阶段处理system
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class ChainAttackStateSystem:MainStateSystem
_class("ChainAttackStateSystem", MainStateSystem)
ChainAttackStateSystem = ChainAttackStateSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function ChainAttackStateSystem:_GetMainStateID()
    return GameStateID.ChainAttack
end

---@param TT token 协程识别码，服务端是nil
function ChainAttackStateSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---这里会结算一次
    if self._world:MatchType() == MatchType.MT_BlackFist and self:_IsBattleEnd() then
        --清理连线
        self:_DoLogicClearChainPath(teamEntity)
        self:_DoRenderClearChainPath()
        --清理连线设置的副属性
        self:_DoLogicClearElementSecondaryType(teamEntity)

        ---战斗结束，主状态机跳转状态
        self:_DoLogicGotoNextState(false, teamEntity)
        return
    end

    --连锁前buff通知
    self:_DoLogicBeforeCalcChain()
    self:_DoRenderBeforeCalcChain(TT)

    --逻辑计算
    self:_DoLogicCalcChainSkill(teamEntity)
    self:_DoLogicMonsterDeadEx()
    ---展示连锁技施法过程
    self:_DoRenderShowChainAttack(TT, teamEntity)
    --表现协程需要卡住状态机
    self:_DoRenderWaitPlaySkillTaskFinish(TT)

    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT, teamEntity)

    --逻辑上计算三星条件
    self:_DoLogicCalc3StarProgress()
    self:_DoLogicCalcBonusObjective()

    ---表现上要清理Combo等
    self:_DoRenderClearLastAttack()

    ---波次内刷怪
    local traps, monsters = self:_DoLogicSpawnInWaveMonsters(MonsterWaveInternalTime.ChainAttack)
    ---波次内刷怪表现
    self:_DoRenderInWave(TT, traps, monsters)
    --极光时刻检查
    local isAuroraTime = self:_DoLogicCheckAuroraTime(teamEntity)
    self:_DoRenderResetAuroraTimeState(TT)
    --清理连线
    self:_DoLogicClearChainPath(teamEntity)
    self:_DoRenderClearChainPath()

    --清理连线设置的副属性
    self:_DoLogicClearElementSecondaryType(teamEntity)

    if not isAuroraTime then
        self:_DoLogicPlayerBuffDelayed(teamEntity)
        self:_DoRenderPlayerBuffDelayed(TT, teamEntity)
    end

    ---连锁技的逻辑
    ---主状态机的切换在player的状态里
    ---服务端不执行player的状态
    ---另外击退效果，位置没有做逻辑表现分离，导致这个函数实际上是Server端的行为
    self:_DoLogicGotoNextState(isAuroraTime, teamEntity)
end

---------------------------------逻辑接口---------------------------
function ChainAttackStateSystem:_DoLogicBeforeCalcChain()
    local ntBeforeCalcChainSkill = NTBeforeCalcChainSkill:New()
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local logicPath = logicChainPathCmpt:GetLogicChainPath()
    ntBeforeCalcChainSkill:SetChainCount(table.count(logicPath))
    self._world:GetService("Trigger"):Notify(ntBeforeCalcChainSkill)
end

function ChainAttackStateSystem:_DoLogicCalcChainSkill(teamEntity)
    ----@type ChainAttackServiceLogic
    local chainAttackServiceLogic = self._world:GetService("ChainAttackLogic")
    chainAttackServiceLogic:_DoLogicCalcChainSkill(teamEntity)

    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RChainAttackData(teamEntity)
end

function ChainAttackStateSystem:_DoLogicMonsterDeadEx()
    ---服务端需要刷一次所有连锁技目标的死亡
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local drops, deadEntityIDList = sMonsterShowLogic:DoAllMonsterDeadLogic(true)
end

function ChainAttackStateSystem:_DoLogicGotoNextState(isAuroraTime, teamEntity)
    ---@type BattleService
    local battle_service = self._world:GetService("Battle")

    if self:_IsBattleEnd() or battle_service:IsWavePreEnd(teamEntity) == true then
        --战斗结束
        self._world:EventDispatcher():Dispatch(GameEventType.ChainAttackFinish, 3)
    else
        if isAuroraTime then
            --极光时刻
            self._world:EventDispatcher():Dispatch(GameEventType.ChainAttackFinish, 2)
        else
            if self._world:MatchType() == MatchType.MT_BlackFist then
                --对方回合
                self._world:EventDispatcher():Dispatch(GameEventType.ChainAttackFinish, 3)
            else
                --怪物回合
                self._world:EventDispatcher():Dispatch(GameEventType.ChainAttackFinish, 1)
            end
        end
    end
end

function ChainAttackStateSystem:_DoLogicCheckAuroraTime(teamEntity)
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    ---@type BattleService
    local battle_service = self._world:GetService("Battle")

    ---@type AffixService
    local affixService = self._world:GetService("Affix")

    local battleStatCmpt = self._world:BattleStat()
    local oldIsAuroraTime = battleStatCmpt:IsRoundAuroraTime()
    local roundAuroraTimeOk = ((not oldIsAuroraTime) or (affixService:IsNoAuroraTimeLimit()))
    local isAuroraTime =
        battleStatCmpt:IsRoundSuperChain() and self._world.BW_WorldInfo.enable_aurora_time and
        roundAuroraTimeOk and
        battleStatCmpt:GuideShowStarTime(self._world.BW_WorldInfo.missionID) and
        not sMonsterShowLogic:IsAllMonsterHasDeadMark() and
        not battle_service:PlayerIsDead(teamEntity) and
        not affixService:IsCloseAuroraTime()

    if isAuroraTime then
        battleStatCmpt:SetRoundAuroraTime(true)
        battleStatCmpt:AddAuroraTimeCount()
        --可能一回合有多次 重播表现
        if oldIsAuroraTime then
            battleStatCmpt:SetReEnterAuroraTime(true)
            --执行一次退出
            local isReEnterClose = true
            self:_DoLogicCloseAuroraTime(isReEnterClose)
        end
        ---@type Vector2[]
        local chainPath = teamEntity:LogicChainPath():GetLogicChainPath()
        --通知进入极光时刻
        self._world:GetService("Trigger"):Notify(NTEnterAuroraTime:New(chainPath[1], teamEntity))
    end

    return isAuroraTime
end

function ChainAttackStateSystem:_DoLogicCalc3StarProgress()
    ---@type Star3CalcService
    local starService = self._world:GetService("Star3Calc")
    starService:Calc3StarProgress()
end
---结算三星奖励是否完成
function ChainAttackStateSystem:_DoLogicCalcBonusObjective()
    ---@type BonusCalcService
    local bonusService = self._world:GetService("BonusCalc")
    bonusService:CalcBonusObjective()
end

function ChainAttackStateSystem:_DoLogicClearChainPath(teamEntity)
    local teamMembers = teamEntity:Team():GetTeamPetEntities()
    ---先清理上次选的数据
    for i, e in ipairs(teamMembers) do
        ----@type SkillPetAttackDataComponent
        local skillPetData = e:SkillPetAttackData()
        skillPetData:ClearPetAttackData()
    end

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    logicChainPathCmpt:ClearLogicChainPath()
end

function ChainAttackStateSystem:_DoLogicClearElementSecondaryType(teamEntity)
    local teamMembers = teamEntity:Team():GetTeamPetEntities()
    ---先清理上次选的数据
    for i, e in ipairs(teamMembers) do
        ---@type ElementComponent
        local playerElementCmpt = e:Element()
        if playerElementCmpt then
            playerElementCmpt:SetUseSecondaryType(false)
        end
    end
end
function ChainAttackStateSystem:_DoLogicPlayerBuffDelayed(teamEntity)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:CalcPlayerBuffDelayedTurn(teamEntity)
end
---------------------------------表现接口---------------------------

function ChainAttackStateSystem:_DoRenderBeforeCalcChain(TT)
end

function ChainAttackStateSystem:_DoRenderShowSuperChainSkill(TT)
end

function ChainAttackStateSystem:_DoRenderShowChainAttack(TT, teamEntity)
end

function ChainAttackStateSystem:_DoRenderClearLastAttack()
end

function ChainAttackStateSystem:_DoRenderInWave(TT, traps, monsters)
end

function ChainAttackStateSystem:_DoRenderClearChainPath()
end

function ChainAttackStateSystem:_DoRenderWaitPlaySkillTaskFinish(TT)
end

function ChainAttackStateSystem:_DoRenderPlayerBuffDelayed(TT)
end
function ChainAttackStateSystem:_DoRenderResetAuroraTimeState(TT)
end
