--[[------------------------------------------------------------------------------------------
    BattleService 战斗整体行为公共服务
]] --------------------------------------------------------------------------------------------
require("base_service")

_class("BattleService", BaseService)
---@class BattleService:BaseService
BattleService = BattleService

function BattleService:Constructor(world)
    self._comboNum = 0 ---表现使用
    self._logicComboNum = 0 ---逻辑使用
    self._logicChainNum = 0 ---数值计算使用
end

--- 这是一个override，因此接口本身予以保留，实际逻辑搬走
function BattleService:IsValidPiecePos(pos)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local isValidGrid = utilData:IsValidPiecePos(pos)
    return isValidGrid
end

function BattleService:IsPosBlock(pos, blockFlag)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local isBlocked = boardServiceLogic:IsPosBlock(pos, blockFlag)
    return isBlocked
end

---逻辑计算的combo
function BattleService:GetLogicComboNum()
    return self._logicComboNum
end

function BattleService:SetLogicComboNum(comboNum)
    self._logicComboNum = comboNum
end

----用来做连线数值计算使用
function BattleService:SetLogicChainNum(chainNum)
    self._logicChainNum = chainNum
end

function BattleService:GetLogicChainNum()
    return self._logicChainNum
end

--返回值判断战斗是否结束
---@return boolean  战斗结束返回true
function BattleService:BattleCalculation()
    --先判断玩家
    local player_entity = self._world:Player():GetLocalTeamEntity()
    --玩家死亡战斗结束
    if player_entity and self:HandlePlayerCalculation() then
        return true
    end

    --如果是守护机关死亡 战斗结束
    local protectedTrapDead = self:HandleTrapCalculation()
    if protectedTrapDead then
        return true
    end

    local curseTowerAllActive = self:HandleCurseTowerCalculation()
    -- 白舒摩尔专属需求：场上有塔，且所有塔全激活时，按战败处理
    if curseTowerAllActive then
        return true
    end

    local chessPetDead = self:HandleChessCalculation()
    if chessPetDead then
        return true
    end

    --怪物逃脱数超过限制 战败
    local monsterEscapeTooMuch = self:HandleMonsterEscapeCalculation()
    if monsterEscapeTooMuch then
        return true
    end

    ---@type BattleStatComponent
    local cmptBattleStat = self:_GetBattleStatComponent()
    --再判断所有怪物，目前使用AI组件来过滤，后边应该需要设计怪物专有组件
    local waveCount = cmptBattleStat:GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParm = levelConfigData:GetWaveCompleteConditionParam(waveCount)
    ---@type CompleteConditionService
    local completeService = self._world:GetService("CompleteCondition")
    cmptBattleStat:SetBattleWaveResult(false) ---2020-07-15 韩玉信 Bug:7112

    local combinedConditionArguments = self:WaveCombinedConditionArguments()

    if completeService:IsDoneCompleteCondition(completeConditionType, completeConditionParm, combinedConditionArguments) then
        cmptBattleStat:SetBattleWaveResult(true)
        return true
    end
    return false
end

--获取通关类型是否是通过怪物全部死亡来判断最后一击
function BattleService:IsCompletConditionMonsterDead()
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local levelCompleteConditionType = levelConfigData:GetLevelCompleteConditionType()
    return levelCompleteConditionType == CompleteConditionType.AllMonsterDead or
        levelCompleteConditionType == CompleteConditionType.WaveEnd
end

---检测关卡是否已完成
function BattleService:CheckLevelFinish()
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local levelCompleteConditionType = levelConfigData:GetLevelCompleteConditionType()
    local levelCompleteConditionParam = levelConfigData:GetLevelCompleteConditionParams()

    local combinedConditionArguments = levelConfigData:GetCombinedCompleteConditionArguments()
    ---@type CompleteConditionService
    local completeService = self._world:GetService("CompleteCondition")
    local isComplete =
        completeService:IsDoneCompleteCondition(
        levelCompleteConditionType,
        levelCompleteConditionParam,
        combinedConditionArguments
    )

    return isComplete
end

---处理己方的结算，检查玩家是否输了
---@return boolean
function BattleService:HandlePlayerCalculation()
    local player_entity = self._world:Player():GetLocalTeamEntity()

    if player_entity == nil then
        return false
    end

    local curHP = player_entity:Attributes():GetCurrentHP()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    if curHP <= 0 or affixService:IsEnoughPlayerBeHitCount() then
        self:LogNotice("player hp turn to zero,he has dead~")
        self:_GetBattleStatComponent():SetBattleWaveResult(false)
        return true
    end
    return false
end

--如果是守护机关死亡 战斗结束
function BattleService:HandleTrapCalculation()
    ---@type LevelConfigData
    local levelCfgData = self._configService:GetLevelConfigData()
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
                    self:_GetBattleStatComponent():SetBattleWaveResult(false)
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

function BattleService:HandleCurseTowerCalculation()
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

