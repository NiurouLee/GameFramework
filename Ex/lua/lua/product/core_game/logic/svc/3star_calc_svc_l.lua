--[[------------------------------------------------------------------------------------------
    Star3CalcService 三星条件计算服务
]] --------------------------------------------------------------------------------------------
require("base_service")

---@class Star3CalcService:BaseService
_class("Star3CalcService", BaseService)
Star3CalcService = Star3CalcService

function Star3CalcService:Constructor(world)
    --三星条件配置
    self._3star_config = Cfg.cfg_threestarcondition

    -- 特殊配置表
    self._trap_special_condition = {} -- eg: 被Y机关攻击次数少于X 123213,13|12314,16 13213,1251,1234|5
    self._trap_special_total_count_condition = {}

    -- 还有以下两种形式
    for index, value in ipairs(self._3star_config) do
        if self:IsSpecialCondition(value.ConditionType) then
            self._trap_special_condition[index] = self:GetSpecialConditionData(value.ConditionNumber)
        elseif self:IsSpecialTotalCountCondition(value.ConditionType) then
            self._trap_special_total_count_condition[index] = self:GetSpecialConditionTotalData(value.ConditionNumber)
        end
    end

    self._3starProgressCalcFuncDic = {}
    ---注册计算器 --统一返回格式为"(已完成数/总数)"字符串
    self._3starProgressCalcFuncDic[BonusObjectiveType.NoAdditional] = self._CalcComplete
    self._3starProgressCalcFuncDic[BonusObjectiveType.Health] = self._CalcHealth
    self._3starProgressCalcFuncDic[BonusObjectiveType.LastWaveRoundNum] = self._CalcComplete
    self._3starProgressCalcFuncDic[BonusObjectiveType.SuperChainCount] = self._CalcSuperChainCount
    self._3starProgressCalcFuncDic[BonusObjectiveType.ActiveSkillCount] = self._CalcActiveSkillCount
    self._3starProgressCalcFuncDic[BonusObjectiveType.AllElementTeam] = self._CalcAllElementTeam
    self._3starProgressCalcFuncDic[BonusObjectiveType.SelectElement] = self._CalcSelectElement
    self._3starProgressCalcFuncDic[BonusObjectiveType.MatchNum] = self._CalcMatchNum
    self._3starProgressCalcFuncDic[BonusObjectiveType.TrapAttackTimes] = self._CalcTrapAttackTimes
    self._3starProgressCalcFuncDic[BonusObjectiveType.TrapAttackDammage] = self._CalcTrapAttackDamage
    self._3starProgressCalcFuncDic[BonusObjectiveType.TrapAttackTotalTimes] = self._CalcTrapAttackTotalTimes
    self._3starProgressCalcFuncDic[BonusObjectiveType.TrapAttackTotalDamage] = self._CalTrapAttackTotalDamage
    self._3starProgressCalcFuncDic[BonusObjectiveType.SmashTrapCount] = self._CalSmashTrapCount
    self._3starProgressCalcFuncDic[BonusObjectiveType.SmashTrapTotalCount] = self._CalSmashTrapTotalCount
    self._3starProgressCalcFuncDic[BonusObjectiveType.TotalMatchPropertyNum] = self._CalTotalMatchPropertyNum
    self._3starProgressCalcFuncDic[BonusObjectiveType.OnceMatchPropertyNum] = self._CalOnceMatchPropertyNum
    self._3starProgressCalcFuncDic[BonusObjectiveType.OnceMatchNorAttTimes] = self._CalOnceMatchNorAttTimes
    self._3starProgressCalcFuncDic[BonusObjectiveType.ColorSkillCount] = self._CalColorSkillCount
    self._3starProgressCalcFuncDic[BonusObjectiveType.AuroraTimeCount] = self._CalAuroraTimeCount
    self._3starProgressCalcFuncDic[BonusObjectiveType.PlayerBeHitCount] = self._CalPlayerBeHitCount
    self._3starProgressCalcFuncDic[BonusObjectiveType.CompelHelpPet] = self._CalCompelHelpPet
    self._3starProgressCalcFuncDic[BonusObjectiveType.ForbidHelpPet] = self._CalForbidHelpPet
    self._3starProgressCalcFuncDic[BonusObjectiveType.KillMonstersInLimitedRound] = self._CalKillMonstersInLimitedRound
    self._3starProgressCalcFuncDic[BonusObjectiveType.KillMonstersWithBuff] = self._CalKillMonstersWithBuff
    self._3starProgressCalcFuncDic[BonusObjectiveType.CollectItems] = self._CalCollectItems
    self._3starProgressCalcFuncDic[BonusObjectiveType.UIChangeTeamLeaderCount] = self._CalChangeTeamLeaderTimes
    self._3starProgressCalcFuncDic[BonusObjectiveType.MonsterEscapeLessThan] = self._CalMonsterEscapeLessThan
    self._3starProgressCalcFuncDic[BonusObjectiveType.PopStarNumber] = self._CalPopStarNumber
