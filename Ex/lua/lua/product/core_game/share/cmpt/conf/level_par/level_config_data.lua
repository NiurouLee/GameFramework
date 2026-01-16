--[[------------------------------------------------------------------------------------------
    LevelConfigData : 关卡数据
]] --------------------------------------------------------------------------------------------

_class("LevelConfigData", Object)
---@class LevelConfigData: Object
LevelConfigData = LevelConfigData

function LevelConfigData:Constructor(configService, world)
    self._world = world
    ---@type ConfigService
    self._configService = configService
    self._levelResPath = "NoneConfig"
    self._levelGridGenID = 0
    self._isApplyPetSupplyPieceWeight = 0

    self._runPosition = self._world:GetRunningPosition()
    if self._runPosition == WorldRunPostion.AtClient then
        self._levelCameraParam = LevelCameraParam:New()
    end

    self._levelMonsterParam = LevelMonsterParam:New(world)
    self._levelCompleteConditionType = 0
    ---@type string[]
    self._levelCompleteConditionParams = {}
    ---@type MonsterTransformParam
    self._levelFirstMonsterArray = {}
    self._levelFirstWaveBossID = nil
    self._levelPlayerBornPos = Vector2(0, 0)
    self._levelPlayerBornRotation = Vector2(0, 0)
    self._levelID = 0

    self._collectDropItemID = -1
    self._collectDropItemNum = -1

    self._boardCenter = Vector3(0, 0, 1)
    self._themeID = -1
    ---@type table<number,LevelStoryTipsParam>
    self._levelStoryTips = {}
    ---@type table<number,LevelStoryBannerParam>
    self._levelStoryBanner = {}
    ---@type table<number,LevelCutsceneParam>
    self._levelCutscene = {}

    --关卡回合数
    self._levelRoundCount = 0
    --WeakLine
    self._levelWeakLineData = nil
    --BGM
    self._bgmID = nil
    self._autoFightLevelPolicy = nil

    self._changeTeamLeaderCount = -1
    self._remotePlayerBornPos = Vector2(5, 5)
    self._remotePlayerBornDir = Vector2(0, -1)

    --棋子关
    self._chessPetRefreshID = nil

    --多棋盘关卡
    self._multiBoard = {}

    self._outOfRoundType = 0
    --小秘境 与怪物波次对应的局内奖励配置
    self._miniMazeWaveCfgArray = {}
end

function LevelConfigData:_ParseLevelRoundCount()
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Maze then
        local mazeService = self._world:GetService("Maze")
        self._levelRoundCount = mazeService:GetLightCount()
    elseif self._world.BW_WorldInfo.matchType == MatchType.MT_Conquest then
        local cfg = self:GetConquestConfig()
        self._levelRoundCount = cfg.MaxRound
    end
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    self._levelRoundCount = affixService:ChangeLevelRound(self._levelRoundCount)

    ---@type TalentService
    local talentSvc = self._world:GetService("Talent")
    self._levelRoundCount = self._levelRoundCount + talentSvc:GetAddRoundCount(self._levelID)
end

function LevelConfigData:_ParseChangeTeamLeaderCount()
    ---@type TalentService
    local talentSvc = self._world:GetService("Talent")
    self._changeTeamLeaderCount = self._changeTeamLeaderCount + talentSvc:GetAddChangeTeamLeaderCount()
end

