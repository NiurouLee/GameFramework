--[[
    构造对局数据开启对局
]]
require("game_module")

AutoTestStartType = {
    Debug = 1, --调试用例
    Restart = 2, --重新开始测试
    Continue = 3, --继续上次测试
    StartHere = 4 --从此处开始测试
}

function AutoTestEnterCoreGame(startType, suite)
    local md = GameGlobal.GetModule(AutoTestModule)
    if md:IsAutoTest() then
        Log.error("自动测试中...")
        return
    end
    WorkWXPoster.ChangeBotGUID("989568c9-94e1-4002-9160-d948ed2bd386")
    startType = startType or AutoTestStartType.Restart
    md:StartAutoTest(startType, suite)
end

function AutoTestSetDebugMode(isDebug)
    local md = GameGlobal.GetModule(AutoTestModule)
    md:SetDebugMode(isDebug)
end

_class("AutoTestModule", GameModule)
AutoTestModule = AutoTestModule

function AutoTestModule:Constructor()
    self._logs = {}
    self._running = false
    self._debugMode = false
    self._config = nil
    self._setup = nil
    self._waitingUI = {}
    self._failedSuites = {}
    self:AttachEvent(GameEventType.UIShowEnd, self.OnUIShowEnd)
end

function AutoTestModule:IsAutoTest()
    return self._running
end

function AutoTestModule:SetAutoTest(v)
    self._running = v
    if not self._debugMode then
        WorkWXPoster.IsActive = v
    end
    if v then
        BattleConst.TimeSpeedList = { 2, 2,3.5 }
    else
        BattleConst.TimeSpeedList = { 1.2, 1.8,3.5 }
    end
end

function AutoTestModule:SetDebugMode(isDebug)
    self._debugMode = isDebug
end

function AutoTestModule:GetTestConfig()
    return self._config
end

function AutoTestModule:GetTestSetup()
    return self._setup
end

function AutoTestModule:AddResultLogs(logs)
    table.appendArray(self._logs, logs)
end

function AutoTestModule:GetResultLogs()
    return self._logs
end

