--[[------------------------------------------------------------------------------------------
    响应波次进入 system
]]
--------------------------------------------------------------------------------------------

require "pop_star_wave_enter_system"

---@class PopStarWaveEnterSystem_Render:PopStarWaveEnterSystem
_class("PopStarWaveEnterSystem_Render", PopStarWaveEnterSystem)
PopStarWaveEnterSystem_Render = PopStarWaveEnterSystem_Render

function PopStarWaveEnterSystem_Render:_DoRenderWaveInfo(TT)
    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")

    --当前波次
    ---@type number
    local waveNum = utilStatSvc:GetStatCurWaveIndex()
    self:_PlayWaveBgm(waveNum)

    --self._world:EventDispatcher():Dispatch(GameEventType.RefreshWaveInfo)
end

function PopStarWaveEnterSystem_Render:_PlayWaveBgm(waveNum)
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    --BGM切换
    local bgmID = levelConfigData:BGMParam(waveNum)
    if not bgmID then
        return
    end
    AudioHelperController.PlayBGMById(bgmID)
end

---展示波次进入的机关，返回一个协程ID
function PopStarWaveEnterSystem_Render:_DoRenderShowWaveTraps(TT, spawnTraps)
    ---@type TrapServiceRender
    local trapRSvc = self._world:GetService("TrapRender")
    return GameGlobal.TaskManager():CoreGameStartTask(trapRSvc.ShowTraps, trapRSvc, spawnTraps)
end

function PopStarWaveEnterSystem_Render:_DoRenderPlayPreMove(TT)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end

    playAISvc:DoCommonRountine(TT)
end

function PopStarWaveEnterSystem_Render:_DoRenderShowUIBattleStart(TT)
    --三星条件展示
    if not GuideHelper.DontShowThreeMission() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowBonusInfo, true)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideUIBattle, true)
    ---强制开启二倍速
    HelperProxy:GetInstance():SetGameTimeScale(BattleConst.TimeSpeedList[BattleConst.Speed2Index])
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveBattlePet)
end

function PopStarWaveEnterSystem_Render:_DoRenderAutoAddBuff(TT, buffSeqList)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")

    --被动buff出场效果
    playBuffSvc:PlayBuffSeqs(TT, buffSeqList)
    playBuffSvc:PlayAutoAddBuff(TT)
    playBuffSvc:PlayBuffView(TT, NTGameStart:New())
end

function PopStarWaveEnterSystem_Render:_DoRenderDestroyBattleEnterResource(TT)
    self:UnloadEffect(GameResourceConst.EffRuchangBlackboard)
    self:UnloadEffect(GameResourceConst.EffBoardShowLine)
end

---这个函数可以拆到svc里
function PopStarWaveEnterSystem_Render:UnloadEffect(effID)
    ---@type ResourcesPoolService
    local poolSvc = self._world:GetService("ResourcesPool")
    ---@type EffectService
    local effSvc = self._world:GetService("Effect")

    local effResPath = effSvc:GetEffectResPath(effID)
    if effResPath then
        poolSvc:DestroyCache(effResPath)
    end
end
