_class("MatchEnterData", Object)
---@class MatchEnterData:Object
MatchEnterData = MatchEnterData

---@param create_info MatchCreateInfo
function MatchEnterData:Constructor(player_pstid, create_info, player_list)
    if player_pstid == nil then
        return
    end

    self._player_pstid = player_pstid
    self._client_create_info = create_info.client_create_info
    self._match_type = create_info.match_type
    self._level_id = create_info.level_id
    self._wordBuffIds = create_info.word_ids

    self._time = create_info.m_time
    self._seed = create_info.seed
    self._joined_players = player_list
    self._sync_mode = create_info.sync_mode
    self._server_auto_fight = create_info.server_auto_fight
    self._flags = FlagValue:New(create_info.match_logic_flags)
    self._guideInfo = create_info.guide_info

    self._level_is_pass = create_info.level_is_pass
    self._assign_wave_refresh_probability = create_info.assign_wave_refresh_probability --关卡指定类型刷新额外波次的概率
    self.m_nHelpPetKey = create_info.m_nHelpPetKey ---助战Key

    --region 传说光灵相关
    self._tale_pet_buffs = create_info.tale_pet_buffs
    self._normal_pet_buffs = create_info.normal_pet_buffs
    self._tale_buff_cfgID = create_info.trail_buff_level_id
    --endregion

    self._double_resource_state = create_info.double_resource_state

    ---词条  TODO赋值
    self._affixList = create_info.affixList ---{1001}
    self._hardIndex = create_info.hard_id
    self._hardID = create_info.hard_pro_id
    ---棋盘的随机数发生器
    self._boardSeed = create_info.board_seed

    self._waveIDList = create_info.wave_id_list
    self._boardIDList = create_info.broad_id_list
end

function MatchEnterData:IsHaveHelpPet()
    return self.m_nHelpPetKey and self.m_nHelpPetKey > 0
end

function MatchEnterData:GetPetHp()
    return 100, 100
end
function MatchEnterData:GetPetDie()
    return false
end

function MatchEnterData:GetMazePetInfoByPstId(pstid)
    local tab = {}
    tab.pet_pstid = pstid
    tab.power = 100
    -- tab.legendPower = 0  --传说光灵能量(群A1_5_光灵接入，策划说不继承了)
    tab.cur_hp = 50
    tab.is_dead = false
    return tab
end

function MatchEnterData:GetCalPetMaxHp(pstid)
    local mask_hp = 100
    return mask_hp
end

--该关卡刷新额外波次概率
function MatchEnterData:GetAssignRefreshProb()
    return self._assign_wave_refresh_probability
end

--该关卡是否已经通关
function MatchEnterData:LevelIsPass()
    return self._level_is_pass
end

--对局类型
function MatchEnterData:GetMatchType()
    return self._match_type
end

--关卡id
function MatchEnterData:GetLevelID()
    return self._level_id
end

--随机数种子
function MatchEnterData:GetSeed()
    return self._seed
end

--服务器时间
function MatchEnterData:GetServerTime()
    return self._time
end

--玩家列表
function MatchEnterData:GetPlayerList()
    return self._joined_players
end

--获取本玩家数据
function MatchEnterData:GetLocalPlayerInfo()
    return self._joined_players[self._player_pstid]
end

--主线关对局数据
function MatchEnterData:GetMissionCreateInfo()
    local createData = nil
    if self._match_type == MatchType.MT_Mission then
        return self._client_create_info.mission_info[1]
    elseif MatchType.MT_ExtMission == self._match_type then
        return self._client_create_info.m_extMissionInfo[1]
    elseif MatchType.MT_Campaign == self._match_type then
        return self._client_create_info.campaign_mission_info[1]
    elseif MatchType.MT_SailingMission == self._match_type then
        return self._client_create_info.sailing_mission_info[1]
    elseif self._match_type == MatchType.MT_MiniMaze then
        return self._client_create_info.bloodsucker_mission_info[1]
    elseif self._match_type == MatchType.MT_PopStar then
        return self._client_create_info.popstar_mission_info[1]
    elseif self._match_type == MatchType.MT_Season then
        return self._client_create_info.season_mission_info[1]
    end
