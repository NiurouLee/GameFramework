--[[------------------------------------------------------------------------------------------
    BattleStatComponent : 战斗信息统计组件 
]] --------------------------------------------------------------------------------------------

_class("BattleStatComponent", Object)
---@class BattleStatComponent: Object
BattleStatComponent = BattleStatComponent

---@param world World
function BattleStatComponent:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")
    self._curWaveIndex = 1
    self._totalWaveCount = 0
    --当前回合是否超级连锁
    self._isSuperChain = false
    --当前回合是否是极光时刻
    self._isAuroraTime = false
    --标记 是极光时刻中再次进入极光时刻（词缀功能 可以重进极光时刻）
    self._isReEnterAuroraTime = false
    --行走导致的刷格子计数，从1开始
    self._pieceRefreshCount = 0
    ------------------------------------------------------------------------------------------
    --当前波次
    --self._curWaveIndex = 0
    --当前关卡的剩余回合数
    self._levelLeftRoundCount = 0
    --当前关卡的回合数
    self._levelInitRound = 0
    --关卡的累计回合数
    self._levelTotalRoundCount = 1
    --关卡的补充回合数（目前来自buff）
    self._levelSupplementRoundCount = 0

    --当前波次的回合数
    self._curWaveInitRound = 0
    --当前波次的累计回合数,默认就是第一回合
    self._curWaveTotalRoundCount = 1
    --当前波次的剩余回合数
    self._curWaveLeftRoundCount = 0
    --当前波次的惩罚回合数
    self._curWavePunishmentRoundCount = 0

    --单局的超级连锁数
    self._superChainCount = 0
    --单局的主动技数
    self._activeSkillCount = 0
    --连锁技次数
    self._chainSkillCount = 0
    --转色技能次数
    self._colorSkillCount = 0
    --一次主动技杀怪数
    self._oneActiveSkillKillCount = 0
    --一次连线最大普攻数量
    self._oneChainMaxNormalAttack = 0
    --一次连线杀怪数
    self._oneChainKillCount = 0
    --一次连线消除的格子最大数
    self._oneMatchMaxNum = {
        one_match_num = 0,
        element_type = PieceType.None
    }
    --单局消除的格子总数
    self._totalMatchNum = 0
    --单局消除每种元素的格子总数
    self._totalElementMatchNum = {}
    self._totalElementMatchNum[ElementType.ElementType_Blue] = 0
    self._totalElementMatchNum[ElementType.ElementType_Red] = 0
    self._totalElementMatchNum[ElementType.ElementType_Green] = 0
    self._totalElementMatchNum[ElementType.ElementType_Yellow] = 0

    --本波次死亡怪物列表
    ---@type number[]
    self._curWaveDeadMonsterIDArray = {}
    ---@type MonsterDeadParam[]
    self._curWaveDeadMonsterParam = {}
    --单局死亡怪物列表
    ---@type MonsterDeadParam[]
    self._totalDeadMonsterIDArray = {}
    --杀死boss数量
    self._killBossCount = 0
    --玩家受击次数
    self._playerBeHitCount = 0
    ---本波次是否通过怪物死亡触发过刷怪,不支持多次触发死亡刷怪
    self._curWaveHasDeadRefreshMonsterState = false

    ---是不是最后一波
    self._isLastWave = false

    --三星条件匹配结果
    self._matchResult = {}

    --三星条件进度
    self._star3Progress = {}

    --当前拾取到的掉落物列表
    self._collectDropNum = 0
    --暂时是资源本掉落的玩家资源
    ---@type RoleAsset[]
    self._dropRoleAssetList = {}

    --暂时是资源本掉落的玩家资源不计入双倍券双倍计算
    ---@type RoleAsset[]
    self._dropRoleAssetNoDoubleList = {}
    --总掉落奖励
    self._totalDropAssets = {}

    --关卡是否完成
    self._battleLevelResult = false
    --波次是否完成
    self._battleWaveResult = false

    ---第几次划线
    self._curChainIndex = 1

    ---单局划线总次数
    self._totalChainNum = 0

    ---怪物死亡弹出Banner使用
    ---@type table<number,table<number,number>>
    self._deadMonsterShowBannerList = {}

    ---@type MatchResult
    self._battleResult = nil
 

    ---上一次释放主动技的回合数
    self._lastDoActiveSkillRound = {}
	
    ---光灵释放主动技的记录  [petPstID]={[回合1]={技能ID1，技能ID2},[回合2]={技能ID1}}
    self._petDoActiveSkillRecord = {}

    -- 被每个机关分别攻击的次数
    self._takeAttackTimesByTrap = {}

    -- 被每个机关攻击的伤害量
    self._takeAttackDamageByTrap = {}

    -- 玩家打碎的机关数量
    self._smashTrapCount = {}

    -- 是否触发特殊波次刷新
    self._AssignWaveResult = false

    -- 当前波次怪物全部死亡触发刷新次数
    self._curWaveAllMonsterDeadTimes = 0

    --是否使用过自动战斗
    self._everAutoFight = 0
   --是否自动战斗
    self._autoFight = false

    --极光时刻次数
    self._auroraTimeCount = 0

    --切换队长的次数，这个是主动更换队长
    self._changeTeamLeaderNum = 0

    ---被动切换队长，例如秘境里队长死亡后，下一个星灵接替队长位置
    self._passiveChangeTeamLeaderNum = 0

    ---无限自动刷怪使用的数据结构
    self.m_listSummonMonsterID = {}
    self.m_nAutoSummon_Index = 0
    self.m_nAutoSummon_TeamIndex = 0
    ---@type SortedArray
    self.m_listAutoSummon = SortedArray:New(Algorithm.COMPARE_CUSTOM, BattleStatComponent._LessComparerByRefreshID)
    self.m_listAutoSummon:AllowDuplicate()
    self.m_nAutoSummonLevel = 0 ---自动刷新当前使用的Level编号

    self._triggerDimensionFlag = TriggerDimensionFlag.None

    self._normalAttackKillCount = 0
    self._firstDeadPetEntity = nil

    self._deadPetList = {}

    self._damageIndex = 0

    ---@type table<number,BuffIntensifyParam>
    self._exChangeBuffMap = {}

    --回合计数
    self._roundCount = 0
    --waitinput 计数
    self._waitInputCount = 0
    --舒摩尔血条数字处理开关
    self._handleShumolHPUI = 0

    self._firstWaveMonsterIDList = {}
    self._firstWaveTrapIDList = {}

    self._roundBeginPlayerPos = Vector2.zero
    self._passWaveList = {}
    ---用来存储怪物被击的伤害数字
    ---@type table<number,number>
    self._monsterBeHitDamageValue ={}

    self._lastAntiTriggerEntityID = 0
    self._mazeAddLight = 0
    self._lastActiveSkillID = 0
    self._lastActiveSkillCasterID = 0

    self._waveEnterRound = {}
    self._curWaveDeadMonsterBuffTable = {}
    self._totalDeadMonsterBuffTable = {}

    self._collectDropNumItemIDDic = {}
    self._playerSkillHitCount = {}

    self._chessDeadPlayerPawnCount = 0
    self._chessDeadPlayerPawnIDChecker = {}
    ---当前回合 某光灵释放了几次主动技
    self._curRoundDoActiveSkillTimes = {}

    self._isPunishmentRoundExecuted = {}

    self._deadMarkAddCount = 0

    --盗宝关 怪物逃脱数
    self._monsterEscapeNum = 0
    --cmd计数
    self._pushCommandIndex = 0
    self._isCastChainByDimensionDoor = false

    ---小秘境    
    self._waveRelicIDDic = {} ---局内获取圣物ID列表 key是回合数 value是圣物ID
    self._wavePartnerDic = {} ---获取的伙伴列表 key是回合数 value是伙伴ID
    self._relicGroupInvalidIDDic = {} ---局内已随机过的圣物组ID对应的圣物ID列表 圣物组ID 失效的圣物ID列表
    self._waveOptionalPartnerListDic = {} ---供选择的伙伴列表 key是回合数 value是伙伴ID
    self._wavePartnerAbandonedList = {} ---被弃选的伙伴列表,不能再出现 伙伴ID数组
    self._waveRelicIDList = {} ---局内获取圣物ID数组 避免使用pairs
    self._wavePartnerIDList = {} ---局内获取伙伴ID数组 避免使用pairs
    self._waveWaitApplyRelicID = 0--局内 等待应用的圣物
    self._waveWaitApplyRelicIsOpening = false--局内 等待应用的圣物 是否是开局圣物
    self._waveWaitApplyPartnerID = 0--局内 等待应用的伙伴
    self._allLocalTeamScanTrapIDInMatch = {}
    self._trapIDBySummonCasterEntityID = {}

    self._combinedConditionRecords = {}

    self._mainWorldBossID = nil--多世界boss时，统计伤害只按第一只boss取
    ---key:monsterClassID,value:数量
    ---保存整场战斗中，每个ClassID出生的数量
    ---@type table<number,number>
    self._createMonsterClassIDRecord = {}
    ---key:monsterD,value:数量
    ---保存整场战斗中，每个MonsterID出生的数量
    ---@type table<number,number>
    self._createMonsterIDRecord = {}
