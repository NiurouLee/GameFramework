--[[------------------------------------------------------------------------------------------
    ClientBattleEnterSystem_Render：客户端初始化战场
    本文件只重写了进场流程中的表现部分，逻辑部分都在基类里实现
    主流程中只调用了ShowBattleEnter这一个函数
]]
--------------------------------------------------------------------------------------------

require "battle_enter_system"

---@class ClientBattleEnterSystem_Render:BattleEnterSystem
_class("ClientBattleEnterSystem_Render", BattleEnterSystem)
ClientBattleEnterSystem_Render = ClientBattleEnterSystem_Render

---主流程调用的展示开场表现行为，这个函数在服务端是个空函数不会被执行
function ClientBattleEnterSystem_Render:_DoRenderShowBattleEnter(TT, teamEntity)
    ---@type UnityEngine.GameObject
    local goEffRuchangActorpoint = UnityEngine.GameObject.Find(GameResourceConst.EffRuchangActorpoint)
    if goEffRuchangActorpoint then
        self.world:MainCamera():SetGoEffRuchangActorpoint(goEffRuchangActorpoint)
        goEffRuchangActorpoint:SetActive(false)

        local camera = goEffRuchangActorpoint:GetComponentInChildren(typeof(UnityEngine.Camera), true)
        if camera then
            local fov = camera.fieldOfView
            local defaultAspect = BattleConst.CameraDefaultAspect
            local aspect = UnityEngine.Screen.width / UnityEngine.Screen.height
            --宽高比小于16:9，则增大摄像机fov，扩大视野，适配ipad
            if aspect < defaultAspect then
                fov = fov + (defaultAspect - aspect) * BattleConst.BattleEnterIntroPresentation_CameraFovMultiplier
            end
            camera.fieldOfView = fov
        end
    else
        if self._world:IsDevelopEnv() then
            ---@type TestRobotModule
            local testRobot = GameGlobal.GetModule(TestRobotModule)
            if testRobot and testRobot.m_bEnableRobot then
                ---冒烟测试模式下，等待1秒，再检查
                YIELD(TT, 1000)
                goEffRuchangActorpoint = UnityEngine.GameObject.Find(GameResourceConst.EffRuchangActorpoint)
                if not goEffRuchangActorpoint then
                    Log.exception("没有找到入场运镜动画节点：eff_ruchang_actorpoint，需要美术检查对应的场景资源")
                end
            else
                Log.exception("没有找到入场运镜动画节点：eff_ruchang_actorpoint，需要美术检查对应的场景资源")
            end
        end
    end

    local cRenderBoard = self._world:GetRenderBoardEntity():RenderBoard()
    local sceneRoot = GameObjectHelper.Find("SceneRoot")
    cRenderBoard:SetSceneGO(sceneRoot)

    ---有队长才需要开场展示的相机切换
    if teamEntity then
        self:BlinkMainCamera(false)
    end

    if self._world:MatchType() ~= MatchType.MT_Chess then
        local cHP = teamEntity:HP()
        cHP:SetHPPosDirty(true) --用于处理队长血条位置偏下的问题
        cHP:SetHPBarTempHide(true)
    end

    --黑拳赛敌方血条隐藏
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local team = self._world:Player():GetRemoteTeamEntity()
        team:HP():SetHPPosDirty(true)
        team:HP():SetHPBarTempHide(true)
    end

    local darkParamName = "H3DDarkLevel"
    UnityEngine.Shader.SetGlobalFloat(darkParamName, 0)

    ---初始化格子动画状态
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:Initialize()

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    self:_InitRoundCountUI(levelConfigData:GetLevelRoundCount())

    --启动剧情
    self._isStoryEnd = false
    local gameStartType = UIHelper.GameStartType()
    if gameStartType == EGameStartType.SkillEditor then
        self._isStoryEnd = true
        self:_DoPostStory(TT)
        return
    end

    ---@type MatchModule
    local match = GameGlobal.GetModule(MatchModule)
    ---@type MatchEnterData
    local story, isActive, isStage1, isStage1Fail = self:_GetStoryByEnterData(match:GetMatchEnterData())
    if story and not isStage1 and not isActive then
        GameGlobal.UIStateManager():ShowDialog(
            "UIStoryController",
            story.id,
            function()
                local login_module = GameGlobal.GetModule(LoginModule)
                if login_module:IsInFirstStory() then
                    GameGlobal.ReportCustomEvent("CreateRole", "ContinueEnterGame")
                end

                self._isStoryEnd = true
                self:ActiveStory()

                --开场BGM
                self:_PlayEnterBgm()
                --保持黑边隐藏状态 等界面切换完毕后再打开
                GameGlobal.UIStateManager():SetBlackSideVisible(false)
            end,
            false,
            false
        )
    else
        --开场BGM
        self:_PlayEnterBgm()
        self._isStoryEnd = true --结束的时候展示三星条件
    end

    ---这个地方要卡住主流程
    self:_DoPostStory(TT)
end

