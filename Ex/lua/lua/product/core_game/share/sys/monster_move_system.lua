--[[------------------------------------------------------------------------------------------
    MonsterMoveSystem 处理怪物行动state的system
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

_class("MonsterMoveSystem", MainStateSystem)
---@class MonsterMoveSystem:MainStateSystem
MonsterMoveSystem = MonsterMoveSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function MonsterMoveSystem:_GetMainStateID()
    return GameStateID.MonsterTurn
end

---@param TT token 协程识别码，服务端是nil
function MonsterMoveSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    --极光时刻关闭
    self:_DoLogicCloseAuroraTime()
    self:_DoRenderCloseAuroraTime(TT)

    ---关闭  玩家被围困双击原地的提示
    self:_DoRenderHideBesiegedTips(TT)

    self:_WaitBeHitSkillFinish(TT)

    self:_DoLogicWorldBossStageBuff()
    self:_DoRenderWorldBossStageBuff(TT)

    ---结算锁血
    self:_DoCalcMonsterLockHPState()
    self:_DoRenderMonsterLockHPState(TT)

    ---刷新怪物死亡逻辑，临时传的TT，以后会重构掉
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)

    ---显示怪物回合信息
    self:_DoRenderHidePetInfo(TT)

    self:_DoLogicBuffBeforeTrapRoundCount()
    self:_DoRenderBuffBeforeTrapRoundCount(TT)

    ---判断机关生命周期
    local calcStateTraps = self:_DoLogicCalcTrapState()
    ---显示机关生命周期
    self:_DoRenderTrapState(TT, calcStateTraps)

    ---计算怪物行动前机关AI
    self:_DoLogicTrapBeforeMonster()
    ---表现怪物行动前机关AI
    self:_DoRenderTrapBeforeMonster(TT)
    --刷死亡
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)
    local ntTeamOrderChange = self:_DoLogicPetDead(teamEntity)
    self:_DoRenderPetDead(TT, teamEntity, ntTeamOrderChange)

    ---这里会结算一次
    if self:_IsBattleEnd() then
        ---战斗结束，主状态机跳转状态
        self:_DoLogicChangeGameState(teamEntity)

        ---显示星灵信息
        self:_DoRenderShowPetInfo(TT)
        return
    end

    ---波次内刷怪
    local traps, monsters = self:_DoLogicSpawnInWaveMonsters(MonsterWaveInternalTime.MonsterTurn)
    ---波次内刷怪表现
    self:_DoRenderInWave(TT, traps, monsters)

    ---播放此阶段的剧情
    self:_DoRenderInnerStoryMonsterTurn(TT)

    --怪物行动前，buff结算
    self:_DoLogicMonsterBuff(teamEntity)

    ---播放怪物的Buff
    self:_DoRenderMonsterBuff(TT)

    ---Dot结算后再次等待
    self:_WaitBeHitSkillFinish(TT)

    ---计算怪物本回合的行为结果
    self:_DoLogicCalcMonsterAction()
    ---播放怪物本回合的表现
    self:_DoRenderPlayMonsterAction(TT)
    self:_DoClearMonsterActionResult()
    local ntTeamOrderChange = self:_DoLogicPetDead(teamEntity)
    self:_DoRenderPetDead(TT, teamEntity, ntTeamOrderChange)

    ---符文等逻辑计算
    self:_DoLogicTrapAfterMonster()
    ---符文等的表现
    self:_DoRenderTrapAfterMonster(TT)
    ---符文表现特效刷新
    self:_UpdateTrapGridRound(TT)

    --MSG55703
    self:_DoLogicMonsterBuffDelayed()
    self:_DoRenderMonsterBuffDelayed(TT)

    ---通知buff
    self:_DoLogicNotifyMonsterTurnEnd(teamEntity)

    ---通知buff表现
    self:_DoRenderNotifyMonsterTurnEnd(TT)

    --怪物行动后 结算受怪物攻击的机关的死亡，死亡目标会挂上deadmark
    self:_DoLogicTrapDie()
    --怪物行动后 结算受怪物攻击的机关的死亡，查找挂了deadmark的目标，播放表现
    self:_DoRenderTrapDie(TT)
    self:_DoPrintAIDebugInfo(TT)
    ---怪物行动后，刷新此阶段的怪物死亡，临时传的TT，以后会重构掉
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)
    local ntTeamOrderChange = self:_DoLogicPetDead(teamEntity)
    self:_DoRenderPetDead(TT, teamEntity, ntTeamOrderChange)

    --棋子死亡
    if self._world:MatchType() == MatchType.MT_Chess then
        self:_DoLogicChessPetDead()
        self:_DoRenderChessPetDead(TT)
    end

    ---结算
    local battleResult = self:_IsBattleEnd()
    if not battleResult then
        self:_DoRenderShowInnerStory(TT)
    end

    self:_DoLogicChangeGameState(teamEntity)
end

-----------------------------逻辑接口------------------------------

function MonsterMoveSystem:_DoLogicCalcTrapState()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    return trapServiceLogic:CalcTrapState(TrapDestroyType.DestroyByRound)
end

function MonsterMoveSystem:_DoLogicChangeGameState(teamEntity)
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    local isMirageOpen = mirageSvc:IsMirageOpen()
    if isMirageOpen then
        self._world:EventDispatcher():Dispatch(GameEventType.MonsterTurnFinish, 3)
        return
    end

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local isTriggerDimension = boardServiceLogic:IsPlayerOnDimension(teamEntity)
    if isTriggerDimension then
        self._world:BattleStat():SetTriggerDimensionFlag(TriggerDimensionFlag.RoundResult)
        self._world:EventDispatcher():Dispatch(GameEventType.MonsterTurnFinish, 2)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.MonsterTurnFinish, 1)
    end