end

function BattleStatComponent:AddMonsterClassIDCreate(monsterClassID)
    if monsterClassID then
        self._createMonsterClassIDRecord[monsterClassID] = (self._createMonsterClassIDRecord[monsterClassID] or 0) + 1
    end
end

function BattleStatComponent:GetMonsterClassIDCount(monsterClassID)
    return self._createMonsterClassIDRecord[monsterClassID] or 0
end

function BattleStatComponent:AddMonsterIDCreate(monsterID)
    if monsterID then
        self._createMonsterIDRecord[monsterID] = (self._createMonsterIDRecord[monsterID] or 0) + 1
    end
end

function BattleStatComponent:GetMonsterIDCount(monsterID)
    return self._createMonsterIDRecord[monsterID] or 0
end


function BattleStatComponent:SetCastChainByDimensionDoorState(state)
    self._isCastChainByDimensionDoor = state
end

function BattleStatComponent:IsCastChainByDimensionDoor()
    return self._isCastChainByDimensionDoor
end

function BattleStatComponent:ClearCastChainByDimensionDoorState()
    self._isCastChainByDimensionDoor = false
end

function BattleStatComponent:IsPunishmentRoundExecuted(punishmentRoundCount)
    return self._isPunishmentRoundExecuted[punishmentRoundCount]
end

function BattleStatComponent:MarkPunishmentRoundExecuted(punishmentRoundCount)
    self._isPunishmentRoundExecuted[punishmentRoundCount] = true   
end

function BattleStatComponent:FetchNewDeadMarkAddCount()
    self._deadMarkAddCount = self._deadMarkAddCount + 1
    return self._deadMarkAddCount
end

function BattleStatComponent:AddPlayerSkillHitCount(skillID)
    if not skillID then
        return
    end

    if not self._playerSkillHitCount[skillID] then
        self._playerSkillHitCount[skillID] = 0
    end

    self._playerSkillHitCount[skillID] = self._playerSkillHitCount[skillID] + 1
end

function BattleStatComponent:GetPlayerSkillHitCount(skillID)
    return self._playerSkillHitCount[skillID] or 0
end

---
---@param t number[]
function BattleStatComponent:SetChessDeadPlayerPawnCount(t)
    for _, id in ipairs(t) do
        self._chessDeadPlayerPawnIDChecker[id] = true
    end

    local v = 0
    for id, _ in pairs(self._chessDeadPlayerPawnIDChecker) do
        v = v + 1
    end

    self._chessDeadPlayerPawnCount = v
end

---
function BattleStatComponent:GetChessDeadPlayerPawnCount()
    return self._chessDeadPlayerPawnCount
end

function BattleStatComponent:SetHandleShumolHPUI(val)
    self._handleShumolHPUI=val
end

function BattleStatComponent:GetHandleShumolHPUI()
    return self._handleShumolHPUI
end

function BattleStatComponent:IncWaitInputCount()
    self._waitInputCount = self._waitInputCount + 1
end

function BattleStatComponent:GetWaitInputCount()
    return self._waitInputCount
end

function BattleStatComponent:IncGameRoundCount()
    self._roundCount = self._roundCount + 1
    return self._roundCount
end

function BattleStatComponent:GetGameRoundCount()
    return self._roundCount
end

function BattleStatComponent:GetDamageIndex()
    self._damageIndex = self._damageIndex + 1
    return self._damageIndex
end

function BattleStatComponent:IncPushCommandIndex()
    self._pushCommandIndex = self._pushCommandIndex + 1
    return self._pushCommandIndex
end

function BattleStatComponent:GetPushCommandIndex()
    return self._pushCommandIndex
end

---@param dataA MSummonRefresh
---@param dataB MSummonRefresh
function BattleStatComponent._LessComparerByRefreshID(dataA, dataB)
    local nCompare = dataB.m_nRefreshID - dataA.m_nRefreshID
    return nCompare
end
function BattleStatComponent:Destructor()
end

function BattleStatComponent:Initialize()
end

function BattleStatComponent:SetFirstDeadPetEntity(pet)
    self._firstDeadPetEntity = pet
end

function BattleStatComponent:GetFirstDeadPetEntity()
    return self._firstDeadPetEntity
end

function BattleStatComponent:SetTotalWaveCount(waveCount)
    self._totalWaveCount = waveCount
end

function BattleStatComponent:GetTotalWaveCount()
    return self._totalWaveCount
end

function BattleStatComponent:IsCurWaveHasDeadRefreshMonster()
    return self._curWaveHasDeadRefreshMonsterState
end

function BattleStatComponent:SetCurWaveHasDeadRefreshMonsterState(state)
    self._curWaveHasDeadRefreshMonsterState = state
end

function BattleStatComponent:AddDeadMonsterID(monsterID)
    local monsterDeadParam = MonsterDeadParam:New(monsterID, self:GetCurWaveIndex(), self:GetCurWaveTotalRoundCount())
    table.insert(self._curWaveDeadMonsterIDArray, monsterID)
    table.insert(self._curWaveDeadMonsterParam, monsterDeadParam)
    table.insert(self._totalDeadMonsterIDArray, monsterDeadParam)

    --杀死boss数量
    local cfg = self._world:GetService("Config")
    local isBoss = cfg:GetMonsterConfigData():IsBoss(monsterID)
    if isBoss then
        self._killBossCount = self._killBossCount + 1
        Log.notice("BattleStatComponent:AddDeadMonsterID() - Boss count=", self._killBossCount)
    end
end

function BattleStatComponent:IsMonsterHasDead(monsterID)
    for _, v in ipairs(self._totalDeadMonsterIDArray) do
        if v:GetMonsterID() == monsterID  then
            return true
        end
    end
    return false
end

function BattleStatComponent:GetCurWaveDeadMonsterIDList()
    return self._curWaveDeadMonsterIDArray
end

function BattleStatComponent:GetCurWaveDeadMonsterParam()
    return self._curWaveDeadMonsterParam
end

function BattleStatComponent:GetTotalDeadMonsterIDList()
    return self._totalDeadMonsterIDArray
end
---@private
function BattleStatComponent:_ClearCurWaveDeadMonsterIDList()
    self._curWaveDeadMonsterIDArray = {}
end

function BattleStatComponent:_ClearCurWaveDeadMonsterParam()
    self._curWaveDeadMonsterParam = {}
end

function BattleStatComponent:GetCurWaveIndex()
    return self._curWaveIndex
end

function BattleStatComponent:GetCurWaveRound()
    return self._curWaveLeftRoundCount
end

function BattleStatComponent:SetLevelRound(roundCount)
    self._levelInitRound = roundCount
    self._levelLeftRoundCount = roundCount
end

function BattleStatComponent:InitLevelRound(roundCount)
    self:SetLevelRound(roundCount)
    self._levelTotalRoundCount = 1
end

function BattleStatComponent:GetMazeAddLight()
    return self._mazeAddLight
end

