--[[------------------------------------------------------------------------------------------
    WaveResultSystem：波次结算状态
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class WaveResultSystem:MainStateSystem
_class("WaveResultSystem", MainStateSystem)
WaveResultSystem = WaveResultSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function WaveResultSystem:_GetMainStateID()
    return GameStateID.WaveResult
end
---@class AssignWave
local AssignWave = {
    None = 0, -- 当前波次非指定结束波次
    AssignEndWave = 1, -- 当前波次为指定结束波次
    AssignRand = 2 -- 当前波次为随机刷新波次
}
_enum("AssignWave", AssignWave)
---@param TT token 协程识别码，服务端是nil
function WaveResultSystem:_OnMainStateEnter(TT)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---由于可能从玩家连线直接跳到波次结算，因此这里需要刷一次怪物死亡
    self:_DoLogicChainAttackDead()
    self:_DoRenderChainAttackDead(TT)

    self:_DoLogicCalc3StarProgress()

    self:_DoLogicCalcBonusObjective()

    --清理连线填充格子
    self:_DoLogicClearChainPath(teamEntity)

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local waveNum = battleStatCmpt:GetCurWaveIndex()
    ---通知逻辑波次结算
    self:_DoLogicNotifyWaveEnd(waveNum)
    ---通知表现波次结算
    self:_DoRenderNotifyWaveEnd(TT, waveNum)

    ---怪物死亡刷新函数的逻辑表现未分离，以后还需要改
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)

    ---机关死亡逻辑
    self:_DoLogicTrapDie()
    ---机关死亡表现
    self:_DoRenderTrapDie(TT)

    ---战斗结算
    local turnToBattleResult, victory = self:_DoLogicCheckBattleResult(teamEntity)
    if turnToBattleResult then
        local hasDeadLogic = self:_DoLogicHandleTurnBattleResult(victory)
        self:_DoRenderHandleTurnBattleResult(TT, victory, hasDeadLogic)
    --Log.debug("BattleEnd battleLevelResult:", battleLevelResult, "PlayerDead:", playerDead, "LastWave:", isLastWave)
    end

    self:_WaitTime(TT, 200)

    ---更新战斗组件统计信息
    self:_DoLogicUpdateBattleStat()

    ---离开波次结算状态
    self:_DoLogicLeaveWaveResult(turnToBattleResult)

    self:_DoRenderSendWaveEnd(TT, turnToBattleResult, victory)
end

---清理连锁技打死的目标
function WaveResultSystem:_DoLogicChainAttackDead()
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local drops, deadEntityIDList = sMonsterShowLogic:DoAllMonsterDeadLogic()
end

--清理连线信息
---@private
function WaveResultSystem:_DoLogicClearChainPath(teamEntity)
    if teamEntity == nil then 
        return 
    end

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    logicChainPathCmpt:ClearLogicChainPath()
end

function WaveResultSystem:_DoLogicCalc3StarProgress()
    ---@type Star3CalcService
    local starService = self._world:GetService("Star3Calc")
    starService:Calc3StarProgress()
end

---结算三星奖励是否完成
function WaveResultSystem:_DoLogicCalcBonusObjective()
    ---@type BonusCalcService
    local bonusService = self._world:GetService("BonusCalc")
    bonusService:CalcBonusObjective()
end

function WaveResultSystem:_DoLogicNotifyWaveEnd(waveNum)
    self._world:GetService("Trigger"):Notify(NTWaveTurnEnd:New(waveNum))
end

----参数一
----@return boolean 是否进入BattleResult,boolean 战斗是否胜利
function WaveResultSystem:_DoLogicCheckBattleResult(teamEntity)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local turn2BattleResult, victory = false, false
    if battleStatCmpt:AssignWaveResult() then
        turn2BattleResult = true
        victory = true
    else
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        local playerDead = battleService:HandlePlayerCalculation(teamEntity)
        --如果是守护机关死亡 战斗结束
        local protectedTrapDead = battleService:HandleTrapCalculation()
        local curseTowerAllActive = battleService:HandleCurseTowerCalculation()
        local chessPetDead = battleService:HandleChessCalculation()
        local monsterEscapeTooMuch = battleService:HandleMonsterEscapeCalculation()
        local popStarNumNotEnough = battleService:HandlePopStarNumber()
        if playerDead or protectedTrapDead or curseTowerAllActive or chessPetDead or monsterEscapeTooMuch or popStarNumNotEnough then
            turn2BattleResult = true
            victory = false
        else
            local curseTowerGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.CurseTower)
            if (curseTowerGroupEntities) and (#curseTowerGroupEntities > 0) then
                local isAllActive = true
                for _, eTower in ipairs(curseTowerGroupEntities) do
                    local isActive = eTower:CurseTower():GetTowerState() == CurseTowerState.Active
                    isAllActive = isAllActive and isActive
                end

                if isAllActive then
                    turn2BattleResult = true
                    victory = false
                end
            end

            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type LevelConfigData
            local levelConfigData = configService:GetLevelConfigData()
            local outOfRoundType = levelConfigData:GetOutOfRoundType()
            local leftRoundCount = battleStatCmpt:GetCurWaveRound()
            -- outOfRoundType: 默认是0，回合用尽扣血机制内，不进行回合数判断
            if outOfRoundType == 0 and leftRoundCount == 0 and not battleStatCmpt:LevelCompleteLimitAllRoundCount() then
                turn2BattleResult = true
                victory = false
            else
                local isLastWave = self:IsLastWave()
                if isLastWave then
                    -- 如果是指定波次结束关卡 计算是否结束关卡
                    -- false:没有触发下一波 直接结束 true 触发了下一波怪物 继续刷新
                    local AssignWaveType, isAssignWaveNotEnd = self:_CalAssignWaveAndRefreshNextWave(true)
                    if isAssignWaveNotEnd then
                        turn2BattleResult = false
                        victory = false
                    else
                        turn2BattleResult = true
                        victory = true--还要判断其他条件，不能直接认为是true；先处理击杀怪数量要求
                        local killAnyMonsterCountEnough = battleService:HandleKillAnyMonsterCountCalculation()
                        if not killAnyMonsterCountEnough then
                            victory = false
                        end
                    end
                else
                    turn2BattleResult = false
                    victory = false
                end
            end
        end
    end

    return turn2BattleResult, victory
end

--计算是否是特殊胜利关卡(指定波次结束关卡并且[概率或按计次]出现下一波次，结算结果按照指定波次计算)AssignWaveAndRandomNextWave 13
--如果是特殊生理关卡需要计算是否要刷新下一波
--如果刷新下一波返回true 不是特殊胜利关卡或者没有触发下一波返回false
function WaveResultSystem:_CalAssignWaveAndRefreshNextWave(battleLevelResult)
    local bRefresh = false

    -- 如果没赢就不刷
    if not battleLevelResult then
        return AssignWave.AssignEndWave, bRefresh
    end

    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local levelCompleteConditionType = levelConfigData:GetLevelCompleteConditionType()
    if levelCompleteConditionType ~= CompleteConditionType.AssignWaveAndRandomNextWave then
        return AssignWave.None, bRefresh
    end

    -- 哪一波次需要结束当前副本并触发随机波次
    local l_arrAssignWaveParams = levelConfigData:GetLevelCompleteConditionParams()[1]
    if table.count(l_arrAssignWaveParams) < LevelCompleteAssignWaveParamExp.RefreshUpProb then
        Log.fatal("if table.count(l_nAssignWaveParams) < ", LevelCompleteAssignWaveParamExp.RefreshUpProb, " then")
    end
    local l_nAssignWave = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.AssignWaveEnd]

    -- 获取当前波次
    local battleStatCmpt = self._world:BattleStat()
    local l_nCurWaveIndex = battleStatCmpt:GetCurWaveIndex()
    if l_nCurWaveIndex < l_nAssignWave then -- 当前波次小于指定波次就返回AssignWave.None
        return AssignWave.None, bRefresh
    end

    if l_nCurWaveIndex > l_nAssignWave then
        return AssignWave.AssignRand, bRefresh -- battleStatCmpt:IsRefreshSpecialWave()
    end

    -- 当前是指定结束波次 l_nCurWaveIndex == l_nAssignWave
    -- 判定走计次刷新还是走随机刷新
    local curType = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.BaseRefreshProb]
    if curType == WaveRefreshModeType.Cumulate then
        return self:_DoCumulateNextWave(l_arrAssignWaveParams)
    else
        return self:_DoRandomNextWave(l_arrAssignWaveParams)
    end