---播放深渊地形的出场技能
function ClientBattleEnterSystem_Render:_PlayTerrainAbyssAppearSkill(TT)
    local group = self.world:GetGroup(self.world.BW_WEMatchers.Trap)
    local eTraps = group:GetEntities()
    local terrainAbyssEntityList = {}
    for k, entity in pairs(eTraps) do
        ---@type TrapRenderComponent
        local trapRenderComponent = entity:TrapRender()
        if trapRenderComponent:GetTrapType() == TrapType.TerrainAbyss then
            table.insert(terrainAbyssEntityList, entity)
        end
    end
    -----@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    local taskID =
        GameGlobal.TaskManager():CoreGameStartTask(
            trapServiceRender.ShowTraps,
            trapServiceRender,
            terrainAbyssEntityList
        )
    return taskID
end

function ClientBattleEnterSystem_Render:_PlayEnterBgm()
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    --BGM切换
    local bgmID = levelConfigData:GetBgmID()
    if bgmID == 0 then
        Log.fatal("关卡 id:" .. levelConfigData:GetLevelID() .. " 未配置BGM!")
        return
        --bgmID = CriAudioIDConst.BGMBattle
    end
    AudioHelperController.PlayBGMById(bgmID)
end

function ClientBattleEnterSystem_Render:_InitializeGuide()
    ---创建引导的手指
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    sEntity:CreateRenderEntity(EntityConfigIDRender.GuideFinger)
end

---@param enterData MatchEnterData
function ClientBattleEnterSystem_Render:_GetStoryByEnterData(enterData)
    local story = nil
    local isActive = false
    local isStage1 = false
    local isStage1Fail = false
    if MatchType.MT_Mission == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetMissionCreateInfo().mission_id
        isStage1 = Cfg.cfg_global["stage_1_id"].IntValue == missionID
        isStage1Fail = mission:GetCurMissionID() == 0
        ---@type DiscoveryData
        local discoveryData = mission:GetDiscoveryData()
        ---@type DiscoveryStory
        story = discoveryData:GetStoryByStageIdStoryType(missionID, StoryTriggerType.BeforeFight)
        isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
    elseif MatchType.MT_ExtMission == enterData._match_type then
        local extTaskID = enterData:GetMissionCreateInfo().m_nExtTaskID
        local cfg_extra_mission_story = Cfg.cfg_extra_mission_story { ExtMissionTaskID = extTaskID }[1]
        if cfg_extra_mission_story then
            for i = 1, table.count(cfg_extra_mission_story.StoryID) do
                if cfg_extra_mission_story.StoryActiveType[i] == StoryTriggerType.BeforeFight then
                    local extMissionStory = DiscoveryStory:New()
                    extMissionStory:Init(cfg_extra_mission_story.StoryID[i], cfg_extra_mission_story.StoryActiveType[i])
                    local extMissionModule = GameGlobal.GetModule(ExtMissionModule)
                    isActive = extMissionModule:IsMissionStoryActive(extTaskID,
                        ActiveStoryType.ActiveStoryType_BeforeBattle)
                    story = extMissionStory
                    break
                end
            end
        end
    elseif MatchType.MT_Campaign == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetCampaignMissionInfo().nCampaignMissionId

        ---兼容story格式
        story = {}
        story.id = mission:GetStoryByStageIdStoryType(missionID, StoryTriggerType.BeforeFight)
        if not story.id then
            story = nil
        end
        isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
    elseif MatchType.MT_TalePet == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        ---@type TalePetCreateInfo
        local info = enterData:GetTalePetMissionInfo()
        local missionID = info.nId

        ---兼容story格式
        story = {}
        story.id = mission:GetStoryByStageIdStoryType(missionID, StoryTriggerType.BeforeFight)
        if not story.id then
            story = nil
        end
        isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
    elseif MatchType.MT_Season == enterData._match_type then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetSeasonMissionInfo().mission_id

        ---兼容story格式
        story = {}
        story.id = mission:GetStoryByStageIdStoryType(missionID, StoryTriggerType.BeforeFight)
        if not story.id then
            story = nil
        end
        isActive = mission:IsMissionStoryActive(missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
    end
    return story, isActive, isStage1, isStage1Fail
end

function ClientBattleEnterSystem_Render:ActiveStory()
    ---@type MatchModule
    local match = GameGlobal.GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    if enterData._match_type == MatchType.MT_Mission then --主线
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetMissionCreateInfo().mission_id
        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
            end
        )
    elseif enterData._match_type == MatchType.MT_ExtMission then --番外
        local exrMissionModule = GameGlobal.GetModule(ExtMissionModule)
        local extTaskID = enterData:GetMissionCreateInfo().m_nExtTaskID
        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                exrMissionModule:SetMissionStoryActive(self, extTaskID, ActiveStoryType.ActiveStoryType_BeforeBattle)
            end
        )
    elseif enterData._match_type == MatchType.MT_Campaign then --活动
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetCampaignMissionInfo().nCampaignMissionId
        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
            end
        )
    elseif enterData._match_type == MatchType.MT_TalePet then
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        ---@type TalePetCreateInfo
        local info = enterData:GetTalePetMissionInfo()
        local missionID = info.nId
        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
            end
        )
    elseif enterData._match_type == MatchType.MT_Season then --赛季
        ---@type MissionModule
        local mission = GameGlobal.GetModule(MissionModule)
        local missionID = enterData:GetSeasonMissionInfo().mission_id
        local useMissionCfg = Cfg.cfg_season_mission[missionID]
        local secondMissionId = nil--同一组两种难度关卡，剧情相同，只看一份
        if useMissionCfg then
            local secondMissionCfg = nil
            local missionGroupId = useMissionCfg.GroupID
            local missionGroupCfgs = Cfg.cfg_season_mission{GroupID = missionGroupId}
            if #missionGroupCfgs > 0 then
                for index, value in ipairs(missionGroupCfgs) do
                    if value.OrderID ~= useMissionCfg.OrderID then
                        secondMissionCfg = value
                        secondMissionId = value.ID
                        break
                    end
                end
            end
        end
        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                mission:SetMissionStoryActive(self, missionID, ActiveStoryType.ActiveStoryType_BeforeBattle)
                if secondMissionId then
                    mission:SetMissionStoryActive(self, secondMissionId, ActiveStoryType.ActiveStoryType_BeforeBattle)
                end
            end
        )
    end