function BattleStatComponent:MazeAddLight(value)
    self._mazeAddLight = self._mazeAddLight + value
end

function BattleStatComponent:InitCurWaveAllMonsterDeadTimes()
    self._curWaveAllMonsterDeadTimes = 0
end

function BattleStatComponent:AddCurWaveAllmonsterDeadTimes()
    self._curWaveAllMonsterDeadTimes = self._curWaveAllMonsterDeadTimes + 1
end

function BattleStatComponent:GetCurWaveAllMonsterDeadTimes()
    return self._curWaveAllMonsterDeadTimes
end

function BattleStatComponent:InitCurWaveRound(roundCount)
    self:SetCurWaveRound(roundCount)
    self._curWaveTotalRoundCount = 1
    self._curWavePunishmentRoundCount = 0
end

function BattleStatComponent:GetLevelTotalRoundCount()
    return self._levelTotalRoundCount
end

function BattleStatComponent:GetLevelLeftRoundCount()
    return self._levelLeftRoundCount
end

function BattleStatComponent:IsFirstRound()
    return self._levelTotalRoundCount == 1
end

function BattleStatComponent:GetPieceRefreshCount()
    return self._pieceRefreshCount
end

function BattleStatComponent:AddPieceRefreshCount(cnt)
    self._pieceRefreshCount = self._pieceRefreshCount + cnt
end

---关卡补充回合
function BattleStatComponent:GetLevelSupplementRoundCount()
    return self._levelSupplementRoundCount
end
function BattleStatComponent:SetLevelSupplementRoundCount(roundCount)
    self._levelSupplementRoundCount = roundCount
end

function BattleStatComponent:SetCurWaveRound(roundCount)
    self._curWaveLeftRoundCount = roundCount
    self._curWaveInitRound = roundCount
end

function BattleStatComponent:SubLevelRound(count)
    self._levelTotalRoundCount = self._levelTotalRoundCount + 1
    if self._levelLeftRoundCount ~= 0 then
        if count <= self._levelLeftRoundCount then
            self._levelLeftRoundCount = self._levelLeftRoundCount - count
        else
            Log.fatal("left_trun_count: " .. self._levelLeftRoundCount .. "not enough to sub:；" .. count)
        end
    end
end

--当前回合数减去count并返回最新回合数
---@param count number
---@return number
function BattleStatComponent:SubCurWaveRound(count)
    self._curWaveTotalRoundCount = self._curWaveTotalRoundCount + 1
    if self._curWaveLeftRoundCount ~= 0 then
        if count <= self._curWaveLeftRoundCount then
            self._curWaveLeftRoundCount = self._curWaveLeftRoundCount - count
        else
            Log.fatal("left_trun_count: " .. self._curWaveLeftRoundCount .. "not enough to sub:；" .. count)
        end
    end
    if self._curWaveLeftRoundCount == 0 then
        self._curWavePunishmentRoundCount = self._curWavePunishmentRoundCount + 1
    end
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Maze then
        local mazeService = self._world:GetService("Maze")
        mazeService:UseLight()
    end
    self:SubLevelRound(count)

    return self._curWaveLeftRoundCount
end

function BattleStatComponent:GetCurWavePunishmentRoundCount()
    return self._curWavePunishmentRoundCount
end
---@return number
---获取当前波次累计的回合数
function BattleStatComponent:GetCurWaveTotalRoundCount()
    return self._curWaveTotalRoundCount
end

function BattleStatComponent:SetCurWaveTotalRoundCount(cnt)
    self._curWaveTotalRoundCount = cnt
end

function BattleStatComponent:SubCurWaveRoundByEffect(count)
    -- 这不是机制上的“过回合”
    -- self._curWaveTotalRoundCount = self._curWaveTotalRoundCount + 1
    if self._curWaveLeftRoundCount ~= 0 then
        if count <= self._curWaveLeftRoundCount then
            self._curWaveLeftRoundCount = self._curWaveLeftRoundCount - count
        else
            Log.warn("left_trun_count: " .. self._curWaveLeftRoundCount .. "not enough to sub:；" .. count)
        end
    end
    -- self._curWavePunishmentRoundCount是废弃需求的遗留变量
    -- if self._curWaveLeftRoundCount == 0 then
    --     self._curWavePunishmentRoundCount = self._curWavePunishmentRoundCount + 1
    -- end

    if self._world.BW_WorldInfo.matchType == MatchType.MT_Maze then
        Log.excpetion(self._className, "通过逻辑效果扣除额外当前回合数的逻辑不能用在秘境规则内，请对过需求后实现这一分支。")
        return self._curWaveLeftRoundCount
    end

    -- 同样，这个不是机制上的“过回合”
    -- self:SubLevelRound(count)
    if self._levelLeftRoundCount ~= 0 then
        if count <= self._levelLeftRoundCount then
            self._levelLeftRoundCount = self._levelLeftRoundCount - count
        else
            Log.warn("left_trun_count: " .. self._levelLeftRoundCount .. "not enough to sub:；" .. count)
        end
    end

    return self._curWaveLeftRoundCount
end

--下一波
function BattleStatComponent:MoveToNextWave()
    self._curWaveIndex = self._curWaveIndex + 1
    self:_ClearCurWaveDeadMonsterIDList()
    self:_ClearCurWaveDeadMonsterParam()
    self:SetCurWaveHasDeadRefreshMonsterState(false)

    self._waveEnterRound[self._curWaveIndex] = self._curWaveLeftRoundCount
end

function BattleStatComponent:GetCurChainIndex()
    return self._curChainIndex
end

function BattleStatComponent:AddChainIndex()
    self._curChainIndex = self._curChainIndex + 1
end

function BattleStatComponent:ResetChainIndex()
    self._curChainIndex = 1
end

--下一回合，无上限，只要没有产生胜负，一直加
function BattleStatComponent:MoveToNextRound(roundCount)
    if not roundCount then
        return self:SubCurWaveRound(1)
    else
        return self:SubCurWaveRound(roundCount)
    end
end

--剩余血量百分比
function BattleStatComponent:GetLeftBlood()
    ---@type Entity
    local heroEntity = self._world:Player():GetLocalTeamEntity()
    if heroEntity == nil then 
        return 0
    end

    ---@type AttributesComponent
    local attrCmpt = heroEntity:Attributes()
    local hp = attrCmpt:GetCurrentHP()
    local maxhp = attrCmpt:CalcMaxHp()

    local blood = hp / maxhp
    return blood
end

function BattleStatComponent:IsFullBlood()
    ---@type Entity
    local heroEntity = self._world:Player():GetLocalTeamEntity()
    if heroEntity == nil then
        return 0
    end

    ---@type AttributesComponent
    local attrCmpt = heroEntity:Attributes()
    local hp = attrCmpt:GetCurrentHP()
    local maxhp = attrCmpt:CalcMaxHp()

    return hp == maxhp
end

---获取玩家血量
function BattleStatComponent:GetPlayerHP()
    ---@type Entity
    local heroEntity = self._world:Player():GetLocalTeamEntity()
    if heroEntity == nil then 
        return 0
    end
    
    ---@type AttributesComponent
    local attrCmpt = heroEntity:Attributes()
    local hp = attrCmpt:GetCurrentHP()
    return hp
end

function BattleStatComponent:GetSuperChainCount()
    return self._superChainCount
end

function BattleStatComponent:GetActiveSkillCount()
    return self._activeSkillCount
end

function BattleStatComponent:GetChainSkillCount()
    return self._chainSkillCount
end

function BattleStatComponent:GetColorSkillCount()
    return self._colorSkillCount
end

function BattleStatComponent:GetKillBossCount()
    return self._killBossCount
end

function BattleStatComponent:GetKillMonsterCount()
    return #self._totalDeadMonsterIDArray
end

function BattleStatComponent:GetOneMatchMaxNum()
    return self._oneMatchMaxNum.one_match_num
end

function BattleStatComponent:GetOneMatchMaxNumType()
    return self._oneMatchMaxNum.element_type
end

function BattleStatComponent:GetTotalMatchNum()
    return self._totalMatchNum
end