end

--迷宫对局数据
function MatchEnterData:GetMazeCreateInfo()
    if self._match_type == MatchType.MT_Maze then
        return self._client_create_info.maze_info[1]
    end
end

--资源本对局数据
function MatchEnterData:GetResDungeonInfo()
    if self._match_type == MatchType.MT_ResDungeon then
        return self._client_create_info.resdungeon_info[1]
    end
end

-- 尖塔对局数据
function MatchEnterData:GetTowerInfo()
    if self._match_type == MatchType.MT_Tower then
        return self._client_create_info.tower_info[1]
    end
end

-- 通用活动关卡对局数据
function MatchEnterData:GetCampaignMissionInfo()
    if self._match_type == MatchType.MT_Campaign then
        return self._client_create_info.campaign_mission_info[1]
    end
end
-- 大航海关卡对局数据
function MatchEnterData:GetSailingMissionInfo()
    if MatchType.MT_SailingMission == self._match_type then
        return self._client_create_info.sailing_mission_info[1]
    end
end
-- 传说光灵关卡对局数据
function MatchEnterData:GetTalePetMissionInfo()
    if self._match_type == MatchType.MT_TalePet then
        return self._client_create_info.tale_pet_info[1]
    end
end

--战场关卡对局数据
function MatchEnterData:GetWorldBossCreateInfo()
    if self._match_type == MatchType.MT_WorldBoss then
        return self._client_create_info.world_boss_mission_info[1]
    end
end
--黑拳赛对局数据
---@return BlackFistCreateInfo
function MatchEnterData:GetBlackFistInfo()
    if self._match_type == MatchType.MT_BlackFist then
        return self._client_create_info.black_fist_info[1]
    end
end

---战棋对局数据
function MatchEnterData:GetChessInfo()
    if self._match_type == MatchType.MT_Chess then
        return self._client_create_info.chess_mission_info[1]
    end
end
---困难关卡
function MatchEnterData:GetDifficultyMissionInfo()
    if self._match_type == MatchType.MT_DifficultyMission then
        return self._client_create_info.difficulty_mission_info[1]
    end
end

---赛季关卡
function MatchEnterData:GetSeasonMissionInfo()
    if self._match_type == MatchType.MT_Season then
        return self._client_create_info.season_mission_info[1]
    end
end

-- 八人关卡
function MatchEnterData:GetEightPetsMissionInfo()
    if self._match_type == MatchType.MT_EightPets then
        return self._client_create_info.eight_pets_mission_info[1]
    end
end

--是否包含三星条件
function MatchEnterData:HasBonusConditionArray()
    if self._match_type == MatchType.MT_Mission then
        return true
    elseif MatchType.MT_ExtMission == self._match_type then
        return true
    elseif MatchType.MT_ResDungeon == self._match_type then
        return true
    end
end

