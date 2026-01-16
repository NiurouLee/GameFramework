--[[------------------------------------------------------------------------------------------
    ClientWaveSwitchSystem_Render：客户端实现玩家出现的表现
]] --------------------------------------------------------------------------------------------

require "wave_switch_system"

---@class ClientWaveSwitchSystem_Render:WaveSwitchSystem
_class("ClientWaveSwitchSystem_Render", WaveSwitchSystem)
ClientWaveSwitchSystem_Render = ClientWaveSwitchSystem_Render

function ClientWaveSwitchSystem_Render:_DoRenderShowSwitch(TT, waveBoard)
    self._world:EventDispatcher():Dispatch(GameEventType.WaveSwitch)

    ---@type Entity
    local viewDataEntity = self._world:GetRenderBoardEntity()
    ---@type WaveDataComponent
    local waveDataCmpt = viewDataEntity:WaveData()

    if not waveDataCmpt:IsExitWave() then --当前波次不是逃离，才显示波次提示信息
        local taskID =
            TaskManager:GetInstance():CoreGameStartTask(
            function(TT)
                ---@type UtilDataServiceShare
                local utilStatSvc = self._world:GetService("UtilData")
                -- 产生指定波次随机波次刷新
                if utilStatSvc:GetStatIsAssignWaveResult() then
                    local configService = self._world:GetService("Config")
                    ---@type LevelConfigData
                    local levelConfigData = configService:GetLevelConfigData()
                    local l_levelId = levelConfigData:GetLevelID()
                    self._world:EventDispatcher():Dispatch(GameEventType.ShowHideWaveWarning, true, l_levelId)
                    YIELD(TT, 2000)
                    self._world:EventDispatcher():Dispatch(GameEventType.ShowHideWaveWarning, false)
                    self._world:EventDispatcher():Dispatch(GameEventType.ShowDropCoinInfoActive)
                else
                    local waveIndex = utilStatSvc:GetStatCurWaveIndex()

                    --波次刷新棋盘表现
                    if waveBoard then
                        ---@type SpawnPieceServiceRender
                        local spawnPieceServiceRender = self._world:GetService("SpawnPieceRender")
                        spawnPieceServiceRender:PlayBoardShow(TT, waveBoard)
                    end

                    self._world:EventDispatcher():Dispatch(GameEventType.ShowWaveSwitch, true, waveIndex)
                    YIELD(TT, 2000)
                    self._world:EventDispatcher():Dispatch(GameEventType.ShowWaveSwitch, false)
                end
            end,
            self
        )
        while not TaskHelper:GetInstance():IsAllTaskFinished({taskID}) do
            YIELD(TT)
        end
    else
        local taskID =
            TaskManager:GetInstance():CoreGameStartTask(
            function(TT)
                ---@type UtilDataServiceShare
                local utilStatSvc = self._world:GetService("UtilData")
                -- 产生指定波次随机波次刷新
                if utilStatSvc:GetStatIsAssignWaveResult() then
                else
                    local waveIndex = utilStatSvc:GetStatCurWaveIndex()
                    --波次刷新棋盘表现
                    if waveBoard then
                        ---@type SpawnPieceServiceRender
                        local spawnPieceServiceRender = self._world:GetService("SpawnPieceRender")
                        spawnPieceServiceRender:PlayBoardShow(TT, waveBoard)
                    end
                    --self._world:EventDispatcher():Dispatch(GameEventType.ShowWaveSwitch, true, waveIndex)
                    --YIELD(TT, 2000)
                    --self._world:EventDispatcher():Dispatch(GameEventType.ShowWaveSwitch, false)
                end
            end,
            self
        )
        while not TaskHelper:GetInstance():IsAllTaskFinished({taskID}) do
            YIELD(TT)
        end
    end
end

function ClientWaveSwitchSystem_Render:_DoRenderTrapState(TT, calcStateTraps)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    trapServiceRender:RenderTrapState(TT, TrapDestroyType.DestoryByWave, calcStateTraps)
    if self._world._matchType == MatchType.MT_Conquest then
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        local score = configService:N5GetCurWaveScore()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIN5UpdateScore, score)
    end
end

function ClientWaveSwitchSystem_Render:_DoRenderAddWaveSwitchBuff(TT)
    ---@type PlayBuffService
    local playBuff = self._world:GetService("PlayBuff")
    playBuff:PlayBuffView(TT, NTWaveSwitch:New())
end

function ClientWaveSwitchSystem_Render:_DoRenderRefreshPetPower(TT, petPowerStateList)
    for _, petPowerState in pairs(petPowerStateList) do
        local entityID = petPowerState.petEntityID
        local petPstID = petPowerState.petPstID
        local curPower = petPowerState.power
        local ready = petPowerState.ready

        --改变CD
        GameGlobal.EventDispatcher():Dispatch(GameEventType.PetPowerChange, petPstID, curPower, true)
        --可以释放
        if ready == 1 then
            --false 不刷新动画
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, false)
        else
            --0 不刷新动画
            GameGlobal:EventDispatcher():Dispatch(GameEventType.PetActiveSkillCancelReady, petPstID, 0)
        end
    end
end