function BattleStatComponent:GetElementMatchNum()
    return self._totalElementMatchNum
end

function BattleStatComponent:GetOneActiveSkillKillCount()
    return self._oneActiveSkillKillCount
end

function BattleStatComponent:GetOneChainKillCount()
    return self._oneChainKillCount
end

function BattleStatComponent:GetOneChainNormalAttackCount()
    return self._oneChainMaxNormalAttack
end

--超级连锁数累加
function BattleStatComponent:AddSuperChainCount(teamEntity)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end
    self._superChainCount = self._superChainCount + 1
end

--极光时刻累加
function BattleStatComponent:AddAuroraTimeCount()
    if self._isAuroraTime then
        self._auroraTimeCount = self._auroraTimeCount + 1
    end
end

function BattleStatComponent:GetAuroraTimeCount()
    return self._auroraTimeCount
end

--记录当前回合超级连锁状态
function BattleStatComponent:SetRoundSuperChain(spc)
    self._isSuperChain = spc
end

function BattleStatComponent:IsRoundSuperChain()
    return self._isSuperChain
end

--记录当前回合连线坐标
---@param chainPath Vector2[]
function BattleStatComponent:SetRoundChainPath(chainPath)
    self._chainPath = chainPath
end

function BattleStatComponent:GetRoundChainPath()
    return self._chainPath
end

function BattleStatComponent:SetRoundAuroraTime(value)
    self._isAuroraTime = value
    if value then
        self._world:GetDataLogger():AddDataLog("OnAuroraStart")
    else
        self._world:GetDataLogger():AddDataLog("OnAuroraEnd")
    end
end

function BattleStatComponent:IsRoundAuroraTime()
    return self._isAuroraTime
end
function BattleStatComponent:SetReEnterAuroraTime(value)
    self._isReEnterAuroraTime = value
end

function BattleStatComponent:IsReEnterAuroraTime()
    return self._isReEnterAuroraTime
end

--主动技数量累加
function BattleStatComponent:AddActiveSkillCount(teamEntity)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end
    self._activeSkillCount = self._activeSkillCount + 1
end

--连锁技数量
function BattleStatComponent:AddChainSkillCount(teamEntity,addCount)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end
    self._chainSkillCount = self._chainSkillCount + addCount
end

--颜色技能数量
function BattleStatComponent:AddColorSkillCount(teamEntity)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end
    self._colorSkillCount = self._colorSkillCount + 1
end

--统计转色技数量
function BattleStatComponent:StatisticsColorSkillCount(teamEntity,skillEffectType)
    if
        skillEffectType == SkillEffectType.ConvertGridElement or skillEffectType == SkillEffectType.ManualConvert or
            skillEffectType == SkillEffectType.ResetGridElement or
            skillEffectType == SkillEffectType.PullAround or
            skillEffectType == SkillEffectType.Teleport or
            skillEffectType == SkillEffectType.HitBack
     then
        self:AddColorSkillCount(teamEntity)
        return true
    end
    return false
end

--主动技杀怪数量
function BattleStatComponent:SetOneActiveSkillKillCount(teamEntity,cnt)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end
    if cnt > self._oneActiveSkillKillCount then
        self._oneActiveSkillKillCount = cnt
    end
end

--一次连线杀怪数
function BattleStatComponent:SetOneChainKillCount(teamEntity,cnt)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end
    if cnt > self._oneChainKillCount then
        self._oneChainKillCount = cnt
    end
end

--一次连线普攻数量
function BattleStatComponent:SetOneChainMaxNormalAttack(teamEntity,cnt)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end
    if cnt > self._oneChainMaxNormalAttack then
        self._oneChainMaxNormalAttack = cnt
    end
end

-- 设置各个机关攻击数量 key:trapid value:被打次数
function BattleStatComponent:AddTakeAttackTimesByTrap(trapId, cnt)
    if not self._takeAttackTimesByTrap[trapId] then
        self._takeAttackTimesByTrap[trapId] = cnt
    else
        self._takeAttackTimesByTrap[trapId] = self._takeAttackTimesByTrap[trapId] + cnt
    end
end

-- 获取各个机关攻击数量 获取玩家被机关攻击次数 key:trapid value:被打次数
function BattleStatComponent:GetTakeAttackTimesByTrap()
    return self._takeAttackTimesByTrap
end

-- 设置各个机关攻击伤害 key:trapid value:伤害
function BattleStatComponent:AddTakeAttackDamageByTrap(trapId, damage)
    if not self._takeAttackDamageByTrap[trapId] then
        self._takeAttackDamageByTrap[trapId] = damage
    else
        self._takeAttackDamageByTrap[trapId] = self._takeAttackDamageByTrap[trapId] + damage
    end
end

-- 获取各个机关攻击伤害 key:trapid value:伤害
function BattleStatComponent:GetTakeAttackDamageByTrap()
    return self._takeAttackDamageByTrap
end

-- 设置击碎机关的数量
function BattleStatComponent:AddSmashTrapCount(trapId, count)
    if not self._smashTrapCount[trapId] then
        self._smashTrapCount[trapId] = count
    else
        self._smashTrapCount[trapId] = self._smashTrapCount[trapId] + count
    end
end

-- 获取击碎的机关数量 key:trapid value:击碎数量
function BattleStatComponent:GetSmashTrapCount()
    return self._smashTrapCount
end
---单次连线匹配的格子数
function BattleStatComponent:SetOneMatchMaxNum(teamEntity,elementType, matchNum)
    --只统计本地队伍
    if not self:_IsLocalTeam(teamEntity) then
        return
    end

    local curElementNum = self._totalElementMatchNum[elementType]
    if not curElementNum then
        Log.fatal("格子颜色" .. elementType .. "的连线统计信息未初始化！")
        return
    end

    if self._oneMatchMaxNum.one_match_num < matchNum then
        self._oneMatchMaxNum.one_match_num = matchNum
        self._oneMatchMaxNum.element_type = elementType
    end

    self._totalMatchNum = self._totalMatchNum + matchNum

    self._totalElementMatchNum[elementType] = curElementNum + matchNum
end

function BattleStatComponent:IsLastWave()
    ---重置是否最后一波状态
    local levelConfigData = self._configService:GetLevelConfigData()
    local maxWaveCount = levelConfigData:GetWaveCount()
    if self._curWaveIndex >= maxWaveCount then
        return true
    end
    return false
end

-- 设置是否触发特殊波次刷新
function BattleStatComponent:SetAssignWaveResult(bRefreshSpecialWave)
    if bRefreshSpecialWave == self._AssignWaveResult then
        return
    end
    if bRefreshSpecialWave == true then -- 防止传入非BOOL值
        self._AssignWaveResult = true
    else
        self._AssignWaveResult = false
    end
end

-- 是否触发特殊波次刷新 特殊波次刷新表示此关卡以胜利
function BattleStatComponent:AssignWaveResult()
    return self._AssignWaveResult
end

function BattleStatComponent:SetBonusMatchResult(matchResult)
    self._matchResult = matchResult
    self._world:EventDispatcher():Dispatch(GameEventType.ShowGuideCondition, self._matchResult)
end

---重置所有三星进度
function BattleStatComponent:Set3StarProgress(progressResult)
    self._star3Progress = progressResult
end
---插入或更新单条三星进度
function BattleStatComponent:UpdateA3StarProgress(keyId, value)
    if keyId == nil then
        return
    end
    self._star3Progress[keyId] = value
    return
end
--根据条件Id查询三星奖励进度
function BattleStatComponent:Get3StarProgress(conditionId)
    if conditionId == nil then
        Log.fatal("未找到三星条件进度 id：", conditionId)
        return ""
    end
    local retStr = self._star3Progress[conditionId]
    if retStr == nil then
        Log.fatal("此时尚未结算三星进度")
        return ""
    end
    return retStr
end

function BattleStatComponent:GetBonusMatchResult()
    return self._matchResult
end

---判断是否是真的零回合，因为达到零回合后会进入惩罚阶段
---@return boolean
function BattleStatComponent:IsRealZeroRound()
    if self:GetCurWaveRound() == 0 and self:GetCurWavePunishmentRoundCount() == 1 then
        return true
    end
    return false
