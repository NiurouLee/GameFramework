--[[------------------------------------------------------------------------------------------
    LoadingSystem：主状态的进度条阶段执行创建逻辑对象、加载资源、初始化等操作
]] --------------------------------------------------------------------------------------------

---@class LoadingSystem : MainStateSystem
_class("LoadingSystem", MainStateSystem)
LoadingSystem = LoadingSystem

---@return GameStateID 状态标识
function LoadingSystem:_GetMainStateID()
    return GameStateID.Loading
end

function LoadingSystem:Filter(world)
    --Log.debug("LoadingSystem Filter")
    return true
end

---@param TT TaskToken nil on server
function LoadingSystem:_OnMainStateEnter(TT)
    self:_DoCreateNetworkEntity()
    self:_DoCreateLogicBoard()
    self:_DoParseAffixData()
    self:_DoParseTalentData()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    configService:InitConfig()
    ---解析队伍里所有宝宝的技能配置
    self:_DoLogicPreLoadPetSkillConfig()

    ---表现侧有一个RenderBoardEntity用于挂载一些表现组件
    ---该Entity的具体配置详见render_entity_config文件
    self:_DoRenderCreateRenderBoard()

    ---创建棋盘、格子、宝宝、怪、机关等逻辑单位
    self:_DoLogicLoading()

    ---生成用于创建表现Entity的结果，并发送给DataListenerService
    self:_DoLogicCalcAndNotifyLoadingResult()

    ---客户端进度条加载所有表现用到的资源
    local waitTaskIDs = {}
    local clientLoadingTaskID = self:_DoRenderLoading(TT)
    table.insert(waitTaskIDs, clientLoadingTaskID)

    self:_WaitTasksEnd(TT, waitTaskIDs)

    ---客户端需要等待服务端通知对局开始的状态消息
    self:_DoRenderMatchStart(TT)

    ---自动测试特殊处理：单机环境下有概率发生配置文件的访问冲突
    self:_DoRenderPreloadCfg()

    --Log.debug("[Loading] 局内开场loading结束")
    ---切换主状态机到BattleEnter
    self:_DoLogicMatchStart()
end

---生成进度条加载过程中的怪物结果列表，并通知表现层
function LoadingSystem:_DoLogicCalcAndNotifyLoadingResult()
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RLoadingData()
end

function LoadingSystem:_DoLogicPreLoadPetSkillConfig()
    ---@type LuaMatchPlayerInfo
    local joinedPlayerInfo = self._world.BW_WorldInfo.localPlayerInfo
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    for petIndex, petInfo in ipairs(joinedPlayerInfo.pet_list) do
        local petPstID = petInfo.pet_pstid
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        local petId = petData:GetTemplateID()
        --觉醒
        local awaking = petData:GetPetAwakening()
        --突破
        local grade = petData:GetPetGrade()
        --皮肤
        local skinId = petData:GetSkinId()
        --普通攻击
        local normalSkillID = petData:GetNormalSkill()
        if normalSkillID then
            configService:GetSkillConfigData(normalSkillID)
        end
        --连锁技能
        local chainSkillIDs = petData:GetChainSkillInfo()
        if chainSkillIDs then
            for i = 1, #chainSkillIDs do
                ---@type SkillConfigData
                local configData = configService:GetSkillConfigData(chainSkillIDs[i].Skill)
                affixService:ChangePetChainCount(configData)
            end
        end
        --主动技能
        local activeSkillID = petData:GetPetActiveSkill()
        if activeSkillID then
            configService:GetSkillConfigData(activeSkillID)
        end
    end
end

function LoadingSystem:_DoLogicLoading()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---生成逻辑格子队列放到BoardComponent组件里
    entityService:GenerateBoardData()
    ---创建宝宝队列
    entityService:CreateBattleTeamLogic()

    ---创建怪和机关
    ---秘境模式下需要检查是否有秘境里的存档
    local battle_archive = self._world:GetService("Maze"):GetBattleArchive()
    local eMonsters = {}
    local eTraps = {}
    --不存档死亡怪的关不恢复活着的怪
    if battle_archive and battle_archive.completion.cond ~= CompleteConditionType.AllRefreshMonsterDead then
        eMonsters = entityService:CreateArchivedMonsters(battle_archive.monsters)
        eTraps = entityService:CreateArchivedTraps(battle_archive.traps)
    else
        local waveNum = 1
        eMonsters = entityService:CreateWaveMonsters(waveNum)
        eTraps = entityService:CreateWaveTraps(waveNum)

        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type LevelConfigData
        local levelConfigData = configService:GetLevelConfigData()
        local isMultiBoardLevel = levelConfigData:IsMultiBoardLevel()
        --多面棋盘
        if isMultiBoardLevel then
            local eMonstersOtherBoard = entityService:CreateWaveMonstersMultiBoard(waveNum)
            local eTrapsOtherBoard = entityService:CreateWaveTrapsMultiBoard(waveNum)
            table.appendArray(eMonsters, eMonstersOtherBoard)
            table.appendArray(eTraps, eTrapsOtherBoard)
        end
    end
    self._world:BattleStat():SetFirstWaveMonsterIDList(eMonsters)
    self._world:BattleStat():SetFirstWaveTrapIDList(eTraps)
end

function LoadingSystem:_DoLogicMatchStart()
    --更新表现数据
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
    self._world:EventDispatcher():Dispatch(GameEventType.LoadingFinish, 1)
end

function LoadingSystem:_DoRenderMatchStart(TT)
end

---@param TT TaskToken
function LoadingSystem:_DoRenderLoading(TT)
end

-- function LoadingSystem:_DoLogicLoadArchievedBattle()
--     --关卡胜利条件进度恢复
--     local battle_archive = self._world:GetService("Maze"):GetBattleArchive()
--     if battle_archive then
--         ---@type CompleteConditionService
--         local ccsvc = self._world:GetService("CompleteCondition")
--         local cfgsvc = self._world:GetService("Config")
--         local cond = cfgsvc:GetLevelConfigData():GetLevelCompleteConditionType()
--         if battle_archive.completion.cond == cond then
--             -- 恢复完成条件
--             ccsvc:SetArchivedData(cond, battle_archive.completion.data)
--         end
--     end
-- end

function LoadingSystem:_DoRenderCreateRenderBoard()
end

function LoadingSystem:_DoCreateLogicBoard()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---创建逻辑棋盘
    entityService:CreateBoardEntity()
end

function LoadingSystem:_DoCreateNetworkEntity()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---创建网络处理单位
    entityService:CreateNetworkEntity()
end

function LoadingSystem:_DoParseAffixData()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    local words = self._world.BW_WorldInfo.wordBuffIds
    if words then
        for _, wordID in ipairs(words) do
            local cfg = Cfg.cfg_word_buff[wordID]
            if cfg then
                if cfg.affixList then
                    table.appendArray(self._world._affixList, cfg.affixList)
                end
            end
        end
        affixService:ParseAffixData(self._world._affixList)
    end
end

function LoadingSystem:_DoParseTalentData()
    if self._world.BW_WorldInfo.matchType ~= MatchType.MT_MiniMaze then
        return
    end
    ---@type TalentService
    local talentSvc = self._world:GetService("Talent")
    ---@type BloodsuckerMissionCreateInfo
    local createInfo = self._world.BW_WorldInfo.clientCreateInfo.bloodsucker_mission_info[1]
    if createInfo then
        talentSvc:ParseTalentData(createInfo.skill_info, createInfo.relics)
    end
end

function LoadingSystem:_DoRenderPreloadCfg()
end
