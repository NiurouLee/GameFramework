--[[------------------------------------------------------------------------------------------
    BonusCalcService 结算条件计算服务
]] --------------------------------------------------------------------------------------------

---@class BonusCalcService:BaseService
_class("BonusCalcService", BaseService)
BonusCalcService = BonusCalcService

function BonusCalcService:Constructor(world)
    ---注册计算器
    self._bonusConditionFuncDic = {}

    self._bonusConditionFuncDic[BonusObjectiveType.NoAdditional] = self._NoAdditional
    self._bonusConditionFuncDic[BonusObjectiveType.Health] = self._CalcHealth
    self._bonusConditionFuncDic[BonusObjectiveType.LastWaveRoundNum] = self._CalcLastWaveRoundNum
    self._bonusConditionFuncDic[BonusObjectiveType.SuperChainCount] = self._CalcSuperChainCount
    self._bonusConditionFuncDic[BonusObjectiveType.ActiveSkillCount] = self._CalcActiveSkillCount
    self._bonusConditionFuncDic[BonusObjectiveType.AllElementTeam] = self._CalcAllElementTeam
    self._bonusConditionFuncDic[BonusObjectiveType.SelectElement] = self._CalcSelectElement
    self._bonusConditionFuncDic[BonusObjectiveType.MatchNum] = self._CalcMatchNum
    self._bonusConditionFuncDic[BonusObjectiveType.TrapAttackTimes] = self._CalcTrapAttackTimes
    self._bonusConditionFuncDic[BonusObjectiveType.TrapAttackDammage] = self._CalcTrapAttackDammage
    self._bonusConditionFuncDic[BonusObjectiveType.TrapAttackTotalTimes] = self._CalcTrapAttackTotalTimes
    self._bonusConditionFuncDic[BonusObjectiveType.TrapAttackTotalDamage] = self._CalTrapAttackTotalDamage
    self._bonusConditionFuncDic[BonusObjectiveType.SmashTrapCount] = self._CalSmashTrapCount
    self._bonusConditionFuncDic[BonusObjectiveType.SmashTrapTotalCount] = self._CalSmashTrapTotalCount
    self._bonusConditionFuncDic[BonusObjectiveType.TotalMatchPropertyNum] = self._CalTotalMatchPropertyNum
    self._bonusConditionFuncDic[BonusObjectiveType.OnceMatchPropertyNum] = self._CalOnceMatchPropertyNum
    self._bonusConditionFuncDic[BonusObjectiveType.OnceMatchNorAttTimes] = self._CalOnceMatchNorAttTimes
    self._bonusConditionFuncDic[BonusObjectiveType.ColorSkillCount] = self._CalColorSkillCount
    self._bonusConditionFuncDic[BonusObjectiveType.AuroraTimeCount] = self._CalAuroraTimeCount
    self._bonusConditionFuncDic[BonusObjectiveType.PlayerBeHitCount] = self._CalPlayerBeHitCount
    self._bonusConditionFuncDic[BonusObjectiveType.CompelHelpPet] = self._CalCompelHelpPet
    self._bonusConditionFuncDic[BonusObjectiveType.ForbidHelpPet] = self._CalForbidHelpPet
    self._bonusConditionFuncDic[BonusObjectiveType.KillMonstersInLimitedRound] = self._CalKillMonstersInLimitedRound
    self._bonusConditionFuncDic[BonusObjectiveType.KillMonstersWithBuff] = self._CalKillMonstersWithBuff
    self._bonusConditionFuncDic[BonusObjectiveType.CollectItems] = self._CalCollectItems
    self._bonusConditionFuncDic[BonusObjectiveType.UIChangeTeamLeaderCount] = self._CalChangeTeamLeaderTimes
    self._bonusConditionFuncDic[BonusObjectiveType.HitBySkill] = self._CalHitBySkill
    self._bonusConditionFuncDic[BonusObjectiveType.ChessDeadPlayerPawnCount] = self._CalChessDeadPlayerPawnCount
    self._bonusConditionFuncDic[BonusObjectiveType.MonsterEscapeLessThan] = self._CalMonsterEscapeLessThan
    self._bonusConditionFuncDic[BonusObjectiveType.PopStarNumber] = self.CalPopStarNumber