end

function WaveResultSystem:_DoCumulateNextWave(l_arrAssignWaveParams)
    local bRefresh = false

    -- 计次上限
    local cumulateNumLimit = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.RefreshUpProb]

    -- 特殊处理，首次更新累计次数刷新波次时，现网号的概率已存档，且数值为50的倍数
    if self._world.BW_WorldInfo.assign_wave_refresh_probability > 2 * cumulateNumLimit then
        self._world.BW_WorldInfo.assign_wave_refresh_probability = 0
    end

    -- 更新累计次数
    self._world.BW_WorldInfo.assign_wave_refresh_probability =
        self._world.BW_WorldInfo.assign_wave_refresh_probability + 1 + self._world.BW_WorldInfo.asset_double_item_count

    -- 如果打过该关卡 判定是否达到计次上限
    if self._world.BW_WorldInfo.level_is_pass then
        if self._world.BW_WorldInfo.assign_wave_refresh_probability >= cumulateNumLimit then
            bRefresh = true
            self._world.BW_WorldInfo.assign_wave_refresh_probability =
                self._world.BW_WorldInfo.assign_wave_refresh_probability - cumulateNumLimit
        end
    else -- 没打过该关卡100%刷怪
        bRefresh = true
    end

    Log.fatal("Prob:", self._world.BW_WorldInfo.assign_wave_refresh_probability)

    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetAssignWaveResult(bRefresh)

    return AssignWave.AssignEndWave, bRefresh -- 还有下一波
