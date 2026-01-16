--[[------------------------------------------------------------------------------------------
    WaveEnterSystem：初始化波次状态
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class WaveEnterSystem:MainStateSystem
_class("WaveEnterSystem", MainStateSystem)
WaveEnterSystem = WaveEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function WaveEnterSystem:_GetMainStateID()
    return GameStateID.WaveEnter
end

---@param TT token 协程识别码，服务端环境下是nil
function WaveEnterSystem:_OnMainStateEnter(TT)
    ---初始化battleState状态，其他依赖波次进入的初始化逻辑也可以放在这里
    self:_DoLogicInitWaveBattleState()

    ---波次开始时的表现
    self:_DoRenderWaveInfo(TT)

    --极光时刻关闭
    self:_DoLogicCloseAuroraTime()
    self:_DoRenderCloseAuroraTime(TT)

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local waveNum = battleStatCmpt:GetCurWaveIndex()
    ---调用notify消息
    self:_DoLogicNotifyWaveEnter(waveNum)
    ---通知进入波次
    self:_DoRenderNotifyWaveEnter(TT, waveNum)

    ---新生成的机关Entity列表
    local spawnTraps = self:_DoLogicCreateWaveTraps()

    ---新创建机关的表现过程
    local showTrapsTaskID = self:_DoRenderShowWaveTraps(TT, spawnTraps)

    ---创建怪物前执行的表现，比如UI上的boss预警信息等
    self:_DoRenderPreShowMonster(TT)

    ---逻辑上创建怪物
    local spawnMonsters, hitbackResult = self:_DoLogicCreateWaveMonsters()

    ---创建的怪物如果是强制创建并击退身形内的玩家MonsterRefreshPosType.PositionHitBack 。会返回一个击退结果，需要表现击退过程
    if hitbackResult then
        self:_DoRenderRefreshMonsterHitBackTeam(TT, hitbackResult)
    end

    ---新创建怪物的表现过程
    self:_DoRenderShowWaveMonsters(TT, spawnMonsters)

    local waitTaskIDList = {}
    if showTrapsTaskID ~= nil then
        table.insert(waitTaskIDList, showTrapsTaskID)
    end

    self:_WaitTasksEnd(TT, waitTaskIDList) ---波次进入流程要等待怪物和机关刷新完成，服务端会直接跳过

    ---波次会有剧情提示，客户端实现
    self:_DoRenderWaveEnterInnerStory(TT)

    ---调用notify消息
    self:_DoLogicNotifyWaveStart(waveNum)

    ---通知波次开始
    self:_DoRenderNotifyWaveStart(TT, waveNum)

    ---怪物行动后，刷新此阶段的怪物死亡
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)
    ---计算前置行为
    self:_DoLogicCalcPreMove()
    ---表现前置行为
    self:_DoRenderPlayPreMove(TT)

    ---切换主状态机状态，前后台一致
    self:_DoLogicSwitchFsmState()
end

---初始化一些组件的状态
function WaveEnterSystem:_DoLogicInitWaveBattleState()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type number
    local waveNum = battleStatCmpt:GetCurWaveIndex()
    Log.notice("EnterWave WaveNum:", waveNum)

    local levelRoundCount = battleStatCmpt:GetLevelLeftRoundCount()
    if battleStatCmpt:AssignWaveResult() then
        local configService = self._world:GetService("Config")
        ---@type LevelConfigData
        local levelConfigData = configService:GetLevelConfigData()
        local l_arrAssignWaveParams = levelConfigData:GetLevelCompleteConditionParams()[1]
        local l_round_num = l_arrAssignWaveParams[LevelCompleteAssignWaveParamExp.RoundNum]
        if l_round_num ~= nil then
            battleStatCmpt:InitCurWaveRound(l_round_num)
        else
            battleStatCmpt:InitCurWaveRound(levelRoundCount)
        end

        self._world:EventDispatcher():Dispatch(GameEventType.UpdateRoundCount, battleStatCmpt:GetCurWaveRound())
    else
        battleStatCmpt:InitCurWaveRound(levelRoundCount)
    end
    battleStatCmpt:InitCurWaveAllMonsterDeadTimes()

    --秘境存档关卡胜利条件还原
    self:_DoLogicLoadArchievedBattle()

    ---通知表现数据更新
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    local isExit = battleSvc:IsCurWaveExit()
    local exitPos = battleSvc:CurWaveExitPos()

    local data = DataWaveEnterResult:New(waveNum, isExit, exitPos)

    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

function WaveEnterSystem:_DoLogicLoadArchievedBattle()
    local battle_archive = self._world:GetService("Maze"):GetBattleArchive()
    if battle_archive then
        --关卡胜利条件进度恢复
        ---@type CompleteConditionService
        local ccsvc = self._world:GetService("CompleteCondition")
        local cfgsvc = self._world:GetService("Config")
        local cond = cfgsvc:GetLevelConfigData():GetLevelCompleteConditionType()
        if battle_archive.completion.cond == cond then
            -- 恢复完成条件
            ccsvc:SetArchivedData(cond, battle_archive.completion.data)
        end
        --掉落物存档恢复
        self._world:BattleStat():SetArchivedDrops(battle_archive.drops)
    end
end

---创建波次机关
---@return array 新创建的机关数组
function WaveEnterSystem:_DoLogicCreateWaveTraps()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    ---@type number
    local waveNum = battleStatCmpt:GetCurWaveIndex()

    ---其实只需要trapEntity
    local eTraps = {}

    if waveNum ~= 1 then
        ---@type LogicEntityService
        local entityService = self._world:GetService("LogicEntity")
        ---服务端以及非第一波次的客户端在这里创建怪物和机关
        eTraps = entityService:CreateWaveTraps(waveNum)
    else
        local trapIDList = self._world:BattleStat():GetFirstWaveTrapIDList()
        for _, id in ipairs(trapIDList) do
            local entity = self._world:GetEntityByID(id)
            table.insert(eTraps, entity)
        end
    end

    return eTraps
end

---创建波次怪物
function WaveEnterSystem:_DoLogicCreateWaveMonsters()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type number
    local waveNum = battleStatCmpt:GetCurWaveIndex()

    local trapsvc = self._world:GetService("TrapLogic")

    ---后续用到的创建资源
    local eMonsters = {}
    local monsterRefreshPosType
    local hitbackResult
    ---客户端在第一波次时，是在loading时创建怪物和机关，所以从loading的组件里取出加载的数据
    if waveNum == 1 then
        local monsterIDList = self._world:BattleStat():GetFirstWaveMonsterIDList()
        for _, id in ipairs(monsterIDList) do
            local entity = self._world:GetEntityByID(id)
            table.insert(eMonsters, entity)
        end
        --第一波怪物出场技计算移到此处
        if eMonsters and not self._world:GetService("Maze"):IsArchivedBattle() then
            ---@type MonsterCreationServiceLogic
            local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")
            for _, e in ipairs(eMonsters) do
                monsterCreationSvc:CalcAppearSkill(e)
                local tEntities, tResults = trapsvc:TriggerTrapByEntity(e, TrapTriggerOrigin.Move)
                e:AddAppearTriggerTrap(tEntities, tResults)
            end
        end
    else
        ---@type LogicEntityService
        local entityService = self._world:GetService("LogicEntity")
        eMonsters, hitbackResult = entityService:CreateWaveMonsters(waveNum) ---服务端以及非第一波次的客户端在这里创建怪物和机关
    end

    return eMonsters, hitbackResult
end

---切换主状态
function WaveEnterSystem:_DoLogicSwitchFsmState()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    --判断是否进入gamestart
    if battleStatCmpt:GetCurWaveIndex() == 1 then
        self._world:EventDispatcher():Dispatch(GameEventType.WaveEnterFinish, 2)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.WaveEnterFinish, 1)
    end
