--[[------------------------------------------------------------------------------------------
    PopStarWaveEnterSystem：初始化波次状态
]]
--------------------------------------------------------------------------------------------

require "main_state_sys"

---@class PopStarWaveEnterSystem:MainStateSystem
_class("PopStarWaveEnterSystem", MainStateSystem)
PopStarWaveEnterSystem = PopStarWaveEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarWaveEnterSystem:_GetMainStateID()
    return GameStateID.PopStarWaveEnter
end

---@param TT token 协程识别码，服务端环境下是nil
function PopStarWaveEnterSystem:_OnMainStateEnter(TT)
    ---初始化battleState状态，其他依赖波次进入的初始化逻辑也可以放在这里
    self:_DoLogicInitWaveBattleState()

    ---波次开始时的表现
    self:_DoRenderWaveInfo(TT)

    ---新生成的机关Entity列表
    local spawnTraps = self:_DoLogicCreateWaveTraps()

    ---新创建机关的表现过程
    local showTrapsTaskID = self:_DoRenderShowWaveTraps(TT, spawnTraps)

    local waitTaskIDList = {}
    if showTrapsTaskID ~= nil then
        table.insert(waitTaskIDList, showTrapsTaskID)
    end

    ---波次进入流程要等待机关刷新完成，服务端会直接跳过
    self:_WaitTasksEnd(TT, waitTaskIDList)

    ---计算前置行为
    self:_DoLogicCalcPreMove()

    ---表现前置行为
    self:_DoRenderPlayPreMove(TT)

    ---开场UI
    self:_DoRenderShowUIBattleStart(TT)

    ---开场Buff
    local buffSeqList = self:_DoLogicGameStart()

    ---开场Buff表现
    self:_DoRenderAutoAddBuff(TT, buffSeqList)

    ---清理入场特效等资源
    self:_DoRenderDestroyBattleEnterResource(TT)

    ---切换主状态机状态，前后台一致
    self:_DoLogicSwitchFsmState()
end

---初始化一些组件的状态
function PopStarWaveEnterSystem:_DoLogicInitWaveBattleState()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type number
    local waveNum = battleStatCmpt:GetCurWaveIndex()

    local levelRoundCount = battleStatCmpt:GetLevelLeftRoundCount()
    battleStatCmpt:InitCurWaveRound(levelRoundCount)

    battleStatCmpt:InitCurWaveAllMonsterDeadTimes()

    ---通知表现数据更新
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    local isExit = battleSvc:IsCurWaveExit()
    local exitPos = battleSvc:CurWaveExitPos()
    local data = DataWaveEnterResult:New(waveNum, isExit, exitPos)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end

---创建波次机关
---@return array 新创建的机关数组
function PopStarWaveEnterSystem:_DoLogicCreateWaveTraps()
    local eTraps = {}

    local trapIDList = self._world:BattleStat():GetFirstWaveTrapIDList()
    for _, id in ipairs(trapIDList) do
        local entity = self._world:GetEntityByID(id)
        table.insert(eTraps, entity)
    end

    return eTraps
end

function PopStarWaveEnterSystem:_DoLogicCalcPreMove()
    ---@type AIService
    local aiService = self.world:GetService("AI")
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.Prev)
end

---开场Buff
function PopStarWaveEnterSystem:_DoLogicGameStart()
    ---对局开始触发
    local gameStartBuffs = {}
    self._world:GetService("Battle"):InitWordBuff(gameStartBuffs)
    self._world:GetService("Battle"):InitTalePetBuff(gameStartBuffs)
    self._world:GetService("Affix"):InitAffixBuff(gameStartBuffs)
    self._world:GetService("Trigger"):Notify(NTGameStart:New())
    return gameStartBuffs
end

---切换主状态
function PopStarWaveEnterSystem:_DoLogicSwitchFsmState()
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarWaveEnterFinish, 1)
end

---------------------------------表现接口--------------------------------------------

---进入波次，客户端需要执行一些表现，由客户端实现
function PopStarWaveEnterSystem:_DoRenderWaveInfo(TT)
end

---展示波次机关，由客户端实现
function PopStarWaveEnterSystem:_DoRenderShowWaveTraps(TT, spawnTraps)
end

function PopStarWaveEnterSystem:_DoRenderPlayPreMove(TT)
end

function PopStarWaveEnterSystem:_DoRenderShowUIBattleStart(TT)
end

function PopStarWaveEnterSystem:_DoRenderAutoAddBuff(TT, buffSeqList)
end

function PopStarWaveEnterSystem:_DoRenderDestroyBattleEnterResource(TT)
end