end

function ClientBattleEnterSystem_Render:_DoPostStory(TT)
    local collector = GameGlobal:GetInstance():GetCollector("CoreGameLoading")
    while self._isStoryEnd == false do
        YIELD(TT)
    end

    ---通知服务器剧情播放完成
    local role = GameGlobal.GetModule(RoleModule)
    local success = role:OnEndStory(TT, 0, 0, 0, 0, 0, 1)
    if not success then
        return
    end

    collector:Sample("ClientBattleEnterSystem_Render:_DoPostStory() begin")
    --下面这块流程要等待UI的相关事情，后边需要重构下
    ---通知UI切到UIBattle
    local match = GameGlobal.GetModule(MatchModule)
    --local stageId = match:GetMatchEnterData():GetMissionCreateInfo().mission_id
    -- 第一关结束是直接进入第二关 UIBattle没关闭 有些数据需要刷新
    if GameGlobal.UIStateManager():IsShow("UIBattle") then
        local uiBattle = GameGlobal.UIStateManager():GetController("UIBattle")
        if uiBattle then
            uiBattle:ResetLayout(TT)
        end
    end
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIBattle)
    while GameGlobal.UIStateManager():IsShow("UIBattle") == false do
        YIELD(TT)
    end
    --重新打开黑边
    GameGlobal.UIStateManager():SetBlackSideVisible(true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, false)

    collector:Sample("ClientBattleEnterSystem_Render:ShowUIBattle()")
    collector:Dump()
    --触发战斗开始引导
    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    local guideTaskId = guideService:Trigger(GameEventType.GuideBattleStart)
    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
    --完成展示，进局
    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")
    if innerStoryService:CheckStoryBanner(StoryShowType.BeginAfterCreateScene) then
        self:BlinkMainCamera(true) --有剧情就开启主相机，防止有剧情时场景黑屏
        InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
    end
end

function ClientBattleEnterSystem_Render:_CreateFinalAttackEffect()
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local effectEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.FinalAttackEffect)
    ---临时配在这里，后边提取到一个统一配置文件里
    local resPath = "eff_finalatk.prefab"
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, false))
end

function ClientBattleEnterSystem_Render:_InitRoundCountUI(waveRoundCount)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.InitRoundCount, waveRoundCount)
end

function ClientBattleEnterSystem_Render:_DoRenderShowBoard(TT, pieceRefreshType, fallingDir)
    self:_BoardShow(TT) --开场格子展示
    YIELD(TT)
    --展示格子下落方向的特效
    if pieceRefreshType == PieceRefreshType.FallingDown then
        --临时 可改到cfg_board
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local curMaxX = utilDataSvc:GetCurBoardMaxX()
        local curMaxY = utilDataSvc:GetCurBoardMaxY()
        local curCenterPos = utilDataSvc:GetBoardCenterPos()
        local effPosGroup = {
            [1] = { curMaxX + 1, curCenterPos.y }, --上箭头
            [2] = { curCenterPos.x, 0 },           --右箭头
            [3] = { curMaxX + 1, curCenterPos.y }, --下箭头
            [4] = { curCenterPos.x, 0 },           --左箭头
        }
        ---@type EffectService
        local sEffect = self._world:GetService("Effect")
        local effId = BattleConst.FallGridDirDefaultEffectId
        local effPos = Vector2(0, 0)
        local dir = Vector2(fallingDir.x, fallingDir.y)
        if dir.x == 0 and dir.y == 1 then --上
            local cfgPos = effPosGroup[1]
            effPos = Vector2(cfgPos[1], cfgPos[2])
        elseif dir.x == 1 and dir.y == 0 then --右
            local cfgPos = effPosGroup[2]
            effPos = Vector2(cfgPos[1], cfgPos[2])
        elseif dir.x == 0 and dir.y == -1 then --下
            local cfgPos = effPosGroup[3]
            effPos = Vector2(cfgPos[1], cfgPos[2])
        elseif dir.x == -1 and dir.y == 0 then --左
            local cfgPos = effPosGroup[4]
            effPos = Vector2(cfgPos[1], cfgPos[2])
        end
        sEffect:CreateWorldPositionDirectionEffect(effId, effPos, dir)
    end
end

