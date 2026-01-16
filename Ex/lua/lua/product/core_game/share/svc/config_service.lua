--[[------------------------------------------------------------------------------------------
    ConfigService : 局内使用的配置服务，逻辑与具体配置隔离
]] --------------------------------------------------------------------------------------------

_class("ConfigService", Object)
---@class ConfigService: Object
ConfigService = ConfigService

function ConfigService:Constructor(world)
    ---@type MainWorld
    self._world = world
end

function ConfigService:Initialize()
    ---@type LevelConfigData
    self._levelConfigData = LevelConfigData:New(self, self._world)
    self._monsterConfigData = MonsterConfigData:New(self._world)
    self._trapConfigData = TrapConfigData:New()
    self._aiConfigData = AiConfigData:New()
    
    ---@type ChessPetConfigData
    self._chessPetConfigData = ChessPetConfigData:New(self._world)

    local hasViewParser = true
    ---@type WorldRunPostion
    local runPos = self._world:GetRunningPosition()
    if runPos == WorldRunPostion.AtServer then
        hasViewParser = false
    end

    --技能配置
    ---@type SkillConfigHelper
    self._skillConfigHelper = SkillConfigHelper:New(hasViewParser)
    --buff配置
    self._buffConfigDic = {}

    --掉落配置
    self._dropConfigData = MonsterDropConfigData:New()

    --掉落物数据
    --key是dropItemID,value是MonsterDropItemConfigData
    self._dropItemConfigDic = {}

    --解析过的3D剧情配置列表,key是cutsceneID,value是CutsceneConfigData
    self._cutsceneDic = {}

    --模块（基础）配置
    ---@type FeatureConfigHelper
    self._featureConfigHelper = FeatureConfigHelper:New()

end

function ConfigService:InitConfig()
    ---@type MainWorldCreationContext
    local worldContext = self._world.BW_WorldInfo
    self._levelConfigData:ParseLevelConfig(worldContext.level_id)
end

---提取当前战斗关卡数据
---@return LevelConfigData
function ConfigService:GetLevelConfigData()
    return self._levelConfigData
end

---提取当前关卡的怪物数据
---@return MonsterConfigData
function ConfigService:GetMonsterConfigData()
    return self._monsterConfigData
end

---提取当前关卡的机关数据
function ConfigService:GetTrapConfigData()
    return self._trapConfigData
end

---提取当前关卡的怪物数据
function ConfigService:GetAiConfigData()
    return self._aiConfigData
end

---清除读取的数据
function ConfigService:ClearSkillConfigData()
    self._skillConfigHelper:ClearSkillData()
end

---提取技能数据
---@param skillID number 技能ID
---@param casterEntity Entity
---@return SkillConfigData 技能配置数据体
function ConfigService:GetSkillConfigData(skillID, casterEntity, forceFetchNew)
    local configData = self._skillConfigHelper:GetSkillData(skillID, forceFetchNew)
    --目前只有光灵的主动技会被替换
    if (not casterEntity) or (not casterEntity:HasPetPstID()) or (configData:GetSkillType() ~= SkillType.Active) then
        return configData
    end

    ---阿克希亚：扫描模块逻辑——扫描模块会根据玩家输入构建一个临时的SkillConfigData
    ---它将替代掉配置上的主动技ID进行计算
    local isSkillReplacedByFeatureScan = casterEntity:HasMatchPet()
    if isSkillReplacedByFeatureScan then
        ---@type MatchPet
        local matchPetData = casterEntity:MatchPet():GetMatchPet()
        local featureList = matchPetData:GetFeatureList() or {feature = {}}
        isSkillReplacedByFeatureScan = featureList.feature[FeatureType.Scan] ~= nil
    end

    if not isSkillReplacedByFeatureScan then
        return configData
    else
        local eBoard = self._world:GetBoardEntity()
        local cLogicFeature = eBoard:LogicFeature()
        if not cLogicFeature:GetActiveSkillConfigData() then
            --[[TODO print some error here]]
            return configData
        end
        return cLogicFeature:GetActiveSkillConfigData()
    end
end

