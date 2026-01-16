_class("AutoTestSetup", Object)
AutoTestSetup = AutoTestSetup

function AutoTestSetup:Constructor(setup)
    self._config = setup
end

function AutoTestSetup:BeforeLoading()
    for i, cfg in ipairs(self._config) do
        local f = self[cfg.setup .. "_Test1"]
        if f then
            f(self, cfg.args)
        end
    end
end

function AutoTestSetup:OnWaitInput(world)
    self._world = world
    for i, cfg in ipairs(self._config) do
        local f = self[cfg.setup .. "_Test2"]
        if f then
            f(self, cfg.args)
        end
    end
end

--关卡基础信息
function AutoTestSetup:LevelBasic_Test1(args)
    self.matchType = args.matchType
    self.levelID = args.levelID
    self.words = args.words
    self.affixs = args.affixs
end

--设置关卡回合数
function AutoTestSetup:SetLevelRoundCount_Test1(args)
    local cfg = Cfg.cfg_level[self.levelID]
    self._originalRoundCount = cfg.Round
    cfg.Round = args.levelRoundCount
end

function AutoTestSetup:SetLevelRoundCount_Test2(args)
    local cfg = Cfg.cfg_level[self.levelID]
    cfg.Round = self._originalRoundCount
end


--添加波次ID列表
function AutoTestSetup:SetLevelWaveIDList_Test1(args)
    local cfg = Cfg.cfg_level[self.levelID]
    self._originalWaveIDList = cfg.MonsterWave
    cfg.MonsterWave = args.waveIDList
end

function AutoTestSetup:SetLevelWaveIDList_Test2(args)
    local cfg = Cfg.cfg_level[self.levelID]
    cfg.MonsterWave = self._originalWaveIDList
end

--添加波次刷新怪物
function AutoTestSetup:AddWaveMonster_Test(args)
    -- local t = self.wave[args.waveID]
    -- if not t.monsters then
    --     t.monsters = {}
    -- end
    -- t.monsters[#t.monsters + 1] = {
    --     monsterID = args.monsterID,
    --     bornPos = args.bornPos,
    --     bornDir = args.bornDir
    -- }
end

--添加波次刷新机关
function AutoTestSetup:AddWaveTrap_Test(args)
    -- local t = self.wave[args.waveID]
    -- if not t.traps then
    --     t.traps = {}
    -- end
    -- t.traps[#t.traps + 1] = {
    --     trapID = args.trapID,
    --     bornPos = args.bornPos,
    --     bornDir = args.bornDir
    -- }
end
--胜利条件扩展成多个
function AutoTestSetup:SetLevelCompleteCondition_Test(args)
end
--添加波次胜利条件
function AutoTestSetup:AddWaveCompleteCondition_Test(args)
end