function ClientBattleEnterSystem_Render:_BoardShow(TT)
    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")
    if innerStoryService:CheckStoryBanner(StoryShowType.BeginAfterBoardShow) then
        self:BlinkMainCamera(true) --有剧情就开启主相机，防止有剧情时场景黑屏
        InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
        self:BlinkMainCamera(false)
    end
end

function ClientBattleEnterSystem_Render:UnloadEffect(poolSvc, effSvc, effectid)
    local effResPath = effSvc:GetEffectResPath(effectid)
    if effResPath then
        poolSvc:DestroyCache(effResPath)
    end
end

function ClientBattleEnterSystem_Render:_DoRenderShowPet(TT, teamEntity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type CameraService
    local sCamera = self._world:GetService("Camera")
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")

    if teamEntity then
        self._teamLeader = teamEntity:GetTeamLeaderPetEntity()
		self._petEntities = teamEntity:Team():GetTeamPetEntities()
        self._posLeader = boardServiceRender:GetRealEntityGridPos(self._teamLeader)
        self._dirLeader = self._teamLeader:Location():GetDirection():Clone()
        ---@type MatchType
        local matchType = self._world.BW_WorldInfo.matchType
        if matchType == MatchType.MT_EightPets then
            self._arrPos = { Vector2(2, 1), Vector2(3, 1), Vector2(4, 1), Vector2(5, 1), Vector2(6, 1), Vector2(7, 1), Vector2(8, 1) }
        else
            self._arrPos = { Vector2(6, 1), Vector2(4, 1), Vector2(7, 1), Vector2(3, 1) }
        end

        for index, arrPos in ipairs(self._arrPos) do
            if arrPos == self._posLeader then --如果与队长位置有重叠，则改为(5,1)
                self._arrPos[index] = Vector2(5, 1)
                break
            end
        end
        ---@type Entity[]
        self._ePets = self:GetTeamMember(teamEntity)

        local tplID = self:GetPetEntityTemplateID(self._teamLeader)
        ---队长出场语音
        ---@type PetAudioModule
        local pm = GameGlobal.GetModule(PetAudioModule)
        pm:PlayPetAudio("TeamLeaderAppear", tplID)

        ---八人不显示运镜这一坨，后面可以改成配置
        if matchType == MatchType.MT_EightPets then
            self._teamLeader:SetViewVisible(true)
            for i, entity in ipairs(self._ePets) do
                entity:SetViewVisible(true)
            end
        else
            ----阶段1
            self:PlayBattleEnterSkillView(TT)
            self:PlayPetFaceAnim(teamEntity)
            self:PlayFocus(TT)
            self:HideStageEffect(TT)
        end

    end

    sMonsterShowRender:PullDownNotLoadHighMonsters()

    ---深渊出场
    self:_PlayTerrainAbyssAppearSkill(TT)

    --阶段2
    if teamEntity then
        self:PetsStandBy()
        sCamera:BlinkMainCamera(true)
        self:PlayDarkEffect()
        self:PlayCameraAnimation(TT)
    end

    ---@type SpawnPieceServiceRender
    local spawnPieceServiceRender = self._world:GetService("SpawnPieceRender")
    spawnPieceServiceRender:PlayBoardShow(TT)

    if teamEntity then
        ---@type GridLocationComponent
        local gridLocCmpt = self._teamLeader:GridLocation()
        local playerPos = gridLocCmpt:GetGridPos()
        boardServiceRender:ReCreateGridEntity(PieceType.None, playerPos)
    end

    self:CheckStoryTips(TT)
    if teamEntity then
        local isArchived = utilDataSvc:IsArchivedBattle()
        if (not isArchived) or table.count(self._ePets) > 0 then --如果不是存档对局，或有队员，就表现
            self:PlayLightBallFly(TT)                            --出现飞行特效eff_ruchuang_guiji
            self:ResetPetsPos(TT)
        end
    end
    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    cameraCmpt:_MoveCameraToNormal()

    if teamEntity then
        self:ShowHPSlider(TT, teamEntity) --运镜完毕才显示血条
    end

    -- 黑拳赛表现没有需求，暂时写在这里，如果没问题就不动了
    if self._world:MatchType() == MatchType.MT_BlackFist then
        self:ShowRemotePlayer(TT)
    elseif self._world:MatchType() == MatchType.MT_Chess then
        self:ShowChessPet(TT)
    end

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayAutoAddBuff()
end

function ClientBattleEnterSystem_Render:ShowRemotePlayer(TT)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local remoteTeamEntity = self._world:Player():GetRemoteTeamEntity()
    ---@type GridLocationComponent
    local gridLocCmpt = remoteTeamEntity:GridLocation()
    local playerPos = gridLocCmpt:GetGridPos()
    --脚底置灰
    boardServiceRender:ReCreateGridEntity(PieceType.None, playerPos)

    --显示血条
    self:ShowHPSlider(TT, remoteTeamEntity)

    --隐藏队员
    local pets = remoteTeamEntity:Team():GetTeamPetEntities()
    local leader = remoteTeamEntity:Team():GetTeamLeaderEntity()
    local posLeader = boardServiceRender:GetRealEntityGridPos(leader)
    local dirLeader = leader:Location():GetDirection():Clone()
    for i, v in ipairs(pets) do
        v:SetLocation(posLeader, dirLeader)
        if v == leader then
            v:SetViewVisible(true)
        else
            v:SetViewVisible(false)
        end
    end

    --boss血条
    ---@type MatchPet
    local matchPet = leader:MatchPet():GetMatchPet()
    local bossIds = SortedArray:New()
    bossIds:Insert(
        {
            HPBarType = HPBarType.BlackFist,
            pstId = remoteTeamEntity:GetID(),
            tplId = matchPet:GetTemplateID(),
            isVice = false,
            matchPet = matchPet,
            hpEnergyVal = 0,
            maxHPEnergyVal = 0
        }
    )
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowBossHp, bossIds)
end

