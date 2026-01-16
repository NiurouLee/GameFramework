--[[------------------------------------------------------------------------------------------
    对局回放剧情入口
]] --------------------------------------------------------------------------------------------
---@class CutsceneGameEntry:Object
_class("CutsceneGameEntry", Object)
CutsceneGameEntry = CutsceneGameEntry

function CutsceneGameEntry:Constructor(levelID)
    self._levelID = levelID
end

function CutsceneGameEntry:InitalizeCoreGame()
    ---@type CutsceneWorldCreationContext
    local worldInfo = CutsceneWorldCreationContext:New()
    worldInfo.level_id = self._levelID

    ---创建游戏世界
    ---@type CutsceneWorld
    self._world = CutsceneWorld:New(worldInfo)
    self._world:EnterWorld()

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    configService:InitConfig()

    --缓存资源
    self:_CacheAssetFile()

    --刷新棋盘
    self:_DoRenderBoard()

    ---@type Entity
    local playerEntity = self:CreateCutscenePlayer()
    self._world:Player():SetLocalTeamEntity(playerEntity)
    ---设置相机
    self:SetUpCutsceneCamera()

    ---@type UnityEngine.GameObject
    local goEffRuchangActorpoint = UnityEngine.GameObject.Find(GameResourceConst.EffRuchangActorpoint)
    if goEffRuchangActorpoint then
        goEffRuchangActorpoint:SetActive(false)
    end

    ---@type ClientTimeService
    self._timeService = self._world:GetService("Time")
    self._running = true

    self._replayTaskID = GameGlobal.TaskManager():CoreGameStartTask(self.ReplayCutscene, self)
end

---缓存.asset文件
function CutsceneGameEntry:_CacheAssetFile()
    ---@type RenderEntityService
    local entityService = self._world:GetService("RenderEntity")
    --创建  renderBoardEntity 储存材质要用
    entityService:CreateRenderBoardEntity()

    --通用材质
    self:_CacheGlobalAssetFile()

    --格子材质
    self:_CacheCutsceneGridMaterial()
end

function CutsceneGameEntry:_CacheGlobalAssetFile()
    local file_name = "globalShaderEffects.asset"
    -- local respool = self._world.BW_Services.ResourcesPool
    ---@type ResourcesPoolService
    local respool = self._world:GetService("ResourcesPool")
    respool:CacheAsset(file_name, 1)
end

function CutsceneGameEntry:_CacheCutsceneGridMaterial()
    ---@type LoadingServiceRender
    local loadingSvc = self._world:GetService("Loading")
    --缓存材质
    loadingSvc:_CacheGridMaterial()

    -- -- local respool = self._world.BW_Services.ResourcesPool
    ---@type ResourcesPoolService
    local respool = self._world:GetService("ResourcesPool")
    local cachetable = {}
    loadingSvc:_CacheCurrentGrid(cachetable)
    for k, v in pairs(cachetable) do
        local resname = v[1]
        local count = v[2]
        if string.endwith(resname, ".mat") then
            respool:CacheMaterial(resname, count)
        else --if string.endwith(resname, ".prefab") then 默认为prefab
            respool:Cache(resname, count)
        end
    end

    --替换材质
    loadingSvc:_ReplaceCachedGridMaterial()
end

---使用固定主角，固定位置
function CutsceneGameEntry:CreateCutscenePlayer()
    local entityConstId = EntityConfigIDRender.CutscenePlayer
    local ctx = EntityCreationContext:New()
    ctx.entity_config_id = entityConstId
    ctx.bShow = true

    ---@type Entity
    local entity = self._world:CreateEntity()
    self._world:SetEntityIdByEntityConfigId(entity, entityConstId)

    EntityAssembler.AssembleEntityComponents(entity, ctx)

    local prefabPath = "1500331.prefab"
    entity:ReplaceAsset(NativeUnityPrefabAsset:New(prefabPath))

    local pos = Vector3(0, 0, 0)
    entity:SetLocation(pos)

    return entity
end

