--[[------------------------------------------------------------------------------------------
    PopStarBattleEnterSystem_Render：消灭星星进入战场表现
]]
--------------------------------------------------------------------------------------------

require "pop_star_battle_enter_system"

---@class PopStarBattleEnterSystem_Render:PopStarBattleEnterSystem
_class("PopStarBattleEnterSystem_Render", PopStarBattleEnterSystem)
PopStarBattleEnterSystem_Render = PopStarBattleEnterSystem_Render

function PopStarBattleEnterSystem_Render:_DoRenderShowBattleEnter(TT, teamEntity)
    ---角色入场镜头节点默认是开启的，此处强制关闭，降低性能消耗
    ---@type UnityEngine.GameObject
    local goEffRuChangActorPoint = UnityEngine.GameObject.Find(GameResourceConst.EffRuchangActorpoint)
    if goEffRuChangActorPoint then
        goEffRuChangActorPoint:SetActive(false)
    end

    local cRenderBoard = self._world:GetRenderBoardEntity():RenderBoard()
    local sceneRoot = GameObjectHelper.Find("SceneRoot")
    cRenderBoard:SetSceneGO(sceneRoot)

    ---隐藏血条
    ---@type HPComponent
    local cHP = teamEntity:HP()
    cHP:SetHPPosDirty(true)
    cHP:SetHPBarTempHide(true)

    ---设置队员位置
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
    ---@type LocationComponent
    local locationCmpt = teamEntity:Location()
    local pets = teamEntity:Team():GetTeamPetEntities()
    for i, e in ipairs(pets) do
        if e:GetID() ~= teamLeaderEntity:GetID() then
            e:SetLocation(locationCmpt:GetPosition(), locationCmpt:GetDirection())
        end
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

    --开场BGM
    self:_PlayEnterBgm()

    self:_DoPostStory(TT)
end

function PopStarBattleEnterSystem_Render:_InitRoundCountUI(waveRoundCount)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.InitRoundCount, waveRoundCount)
end

function PopStarBattleEnterSystem_Render:_PlayEnterBgm()
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

function PopStarBattleEnterSystem_Render:_DoPostStory(TT)
    local collector = GameGlobal:GetInstance():GetCollector("CoreGameLoading")
    collector:Sample("PopStarBattleEnterSystem_Render:_DoPostStory() begin")

    ---通知UI切到UIBattle
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIBattle)
    while GameGlobal.UIStateManager():IsShow("UIBattle") == false do
        YIELD(TT)
    end

    --重新打开黑边
    GameGlobal.UIStateManager():SetBlackSideVisible(true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, false)

    collector:Sample("PopStarBattleEnterSystem_Render:ShowUIBattle()")
    collector:Dump()

    --触发战斗开始引导
    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    local guideTaskId = guideService:Trigger(GameEventType.GuideBattleStart)
    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
end

function PopStarBattleEnterSystem_Render:_DoRenderShowBoard(TT, pieceRefreshType, fallingDir)
    self:_BoardShow(TT) --开场格子展示
    YIELD(TT)
    --展示格子下落方向的特效
    if pieceRefreshType == PieceRefreshType.FallingDown then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local curMaxX = utilDataSvc:GetCurBoardMaxX()
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

function PopStarBattleEnterSystem_Render:_BoardShow(TT)
    ---深渊出场
    self:_PlayTerrainAbyssAppearSkill(TT)

    ---棋盘出场
    ---@type SpawnPieceServiceRender
    local spawnPieceServiceRender = self._world:GetService("SpawnPieceRender")
    spawnPieceServiceRender:PlayBoardShow(TT)

    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    cameraCmpt:_MoveCameraToNormal()

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayAutoAddBuff()
end

---播放深渊地形的出场技能
function PopStarBattleEnterSystem_Render:_PlayTerrainAbyssAppearSkill(TT)
    local group = self.world:GetGroup(self.world.BW_WEMatchers.Trap)
    local eTraps = group:GetEntities()
    local terrainAbyssEntityList = {}
    for _, entity in pairs(eTraps) do
        ---@type TrapRenderComponent
        local trapRenderComponent = entity:TrapRender()
        if trapRenderComponent:GetTrapType() == TrapType.TerrainAbyss then
            table.insert(terrainAbyssEntityList, entity)
        end
    end

    -----@type TrapServiceRender
    local trapRSvc = self._world:GetService("TrapRender")
    local taskID = GameGlobal.TaskManager():CoreGameStartTask(trapRSvc.ShowTraps, trapRSvc, terrainAbyssEntityList)
    return taskID
end

---客户端组装feature的表现
function PopStarBattleEnterSystem_Render:_DoRenderAssembleFeature(TT)
    ---@type FeatureServiceRender
    local featureRender = self._world:GetService("FeatureRender")
    if featureRender then
        featureRender:OnBattleEnter(TT)
    end
end