end

function MonsterMoveSystem:_DoLogicMonsterBuff(teamEntity)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:CalcMonsterBuffTurn(teamEntity)
end

function MonsterMoveSystem:_DoLogicMonsterBuffDelayed()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:CalcMonsterBuffDelayedTurn()
end

function MonsterMoveSystem:_DoLogicNotifyMonsterTurnEnd(teamEntity)
    self._world:GetService("Trigger"):Notify(NTMonsterTurnEnd:New(teamEntity))
end

function MonsterMoveSystem:_DoCalcMonsterLockHPState()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:RefreshLockHPLogic()
end

function MonsterMoveSystem:_DoLogicCalcMonsterAction()
    ---@type MonsterMoveServiceLogic
    local monsterMoveServiceLogic = self.world:GetService("MonsterMoveLogic")
    monsterMoveServiceLogic:_DoLogicCalcMonsterAction()
end

function MonsterMoveSystem:_DoLogicTrapBeforeMonster()
    ---@type MonsterMoveServiceLogic
    local monsterMoveServiceLogic = self.world:GetService("MonsterMoveLogic")
    monsterMoveServiceLogic:_DoLogicTrapBeforeMonster()
end

function MonsterMoveSystem:_DoLogicTrapAfterMonster()
    ---@type MonsterMoveServiceLogic
    local monsterMoveServiceLogic = self.world:GetService("MonsterMoveLogic")
    monsterMoveServiceLogic:_DoLogicTrapAfterMonster()
end

function MonsterMoveSystem:_DoLogicWorldBossStageBuff()
    if self.world:MatchType() == MatchType.MT_WorldBoss then
        ---@type BattleService
        local battleSvc = self.world:GetService("Battle")
        ---@type BuffLogicService
        local buffLogicSvc = self.world:GetService("BuffLogic")
        ---@type AffixService
        local affixService = self.world:GetService("Affix")
        local entityArray = battleSvc:GetWorldBossEntityArray()
        for index, entity in ipairs(entityArray) do
            ---@type MonsterIDComponent
            local monsterIDCmpt = entity:MonsterID()
            local monsterID = monsterIDCmpt:GetMonsterID()
            local addBuffList,newAttrData = monsterIDCmpt:WorldBossSwitchStage()
            if newAttrData then
                ---@type AttributesComponent
                local attributeCmpt = entity:Attributes()
                local newAtk = newAttrData.atk
                local newDef = newAttrData.def
                if newAtk then
                    ---攻防血还得被词条处理一次
                    newAtk = affixService:ChangeMonsterAttr(monsterID, newAtk, AffixAttrType.Attack)
                    attributeCmpt:Modify("Attack", newAtk)
                end
                if newDef then
                    newDef = affixService:ChangeMonsterAttr(monsterID, newDef, AffixAttrType.Defence)
                    attributeCmpt:Modify("Defense", newDef)
                end
            end
            for i, buffID in ipairs(addBuffList) do
                buffLogicSvc:AddBuff(buffID, entity)
            end
            local changeStageCount = monsterIDCmpt:GetCurRoundChangeStageCount()
            for i = 1, changeStageCount do
                self.world:GetService("Trigger"):Notify(NTWorldBossStageSwitch:New(monsterIDCmpt:GetCurStage()))
            end
            monsterIDCmpt:ResetCurRoundChangeStageCount()
        end
    end
end

function MonsterMoveSystem:_DoClearMonsterActionResult()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type AIRecorderComponent
    local recorderCmpt = self._world:GetBoardEntity():AIRecorder()
    recorderCmpt:ClearAIRecorder()
    boardEntity:ReplaceShareSkillResult()
end

function MonsterMoveSystem:_DoLogicBuffBeforeTrapRoundCount()
    self._world:GetService("Trigger"):Notify(NTMonsterRoundBeforeTrapRoundCount:New())
end

------------------------------表现接口-------------------------------------
function MonsterMoveSystem:_DoRenderHidePetInfo(TT)
end

function MonsterMoveSystem:_DoRenderShowPetInfo(TT)
end

function MonsterMoveSystem:_DoRenderInnerStoryMonsterTurn(TT)
end

function MonsterMoveSystem:_DoRenderMonsterBuff(TT)
end

function MonsterMoveSystem:_DoRenderMonsterBuffDelayed(TT)
end

function MonsterMoveSystem:_DoRenderNotifyMonsterTurnEnd(TT)
end

function MonsterMoveSystem:_DoRenderShowInnerStory(TT)
end

function MonsterMoveSystem:_WaitBeHitSkillFinish(TT)
end

function MonsterMoveSystem:_DoRenderTrapState(TT, calcStateTraps)
end

function MonsterMoveSystem:_UpdateTrapGridRound(TT)
end

function MonsterMoveSystem:_DoRenderPlayMonsterAction(TT)
end

function MonsterMoveSystem:_DoRenderTrapBeforeMonster(TT)
end

function MonsterMoveSystem:_DoRenderTrapAfterMonster(TT)
end

function MonsterMoveSystem:_DoRenderHideBesiegedTips(TT)
end

function MonsterMoveSystem:_DoRenderInWave(TT, traps, monsters)
end

function MonsterMoveSystem:_DoRenderMonsterLockHPState(TT)
end

function MonsterMoveSystem:_DoRenderWorldBossStageBuff(TT)
end

function MonsterMoveSystem:_DoPrintAIDebugInfo(TT)
end

function MonsterMoveSystem:_DoRenderBuffBeforeTrapRoundCount(TT)
end