end

---判断 关卡 要坚持完全部回合
---@return boolean
function BattleStatComponent:LevelCompleteLimitAllRoundCount()
    ---@type LevelConfigData
    local curLevelData = self._configService:GetLevelConfigData()

    local completeType = curLevelData:GetLevelCompleteConditionType()

    if CompleteConditionType.RoundCountLimit == completeType then
        --波次胜利条件是坚持回合 && 关卡最大回合=胜利条件的回合数
        local curRound = curLevelData:GetLevelRoundCount()
        local conditionParam = curLevelData:GetLevelCompleteConditionParams()[1]
        local configRound =conditionParam[1]
        return curRound == configRound
    elseif CompleteConditionType.AssignWaveAndRandomNextWave == completeType then
        return self:AssignWaveResult()
    elseif CompleteConditionType.RoundCountLimitAndCheckMonsterEscape == completeType then
        local curRound = curLevelData:GetLevelRoundCount()
        local conditionParam = curLevelData:GetLevelCompleteConditionParams()[1]
        local configRound =conditionParam[1]
        return curRound == configRound
    elseif CompleteConditionType.CombinedCompleteCondition == completeType then
        local curWaveIndex = self:GetCurWaveIndex()
        local cfgWave = curLevelData:GetWaveConfig(curWaveIndex)
        local combinedCompleteConditionArgs = cfgWave:GetCombinedCompleteConditionArguments()
        local typeA = combinedCompleteConditionArgs.conditionA
        local typeB = combinedCompleteConditionArgs.conditionB
        local paramA = combinedCompleteConditionArgs.conditionParamA
        local paramB = combinedCompleteConditionArgs.conditionParamB
        if typeA == CompleteConditionType.RoundCountLimit then
            local curRound = curLevelData:GetLevelRoundCount()
            return curRound == paramA[1][1]
        elseif typeA == CompleteConditionType.AssignWaveAndRandomNextWave then
            return self:AssignWaveResult()
        end

        if typeB == CompleteConditionType.RoundCountLimit then
            local curRound = curLevelData:GetLevelRoundCount()
            return curRound == paramB[1][1]
        elseif typeB == CompleteConditionType.AssignWaveAndRandomNextWave then
            return self:AssignWaveResult()
        end
    end

    return false
end

---是否还有下个波次
function BattleStatComponent:HasNextWave()
    local curWaveNum = self:GetCurWaveIndex()
    local levelConfigData = self._configService:GetLevelConfigData()
    local maxWaveCount = levelConfigData:GetWaveCount()
    if curWaveNum < maxWaveCount then
        return true
    end

    return false
end

function BattleStatComponent:AddTotalDropAssets(assetID, count)
    local asset = self._totalDropAssets[assetID]
    if not asset then
        asset = RoleAsset:New()
        asset.assetid = assetID
        asset.count = count
    else
        asset.count = asset.count + count
    end
    self._totalDropAssets[assetID] = asset
end

function BattleStatComponent:GetTotalDropAssets()
    return self._totalDropAssets
end

function BattleStatComponent:AddDropRoleAsset(assetid, count)
    self:AddTotalDropAssets(assetid, count)

    for k, v in ipairs(self._dropRoleAssetList) do
        if v.assetid == assetid then
            v.count = count + v.count
            return
        end
    end
    local asset = RoleAsset:New()
    asset.assetid = assetid
    asset.count = count
    table.insert(self._dropRoleAssetList, asset)
end
---获得想要参数类型的掉落物数量
---@param assetID number
function BattleStatComponent:GetDropRoleAsset(assetID)
    if not assetID then
        return self._dropRoleAssetList
    end
    for k, v in ipairs(self._dropRoleAssetList) do
        if v.assetid == assetID then
            return v.count
        end
    end
    return 0
end

function BattleStatComponent:GetArchivedDrops()
    local drops={}
    drops.noDoubleList = self._dropRoleAssetNoDoubleList
    drops.assetList = self._dropRoleAssetList
    drops.totalList = self._totalDropAssets
    return drops
end

function BattleStatComponent:SetArchivedDrops(drops)
    if not drops then
        return
    end
    
    self._dropRoleAssetList = drops.assetList
    self._dropRoleAssetNoDoubleList = drops.noDoubleList
    self._totalDropAssets = drops.totalList
end

function BattleStatComponent:AddDropRoleAssetNoDouble(assetid, count)
    self:AddTotalDropAssets(assetid, count)

    for k, v in ipairs(self._dropRoleAssetNoDoubleList) do
        if v.assetid == assetid then
            v.count = count + v.count
            return
        end
    end
    local asset = RoleAsset:New()
    asset.assetid = assetid
    asset.count = count
    table.insert(self._dropRoleAssetNoDoubleList, asset)
end
---获得想要参数类型的掉落物数量
---@param assetID number
function BattleStatComponent:GetDropRoleAssetNoDouble(assetID)
    if not assetID then
        return self._dropRoleAssetNoDoubleList
    end
    for k, v in ipairs(self._dropRoleAssetNoDoubleList) do
        if v.assetid == assetID then
            return v.count
        end
    end
    return 0
end

function BattleStatComponent:CollectDrop(dropItemID)
    dropItemID = dropItemID or -1
    if not self._collectDropNumItemIDDic[dropItemID] then
        self._collectDropNumItemIDDic[dropItemID] = 0
    end
    self._collectDropNumItemIDDic[dropItemID] = self._collectDropNumItemIDDic[dropItemID] + 1
    self._collectDropNum = self._collectDropNum + 1
    return self._collectDropNum
end

function BattleStatComponent:GetDropCollectNum()
    return self._collectDropNum
end

function BattleStatComponent:GetDropCollectNumByItemID(itemID)
    itemID = itemID or -1
    return self._collectDropNumItemIDDic[itemID] or 0
end

function BattleStatComponent:SetDropCollectNum(num)
    self._collectDropNum = num
end

---设置关卡是否完成
function BattleStatComponent:SetBattleLevelResult(battleLevelResult)
    self._battleLevelResult = battleLevelResult
end

---查询关卡是否完成
function BattleStatComponent:GetBattleLevelResult()
    return self._battleLevelResult
end

---设置波次是否完成
function BattleStatComponent:SetBattleWaveResult(battleWaveResult)
    self._battleWaveResult = battleWaveResult
    self._passWaveList[self:GetCurWaveIndex()] = battleWaveResult
end

---查询波次结果
function BattleStatComponent:GetBattleWaveResult()
    return self._battleWaveResult
end

function BattleStatComponent:IsMonsterShowBannerCurWave(monsterID)
    local wave = self:GetCurWaveIndex()
    if not self._deadMonsterShowBannerList[wave] then
        return false
    else
        local deadList = self._deadMonsterShowBannerList[wave]
        return table.icontains(deadList, monsterID)
    end
end

function BattleStatComponent:AddDeadMonsterShowBanner(monsterID)
    local wave = self:GetCurWaveIndex()
    if not self._deadMonsterShowBannerList[wave] then
        self._deadMonsterShowBannerList[wave] = {}
    end
    table.insert(self._deadMonsterShowBannerList[wave], monsterID)
end

---获取当前波次回合数
function BattleStatComponent:GetCurWaveRoundNum()
    return self._curWaveTotalRoundCount
end

---这个是
---@param matchResult MatchResult
function BattleStatComponent:SetBattleMatchResult(matchResult)
    self._battleResult = matchResult
end

---@return MatchResult
function BattleStatComponent:GetBattleMatchResult()
    return self._battleResult
end

function BattleStatComponent:GetAutoFight()
    return self._autoFight
end

function BattleStatComponent:SetAutoFight(autoFight)
    self._autoFight = autoFight or false
    self:SetEverAutoFight()
    if not autoFight then
        self._world:GetDataLogger():AddDataLog("OnCancelAutoFight")
    end
end

function BattleStatComponent:GetEverAutoFight()
    return self._everAutoFight
end

function BattleStatComponent:SetEverAutoFight()
    self._everAutoFight = 1
