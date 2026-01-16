--[[------------------------------------------------------------------------------------------
    响应进入战场system
]] --------------------------------------------------------------------------------------------

---@class PlayerDefeatType
local PlayerDefeatType = {
    None = 0, ---没有失败
    ZeroHp = 1, ---血量减到0
    ProtectedTrapDead = 2 ,---守护机关死亡
    CurseTowerAllActive = 3, --- 所有诅咒塔点亮
    ChessAllDead = 4,---战棋的棋子都死亡了
    MonsterEscapeTooMuch = 5, ---怪物逃脱数超过限制(N28塔防)
    PopStarNumberNotEnough = 6, ---消除格子数不足(N31消灭星星)
 }
 PlayerDefeatType = PlayerDefeatType
_enum("PlayerDefeatType", PlayerDefeatType)

---@class BattleResultSystem:MainStateSystem
_class("BattleResultSystem", MainStateSystem)
BattleResultSystem = BattleResultSystem

function BattleResultSystem:_GetMainStateID()
    return GameStateID.BattleResult
end

function BattleResultSystem:_OnMainStateEnter(TT)
    local victory,defeatType = self:_DoLogicBeforeExit()
    self:_DoRenderShowExit(TT, victory,defeatType)

    self:_DoLogicAfterExit()
    self:_DoLogicBattleResult()
end

function BattleResultSystem:_DoLogicBattleResult()
end

function BattleResultSystem:_DoLogicBeforeExit()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local victory = battleStatCmpt:GetBattleLevelResult() and 1 or 0

    --战斗胜利、失败后触发的buff
    local defeatType = self:_DoLogicCalcDefeatType()
    self._world:GetService("Trigger"):Notify(NTGameOver:New(victory,defeatType))
    --白盒测试结束状态
    ---@type AutoTestService
    local svc = self._world:GetService("AutoTest")
    if svc then
        svc:SetGameOver_Test()
    end
    return victory,defeatType
end

function BattleResultSystem:_DoLogicCalcDefeatType()
    --玩家死亡战斗结束
    if self:IsPlayerDead() then
        return PlayerDefeatType.ZeroHp
    end

    --如果是守护机关死亡 战斗结束
    local protectedTrapDead = self:IsProtectedTrapDead()
    if protectedTrapDead then
        return PlayerDefeatType.ProtectedTrapDead
    end

    ---诅咒塔全部点亮
    local curseTowerAllActive = self:IsCurseTowerAllActive()
    if curseTowerAllActive then 
        return PlayerDefeatType.CurseTowerAllActive
    end

    local allChessDead = self:IsChessCalculation()
    if allChessDead then 
        return PlayerDefeatType.ChessAllDead
    end

    local monsterEscapeTooMuch = self:IsMonsterEscapeTooMuch()
    if monsterEscapeTooMuch then 
        return PlayerDefeatType.MonsterEscapeTooMuch
    end
    
    ---并没有失败
    return PlayerDefeatType.None
end

function BattleResultSystem:_DoRenderShowExit(TT, victory,defeatType)
end

function BattleResultSystem:_DoLogicAfterExit()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    --计算一次三星奖励，后续如果为了看三星进度，可以放到角色行动结束后，算一次
    if self._world.BW_WorldInfo.hasBonusCondition then
        ---@type BonusCalcService
        local bonusCalcSvc = self._world:GetService("BonusCalc")
        bonusCalcSvc:CalcBonusObjective()
    end

    ---@type MatchType
    local matchType = self._world.BW_WorldInfo.matchType
    self.battleMatchResult = self:_CalcBattleResult(matchType, battleStatCmpt)

    --记录数据日志
    self._world:GetDataLogger():AddDataLog("OnShowEnd")
    self._world:GetDataLogger():AddDataLog("OnBattleEnd")


end

---@param matchType MatchType
---@param battleStatCmpt BattleStatComponent
---@return MatchResult
function BattleResultSystem:_CalcBattleResult(matchType, battleStatCmpt)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local result = battleService:CalcBattleResultLogic(matchType, battleStatCmpt:GetBattleLevelResult())

    --统计数据
    result.battle_statistics.ActiveSkill = battleStatCmpt:GetActiveSkillCount()
    result.battle_statistics.Blood = self:_CalcLeftBlood(battleStatCmpt)
    result.battle_statistics.ChainSkill = battleStatCmpt:GetChainSkillCount()
    result.battle_statistics.ColorSkill = battleStatCmpt:GetColorSkillCount()
    result.battle_statistics.KillBoss = battleStatCmpt:GetKillBossCount()
    result.battle_statistics.KillMonster = battleStatCmpt:GetKillMonsterCount()
    result.battle_statistics.LeftTurn = battleStatCmpt:GetLevelLeftRoundCount()
    result.battle_statistics.MaxChain = battleStatCmpt:GetOneMatchMaxNum()
    result.battle_statistics.OneActiveSkillKill = battleStatCmpt:GetOneActiveSkillKillCount()
    result.battle_statistics.OneChainKillMonster = battleStatCmpt:GetOneChainKillCount()
    result.battle_statistics.OneChainNormalAttack = battleStatCmpt:GetOneChainNormalAttackCount()
    result.battle_statistics.SuperChain = battleStatCmpt:GetAuroraTimeCount()
    result.battle_statistics.UseTurn = battleStatCmpt:GetLevelTotalRoundCount() - 1
    result.battle_statistics.AutoFight = battleStatCmpt:GetEverAutoFight()
    result.battle_statistics.changeTeamLeaderNum = battleStatCmpt:GetTeamLeaderChangeNum()
    result.battle_statistics.passivechangeLeaderNum = battleStatCmpt:GetPassiveTeamLeaderChangeNum()
    result.battle_statistics.line_time = battleStatCmpt:GetTotalChainNum()
    result.battle_statistics.step_num = battleStatCmpt:GetTotalMatchNum()
    result.battle_statistics.MazeAddLight = battleStatCmpt:GetMazeAddLight()
    result.battle_statistics.EraseSquare = battleStatCmpt:GetElementMatchNum()
    --客户端表现层的统计数据
    ---@type RenderBattleStatComponent
    local renderBattleStat = self._world:RenderBattleStat()
    if renderBattleStat then
        result.battle_statistics.DoubleSpeed = renderBattleStat:GetEverSpeed()
    end
    return result
end

function BattleResultSystem:_CalcLeftBlood(battleStatCmpt)
    local hpPercent = battleStatCmpt:GetLeftBlood()
    --MSG58834
    --取整规则同UI显示，并将UI显示的数值发送给服务器
    if hpPercent <= 0 then
        hpPercent = 0
    elseif hpPercent <= 0.01 then
        hpPercent = 1
    else
        hpPercent = math.floor(hpPercent * 100 + 0.5)
    end

    hpPercent = hpPercent / 100
    return hpPercent
end