function LevelConfigData:ParseLevelConfig(levelID)
    Log.notice("[LevelConfigData] level id = ", levelID)
    self._levelID = levelID
    local levelConfigData = Cfg.cfg_level[levelID]
    if not levelConfigData then
        Log.exception("ParseLevelConfig not find levelID = ", levelID)
        return
    end

    self._levelRoundCount = levelConfigData.Round
    self:_ParseLevelRoundCount()

    local bornPos = levelConfigData.BornPos
    self._levelPlayerBornPos = Vector2(bornPos[1], bornPos[2])

    local bornRotation = levelConfigData.BornRotation
    self._levelPlayerBornRotation = Vector2(bornRotation[1], bornRotation[2])

    local remotePos = levelConfigData.EnemyBornPos
    if remotePos then
        self._remotePlayerBornPos.x, self._remotePlayerBornPos.y = remotePos[1], remotePos[2]
    end

    local remoteRotation = levelConfigData.EnemyBornRotation
    if remoteRotation then
        self._remotePlayerBornDir.x, self._remotePlayerBornDir.y = remoteRotation[1], remoteRotation[2]
    end

    --格子生成方式ID
    self._levelGridGenID = levelConfigData.GridGenID
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Conquest then
        local cfg = self:GetConquestConfig()
        self._levelGridGenID = cfg.BoardID
    end
    self._isApplyPetSupplyPieceWeight = levelConfigData.PetSupplyPieceWeight or 0
    self._themeID = levelConfigData.Theme

    if self._runPosition ~= WorldRunPostion.Cutscene then
        --设置关卡怪物数据
        self._levelMonsterParam:ParseMonsterParam(levelConfigData)
    end

    --关卡胜利条件
    self._levelCompleteConditionType = levelConfigData.CompleteConditionID
    self._levelCompleteConditionParams = levelConfigData.CompleteConditionParams or {}

    if self._levelCompleteConditionType == CompleteConditionType.CombinedCompleteCondition then
        self._combinedCompleteConditionA = levelConfigData.CombinedCompleteConditionA
        self._combinedCompleteConditionAParam = levelConfigData.CombinedCompleteConditionParamA
        self._combinedCompleteConditionB = levelConfigData.CombinedCompleteConditionB
        self._combinedCompleteConditionBParam = levelConfigData.CombinedCompleteConditionParamB
    end

    if levelConfigData.BoardCenter ~= nil then
        local center =
            Vector3(levelConfigData.BoardCenter[1], levelConfigData.BoardCenter[2], levelConfigData.BoardCenter[3])
        self._boardCenter = center
    end
    if levelConfigData.StoryTips then
        for _, param in ipairs(levelConfigData.StoryTips) do
            local tipsParam = LevelStoryTipsParam:New(param)
            table.insert(self._levelStoryTips, tipsParam)
        end
    end

    if levelConfigData.StoryBanner then
        for _, param in ipairs(levelConfigData.StoryBanner) do
            local bannerParam = LevelStoryBannerParam:New(param)
            table.insert(self._levelStoryBanner, bannerParam)
        end
    end

    if levelConfigData.Cutscene then
        for _, param in ipairs(levelConfigData.Cutscene) do
            local cutsceneParam = LevelCutsceneParam:New(param)
            table.insert(self._levelCutscene, cutsceneParam)
        end
    end

    -- 检查显示弱连线引导关卡
    if levelConfigData.WeakLine then
        self._levelWeakLineData = {}
        local showType = levelConfigData.WeakLine[1].type
        if showType == 1 then --所有关卡都显示
        elseif showType == 0 then -- 某些回合不显示
            local dontShowRounds = {}
            for i = 2, #levelConfigData.WeakLine do
                local data = levelConfigData.WeakLine[i]
                table.insert(dontShowRounds, data)
            end
            self._levelWeakLineData.dontShowRounds = dontShowRounds
        end
    else
        self._levelWeakLineData = nil
    end

    if self._runPosition == WorldRunPostion.AtClient then
        --设置相机数据
        local cfgThemeData = Cfg.cfg_theme[levelConfigData.Theme]

        --场景资源路径
        self._levelResPath = cfgThemeData.SceneResPath
        self._levelCameraParam:ParseCameraParam(cfgThemeData)
        -- bgmID
        self._bgmID = cfgThemeData.BgmID
    end

    self._autoFightLevelPolicy = levelConfigData.AutoFightLevelPolicy
    self._autoFightLevelPolicyParam = levelConfigData.AutoFightLevelPolicyParam

    self._changeTeamLeaderCount = levelConfigData.ChangTeamMaxCount
    self:_ParseChangeTeamLeaderCount()

    if self._world.BW_WorldInfo.matchType == MatchType.MT_Chess then
        self._chessPetRefreshID = levelConfigData.ChessPetRefreshID
    end
    --local featureCfgHelper = FeatureConfigHelper:New()
    --self._featureList = featureCfgHelper:ParseCustomFeatureList(levelConfigData.FeautreList)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    self._featureList = affixService:ReplaceReplaceFeatureModule(levelConfigData.FeatureList)

    --多棋盘关卡
    if levelConfigData.GridGenID then
        self._multiBoard = table.cloneconf(levelConfigData.MultiBoard) or {}

        --波次刷新
        self._levelMonsterParamMultiBoard = {}

        for _, v in ipairs(self._multiBoard) do
            local boardIndex = v.index
            local levelMonsterParam = LevelMonsterParam:New(self._world)
            levelMonsterParam:ParseMonsterParamMultiBoard(v.monsterWave)
            self._levelMonsterParamMultiBoard[boardIndex] = levelMonsterParam
        end
    end

    self._outOfRoundType = levelConfigData.OutOfRoundType or 0

    ---解析关卡扩充逻辑
    local extraLogic = levelConfigData.ExtraLogic
    if extraLogic then 
        ---当守护机关死亡时，是否还检查胜负，配置成1，就不检查了
        self._ignoreProtectedTrapDead = extraLogic.IgnoreProtectedDead
    end
    --小秘境 波次对应的局内奖励
    self:_ParseMiniMazeWaveCfg(levelConfigData)