--获取三星条件列表
function MatchEnterData:GetBonusConditionArray()
    local bonusConditionArray = {}
    if self._match_type == MatchType.MT_Mission then
        local missionInfo = self._client_create_info.mission_info[1]
        local missionData = Cfg.cfg_mission[missionInfo.mission_id]
        local conditionID = missionData.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = missionData.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = missionData.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    elseif MatchType.MT_Campaign == self._match_type then
        local missionInfo = self._client_create_info.campaign_mission_info[1]
        local missionData = Cfg.cfg_campaign_mission[missionInfo.nCampaignMissionId]
        if missionData and missionData.IgnoreThreeStar == 0 then -- 不忽略三星条件
            local conditionID = missionData.ThreeStarCondition1
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition2
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition3
            bonusConditionArray[#bonusConditionArray + 1] = conditionID
        end
    elseif MatchType.MT_ExtMission == self._match_type then
        --self._client_create_info.m_extMissionInfo[1]
        ---@type ExtMissionCreateInfo
        local extMissionInfo = self._client_create_info.m_extMissionInfo[1]
        local extTaskData = Cfg.cfg_extra_mission_task[extMissionInfo.m_nExtTaskID]
        local conditionID = 0

        conditionID = extTaskData.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = extTaskData.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = extTaskData.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    elseif MatchType.MT_ResDungeon == self._match_type then
        ---@type ExtMissionCreateInfo
        local info = self._client_create_info.resdungeon_info[1]
        local cfg = Cfg.cfg_res_instance_detail[info.res_dungeon_id]
        local conditionID = 0

        conditionID = cfg.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    elseif MatchType.MT_Season == self._match_type then
        local missionInfo = self._client_create_info.season_mission_info[1]
        local missionData = Cfg.cfg_season_mission[missionInfo.mission_id]
        if missionData and missionData.ShowCondition == 1 then -- 不忽略三星条件
            local conditionID = missionData.ThreeStarCondition1
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition2
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition3
            bonusConditionArray[#bonusConditionArray + 1] = conditionID
        end
    end

    return bonusConditionArray
end

-- function MatchEnterData:IsAutoFightEnabled()
--     return self._flags:CheckFlag(MatchLogicFlags.MLF_AutoFight)
-- end

function MatchEnterData:IsSpeedUpEnabled()
    return self._flags:CheckFlag(MatchLogicFlags.MLF_SpeedUp)
end

function MatchEnterData:GetSyncMode()
    return self._sync_mode
end

function MatchEnterData:GetServerAutoFight()
    return self._server_auto_fight
end

function MatchEnterData:IsEnableAuroraTime()
    return Cfg.cfg_global["EnableAuroraTime"].IntValue == 1
end

function MatchEnterData:GetWordBuffIds()
    return self._wordBuffIds
end

function MatchEnterData:GetLocalMatchPets()
    if self._func_get_local_match_pets then
        return self._func_get_local_match_pets()
    end
end

function MatchEnterData:GetRemoteMatchPets()
    if self._func_get_remote_match_pets then
        return self._func_get_remote_match_pets()
    end
end

function MatchEnterData:GetTalePetBuffs()
    return self._tale_pet_buffs
end
function MatchEnterData:GetNormalPetBuffs()
    return self._normal_pet_buffs
end

function MatchEnterData:GetTaleBuffCfgID()
    return self._tale_buff_cfgID
end

function MatchEnterData:GetAffixList()
    return self._affixList
end

function MatchEnterData:GetDoubleResourceState()
    return self._double_resource_state
end

---@return number
function MatchEnterData:GetAssetDoubleItemCount()
    if self._match_type == MatchType.MT_Mission then
        return self:GetMissionCreateInfo().asset_double_item_count
    elseif MatchType.MT_ResDungeon == self._match_type then
        return self:GetResDungeonInfo().asset_double_item_count
    end
    return 0
end

function MatchEnterData:GetHardID()
    return self._hardID
end

function MatchEnterData:GetHardIndex()
    return self._hardIndex
end

function MatchEnterData:GetBoardSeed()
    return self._boardSeed
end

function MatchEnterData:GetWaveIDList()
    return self._waveIDList
end

function MatchEnterData:GetBoardIDList()
    return self._boardIDList
end

---@param matchType MatchType
function MatchEnterData:GetFsmID(matchType)
    if matchType == MatchType.MT_PopStar then
        return 2
    end
    
    return 1
end

---@class MainWorldCreationContextType
local MainWorldCreationContextType = {
    Client = 1,
    Server = 2
}
_enum("MainWorldCreationContextType", MainWorldCreationContextType)

---@return MainWorldCreationContext
---@param type MainWorldCreationContextType
function MatchEnterData:CreateWorldInfo(type)
    ---@type MainWorldCreationContext
    local worldInfo = MainWorldCreationContext:New()
    worldInfo.game_mode = MatchType2GameMode.GetGameModeByMatchType(self:GetMatchType())
    worldInfo.fsm_id = self:GetFsmID(self:GetMatchType())
    worldInfo.level_id = self:GetLevelID()
    worldInfo.world_seed = self:GetSeed()
    worldInfo.players = self:GetPlayerList()
    worldInfo.localPlayerInfo = self:GetLocalPlayerInfo()
    local syncMode = self:GetSyncMode()
    if syncMode ~= 0 then
        worldInfo.network_mode = NetworkMode.Networks
    else
        worldInfo.network_mode = NetworkMode.StandAlone
    end

    worldInfo.syncMode = syncMode
    worldInfo.wordBuffIds = self:GetWordBuffIds()
    worldInfo.level_is_pass = self:LevelIsPass()
    worldInfo.assign_wave_refresh_probability = self:GetAssignRefreshProb()

    ---是否由服务器计算自动战斗数据 仅用于机器人跑局内
    worldInfo.server_auto_fight = self:GetServerAutoFight()
    worldInfo.enable_aurora_time = self:IsEnableAuroraTime()
    worldInfo.hasBonusCondition = self:HasBonusConditionArray()
    worldInfo.matchType = self:GetMatchType()
    worldInfo.guideInfo = self._guideInfo
    worldInfo:InitializeBonusCondition(self._client_create_info)

    if worldInfo.matchType == MatchType.MT_Mission then
        worldInfo.missionID = self:GetMissionCreateInfo().mission_id
    elseif worldInfo.matchType == MatchType.MT_ExtMission then
        worldInfo.ext_mission_task_id = self:GetMissionCreateInfo().m_nExtTaskID
    elseif worldInfo.matchType == MatchType.MT_Maze then
        worldInfo.mazeCreateInfo = self:GetMazeCreateInfo()
    elseif worldInfo.matchType == MatchType.MT_BlackFist then
        worldInfo.blackFistInfo = self:GetBlackFistInfo()
        worldInfo.remoteTeamInfo = worldInfo.blackFistInfo.black_team_info
        for _, matchPetInfo in ipairs(worldInfo.remoteTeamInfo) do
            matchPetInfo.pet_power = -1
        end
    elseif worldInfo.matchType == MatchType.MT_PopStar then
        worldInfo.missionID = self:GetMissionCreateInfo().mission_id
    end

    if type == MainWorldCreationContextType.Server then
        worldInfo.network_mode = NetworkMode.Networks
    end

    local localMatchPets, remoteMatchPets = worldInfo:InitializePetsData()
    self._func_get_local_match_pets = function()
        return localMatchPets, worldInfo.localPlayerInfo.pet_list
    end
    self._func_get_remote_match_pets = function()
        return remoteMatchPets, worldInfo.remoteTeamInfo
    end
    worldInfo.m_nHelpPetKey = self.m_nHelpPetKey

    --region 传说光灵相关
    worldInfo.tale_pet_buffs = self:GetTalePetBuffs()
    worldInfo.normal_pet_buffs = self:GetNormalPetBuffs()
    --endregion

    ---词条
    worldInfo.affixList = self:GetAffixList()
    worldInfo.double_resource_state = self:GetDoubleResourceState()
    worldInfo.hardID = self:GetHardID()

    worldInfo.asset_double_item_count = self:GetAssetDoubleItemCount()

    worldInfo.boardSeed = self:GetBoardSeed()
    worldInfo.waveIDList = self:GetWaveIDList()
    worldInfo.boardIDList = self:GetBoardIDList()

    --[[
        助战数据获取
        就算需求是“有助战的阵容内固定5号slot是助战光灵”也不代表你真的都不需要存一下到底谁是助战光灵！
        C++那边有一个东西是E_HelpPet_EnableHelpSlotIndex，这个值是5，服务端代码就是这样写的：
        (team_slot == E_HelpPet_EnableHelpSlotIndex && nHelpPetKey > 0)

        秘境和黑拳赛目前（2022/1/4）不存在助战，所以只遍历localTeam就可以
    ]]
    if self.m_nHelpPetKey > 0 then
        -- worldInfo.localHelpPetPstID = 111
        for _, matchPet in pairs(localMatchPets) do
            if matchPet:GetTeamSlot() == BattleConst.E_HelpPet_EnableHelpSlotIndex then
                worldInfo.localHelpPetPstID = matchPet:GetPstID()
                break
            end
        end
    end

    return worldInfo
end