end

function WaveResultSystem:_DoRandomNextWave(l_arrAssignWaveParams)
    local bRefresh = false
    local l_nPerThousandProbability = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.BaseRefreshProb] -- 刷怪千分之概率
    local l_nUpProb = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.RefreshUpProb] -- 基础增长率

    -- 当前刷新概率 大于基础概率使用当前刷新概率计算
    if self._world.BW_WorldInfo.assign_wave_refresh_probability > l_nPerThousandProbability then
        l_nPerThousandProbability = self._world.BW_WorldInfo.assign_wave_refresh_probability
    elseif l_nPerThousandProbability > self._world.BW_WorldInfo.assign_wave_refresh_probability then
        self._world.BW_WorldInfo.assign_wave_refresh_probability = l_nPerThousandProbability
    end

    -- 如果打过该关卡 随机概率
    --l_nPerThousandProbability = 1000
    if self._world.BW_WorldInfo.level_is_pass then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local nRandNum = randomSvc:LogicRand(1, 1000) -- 刷怪千分之概率
        if nRandNum <= l_nPerThousandProbability then
            bRefresh = true
            self._world.BW_WorldInfo.assign_wave_refresh_probability = 0 -- 如果触发了刷怪 下次采用默认刷新概率
        elseif l_nUpProb then
            if self._world.BW_WorldInfo.double_resource_state then
                Log.debug("Level is Double Resource State")
                l_nUpProb = l_nUpProb * 2
            end
            self._world.BW_WorldInfo.assign_wave_refresh_probability =
                self._world.BW_WorldInfo.assign_wave_refresh_probability + l_nUpProb
            Log.fatal("Prob:", self._world.BW_WorldInfo.assign_wave_refresh_probability)
        end
    else -- 没打过该关卡100%刷怪
        bRefresh = true
    end

    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetAssignWaveResult(bRefresh)

    -- battleStatCmpt:SetRefreshSpecialWave(bRefresh)

    return AssignWave.AssignEndWave, bRefresh -- 还有下一波
end

function WaveResultSystem:_DoLogicHandleTurnBattleResult(victory)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetBattleLevelResult(victory)

    if victory then
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        return battleService:LevelWinKillAllMonster()
    end
end

function WaveResultSystem:_DoLogicUpdateBattleStat()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:ResetChainIndex()
end

function WaveResultSystem:_DoLogicLeaveWaveResult(turnToBattleResult)
    if turnToBattleResult == false then
        ---@type MatchType
        local matchType = self._world.BW_WorldInfo.matchType
        if matchType == MatchType.MT_MiniMaze then
            self._world:EventDispatcher():Dispatch(GameEventType.WaveResultFinish, 3)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.WaveResultFinish, 1)
        end
    else
        self._world:EventDispatcher():Dispatch(GameEventType.WaveResultFinish, 2)
    end
end

---@return boolean
function WaveResultSystem:IsLastWave()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local isLastWave = battleStatCmpt:IsLastWave()
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local levelCompleteConditionType = levelConfigData:GetLevelCompleteConditionType()
    if levelCompleteConditionType ~= CompleteConditionType.AssignWaveAndRandomNextWave then
        return isLastWave
    else
        -- 获取当前波次
        local l_nCurWaveIndex = battleStatCmpt:GetCurWaveIndex()
        -- 哪一波次需要结束当前副本并触发随机波次
        local l_arrAssignWaveParams = levelConfigData:GetLevelCompleteConditionParams()[1]
        local l_nAssignWave = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.AssignWaveEnd]
        if l_nCurWaveIndex == l_nAssignWave then
            return true
        else
            return isLastWave
        end
    end
end

------------------------------------表现------------------------------------

function WaveResultSystem:_DoRenderNotifyWaveEnd(TT, waveNum)
end

function WaveResultSystem:_DoRenderChainAttackDead(TT)
end

function WaveResultSystem:_DoRenderHandleTurnBattleResult(TT, victory, hasDeadLogic)
end

function WaveResultSystem:_DoRenderSendWaveEnd(TT, turnToBattleResult, victory)
end
