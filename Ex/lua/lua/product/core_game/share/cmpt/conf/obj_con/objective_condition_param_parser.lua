--[[------------------------------------------------------------------------------------------
    ObjectiveConditionParamParser : 目标条件参数解析器
]] --------------------------------------------------------------------------------------------

---@class ObjectiveConditionParamParser: Object
_class("ObjectiveConditionParamParser", Object)
ObjectiveConditionParamParser = ObjectiveConditionParamParser

function ObjectiveConditionParamParser:Constructor()
    ---注册所有解析类型
    self._conditionParamFuncDic = {}
    self._conditionParamFuncDic[BonusObjectiveType.NoAdditional] = self._ParseNoAdditianlParam
    self._conditionParamFuncDic[BonusObjectiveType.Health] = self._ParseHealthParam
    self._conditionParamFuncDic[BonusObjectiveType.LastWaveRoundNum] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.SuperChainCount] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.ActiveSkillCount] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.AllElementTeam] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.SelectElement] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.MatchNum] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.TrapAttackTimes] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.TrapAttackDammage] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.TrapAttackTotalTimes] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.TrapAttackTotalDamage] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.SmashTrapCount] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.SmashTrapTotalCount] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.TotalMatchPropertyNum] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.OnceMatchPropertyNum] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.OnceMatchNorAttTimes] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.ColorSkillCount] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.AuroraTimeCount] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.PlayerBeHitCount] = self._ParseMatchNumber
    self._conditionParamFuncDic[BonusObjectiveType.CompelHelpPet] = self._ParseParam_CompelHelpPet
    self._conditionParamFuncDic[BonusObjectiveType.ForbidHelpPet] = self._ParseParam_ForbidHelpPet
    self._conditionParamFuncDic[BonusObjectiveType.KillMonstersInLimitedRound] = self._ParseParam_KillMonstersInLimitedRound
    self._conditionParamFuncDic[BonusObjectiveType.KillMonstersWithBuff] = self._ParseParam_KillMonstersWithBuff
    self._conditionParamFuncDic[BonusObjectiveType.CollectItems] = self._ParseParam_CollectItems
    self._conditionParamFuncDic[BonusObjectiveType.UIChangeTeamLeaderCount] = self._ParseParam_UIChangeTeamLeaderCount
    self._conditionParamFuncDic[BonusObjectiveType.HitBySkill] = self._ParseParam_HitBySkill
    self._conditionParamFuncDic[BonusObjectiveType.ChessDeadPlayerPawnCount] = self._ParseParam_ChessDeadPlayerPawnCount
    self._conditionParamFuncDic[BonusObjectiveType.MonsterEscapeLessThan] = self._ParseParam_MonsterEscapeLessThan
    self._conditionParamFuncDic[BonusObjectiveType.PopStarNumber] = self._ParseMatchNumber
end

---解析条件参数
function ObjectiveConditionParamParser:ParseObjectiveConditionParam(conditionType, conditionParam)
    local parseFunc = self._conditionParamFuncDic[conditionType]
    local bonusConditionParamData = nil
    if parseFunc ~= nil then
        bonusConditionParamData = parseFunc(self, conditionParam)
    else
        Log.fatal("parse bonus obj Func is null,effect", conditionType)
    end

    return bonusConditionParamData
end

function ObjectiveConditionParamParser:_ParseNoAdditianlParam(conditionParam)
    return conditionParam
end

function ObjectiveConditionParamParser:_ParseHealthParam(conditionParam)
    local percent = tonumber(conditionParam[1])
    return percent
end
function ObjectiveConditionParamParser:_ParseMatchNumber(conditionParam)
    return conditionParam
end

function ObjectiveConditionParamParser:_ParseParam_CompelHelpPet(conditionParam)
    return conditionParam
end

function ObjectiveConditionParamParser:_ParseParam_ForbidHelpPet(conditionParam)
    return conditionParam
end

---@class BonusConditionParam_KillMonstersInLimitedRound
---@field roundLimit number
---@field tBossID number[]

---@return BonusConditionParam_KillMonstersInLimitedRound
function ObjectiveConditionParamParser:_ParseParam_KillMonstersInLimitedRound(conditionParam)
    local roundLimit = tonumber(conditionParam[1])
    local splitBossID = string.split(conditionParam[2], ',')
    local tBossID = {}
    for _, bossID in ipairs(splitBossID) do
        local n = tonumber(bossID)
        if not n then
            goto BOSS_ID_CONTINUE
        end

        table.insert(tBossID, n)
        ::BOSS_ID_CONTINUE::
    end

    return {
        roundLimit = roundLimit,
        tBossID = tBossID
    }
end

---@class BonusConditionParam_KillMonstersWithBuff
---@field requireCount number
---@field tBossID number[]
---@field tBuffID number[]

---@return BonusConditionParam_KillMonstersWithBuff
function ObjectiveConditionParamParser:_ParseParam_KillMonstersWithBuff(conditionParam)
    local requireCount = tonumber(conditionParam[1])
    local splitBossID = string.split(conditionParam[2], ',')
    local splitbuffID = string.split(conditionParam[3], ',')

    local tBossID = {}
    for _, bossID in ipairs(splitBossID) do
        local n = tonumber(bossID)
        if not n then
            goto BOSS_ID_CONTINUE
        end

        table.insert(tBossID, n)
        ::BOSS_ID_CONTINUE::
    end

    local tBuffID = {}
    for _, buffID in ipairs(splitbuffID) do
        local n = tonumber(buffID)
        if not n then
            goto BUFF_ID_CONTINUE
        end

        table.insert(tBuffID, n)
        ::BUFF_ID_CONTINUE::
    end

    return {
        requireCount = requireCount, 
        tBossID = tBossID, 
        tBuffID = tBuffID
    }
end

function ObjectiveConditionParamParser:_ParseParam_CollectItems(conditionParam)
    local id = tonumber(conditionParam[1])
    local count = tonumber(conditionParam[2])

    return {
        id = id,
        count = count
    }
end

function ObjectiveConditionParamParser:_ParseParam_UIChangeTeamLeaderCount(conditionParam)
    local count = tonumber(conditionParam[1])

    return {
        count = count
    }
end

function ObjectiveConditionParamParser:_ParseParam_HitBySkill(conditionParam)
    local count = tonumber(conditionParam[1])
    local skillID = tonumber(conditionParam[2])

    return {
        count = count,
        skillID = skillID
    }
end

---
function ObjectiveConditionParamParser:_ParseParam_ChessDeadPlayerPawnCount(conditionParam)
    local count = tonumber(conditionParam[1])

    return {
        count = count,
    }
end

function ObjectiveConditionParamParser:_ParseParam_MonsterEscapeLessThan(conditionParam)
    local count = tonumber(conditionParam[1])

    return {
        count = count,
    }
end