require "base_world_creation_context"
require "components_lookup"
---------------------------------------------

--[[-------------------------------------------
    创建一个世界的上下文
]]
_class("MainWorldCreationContext", BaseWorldCreationContext)
---@class MainWorldCreationContext:BaseWorldCreationContext
MainWorldCreationContext = MainWorldCreationContext

function MainWorldCreationContext:Constructor()
    self.WCC_StartCreationIndex = 1
    self.WCC_EntityCreationProto = Entity

    local wEComponents = ComponentsLookup:New({})
    local wUniqueComponents = ComponentsLookup:New({})
    local wEMatchers = {}

    MatchPackInstaller:InstallEntityComponentsLookup(wEComponents)
    MatchPackInstaller:InstallUniqueComponentsLookup(wUniqueComponents)

    self._sharedComponentStartIndex = wEComponents["SharedStartIndex"]
    self._logicComponentStartIndex = wEComponents["LogicStartIndex"]
    self._renderComponentStartIndex = wEComponents["RenderStartIndex"]

    self._logicCmptUniqueStartIndex = wUniqueComponents["LogicUniqueStartIndex"]
    self._renderCmptUniqueStartIndex = wUniqueComponents["RenderUniqueStartIndex"]
    self._sharedCmptUniqueStartIndex = wUniqueComponents["SharedUniqueStartIndex"]

    --Matchers 初始化依赖于 wEComponents 要放在最后
    BasePackInstaller:InstallEntityMatchers(wEMatchers, wEComponents)
    CombatPackInstaller:InstallEntityMatchers(wEMatchers, wEComponents)
    MatchPackInstaller:InstallEntityMatchers(wEMatchers, wEComponents)

    self.BWCC_EComponentsEnum = wEComponents
    self.BWCC_WUniqueComponentsEnum = wUniqueComponents
    self.BWCC_EMatchers = wEMatchers

    --项目特化定制
    self.network_mode = NetworkMode.StandAlone
    self.level_id = 0
    self.game_mode = 0
    self.world_seed = 0
    self.local_player_id = 1
    self.localPlayerInfo = nil
    self.server_auto_fight = false
    self.enable_aurora_time = false
    self.totalComponents = wEComponents.TotalComponents
    ---@type MatchType
    self.matchType = MatchType.MT_Mission
    self.missionID = -1
    --番外id，对应cfg_extra_mission_task
    self.ext_mission_task_id = -1
    ---@type ClientMatchCreateInfo
    self.clientCreateInfo = nil

    --词缀
    self.wordBuffIds = nil

    --是否已经打过该关卡
    self.level_is_pass = false

    --关卡指定类型刷新额外波次的概率
    self.assign_wave_refresh_probability = 0

    --所有的玩家数据
    self.players = {}

    ---@type MatchPet[]
    self.localMatchPets = {}
    self.localMatchPetDict = {}
    self.guideInfo = nil

    ---同步策略
    self.syncMode = 0
    ---助战Key
    self.m_nHelpPetKey = nil

    --region 传说光灵相关
    self.tale_pet_buffs = nil
    self.normal_pet_buffs = nil
    --endregion

    --是否使用了双倍券
    self.double_resource_state = false
    --携行者使用个数
    self.asset_double_item_count = 0

    ---词条
    self.affixList = {}
    self.hardID = nil
    self.boardSeed = 0
    self.waveIDList = {}
    self.boardIDList = {}

    --黑拳赛
    self.remoteTeamInfo = nil
    self.remotePlayerPos = Vector2(5, 5)
    self.remoteMatchPets = {}
    self.remoteMatchPetDict = {}
end

