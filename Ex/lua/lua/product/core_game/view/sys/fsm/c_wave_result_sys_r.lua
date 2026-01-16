--[[------------------------------------------------------------------------------------------
    ClientWaveResultSystem_Render：客户端实现波次结算的表现
]] --------------------------------------------------------------------------------------------

require "wave_result_system"

---@class ClientWaveResultSystem_Render:WaveResultSystem
_class("ClientWaveResultSystem_Render", WaveResultSystem)
ClientWaveResultSystem_Render = ClientWaveResultSystem_Render

function ClientWaveResultSystem_Render:_DoRenderNotifyWaveEnd(TT, waveNum)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTWaveTurnEnd:New(waveNum))
end

function ClientWaveResultSystem_Render:_DoRenderChainAttackDead(TT)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:DoAllMonsterDeadRender(TT)
end

function ClientWaveResultSystem_Render:_DoRenderHandleTurnBattleResult(TT, victory, hasDeadLogic)
    GameGlobal.UAReportForceGuideEvent("BattleResult", { victory and 1 or 0 }, false, true)
    if victory then
        if hasDeadLogic then
            ---@type MonsterShowRenderService
            local sMonsterShowRender = self._world:GetService("MonsterShowRender")

            local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
            local monster_entities = monster_group:GetEntities()
            for _, v in pairs(monster_entities) do
                v:ReplaceRedHPAndWhitHP(0)
                v:AddDeadFlag()
            end

            sMonsterShowRender:DoAllMonsterDeadRender(TT)
        end
    end
end

function ClientWaveResultSystem_Render:_DoRenderSendWaveEnd(TT, turnToBattleResult, victory)
    ---@type MatchModule
    local matchMD = GameGlobal.GetModule(MatchModule)
    ---@type number
    local waveIndex = BattleStatHelper.GetCurWaveIndex()
    if self._world._matchType == MatchType.MT_Conquest or
        self._world._matchType == MatchType.MT_MiniMaze then
        ---奖励波次这里还是会有问题
        if BattleStatHelper.GetBattleWaveResult() then
            matchMD:HandleWaveEnd(waveIndex)
        end
    end
end
