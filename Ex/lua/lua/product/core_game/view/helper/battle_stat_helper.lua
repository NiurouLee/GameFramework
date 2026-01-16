--[[------------------------------------------------------------------------------------------
    BattleStateHelper : 用来给局内UI层访问逻辑层统计数据的静态类。
    UI层关心的是数据形式，不关心数据在逻辑层的组织形式，这一层用来隔离UI和逻辑
    不要在局内逻辑层使用此对象，否则服务端会报错！！
]] --------------------------------------------------------------------------------------------

---@class BattleStatHelper: Object
_class("BattleStatHelper", Object)
BattleStatHelper = BattleStatHelper

---@return BattleStatComponent
function BattleStatHelper._GetBattleStatComponent()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    if not mainWorld then
        return
    end
    return mainWorld:BattleStat()
end

function BattleStatHelper._GetMainWorld()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    return mainWorld
end

function BattleStatHelper.Get3StarProgress(conditionId)
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    return statCmpt:Get3StarProgress(conditionId)
end

function BattleStatHelper.GetBonusMatchResult()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    return statCmpt:GetBonusMatchResult()
end

function BattleStatHelper.GetDropCollectNum()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    return statCmpt:GetDropCollectNum()
end

function BattleStatHelper.IsAssignWaveLevel()
    local l_mainworld = BattleStatHelper._GetMainWorld()
    local configService = l_mainworld:GetService("Config")
    ---@type BattleStatComponent
    local statCmpt = l_mainworld:BattleStat()

    if configService then
        local levelConfigData = configService:GetLevelConfigData()
        local levelCompleteConditionType = levelConfigData:GetLevelCompleteConditionType()
        if levelCompleteConditionType == CompleteConditionType.AssignWaveAndRandomNextWave then -- 如果是指定波次结束关卡需要特殊处理
            local l_arrAssignWaveParams = levelConfigData:GetLevelCompleteConditionParams()[1]
            local l_nAssignWave = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.AssignWaveEnd]
            if l_nAssignWave ~= nil then
                return true, l_nAssignWave
            end
        end
    end

    return false, statCmpt:GetTotalWaveCount()
end

function BattleStatHelper.GetCurWaveIndex()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    local nCurWave = statCmpt:GetCurWaveIndex()

    local isAssignLevel, nTotalWaveCount = BattleStatHelper.IsAssignWaveLevel()
    if isAssignLevel and nCurWave > nTotalWaveCount then
        return nTotalWaveCount
    else
        return nCurWave
    end
end

function BattleStatHelper.GetTotalWaveCount()
    local isAssignLevel, nTotalWaveCount = BattleStatHelper.IsAssignWaveLevel()
    return nTotalWaveCount
end

function BattleStatHelper.GetTotalDropCoin()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    local coinCount = statCmpt:GetDropRoleAssetNoDouble(RoleAssetID.RoleAssetGold)
    return coinCount
end

function BattleStatHelper.GetTotalDropMazeCoin()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    local coinCount = statCmpt:GetDropRoleAsset(RoleAssetID.RoleAssetMazeCoin)
    return coinCount
end

---@return number
---获取关卡内累计的回合数
function BattleStatHelper.GetLevelTotalRoundCount()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    return statCmpt:GetLevelTotalRoundCount()
end

function BattleStatHelper.CalcBonusObjective()
    ---@type MainWorld
    local mainWorld = BattleStatHelper._GetMainWorld()
    if not mainWorld then
        return
    end
    ---@type BonusCalcService
    local bonusService = mainWorld:GetService("BonusCalc")
    bonusService:CalcBonusObjective()
end

function BattleStatHelper.GetAutoFightStat()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    if not statCmpt then
        return false
    end
    return statCmpt:GetAutoFight()
end

function BattleStatHelper.GetHandleShumolHPUI()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    if not statCmpt then
        return false
    end
    return statCmpt:GetHandleShumolHPUI()
end

----@return number
function BattleStatHelper.GetDeadMonsterCount()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    if statCmpt then
        local deadMonsterList = statCmpt:GetCurWaveDeadMonsterIDList()
        return table.count(deadMonsterList)
    end
end