function CutsceneGameEntry:SetUpCutsceneCamera()
    local cameraName = "MainCamera"
    ---@type ResRequest
    self._request = UnityResourceService:GetInstance():LoadGameObject(cameraName .. ".prefab")
    ---@type UnityEngine.GameObject
    local go = self._request.Obj

    --设置相机数据
    local levelRawData = Cfg.cfg_level[self._levelID]
    local themeRawData = Cfg.cfg_theme[levelRawData.Theme]

    local cameraCmpt = go:GetComponent("Camera")
    cameraCmpt.fieldOfView = self:CalcCutsceneFov(themeRawData.Fov)

    cameraCmpt.nearClipPlane = themeRawData.NearClipDistance
    cameraCmpt.farClipPlane = themeRawData.FarClipDistance

    local numberArray = string.split(themeRawData.CameraPosition, ",")
    local positionX = tonumber(numberArray[1])
    local positionY = tonumber(numberArray[2])
    local positionZ = tonumber(numberArray[3])
    local cameraPos = Vector3(positionX, positionY, positionZ)
    cameraCmpt.transform.position = cameraPos

    local rotationNumberArray = string.split(themeRawData.CameraRotation, ",")
    local rotationX = tonumber(rotationNumberArray[1])
    local rotationY = tonumber(rotationNumberArray[2])
    local rotationZ = tonumber(rotationNumberArray[3])
    cameraCmpt.transform.rotation = Quaternion.Euler(rotationX, rotationY, rotationZ)
end

function CutsceneGameEntry:CalcCutsceneFov(fov)
    local newFov = fov
    local defaultAspect = BattleConst.CameraDefaultAspect
    local aspect = UnityEngine.Screen.width / UnityEngine.Screen.height
    --宽高比小于16:9，则增大摄像机fov，扩大视野，适配ipad
    if aspect < defaultAspect then
        newFov = fov + (defaultAspect - aspect) * 6
    end

    return newFov
end

function CutsceneGameEntry:Stop()
    self._running = false
end

function CutsceneGameEntry:Running()
    return self._running
end

function CutsceneGameEntry:Dispose()
    ---@type CutsceneServiceRender
    local cutsceneSvc = self._world:GetService("Cutscene")
    cutsceneSvc:ResetSkyBoxColor()

    self._matchEnterData = nil
    self._enterPreferenceData = nil
    UnityEngine.GameObject.Destroy(self._request.Obj)
    self._request = nil

    self._world:ExitWorld()
    self._world:Dispose()

    InnerGameHelperRender:GetInstance():Dispose()
end

function CutsceneGameEntry:Update(curTimeMS, deltaTimeMS)
    self._timeService:SetCurrentTime(curTimeMS)
    self._timeService:SetDeltaTime(deltaTimeMS)

    self._world:UpdateWorld(deltaTimeMS)
end

function CutsceneGameEntry:ReplayCutscene(TT)
    ---@type CutsceneServiceRender
    local cutsceneSvc = self._world:GetService("Cutscene")
    cutsceneSvc:ReviewCutscene(TT, self._levelID)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.CutsceneFinish)
end

---刷新棋盘
function CutsceneGameEntry:_DoRenderBoard()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    --格式是 {[1],[2]}
    local gapTiles = BattleConst.GapTiles
    --改成V2
    local gapTilesPosList = {}
    for i, p in ipairs(gapTiles) do
        local gridPos = Vector2(p[1], p[2])
        table.insert(gapTilesPosList, gridPos)
    end

    --创建格子
    local piecePosList = {}
    for x = 1, BattleConst.DefaultMaxX do
        for y = 1, BattleConst.DefaultMaxY do
            local gridPos = Vector2(x, y)
            if not table.icontains(gapTilesPosList, gridPos) then
                local pieceType = math.random(1, 4)
                local gridEntity = boardServiceRender:CreateGridEntity(pieceType, gridPos, true)
                gridEntity:SetViewVisible(true)

                --V3表现坐标 用于刷新线
                local renderPos = boardServiceRender:GridPos2RenderPos(gridPos)
                table.insert(piecePosList, renderPos)
            end
        end
    end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local brillantLineObj = renderBoardCmpt:GetBrillantGridObj()
    --画格子之间的线
    if brillantLineObj then
        brillantLineObj:SetActive(true)
        local curPieceTable = renderBoardCmpt._gridEntityTable
        CellRenderManager.DrawRangeImmediate(piecePosList)
    end
end