---显示棋子
function ClientBattleEnterSystem_Render:ShowChessPet(TT)
    local group = self.world:GetGroup(self.world.BW_WEMatchers.ChessPetRender)
    local chessPetEntitys = group:GetEntities()
    for i, v in ipairs(chessPetEntitys) do
        v:SetViewVisible(true)
        self:ShowHPSlider(TT, v)
        v:ReplaceHPComponent()
    end
end

---播放运镜技表现
function ClientBattleEnterSystem_Render:PlayBattleEnterSkillView(TT)
    ---@type PlaySkillService
    local sPlaySkill = self._world:GetService("PlaySkill")
    for id, entity in ipairs(self._petEntities) do
        ---@type ViewComponent
        local viewCmpt = entity:View()
        if viewCmpt == nil or viewCmpt:GetGameObject() == nil then
            ---@type AssetComponent
            local assetCmpt = entity:Asset()
            local resPath = assetCmpt:GetResPath()
            Log.exception("Pet resource load failed:", resPath)
        end

        local goName = entity:View():GetGameObject().name
        local cfgBattleEnterSkillId = Cfg.cfg_pet_battle_enter_skill[goName]
        local battleEnterSkillId --运镜技ID

        if entity:GetID() == self._teamLeader:GetID() then
            if cfgBattleEnterSkillId then
                battleEnterSkillId = cfgBattleEnterSkillId.TeamLeaderSkillID
            else
                battleEnterSkillId = Cfg.cfg_pet_battle_enter_skill["0"].TeamLeaderSkillID
            end
        else
            if cfgBattleEnterSkillId then
                battleEnterSkillId = cfgBattleEnterSkillId.TeamMemberSkillID
            end
        end
		if battleEnterSkillId then
			sPlaySkill:PlaySkillView(entity, battleEnterSkillId)
		end
    end
end

local function _createV4FromV3(v3)
    local v4 = Vector4.zero
    v4.x = v3.x
    v4.y = v3.y
    v4.z = v3.z
    v4.w = 1

    return v4
end

---播放运镜阶段1
function ClientBattleEnterSystem_Render:PlayFocus(TT)
    local match = GameGlobal.GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    if enterData._match_type == MatchType.MT_Mission then --主线
        local missionID = enterData:GetMissionCreateInfo().mission_id
        if missionID and self._ePets then
            local l_pet_array = "" .. self._teamLeader:PetPstID():GetTemplateID()
            for key, value in pairs(self._ePets) do
                l_pet_array = l_pet_array .. "," .. value:PetPstID():GetTemplateID()
            end
            GameGlobal.UAReportForceGuideEvent(
                "MissionShowPet",
                {
                    missionID,
                    l_pet_array
                }
            )
        end
    end

    ---@type UnityEngine.GameObject
    local goEffRuchangActorpoint = self.world:MainCamera():GetGoEffRuchangActorpoint()
    if not goEffRuchangActorpoint then
        Log.fatal("Can not find actor point.")
        return
    end
    local goRenderSetting = UnityEngine.GameObject.Find("[H3DRenderSetting]")
    local csRenderSetting = goRenderSetting:GetComponent("H3DRenderSetting")
    if csRenderSetting.CustomLight and csRenderSetting.CustomShadow then
        csRenderSetting.CustomLight.forward = csRenderSetting.CustomLightForwardIntro
        csRenderSetting.CustomShadow.forward = csRenderSetting.CustomShadowForwardIntro
        UnityEngine.Shader.SetGlobalVector(
            "_H3D_CustomLightDir",
            _createV4FromV3(csRenderSetting.CustomLightForwardIntro)
        )
        UnityEngine.Shader.SetGlobalVector(
            "_H3D_CustomShadowDir",
            _createV4FromV3(csRenderSetting.CustomShadowForwardIntro)
        )
    end
    goEffRuchangActorpoint:SetActive(true)
    ---@type UnityEngine.Animation
    local anim = goEffRuchangActorpoint:GetComponent("Animation")
    anim:Play()
    ---@type UnityEngine.Transform[]
    local trans = {}
    local tranLeader = self._teamLeader:View():GetGameObject().transform
    table.insert(trans, tranLeader)
    for i, e in ipairs(self._ePets) do
        if e then
            local tranPet = e:View():GetGameObject().transform
            table.insert(trans, tranPet)
        end
    end
    for index, tran in ipairs(trans) do
        local tranChild = GameObjectHelper.FindChild(goEffRuchangActorpoint.transform, tostring(index))
        tran:SetParent(tranChild)
        tran.localPosition = Vector3.zero
        tran.localRotation = Quaternion.identity
    end
    YIELD(TT, GameResourceConst.AnimRuchangCameratempLen)
    for index, tran in ipairs(trans) do
        tran:SetParent(goEffRuchangActorpoint.transform.parent)
        tran.localPosition = Vector3.zero
        tran.localRotation = Quaternion.identity
    end
    goEffRuchangActorpoint:SetActive(false)
    if csRenderSetting.CustomLight and csRenderSetting.CustomShadow then
        csRenderSetting.CustomLight.forward = csRenderSetting.CustomLightForwardBattle
        csRenderSetting.CustomShadow.forward = csRenderSetting.CustomShadowForwardBattle
        UnityEngine.Shader.SetGlobalVector(
            "_H3D_CustomLightDir",
            _createV4FromV3(csRenderSetting.CustomLightForwardBattle)
        )
        UnityEngine.Shader.SetGlobalVector(
            "_H3D_CustomShadowDir",
            _createV4FromV3(csRenderSetting.CustomShadowForwardBattle)
        )
    end