--提取buff数据
---@return BuffConfigData
function ConfigService:GetBuffConfigData(buffID)
    --[[for k, v in pairs(self._buffConfigDic) do
        if k == buffID then
            return v
        end
    end--]]
    if self._buffConfigDic[buffID] ~= nil then
        return self._buffConfigDic[buffID]
    end

    ---没有缓存的话，解析一次
    local buffConfigData = BuffConfigData:New(buffID)
    self._buffConfigDic[buffID] = buffConfigData
    return buffConfigData
end

---提取怪物的掉落数据
---@param dropID 掉落ID
function ConfigService:GetMonsterDropConfigData()
    return self._dropConfigData
end

---掉落物配置数据
---@return MonsterDropItemConfigData
function ConfigService:GetMonsterDropItemConfigData(dropItemID)
    --[[for k, v in pairs(self._dropItemConfigDic) do
        if k == dropItemID then
            return v
        end
    end--]]
    if self._dropItemConfigDic[dropItemID] ~= nil then
        return self._dropItemConfigDic[dropItemID]
    end

    ---@type MonsterDropItemConfigData
    local dropItemConfigData = MonsterDropItemConfigData:New()
    --dropItemConfigData:ParseDropItemConfig(dropItemID)

    self._dropItemConfigDic[dropItemID] = dropItemConfigData

    return dropItemConfigData
end

---提取任务的三星奖励条件，从missionmodule重构过来，主线
---@param missionID number
---@return number[]
function ConfigService:GetMission3StarCondition(missionID)
    local mission_config = Cfg.cfg_mission[missionID]
    local condition = {}
    if mission_config then
        table.insert(condition, mission_config.ThreeStarCondition1)
        table.insert(condition, mission_config.ThreeStarCondition2)
        table.insert(condition, mission_config.ThreeStarCondition3)
    end
    return condition
end

-- 活动通用关卡
---@param missionID number
---@return number[]
function ConfigService:GetCampaignMission3StarCondition(missionID)
    local mission_config = Cfg.cfg_campaign_mission[missionID]
    local condition = {}
    if mission_config and mission_config.IgnoreThreeStar == 0 then
        table.insert(condition, mission_config.ThreeStarCondition1)
        table.insert(condition, mission_config.ThreeStarCondition2)
        table.insert(condition, mission_config.ThreeStarCondition3)
    end
    return condition
end

function ConfigService:GetChessMission3StarCondition(missionID)
    local mission_config = Cfg.cfg_chess_mission[missionID]
    local condition = {}
    if mission_config and mission_config.IgnoreThreeStar == 0 then
        table.insert(condition, mission_config.ThreeStarCondition1)
        table.insert(condition, mission_config.ThreeStarCondition2)
        table.insert(condition, mission_config.ThreeStarCondition3)
    end
    return condition
end

--获取番外3星条件
function ConfigService:GetExtMission3StarCondition(taskID)
    local mission_config = Cfg.cfg_extra_mission_task[taskID]
    local condition = {}
    if mission_config then
        condition[1] = mission_config.ThreeStarCondition1
        condition[2] = mission_config.ThreeStarCondition2
        condition[3] = mission_config.ThreeStarCondition3
    end
    return condition
end

-- 消灭星星关卡三星条件
---@param missionID number
---@return number[]
function ConfigService:GetPopStar3StarCondition(missionID)
    local mission_config = Cfg.cfg_popstar_mission[missionID]
    local condition = {}
    if mission_config and mission_config.IgnoreThreeStar == 0 then
        table.insert(condition, mission_config.ThreeStarCondition1)
        table.insert(condition, mission_config.ThreeStarCondition2)
        table.insert(condition, mission_config.ThreeStarCondition3)
    end
    return condition
end
---@param missionID number
---@return number[]
function ConfigService:GetSeasonMission3StarCondition(missionID)
    local mission_config = Cfg.cfg_season_mission[missionID]
    local condition = {}
    if mission_config and mission_config.ShowCondition == 1 then
        table.insert(condition, mission_config.ThreeStarCondition1)
        table.insert(condition, mission_config.ThreeStarCondition2)
        table.insert(condition, mission_config.ThreeStarCondition3)
    end
    return condition
end
---获取被动技能ID
function ConfigService:GetPetPassiveSkill(passiveSkillID)
    local config = Cfg.cfg_passive_skill[passiveSkillID]
    return config