---检查战棋结算条件
function BattleService:HandleChessCalculation()
    if self._world:MatchType() ~= MatchType.MT_Chess then
        return false
    end

    ---@type BattleStatComponent
    local cmptBattleStat = self:_GetBattleStatComponent()
    local waveCount = cmptBattleStat:GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParm = levelConfigData:GetWaveCompleteConditionParam(waveCount)
    local chessPetGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.ChessPet)

    if completeConditionType == CompleteConditionType.CombinedCompleteCondition then
        local args = levelConfigData:GetCombinedCompleteConditionArguments()
        if
            args.conditionA == CompleteConditionType.ChessEscape or
                args.conditionA == CompleteConditionType.SelectChessEscape
         then
            completeConditionType = args.conditionA
            completeConditionParm = args.conditionParamA
        elseif
            args.conditionB == CompleteConditionType.ChessEscape or
                args.conditionB == CompleteConditionType.SelectChessEscape
         then
            completeConditionType = args.conditionB
            completeConditionParm = args.conditionParamB
        end
    end

    if completeConditionType == CompleteConditionType.SelectChessEscape then
        --如果是胜利条件24，指定棋子逃跑，需要判断指定棋子是否死亡
        local targetChessClassID = completeConditionParm[1][2]
        if (chessPetGroupEntities) and (#chessPetGroupEntities > 0) then
            for _, chessPet in ipairs(chessPetGroupEntities) do
                ---@type ChessPetComponent
                local chessPetCmpt = chessPet:ChessPet()
                local chessPetClassID = chessPetCmpt:GetChessPetClassID()
                local curHP = chessPet:Attributes():GetCurrentHP()
                if curHP > 0 and targetChessClassID == chessPetClassID then
                    return false
                end
            end
        end
    elseif completeConditionType == CompleteConditionType.ChessEscape then
        --如果是胜利条件23，需要判断棋子死亡数量
        local limitCount = completeConditionParm[1][1]

        local aliveChessCount = 0
        local escapeChessCount = 0
        if (chessPetGroupEntities) and (#chessPetGroupEntities > 0) then
            for _, chessPet in ipairs(chessPetGroupEntities) do
                ---@type ChessPetComponent
                local chessPetCmpt = chessPet:ChessPet()
                local chessPetClassID = chessPetCmpt:GetChessPetClassID()
                local curHP = chessPet:Attributes():GetCurrentHP()
                if curHP > 0 and not chessPet:HasMonsterEscape() then
                    aliveChessCount = aliveChessCount + 1
                end
                if chessPet:HasMonsterEscape() then
                    escapeChessCount = escapeChessCount + 1
                end
            end
        end
        if aliveChessCount > 0 or escapeChessCount >= limitCount then
            return false
        end
    else
        if (chessPetGroupEntities) and (#chessPetGroupEntities > 0) then
            for _, chessPet in ipairs(chessPetGroupEntities) do
                local curHP = chessPet:Attributes():GetCurrentHP()
                if curHP > 0 then
                    return false
                end
            end
        end
    end

    return true
end
function BattleService:HandleMonsterEscapeCalculation()
    ---@type BattleStatComponent
    local cmptBattleStat = self:_GetBattleStatComponent()
    local waveCount = cmptBattleStat:GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
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

--返回 击杀任意怪物达到xxx个 完成与否，有该条件且没完成 才会返回false 用于胜利判断
function BattleService:HandleKillAnyMonsterCountCalculation()
    ---@type BattleStatComponent
    local cmptBattleStat = self:_GetBattleStatComponent()
    local waveCount = cmptBattleStat:GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParm = levelConfigData:GetWaveCompleteConditionParam(waveCount)
    if completeConditionType == CompleteConditionType.CombinedCompleteCondition then
        local mode = completeConditionParm[1][1]
        if mode == CombinedCompleteConditionMode.And then
            local args = levelConfigData:GetCombinedCompleteConditionArguments()
            if
                args.conditionA == CompleteConditionType.KillAnyMonsterCount
            then
                completeConditionType = args.conditionA
                completeConditionParm = args.conditionParamA
            elseif
                args.conditionB == CompleteConditionType.KillAnyMonsterCount
            then
                completeConditionType = args.conditionB
                completeConditionParm = args.conditionParamB
            end
        end
    end

    if completeConditionType == CompleteConditionType.KillAnyMonsterCount then
        ---@type CompleteConditionService
        local completeService = self._world:GetService("CompleteCondition")
        if not completeService:IsDoneCompleteCondition(completeConditionType, completeConditionParm, nil) then
            return false
        end
    end

    return true
end
function BattleService:HandleMonsterCalculation(monster_entity)
end

function BattleService:CalcMonsterCount()
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local count = 0
    for k, v in ipairs(monster_group:GetEntities()) do
        count = count + 1
    end
    return count
end

--获取坐标位置上的怪物
function BattleService:SelectMonsterOnPos(grid_pos_list, limit)
    local monsters = {}
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, grid_pos in ipairs(grid_pos_list) do
        for _, e in ipairs(monster_group:GetEntities()) do
            local monster_grid_location_cmpt = e:GridLocation()
            if monster_grid_location_cmpt.Position == grid_pos and #monsters < limit then
                table.insert(monsters, e)
            end
        end
    end
    return monsters
end

--怪物死亡，真正销毁前，会加上一个deadflag组件，
--此时怪物处于预死亡阶段
function BattleService:IsAllMonstersPreDead(teamEntity)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local enemy = teamEntity:Team():GetEnemyTeamEntity()
        return enemy:HasTeamDeadMark()
    end

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local isDead = e:HasDeadMark()
        if not isDead then
            return false
        end
    end
     --符文刺客 离场怪
     local offBoardMonsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.OffBoardMonster)
     local offBoardMonsterEntities = offBoardMonsterGroup:GetEntities()
     for _, e in ipairs(offBoardMonsterEntities) do
        local isDead = e:HasDeadMark()
        if not isDead then
            return false
        end
     end

    return true
end

---@param teamEntity Entity
function BattleService:CheckAllMonstersDead(teamEntity)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local enemy = teamEntity:Team():GetEnemyTeamEntity()
        return enemy:HasTeamDeadMark()
    end

    local globalOffBoardMonsterGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.OffBoardMonster)
    if globalOffBoardMonsterGroup and (#globalOffBoardMonsterGroup > 0) then
        return false
    end

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    if monsterGroup == nil then
        return true
    end

    local aiActorCount = #monsterGroup:GetEntities()
    if aiActorCount <= 0 then
        ---目前是没有ai，就认为是没有monsters了
        return true
    end

    for _, e in ipairs(monsterGroup:GetEntities()) do
        local curHP = e:Attributes():GetCurrentHP()
        if curHP > 0 then
            return false
        end
    end

    return true
end

---需要检查指定机关是否存活
function BattleService:CheckSpecificTrapDead()
    ---@type BattleStatComponent
    local cmptBattleStat = self:_GetBattleStatComponent()
    local waveCount = cmptBattleStat:GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParm = levelConfigData:GetWaveCompleteConditionParam(waveCount)

    if completeConditionType == CompleteConditionType.TrapTypeDeadAndAllMonsterDead then
        ---@type CompleteConditionService
        local completeService = self._world:GetService("CompleteCondition")
        if completeService:IsDoneCompleteCondition(completeConditionType, completeConditionParm, nil) then
            return true
        end
    else
        return true
    end

    return false
end

---查询本波次完成条件类型
---@return CompleteConditionType
function BattleService:CurWaveCompleteConditionType()
    local waveCount = self:_GetBattleStatComponent():GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParam = levelConfigData:GetWaveCompleteConditionParam(waveCount)
    return completeConditionType, completeConditionParam
end

---@param waveCount number|nil nil => currentWaveIndex
---
function BattleService:WaveCombinedConditionArguments(waveCount)
    if not waveCount then
        waveCount = self:_GetBattleStatComponent():GetCurWaveIndex()
    end
    local levelConfigData = self._configService:GetLevelConfigData()
    return levelConfigData:GetWaveCombinedCompleteConditionArguments(waveCount)
end

---判断波次是否预结束了
function BattleService:IsWavePreEnd(teamEntity)
    local curWaveFinishType, curWaveFinishParam = self:CurWaveCompleteConditionType()
    local allMonsterPreDead = self:IsAllMonstersPreDead(teamEntity)

    if curWaveFinishType == CompleteConditionType.AllMonsterDead then
        if allMonsterPreDead == true then
            return true
        end
    else
        local combinedConditionArguments = self:WaveCombinedConditionArguments()
        ---@type CompleteConditionService
        local completeServices = self._world:GetService("CompleteCondition")
        local isFinish =
            completeServices:IsDoneCompleteCondition(curWaveFinishType, curWaveFinishParam, combinedConditionArguments)
        return isFinish
    end

    return false
end

---@return boolean 是否执行了死亡逻辑
function BattleService:LevelWinKillAllMonster()
    local curWaveFinishType = self:CurWaveCompleteConditionType()
    if curWaveFinishType ~= CompleteConditionType.AllBossNotSurvival then
        return false
    end
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local monster_entities = monster_group:GetEntities()
    for _, v in ipairs(monster_entities) do
        v:Attributes():Modify("HP", 0)
        sMonsterShowLogic:AddMonsterDeadMark(v, true)
    end
    local drops, deadEntityIDList = sMonsterShowLogic:DoAllMonsterDeadLogic()

    return true
end

function BattleService:IsFinalAttack()
    ---是否最后一波
    local isLastWave = self:_GetBattleStatComponent():IsLastWave()
    if not isLastWave then
        return false
    end
    local curWaveFinishType, curWaveFinishParam = self:CurWaveCompleteConditionType()

    ---@type BattleStatComponent
    local cmptBattleStat = self:_GetBattleStatComponent()
    --再判断所有怪物，目前使用AI组件来过滤，后边应该需要设计怪物专有组件
    local waveCount = cmptBattleStat:GetCurWaveIndex()

    -- 固定不触发最后一击
    if (curWaveFinishType ~= CompleteConditionType.CombinedCompleteCondition) and (not self:_IsNeedFinalAttack(curWaveFinishType)) then
        return false
    end

    if self:IsCompletConditionMonsterDead() then
        return self:IsAllMonsterHasDeadMarkAndNoDeadSkillSummon()
    else
        local combinedConditionArguments = self:WaveCombinedConditionArguments()
        ---@type CompleteConditionService
        local completeServices = self._world:GetService("CompleteCondition")
        local isFinish =
            completeServices:IsDoneCompleteCondition(curWaveFinishType, curWaveFinishParam, combinedConditionArguments)

        if isFinish and (curWaveFinishType == CompleteConditionType.CombinedCompleteCondition) then
            local isFinalAttack = self:_IsCombinedConditionNeedFinalAttack(curWaveFinishParam, combinedConditionArguments)
            return isFinalAttack
        end

        return isFinish
    end
end

---玩家行动阶段的最后一击判断(普攻和机关使用的判断)
function BattleService:IsPlayerTurnFinalAttack()
    return self:IsFinalAttack()
end

---是否所有怪都挂上了死亡组件 并且 没有死亡的怪物有死亡召唤的技能
function BattleService:IsAllMonsterHasDeadMarkAndNoDeadSkillSummon()
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local isDead = e:HasDeadMark()
        if not isDead then
            return false
        end

        if self:HasDeadSkillSummonMonster(e) then
            return false
        end
    end
    --符文刺客 离场怪
    local offBoardMonsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.OffBoardMonster)
    local offBoardMonsterEntities = offBoardMonsterGroup:GetEntities()
    for _, e in ipairs(offBoardMonsterEntities) do
        local isDead = e:HasDeadMark()
        if not isDead then
            return false
        end
    end
    return true
end

--怪物死亡技能会召唤新的怪物
function BattleService:HasDeadSkillSummonMonster(entity)
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local monsterIDCmpt = entity:MonsterID()
    local deathSkillID = 0
    if monsterIDCmpt then
        deathSkillID = monsterConfigData:GetMonsterDeathSkillID(monsterIDCmpt:GetMonsterID())
        if deathSkillID then
            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(deathSkillID)
            local cfgEffectArray = skillConfigData:GetSkillEffect()
            for index, cfgEffectParam in ipairs(cfgEffectArray) do
                if cfgEffectParam:GetEffectType() == SkillEffectType.SummonEverything then
                    return true
                end
            end
        end
    end
    return false
end

function BattleService:_IsNeedFinalAttack(curWaveFinishType)
    if
        curWaveFinishType == CompleteConditionType.CollectItems or
            curWaveFinishType == CompleteConditionType.RoundCountLimit or
            curWaveFinishType == CompleteConditionType.ArriveAtPos or
            curWaveFinishType == CompleteConditionType.AllRefreshMonsterDeadOrRoundCountLimit or
            curWaveFinishType == CompleteConditionType.CheckFlagBuffCount
     then
        return false
    end
    return true
end

---MSG62455(策)/MSG62478(程) 局内QA_复合胜利条件下是否播放最后一击的逻辑补充_20230509
---注意：只能在已经确定胜利之后进行检查
---注：代码行数确实可以再压缩，但压了之后的可读性不太有把握，容我三思
function BattleService:_IsCombinedConditionNeedFinalAttack(conditionParam, combinedConditionArguments)
    local mode = conditionParam[1][1]

    local conditionA = combinedConditionArguments.conditionA
    local conditionParamA = combinedConditionArguments.conditionParamA
    local conditionB = combinedConditionArguments.conditionB
    local conditionParamB = combinedConditionArguments.conditionParamB

    ---@type BattleStatComponent
    local uniqueBattleStat = self._world:BattleStat()
    local records = uniqueBattleStat:GetCombinedConditionRecord()

    if #records == 0 then
        Log.error("_IsCombinedConditionNeedFinalAttack: no combined condition record???")
        return true
    end

    local determiningConditionType

    if mode == CombinedCompleteConditionMode.And then
        -- 根据最终结算胜利时，最后达成的2个胜利条件中后达成的胜利条件判断是否播放最后一击
        local last = records[#records]
        local lastA = last.resultA
        local lastB = last.resultB

        -- 判断时没有完全达成胜利则不进行判断
        if not (lastA and lastB) then
            return false
        end

        for i = (#records - 1), 1, -1 do
            local data = records[i]
            if (not data.resultA) and (not data.resultB) then
                --前一次记录中两者都没有达成，(在与逻辑内)即2个胜利条件同时达成，规则引用如下：
                --若2个胜利条件同时达成，则根据monster_wave表中配置的第二个胜利条件判断是否播放最后一击
                determiningConditionType = conditionB
                break
            else
                --继续往前找
                if data.resultA and data.resultB then
                    goto CONTINUE
                else
                    --条件存在先后顺序，规则引用如下：
                    --最后达成的2个胜利条件中*后达成*的胜利条件判断是否播放最后一击
                    if (not data.resultA) then
                        determiningConditionType = conditionA
                        --elseif (not data.resultB) then
                    else
                        determiningConditionType = conditionB
                    end
                    break
                end
            end

            ::CONTINUE::

            lastA = data.resultA
            lastB = data.resultB
        end
    elseif mode == CombinedCompleteConditionMode.Or then
        --根据2个胜利条件中最先达成的胜利条件判断是否播放最后一击
        local first = records[#records]
        local lastA = first.resultA
        local lastB = first.resultB

        -- 判断时没有完全达成胜利则不进行判断
        if not (lastA or lastB) then
            return false
        end

        --只有一个条件达成，不需要判断另一个
        if lastA ~= lastB then
            determiningConditionType = lastA and conditionA or conditionB
        else
            --同时达成时需判断先后
            for i = (#records - 1), 1, -1 do
                local data = records[i]

                --两个条件在这轮判断中都没有达成，直接按上一次的数据判断
                if (not data.resultA) and (not data.resultB) then
                    break
                end

                lastA = data.resultA
                lastB = data.resultB

                --两个条件不是同时达成，已经可以判断
                if (lastA ~= lastB) then
                    break
                end
            end

            if lastA ~= lastB then
                determiningConditionType = lastA and conditionA or conditionB
            else
                --[[
                文档附加规则引用如下：
                  附目前无需播放最后一击的胜利条件：2-拾取指定物品、7-限制回合数、8-到达指定位置、11-全部刷新的怪物死亡或限制回合数、
                  12-计数buff累加到一定次数，策划在配置“或”关系的复合胜利条件时，需要将以上几种胜利条件配置在前面，保证最后结算时若
                  2个条件同时达成，也会播放预期表现

                  i.e. 如果两个条件就是同时达成的，按第一个条件进行判断
                ]]
                determiningConditionType = conditionA
            end
        end
    else
        Log.error("invalid combined complete condition mode: ", tostring(mode))
        return true
    end

    local condParam = determiningConditionType == conditionA and conditionParamA or conditionParamB

    --因不支持复合条件套娃，可以断定这里是单一条件
    ---@type CompleteConditionService
    local completeServices = self._world:GetService("CompleteCondition")
    return completeServices:IsDoneCompleteCondition(conditionA, condParam, nil)
end

---@return MathService
function BattleService:GetMathService()
    ---@type MathService
    local mathService = self._world:GetService("Math")
    return mathService
end

function BattleService:GetRandom(m, n)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    return randomSvc:LogicRand(m, n)
end

--region 出口
---@return boolean 当前波次是否为出波次
function BattleService:IsCurWaveExit()
    local waveType, _ = self:CurWaveCompleteConditionType()
    if waveType == CompleteConditionType.ArriveAtPos then
        return true
    end
    return false
end
---@return Vector2 返回当前波次的出口位置
function BattleService:CurWaveExitPos()
    local waveType, waveParam = self:CurWaveCompleteConditionType()
    if waveType == CompleteConditionType.ArriveAtPos then
        return Vector2(waveParam[1][1], waveParam[1][2])
    end
end
--endregion

--初始化词缀
function BattleService:InitWordBuff(GameStartBuffs)
    local words = self._world.BW_WorldInfo.wordBuffIds

    if words == nil or #words == 0 then
        return
    end
    ---@type BuffLogicService
    local buffLogic = self._world:GetService("BuffLogic")
    for _, wordID in ipairs(words) do
        local cfg = Cfg.cfg_word_buff[wordID]
        if cfg == nil then
            Log.fatal("word not found: ", wordID)
            return
        end
        for _, id in ipairs(cfg.BuffID) do
            -- Log.notice("[Word!!!] 初始化词缀，", wordID, "挂buff: ", id)
            local ret = buffLogic:AddBuffByTargetType(id, cfg.BuffTargetType, cfg.BuffTargetParam)
            ---@param inst BuffInstance
            for _, inst in ipairs(ret) do
                GameStartBuffs[#GameStartBuffs + 1] = {inst:Entity(), inst:BuffSeq()}
            end
        end
    end
end

function BattleService:InitTalePetBuff(GameStartBuffs)
    ---@type BuffLogicService
    local buffLogic = self._world:GetService("BuffLogic")

    local taleBuff = self._world.BW_WorldInfo.tale_pet_buffs
    if taleBuff and #taleBuff > 0 then
        for _, id in ipairs(taleBuff) do
            local ret = buffLogic:AddBuffByTargetType(id, BuffTargetType.AllTalePet, {})
            ---@param inst BuffInstance
            for _, inst in ipairs(ret) do
                GameStartBuffs[#GameStartBuffs + 1] = {inst:Entity(), inst:BuffSeq()}
            end
        end
    end

    local nonTaleBuff = self._world.BW_WorldInfo.normal_pet_buffs
    if nonTaleBuff and #nonTaleBuff > 0 then
        for _, id in ipairs(nonTaleBuff) do
            local ret = buffLogic:AddBuffByTargetType(id, BuffTargetType.AllNonTalePet, {})
            ---@param inst BuffInstance
            for _, inst in ipairs(ret) do
                GameStartBuffs[#GameStartBuffs + 1] = {inst:Entity(), inst:BuffSeq()}
            end
        end
    end
end

---@return SkillType
function BattleService:ParseSkillType(skillID)
    if not skillID then
        return nil
    end
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillCfg = cfgSvc:GetSkillConfigData(skillID)
    return skillCfg:GetSkillType()
end

---检查玩家是否已经死亡
function BattleService:PlayerIsDead(teamEntity)
    if self._world:MatchType() == MatchType.MT_Chess then
        local allChessDead = self:HandleChessCalculation()
        if allChessDead then
            return true
        end
        return false
    end

    ---@type AttributesComponent
    local attributeCmpt = teamEntity:Attributes()
    local playerHp = attributeCmpt:GetCurrentHP()
    if playerHp > 0 then
        ---@type AffixService
        local affixService = self._world:GetService("Affix")
        if affixService:IsEnoughPlayerBeHitCount() then
            return true
        end

        local isAllTowerActive = self:HandleCurseTowerCalculation()
        if isAllTowerActive then
            return true
        end
        return false
    else
        return true
    end
end

function BattleService:UpdateTeamHPLogic(teamEntity)
    ---@type AttributesComponent
    local teamAttrConmpt = teamEntity:Attributes()
    local petList = teamEntity:Team():GetTeamPetEntities()
    local maxHP = 0
    for i, entity in ipairs(petList) do
        ---@type AttributesComponent
        local attributesComponent = entity:Attributes()
        if attributesComponent then
            local petMaxHP = attributesComponent:CalcMaxHp()
            maxHP = petMaxHP + maxHP
        end
    end
    teamAttrConmpt:Modify("MaxHP", maxHP)

    self:LogNotice("UpdateTeamHPLogic()  maxHP=", maxHP)
end

function BattleService:UpdateTeamDefenceLogic(teamEntity)
    ---@type AttributesComponent
    local teamAttrConmpt = teamEntity:Attributes()

    local petList = teamEntity:Team():GetTeamPetEntities()
    local defence = 0
    for i, entity in ipairs(petList) do
        ---@type AttributesComponent
        local attributesComponent = entity:Attributes()
        if attributesComponent then
            local petdefence = attributesComponent:GetDefence()
            defence = petdefence + defence
        end
    end
    ---向上取整
    defence = math.ceil(defence)
    teamAttrConmpt:Modify("Defense", defence)
    self:LogNotice("UpdateTeamDefenceLogic defense=", defence)
end

function BattleService:UnloadPetLogic(teamEntity)
end

---@param casterEntity Entity
---@return number ,number
function BattleService:GetCasterHP(casterEntity)
    ---@type AttributesComponent
    local attributeCmpt
    if casterEntity:HasPetPstID() then
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        attributeCmpt = teamEntity:Attributes()
    else
        attributeCmpt = casterEntity:Attributes()
    end
    local HP = attributeCmpt:GetCurrentHP()
    local maxHP = attributeCmpt:CalcMaxHp()
    return HP, maxHP
end

function BattleService:GetAliveMonsterCount()
    ---@type Entity[]
    local MonsterEntityArray = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    local liveCount = 0
    for k, entity in ipairs(MonsterEntityArray) do
        if not entity:HasDeadMark() then
            liveCount = liveCount + 1
        end
    end
    return liveCount
end

function BattleService:CalcTeamElementTypeCount()
    local elementList = {}

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type Entity[]
    local teamMembers = teamEntity:Team():GetTeamPetEntities()
    for _, petEntity in ipairs(teamMembers) do
        ---@type ElementComponent
        local elementCmpt = petEntity:Element()
        local elementType = elementCmpt:GetPrimaryType()
        if not table.icontains(elementList, elementType) then
            table.insert(elementList, elementType)
        end
    end
    return #elementList
end

---@param matchType MatchType
---@param battleStatCmpt BattleStatComponent
---@return MatchResult
function BattleService:CalcBattleResultLogic(matchType, victory)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type MatchResult
    local result = MatchResult:New()
    result.victory = victory
    result.assign_wave_refresh_probability = self._world.BW_WorldInfo.assign_wave_refresh_probability
    if matchType == MatchType.MT_Mission then
        local mr = MissionResult:New()
        mr.star_condition = battleStatCmpt:GetBonusMatchResult() or {}
        result.mission_result[1] = mr
    elseif matchType == MatchType.MT_Campaign then
        local mr = CampaignMissionResult:New()
        mr.star_condition = battleStatCmpt:GetBonusMatchResult() or {}
        result.campaign_result[1] = mr
    elseif matchType == MatchType.MT_ExtMission then
        local mr = ExtMissionResult:New()
        mr.m_vecCondition = battleStatCmpt:GetBonusMatchResult() or {}
        result.ext_mission_result[1] = mr
    elseif matchType == MatchType.MT_ResDungeon then
        local mr = ResDungeonResult:New()
        if result.victory then
            mr.ext_rewards = battleStatCmpt:GetDropRoleAsset()
            mr.ext_rewards_no_double = battleStatCmpt:GetDropRoleAssetNoDouble()
        end
        mr.m_vecCondition = battleStatCmpt:GetBonusMatchResult() or {}
        result.res_dungeon_result[1] = mr
    elseif matchType == MatchType.MT_TalePet then
        local mr = TalePetResult:New()
        result.tale_pet_reward[1] = mr
    elseif matchType == MatchType.MT_LostArea then
        local mr = LostAreaResult:New()
        result.lost_area_result[1] = mr
    elseif matchType == MatchType.MT_Maze then
        local mr = MazeResult:New()
        local mazeService = self._world:GetService("Maze")
        --剩余能量
        local pet_infos = {}
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        local petEntities = teamEntity:Team():GetTeamPetEntities()
        for _, e in ipairs(petEntities) do
            ----@type MatchPetResult
            local info = MatchPetResult:New()
            info.pet_pstid = e:PetPstID():GetPstID()
            info.pet_power = e:Attributes():GetAttribute("Power")
            info.pet_legendPower = e:Attributes():GetAttribute("LegendPower")
            local hp = e:Attributes():GetCurrentHP()
            info.pet_blood = hp / e:Attributes():CalcMaxHp()
            if hp <= 0 then
                info.pet_is_dead = true
            end
            table.insert(pet_infos, info)
        end
        mr.pet_result = pet_infos
        --圣物记录
        mr.relics_counters = mazeService:GetRelicCounters()
        --局内掉落
        local drops = battleStatCmpt:GetTotalDropAssets()
        if drops then
            mr.drop_rewards = table.toArray(drops)
        end
        --局内存档
        mr.battle_archive = self:CalcBattleArchive()
        mr.save_archive = false
        result.maze_result[1] = mr
    elseif matchType == MatchType.MT_Tower then
        local mr = TowerResult:New()
        result.tower_result[1] = mr
    elseif matchType == MatchType.MT_Conquest then
        local mr = ConquestMissionResult:New()
        local curTeamHP = battleStatCmpt:GetPlayerHP()
        local currentWaveIndex = battleStatCmpt:GetCurWaveIndex()
        if curTeamHP <= 0 and currentWaveIndex <= 1 then
            result.victory = false
        else
            result.victory = true
        end
        if not battleStatCmpt:GetBattleLevelResult() then
            currentWaveIndex = currentWaveIndex - 1
        end
        mr.pass_wave_index = currentWaveIndex
        result.conquest_mission_result[1] = mr
    elseif matchType == MatchType.MT_BlackFist then
        local mr = BlackFistResult:New()
        result.black_fist_result[1] = mr
    elseif matchType == MatchType.MT_WorldBoss then
        local mr = WorldBossResult:New()
        --local total_damage = battleStatCmpt:GetTotalMonsterBeHitDamageValue()
        local total_damage = battleStatCmpt:GetMainWorldBossBeHitDamageValue()--只统计主boss的伤害，多boss时会配伤害传递
        if not victory then
            result.victory = total_damage > 0
        end
        if total_damage > BattleConst.TotalDamageMaxValue then
            Log.fatal("[SyncLog],type:", BattleFailedType.TotalDamageTooLarge, " TotalDamageValue:", total_damage)
            mr.total_damage = total_damage % BattleConst.TotalDamageMaxValueMod
        else
            --mr.total_damage = battleStatCmpt:GetTotalMonsterBeHitDamageValue()
            mr.total_damage = battleStatCmpt:GetMainWorldBossBeHitDamageValue()
            Log.debug("WorldBossResult Damage:", mr.total_damage)
        end
        result.world_boss_result[1] = mr
    elseif matchType == MatchType.MT_Chess then
        local mr = ChessMissionResult:New()
        mr.star_condition = battleStatCmpt:GetBonusMatchResult() or {}
        result.chess_mission_result[1] = mr
    elseif matchType == MatchType.MT_DifficultyMission then
        local mr = DifficultyMissionResult:New()
        result.difficulty_mission_result[1] = mr
    elseif matchType == MatchType.MT_SailingMission then
        local mr = SailingMissionResult:New()
        result.sailing_mission_result[1] = mr
    elseif matchType == MatchType.MT_MiniMaze then
        local mr = BloodsuckerMissionResult:New()
        local curTeamHP = battleStatCmpt:GetPlayerHP()
        local currentWaveIndex = battleStatCmpt:GetCurWaveIndex()
        if curTeamHP <= 0 and currentWaveIndex <= 1 then
            result.victory = false
        else
            result.victory = true
        end
        if not battleStatCmpt:GetBattleLevelResult() then
            currentWaveIndex = currentWaveIndex - 1
        end
        mr.is_full_blood = battleStatCmpt:IsFullBlood()
        mr.kill_monster_num = battleStatCmpt:GetKillMonsterCount()
        mr.pass_pet_type_num = self:CalcTeamElementTypeCount()
        mr.pass_wave_index = currentWaveIndex
        mr.select_pets = battleStatCmpt:GetAllMiniMazePartnerList()
        mr.select_relics = battleStatCmpt:GetAllMiniMazeRelicList()
        result.bloodsucker_mission_result[1] = mr
    elseif matchType == MatchType.MT_PopStar then
        local mr = PopStarMissionResult:New()
        mr.star_condition = battleStatCmpt:GetBonusMatchResult() or {}
        ---@type PopStarServiceLogic
        local popStarSvc = self._world:GetService("PopStarLogic")
        mr.star_num = popStarSvc:GetPopGridNum()
        result.popstar_mission_result[1] = mr
    elseif matchType == MatchType.MT_Season then
        local mr = SeasonMissionResult:New()
        mr.star_condition = battleStatCmpt:GetBonusMatchResult() or {}
        result.season_mission_result[1] = mr
    elseif matchType == MatchType.MT_EightPets then
        local mr = EightPetsResult:New()
        result.eight_pets_mission_result[1] = mr
    end
    return result
end

function BattleService:CalcBattleArchive()
    local t = {}
    --棋盘
    ---@type BoardEntity
    local boardEntity = self._world:GetBoardEntity()
    local pieceTypes = boardEntity:Board().Pieces

    --颜色信息
    local pieces = {}
    t.pieces = pieces
    for x, row in pairs(pieceTypes) do
        pieces[x] = {}
        for y, v in pairs(row) do
            pieces[x][y] = v
        end
    end

    --怪物血量位置[2021-6-21增加怪物锁血状态]
    local monsters = {}
    t.monsters = monsters
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for i, e in ipairs(monsterGroup:GetEntities()) do
        local val = e:Attributes():GetCurrentHP()
        if val and val > 0 then
            local monsterID = e:MonsterID():GetMonsterID()
            local m = {
                monsterID = monsterID,
                hp = val,
                pos = e:GridLocation().Position,
                dir = e:GridLocation().Direction,
                offset = e:GridLocation().Offset,
                bodyArea = e:BodyArea():GetArea(),
                aiData = e:AI():GetRuntimeData()
            }
            --特效存档
            local effHolder = e:EffectHolder()
            if effHolder then
                m.effect = effHolder:GetBindEffectID()
            end
            --buff状态
            m.buffData = e:BuffComponent():SaveArchivedData()
            table.insert(monsters, m)
        end
    end

    --玩家位置
    local team = self._world:Player():GetLocalTeamEntity()
    t.team = {
        pos = team:GridLocation().Position,
        dir = team:GridLocation().Direction
    }

    --机关位置
    local traps = {}
    t.traps = traps
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if e:Trap():GetTrapType() ~= TrapType.Protected and not e:HasDeadMark() then
            traps[#traps + 1] = {
                trapID = e:Trap():GetTrapID(),
                pos = e:GridLocation().Position,
                dir = e:GridLocation().Direction
            }
        end
    end

    --保护机关要保存满血
    local protectTrap = self._world:BattleStat():GetSavedProtectTrap()
    if protectTrap then
        for k, v in ipairs(protectTrap) do
            traps[#traps + 1] = v
        end
    end

    --过关条件进度
    local completion = {}
    t.completion = completion
    local cfgsvc = self._world:GetService("Config")
    local cond = cfgsvc:GetLevelConfigData():GetLevelCompleteConditionType()
    completion.cond = cond
    ---@type CompleteConditionService
    local ccsvc = self._world:GetService("CompleteCondition")
    completion.data = ccsvc:GetArchivedData(cond)

    --关卡掉落存档
    local drops = self._world:BattleStat():GetArchivedDrops()
    t.drops = drops

    return echo(t)
end

function BattleService:GetLocalTeamHP()
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type AttributesComponent
    local attributeCmpt = teamEntity:Attributes()
    local curHP = attributeCmpt:GetCurrentHP()
    local maxHP = attributeCmpt:CalcMaxHp()
    return curHP, maxHP
end
---@return Entity
function BattleService:GetWorldBossEntity()
    ---@type Entity[]
    local groupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for k, entity in ipairs(groupEntities) do
        if entity:MonsterID():IsWorldBoss() then
            return entity
        end
    end
end

---@return Entity
function BattleService:GetWorldBossEntityArray()
    local entityArray = {}
    ---@type Entity[]
    local groupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for k, entity in ipairs(groupEntities) do
        if entity:MonsterID():IsWorldBoss() then
            table.insert(entityArray,entity)
        end
    end
    return entityArray
end

function BattleService:ChangeLocalTeamLeader(petPstID, sendNTTeamOrderChange)
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local petEntity = teamEntity:Team():GetPetEntityByPetPstID(petPstID)
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
    if not petEntity or petEntity:GetID() == teamLeaderEntity:GetID() then
        Log.fatal("ChangeTeamLeader Failed Pet Invalid PetPstID:", petPstID)
        return false
    end

    Log.debug("ChangeTeamLeader oldPet=", teamLeaderEntity:GetID(), " newPet=", petEntity:GetID())
    local teamOrderBeforeTmp = teamEntity:Team():GetTeamOrder()
    local teamOrderBefore = table.cloneconf(teamOrderBeforeTmp)

    --替换逻辑顺序
    teamEntity:SetTeamLeaderPetEntity(petEntity)
    local teamOrderAfter = teamEntity:Team():GetTeamOrder()
    local teamOrderAfterClone = table.cloneconf(teamOrderAfter)

    --通知队伍顺序变化
    if sendNTTeamOrderChange then
        self._world:GetService("Trigger"):Notify(NTTeamOrderChange:New(teamEntity, teamOrderBefore, teamOrderAfter))
    end

    return teamOrderBefore, teamOrderAfterClone
end

---@param teamEntity Entity team entity
---@return Entity|nil first suitable candidate
function BattleService:GetFirstLeaderCandidate(teamEntity)
    local cTeam = teamEntity:Team()
    local tTeamOrder = cTeam:GetTeamOrder()
    for i = 2, #(tTeamOrder) do
        local pstID = tTeamOrder[i]
        local e = cTeam:GetPetEntityByPetPstID(pstID)
        if (not e:HasBuffFlag(BuffFlags.SealedCurse)) and (not e:PetPstID():IsHelpPet()) then
            return e
        end
    end
end

function BattleService:CanBeTeamLeader(entity)
    if (not entity:HasPetPstID()) or (entity:PetPstID():IsHelpPet()) then
        return false
    end
    local bSealed = entity:HasBuffFlag(BuffFlags.SealedCurse)
    local bAble = true
    if bSealed then
        bAble = false
    end
    return bAble
end


---@param pos Vector2
function BattleService:FindMonsterEntityInPos(checkPos, withDead)
    local targetEntityID = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if withDead or not e:HasDeadMark() then
            local monsterEntityID = e:GetID()
            local monster_grid_location_cmpt = e:GridLocation()
            local monster_body_area_cmpt = e:BodyArea()
            local monster_body_area = monster_body_area_cmpt:GetArea()
            for i, bodyArea in ipairs(monster_body_area) do
                local curMonsterBodyPos = monster_grid_location_cmpt.Position + bodyArea
                if curMonsterBodyPos == checkPos then
                    --targetEntityID = monsterEntityID
                    if e:HasRide() and e:Ride():GetRiderID() == monsterEntityID then
                        table.insert(targetEntityID, 1, monsterEntityID)
                    else
                        table.insert(targetEntityID, monsterEntityID)
                    end
                    break
                end
            end

            --没有加进来的再判断一下
            if not table.intable(targetEntityID, monsterEntityID) then
                --bodyArea不包括坐标中点的也要加进来(n20魔方BOSS瘫痪后)
                if monster_grid_location_cmpt:GetGridPos() == checkPos then
                    table.insert(targetEntityID, monsterEntityID)
                end
            end
        end
    end
    --下面这种方式依赖阻挡信息，击退的时候触发机关时阻挡还没更新
    -- ---@type BoardServiceLogic
    -- local svc = self._world:GetService("BoardLogic")
    -- local es = svc:GetMonstersAtPos(checkPos)
    -- local e = es[1]
    -- if e and (withDead or (not e:HasDeadMark())) and self:SelectConditionFilter(e) then
    --     targetEntityID = e:GetID()
    -- end
    return targetEntityID
end
----------------------

function BattleService:KillPlayer()
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type Vector2
    ---@type AttributesComponent
    local attributeCmpt = teamEntity:Attributes()
    attributeCmpt:Modify("HP",0)
    teamEntity:AddTeamDeadMark()
end

---@param relicID number
---@param switchState WaveResultAwardNextStateType
function BattleService:ApplyRelic(relicID, switchState,reApply)
    Log.debug("[MiniMaze] BattleService ApplyRelic relicID: ",relicID)
    local cfg = Cfg.cfg_item_relic[relicID]
    if not cfg then
        return
    end
    
    --存储选择过的圣物
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if not battleStatCmpt then
        return
    end
    --if self._world:RunAtServer() then
    if not reApply then--加伙伴时会重新调用Apply
        if switchState == WaveResultAwardNextStateType.WaitInput then
            battleStatCmpt:SetChooseRelic(relicID)
            ---@type TalentService
            local talentSvc = self._world:GetService("Talent")
            ---@type TalentComponent
            local talentCmpt = talentSvc:GetTalentComponent()
            talentCmpt:SetIsChosenOpeningRelic(true)
        else
            battleStatCmpt:SetWaveChooseRelic(battleStatCmpt:GetCurWaveIndex(), relicID)
        end
    end
    Log.debug("[MiniMaze] BattleService ApplyRelic step has battle stat")

    if #cfg.BuffID == 0 then
        return
    end
    Log.debug("[MiniMaze] BattleService ApplyRelic step has BuffID")

    local relicBuffs = {}
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    for _, buffID in ipairs(cfg.BuffID) do
        if buffID > 0 then
            Log.notice("[MiniMazeRelic] add buff:", buffID, " relic:", relicID)
            local buffIns = buffLogicSvc:AddBuffByTargetType(buffID, cfg.BuffTargetType, cfg.BuffTargetParam)
            for _, buffIn in ipairs(buffIns) do
                buffIn:SetRelicID(relicID)
                relicBuffs[#relicBuffs + 1] = { buffIn:Entity(), buffIn:BuffSeq() }
            end
        end
    end

    ---@type L2RService
    --local l2RSvc = self._world:GetService("L2R")
    --l2RSvc:L2RAddRelicData(relicID, relicBuffs, switchState)
    return relicID, relicBuffs
end

function BattleService:CalcRandomRelic(groupID, count)
    local relicGroupID = groupID
    local randomCount = count
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if not relicGroupID and not randomCount then
        local curWaveIndex = battleStatCmpt:GetCurWaveIndex()
        ---@type LevelConfigData
        local levelConfigData = self._configService:GetLevelConfigData()
        local cfgMiniMazeWave = levelConfigData:GetMiniMazeWaveCfg(curWaveIndex)
        if not cfgMiniMazeWave then
            return
        end
        if not cfgMiniMazeWave.RelicGroupID then
            return
        end
        if not cfgMiniMazeWave.RelicCount or (cfgMiniMazeWave.RelicCount <= 0) then
            return
        end
        relicGroupID = cfgMiniMazeWave.RelicGroupID
        randomCount = cfgMiniMazeWave.RelicCount
    end
    
    local relicGroupCfg = Cfg.cfg_mini_maze_relic_group[relicGroupID]
    if not relicGroupCfg then
        return
    end

    local relicIDArray = relicGroupCfg.RelicIDArray
    if not relicIDArray or #relicIDArray <= 0 then
        return
    end

    ---@type TalentService
    local talentSvc = self._world:GetService("Talent")
    local unlockRelicIDList = talentSvc:GetUnlockRelicIDList()
    local lockRelicIDArray = {}
    if relicGroupCfg.LockRelicIDArray then
        for _, value in ipairs(relicGroupCfg.LockRelicIDArray) do
            --检查圣物是否解锁
            if not table.icontains(unlockRelicIDList, value) then
                table.insert(lockRelicIDArray, value)
            end
        end
    end    

    local tmpRelicIDList = table.cloneconf(relicIDArray)
    local randomRelicIDList = {}
    local invalidRelicIDList = battleStatCmpt:GetInvalidRelicIDList(relicGroupID) or {}
    table.appendArray(invalidRelicIDList, lockRelicIDArray)
    local selectedRelicIDList = battleStatCmpt:GetAllMiniMazeRelicList() or {}
    table.appendArray(invalidRelicIDList, selectedRelicIDList)
    for _, value in ipairs(tmpRelicIDList) do
        if not table.icontains(invalidRelicIDList, value) then            
            table.insert(randomRelicIDList, value)
        end
    end

    local relics = {}
    for i = 1, randomCount do
        --异常处理：可随机数量不足时，重置随机池(已选取的需要排除掉)
        if #randomRelicIDList < 1 then
            local selectedRelicIDList = battleStatCmpt:GetAllMiniMazeRelicList()
            table.appendArray(selectedRelicIDList, lockRelicIDArray)
            table.appendArray(selectedRelicIDList, relics)
            for _, value in ipairs(tmpRelicIDList) do
                if not table.icontains(selectedRelicIDList, value) then
                    table.insert(randomRelicIDList, value)
                end
            end
        end

        if #randomRelicIDList >= 1 then
            local randomRes = self:GetRandom(1, #randomRelicIDList)
            local relicID = randomRelicIDList[randomRes]
            table.insert(relics, relicID)
            table.removev(randomRelicIDList, relicID)
        end        
    end
    if #relics > 0 then
        battleStatCmpt:SetInvalidRelicIDList(relicGroupID, relics)
        return relics
    end
end

function BattleService:_RandomByWeight(eliteGroup, weightGroup)
    if #eliteGroup ~= #weightGroup or #eliteGroup < 1 then
        return
    end

    local totalWeight = 0
    for _, w in ipairs(weightGroup) do
        totalWeight = totalWeight + w
    end

    local rand = self:GetRandom()

    local eliteID = eliteGroup[1]
    local curWeight = rand * totalWeight
    for i, w in ipairs(weightGroup) do
        curWeight = curWeight - w
        if curWeight <= 0 then
            eliteID = eliteGroup[i]
            table.remove(eliteGroup, i)
            table.remove(weightGroup, i)
            return eliteID
        end
    end
end

---@param nMonsterID number
---@return number[]
function BattleService:CalcEliteIDArray(nMonsterID)
    ---@type MonsterConfigData
    local monsterCfgData = self._configService:GetMonsterConfigData()

    --配置的精英词缀列表
    local eliteIDArray = monsterCfgData:GetEliteIDArray(nMonsterID)

    --随机参数
    local randomParam = monsterCfgData:GetEliteIDRandomParam(nMonsterID)
    if randomParam then
        local eliteCount = randomParam.count
        local weightArray = table.cloneconf(randomParam.weight)
        if eliteCount > #eliteIDArray or #weightArray ~= #eliteIDArray then
            Log.error("Monster Elite Random Weight config err, monsterID=", nMonsterID)
            return
        end

        local randomEliteIDArray = {}
        for i = 1, eliteCount do
            local eliteID = self:_RandomByWeight(eliteIDArray, weightArray)
            if eliteID then
                table.insert(randomEliteIDArray, eliteID)
            end
        end
        if #randomEliteIDArray > 0 then
            eliteIDArray = randomEliteIDArray
        end
    end    

    --应用词条调整词缀
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    local retEliteID = affixSvc:ReplaceMonsterEliteBuff(nMonsterID, eliteIDArray)
    retEliteID = affixSvc:AddMonsterEliteBuff(nMonsterID, retEliteID)
    return retEliteID or {}
end

---检查消灭星星模式下，消除个数是否不够
function BattleService:HandlePopStarNumber()
    if self._world:MatchType() ~= MatchType.MT_PopStar then
        return false
    end

    ---@type BattleStatComponent
    local cmptBattleStat = self:_GetBattleStatComponent()
    local waveCount = cmptBattleStat:GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
    ---@type CompleteConditionType
    local completeConditionType = levelConfigData:GetWaveCompleteConditionType(waveCount)
    local completeConditionParm = levelConfigData:GetWaveCompleteConditionParam(waveCount)

    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    if completeConditionType == CompleteConditionType.ComparePopStarNumber then
        local popBaseNumber = completeConditionParm[1][2]
        local curPopNum = popStarSvc:GetPopGridNum()

        local notEnough = curPopNum < popBaseNumber
        return notEnough
    end

    return false
end
---@param entity Entity
---@return PetSexType
function BattleService:GetPetSexType(entity)
    ---@type PetPstIDComponent
    local petPstIDCmpt = entity:PetPstID()
    local templateID =petPstIDCmpt:GetTemplateID()
    local cfgPet =  Cfg.cfg_pet[templateID]
    if cfgPet then
        return cfgPet.PetProperty
    end
end