end

function Star3CalcService:IsSpecialCondition(eConditionType)
    if
        eConditionType == BonusObjectiveType.TrapAttackTimes or eConditionType == BonusObjectiveType.TrapAttackDammage or
            eConditionType == BonusObjectiveType.SmashTrapCount
     then
        return true
    else
        return false
    end
end

function Star3CalcService:IsSpecialTotalCountCondition(eConditionType)
    if
        eConditionType == BonusObjectiveType.TrapAttackTotalTimes or
            eConditionType == BonusObjectiveType.TrapAttackTotalDamage or
            eConditionType == BonusObjectiveType.SmashTrapTotalCount
     then
        return true
    else
        return false
    end
end

function Star3CalcService:GetConditionNumber(conditionId)
    local value = self._3star_config[conditionId]
    if self:IsSpecialCondition(value.ConditionType) then
        return self._trap_special_condition[conditionId]
    end
    if self:IsSpecialTotalCountCondition(value.ConditionType) then
        return self._trap_special_total_count_condition[conditionId]
    end
    return value.ConditionNumber
end

function Star3CalcService:BeZeroProgress(conditionId)
    local conditionData = self._3star_config[conditionId]
    if conditionData == nil then
        Log.fatal("No config when BeZeroProgress id:", conditionId)
        return ""
    end
    local conditionType = conditionData.ConditionType
    if conditionType == BonusObjectiveType.Health then
        return "(0/1)"
    elseif conditionType == BonusObjectiveType.NoAdditional then
        return ""
    elseif self:IsSpecialCondition(conditionType) then
        return "(0/" .. tostring(#self._trap_special_condition[conditionId]) .. ")"
    elseif self:IsSpecialTotalCountCondition(conditionType) then
        return "(0/" .. tostring(self._trap_special_total_count_condition[conditionId].TotalCount) .. ")"
    elseif conditionType == BonusObjectiveType.SelectElement then
        return "(0/" .. conditionData.ConditionNumber[1] .. ")"
    elseif conditionType == BonusObjectiveType.KillMonstersInLimitedRound then
        return table.concat({"(0/", tostring(conditionData.ConditionNumber[1]), ")"})
    elseif conditionType == BonusObjectiveType.KillMonstersWithBuff then
        return table.concat({"(0/", tostring(conditionData.ConditionNumber[1]), ")"})
    elseif conditionType == BonusObjectiveType.HitBySkill then
        return table.concat({"(0/", tostring(conditionData.ConditionNumber[1]), ")"})
    end
    local conditionParam = conditionData.ConditionNumber[#conditionData.ConditionNumber]

    return "(0/" .. conditionParam .. ")"
end

function Star3CalcService:CalcProgress(conditionId)
    local conditionData = self._3star_config[conditionId]
    if conditionData == nil then
        Log.fatal("No config when CalcProgress id:", conditionId)
        return ""
    end
    local conditionType = conditionData.ConditionType
    local calcFunc = self._3starProgressCalcFuncDic[conditionType]
    if calcFunc ~= nil then
        local conditionParam = conditionData.ConditionNumber
        if self:IsSpecialCondition(conditionType) then
            conditionParam = self._trap_special_condition[conditionId]
        elseif self:IsSpecialTotalCountCondition(conditionType) then
            conditionParam = self._trap_special_total_count_condition[conditionId]
        end
        return calcFunc(self, conditionParam)
    else
        Log.fatal("No bonus calculator", conditionType)
    end
    return ""
end

function Star3CalcService:AutoTestCalcProgress(conditionType, conditionParam)
    local calcFunc = self._3starProgressCalcFuncDic[conditionType]
    return calcFunc(self, conditionParam)
end

---是否完成关卡
function Star3CalcService:_CalcComplete(conditionParam)
    return ""
end

function Star3CalcService:_CalCompelHelpPet(conditionParam)
    return ""
end
function Star3CalcService:_CalForbidHelpPet(conditionParam)
    return ""
end
---检查血量
function Star3CalcService:_CalcHealth(conditionParam)
    local hpNumerator = tonumber(conditionParam[1])
    local targetPercent = hpNumerator / 100
    local playerEntity = self._world:Player():GetLocalTeamEntity()
    ---@type AttributesComponent
    local attrCmpt = playerEntity:Attributes()

    local curHp = attrCmpt:GetCurrentHP()
    local maxHp = attrCmpt:CalcMaxHp()

    local curPercent = curHp / maxHp
    if curPercent >= targetPercent then
        return "(1/1)"
    else
        return "(0/1)"
    end
end

---超级连锁数
function Star3CalcService:_CalcSuperChainCount(conditionParam)
    local superChainCount = tonumber(conditionParam[1])
    local curSuperChainCount = self:_GetBattleStatComponent():GetSuperChainCount()
    if curSuperChainCount <= superChainCount then
        return "(" .. curSuperChainCount .. "/" .. superChainCount .. ")"
    else
        return "(" .. superChainCount .. "/" .. superChainCount .. ")"
    end
end

---主动技释放数
function Star3CalcService:_CalcActiveSkillCount(conditionParam)
    local activeSkillCount = tonumber(conditionParam[1])
    local curActiveSkillCount = self:_GetBattleStatComponent():GetActiveSkillCount()
    if activeSkillCount == 0 then
        if curActiveSkillCount == 0 then
            return "(1/1)"
        else
            return "(0/1)"
        end
    else
        if curActiveSkillCount <= activeSkillCount then
            return "(" .. curActiveSkillCount .. "/" .. activeSkillCount .. ")"
        else
            return "(" .. activeSkillCount .. "/" .. activeSkillCount .. ")"
        end
    end
end

---是否全属性出战
function Star3CalcService:_CalcAllElementTeam(conditionParam)
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
        return "(0/1)"
    end

    local hasRed = table.icontains(teamElement, ElementType.ElementType_Red)
    if not hasRed then
        return "(0/1)"
    end

    local hasGreen = table.icontains(teamElement, ElementType.ElementType_Green)
    if not hasGreen then
        return "(0/1)"
    end

    local hasYellow = table.icontains(teamElement, ElementType.ElementType_Yellow)
    if not hasYellow then
        return "(0/1)"
    end

    return "(1/1)"
end

---有N个M属性的成员出战
function Star3CalcService:_CalcSelectElement(conditionParam)
    local memCount = tonumber(conditionParam[1])
    local memElement = tonumber(conditionParam[2])

    local curCount = 0

    ---@type JoinedPlayerInfo
    local joinedPlayerInfo = self._world.BW_WorldInfo.localPlayerInfo
    for petIndex, petinfo in ipairs(joinedPlayerInfo.pet_list) do
        local petPstID = petinfo.pet_pstid
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        local elementType = petData:GetPetFirstElement()
        if elementType == memElement then
            curCount = curCount + 1
        end
    end
    if curCount <= memCount then
        return "(" .. curCount .. "/" .. memCount .. ")"
    else
        return "(" .. memCount .. "/" .. memCount .. ")"
    end
end

---消除格子
function Star3CalcService:_CalcMatchNum(conditionParam)
    local matchType = tonumber(conditionParam[1])
    local matchParam = tonumber(conditionParam[2])
    ---@type BattleStatComponent
    local battleStateCmpt = self:_GetBattleStatComponent()
    if matchType == 1 then --单次连线消除X个格子
        local oneMatchNum = battleStateCmpt:GetOneMatchMaxNum()
        if oneMatchNum <= matchParam then
            return "(" .. oneMatchNum .. "/" .. matchParam .. ")"
        else
            return "(" .. matchParam .. "/" .. matchParam .. ")"
        end
    elseif matchType == 2 then --单局消除X个格子
        local totalMatchNum = battleStateCmpt:GetTotalMatchNum()
        if totalMatchNum <= matchParam then
            return "(" .. totalMatchNum .. "/" .. matchParam .. ")"
        else
            return "(" .. matchParam .. "/" .. matchParam .. ")"
        end
    elseif matchType == 3 then --单局消除X个同色格子
        local elementMatchArray = battleStateCmpt:GetElementMatchNum()
        for index, value in ipairs(elementMatchArray) do
            if value ~= 0 then
                if value <= matchParam then
                    return "(" .. value .. "/" .. matchParam .. ")"
                else
                    return "(" .. matchParam .. "/" .. matchParam .. ")"
                end
            end
        end
    end
end

-- 累计消除Y个X属性格子
function Star3CalcService:_CalTotalMatchPropertyNum(conditionParam)
    local l_PieceType = tonumber(conditionParam[1])
    local l_MatchNum = tonumber(conditionParam[2])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local elementMatchArray = battleStateCmpt:GetElementMatchNum()
    local l_value = elementMatchArray[l_PieceType]
    if l_value ~= nil and l_value > 0 then
        if l_value > l_MatchNum then
            l_value = l_MatchNum
        end
        return "(" .. tostring(l_value) .. "/" .. tostring(l_MatchNum) .. ")"
    end
    return "(0/" .. tostring(l_MatchNum) .. ")"
end

-- 一次性消除Y个X属性格子
function Star3CalcService:_CalOnceMatchPropertyNum(conditionParam)
    local l_PieceType = tonumber(conditionParam[1])
    local l_MatchNum = tonumber(conditionParam[2])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local battleState_type = battleStateCmpt:GetOneMatchMaxNumType()
    local battleState_MatChNum = battleStateCmpt:GetOneMatchMaxNum()

    if battleState_MatChNum > 0 and battleState_type == l_PieceType then
        if battleState_MatChNum > l_MatchNum then
            battleState_MatChNum = l_MatchNum
        end
        return "(" .. tostring(battleState_MatChNum) .. "/" .. tostring(l_MatchNum) .. ")"
    end
    return "(0/" .. tostring(l_MatchNum) .. ")"
end

-- 被Y机关攻击次数少于X
function Star3CalcService:_CalcTrapAttackTimes(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_times = battleStateCmpt:GetTakeAttackTimesByTrap() -- 获取玩家被机关攻击次数 key:trapid value:被打次数

    local nCondCount = 0 --
    -- 判断是否都达成
    for key, value in pairs(conditionParam) do
        if trap_attack_times[key] ~= nil and trap_attack_times[key] >= value then -- 没被该trap打过 或者 挨打次数比配置的挨打次数少
            nCondCount = nCondCount + 1
        end
    end

    return "(" .. tostring(nCondCount) .. "/" .. tostring(#conditionParam) .. ")"
end

-- 被Y机关攻击伤害少于X
function Star3CalcService:_CalcTrapAttackDamage(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_damage = battleStateCmpt:GetTakeAttackDamageByTrap()

    local nCondCount = 0
    for key, value in pairs(conditionParam) do
        if trap_attack_damage[key] ~= nil and trap_attack_damage[key] >= value then
            nCondCount = nCondCount + 1
        end
    end

    return "(" .. tostring(nCondCount) .. "/" .. tostring(#conditionParam) .. ")"
end

-- 被Y机关攻击总次数少于X
function Star3CalcService:_CalcTrapAttackTotalTimes(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_times = battleStateCmpt:GetTakeAttackTimesByTrap() -- 获取玩家被机关攻击次数 key:trapid value:被打次数

    local nCondCount = 0 --
    -- 判断是否达成
    for key, value in pairs(conditionParam) do
        if key ~= "TotalCount" and trap_attack_times[key] ~= nil then
            nCondCount = nCondCount + trap_attack_times[key]
        end
    end

    return "(" .. tostring(nCondCount) .. "/" .. tostring(conditionParam["TotalCount"]) .. ")"
end

-- 被Y机关攻击总伤害少于X
function Star3CalcService:_CalTrapAttackTotalDamage(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local trap_attack_damage = battleStateCmpt:GetTakeAttackDamageByTrap()

    local nTotalDamage = 0
    for key, value in pairs(conditionParam) do
        if key ~= "TotalCount" and trap_attack_damage[key] ~= nil then
            nTotalDamage = nTotalDamage + trap_attack_damage[key]
        end
    end

    return "(" .. tostring(nTotalDamage) .. "/" .. tostring(conditionParam["TotalCount"]) .. ")"
end

-- 打碎X个机关
function Star3CalcService:_CalSmashTrapCount(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local smash_trap_count = battleStateCmpt:GetSmashTrapCount() -- 获取玩家击碎机关数量 key:trapid value:击碎数量

    local nCondCount = 0
    for key, value in pairs(conditionParam) do
        if smash_trap_count[key] ~= nil and smash_trap_count[key] >= value then
            nCondCount = nCondCount + 1
        end
    end

    return "(" .. tostring(nCondCount) .. "/" .. tostring(#conditionParam) .. ")"
end

-- 总共打碎X个机关
function Star3CalcService:_CalSmashTrapTotalCount(conditionParam)
    local battleStateCmpt = self:_GetBattleStatComponent()
    local smash_trap_count = battleStateCmpt:GetSmashTrapCount() -- 获取玩家击碎机关数量 key:trapid value:击碎数量

    local nTotalSmashCount = 0
    for key, value in pairs(conditionParam) do
        if key ~= "TotalCount" and smash_trap_count[key] ~= nil then
            nTotalSmashCount = nTotalSmashCount + smash_trap_count[key]
        end
    end

    return "(" .. tostring(nTotalSmashCount) .. "/" .. tostring(conditionParam["TotalCount"]) .. ")"
end

-- 一次连线普攻次数达到X
function Star3CalcService:_CalOnceMatchNorAttTimes(conditionParam)
    local nNorAttTimes = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local nOneChainNormalAttackCount = battleStateCmpt:GetOneChainNormalAttackCount()
    if nOneChainNormalAttackCount > nNorAttTimes then
        nOneChainNormalAttackCount = nNorAttTimes
    end
    return "(" .. tostring(nOneChainNormalAttackCount) .. "/" .. tostring(nNorAttTimes) .. ")"
end

--完成X次转色
function Star3CalcService:_CalColorSkillCount(conditionParam)
    local nColorSkillCount = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local nCmptColorSkillCount = battleStateCmpt:GetColorSkillCount()
    if nCmptColorSkillCount > nColorSkillCount then
        nCmptColorSkillCount = nColorSkillCount
    end
    return "(" .. tostring(nCmptColorSkillCount) .. "/" .. tostring(nColorSkillCount) .. ")"
end

function Star3CalcService:_CalAuroraTimeCount(conditionParam)
    local x = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local cnt = battleStateCmpt:GetAuroraTimeCount()
    if cnt > x then
        cnt = x
    end
    return "(" .. tostring(cnt) .. "/" .. tostring(x) .. ")"
end

function Star3CalcService:_CalPlayerBeHitCount(conditionParam)
    local x = tonumber(conditionParam[1])
    local battleStateCmpt = self:_GetBattleStatComponent()
    local cnt = battleStateCmpt:GetPlayerBeHitCount()
    if cnt > x then
        cnt = x
    end
    return "(" .. tostring(cnt) .. "/" .. tostring(x) .. ")"
end

function Star3CalcService:_CalKillMonstersInLimitedRound(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    ---@type BonusConditionParam_KillMonstersInLimitedRound
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.KillMonstersInLimitedRound, conditionParam)

    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local result = bonusCalcSvc:_CalKillMonstersInLimitedRound(param)

    return result and "(1/1)" or "(0/1)"
end

function Star3CalcService:_CalKillMonstersWithBuff(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.KillMonstersWithBuff, conditionParam)

    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local _isPass, count, requireCount = bonusCalcSvc:_CalKillMonstersWithBuff(param)

    return table.concat({"(", count, "/", requireCount, ")"})
end

function Star3CalcService:_CalCollectItems(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.CollectItems, conditionParam)

    ---@type BonusCalcService
    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local _isPass, count, requireCount = bonusCalcSvc:_CalCollectItems(param)

    return table.concat({"(", count, "/", requireCount, ")"})
end

function Star3CalcService:_CalChangeTeamLeaderTimes(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.UIChangeTeamLeaderCount, conditionParam)

    ---@type BonusCalcService
    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local _isPass, count, requireCount = bonusCalcSvc:_CalChangeTeamLeaderTimes(param)

    return table.concat({"(", count, "/", requireCount, ")"})
end
function Star3CalcService:_CalMonsterEscapeLessThan(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.MonsterEscapeLessThan, conditionParam)

    ---@type BonusCalcService
    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local isPass, count, maxCount = bonusCalcSvc:_CalMonsterEscapeLessThan(param)
    if count > maxCount then
        count = maxCount
    end
    return table.concat({"(", count, "/", maxCount, ")"})
end
---
function Star3CalcService:_CalChessDeadPlayerPawnCount(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.ChessDeadPlayerPawnCount, conditionParam)

    ---@type BonusCalcService
    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local _isPass, count, requireCount = bonusCalcSvc:_CalChessDeadPlayerPawnCount(param)

    return table.concat({ "(", count, "/", requireCount, ")" })
end

function Star3CalcService:_CalHitBySkill(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.HitBySkill, conditionParam)

    ---@type BonusCalcService
    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local _isPass, count, requireCount = bonusCalcSvc:_CalHitBySkill(param)

    return table.concat({"(", count, "/", requireCount, ")"})
end

function Star3CalcService:_CalPopStarNumber(conditionParam)
    local parser = ObjectiveConditionParamParser:New()
    local param = parser:ParseObjectiveConditionParam(BonusObjectiveType.PopStarNumber, conditionParam)

    ---@type BonusCalcService
    local bonusCalcSvc = self._world:GetService("BonusCalc")
    local isPass, count, requireCount = bonusCalcSvc:CalPopStarNumber(param)

    return table.concat({ "(", count, "/", requireCount, ")" })
end

-- 获取多个实体攻击数据
function Star3CalcService:GetSpecialConditionData(conditionData)
    local arrTrapCond = {}
    -- local nTotalCount = 0
    for _, value in ipairs(conditionData) do
        local TrapCond = table.tonumber(string.split(value, ","))
        if table.count(TrapCond) == 2 then
            arrTrapCond[TrapCond[1]] = TrapCond[2]
        -- nTotalCount = nTotalCount + TrapCond[2]
        end
    end
    return arrTrapCond -- , nTotalCount
end

-- 获取多个实体攻击总数数据
function Star3CalcService:GetSpecialConditionTotalData(conditionData)
    local arrTrapCond = {}
    if table.count(conditionData) ~= 2 then
        return arrTrapCond
    end
    local TrapArray = table.tonumber(string.split(conditionData[1], ","))
    for _, value in ipairs(TrapArray) do
        arrTrapCond[value] = true
    end
    arrTrapCond["TotalCount"] = tonumber(conditionData[2])
    return arrTrapCond
end

function Star3CalcService:Calc3StarProgress()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Mission then
        local threeStarConditions = self._configService:GetMission3StarCondition(self._world.BW_WorldInfo.missionID)
        ---获取三星进度计算服务Star3CalcService
        ---@type Star3CalcService
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:CalcProgress(conditionId)
            battleStatCmpt:UpdateA3StarProgress(conditionId, ret)
        end
    elseif self._world.BW_WorldInfo.matchType == MatchType.MT_Campaign then
        local threeStarConditions = self._configService:GetCampaignMission3StarCondition(self._world.BW_WorldInfo.missionID)
        ---获取三星进度计算服务Star3CalcService
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:CalcProgress(conditionId)
            battleStatCmpt:UpdateA3StarProgress(conditionId, ret)
        end
    elseif self._world.BW_WorldInfo.matchType == MatchType.MT_ExtMission then
        local threeStarConditions =
            self._configService:GetExtMission3StarCondition(self._world.BW_WorldInfo.ext_mission_task_id)
        ---获取三星进度计算服务Star3CalcService
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:CalcProgress(conditionId)
            battleStatCmpt:UpdateA3StarProgress(conditionId, ret)
        end
    elseif self._world.BW_WorldInfo.matchType == MatchType.MT_Season then
        local threeStarConditions = self._configService:GetSeasonMission3StarCondition(self._world.BW_WorldInfo.missionID)
        ---获取三星进度计算服务Star3CalcService
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:CalcProgress(conditionId)
            battleStatCmpt:UpdateA3StarProgress(conditionId, ret)
        end
    end
end