end
--小秘境 波次对应的局内奖励
function LevelConfigData:_ParseMiniMazeWaveCfg(levelConfig)
    if self._world.BW_WorldInfo.matchType == MatchType.MT_MiniMaze then
        local monsterWaveArray = levelConfig.MonsterWave
        if monsterWaveArray then
            for k, monsterWaveID in ipairs(monsterWaveArray) do
                local miniMazeWaveConfig = Cfg.cfg_mini_maze_wave[monsterWaveID]
                if (miniMazeWaveConfig == nil) then
                    Log.error("LevelMonsterParam miniMazeWaveConfig =nil", monsterWaveID)
                end
                --self._miniMazeWaveCfgArray[#self._miniMazeWaveCfgArray + 1] = table.cloneconf(miniMazeWaveConfig)
                self._miniMazeWaveCfgArray[#self._miniMazeWaveCfgArray + 1] = miniMazeWaveConfig
            end
        end
    end
end
---获取模块列表
function LevelConfigData:GetFeatureList()
    return self._featureList
    --原始配置数据 {feature={[featureType]={}}}
end
function LevelConfigData:GetAutoFightLevelPolicy()
    return self._autoFightLevelPolicy, self._autoFightLevelPolicyParam
end

function LevelConfigData:GetLevelRoundCount()
    return self._levelRoundCount
end

function LevelConfigData:GetLevelWeakLineData()
    return self._levelWeakLineData
end
function LevelConfigData:GetLevelID()
    return self._levelID
end

---@return Vector2
function LevelConfigData:GetPlayerBornPos()
    return self._levelPlayerBornPos
end

function LevelConfigData:SetPlayerBornPos(pos)
    self._levelPlayerBornPos = pos
end

function LevelConfigData:GetRemotePlayerBornPos()
    return self._remotePlayerBornPos
end

function LevelConfigData:GetRemotePlayerBornRotation()
    return self._remotePlayerBornDir
end

---@return Vector2
function LevelConfigData:GetPlayerBornRotation()
    return self._levelPlayerBornRotation
end

function LevelConfigData:GetBgmID()
    return self._bgmID
end

function LevelConfigData:GetWaveCompleteConditionType(waveNum)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    local waveCount = self._levelMonsterParam:GetMonsterWaveCount()
    if waveCount == waveNum then
        return affixService:GetAffixLastWaveCompleteType(self._levelMonsterParam:GetWaveCompleteConditionType(waveNum))
    end
    return self._levelMonsterParam:GetWaveCompleteConditionType(waveNum)
end

---
function LevelConfigData:GetWaveCombinedCompleteConditionArguments(waveNum)
    --没有提出affixService相关的需求，之后要扩展的话看一下上面
    return self._levelMonsterParam:GetWaveCombinedCompleteConditionArguments(waveNum)
end

function LevelConfigData:GetWaveCompleteConditionParam(waveNum)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    local waveCount = self._levelMonsterParam:GetMonsterWaveCount()
    if waveCount == waveNum then
        return affixService:GetAffixLastWaveCompleteParam(
            self._levelMonsterParam:GetWaveCompleteConditionParam(waveNum)
        )
    end
    return self._levelMonsterParam:GetWaveCompleteConditionParam(waveNum)
end
--获取波次数量
function LevelConfigData:GetWaveCount()
    return self._levelMonsterParam:GetMonsterWaveCount()
end

---@return LevelMonsterWaveParam
function LevelConfigData:GetWaveConfig(waveNum)
    return self._levelMonsterParam:GetWaveConfig(waveNum)
end

function LevelConfigData:GetCameraParam()
    return self._levelCameraParam
end

function LevelConfigData:GetLevelResPath()
    return self._levelResPath
end

function LevelConfigData:GetGridGenID()
    return self._levelGridGenID
end

function LevelConfigData:IsApplyPetSupplyPieceWeight()
    return self._isApplyPetSupplyPieceWeight == 1
end

---获得波次开始的怪物刷新配置
---@return LevelMonsterRefreshParam
function LevelConfigData:GetLevelWaveBeginRefreshMonsterParam(waveNum, playerPos)
    return self._levelMonsterParam:GetWaveBeginMonsterParam(waveNum, playerPos)
end

---根据刷怪类型和波次获得怪物波次中刷新配置
---@return LevelMonsterRefreshParam
function LevelConfigData:GetLevelWaveInternalRefreshMonsterParam(waveNum, refreshType)
    return self._levelMonsterParam:GetWaveInternalRefreshMonsterParam(waveNum, refreshType)
end

---获取波次陷阱ID
function LevelConfigData:GetLevelWaveTrapIDArray(waveNum)
    return self._levelMonsterParam:GetWaveBeginTrapArray(waveNum)
end

function LevelConfigData:GetLevelAllWaveTraps()
    local trapParamArray = {}

    --提前波
    local trapIDPreArray = self:GetLevelWaveTrapIDArray(0)
    if trapIDPreArray then
        table.appendArray(trapParamArray, trapIDPreArray)
    end

    --每波的机关
    for i = 1, self:GetWaveCount() do
        local trapIDArray = self:GetLevelWaveTrapIDArray(i)
        table.appendArray(trapParamArray, trapIDArray)
    end

    return trapParamArray
end

---提取波次内刷怪的数据
function LevelConfigData:GetLevelWaveInternalRefreshData(waveNum)
    return self._levelMonsterParam:GetWaveInternalRefreshData(waveNum)
end

---关卡胜利条件类型
function LevelConfigData:GetLevelCompleteConditionType()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    return affixService:GetAffixLevelCompleteType(self._levelCompleteConditionType)
end

---
function LevelConfigData:IsCombinedCompleteCondition()
    local conditionType = self:GetLevelCompleteConditionType()
    return conditionType == CompleteConditionType.CombinedCompleteCondition
end

---
function LevelConfigData:GetCombinedCompleteConditionArguments()
    return {
        conditionA = self._combinedCompleteConditionA,
        conditionParamA = self._combinedCompleteConditionAParam,
        conditionB = self._combinedCompleteConditionB,
        conditionParamB = self._combinedCompleteConditionBParam
    }
end

---返回当前关卡所有波次掉落数总和
function LevelConfigData:GetLevelCollectItem()
    -- if self._levelCompleteConditionParams ~= nil then
    --     if self._levelCompleteConditionType == CompleteConditionType.CollectItems then
    --         ---第二个参数是拾取物的数量
    --         return tonumber(self._levelCompleteConditionParams[2])
    --     end
    -- end
    local waves = self._levelMonsterParam:GetMonsterWaveArray()
    if not waves then
        return
    end
    local count = 0
    for i, v in ipairs(waves) do
        if v:GetCompleteConditionType() == CompleteConditionType.CollectItems then
            local param = v:GetCompleteConditionParam()[1]
            count = count + param[2]
        end
    end
    return count
end
function LevelConfigData:GetLevelMonsterEscapeLimit()
    -- if self._levelCompleteConditionParams ~= nil then
    --     if self._levelCompleteConditionType == CompleteConditionType.RoundCountLimitAndCheckMonsterEscape then
    --         return tonumber(self._levelCompleteConditionParams[1][2])
    --     end
    -- end
    local waves = self._levelMonsterParam:GetMonsterWaveArray()
    if not waves then
        return
    end
    local count = 0
    for i, v in ipairs(waves) do
        if v:GetCompleteConditionType() == CompleteConditionType.RoundCountLimitAndCheckMonsterEscape then
            local param = v:GetCompleteConditionParam()[1]
            count = count + param[2]
        end
    end
    return count
end

function LevelConfigData:GetLevelCompleteConditionParamList(completeConditionType)
    local waves = self._levelMonsterParam:GetMonsterWaveArray()
    if not waves then
        return
    end
    local paramList = {}
    for i, v in ipairs(waves) do
        local param = v:GetCompleteConditionParam()[1]
        if completeConditionType and v:GetCompleteConditionType() == completeConditionType then
            table.insert(paramList, param)
        else
            table.insert(paramList, param)
        end
    end
    return paramList
end

function LevelConfigData:GetLevelCompleteConditionParams()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    return affixService:GetAffixLevelCompleteParam(self._levelCompleteConditionParams)
end

---获取胜利条件国际化文本
---@return string
function LevelConfigData:GetLevelCompleteConditionStr()
    if self._levelCompleteConditionType ~= CompleteConditionType.CombinedCompleteCondition then
        return self:_GetSingleCompleteConditionStr(self._levelCompleteConditionType, self._levelCompleteConditionParams)
    end

    local mode = self._levelCompleteConditionParams[1][1]
    local args = self:GetCombinedCompleteConditionArguments()
    local strA = self:_GetSingleCompleteConditionStr(args.conditionA, args.conditionParamA)
    local strB = self:_GetSingleCompleteConditionStr(args.conditionB, args.conditionParamB)
    local str = ""
    if mode == CombinedCompleteConditionMode.And then
        str = StringTable.Get("str_battle_condition_and", strA, strB)
    elseif mode == CombinedCompleteConditionMode.Or then
        str = StringTable.Get("str_battle_condition_or", strA, strB)
    end
    return str
end

function LevelConfigData:_GetSingleCompleteConditionStr(conditionType, param)
    Log.debug("[level] LevelConfigData:GetLevelCompleteConditionStr", conditionType)
    if conditionType == CompleteConditionType.AllBossNotSurvival then
        local strID = Cfg.cfg_level_complete_condition[conditionType].ConditionStr
        ---@type MonsterConfigData
        local monsterConfigData = self._configService:GetMonsterConfigData()
        local monsterNameList = {}
        ---去掉重复的名字
        for k, v in ipairs(param[1]) do
            local name = StringTable.Get(monsterConfigData:GetMonsterName(tonumber(v)))
            local bornType = monsterConfigData:GetMonsterBornType(tonumber(v))
            if bornType ~= MonsterBornType.AfterFury then
                table.insert(monsterNameList, name)
            end
        end
        ---拼接字符串
        local ret = StringTable.Get(strID) .. " "
        for _, name in ipairs(monsterNameList) do
            ret = ret .. "【" .. name .. "】 "
        end
        return ret
    elseif conditionType == CompleteConditionType.AllConfigMonsterDead then
        local strID = Cfg.cfg_level_complete_condition[conditionType].ConditionStr
        ---@type MonsterConfigData
        local monsterConfigData = self._configService:GetMonsterConfigData()
        local monsterNameList = {}
        ---去掉重复的名字
        for k, param in ipairs(param) do
            if type(param) == "number" then
                local name = StringTable.Get(monsterConfigData:GetMonsterName(tonumber(param)))
                local bornType = monsterConfigData:GetMonsterBornType(tonumber(param))
                if bornType ~= MonsterBornType.AfterFury then
                    table.insert(monsterNameList, name)
                end
            elseif type(param) == "table" then
                --local monsterIDList = string.split(param,"|")
                for i, v in ipairs(param) do
                    local monsterID = tonumber(v)
                    local name = StringTable.Get(monsterConfigData:GetMonsterName(tonumber(monsterID)))
                    local bornType = monsterConfigData:GetMonsterBornType(tonumber(monsterID))
                    if bornType ~= MonsterBornType.AfterFury then
                        table.insert(monsterNameList, name)
                    end
                end
            end
        end
        ---拼接字符串
        local ret = StringTable.Get(strID) .. " "
        for _, name in ipairs(monsterNameList) do
            ret = ret .. "【" .. name .. "】 "
        end
        return ret
    else
        local strID = ""
        local cfgv = Cfg.cfg_level_complete_condition[conditionType]
        if cfgv then
            strID = cfgv.ConditionStr
        else
            Log.warn("### no data in cfg_level_complete_condition. ID=", conditionType)
        end
        if conditionType == CompleteConditionType.CollectItems then
            local dropItemID = param[1][1]
            local dropItemCount = param[1][2]

            return StringTable.Get(strID, dropItemCount)
        else
            if param[1] then
                return StringTable.Get(strID, param[1][1])
            else
                return StringTable.Get(strID)
            end
        end
    end
end

function LevelConfigData:GetIsBoss(waveNum)
    return self._levelMonsterParam:GetIsBoss(waveNum)
end

function LevelConfigData:GetBossID(waveNum)
    local id = self._levelMonsterParam:GetBossID(waveNum)
    if not id then
        Log.fatal("GetBossID Failed LevelID:", self._levelID, "WaveNum:", waveNum)
    end
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    id = affixService:ChangeMonsterID(id, waveNum)
    return id
end

function LevelConfigData:GetAllMonsterID()
    return self._levelMonsterParam:GetAllMonsterID()
end

function LevelConfigData:GetLoadingMonsterID()
    return self._levelMonsterParam:GetLoadingMonsterID()
end

function LevelConfigData:GetRunningMonsterID()
    return self._levelMonsterParam:GetRunningMonsterID()
end

function LevelConfigData:HitBackParam(waveNum)
    return self._levelMonsterParam:HitBackParam(waveNum)
end

---场景相机要看的中心点位置
function LevelConfigData:GetBoardCenterPos(waveNum)
    return self._boardCenter
end

function LevelConfigData:BGMParam(waveNum)
    return self._levelMonsterParam:BGMParam(waveNum)
end

function LevelConfigData:GetLevelStoryTipsParam()
    return self._levelStoryTips
end

function LevelConfigData:GetLevelStoryBannerParam()
    return self._levelStoryBanner
end

function LevelConfigData:GetLevelCutsceneParam()
    return self._levelCutscene
end

---@return table<number,StoryTipsParam>
function LevelConfigData:GetStoryTipsList(tipsID)
    local tipsConfig = Cfg.cfg_level_story_tips[tipsID]
    local tipsList = {}
    if not tipsConfig then
        Log.fatal("tipsConfig is Nil TipsID:", tipsID)
    end

    for _, v in ipairs(tipsConfig.TipsList) do
        local storyTipsParam = StoryTipsParam:New(v)
        table.insert(tipsList, storyTipsParam)
    end
    return tipsList
end
---@return    table<number,StoryBannerParam>
function LevelConfigData:GetStoryBannerList(bannerID)
    local bannerConfig = Cfg.cfg_story_banner[bannerID]
    ---@type   table<number,StoryBannerParam>
    local bannerList = {}
    if not bannerConfig then
        Log.fatal("bannerConfig is Nil BannerID:", bannerID)
    end
    for _, v in ipairs(bannerConfig.BannerList) do
        local bannerParam = StoryBannerParam:New(v)
        table.insert(bannerList, bannerParam)
    end
    return bannerList
end

function LevelConfigData:DebugCompleteCondition(nType, nParam)
    self._levelCompleteConditionType = nType
    self._levelCompleteConditionParams = nParam
    self._levelMonsterParam:DebugCompleteCondition(nType, nParam)
end

function LevelConfigData:GetChangeTeamLeaderCount()
    return self._changeTeamLeaderCount
end

function LevelConfigData:GetWaveBoard(waveNum)
    return self._levelMonsterParam:GetWaveBoard(waveNum)
end

function LevelConfigData:GetWaveBuff(waveNum)
    local cfg = Cfg.cfg_conquest_level_wave {LevelID = self._levelID, WaveIndex = waveNum}
    if cfg then
    end
end

function LevelConfigData:GetConquestConfig()
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Conquest then
        ---@type  ConquestMissionCreateInfo
        local conQuestInfo = self._world.BW_WorldInfo:GetConquestCreateInfo()
        local missionID = conQuestInfo.mission_id
        local randomIndex = conQuestInfo.random_index
        local cfg = Cfg.cfg_conquest_mission {MissionID = missionID, RandomID = randomIndex}
        if not cfg then
            Log.fatal("GetConquestConfig Failed missionID:", missionID, "RandomID:", randomIndex)
        end
        return cfg[1]
    else
        Log.fatal("GetInvalidConfig MatchTypeInvalid MatchType:", self._world.BW_WorldInfo.matchType)
    end
end

function LevelConfigData:GetChessPetRefreshID()
    return self._chessPetRefreshID
end

---是拼接棋盘关卡
function LevelConfigData:IsSpliceBoardLevel()
    local boardConfig = Cfg.cfg_board[self._levelGridGenID]
    local isSpliceBoardLevel = (boardConfig.SpliceBoard and table.count(boardConfig.SpliceBoard) > 0)
    return isSpliceBoardLevel
end

---多面棋盘
function LevelConfigData:GetMultiBoard()
    return self._multiBoard
end

---是多棋盘关卡
function LevelConfigData:IsMultiBoardLevel()
    local isMultiBoardLevel = (self._multiBoard and table.count(self._multiBoard) > 0)
    return isMultiBoardLevel
end

---获取某一面的棋盘信息
function LevelConfigData:GetMultiBoardInfo(boardIndex)
    local boardInfo = nil
    for _, v in ipairs(self._multiBoard) do
        if v.index == boardIndex then
            boardInfo = v
            break
        end
    end

    return boardInfo
end

---获得某一面波次开始的怪物刷新配置
---@return LevelMonsterRefreshParam
function LevelConfigData:GetLevelWaveBeginRefreshMonsterParamMultiBoard(boardIndex, waveNum, playerPos)
    ---@type LevelMonsterParam
    local levelMonsterParam = self._levelMonsterParamMultiBoard[boardIndex]
    if levelMonsterParam then
        ---@type LevelMonsterRefreshParam
        local monsterRefreshParam = levelMonsterParam:GetWaveBeginMonsterParam(waveNum, playerPos)
        if monsterRefreshParam then
            monsterRefreshParam:SetBoardIndex(boardIndex)
        end

        return monsterRefreshParam
    end
end

function LevelConfigData:GetOutOfRoundType()
    return self._outOfRoundType
end

function LevelConfigData:GetWaveShowInterval(waveNum)
    return self._levelMonsterParam:WaveMonsterShowInterval(waveNum)
end

---获取关卡里有守护机关死亡时，是否失败
function LevelConfigData:GetIgnoreProtectedTrapDead()
    return self._ignoreProtectedTrapDead
end
--小秘境 怪物波次对应的局内奖励配置
function LevelConfigData:GetMiniMazeWaveCfg(waveNum)
    return self._miniMazeWaveCfgArray[waveNum]
end