end

function ClientBattleEnterSystem_Render:PlayDarkEffect()
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    sEffect:CreateScreenEffPointEffect(GameResourceConst.EffRuchangBlackboard)
end

function ClientBattleEnterSystem_Render:PetsStandBy()
    self._teamLeader:SetLocation(self._posLeader, self._dirLeader)
    local arrDir = { Vector2(0, 1), Vector2(0, 1), Vector2(0, 1), Vector2(0, 1) }
    for i, e in ipairs(self._ePets) do
        if e then
            e:SetLocation(self._arrPos[i], arrDir[i])
        end
    end
end

function ClientBattleEnterSystem_Render:CheckStoryTips(TT)
    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")
    innerStoryService:CheckStoryTips(StoryShowType.BeginAfterMasterShowBeginTeamShow)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuidePlayerShow) --引导:角色显示后-----------------
end

--隐藏StageEffect下的ruchang_eff结点
function ClientBattleEnterSystem_Render:HideStageEffect(TT)
    local goStageEffect = GameObjectHelper.Find("StageEffect")
    if goStageEffect then
        local tran = GameObjectHelper.FindChild(goStageEffect.transform, "ruchang_eff")
        if tran then
            tran.gameObject:SetActive(false)
        else
            Log.fatal("### ruchang_eff is not under StageEffect.")
        end
    else
        Log.warn("### no GameObject named [StageEffect] in scene.")
    end
end

function ClientBattleEnterSystem_Render:ResetPetsPos(TT)
    for i, v in ipairs(self._ePets) do
        if v then
            v:SetPosition(self._posLeader)
        end
    end
end

---拿到队员
---@return Entity[]
function ClientBattleEnterSystem_Render:GetTeamMember(teamEntity)
    local teamMember = {}
    local teamLeaderPetPstID = teamEntity:Team():GetTeamLeaderPetPstID()
    local pets = teamEntity:Team():GetTeamPetEntities()
    for _, e in ipairs(pets) do
        local petPstIDCmpt = e:PetPstID()
        if petPstIDCmpt:GetPstID() ~= teamLeaderPetPstID then
            teamMember[#teamMember + 1] = e
        end
    end
    return teamMember
end

-- function ClientBattleEnterSystem_Render:PlayTeamMember(TT)
--     ---@type EffectService
--     local sEffect = self._world:GetService("Effect")
--     local arrDir = {Vector2(0, 1), Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)}
--     for i, v in ipairs(self._ePets) do
--         local pos = self._arrPos[i]
--         local dir = arrDir[i]
--         v:SetLocation(pos, dir)
--     end
--     YIELD(TT, 300)

--     for i, v in ipairs(self._ePets) do
--         if v then
--             local elementType = self:GetPetEntityFirstElementType(v)
--             sEffect:CreateEffect(sEffect:GetPetShowEffIdByEntity(elementType), v)
--             YIELD(TT, 200)
--             local templateID = self:GetPetEntityTemplateID(v)
--             local cfgPet = Cfg.cfg_pet[templateID]
--             local permanentFxArray = cfgPet.BattlePermanentEffect
--             if permanentFxArray and #permanentFxArray > 0 then
--                 for _, effectID in ipairs(permanentFxArray) do
--                     sEffect:CreateEffect(effectID, v)
--                 end
--             end
--             v:SetViewVisible(true)
--         end
--     end
-- end