function BattleStatHelper.GetBattleWaveResult()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    if statCmpt then
        return statCmpt:GetBattleWaveResult()
    end
end

function BattleStatHelper.GetRoundBeginPlayerPos()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    if statCmpt then
        return statCmpt:GetRoundBeginPlayerPos()
    end
end

function BattleStatHelper.CheckActiveSkillCastCondition(petPstID, skillID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    return utilData:CheckActiveSkillCastCondition(petPstID, skillID)
end

function BattleStatHelper.IsSkillDisabledWhenCasterIsTeamLeader(petPstID, skillID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    return utilData:IsSkillDisabledWhenCasterIsTeamLeader(petPstID, skillID)
end

function BattleStatHelper.IsPetCurrentTeamLeader(petPstID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    return utilData:IsPetCurrentTeamLeader(petPstID)
end

function BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(petPstID, skillID)
    if (BattleStatHelper.IsPetCurrentTeamLeader(petPstID) and
        BattleStatHelper.IsSkillDisabledWhenCasterIsTeamLeader(petPstID, skillID))
    then
        return false
    end
    return true
end

function BattleStatHelper.CheckCanCastActiveSkill_SwapPetTeamOrder(petPstID, skillID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    return utilData:CheckCanCastActiveSkillBySwapPetTeamOrder(petPstID, skillID)
end

---Get Logic Current LogicTeam Order => GetLogicCurrentLocalTeamOrder
function BattleStatHelper.GetLogicCurrentLocalTeamOrder()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()

    local eTeam = mainWorld:Player():GetLocalTeamEntity()
    return eTeam:Team():CloneTeamOrder()
end

function BattleStatHelper.GetCurRoundDoActiveSkillTimes(petPstID)
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    return statCmpt:GetCurRoundDoActiveSkillTimes(petPstID)
end

function BattleStatHelper.GetLevelOutOfRoundType()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type ConfigService
    local configService = mainWorld:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    return levelConfigData:GetOutOfRoundType()
end

function BattleStatHelper.GetOutOfRoundPunishHPPercent(preview)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type BattleStatComponent
    local battleStatCmpt = mainWorld:BattleStat()
    local punishmentRoundCount = battleStatCmpt:GetCurWavePunishmentRoundCount()
    if preview then
        punishmentRoundCount = punishmentRoundCount + 1
    end
    local punishPercent = 0
    for round, percent in pairs(BattleConst.PunishmentRoundHPPercent) do
        if round <= punishmentRoundCount then
            punishPercent = percent
        end
    end
    return punishPercent
end

function BattleStatHelper.GetPreviousReadyRoundCount(petPstID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    return utilData:GetPreviousReadyRoundCount(petPstID)
end

---设置波次结束时选择的圣物
-- ---@param relicID number 圣物ID
-- function BattleStatHelper.SetWaveChooseRelic(relicID)
--     ---@type BattleStatComponent
--     local statCmpt = BattleStatHelper._GetBattleStatComponent()

--     local waveIndex = statCmpt:GetCurWaveIndex()
--     statCmpt:SetWaveChooseRelic(waveIndex, relicID)
-- end

-- ---@param relicID number 圣物ID
-- function BattleStatHelper.SetChooseRelic(relicID)
--     ---@type BattleStatComponent
--     local statCmpt = BattleStatHelper._GetBattleStatComponent()
--     statCmpt:SetChooseRelic(relicID)

--     local mainWorld = BattleStatHelper._GetMainWorld()
--     if not mainWorld then
--         return
--     end
--     ---@type TalentService
--     local talentSvc = mainWorld:GetService("Talent")
--     ---@type TalentComponent
--     local talentCmpt = talentSvc:GetTalentComponent()
--     talentCmpt:SetIsChosenOpeningRelic(true)
-- end

function BattleStatHelper.GetAllMiniMazeRelic()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    return statCmpt:GetAllMiniMazeRelicList()
end

function BattleStatHelper.GetWaveChooseRelic()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()

    local waveIndex = statCmpt:GetCurWaveIndex()
    return statCmpt:GetWaveChooseRelic(waveIndex)
end

-- ---设置波次结束时选择的伙伴
-- ---@param partner number 伙伴ID
-- function BattleStatHelper.SetWaveChoosePartner(partner)
--     ---@type BattleStatComponent
--     local statCmpt = BattleStatHelper._GetBattleStatComponent()

--     local waveIndex = statCmpt:GetCurWaveIndex()
--     statCmpt:SetWaveChoosePartner(waveIndex, partner)
-- end

function BattleStatHelper.GetWaveChoosePartner()
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()

    local waveIndex = statCmpt:GetCurWaveIndex()
    return statCmpt:GetWaveChoosePartner(waveIndex)
end

function BattleStatHelper.GetEliteIDArray(entityID, monsterID)
    ---@type MainWorld
    local mainWorld = BattleStatHelper._GetMainWorld()
    if not mainWorld then
        return
    end
    ---@type Entity
    local monster = mainWorld:GetEntityByID(entityID)

    if not monster:HasMonsterID() then
        return
    end

    ---@type MonsterIDComponent
    local monsterIDCmpt = monster:MonsterID()
    if monsterID ~= monsterIDCmpt:GetMonsterID() then
        return
    end

    return monsterIDCmpt:GetEliteIDArray()
end

---检查光灵是否强制出战
function BattleStatHelper.CheckForceMatch(petPstID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    local entity = utilData:GetEntityByPstID(petPstID)

    return utilData:GetEntityBuffValue(entity,"PetForceMatch")
end
function BattleStatHelper.GetAllFeatureSkillCdOff()
    ---@type MainWorld
    local mainWorld = BattleStatHelper._GetMainWorld()
    if not mainWorld then
        return
    end
    ---@type FeatureServiceLogic
    local lsvcFeature = mainWorld:GetService("FeatureLogic")
    if lsvcFeature then
        local cdOff = lsvcFeature:GetAllFeatureSkillCdOff()
        return cdOff
    end
    return 0
end
function BattleStatHelper.GetSpecificFeatureSkillCdOff(featureType)
    ---@type MainWorld
    local mainWorld = BattleStatHelper._GetMainWorld()
    if not mainWorld then
        return
    end
    ---@type FeatureServiceLogic
    local lsvcFeature = mainWorld:GetService("FeatureLogic")
    if lsvcFeature then
        local specificCdOff = lsvcFeature:GetSpecificFeatureSkillCdOff(featureType)
        return specificCdOff
    end
    return 0
end

function BattleStatHelper.GetPetSkillReadyAttr(petPstID,skillID)
    ---@type MainWorld
    local mainWorld = BattleStatHelper._GetMainWorld()
    if not mainWorld then
        return
    end
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    local entity = utilData:GetEntityByPstID(petPstID)
    return utilData:GetPetSkillReadyAttr(entity,skillID)
end

function BattleStatHelper.CalcZhongxuForceMovementCostByPick(petPstID, skillID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    local entity = utilData:GetEntityByPstID(petPstID)
    return utilData:CalcZhongxuForceMovementCostByPick(entity, skillID)
end
function BattleStatHelper.CalcZhongxuForceMovementNextMinCost(petPstID, skillID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    local entity = utilData:GetEntityByPstID(petPstID)
    
    return utilData:CalcZhongxuForceMovementNextMinCostForUI(entity, skillID)
end
function BattleStatHelper.CheckCanCastActiveSkill_GetCantReadyReasonByBuff(petPstID, skillID)
    ---@type MainWorld
    local mainWorld = BattleStatHelper._GetMainWorld()
    if not mainWorld then
        return
    end
    ---@type UtilDataServiceShare
    local utilData = mainWorld:GetService("UtilData")
    local entity = utilData:GetEntityByPstID(petPstID)
    if not entity then
        return
    end
    if utilData:IsPetExtraActiveSkill(entity,skillID) then
        local canNotReady,reason = utilData:IsBuffSetExtraActiveSkillCanNotReady(petPstID,skillID)
        return reason
    else
        local canNotReady,reason = utilData:IsBuffSetActiveSkillCanNotReady(petPstID)
        return reason
    end
end
function BattleStatHelper.GetMonsterBeHitDamageValue(entityID)
    ---@type BattleStatComponent
    local statCmpt = BattleStatHelper._GetBattleStatComponent()
    return statCmpt:GetMonsterBeHitDamageValue(entityID)
end