end

function BonusCalcService:CalcCondition(conditionType, conditionParam)
    local calcFunc = self._bonusConditionFuncDic[conditionType]
    if calcFunc ~= nil then
        return calcFunc(self, conditionParam)
    else
        Log.fatal("No bonus calculator", conditionType)
    end

    return false
end

---检查当前关卡是否完成
function BonusCalcService:_NoAdditional()
    return self:_GetBattleStatComponent():GetBattleLevelResult()
end

function BonusCalcService:_CalCompelHelpPet()
    local bComplete = self:_GetBattleStatComponent():GetBattleLevelResult()
    if bComplete then
        return self._world:IsHaveHelpPet()
    end
    return bComplete
end

function BonusCalcService:_CalForbidHelpPet()
    local bComplete = self:_GetBattleStatComponent():GetBattleLevelResult()
    if bComplete then
        return not self._world:IsHaveHelpPet()
    end
    return bComplete
end

---检查血量
function BonusCalcService:_CalcHealth(conditionParam)
    ---@type CalcDamageService
    local calcDamageService = self._world:GetService("CalcDamage")
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    if teamEntity == nil then 
        return false
    end

    local curHp, maxHp = calcDamageService:GetTeamLogicHP(teamEntity)
    local targetPercent = conditionParam / 100
    local curPercent = curHp / maxHp
    if curPercent >= targetPercent then
        return true
    end
    return false
end

---剩余回合数
function BonusCalcService:_CalcLastWaveRoundNum(conditionParam)
    local leftWaveCount = self:_GetBattleStatComponent()._curWaveLeftRoundCount
    local needCount = tonumber(conditionParam[1])
    if leftWaveCount >= needCount then
        return true
    else
        return false
    end
end

---超级连锁数
function BonusCalcService:_CalcSuperChainCount(conditionParam)
    local superChainCount = tonumber(conditionParam[1])
    local curSuperChainCount = self:_GetBattleStatComponent():GetSuperChainCount()
    if curSuperChainCount >= superChainCount then
        return true
    end

    return false
end

---主动技释放数
function BonusCalcService:_CalcActiveSkillCount(conditionParam)
    local activeSkillCount = tonumber(conditionParam[1])
    local curActiveSkillCount = self:_GetBattleStatComponent():GetActiveSkillCount()
    if curActiveSkillCount >= activeSkillCount then
        return true
    end

    return false
end