---@return MatchPet[], MatchPet[]
function MainWorldCreationContext:InitializePetsData()
    local petList = self.localPlayerInfo.pet_list
    ---@param v MatchPetInfo
    for k, v in ipairs(petList) do
        local petData
        if self.matchType == MatchType.MT_PopStar then
            petData = PopStarMatchPet:New(v)
        else
            petData = MatchPet:New(v)
        end
        self.localMatchPets[#self.localMatchPets + 1] = petData
        self.localMatchPetDict[v.pet_pstid] = petData
    end

    if self.remoteTeamInfo then
        petList = self.remoteTeamInfo
        ---@param v MatchPetInfo
        for k, v in ipairs(petList) do
            local petInfo = v
            petInfo.pet_pstid = k
            local petData = MatchPet:New(petInfo)
            self.remoteMatchPets[#self.remoteMatchPets + 1] = petData
            self.remoteMatchPetDict[petInfo.pet_pstid] = petData
        end
    end
    self.TeamLeaderPetPstID = -1
    return self.localMatchPetDict, self.remoteMatchPetDict
end

function MainWorldCreationContext:InitializeBonusCondition(clientCreateInfo)
    self.clientCreateInfo = clientCreateInfo
    self.bonusCondition = self:_CalcBonusConditionArray()
    if #self.bonusCondition > 1 then
        self.hasBonusCondition = true
    end
end

--获取三星条件列表
function MainWorldCreationContext:_CalcBonusConditionArray()
    local bonusConditionArray = {}
    if self.matchType == MatchType.MT_Mission then
        local missionInfo = self.clientCreateInfo.mission_info[1]
        local missionData = Cfg.cfg_mission[missionInfo.mission_id]
        local conditionID = missionData.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = missionData.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = missionData.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    elseif self.matchType == MatchType.MT_Campaign then
        local missionInfo = self.clientCreateInfo.campaign_mission_info[1]
        local missionData = Cfg.cfg_campaign_mission[missionInfo.nCampaignMissionId]
        if missionData and missionData.IgnoreThreeStar == 0 then -- 不忽略三星条件
            local conditionID = missionData.ThreeStarCondition1
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition2
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition3
            bonusConditionArray[#bonusConditionArray + 1] = conditionID
        end
    elseif MatchType.MT_ExtMission == self.matchType then
        --self._client_create_info.m_extMissionInfo[1]
        ---@type ExtMissionCreateInfo
        local extMissionInfo = self.clientCreateInfo.m_extMissionInfo[1]
        local extTaskData = Cfg.cfg_extra_mission_task[extMissionInfo.m_nExtTaskID]
        local conditionID = 0

        conditionID = extTaskData.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = extTaskData.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = extTaskData.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    elseif MatchType.MT_ResDungeon == self.matchType then
        ---@type ExtMissionCreateInfo
        local info = self.clientCreateInfo.resdungeon_info[1]
        local cfg = Cfg.cfg_res_instance_detail[info.res_dungeon_id]
        local conditionID = 0

        conditionID = cfg.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    elseif self.matchType == MatchType.MT_Chess then
        ---@type ChessMissionCreateInfo
        local info = self.clientCreateInfo.chess_mission_info[1]
        local cfg = Cfg.cfg_chess_mission[info.mission_id]
        
        local conditionID = 0
        conditionID = cfg.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    elseif self.matchType == MatchType.MT_PopStar then
        local missionInfo = self.clientCreateInfo.popstar_mission_info[1]
        local missionData = Cfg.cfg_popstar_mission[missionInfo.mission_id]
        if missionData and missionData.IgnoreThreeStar == 0 then
            local conditionID = missionData.ThreeStarCondition1
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition2
            bonusConditionArray[#bonusConditionArray + 1] = conditionID

            conditionID = missionData.ThreeStarCondition3
            bonusConditionArray[#bonusConditionArray + 1] = conditionID
        end
    elseif self.matchType == MatchType.MT_Season then
        ---@type SeasonMissionCreateInfo
        local info = self.clientCreateInfo.season_mission_info[1]
        local cfg = Cfg.cfg_season_mission[info.mission_id]
        
        local conditionID = 0
        conditionID = cfg.ThreeStarCondition1
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition2
        bonusConditionArray[#bonusConditionArray + 1] = conditionID

        conditionID = cfg.ThreeStarCondition3
        bonusConditionArray[#bonusConditionArray + 1] = conditionID
    end

    return bonusConditionArray
end

function MainWorldCreationContext:GetLocalMatchPetList()
    return self.localMatchPets
end

function MainWorldCreationContext:GetRemoteMatchPetList()
    return self.remoteMatchPets
end

function MainWorldCreationContext:GetRemotePlayerPosition()
    return self.remotePlayerPos
end

---@return MatchPet
function MainWorldCreationContext:GetPetData(pstid)
    return self.localMatchPetDict[pstid] or self.remoteMatchPetDict[pstid]
end

function MainWorldCreationContext:GetPlayerPstID()
    return self.localPlayerInfo.pstid
end

function MainWorldCreationContext:GetPlayerLevel()
    return self.localPlayerInfo.nLevel
end

function MainWorldCreationContext:AvailableInRender(index)
    return index >= self._sharedComponentStartIndex
end

function MainWorldCreationContext:UniqueCmptAvailableInRender(index)
    return index >= self._sharedCmptUniqueStartIndex
end

function MainWorldCreationContext:GetConquestCreateInfo()
    return self.clientCreateInfo.conquest_mission_info[1]
end

function MainWorldCreationContext:GetLocalHelpPetPstID()
    return self.localHelpPetPstID
end

---------------------------------------------

--[[-------------------------------------------
    世界是运行在客户端还是服务器
]]
---@class WorldRunPostion
WorldRunPostion = {
    AtServer = 1,
    AtClient = 2,
    Cutscene = 3
}
_enum("WorldRunPostion", WorldRunPostion)

---@class PlayerCreationContext
_class("PlayerCreationContext", Object)
PlayerCreationContext = PlayerCreationContext

function PlayerCreationContext:Constructor()
    self.player_id = 0
    self.player_runtime_data = nil
    self.character_context = nil
    self.pet_contexts = {}
end

function PlayerCreationContext:Destructor()
    self.character_context = nil
    self.player_runtime_data = nil
    self.pet_contexts = nil
end

---@class EntityCreationContext
_class("EntityCreationContext", Object)
EntityCreationContext = EntityCreationContext

function EntityCreationContext:Constructor()
    self.entity_config_id = 0
    self.bShow = true

    --有时候，需要手动生成一个entityconfig，去创建entity，这时需要将self.entity_config_id置为0
    self.entity_config = nil

    --runtimedata是一个entity的非配置数据，一般来自于服务器的持久化数据
    --具体格式暂时不做规定，以后肯定是跟服务器上的数据结构匹配的
    self.entity_runtime_data = nil
end