end

function BattleStatComponent:GetLastDoActiveSkillRound(petPstID,extraSkillIndex)
    local recordSkillIndex = extraSkillIndex or 0
    if not self._lastDoActiveSkillRound[petPstID] then
        return
    end
    return self._lastDoActiveSkillRound[petPstID][recordSkillIndex]
end

function BattleStatComponent:SetLastDoActiveSkillRound(petPstID, round, extraSkillIndex)
    local recordSkillIndex = extraSkillIndex or 0
    if not self._lastDoActiveSkillRound[petPstID] then
        self._lastDoActiveSkillRound[petPstID] = {}
    end
    self._lastDoActiveSkillRound[petPstID][recordSkillIndex] = round
    --self._lastDoActiveSkillRound[petPstID] = round
end
function BattleStatComponent:GetCurRoundDoActiveSkillTimes(petPstID)
    return self._curRoundDoActiveSkillTimes[petPstID] or 0
end

function BattleStatComponent:RecordCurRoundDoActiveSkillTimes(petPstID)
    if self._curRoundDoActiveSkillTimes[petPstID] then
        local curTimes = self._curRoundDoActiveSkillTimes[petPstID]
        self._curRoundDoActiveSkillTimes[petPstID] = curTimes + 1
    else
        self._curRoundDoActiveSkillTimes[petPstID] = 1
    end
end
function BattleStatComponent:ClearCurRoundDoActiveSkillTimes()
    self._curRoundDoActiveSkillTimes = {}
end

function BattleStatComponent:GetPetDoActiveSkillRecord(petPstID, round)
    if not self._petDoActiveSkillRecord[petPstID] then
        return {}
    end
    return self._petDoActiveSkillRecord[petPstID][round]
end

function BattleStatComponent:SetPetDoActiveSkillRecord(petPstID, round, skillID)
    if not self._petDoActiveSkillRecord[petPstID] then
        self._petDoActiveSkillRecord[petPstID] = {}
    end
    if not self._petDoActiveSkillRecord[petPstID][round] then
        self._petDoActiveSkillRecord[petPstID][round] = {}
    end

    table.insert(self._petDoActiveSkillRecord[petPstID][round], skillID)
end

function BattleStatComponent:GuideShowStarTime(missionId)
    if missionId and missionId > 0 then
        if not self.starTimeLimitMissionId then
            self.starTimeLimitMissionId = Cfg.cfg_guide_const["guide_star_time_limit_mission"].IntValue
        end
        return missionId > self.starTimeLimitMissionId
    else
        return true
    end
end

function BattleStatComponent:GetAutoSummonIndex()
    return self.m_nAutoSummon_Index
end
function BattleStatComponent:SetAutoSommonIndex(nIndex)
    self.m_nAutoSummon_Index = nIndex
end

function BattleStatComponent:GetAutoSummonMonsterList()
    return self.m_listSummonMonsterID
end
function BattleStatComponent:GetAutoSummonList()
    return self.m_listAutoSummon
end

function BattleStatComponent:GetAutoSummonLevel()
    return self.m_nAutoSummonLevel
end
function BattleStatComponent:SetAutoSummonLevel(nLevel)
    self.m_nAutoSummonLevel = nLevel
end

function BattleStatComponent:AddTotalChainNum()
    self._totalChainNum = self._totalChainNum + 1
end

function BattleStatComponent:GetTotalChainNum()
    return self._totalChainNum
end
-------------------------------------

--------------------
---@class MSummonRefresh : Object
_class("MSummonRefresh", Object)
MSummonRefresh = MSummonRefresh

function MSummonRefresh:Constructor(nRefreshID)
    self.m_nSummonIndex = 0
    self.m_nLevelID = self:_FindLevelID(nRefreshID) ---m_nLevelID不同时要变更关卡场景
    self.m_nRefreshID = nRefreshID ---cfg_refresh主键：可能会有很多个MSummonRefresh记录是一样的
    self.m_nRefreshID_Monster = 0 ---cfg_refresh_monster 主键
    ---@type LevelMonsterRefreshParam
    self.m_cfgRefreshMonster = nil
    self.m_nRefreshID_Trap = 0 ---cfg_refresh_trap主键
    ---@type LevelMonsterRefreshParam
    self.m_cfgRefreshTrap = nil
    self.m_stLevelName = ""
    self.m_nAutoAttack = nil
end
---通过怪物刷新ID+机关刷新ID，反向查找格子生成配置GridGenID
function MSummonRefresh:_FindLevelID(nRefreshID)
    local listLevelConfig = Cfg.cfg_level()
    for nLevelID, cfgLevel in pairs(listLevelConfig) do
        for key, nWaveID in ipairs(cfgLevel.MonsterWave) do
            if nWaveID == nRefreshID then
                return nLevelID
            end
        end
    end
end
-------------------------------------
---@return MSummonData[]
function BattleStatComponent:_InitRefreshMonster(nRefreshID)
    local cfgRefreshMonster = Cfg.cfg_refresh_monster[nRefreshID]
    if cfgRefreshMonster then
        local levelMonsterRefreshParam = LevelMonsterRefreshParam:New(self._world)
        local listID = levelMonsterRefreshParam:ParseMonsterRefreshParam(cfgRefreshMonster)
        -- local listPos = levelMonsterRefreshParam:GetMonsterPosArray()
        return levelMonsterRefreshParam
    end
    return nil
end
---@return MSummonData[]
function BattleStatComponent:_InitRefreshTrap(nRefreshID)
    local cfgRefreshMonster = Cfg.cfg_refresh_trap[nRefreshID]
    if cfgRefreshMonster then
        local levelMonsterRefreshParam = LevelMonsterRefreshParam:New(self._world)
        local listSummon = levelMonsterRefreshParam:ParseTrapRefreshParam(cfgRefreshMonster)
        return levelMonsterRefreshParam
    end
    return nil
end
---用cfg_refresh表的数据生成自动召唤的 MonsterID、TrapID候选
function BattleStatComponent:InitAutoSommonList(nMaxCount)
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    self.m_listAutoSummon:Clear()
    ---LevelConfigData
    local cfgRefresh = Cfg.cfg_refresh()
    for key, value in pairs(cfgRefresh) do
        local nAutoSummon = value.AutoSummon
        if nAutoSummon and nAutoSummon > 0 then
            local listRefresh_Monster = value.TrapRefreshIDList
            local listRefresh_Trap = value.MonsterRefreshIDList
            local nMaxCount = math.max(table.count(listRefresh_Monster), table.count(listRefresh_Trap))
            for i = 1, nMaxCount do ---处理每一条刷新配置
                local refreshData = MSummonRefresh:New(key)
                refreshData.m_stLevelName = value.desc
                refreshData.m_nAutoAttack = value.AutoAttack or 0
                ---刷新怪物
                local nRefreshID_Monster = listRefresh_Monster[i]
                if nRefreshID_Monster then
                    refreshData.m_nRefreshID_Monster = nRefreshID_Monster
                    refreshData.m_cfgRefreshMonster = self:_InitRefreshMonster(nRefreshID_Monster)
                end
                ---刷新机关
                local nRefreshID_Trap = listRefresh_Trap[i]
                if nRefreshID_Trap then
                    refreshData.m_nRefreshID_Trap = nRefreshID_Trap
                    refreshData.m_cfgRefreshTrap = self:_InitRefreshTrap(nRefreshID_Trap)
                end
                refreshData.m_nSummonIndex = table.count(self.m_listAutoSummon)
                self.m_listAutoSummon:Insert(refreshData)
            end
        end
    end
end
-------------------------------------
function BattleStatComponent:GetAutoSommonTeam()
    return self.m_nAutoSummon_TeamIndex
end
function BattleStatComponent:SetAutoSommonTeam(nIndex)
    self.m_nAutoSummon_TeamIndex = nIndex
end

--region TriggerDimensionFlag 触发任意门State标记
function BattleStatComponent:GetTriggerDimensionFlag()
    return self._triggerDimensionFlag
end
function BattleStatComponent:SetTriggerDimensionFlag(flag)
    self._triggerDimensionFlag = flag
