--[[------------------------------------------------------------------------------------------
    PopStarLoadingSystem：主状态的进度条阶段执行创建逻辑对象、加载资源、初始化等操作
]]
--------------------------------------------------------------------------------------------

---@class PopStarLoadingSystem : MainStateSystem
_class("PopStarLoadingSystem", MainStateSystem)
PopStarLoadingSystem = PopStarLoadingSystem

---@return GameStateID 状态标识
function PopStarLoadingSystem:_GetMainStateID()
    return GameStateID.PopStarLoading
end

function PopStarLoadingSystem:Filter(world)
    return true
end

---@param TT TaskToken nil on server
function PopStarLoadingSystem:_OnMainStateEnter(TT)
    self:_DoCreateNetworkEntity()
    self:_DoCreateLogicBoard()
    self:_DoParseAffixData()
    self:_DoParseTrapRefreshData()
    self:_DoParsePropRefreshData()

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

    ---切换主状态机到BattleEnter
    self:_DoLogicMatchStart()
end

------------------------------------逻辑接口----------------------------------

function PopStarLoadingSystem:_DoCreateNetworkEntity()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---创建网络处理单位
    entityService:CreateNetworkEntity()
end

function PopStarLoadingSystem:_DoCreateLogicBoard()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---创建逻辑棋盘
    entityService:CreateBoardEntity()
end

function PopStarLoadingSystem:_DoParseAffixData()
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    local words = self._world.BW_WorldInfo.wordBuffIds
    if words then
        for _, wordID in ipairs(words) do
            local cfg = Cfg.cfg_word_buff[wordID]
            if cfg.affixList then
                table.appendArray(self._world._affixList, cfg.affixList)
            end
        end
        affixService:ParseAffixData(self._world._affixList)
    end
end

function PopStarLoadingSystem:_DoParseTrapRefreshData()
    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    local missionID = self._world.BW_WorldInfo.missionID
    local cfgMission = Cfg.cfg_popstar_mission[missionID]
    popStarSvc:DoParseTrapRefreshData(cfgMission.TrapRefreshID)
end

function PopStarLoadingSystem:_DoParsePropRefreshData()
    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    local missionID = self._world.BW_WorldInfo.missionID
    local cfgMission = Cfg.cfg_popstar_mission[missionID]
    popStarSvc:DoParsePropRefreshData(cfgMission.PropRefreshIDList)
end

function PopStarLoadingSystem:_DoLogicPreLoadPetSkillConfig()
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type LuaMatchPlayerInfo
    local joinedPlayerInfo = self._world.BW_WorldInfo.localPlayerInfo
    for _, petInfo in ipairs(joinedPlayerInfo.pet_list) do
        local petPstID = petInfo.pet_pstid
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        --主动技能
        local activeSkillID = petData:GetPetActiveSkill()
        if activeSkillID then
            configService:GetSkillConfigData(activeSkillID)
        end
    end
end

---加载逻辑实体（棋盘、光灵、机关）
function PopStarLoadingSystem:_DoLogicLoading()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")

    ---生成逻辑格子队列放到BoardComponent组件里
    entityService:GenerateBoardData()
    ---创建宝宝队列
    entityService:CreateBattleTeamLogic()

    ---创建首波机关
    local eTraps = {}
    local waveNum = 1
    eTraps = entityService:CreateWaveTraps(waveNum)
    self._world:BattleStat():SetFirstWaveTrapIDList(eTraps)
end

---生成进度条加载过程中的怪物结果列表，并通知表现层
function PopStarLoadingSystem:_DoLogicCalcAndNotifyLoadingResult()
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RLoadingData()
end

function PopStarLoadingSystem:_DoLogicMatchStart()
    --更新棋盘表现数据
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()

    ---切换主状态机状态
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarLoadingFinish, 1)
end

------------------------------------表现接口----------------------------------

function PopStarLoadingSystem:_DoRenderCreateRenderBoard()
end

---@param TT TaskToken
function PopStarLoadingSystem:_DoRenderLoading(TT)
end

function PopStarLoadingSystem:_DoRenderMatchStart(TT)
end

function PopStarLoadingSystem:_DoRenderPreloadCfg()
end