---光球飞行
function ClientBattleEnterSystem_Render:PlayLightBallFly(TT)
    ---@type RenderEntityService
    local entityService = self._world:GetService("RenderEntity")
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    for i, v in ipairs(self._ePets) do
        effectService:CreateWorldPositionEffect(GameResourceConst.EffRuchuangPetBao, self._arrPos[i])
    end
    YIELD(TT, 50)
    for i, v in ipairs(self._ePets) do
        if v then
            v:SetViewVisible(false)
        end
    end
    local eBalls = {}
    for i, v in ipairs(self._ePets) do
        if not v then
            return
        end
        local gridLoc = v:GridLocation()
        if not gridLoc then
            return
        end
        local position = boardServiceRender:GetRealEntityGridPos(v)
        local eBall = entityService:CreateRenderEntity(EntityConfigIDRender.Projectile)
        eBall:ReplaceAsset(NativeUnityPrefabAsset:New("eff_ruchuang_guiji.prefab", false))
        eBall:SetPosition(position)
        table.insert(eBalls, eBall)
    end
    local tranLeader = self._teamLeader:View():GetGameObject().transform
    local flyDuration = 400
    local arrCtrlNode = {
        [1] = { Vector3(0.1, 0.3, 0.2) },
        [2] = { Vector3(0, 0.1, 0) },
        [3] = { Vector3(0, 0.1, 0) },
        [4] = { Vector3(-0.1, 0.1, -0.1), Vector3(0.2, 0.2, 0.2) }
    }
    local height = Vector3(0, 0.6, 0) --光球高度偏移
    for i, v in ipairs(eBalls) do
        v:SetViewVisible(true)
        local view = v:View()
        if not view then
            return
        end
        local tranBall = view.ViewWrapper.GameObject.transform
        tranBall.position = tranBall.position + height
        local path = { tranBall.position }
        if arrCtrlNode[i] then
            for j, vj in ipairs(arrCtrlNode[i]) do
                table.insert(path, tranBall.position + height + vj)
            end
        end
        table.insert(path, tranLeader.position + height)
        tranBall:DOPath(
            path,
            flyDuration * 0.001,
            DG.Tweening.PathType.CatmullRom,
            DG.Tweening.PathMode.Full3D,
            10,
            Color.red
        ):SetEase(DG.Tweening.Ease.InCubic):OnComplete(
            function()
                self._world:DestroyEntity(v)
            end
        )
    end
    YIELD(TT, flyDuration)
    effectService:CreateWorldPositionEffect(GameResourceConst.EffRuchuangHeti, self._posLeader)
end

---显示宝宝血条
function ClientBattleEnterSystem_Render:ShowHPSlider(TT, teamEntity)
    ---@type HPComponent
    local cHP = teamEntity:HP()
    local hpSliderEntityID = cHP:GetHPSliderEntityID()
    local eHPBar = self._world:GetEntityByID(hpSliderEntityID)
    if not eHPBar then
        return
    end
    cHP:SetHPPosDirty(true) --用于处理队长血条位置偏下的问题
    cHP:SetHPBarTempHide(false)
    --血条上的buff图标
    local go = eHPBar:View():GetGameObject()
    local uiview = go:GetComponent("UIView")
    ---@type UISelectObjectPath
    local buffRootPath = uiview:GetUIComponent("UISelectObjectPath", "buffRoot")
    if buffRootPath then
        local buffRoot = UICustomWidgetPool:New(self, buffRootPath)
        buffRoot:SpawnObjects("UIHPBuffInfo", 1)
        ---@type UIHPBuffInfo
        local uiHPBuffInfo = buffRoot:GetAllSpawnList()[1]
        uiHPBuffInfo:SetData(teamEntity:GetID())
        cHP:SetUIHpBuffInfoWidget(buffRoot)
    end
end

---播放相机运镜动画
function ClientBattleEnterSystem_Render:PlayCameraAnimation(TT)
    local match = GameGlobal.GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    if enterData._match_type == MatchType.MT_Mission then --主线
        local missionID = enterData:GetMissionCreateInfo().mission_id
        GameGlobal.UAReportForceGuideEvent(
            "MissionRefreshRoad",
            {
                missionID
            }
        )
    end
    local levelID = self._world.BW_WorldInfo.level_id
    local levelConfig = Cfg.cfg_level[levelID]
    local themeID = levelConfig.Theme
    local cfgThemeData = Cfg.cfg_theme[themeID]
    if not cfgThemeData then
        Log.error("关卡theme配置无效: ", tostring(themeID))
        return
    end

    local camera = self._world:MainCamera():Camera()
    ---现在就一个值，用到了再加枚举
    if cfgThemeData.BoardShowCameraAnimationMode and cfgThemeData.BoardShowCameraAnimationMode == 1 then
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type LevelConfigData
        local levelConfigData = configService:GetLevelConfigData()
        ---@type LevelCameraParam
        local cameraParam = levelConfigData:GetCameraParam()
        local originalCameraPos = cameraParam:GetCameraPosition()

        ---@type DG.Tweening.Tweener
        local tweener = camera.gameObject.transform:DOMove(originalCameraPos,
            BattleConst.BoardShowCameraAnimationByScript_TweenTime):SetEase(DG.Tweening.Ease.OutExpo)
        YIELD(TT, BattleConst.BoardShowCameraAnimationByScript_TweenTime * 1000)
    else
        ---@type UnityEngine.Animation
        local animation = camera.gameObject:GetComponent(typeof(UnityEngine.Animation))
        if animation and animation.clip then
            animation:Play()
            YIELD(TT, animation.clip.length * 1000)
        else
            Log.fatal("### no animation on camera.")
        end
    end
end

---根据Entity拿到TemplateID
---@param petEntity Entity
function ClientBattleEnterSystem_Render:GetPetEntityTemplateID(petEntity)
    return petEntity:PetPstID():GetTemplateID()
end

