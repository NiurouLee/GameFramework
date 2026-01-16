--[[------------------------------------------------------------------------------------------
    ClientRoundResultSystem_Render：客户端实现的回合结算表现
]] --------------------------------------------------------------------------------------------

require "round_result_system"

---@class ClientRoundResultSystem_Render:RoundResultSystem
_class("ClientRoundResultSystem_Render", RoundResultSystem)
ClientRoundResultSystem_Render = ClientRoundResultSystem_Render

function ClientRoundResultSystem_Render:_DoRenderShowRoundEnd(TT, battleCalcResult)
    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local l_role_module = GameGlobal.GetModule(RoleModule)
    -- 已过了UA打点上报强引导关卡 就不要上报了
    -- 由于以下判断存在较多的字符串操作会影响局内性能 同时 局内不能使用CheckModuleUnlock判断是否进行如下操作 故 写在这里
    if not l_role_module:CheckModuleUnlock(GameModuleID.MD_ForceGuideEnd) then
        local attrGroup = self._world:GetGroup(self._world.BW_WEMatchers.Attributes)
        local l_strTemp = ""
        for i, e in ipairs(attrGroup:GetEntities()) do
            local l_ePetMonster = nil
            local l_templateId = 0
            if e:HasMonsterID() then
                l_ePetMonster = "monster"
                l_templateId = e:MonsterID():GetMonsterID()
            elseif e:HasTeam() then
                l_ePetMonster = "team"
                l_templateId = 0
            end

            if l_ePetMonster ~= nil then
                local val = utilStatSvc:GetCurrentLogicHP(e)
                if val then
                    l_strTemp = l_strTemp .. "{" .. l_ePetMonster .. ": " .. l_templateId .. " , hp: " .. val .. "},"
                end
            end
        end
        local curRound = utilStatSvc:GetStatCurWaveRoundNum()
        GameGlobal.UAReportForceGuideEvent(
            "FightRoundInfo",
            {
                curRound,
                l_strTemp
            },
            false,
            true
        )
    end

    --结算胜利
    if battleCalcResult then
        return
    end

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    --MSG49015：回合用尽的扣血提示时机修改，还原至添加功能之前的状态
    if utilStatSvc:GetStatIsRealZeroRound() and not utilStatSvc:GetStatLevelCompleteLimitAllRoundCount() then
        if self._world:MatchType() ~= MatchType.MT_WorldBoss then
            if levelConfigData:GetOutOfRoundType() == 0 then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowZeroRoundWarning, true)
                YIELD(TT, 2000)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowZeroRoundWarning, false)
            end
        end
    end
end

function ClientRoundResultSystem_Render:_DoRenderNotifyRoundTurnEnd(TT, teamEntity)
    local svc = self._world:GetService("PlayBuff")
    svc:PlayBuffView(TT, NTRoundTurnEnd:New())
    svc:PlayBuffView(TT, NTEnemyTurnEnd:New(teamEntity))
end

function ClientRoundResultSystem_Render:_DoRenderInWave(TT, traps, monsters)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:PlaySpawnInWave(TT, traps, monsters)
end

function ClientRoundResultSystem_Render:_DoRenderTrapAction(TT)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end

    playAISvc:DoCommonRountine(TT)
end

function ClientRoundResultSystem_Render:_DoRenderRefreshCombinedWaveInfoOnRoundResult(TT)
    self._world:EventDispatcher():Dispatch(GameEventType.BattleUIRefreshCombinedWaveInfoOnRoundResult)
end

function ClientRoundResultSystem_Render:_DoRenderCalcTrapStateNonFightClub(TT, calcStateTraps)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    trapServiceRender:RenderTrapState(TT, TrapDestroyType.DestroyAtRoundResult, calcStateTraps)
end

function ClientRoundResultSystem_Render:_UpdateTrapGridRound(TT)
    ---@type TrapServiceRender
    local svc = self._world:GetService("TrapRender")
    svc:UpdateTrapGridRound()
end