end
TriggerDimensionFlag = {
    None = 0,
    ChainAttack = 1, --连锁
    WaitInput = 2, --输入
    RoundResult = 3 --回合结算
}
--endregion

function BattleStatComponent:SetNormalAttackKillCount(count)
    self._normalAttackKillCount = count
end

function BattleStatComponent:GetNormalAttackKillCount()
    return self._normalAttackKillCount
end

function BattleStatComponent:GetTeamLeaderChangeNum()
    return self._changeTeamLeaderNum
end

function BattleStatComponent:AddTeamLeaderChangeNum()
    self._changeTeamLeaderNum = self._changeTeamLeaderNum + 1
end

function BattleStatComponent:GetPassiveTeamLeaderChangeNum()
    return self._passiveChangeTeamLeaderNum
end

function BattleStatComponent:AddPassiveTeamLeaderChangeNum()
    self._passiveChangeTeamLeaderNum = self._passiveChangeTeamLeaderNum + 1
end

function BattleStatComponent:SaveProtectTrap(trapId, pos, dir)
    if not self._protectTrap then
        self._protectTrap = {}
    end
    self._protectTrap[#self._protectTrap + 1] = {trapID = trapId, pos = pos, dir = dir}
end

function BattleStatComponent:GetSavedProtectTrap()
    return self._protectTrap
end
----@param intensifyParam BuffIntensifyParam
function BattleStatComponent:AddBuffIntensifyParam(intensifyParam)
    for _, param in ipairs(intensifyParam) do
        if not self._exChangeBuffMap[param.BuffID] then
            self._exChangeBuffMap[param.BuffID] = param
        else
            Log.fatal("Already Has Buff ExchangeConfig BuffID:", param.BuffID, "Trace:", Log.traceback())
        end
    end
end
---@return BuffIntensifyParam
function BattleStatComponent:GetBuffIntensifyParam(buffID)
    if self._exChangeBuffMap[buffID] then
        return self._exChangeBuffMap[buffID]
    end
end

function BattleStatComponent:AddBuffEquipRefineParam(intensifyParam)
    for _, param in ipairs(intensifyParam) do
        self._exChangeBuffMap[param.BuffID] = param
    end
end

function BattleStatComponent:AddPlayerBeHitCount(cnt)
    self._playerBeHitCount = self._playerBeHitCount + cnt
end

function BattleStatComponent:GetPlayerBeHitCount()
    return self._playerBeHitCount
end

function BattleStatComponent:SetHeroLastAttackMonster(t)
    self._heroLastAttackMonster = t
end
function BattleStatComponent:GetHeroLastAttackMonster()
    return self._heroLastAttackMonster
end

function BattleStatComponent:SetFirstWaveMonsterIDList(monsterEntityList)
    for _, entity in ipairs(monsterEntityList) do
        table.insert(self._firstWaveMonsterIDList,entity:GetID())
    end
end

function BattleStatComponent:GetFirstWaveMonsterIDList()
    return self._firstWaveMonsterIDList
end

function BattleStatComponent:SetFirstWaveTrapIDList(trapEntityList)
    for i, entity in ipairs(trapEntityList) do
        table.insert(self._firstWaveTrapIDList,entity:GetID())
    end
end

function BattleStatComponent:GetFirstWaveTrapIDList()
    return self._firstWaveTrapIDList
end

function BattleStatComponent:SetRoundBeginPlayerPos(pos)
    self._roundBeginPlayerPos = pos
end
---@type Vector2
function BattleStatComponent:GetRoundBeginPlayerPos()
    return self._roundBeginPlayerPos
end
----服务端用来校验使用
function BattleStatComponent:IsWavePass(waveIndex)
    if self._curWaveIndex >= waveIndex then
        local waveResult =self._passWaveList[waveIndex]
        ---这里如果收到一个没通过波次的通过波次消息，基本上就是改代码了。
        if not waveResult then
            Log.fatal("[SyncLog],type:", BattleFailedType.WavePassInvalid, " info:", "wave: ",waveIndex," NotPass")
        end
        return waveResult
    end
    return false
end
---暂时只有世界Boss使用
function BattleStatComponent:AddMonsterBeHitDamageValue(entityID, value,skillID)
    if value > BattleConst.SingleDamageMaxValue then
        if EDITOR then 
            Log.exception("[SyncLog],type:",BattleFailedType.SingleDamageTooLarge," SingleDamageValue:",value," SkillID:",skillID)
        else
            Log.fatal("[SyncLog],type:",BattleFailedType.SingleDamageTooLarge," SingleDamageValue:",value," SkillID:",skillID)
        end
        value =0
    end
    if not self._monsterBeHitDamageValue[entityID] then
        self._monsterBeHitDamageValue[entityID] =0
    end
    self._monsterBeHitDamageValue[entityID] = self._monsterBeHitDamageValue[entityID] + value
    --Log.fatal("AddDamage：",value," Total:",self._monsterBeHitDamageValue[entityID])
end
---暂时只有世界Boss使用
function BattleStatComponent:SubMonsterBeHitDamageValue(entityID,value)
    if not self._monsterBeHitDamageValue[entityID] then
        self._monsterBeHitDamageValue[entityID] =0
    end
    self._monsterBeHitDamageValue[entityID] = self._monsterBeHitDamageValue[entityID] - value
    --Log.fatal("SubDamage：",value," Total:",self._monsterBeHitDamageValue[entityID])
end
---暂时只有世界Boss使用
function BattleStatComponent:GetTotalMonsterBeHitDamageValue()
    local totalDamage = 0
    for k, damage in pairs(self._monsterBeHitDamageValue) do
        totalDamage = damage + totalDamage
    end
    --Log.fatal("TotalDamage：",totalDamage)
    return totalDamage
end
function BattleStatComponent:GetMainWorldBossBeHitDamageValue()
    local mainWorldBossID = self:GetMainWorldBossID()
    if mainWorldBossID then
        local dmg = self:GetMonsterBeHitDamageValue(mainWorldBossID)
        return dmg
    else
        return 0
    end
end
function BattleStatComponent:GetMonsterBeHitDamageValue(entityID)
    local totalDamage = self._monsterBeHitDamageValue[entityID]
    return totalDamage or 0
end

function BattleStatComponent:SetLastAntiTriggerEntityID(id)
    self._lastAntiTriggerEntityID = id
end

function BattleStatComponent:GetLastAntiTriggerEntityID() return self._lastAntiTriggerEntityID end

function BattleStatComponent:GetLastActiveSkillID()
    return self._lastActiveSkillID
end

function BattleStatComponent:SetLastActiveSkillID(activeSkillID)
    self._lastActiveSkillID = activeSkillID
end

function BattleStatComponent:GetLastActiveSkillCasterID() return self._lastActiveSkillCasterID end
function BattleStatComponent:SetLastActiveSkillCasterID(casterID)
    self._lastActiveSkillCasterID = casterID
end

function BattleStatComponent:GetCurWaveEnterRound()
    return self._waveEnterRound[self._curWaveIndex]
end

function BattleStatComponent:GetCurWaveTotalRound()
    return self._curWaveLeftRoundCount - self._waveEnterRound[self._curWaveIndex]
end

---@param entity Entity
function BattleStatComponent:AddDeadMonsterBuffInfo(entity)
    local cBuff = entity:BuffComponent()
    local tBuffInstance = cBuff:GetBuffArray()
    local tBuffID = {}
    for _, ins in ipairs(tBuffInstance) do
        if not ins:IsUnload() then
            table.insert(tBuffID, ins:BuffID())
        end
    end
    local monsterID = entity:MonsterID():GetMonsterID()
    local buffInfo = {
        entityID = entity:GetID(),
        buffIDs = tBuffID
    }
    if not self._curWaveDeadMonsterBuffTable[monsterID] then
        self._curWaveDeadMonsterBuffTable[monsterID] = {}
    end
    table.insert(self._curWaveDeadMonsterBuffTable, buffInfo)

    if not self._totalDeadMonsterBuffTable[monsterID] then
        self._totalDeadMonsterBuffTable[monsterID] = {}
    end
    table.insert(self._totalDeadMonsterBuffTable[monsterID], buffInfo)
end

---
function BattleStatComponent:GetTotalDeadMonsterBuffInfo()
    return self._totalDeadMonsterBuffTable
end

--region 小秘境相关

---设置波次结束时选择的圣物(客户端ui记录)
---@param waveIndex number 波次序号
---@param relicID number 圣物ID
function BattleStatComponent:SetWaveChooseRelic(waveIndex, relicID)
    if not self._waveRelicIDDic[waveIndex] then
        self._waveRelicIDDic[waveIndex] = relicID
        table.insert(self._waveRelicIDList, relicID)
    else
        Log.error("MiniMaze 波次圣物已设置完毕")
    end
end

---@param relicID number 圣物ID
function BattleStatComponent:SetChooseRelic(relicID)
    table.insert(self._waveRelicIDList, relicID)
end

function BattleStatComponent:GetWaveChooseRelic(waveIndex)
    return self._waveRelicIDDic[waveIndex] or 0
end

function BattleStatComponent:GetAllMiniMazeRelicList()
    local relicIDArray = table.cloneconf(self._waveRelicIDList)
    return relicIDArray
end

---设置波次结束时选择的伙伴(客户端ui记录)
---@param waveIndex number 波次序号
---@param partner number 伙伴ID
function BattleStatComponent:SetWaveChoosePartner(waveIndex, partner)
    if not self._wavePartnerDic[waveIndex] then
        self._wavePartnerDic[waveIndex] = partner
        table.insert(self._wavePartnerIDList, partner)
    else
        Log.error("MiniMaze 波次伙伴已设置完毕")
    end
end

function BattleStatComponent:GetWaveChoosePartner(waveIndex)
    return self._wavePartnerDic[waveIndex] or 0
end

function BattleStatComponent:GetAllMiniMazePartnerList()
    local array = table.cloneconf(self._wavePartnerIDList)
    return array
end

---设置波次结束时供选择的伙伴
---@param waveIndex number 波次序号
---@param partner number 伙伴ID
function BattleStatComponent:SetWaveOptionalPartnerIDList(waveIndex, partnerIDList)
    if not self._waveOptionalPartnerListDic[waveIndex] then
        self._waveOptionalPartnerListDic[waveIndex] = partnerIDList
    else
    end
end

function BattleStatComponent:GetWaveOptionalPartnerIDList(waveIndex)
    return self._waveOptionalPartnerListDic[waveIndex]
end

---设置波次结束时已被随机的圣物ID
---@param groupID number 圣物组ID
---@param relicIDList number[] 圣物ID列表
function BattleStatComponent:SetInvalidRelicIDList(groupID, relicIDList)
    if not self._relicGroupInvalidIDDic[groupID] then
        self._relicGroupInvalidIDDic[groupID] = {}
    end

    table.appendArray(self._relicGroupInvalidIDDic[groupID], relicIDList)
end

function BattleStatComponent:GetInvalidRelicIDList(groupID)
    local invalidArray = self._relicGroupInvalidIDDic[groupID]
    local cloneArray = table.cloneconf(invalidArray)
    return cloneArray
end

---添加弃选的伙伴ID
---@param partnerID number 伙伴ID
function BattleStatComponent:AddAbandonedPartnerIDList(partnerIDList)
    for _, partnerID in ipairs(partnerIDList) do
        table.insert(self._wavePartnerAbandonedList,partnerID)
    end
end

function BattleStatComponent:GetAbandonedPartnerIDList()
    return self._wavePartnerAbandonedList
end
---设置等待应用的圣物ID
---@param relicID number 圣物ID
---@param isOpening boolean 是否是开局圣物
---@param partnerID number 伙伴ID
function BattleStatComponent:SetWaveWaitApplyAward(relicID, isOpening,partnerID)
    self._waveWaitApplyRelicID = relicID
    self._waveWaitApplyRelicIsOpening = isOpening
    self._waveWaitApplyPartnerID = partnerID
end
---获取等待应用的波次奖励
function BattleStatComponent:GetWaveWaitApplyAward()
    return self._waveWaitApplyRelicID,self._waveWaitApplyRelicIsOpening,self._waveWaitApplyPartnerID
end
---清除等待应用的波次奖励
function BattleStatComponent:ClearWaveWaitApplyAward()
    self._waveWaitApplyRelicID = 0
    self._waveWaitApplyRelicIsOpening = false
    self._waveWaitApplyPartnerID = 0
end
---设置等待应用的圣物ID
---@param waveIndex number 波次序号
---@param relicID number 圣物ID
function BattleStatComponent:SetWaveChoosePartner(waveIndex, partner)
end
--endregion

function BattleStatComponent:AddScanTrapIDInMatch(id)
    if not table.icontains(self._allLocalTeamScanTrapIDInMatch, id) then
        table.insert(self._allLocalTeamScanTrapIDInMatch, id)
    end
end

function BattleStatComponent:GetAllScanTrapIDInMatch()
    return self._allLocalTeamScanTrapIDInMatch
end

function BattleStatComponent:AddTrapIDByCasterEntityID(trapID, casterEntityID)
    if not self._trapIDBySummonCasterEntityID[casterEntityID] then
        self._trapIDBySummonCasterEntityID[casterEntityID] = {}
    end

    if not table.icontains(self._trapIDBySummonCasterEntityID[casterEntityID], trapID) then
        table.insert(self._trapIDBySummonCasterEntityID[casterEntityID], trapID)
    end
end

function BattleStatComponent:IsTrapSummonedByCasterBefore(trapID, casterEntityID)
    if not self._trapIDBySummonCasterEntityID[casterEntityID] then
        return false
    end

    return table.icontains(self._trapIDBySummonCasterEntityID[casterEntityID], trapID)
end
---用于统计时排除黑拳赛敌方队伍
function BattleStatComponent:_IsLocalTeam(teamEntity)
    local localTeamEntity = self._world:Player():GetLocalTeamEntity()
    if localTeamEntity and teamEntity and (localTeamEntity:GetID() ~= teamEntity:GetID()) then
        return false
    end
    return true--如果teamEntity为空，也按是本地队伍处理，避免意外影响原有统计
end

function BattleStatComponent:GetMonsterEscapeNum()
    return self._monsterEscapeNum
end

function BattleStatComponent:AddMonsterEscapeNum(count)
    local addNum = count or 1
    self._monsterEscapeNum = self._monsterEscapeNum + 1
end

function BattleStatComponent:AppendCombinedConditionRecord(resultA, resultB)
    table.insert(self._combinedConditionRecords, {
        resultA = resultA,
        resultB = resultB
    })
end

function BattleStatComponent:GetCombinedConditionRecord()
    return self._combinedConditionRecords
end
function BattleStatComponent:GetMainWorldBossID()
    return self._mainWorldBossID
end
function BattleStatComponent:SetMainWorldBossID(id)
    self._mainWorldBossID = id
end

---@return BattleStatComponent
function MainWorld:BattleStat()
    if EDITOR and CHECK_RENDER_ACCESS_LOGIC  then
        local debugInfo = debug.getinfo(2, "S")
        local filePath = debugInfo.short_src
        local renderIndex = string.find(filePath, "_r.lua")
        if renderIndex ~= nil then
            Log.exception("render file :", filePath, " call BattleStat() ", Log.traceback())
            return nil
        end
    end
    return self:GetUniqueComponent(self.BW_UniqueComponentsEnum.BattleStat)
end

function MainWorld:HasBattleStat()
    return self:GetUniqueComponent(self.BW_UniqueComponentsEnum.BattleStat) ~= nil
end

function MainWorld:AddBattleStat()
    local index = self.BW_UniqueComponentsEnum.BattleStat
    local component = BattleStatComponent:New(self)
    component:Initialize()
    self:SetUniqueComponent(index, component)
end


function MainWorld:RemoveBattleStat()
    if self:HasBattleStat() then
        self:SetUniqueComponent(self.BW_UniqueComponentsEnum.BattleStat, nil)
    end
end