end

function WaveEnterSystem:_DoLogicNotifyWaveStart(waveNum)
    --通知怪物波次刷新
    local triggerService = self._world:GetService("Trigger")
    triggerService:Notify(NTWaveTurnStart:New(waveNum))
end

function WaveEnterSystem:_DoLogicNotifyWaveEnter(waveNum)
    --通知怪物波次刷新
    local triggerService = self._world:GetService("Trigger")
    triggerService:Notify(NTWaveEnter:New(waveNum))
end

---把 "0,1" 转化成 Vector2(0,1)
---@param str string
---@return Vector2
function WaveEnterSystem:V2Str2V2(str)
    if string.isnullorempty(str) then
        return Vector2.zero
    end
    local dirStrs = string.split(str, ",")
    local dir = Vector2(tonumber(dirStrs[1]), tonumber(dirStrs[2]))
    return dir
end
---把 "0,1" 转化成 Vector2(0,1)
---@param str string
---@return Vector2
function WaveEnterSystem:V2StrArr2V2Arr(strs)
    if string.isnullorempty(strs) then
        return nil
    end
    local dirStrs = string.split(strs, ";")
    local arr = {}
    for i, v in ipairs(dirStrs) do
        local v2 = self:V2Str2V2(v)
        table.insert(arr, v2)
    end
    return arr
end


function WaveEnterSystem:_DoLogicCalcPreMove()
    ---@type AIService
    local aiService = self.world:GetService("AI")
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.Prev)
end

---------------------------------表现接口--------------------------------------------

---进入波次，客户端需要执行一些表现，由客户端实现
function WaveEnterSystem:_DoRenderWaveInfo(TT)
end

---展示波次机关，由客户端实现
function WaveEnterSystem:_DoRenderShowWaveTraps(TT, spawnTraps)
end

---创建出怪物前，需要有一些预警信息等的UI展示
function WaveEnterSystem:_DoRenderPreShowMonster(TT)
end

---展示波次怪物，由客户端实现
function WaveEnterSystem:_DoRenderShowWaveMonsters(TT, spawnMonsters)
end

---创建波次剧情提示
function WaveEnterSystem:_DoRenderWaveEnterInnerStory(TT)
end

---通知波次开始
function WaveEnterSystem:_DoRenderNotifyWaveStart(TT, waveNum)
end

function WaveEnterSystem:_DoRenderNotifyWaveEnter(TT, waveNum)
end

function WaveEnterSystem:_DoRenderPlayPreMove(TT)
end

function WaveEnterSystem:_DoRenderRefreshMonsterHitBackTeam(TT, hitbackResult)
end