function AutoTestModule:AddFailedSuite(suiteName)
    self._failedSuites[#self._failedSuites + 1] = suiteName
end

function AutoTestModule:GetFailedCount()
    return #self._failedSuites
end

function AutoTestModule:GetStartType()
    return self._startType
end

function AutoTestModule:StartAutoTest(startType, suite)
    self._logs = {} --清一下log
    self._waitingUI = {}
    self._startType = startType
    _G.NOGUIDE = true --关闭引导

    --查找所有suite
    local suites = {}
    if startType == AutoTestStartType.Debug then
        self._debugMode = true
        suites = { suite }
    else
        local collector = function(node, f)
            for i, v in ipairs(node.suites) do
                if not table.icontains(InvalidAutoTestConfig.invalidSuite, v.suite) then
                    suites[#suites + 1] = _G[v.suite]
                end
            end
            for _, n in ipairs(node.nodes) do
                if not table.icontains(InvalidAutoTestConfig.invalidNode, n.name) then
                    f(n, f)
                end
            end
        end
        collector(AutoTestConfig, collector)
    end

    local endIndex = #suites
    local beginIndex = 1
    if startType == AutoTestStartType.Continue then
        beginIndex = UnityEngine.PlayerPrefs.GetInt("AutoTestSuiteIndex", 1)
    elseif startType == AutoTestStartType.StartHere then
        for i, s in ipairs(suites) do
            if s == suite then
                beginIndex = i
                break
            end
        end
    end
    if beginIndex >= endIndex then
        beginIndex = 1
    end
    local startTime = os.clock()
    GameGlobal.TaskManager():StartTask(
        function(TT)
            self:SetAutoTest(true)
            local outUI = "UIDiscovery"
            for i = beginIndex, endIndex do
                local v = suites[i]
                --记录index
                if not self._debugMode then
                    UnityEngine.PlayerPrefs.SetInt("AutoTestSuiteIndex", i)
                end
                ToastManager.ShowToast("Start " .. v.name .. " (" .. i .. "/" .. endIndex .. ")")
                self:EnterCoreGame(v)
                self:WaitForUIShow(
                    TT,
                    outUI,
                    function()
                        ToastManager.ShowToast("Finish " .. v.name .. " (" .. i .. "/" .. endIndex .. ")")
                    end,
                    120, --2分钟没结束认为卡死
                    function(TT)
                        if not self._debugMode then
                            WorkWXPoster.SendError("白盒测试用例卡死：" ..
                                v.name .. " (" .. i .. "/" .. endIndex .. ")")
                        end
                        --退出局内
                        self:AutoTestClose()
                        self:AddFailedSuite(v.name)
                        YIELD(TT, 10000)
                    end
                )
            end

            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.FakeInput,
                { ui = outUI, input = "ShowAutoTestLogs", args = {} }
            )
            if not self._debugMode then
                local seconds = math.floor(os.clock() - startTime)
                local hour = math.floor(seconds / 3600)
                local min = math.floor(seconds / 60 - hour * 60)
                local mdb = MarkdownBuilder:New()
                mdb:AppendH1("局内白盒结束")
                mdb:AppendColorGreen("耗时：" .. hour .. "小时" .. min .. "分钟")
                mdb:AppendColorOrange(" 总用例数：" .. endIndex)
                mdb:AppendColorRed("失败用例：" .. #self._failedSuites .. "\n")
                for i, suiteName in ipairs(self._failedSuites) do
                    mdb:AppendColorRed(string.format("%d - %s\n", i, suiteName))
                end
                local log = mdb:ToString()
                WorkWXPoster.SendWorkWXMarkDown(log)
            end
            self:SetAutoTest(false)
        end
    )
end

function AutoTestModule:OnUIShowEnd(uiName, uiParams)
    local cb = self._waitingUI[uiName]
    if cb then
        cb(uiParams)
        self._waitingUI[uiName] = nil
    end
end

function AutoTestModule:WaitForUIShow(TT, uiName, callback, timeout, timeoutCallback)
    self._waitingUI[uiName] = callback
    local start = os.clock()
    while self._waitingUI[uiName] do
        YIELD(TT, 1000)
        if timeout > 0 then
            local delta = os.clock() - start
            if delta > timeout then
                self._waitingUI[uiName] = nil
                if timeoutCallback then
                    timeoutCallback()
                end
                break
            end
        end
    end
end

function AutoTestModule:EnterCoreGame(config)
    GameGlobal:GetInstance():SetOfflineMatch(true)
    self._config = config

    self._setup = AutoTestSetup:New(config.setup)
    self._setup:BeforeLoading()

    local pstid = self:GetModule(RoleModule):GetPstId()
    ---@type MatchCreateInfo
    local createInfo = self:CreateMatchCreateInfo(self._setup, config)
    local playerList = self:CreateMatchPlayerList(config.petList)
    local enterData = MatchEnterData:New(pstid, createInfo, playerList)
    local enterPreferenceData = MatchEnterPreFerenceData:New(playerList)
    self:GetModule(MatchModule):SetMatchEnterData(enterData, enterPreferenceData)
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Battle_Loading)
end

function AutoTestModule:ExitCoreGame()
    GameGlobal:GetInstance():SetOfflineMatch(false)
end

function AutoTestModule:CreateMatchCreateInfo(setupInfo, config)
    local createInfo = MatchCreateInfo:New()
    createInfo.match_type = setupInfo.matchType --对局类型
    createInfo.creator_id = 0 --创建者
    createInfo.level_id = setupInfo.levelID --战斗关id
    createInfo.formation_id = 0 --队伍id
    createInfo.seed = 1234567 --随机数种子
    createInfo.m_time = os.time() --服务器时间
    createInfo.match_logic_flags = 0 --逻辑功能开关
    createInfo.sync_mode = 0 --同步模式，0表现不开启，1是发布版，2是调试版
    createInfo.server_auto_fight = false --是否开启服务器自动战斗
    createInfo.guide_info = GuideInfo:New() --引导信息
    createInfo.word_ids = setupInfo.wordIds or {} --关卡词缀id列表
    createInfo.client_create_info = self:CreateClientMatchCreateInfo(setupInfo, config) --客户端提交的信息
    createInfo.level_is_pass = false -- 该关卡已经通关 false为首次挑战 true表示已经通过该关卡
    createInfo.assign_wave_refresh_probability = 0 -- 该关卡刷新额外波次的概率
    createInfo.m_nHelpPetKey = 0 --助战星灵Key
    createInfo.tale_pet_buffs = setupInfo.talePetBuffs or {} --传说星灵带的buffids
    createInfo.normal_pet_buffs = setupInfo.normalPetBuffs or {} --普通星灵带的buffids
    createInfo.trail_buff_level_id = 0 --buff_level_id列表
    createInfo.affixList = setupInfo.affixs or {}
    return createInfo
end

function AutoTestModule:CreateClientMatchCreateInfo(setupInfo, config)
    local clientInfo = ClientMatchCreateInfo:New()
    clientInfo.mission_info = {}
    clientInfo.m_extMissionInfo = {}
    clientInfo.maze_info = {}
    clientInfo.resdungeon_info = {}
    clientInfo.tower_info = {}
    clientInfo.lost_area_mission_info = {}
    clientInfo.campaign_mission_info = {}
    clientInfo.tale_pet_info = {}
    clientInfo.black_fist_info = {}
    if setupInfo.matchType == MatchType.MT_Mission then
        local info = MissionCreateInfo:New()
        info.mission_id = 4008020 --8-2
        clientInfo.mission_info[1] = info
    elseif setupInfo.matchType == MatchType.MT_Maze then
        local info = MazeCreateInfo:New()
        info.maze_version = 0
        info.maze_layer = 1
        info.maze_room_index = 0
        info.maze_light = 99
        info.maze_room_id = 1011000
        info.maze_step = 1
        info.relics = {} --圣物背包
        info.relic_counters = {} --圣物触发次数
        info.wave_randoms = { 1, 1, 1, 1, 1 } --波次随机数
        info.avg_pet_level = 50 --队伍卡牌平局等级
        info.maze_rand_seed = 1234567 --秘境随机数种子
        info.battle_archive = "" --战斗存档
        info.has_archive = false --是否有存档
        clientInfo.maze_info[1] = info
    elseif setupInfo.matchType == MatchType.MT_BlackFist then
        local info = BlackFistCreateInfo:New()
        for i, v in ipairs(config.remotePet) do
            local petInfo = MatchPetInfo:New()
            petInfo.pet_pstid = v.id
            petInfo.pet_power = -1 --初始能量
            petInfo.template_id = v.id --配置id
            petInfo.level = v.level --等级
            petInfo.grade = v.grade --阶段
            petInfo.awakening = v.awakening --觉醒
            petInfo.affinity_level = 1 --亲密度等级
            petInfo.team_slot = i --宝宝在星灵队伍中的位置
            petInfo.attack = 0 --攻击力
            petInfo.defense = 0 --防御力
            petInfo.max_hp = 0 --血量上限
            petInfo.cur_hp = 0 -- 当前血量
            petInfo.after_damage = 0 --伤害后处理系数
            petInfo.equip_lv = v.equiplv --装备等级
            petInfo.equip_refine_lv = v.equipRefineLv or 0 --装备精炼等级
            petInfo.m_nHelpPetKey = 0 --助战标识
            table.insert(info.black_team_info, petInfo)
        end
        clientInfo.black_fist_info[1] = info
    end
    return clientInfo
end

function AutoTestModule:CreateMatchPlayerList(petList)
    local luainfo = LuaMatchPlayerInfo:New()
    luainfo.blood = 1
    luainfo.nick = ""
    luainfo.pstid = self:GetModule(RoleModule):GetPstId()
    luainfo.nLevel = 1
    luainfo.pet_list = {}
    for i, v in ipairs(petList) do
        local petInfo = MatchPetInfo:New()
        petInfo.pet_pstid = v.id
        petInfo.pet_power = -1 --初始能量
        petInfo.template_id = v.id --配置id
        petInfo.level = v.level --等级
        petInfo.grade = v.grade --阶段
        petInfo.awakening = v.awakening --觉醒
        petInfo.affinity_level = 1 --亲密度等级
        petInfo.team_slot = i --宝宝在星灵队伍中的位置
        petInfo.attack = 0 --攻击力
        petInfo.defense = 0 --防御力
        petInfo.max_hp = 0 --血量上限
        petInfo.cur_hp = 0 -- 当前血量
        petInfo.after_damage = 0 --伤害后处理系数
        petInfo.equip_lv = v.equiplv --装备等级
        petInfo.equip_refine_lv = v.equipRefineLv or 0 --装备精炼等级
        petInfo.m_nHelpPetKey = 0 --助战标识
        table.insert(luainfo.pet_list, petInfo)
    end
    return { [luainfo.pstid] = luainfo }
end

function AutoTestModule:AutoTestClose()
    GameGlobal:GetInstance():StopCoreGame()
    GameGlobal.TaskManager():KillCoreGameTasks()
    GameGlobal:GetInstance():ExitCoreGame()
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery)
end