local DirType = {
    Row = 1,
    Col = 2
}
---@return Vector2[]
function ClientBattleEnterSystem_Render:SortGridList(gridList, dir)
    local tmp = {}
    for k, v in pairs(gridList) do
        tmp[#tmp + 1] = v:GetGridPosition():Clone()
    end
    local CmpRow = function(a, b)
        return a.y > b.y
    end

    local CmpCol = function(a, b)
        return a.x > b.x
    end
    if dir == DirType.Row then
        table.sort(tmp, CmpCol)
    end
    if dir == DirType.Col then
        table.sort(tmp, CmpRow)
    end
    return tmp
end

function ClientBattleEnterSystem_Render:GetGridSizeAndCenterPos(gridEntityList, dir)
    local gridCount = table.count(gridEntityList)

    local numberType = gridCount % 2
    local gridList = self:SortGridList(gridEntityList, dir)
    local centerIndex = math.floor(gridCount / 2)
    if numberType == 1 then
        centerIndex = centerIndex + 1
    end
    ---@type Vector2
    local centerPos = gridList[centerIndex]
    if numberType == 0 then
        if dir == DirType.Col then
            centerPos = Vector2(centerPos.x, centerPos.y - 0.5)
        elseif dir == DirType.Row then
            centerPos = Vector2(centerPos.x - 0.5, centerPos.y)
        end
    end
    return gridCount, centerPos
end

function ClientBattleEnterSystem_Render:PlayPetFaceAnim(teamEntity)
    local petEntityList = teamEntity:Team():GetTeamPetEntities()
    for i, petEntity in ipairs(petEntityList) do
        GameGlobal.TaskManager():CoreGameStartTask(self._PlayFace, self, petEntity)
    end
end

function ClientBattleEnterSystem_Render:_PlayFace(TT, petEntity)
    local duration = 0
    local faceSeq = {}
    local waitTime = 0

    local faceId = GameResourceConst.EnterFaceAnimCfgID

    --白盒测试状态下，玩家身上数据并没有用例中的光灵，故无法取到，直接返回，不再播放表现
    local isAutoTest = false
    if EDITOR then
        local autoTestMd = GameGlobal.GetModule(AutoTestModule)
        if autoTestMd:IsAutoTest() then
            isAutoTest = true
        end
    end
    if not isAutoTest then
        local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        local isTeamLeader = false
        if teamEntity then
            isTeamLeader = teamEntity:Team():IsTeamLeaderByEntityId(petEntity:GetID())
        end
        --如果是队长 @suli
        if isTeamLeader then
            local petPstID = petEntity:PetPstID():GetPstID()
            ---@type Pet
            local pet = GameGlobal.GetModule(PetModule):GetPet(petPstID)
            if pet then --新手引导等 不是自己的光灵
                local skin_id = pet:GetSkinId()
                local cfg_pet_skin = Cfg.cfg_pet_skin[skin_id]
                if not cfg_pet_skin then
                    Log.error("###[ClientBattleEnterSystem_Render] cfg_pet_skin is nil ! id --> ", skin_id)
                else
                    if cfg_pet_skin.EnterBattleFaceCfgID then
                        faceId = cfg_pet_skin.EnterBattleFaceCfgID
                    end
                end
            end
        end
    end
    local cfg = Cfg.cfg_aircraft_pet_face[faceId]
    if not cfg then
        Log.fatal("###找不到配置表情配置：", faceId)
        return
    end
    local preTime = 0

    preTime = preTime + waitTime

    if cfg.FaceSeq then
        for i, value in ipairs(cfg.FaceSeq) do
            local face = {}
            face.frame = value[1]
            local time = value[2]
            face.time = preTime + time
            preTime = preTime + time
            duration = duration + time

            faceSeq[#faceSeq + 1] = face
        end
    end
    local timeService = self._world:GetService("Time")
    waitTime = duration + duration
    local runTime = 0
    local faceIdx = 1
    local mat = self:GetPetFaceMat(petEntity)
    while runTime < duration do
        if faceIdx <= #faceSeq then
            local nowFace = faceSeq[faceIdx]
            if runTime > nowFace.time then
                faceIdx = faceIdx + 1
                if mat and faceIdx <= #faceSeq then
                    nowFace = faceSeq[faceIdx]
                    mat:SetInt("_Frame", nowFace.frame)
                end
            end
        end
        local deltaTimeMS = timeService:GetDeltaTimeMs()
        runTime = deltaTimeMS + runTime
        YIELD(TT)
    end
end

---@param petEntity Entity
function ClientBattleEnterSystem_Render:GetPetFaceMat(petEntity)
    ---@type ViewComponent
    local viewComponent = petEntity:View()
    ---@type UnityEngine.GameObject
    local petGo = viewComponent:GetGameObject()
    local resID = petEntity:PetPstID():GetResID()
    local faceMat = nil
    local face_name = resID .. "_face"
    local face = GameObjectHelper.FindChild(petGo.transform, face_name)
    if face then
        local render = face.gameObject:GetComponent(typeof(UnityEngine.SkinnedMeshRenderer))
        if not render then
            Log.fatal("面部表情节点上找不到SkinnedMeshRenderer：", face_name)
        else
            ---@type UnityEngine.Material
            faceMat = render.material
        end
    end
    return faceMat
end

---客户端组装feature的表现
function ClientBattleEnterSystem_Render:_DoRenderAssembleFeature(TT)
    ---@type FeatureServiceRender
    local featureRender = self._world:GetService("FeatureRender")
    if featureRender then
        featureRender:OnBattleEnter(TT)
    end
end
