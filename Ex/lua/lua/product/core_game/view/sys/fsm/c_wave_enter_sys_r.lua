--[[------------------------------------------------------------------------------------------
    响应波次进入 system
]] --------------------------------------------------------------------------------------------

require "wave_enter_system"

---@class ClientWaveEnterSystem_Render:WaveEnterSystem
_class("ClientWaveEnterSystem_Render", WaveEnterSystem)
ClientWaveEnterSystem_Render = ClientWaveEnterSystem_Render

function ClientWaveEnterSystem_Render:_DoRenderWaveInfo(TT)
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")

    --当前波次
    ---@type number
    local waveNum = utilStatSvc:GetStatCurWaveIndex()
    Log.notice("EnterWave WaveNum:", waveNum)
    if levelConfigData:GetWaveCompleteConditionType(waveNum) == CompleteConditionType.KillAnyMonsterCount then
        local param = levelConfigData:GetWaveCompleteConditionParam(waveNum)
        self._world:EventDispatcher():Dispatch(GameEventType.UIInitMonsterDeadCount, param[1][1])
    end
    self:_PlayWaveBgm(waveNum)

    self._world:EventDispatcher():Dispatch(GameEventType.RefreshWaveInfo)
end

function ClientWaveEnterSystem_Render:_PlayWaveBgm(waveNum)
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
function ClientWaveEnterSystem_Render:_DoRenderShowWaveTraps(TT, spawnTraps)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    local taskID =
        GameGlobal.TaskManager():CoreGameStartTask(trapServiceRender.ShowTraps, trapServiceRender, spawnTraps)
    return taskID
end

---创建出怪物前，需要有一些预警信息等的UI展示
function ClientWaveEnterSystem_Render:_DoRenderPreShowMonster(TT)
    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local isBossWave, bossIDs = utilStatSvc:GetStatBossWaveInfo()

    --BOSS来袭
    if isBossWave then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideBossComing, true, bossIDs[1])
        YIELD(TT, 2000)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideBossComing, false)
    end
end

---展示波次怪物，由客户端实现
function ClientWaveEnterSystem_Render:_DoRenderShowWaveMonsters(TT, spawnMonsters)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local isFirstWave = utilStatSvc:GetStatIsFirstWave()

    if not isFirstWave then
        sMonsterShowRender:CreateMonsterHPEntities(spawnMonsters)
    else
        local match = GameGlobal.GetModule(MatchModule)
        local enterData = match:GetMatchEnterData()
        if enterData._match_type == MatchType.MT_Mission then --主线
            local missionID = enterData:GetMissionCreateInfo().mission_id
            GameGlobal.UAReportForceGuideEvent(
                "MissionRefreshMonster",
                {
                    missionID
                }
            )
        end
    end

    sMonsterShowRender:ShowMonsters(TT, spawnMonsters)
end

---创建波次剧情提示
function ClientWaveEnterSystem_Render:_DoRenderWaveEnterInnerStory(TT)
    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local isFirstWave = utilStatSvc:GetStatIsFirstWave()

    if isFirstWave then
        --怪物剧情对话
        if innerStoryService:CheckStoryBanner(StoryShowType.BeginAfterMonsterShow) then
            InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
        end
        innerStoryService:CheckStoryTips(StoryShowType.BeginAfterMonsterShow)
    end
end

function ClientWaveEnterSystem_Render:_DoRenderNotifyWaveStart(TT, waveNum)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveBattlePet)
    local playBuffService = self._world:GetService("PlayBuff")
    playBuffService:PlayBuffView(TT, NTWaveTurnStart:New(waveNum))
end

function ClientWaveEnterSystem_Render:_DoRenderNotifyWaveEnter(TT, waveNum)
    local playBuffService = self._world:GetService("PlayBuff")
    playBuffService:PlayBuffView(TT, NTWaveEnter:New(waveNum))
end

function ClientWaveEnterSystem_Render:_DoRenderPlayPreMove(TT)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end

    playAISvc:DoCommonRountine(TT)
end

--麦格芬出场击退
function ClientWaveEnterSystem_Render:_DoRenderRefreshMonsterHitBackTeam(TT, hitbackResult)
    if not hitbackResult then
        return
    end
    local processHitTaskID = nil

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    -- local hitBackSpeed = BattleConst.HitbackSpeed
    local hitBackSpeed = 10

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    if hitbackResult and not teamEntity:HasHitback() and not hitbackResult:GetHadPlay() then
        hitbackResult:SetHadPlay(true)
        processHitTaskID = playSkillService:ProcessHit(renderBoardEntity, teamEntity, hitbackResult, hitBackSpeed)
    end

    ---等待击退/撞墙等处
    if processHitTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(processHitTaskID) do
            YIELD(TT)
        end
    end
    YIELD(TT)
    if hitbackResult then
        local pieceService = self._world:GetService("Piece")
        pieceService:RemovePrismAt(hitbackResult:GetPosTarget())
    end
end