---是否全属性出战
function BonusCalcService:_CalcAllElementTeam(conditionParam)
    local teamElement = {}

    ---@type JoinedPlayerInfo
    local joinedPlayerInfo = self._world.BW_WorldInfo.localPlayerInfo
    for petIndex, petinfo in ipairs(joinedPlayerInfo.pet_list) do
        local petPstID = petinfo.pet_pstid
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        local elementType = petData:GetPetFirstElement()
        teamElement[#teamElement + 1] = elementType
    end

    local hasBlue = table.icontains(teamElement, ElementType.ElementType_Blue)
    if not hasBlue then
        return false
    end

    local hasRed = table.icontains(teamElement, ElementType.ElementType_Red)
    if not hasRed then
        return false
    end

    local hasGreen = table.icontains(teamElement, ElementType.ElementType_Green)
    if not hasGreen then
        return false
    end

    local hasYellow = table.icontains(teamElement, ElementType.ElementType_Yellow)
    if not hasYellow then
        return false
    end

    return true
end

---有N个M属性的成员出战
function BonusCalcService:_CalcSelectElement(conditionParam)
    local memCount = tonumber(conditionParam[1])
    local memElement = tonumber(conditionParam[2])

    local curCount = 0

    ---@type JoinedPlayerInfo
    local joinedPlayerInfo = self._world.BW_WorldInfo.localPlayerInfo
    for petIndex, petInfo in ipairs(joinedPlayerInfo.pet_list) do
        local petPstID = petInfo.pet_pstid
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        local elementType = petData:GetPetFirstElement()
        if elementType == memElement then
            curCount = curCount + 1
        end
    end

    if curCount >= memCount then
        return true
    end

    return false
end

---消除格子
function BonusCalcService:_CalcMatchNum(conditionParam)
    local matchType = tonumber(conditionParam[1])
    local matchParam = tonumber(conditionParam[2])

    if matchType == 1 then --单次连线消除X个格子
        local oneMatchNum = self:_GetBattleStatComponent():GetOneMatchMaxNum()
        if oneMatchNum >= matchParam then
            return true
        end
    elseif matchType == 2 then --单局消除X个格子
        local totalMatchNum = self:_GetBattleStatComponent():GetTotalMatchNum()
        if totalMatchNum >= matchParam then
            return true
        end
    elseif matchType == 3 then --单局消除X个同色格子
        local elementMatchArray = self:_GetBattleStatComponent():GetElementMatchNum()
        for k, v in pairs(elementMatchArray) do
            if v >= matchParam then
                return true
            end
        end
    end

    return false
end

-- 累计消除Y个X属性格子
function BonusCalcService:_CalTotalMatchPropertyNum(conditionParam)
    local l_PieceType = tonumber(conditionParam[1])
    local l_MatchNum = tonumber(conditionParam[2])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local elementMatchArray = battleStateCmpt:GetElementMatchNum()
    local l_value = elementMatchArray[l_PieceType]
    if l_value ~= nil and l_value >= l_MatchNum then
        return true
    end
    return false
end

-- 一次性消除Y个X属性格子
function BonusCalcService:_CalOnceMatchPropertyNum(conditionParam)
    local l_PieceType = tonumber(conditionParam[1])
    local l_MatchNum = tonumber(conditionParam[2])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local battleState_type = battleStateCmpt:GetOneMatchMaxNumType()
    local battleState_MatChNum = battleStateCmpt:GetOneMatchMaxNum()

    if battleState_MatChNum >= l_MatchNum and battleState_type == l_PieceType then
        return true
    end
    return false
end

-- 被Y机关攻击次数少于X
function BonusCalcService:_CalcTrapAttackTimes(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_times = battleStateCmpt:GetTakeAttackTimesByTrap() -- 获取玩家被机关攻击次数 key:trapid value:被打次数
    --local nCondCount = 0
    for key, value in pairs(conditionParam) do
        if trap_attack_times[key] ~= nil and trap_attack_times[key] >= value then -- 没被该trap打过 或者 挨打次数比配置的挨打次数少
            --nCondCount = nCondCount + 1
            return false
        end
    end

    return true
    -- if nCondCount < table.count(conditionParam) then
    --     return true
    -- else
    --     return false
    -- end
end

-- 被Y机关攻击伤害少于X
function BonusCalcService:_CalcTrapAttackDammage(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_damage = battleStateCmpt:GetTakeAttackDamageByTrap()

    for key, value in pairs(conditionParam) do
        if trap_attack_damage[key] ~= nil and trap_attack_damage[key] >= value then
            return false
        end
    end

    return true
end

-- 被Y机关攻击总次数少于X
function BonusCalcService:_CalcTrapAttackTotalTimes(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_times = battleStateCmpt:GetTakeAttackTimesByTrap() -- 获取玩家被机关攻击次数 key:trapid value:被打次数

    local nCondCount = 0 --
    -- 判断是否达成
    for key, value in pairs(conditionParam) do
        if key ~= "TotalCount" and trap_attack_times[key] ~= nil then
            nCondCount = nCondCount + trap_attack_times[key]
        end
    end

    -- 如果挨打总次数大于配置次数 则不完成
    if nCondCount >= conditionParam["TotalCount"] then
        return false
    else
        return true
    end
end

-- 被Y机关攻击总伤害少于X
function BonusCalcService:_CalTrapAttackTotalDamage(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_damage = battleStateCmpt:GetTakeAttackDamageByTrap()

    local nTotalDamage = 0
    for key, value in pairs(conditionParam) do
        if key ~= "TotalCount" and trap_attack_damage[key] ~= nil then
            nTotalDamage = nTotalDamage + trap_attack_damage[key]
        end
    end

    if nTotalDamage >= conditionParam["TotalCount"] then
        return false
    else
        return true
    end
end

-- 打碎X个机关
function BonusCalcService:_CalSmashTrapCount(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local smash_trap_count = battleStateCmpt:GetSmashTrapCount() -- 获取玩家击碎机关数量 key:trapid value:击碎数量

    local bIsFinish = true
    for key, value in pairs(conditionParam) do
        if smash_trap_count[key] == nil or smash_trap_count[key] < value then -- 有一个不达标就返回
            bIsFinish = false
            break
        end
    end

    return bIsFinish
end

-- 总共打碎X个机关
function BonusCalcService:_CalSmashTrapTotalCount(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local smash_trap_count = battleStateCmpt:GetSmashTrapCount() -- 获取玩家击碎机关数量 key:trapid value:击碎数量

    local nTotalSmashCount = 0
    for key, value in pairs(conditionParam) do
        if key ~= "TotalCount" and smash_trap_count[key] ~= nil then
            nTotalSmashCount = nTotalSmashCount + smash_trap_count[key]
        end
    end
    if nTotalSmashCount >= conditionParam["TotalCount"] then
        return true
    else
        return false
    end
end

-- 一次连线普攻次数达到X
function BonusCalcService:_CalOnceMatchNorAttTimes(conditionParam)
    local nNorAttTimes = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local nOneChainNormalAttackCount = battleStateCmpt:GetOneChainNormalAttackCount()
    if nOneChainNormalAttackCount >= nNorAttTimes then
        return true
    end
    return false
end

--完成X次转色
function BonusCalcService:_CalColorSkillCount(conditionParam)
    local nColorSkillCount = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local nCmptColorSkillCount = battleStateCmpt:GetColorSkillCount()
    if nCmptColorSkillCount >= nColorSkillCount then
        return true
    end
    return false
end

function BonusCalcService:_CalAuroraTimeCount(conditionParam)
    local x = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local cnt = battleStateCmpt:GetAuroraTimeCount()
    if cnt >= x then
        return true
    end
    return false
end

function BonusCalcService:_CalPlayerBeHitCount(conditionParam)
    local x = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local cnt = battleStateCmpt:GetPlayerBeHitCount()
    if cnt < x then
        return true
    end
    return false
end

---@param param BonusConditionParam_KillMonstersInLimitedRound
function BonusCalcService:_CalKillMonstersInLimitedRound(conditionParam)
    local roundLimit = conditionParam.roundLimit
    local tBossID = conditionParam.tBossID

    local isAllMonsterKilled = true

    local globalMonsterGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(globalMonsterGroup) do
        if table.icontains(tBossID, e:MonsterID():GetMonsterID()) then
            isAllMonsterKilled = isAllMonsterKilled and e:HasDeadMark()
        end
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    --local isAllMonsterKilled = battleStatCmpt:GetLevelTotalRoundCount() <= roundLimit --[[MSG44740]]

    --<goto FINALIZE> at line 412 jumps into the scope of local 'curWaveDeadMonsterParam'
    local curWaveDeadMonsterParam = battleStatCmpt:GetCurWaveDeadMonsterParam()

    if not isAllMonsterKilled then
        goto FINALIZE
    end

    for _, param in ipairs(curWaveDeadMonsterParam) do
        if table.icontains(tBossID, param:GetMonsterID()) then
            isAllMonsterKilled = isAllMonsterKilled and param:GetDeadWave() <= roundLimit
        end
    end

    ::FINALIZE::
    return isAllMonsterKilled
end

---@param param BonusConditionParam_KillMonstersWithBuff
function BonusCalcService:_CalKillMonstersWithBuff(param)
    local requireCount = param.requireCount
    local tBossID = param.tBossID
    local tBuffID = param.tBuffID

    local count = 0

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local totalDeadMonsterBuffInfo = battleStatCmpt:GetTotalDeadMonsterBuffInfo()
    for _, monsterID in ipairs(tBossID) do
        if not totalDeadMonsterBuffInfo[monsterID] then goto MONSTER_ID_CONTINUE end

        local tBuffInfo = totalDeadMonsterBuffInfo[monsterID]
        if #tBuffInfo == 0 then goto MONSTER_ID_CONTINUE end
        for _, info in ipairs(tBuffInfo) do
            local union = table.union(tBuffID, info.buffIDs)
            if #union > 0 then
                count = count + 1
            end
        end

        ::MONSTER_ID_CONTINUE::
    end

    count = math.min(count, requireCount)

    return count >= requireCount, count, requireCount
end

function BonusCalcService:_CalCollectItems(param)
    local maxCollectCount = param.count
    local curCollectNum = self._world:BattleStat():GetDropCollectNumByItemID(param.id)
    return curCollectNum >= maxCollectCount, curCollectNum, maxCollectCount
end

function BonusCalcService:_CalChangeTeamLeaderTimes(param)
    local maxCount = param.count
    local count = self._world:BattleStat():GetTeamLeaderChangeNum()

    return count <= maxCount, count, maxCount
end
function BonusCalcService:_CalMonsterEscapeLessThan(param)
    local maxCount = param.count
    local count = self._world:BattleStat():GetMonsterEscapeNum()

    return count < maxCount, count, maxCount
end

function BonusCalcService:_CalHitBySkill(param)
    local skillID = param.skillID
    local requireCount = param.count

    local count = self._world:BattleStat():GetPlayerSkillHitCount(skillID)

    return count <= requireCount, count, requireCount
end

---
function BonusCalcService:_CalChessDeadPlayerPawnCount(param)
    local requireCount = param.count

    local count = self._world:BattleStat():GetChessDeadPlayerPawnCount()

    return count <= requireCount, count, requireCount
end

function BonusCalcService:CalPopStarNumber(param)
    local requireNum = tonumber(param[1])

    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    local curNum = popStarSvc:GetPopGridNum()

    return curNum >= requireNum, curNum, requireNum
end

function BonusCalcService:CalcBonusObjective()
    ---@type BonusCalcService
    local bonusCalcService = self._world:GetService("BonusCalc")
    local star3CalcService = self._world:GetService("Star3Calc")
    local conditionParser = ObjectiveConditionParamParser:New()
    local calcResultArray = {}

    local conditionIDArray = self._world.BW_WorldInfo.bonusCondition
    for _, conditionID in ipairs(conditionIDArray) do
        local conditionData = Cfg.cfg_threestarcondition[conditionID]
        if conditionData == nil then
            return
        end
        local conditionType = conditionData.ConditionType
        --local conditionParamArray = conditionData.ConditionNumber
        local conditionParamArray = star3CalcService:GetConditionNumber(conditionID)
        local conditionParam = conditionParser:ParseObjectiveConditionParam(conditionType, conditionParamArray)
        if conditionParam == nil then
            calcResultArray[#calcResultArray + 1] = conditionID
        else
            local matchRes = bonusCalcService:CalcCondition(conditionType, conditionParam)
            if matchRes == true then
                calcResultArray[#calcResultArray + 1] = conditionID
            end
        end
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetBonusMatchResult(calcResultArray)
end