end

function ConfigService:GetChangeTeamLeaderCount()
    local count = self._levelConfigData:GetChangeTeamLeaderCount()
    return count
end
---获取指定波次的胜利条件类型
function ConfigService:GetWaveCompleteConditionType(waveIndex)
    ---@type CompleteConditionType
    local completeConditionType = self._levelConfigData:GetWaveCompleteConditionType(waveIndex)
    return completeConditionType
end

function ConfigService:GetCutsceneConfig(cutsceneID)
    if self._cutsceneDic[cutsceneID] ~= nil then
        return self._cutsceneDic[cutsceneID]
    end

    ---@type CutsceneConfigData
    local cutsceneCfgData = CutsceneConfigData:New()
    cutsceneCfgData:ParseCutsceneConfig(cutsceneID)

    self._cutsceneDic[cutsceneID] = cutsceneCfgData

    return cutsceneCfgData
end

function ConfigService:GetN5CurWaveConfig()
    if self._world._matchType == MatchType.MT_Conquest then
        local levelID = self._world.BW_WorldInfo.level_id
        local waveIndex = self._world:BattleStat():GetCurWaveIndex()
        local cfg = Cfg.cfg_conquest_level_wave {LevelID = levelID, WaveIndex = waveIndex}
        if not cfg then
            Log.fatal("GetN5CurWaveConfig Failed LevelID:", levelID, "WaveIndex:", waveIndex)
        end
        return cfg[1]
    end
    Log.fatal("GetN5CurWaveConfig MatchType", self._world._matchType, " Invalid ")
end
function ConfigService:N5GetCurWaveScore()
    local cfg = self:GetN5CurWaveConfig()
    if cfg then
        return cfg.WaveFirstPassAward[2]
    end
end

function ConfigService:GetN5WaveBuff()
    local cfg = self:GetN5CurWaveConfig()
    if cfg then
        return cfg.WavePassBuff
    end
end

function ConfigService:GetHardID()
    if self._world._matchType == MatchType.MT_Conquest then
        local cfg = self:GetN5CurWaveConfig()
        return cfg.DiffParamID
    elseif self._world._matchType == MatchType.MT_MiniMaze then
        ---@type LevelConfigData
        local levelConfigData = self:GetLevelConfigData()
        local curWaveIndex = self._world:BattleStat():GetCurWaveIndex()
        local cfgMiniMazeWave = levelConfigData:GetMiniMazeWaveCfg(curWaveIndex)
        return cfgMiniMazeWave.DiffParamID
    else
        return self._world:GetHardID()
    end
end
---@param attrFormalType MonsterADHFormulaType
function ConfigService:GetAffixHardParam(attrFormalType)
    local defY = BattleConst.MonsterADHFormula2ParmaYDefault
    local defZ = BattleConst.MonsterADHFormula2ParmaZDefault
    local hardID = self:GetHardID()
    local cfg = Cfg.cfg_affix_hard_param[hardID]
    if cfg then
        if attrFormalType == MonsterADHFormulaType.N4AttackAndDefense then
            return cfg.ParamY, cfg.ParamZ
        elseif attrFormalType == MonsterADHFormulaType.N4HP then
            return cfg.ParamY2, cfg.ParamZ2
        elseif attrFormalType == MonsterADHFormulaType.N25MiniMaze then
            return cfg.ParamY3 or defY, cfg.ParamZ3 or defZ
        end
    end
    return defY, defZ
end

---提取当前关卡的棋子光灵数据
---@return ChessPetConfigData
function ConfigService:GetChessPetConfigData()
    return self._chessPetConfigData
end

---提取模块（基础）数据
---@param featureType number 模块类型
---@return FeatureConfigData 模块配置数据体
function ConfigService:GetFeatureConfigData(featureType)
    return self._featureConfigHelper:GetFeatureData(featureType)
end
---解析光灵、关卡的模块配置，与模块基础配置组合出最终的配置对象
---featureCfg 原始配置数据 {[featureType]={}}
function ConfigService:ParseCustomFeatureList(featureCfg)
    return self._featureConfigHelper:ParseCustomFeatureList(featureCfg)
end