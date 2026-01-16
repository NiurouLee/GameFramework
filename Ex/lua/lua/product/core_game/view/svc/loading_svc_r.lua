--[[
    进入对局loading过程
]]
---@class LoadingServiceRender: BaseService
_class("LoadingServiceRender", BaseService)
LoadingServiceRender = LoadingServiceRender

function LoadingServiceRender:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
    self._LoadProcessValue = 0
    self._cachedSoundMonsterIdList = {}
    self._cachedSoundTrapIdList = {}
    self._cachedVoiceMonsterIdList = {}
    self._cachedMonsterIdList = {}
    self._cachedTrapIdList = {}
    self._cachedBuffIdList = {}
    self._cachedSkillIdList = {}

    self._loadAfterLoading = {}
    self._loadingTimeTable = {}
    self._afterLoadingTime = {}

    self._transformMonsterIDDic = {
        [2900141] = 2900142,
        [2900181] = 2900182
    }

    self._brillantGridMaterial = "brillant_gezi_main.mat"
    self._blindGridMaterial = "stage_gezi_color_blind.mat"
end

function LoadingServiceRender:MockLoading(TT)
    if LocalDB.GetInt(GameGlobal.GetHighFrameKey(), 0) == 1 then
        BattleConst.RealFrameTime = 1 / 60
    end

    local collector = GameGlobal:GetInstance():GetCollector("CoreGameLoading")
    local loadBegin = os.clock()

    Log.prof("[loading] start load")

    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    local levelResPath = levelConfigData:GetLevelResPath()
    local tik = os.clock()
    GameGlobal:GetInstance().gameLogic:LoadScene(TT, levelResPath)
    YIELD(TT)

    local newBake = UnityEngine.GameObject.Find("NewBake")
    if newBake then
        UnityEngine.Shader.EnableKeyword("H3D_SPE_BAKE_NEW")
    else
        UnityEngine.Shader.DisableKeyword("H3D_SPE_BAKE_NEW")
    end

    --[[ move to exit coregame
    --gc start
    HelperProxy:GetInstance():GCCollect()
    collectgarbage("collect")
    HelperProxy:GetInstance():GCCollect()
    collectgarbage("collect")
    --gc finish
    ]]
    self:_UpdateLoadingProcess(30)
    YIELD(TT)
    local tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "LoadScene", time = (tok - tik) * 1000})

    self:_CacheGlobalAssetFile()
    self:_CacheGridMaterial()
    self:_CacheObject(TT, 60)
    YIELD(TT)
    self:_ReplaceCachedGridMaterial()
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "CacheObject", time = (tok - tik) * 1000})

    self:_LoadingSystemCacheAudio(TT)
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "CacheAudio", time = (tok - tik) * 1000})

    self:_SetUpSceneCamera()
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_SetUpSceneCamera", time = (tok - tik) * 1000})
    YIELD(TT)

    self:_CacheAllEntity(TT)
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity", time = (tok - tik) * 1000})

    YIELD(TT)
    self:_UpdateLoadingProcess(90)

    self:_InitializeLoadingEntity(TT)

    YIELD(TT)
    self:_UpdateLoadingProcess(100)

    -- 加载完成
    local allTime = os.clock() - loadBegin
    Log.prof("[loading] end load use time=", allTime * 1000)

    --分段加载时间统计
    for i, v in ipairs(self._loadingTimeTable) do
        Log.prof("[loading] process,", v.name, ",time,", v.time)
    end

    --资源加载时间统计[性能分析用，代码不要删除]
    --local respool = self._world.BW_Services.ResourcesPool
    --respool:PrintLoadTime()
    collector:Sample("LoadingServiceRender:MockLoading()")

    --通知LoadingManager
    GameGlobal.LoadingManager():CoreGameLoadingFinish()
    if EDITOR then
        self._world:GetAIDebugModule():StartCoreGame()
    end
end

function LoadingServiceRender:LoadAfterLoading(TT)
    local respool = self._world.BW_Services.ResourcesPool
    local tik = os.clock()
    local restable = self._loadAfterLoading
    for k, v in pairs(restable) do
        local resname = v[1]
        local count = v[2]
        if string.endwith(resname, ".mat") then
            respool:CacheMaterial(resname, count)
        else --if string.endwith(resname, ".prefab") then 默认为prefab
            respool:Cache(resname, count)
        end
        YIELD(TT)
    end
    local tok = os.clock()
    Log.prof("[loading] load after loading finished, use time=", (tok - tik) * 1000)
end

function LoadingServiceRender:_UpdateLoadingProcess(value)
    self._LoadProcessValue = value
    GameGlobal.EventDispatcher():Dispatch(GameEventType.LoadingProgressChanged, value)
end

function LoadingServiceRender:_CacheObject(TT, maxProcess)
    local respool = self._world.BW_Services.ResourcesPool
    local cachetable = self:_GetCacheTable()
    local count = table.count(cachetable)
    local oneProcess = (maxProcess - self._LoadProcessValue) / count

    for keystr, t in pairs(cachetable) do
        local tik = os.clock()
        local restable = t
        for k, v in pairs(restable) do
            local resname = v[1]
            local count = v[2]
            if string.endwith(resname, ".mat") then
                respool:CacheMaterial(resname, count)
            else --if string.endwith(resname, ".prefab") then 默认为prefab
                respool:Cache(resname, count)
            end
        end
        self:_UpdateLoadingProcess(self._LoadProcessValue + oneProcess)
        YIELD(TT)
        local tok = os.clock()
        table.insert(self._loadingTimeTable, {name = "CacheObject/" .. keystr, time = (tok - tik) * 1000})
    end
    self:_UpdateLoadingProcess(maxProcess)
end

function LoadingServiceRender:_SetUpSceneCamera()
    ---@type CameraService
    local cameraService = self._world:GetService("Camera")
    cameraService:InitializeSceneCamera()
end

function LoadingServiceRender:_CacheAllEntity(TT)
    local tik = os.clock()
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    entityPoolService:CacheEntities()

    YIELD(TT)
    entityPoolService:HideCacheEntities()
    YIELD(TT)
    local tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity/CacheEntities", time = (tok - tik) * 1000})

    --预览实体
    self:_PreCreatePreviewEntity()

    ---预先把棋盘以及棋盘上的格子创建出来
    self:_PreCreateBoard()
    YIELD(TT)
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity/_PreCreateBoard", time = (tok - tik) * 1000})

    ---预热动画
    self:_PreWarmAnim()
    YIELD(TT)

    self:_PrePlayAnim()

    YIELD(TT)
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity/_PreWarmAnim_PrePlayAnim", time = (tok - tik) * 1000})

    ---预先把玩家队伍创建出来
    self:_PreCreateTeam()
    YIELD(TT)
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity/_PreCreateTeam", time = (tok - tik) * 1000})

    ---第一波次的怪和机关
    self:_PreCreateFirstWaveMonsterAndTrap(TT)

    YIELD(TT)
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity/_PreCreateFirstWave", time = (tok - tik) * 1000})

    ---隐藏格子
    self:_MoveUpAllGrid()
    YIELD(TT)
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity/_MoveUpAllGrid", time = (tok - tik) * 1000})

    ---预热shader
    ResourceManager:GetInstance():WarmUpCoreGameShader()
    tik = tok
    tok = os.clock()
    table.insert(self._loadingTimeTable, {name = "_CacheAllEntity/WarmUpCoreGameShader", time = (tok - tik) * 1000})
end

function LoadingServiceRender:_PreCreatePreviewEntity()
    ---@type RenderEntityService
    local entityService = self._world:GetService("RenderEntity")
    local ePreview = entityService:CreateRenderEntity(EntityConfigIDRender.Preview)
    self._world:SetPreviewEntity(ePreview)
    return ePreview
end

---创建棋盘逻辑
function LoadingServiceRender:_PreCreateBoard()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    boardServiceRender:InitBaseGridRenderPos()--设置(1,1)格子的基础位置，可能有配置修改
    ---初始化白线，这个操作需要在创建格子gameObject之前进行，否则CellRenderManager会报错
    ---@type SpawnPieceServiceRender
    local spawnPieceServiceRender = self._world:GetService("SpawnPieceRender")
    spawnPieceServiceRender:InitializeCellRender()

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:CreateBoardGridEntity()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:InitPieceAnim()

    --多面棋盘
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    local isMultiBoardLevel = levelConfigData:IsMultiBoardLevel()
    if isMultiBoardLevel then
        renderEntityService:CreateBoardMultiGridEntity()
        ---@type PieceMultiServiceRender
        local pieceMultiService = self._world:GetService("PieceMulti")
        local multiBoard = levelConfigData:GetMultiBoard()
        for i, boardInfo in ipairs(multiBoard) do
            local boardIndex = boardInfo.index
            pieceMultiService:InitPieceAnim(boardIndex)
        end
    end

    --拼接棋盘
    renderEntityService:CreateBoardSpliceGridEntity()
end

---动画的addClip操作会导致rebuildinternalstate，因此需要提前做这个事情
function LoadingServiceRender:_PreWarmAnim(cacheGridList)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        ---@type Entity
        local pieceEntity = e
        ---@type ViewComponent
        local viewCmpt = pieceEntity:View()
        local gameObj = viewCmpt:GetGameObject()
        gameObj:SetActive(true)
    end
end

---将所有格子移动到一个看不到的位置
function LoadingServiceRender:_MoveUpAllGrid()
    --多面棋盘不隐藏格子
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    local isMultiBoardLevel = levelConfigData:IsMultiBoardLevel()
    local isSpliceBoardLevel = levelConfigData:IsSpliceBoardLevel()

    if isMultiBoardLevel or isSpliceBoardLevel then
        return
    end

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        ---@type Entity
        local pieceEntity = e
        ---@type ViewComponent
        local viewCmpt = pieceEntity:View()
        local gameObj = viewCmpt:GetGameObject()
        local curPos = gameObj.transform.position
        gameObj.transform.position = Vector3(curPos.x, BattleConst.CacheHeight, curPos.z)
    end
end

---预播放格子动画，animation需要预先播放一次避免第一次播放时的卡顿
function LoadingServiceRender:_PrePlayAnim()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        pieceService:SetPieceEntityAnimNormal(e)
    end
end

--场景
function LoadingServiceRender:_GetSceneCacheTable()
    local sceneRes = Cfg.cfg_regular_resource {}
    local t = {}
    for i, v in ipairs(sceneRes) do
        if v.LoadType == "GameObject" and v.Tag == "scene" then
            t[#t + 1] = {v.ResName, v.CacheCount}
        end
    end
    self:_CacheCurrentGrid(t)
    return t
end

--格子
function LoadingServiceRender:_CacheCurrentGrid(tableName)
    local loadGridConfig = {
        {PieceType.Blue, 20},
        {PieceType.Red, 20},
        {PieceType.Green, 20},
        {PieceType.Yellow, 20},
        {PieceType.Any, 1},
        {PieceType.None, 1}
    }
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    for i = 1, #loadGridConfig do
        local gridPath = boardServiceRender:_GetGridPrefabPath(loadGridConfig[i][1])
        table.insert(tableName, {gridPath, loadGridConfig[i][2]})
    end
end

--宠物
function LoadingServiceRender:_GetPetCacheTable()
    local ret = {}
    ---@type PetModule
    local petModule = GameGlobal.GameLogic():GetModule(PetModule)
    local joinedPlayerInfoArray = self._world.BW_WorldInfo.players
    for i, joinedPlayerInfo in pairs(joinedPlayerInfoArray) do
        for petIndex, matchPetInfo in ipairs(joinedPlayerInfo.pet_list) do
            local petPstID = matchPetInfo.pet_pstid
            local petData
            if self._world:MatchType() == MatchType.MT_PopStar then
                petData = PopStarMatchPet:New(matchPetInfo)
            else
                petData = MatchPet:New(matchPetInfo)
            end
            
            local retCache = self:_GetCacheTable_ByPetData({petData})
            table.appendArray(ret, retCache)
        end
    end
    if self._world:MatchType() == MatchType.MT_BlackFist then
        for petIndex, matchPetInfo in ipairs(self._world.BW_WorldInfo.remoteTeamInfo) do
            local petPstID = matchPetInfo.pet_pstid
            local petData = MatchPet:New(matchPetInfo)
            local retCache = self:_GetCacheTable_ByPetData({petData})
            table.appendArray(ret, retCache)
        end
    end
    return ret
end

--机关
function LoadingServiceRender:_GetTrapCacheTable()
    local ret = {}

    local levelConfigData = self._configService:GetLevelConfigData()
    local waveNum = levelConfigData:GetWaveCount()
    local traps = levelConfigData:GetLevelAllWaveTraps()
    local trapArray = {}
    if #traps == 0 then
        return ret
    end
    for _, trapTransformParam in ipairs(traps) do
        local t = self:_GetOneTrapCacheTable(trapTransformParam)
        table.appendArray(ret, t)
    end
    return ret
end

function LoadingServiceRender:_GetOneTrapCacheTable(trapTransformParam)
    local ret = {}
    local trapConfigData = self._configService:GetTrapConfigData()
    local trapId = trapTransformParam:GetTrapID()
    if table.icontains(self._cachedTrapIdList, trapId) then
        return ret
    end
    table.insert(self._cachedTrapIdList, trapId)

    --模型动作
    table.insert(ret, {trapConfigData:GetTrapResPath(trapId), 1})

    --技能
    local skillIds = trapConfigData:GetSkillIDs(trapId)
    if skillIds then
        local t = self:_GetSkillCacheTable(skillIds)
        table.appendArray(ret, t)
    end

    --特殊材质动画
    local shaderEffect = trapConfigData:GetTrapShaderEffect(trapId)
    if shaderEffect then
        self:_CacheEachShaderEffectsAssetFile(shaderEffect)
    end

    return ret
end

--怪物
function LoadingServiceRender:_GetMonsterCacheTable()
    local ret = {}
    local levelConfigData = self._configService:GetLevelConfigData()
    --提前波次和第一波预加载
    local monsterIds = levelConfigData:GetLoadingMonsterID()
    for _, monsterID in ipairs(monsterIds) do
        local t = self:_GetOneMonsterCacheTable(monsterID)
        table.appendArray(ret, t)
    end

    --第二波之后延迟加载
    monsterIds = levelConfigData:GetRunningMonsterID()
    for _, monsterID in ipairs(monsterIds) do
        local t = self:_GetOneMonsterCacheTable(monsterID)
        table.appendArray(ret, t)
        -- table.appendArray(self._loadAfterLoading, t)
    end

    return ret
end

function LoadingServiceRender:_GetOneMonsterCacheTable(monsterID)
    local ret = {}
    if table.icontains(self._cachedMonsterIdList, monsterID) then
        return ret
    end
    table.insert(self._cachedMonsterIdList, monsterID)

    local monsterConfigData = self._configService:GetMonsterConfigData()
    --模型动作
    table.insert(ret, {monsterConfigData:GetMonsterResPath(monsterID), 1})
    --特效
    local permanentEffectArray = monsterConfigData:GetMonsterPermanentEffectID(monsterID)
    local idleEffectArray = monsterConfigData:GetMonsterIdleEffectID(monsterID)
    if permanentEffectArray then
        for _, effectID in ipairs(permanentEffectArray) do
            table.insert(ret, {Cfg.cfg_effect[effectID].ResPath, 1})
        end
    end
    if idleEffectArray then
        for _, effectID in ipairs(idleEffectArray) do
            table.insert(ret, {Cfg.cfg_effect[effectID].ResPath, 1})
        end
    end

    --死亡特效
    local deathEffectID = monsterConfigData:GetDeathShowEffectID(monsterID)
    if deathEffectID ~= nil then
        if type(deathEffectID) == "number" then
            table.insert(ret, {Cfg.cfg_effect[deathEffectID].ResPath, 1})
        else
            for i, effID in ipairs(deathEffectID) do
                table.insert(ret, {Cfg.cfg_effect[effID].ResPath, 1})
            end
        end
    end

    --技能
    local skillIds = monsterConfigData:GetCacheSkillIds(monsterID)
    local t = self:_GetSkillCacheTable(skillIds)
    table.appendArray(ret, t)

    --buff
    local buffList = monsterConfigData:GetBornBuffList(monsterID)
    if buffList then
        local t = self:_GetBuffCacheTable(buffList)
        table.appendArray(ret, t)
    end

    --特殊材质动画
    local shaderEffect = monsterConfigData:GetMonsterShaderEffect(monsterID)
    if shaderEffect then
        self:_CacheEachShaderEffectsAssetFile(shaderEffect)
    end

    --ai可能引用其他monster
    local aiidAndOrders = monsterConfigData:GetMonsterAIID(monsterID)
    for i = 1, #aiidAndOrders do
        local aiid = aiidAndOrders[i][1]
        if aiid then
            local aiConfig = AILogicConfig[aiid]
            if aiConfig then
                for _, action in pairs(aiConfig.Action) do
                    if type(action) == "table" and action.Type == "ActionCrazyMode" then
                        local transformMonsterID = action.Data[1]
                        local t = self:_GetOneMonsterCacheTable(transformMonsterID)
                        table.appendArray(ret, t)
                    end
                end
            end
        end
    end

    return ret
end

function LoadingServiceRender:_GetSkillCacheTable(skillIds, skinId)
    local ret = {}
    for _, skillid in ipairs(skillIds) do
        local t = self:_GetOneSkillCacheTable(skillid, skinId)
        table.appendArray(ret, t)
    end
    return ret
end

--技能的所有资源都从这里加载
function LoadingServiceRender:_GetOneSkillCacheTable(skillId, skinId)
    local ret = {}
    if table.icontains(self._cachedSkillIdList, skillId) then
        return ret
    end
    table.insert(self._cachedSkillIdList, skillId)

    ---@type SkillConfigData
    local skillConfig = self._configService:GetSkillConfigData(skillId)

    --技能view中的资源
    local skillPhaseArray = skillConfig:GetSkillPhaseArray(skinId)
    if not skillPhaseArray then
        local levelID = self._world.BW_WorldInfo.level_id
        Log.exception("找不到技能 skillID=" .. skillId .. "   levelID=" .. levelID)
    end
    for _, phase in ipairs(skillPhaseArray) do
        ---@type SkillPhaseParamBase
        local skillPhaseParam = phase:GetPhaseParam()
        local t = skillPhaseParam:GetCacheTable(skillConfig,skinId)
        table.appendArray(ret, t)
    end

    --根据技能效果加载资源
    ---@type ConfigDecorationService
    -- local svcCfgDeco = self._world:GetService("ConfigDecoration")
    -- local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(nil, skillId) -- Loading时应该只需要静态配置
    local skillEffectArray = skillConfig:GetSkillEffect()
    for _, effect in ipairs(skillEffectArray) do
        if effect.GetEffectType then
            if effect:GetEffectType() == SkillEffectType.AddBuff then
                --buff
                local t = self:_GetOneBuffCacheTable(effect:GetBuffID())
                table.appendArray(ret, t)
            elseif effect:GetEffectType() == SkillEffectType.SummonEverything then
                --召唤物
                local t = self:_GetSummonCacheTable(effect)
                table.appendArray(ret, t)
            elseif effect:GetEffectType() == SkillEffectType.MakePhantom then
                ---@type SkillMakePhantomParam
                local eft = effect
                local t = self:_GetOneMonsterCacheTable(eft:GetTargetID())
                table.appendArray(ret, t)
            elseif effect:GetEffectType() == SkillEffectType.Transformation then
                ---@type SkillTransformationParam
                local eft = effect
                local t = self:_GetOneMonsterCacheTable(eft:GetTargetMonsterID())
                table.appendArray(ret, t)
            elseif effect:GetEffectType() == SkillEffectType.SummonMultipleTrap then
                local t = self:_GetOneTrapCacheTable(effect) -- 里面用的是GetTrapID()
                table.appendArray(ret, t)
            end
        end
    end

    return ret
end

function LoadingServiceRender:_GetBuffCacheTable(buffList)
    local ret = {}
    for _, buffID in ipairs(buffList) do
        local t = self:_GetOneBuffCacheTable(buffID)
        table.appendArray(ret, t)
    end
    return ret
end

--buff的所有资源都通过此函数获取
function LoadingServiceRender:_GetOneBuffCacheTable(buffID)
    local ret = {}
    if table.icontains(self._cachedBuffIdList, buffID) then
        return ret
    end
    table.insert(self._cachedBuffIdList, buffID)

    -- 加载时特殊处理，如果配的buffID确实是无效值，那么不再走下面的逻辑
    -- buffID在特定配置下可能是无效的
    if not Cfg.cfg_buff[buffID] then
        return ret
    end

    local buffConfig = self._configService:GetBuffConfigData(buffID)
    --特效
    local t = buffConfig:GetCacheTable()
    table.appendArray(ret, t)

    --技能
    local skillIds = buffConfig:GetCacheSkillIds()
    local t = self:_GetSkillCacheTable(skillIds)
    table.appendArray(ret, t)

    --buff
    local buffIds = buffConfig:GetCacheBuffIds()
    local t = self:_GetBuffCacheTable(buffIds)
    table.appendArray(ret, t)
    return ret
end

---取出召唤的prefab加入cache列表
---@param skillEffectParam SkillEffectParam_SummonEverything
function LoadingServiceRender:_GetSummonCacheTable(skillEffectParam)
    local ret = {}
    local summonType = skillEffectParam:GetSummonType()
    local summonIDS = skillEffectParam:GetSummonList()
    for _key, summonID in pairs(summonIDS) do
        if summonType == SkillEffectEnum_SummonType.Monster then
            local t = self:_GetOneMonsterCacheTable(summonID)
            table.appendArray(ret, t)
        elseif summonType == SkillEffectEnum_SummonType.Trap then
            local trapData = Cfg.cfg_trap[summonID]
            local prefabPath = trapData.ResPath
            table.insert(ret, {prefabPath, 1})
        end
    end
    return ret
end

function LoadingServiceRender:_GetCacheTable()
    local t = {}
    t["scene"] = self:_GetSceneCacheTable()
    t["monster"] = self:_GetMonsterCacheTable()
    t["trap"] = self:_GetTrapCacheTable()
    t["pet"] = self:_GetPetCacheTable()
    t["common"] = self:_GetGameCacheResGroup()
    return t
end

function LoadingServiceRender:_LoadingSystemCacheAudio(TT)
    --音效缓存
    local cachetable = self:_GetSoundCacheTable()
    local l_acbMap = {}
    for k, v in ipairs(cachetable) do
        if USEADX2AUDIO then
            local l_strAcbName, l_strCueName = AudioHelperController.GetCueSheetAndCue(v)
            if l_strAcbName and l_acbMap[l_strAcbName] == nil then -- 统计acb
                l_acbMap[l_strAcbName] = true
                AudioHelperController.RequestInnerGameSoundByResName(l_strAcbName)
            end
        else
            AudioHelperController.RequestInnerGameSound(v)
        end
    end

    --语音缓存
    local cachetable = self:_GetVoiceCacheTable()
    local l_res_map = {}
    for k, v in ipairs(cachetable) do
        local voiceResName = AudioHelperController.GetResNameByAudioId(v) --AudioHelper.GetAudioResName(v)
        if (voiceResName ~= nil) and (not l_res_map[voiceResName]) then
            l_res_map[voiceResName] = true
            AudioHelperController.RequestInnerGameVoiceByResName(voiceResName)
        end
    end
end

function LoadingServiceRender:_GetSoundCacheTable()
    local t = {}
    table.appendArray(t, self:_GetSceneSoundCacheTable())
    table.appendArray(t, self:_GetPetSoundCacheTable())
    table.appendArray(t, self:_GetTrapSoundCacheTable())
    table.appendArray(t, self:_GetMonsterSoundCacheTable())
    return t
end

--固定局内音效
function LoadingServiceRender:_GetSceneSoundCacheTable()
    local t = {}
    --连线音效
    for i = CriAudioIDConst.SoundCoreGameLinkLineStart, CriAudioIDConst.SoundCoreGameLinkLineEnd do
        t[#t + 1] = i
    end
    --[[ 暂时不用 资源只有9016一个 如果未来增加行走音效 也只用这一个 音效师通过cri提供随机逻辑
    --行走音效
    for i = CriAudioIDConst.SoundCoreGameChainMoveStart, CriAudioIDConst.SoundCoreGameUndoLink do
        t[#t + 1] = i
    end]]
    t[#t + 1] = CriAudioIDConst.SouncCoreGameMonsterDeath
    --t[#t + 1] = CriAudioIDConst.SoundSystemGridUnfold --铺格子音效 (废弃)
    t[#t + 1] = CriAudioIDConst.SoundPetCommonShow --宠物出场音效
    --t[#t + 1] = CriAudioIDConst.SoundAuroraTimeActive      -- 极光时刻音效
    for i, v in ipairs(BattleConst.MonsterBornAudioList) do
        t[#t + 1] = v --怪物出场音效
    end
    return t
end

--宠物音效
function LoadingServiceRender:_GetPetSoundCacheTable()
    local ret = {}
    ---@type PetModule
    local petModule = GameGlobal.GameLogic():GetModule(PetModule)
    local joinedPlayerInfoArray = self._world.BW_WorldInfo.players
    for i, joinedPlayerInfo in pairs(joinedPlayerInfoArray) do
        for petIndex, matchPetInfo in ipairs(joinedPlayerInfo.pet_list) do
            local petPstID = matchPetInfo.pet_pstid
            --local petData = MatchPet:New(matchPetInfo) --petModule:GetPet(petPstID)
            local petData
            if self._world:MatchType() == MatchType.MT_PopStar then
                petData = PopStarMatchPet:New(matchPetInfo)
            else
                petData = MatchPet:New(matchPetInfo)
            end
            --技能
            local normalSkillID = petData:GetNormalSkill()
            local chainSkill = petData:GetChainSkillInfo()
            local activeSkill = petData:GetPetActiveSkill()
            local skillIds = {normalSkillID, table.unpack(table.select(chainSkill, "Skill")), activeSkill}
            local t = self:_GetSkillCacheSound(skillIds)
            table.appendArray(ret, t)
        end
    end
    return ret
end

--机关音效
function LoadingServiceRender:_GetTrapSoundCacheTable()
    local ret = {}
    local levelConfigData = self._configService:GetLevelConfigData()
    local traps = levelConfigData:GetLevelAllWaveTraps()
    local trapArray = {}
    if #traps == 0 then
        return ret
    end
    for _, trapTransformParam in ipairs(traps) do
        local t = self:_CacheTrapSound(trapTransformParam:GetTrapID())
        table.appendArray(ret, t)
    end
    return ret
end

--怪物音效
function LoadingServiceRender:_GetMonsterSoundCacheTable()
    local ret = {}
    local levelConfigData = self._configService:GetLevelConfigData()
    local monsterIds = levelConfigData:GetAllMonsterID()
    for _, monsterID in ipairs(monsterIds) do
        local t = self:_CacheMonsterSound(monsterID)
        table.appendArray(ret, t)
    end

    return ret
end

function LoadingServiceRender:_CacheMonsterSound(monsterID)
    if table.ikey(self._cachedSoundMonsterIdList, monsterID) then
        return
    end

    table.insert(self._cachedSoundMonsterIdList, monsterID)
    local ret = {}
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()

    local deathAudioID = monsterConfigData:GetDeathAudioID(monsterID)
    if deathAudioID then
        table.insert(ret, deathAudioID)
    end

    --技能
    local skillIds = monsterConfigData:GetCacheSkillIds(monsterID)
    local t = self:_GetSkillCacheSound(skillIds)
    table.appendArray(ret, t)

    local transformID = self._transformMonsterIDDic[monsterID]
    if transformID then
        local t = self:_CacheMonsterSound(transformID)
        table.appendArray(ret, t)
    end

    --ai可能引用其他monster
    local aiidAndOrders = monsterConfigData:GetMonsterAIID(monsterID)
    for i = 1, #aiidAndOrders do
        local aiid = aiidAndOrders[i][1]
        if aiid then
            local aiConfig = AILogicConfig[aiid]
            if aiConfig then
                for _, action in pairs(aiConfig.Action) do
                    if type(action) == "table" and action.Type == "ActionCrazyMode" then
                        local transformMonsterID = action.Data[1]
                        local t = self:_CacheMonsterSound(transformMonsterID)
                        table.appendArray(ret, t)
                    end
                end
            end
        end
    end
    return ret
end

function LoadingServiceRender:_CacheTrapSound(trapId)
    local ret = {}
    local trapConfigData = self._configService:GetTrapConfigData()

    --技能
    local skillIds = trapConfigData:GetSkillIDs(trapId)
    if skillIds then
        local t = self:_GetSkillCacheSound(skillIds)
        table.appendArray(ret, t)
    end

    local trapConfig = trapConfigData:GetTrapData(trapId)

    if trapConfig.AIID then
        for i = 1, #trapConfig.AIID do
            local nConfigAiID = trapConfig.AIID[i]
            local aiConfigData = Cfg.cfg_ai[nConfigAiID]

            if aiConfigData then
                local t = self:_GetSkillCacheSound(aiConfigData.SkillList)
                table.appendArray(ret, t)
            end
        end
    end

    return ret
end

function LoadingServiceRender:_GetSkillCacheSound(skillIds)
    if not skillIds then
        return
    end
    local ret = {}
    for _, skillid in ipairs(skillIds) do
        ---@type SkillConfigData
        local skillConfig = self._configService:GetSkillConfigData(skillid)
        local skillPhaseArray = skillConfig:GetSkillPhaseArray()
        for _, phase in ipairs(skillPhaseArray) do
            local ct = phase:GetPhaseParam():GetSoundCacheTable()
            if ct and #ct > 0 then
                table.appendArray(ret, ct)
            end
        end

        local effectArray = skillConfig:GetSkillEffect()
        for key, effectValue in pairs(effectArray) do
            if effectValue:GetEffectType() == SkillEffectType.SummonEverything then
                local summonType = effectValue:GetSummonType()
                local summonIDS = effectValue:GetSummonList()
                for _key, summonID in pairs(summonIDS) do
                    if summonType == SkillEffectEnum_SummonType.Monster then
                        local t = self:_CacheMonsterSound(summonID)
                        table.appendArray(ret, t)
                    elseif summonType == SkillEffectEnum_SummonType.Trap then
                        local t = self:_CacheSummonTrapSound(summonID)
                        table.appendArray(ret, t)
                    end
                end
            elseif effectValue:GetEffectType() == SkillEffectType.AddBuff then
                local t = self:_CacheBuffSound(effectValue:GetBuffID())
                table.appendArray(ret, t)
            elseif effectValue:GetEffectType() == SkillEffectType.Transformation then
                local t = self:_CacheMonsterSound(effectValue:GetTargetMonsterID())
                table.appendArray(ret, t)
            elseif effectValue:GetEffectType() == SkillEffectType.MakePhantom then
                local t = self:_CacheMonsterSound(effectValue:GetTargetID())
                table.appendArray(ret, t)
            elseif effectValue:GetEffectType() == SkillEffectType.SummonMultipleTrap then
                local t = self:_CacheSummonTrapSound(effectValue:GetTrapID())
                table.appendArray(ret, t)
            end
        end
    end

    return ret
end

function LoadingServiceRender:_CacheBuffSound(buffID)
    local ret = {}
    -- 加载时特殊处理，如果配的buffID确实是无效值，那么不再走下面的逻辑
    -- buffID在特定配置下可能是无效的
    if not Cfg.cfg_buff[buffID] then
        return ret
    end
    ---@type BuffConfigData
    local buffConfig = self._configService:GetBuffConfigData(buffID)
    local ct = buffConfig:GetSoundCacheTable()
    if ct and #ct > 0 then
        table.appendArray(ret, ct)
    end

    --TODO技能
    --buff
    --召唤

    return ret
end

function LoadingServiceRender:_CacheSummonTrapSound(trapID)
    if table.ikey(self._cachedSoundTrapIdList, trapID) then
        return
    end
    table.insert(self._cachedSoundTrapIdList, trapID)

    local ret = self:_CacheTrapSound(trapID)
    local trapConfigData = self._configService:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(trapID)
    local logicParam = trapData.LogicParam
    if logicParam then
        local trapSummonMonsterID = logicParam.MonsterId
        if trapSummonMonsterID then
            local t = self:_CacheMonsterSound(trapSummonMonsterID)
            table.appendArray(ret, t)
        end
    end
    return ret
end

function LoadingServiceRender:_GetVoiceCacheTable()
    local ret = {}
    --table.appendArray(t, self:_GetSceneVoiceCacheTable())
    table.appendArray(ret, self:_GetPetVoiceCacheTable())
    table.appendArray(ret, self:_GetMonsterVoiceCacheTable())
    return ret
end

--宠物语音
function LoadingServiceRender:_GetPetVoiceCacheTable()
    local ret = {}
    ---@type PetModule
    local petModule = GameGlobal.GameLogic():GetModule(PetModule)
    local joinedPlayerInfoArray = self._world.BW_WorldInfo.players
    for i, joinedPlayerInfo in pairs(joinedPlayerInfoArray) do
        for petIndex, matchPetInfo in ipairs(joinedPlayerInfo.pet_list) do
            local petPstID = matchPetInfo.pet_pstid
            --local petData = MatchPet:New(matchPetInfo) --petModule:GetPet(petPstID)
            local petData
            if self._world:MatchType() == MatchType.MT_PopStar then
                petData = PopStarMatchPet:New(matchPetInfo)
            else
                petData = MatchPet:New(matchPetInfo)
            end
            --技能
            local normalSkillID = petData:GetNormalSkill()
            local chainSkill = petData:GetChainSkillInfo()
            local activeSkill = petData:GetPetActiveSkill()
            local skillIds = {normalSkillID, table.unpack(table.select(chainSkill, "Skill")), activeSkill}

            for _, skillid in ipairs(skillIds) do
                ---@type SkillConfigData
                local skillConfig = self._configService:GetSkillConfigData(skillid)
                local skillPhaseArray = skillConfig:GetSkillPhaseArray(petData:GetSkinId())
                for _, phase in ipairs(skillPhaseArray) do
                    local t = phase:GetPhaseParam():GetVoiceCacheTable()
                    if t and #t > 0 then
                        table.appendArray(ret, t)
                    end
                end
            end
        end
    end
    return ret
end

--怪物语音
function LoadingServiceRender:_GetMonsterVoiceCacheTable()
    local ret = {}
    local levelConfigData = self._configService:GetLevelConfigData()
    local monsterIds = levelConfigData:GetAllMonsterID()
    for _, monsterID in ipairs(monsterIds) do
    end

    return ret
end

function LoadingServiceRender:_CacheMonsterVoice(monsterID)
    if table.ikey(self._cachedVoiceMonsterIdList, monsterID) then
        return
    end
    table.insert(self._cachedVoiceMonsterIdList, monsterID)

    local ret = {}
    local monsterConfigData = self._configService:GetMonsterConfigData()
    --技能
    local skillIdsList = monsterConfigData:GetCacheSkillIds(monsterID)
    for _, skillIds in pairs(skillIdsList) do
        for _, skillid in ipairs(skillIds) do
            ---@type SkillConfigData
            local skillConfig = self._configService:GetSkillConfigData(skillid)
            local skillPhaseArray = skillConfig:GetSkillPhaseArray()
            for _, phase in ipairs(skillPhaseArray) do
                local ct = phase:GetPhaseParam():GetVoiceCacheTable()
                if ct and #ct > 0 then
                    table.appendArray(ret, ct)
                end
            end

            local effectArray = skillConfig:GetSkillEffect()
            for key, effectValue in pairs(effectArray) do
                if effectValue:GetEffectType() == SkillEffectType.SummonEverything then
                    local summonType = effectValue:GetSummonType()
                    local summonIDS = effectValue:GetSummonList()
                    for _key, summonID in pairs(summonIDS) do
                        if summonType == SkillEffectEnum_SummonType.Monster then
                            local t = self:_CacheMonsterVoice(ret, summonID)
                            table.appendArray(ret, t)
                        elseif summonType == SkillEffectEnum_SummonType.Trap then
                        ---机关的语音功能还没实现
                        end
                    end
                end
            end
        end
    end
    return ret
end
function LoadingServiceRender:_GetGameCacheResGroup()
    local ret = {}
    local resGroup = GameCacheResGroup:New()
    local effectcache = resGroup.EffectTable
    for k, v in pairs(effectcache) do
        local effectinfo = Cfg.cfg_effect[k]
        if effectinfo ~= nil then
            table.insert(ret, {effectinfo.ResPath, v})
        end
    end
    return ret
end

---缓存.asset文件
function LoadingServiceRender:_CacheGlobalAssetFile()
    local file_name = "globalShaderEffects.asset"
    ---@type ResourcesPoolService
    local respool = self._world.BW_Services.ResourcesPool
    respool:CacheAsset(file_name, 1)
end

---缓存.asset文件
function LoadingServiceRender:_CacheEachShaderEffectsAssetFile(file_name)
    local respool = self._world.BW_Services.ResourcesPool
    respool:CacheAsset(file_name, 1)
end

function LoadingServiceRender:_CacheGridMaterial(cacheTable)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local style = UIPropertyHelper:GetInstance():GetColorBlindStyle()
    local materialPath = ""
    local useBrillantLine = false
    local levelID = self._world.BW_WorldInfo.level_id
    local levelConfig = Cfg.cfg_level[levelID]
    local themeID = levelConfig.Theme
    local cfgThemeData = Cfg.cfg_theme[themeID]
    if style == 1 then
        materialPath = self._brillantGridMaterial
        useBrillantLine = true
        renderBoardCmpt:SetBrillantGridLineExtendParam(cfgThemeData.BrillantGridLineExtendParam)
    elseif style == 2 then
        if (not cfgThemeData.NormalMaterial) then
            Log.error("cfg_theme[", themeID, "]: NormalMaterial is nil")
            return
        end

        materialPath = cfgThemeData.NormalMaterial
    elseif style == 3 then
        materialPath = self._blindGridMaterial
    end

    renderBoardCmpt:SetGridMaterialPath(materialPath)

    ---@type ResourcesPoolService
    local respool = self._world.BW_Services.ResourcesPool
    respool:CacheMaterial(materialPath, 1)

    if useBrillantLine then
        local lineParam = cfgThemeData.BrillantWhiteLineParam
        local levelGridCellScale = lineParam and lineParam["GridCellScale"] or BattleConst.GridCellScale
        ---设置控制格子网线大小的全局变量
        UnityEngine.Shader.SetGlobalFloat("_h3d_GeziCellScale",levelGridCellScale)
    
        local req = ResourceManager:GetInstance():SyncLoadAsset(GameResourceConst.BrillantLine, LoadType.GameObject)
        renderBoardCmpt:SetBrillantGridRequest(req)

    --local gameObj = req.Obj
    --
    --local hLineList = {}
    --for hIndex = 1,10 do
    --    local childName = "h_"..hIndex
    --    local obj = GameObjectHelper.FindChild(gameObj.transform, childName)
    --    hLineList[#hLineList + 1] = obj.gameObject
    --end
    --
    --local vLineList = {}
    --for vIndex = 1,10 do
    --    local childName = "v_"..vIndex
    --    local obj = GameObjectHelper.FindChild(gameObj.transform, childName)
    --    vLineList[#vLineList + 1] = obj.gameObject
    --end
    --
    --renderBoardCmpt:SetBrillantGridLineList(hLineList,vLineList)
    end
end

function LoadingServiceRender:_PreCreateFirstWaveMonsterAndTrap(TT)
    local eMonsters = {}
    ----@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local monsterIDList = utilDataSvc:GetFirstWaveMonsterIDList()
    for _, id in ipairs(monsterIDList) do
        local entity = self._world:GetEntityByID(id)
        table.insert(eMonsters, entity)
    end
    --local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    --local eMonsters = group:GetEntities()
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:CreateMonsterHPEntities(eMonsters)

    --秘境存档恢复
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local isArchived = utilDataSvc:IsArchivedBattle()
    if isArchived then
        for _, v in pairs(eMonsters) do
            local hpCmpt = v:HP()
            local curhp = utilDataSvc:GetCurrentLogicHP(v)
            v:ReplaceRedHPAndWhitHP(curhp)
        end
    end

    YIELD(TT)

    for _, v in pairs(eMonsters) do
        ---@type Entity
        local monsterEntity = v
        monsterEntity:SetViewVisible(true)
        monsterEntity:SetLocation(
            monsterEntity:GetGridPosition() + monsterEntity:GetGridOffset(),
            monsterEntity:GetGridDirection()
        )
        monsterEntity:SetLocationHeight(BattleConst.CacheHeight)

        local hpCmpt = monsterEntity:HP()
        local hpSliderEntityID = hpCmpt:GetHPSliderEntityID()
        local hpEntity = self._world:GetEntityByID(hpSliderEntityID)
        if hpEntity then
            local go = hpEntity:View().ViewWrapper.GameObject
            local uiview = go:GetComponent("UIView")
            ---@type UISelectObjectPath
            local buffRootPath = uiview:GetUIComponent("UISelectObjectPath", "buffRoot")
            if buffRootPath then
                local buffRoot = UICustomWidgetPool:New(self, buffRootPath)
                buffRoot:SpawnObjects("UIHPBuffInfo", 1)
                ---@type UIHPBuffInfo
                local uiHPBuffInfo = buffRoot:GetAllSpawnList()[1]
                uiHPBuffInfo:SetData(monsterEntity:GetID())
                hpCmpt:SetUIHpBuffInfoWidget(buffRoot)
            end
        end
    end
end

---预先创建队伍数据
function LoadingServiceRender:_PreCreateTeam()
    ---@type RenderEntityService
    local entityServiceRender = self._world:GetService("RenderEntity")

    if self._world:MatchType() ~= MatchType.MT_Chess then
        entityServiceRender:CreateBattleTeamMemberRender()
        entityServiceRender:CreateBattleTeamRender()
    elseif self._world:MatchType() == MatchType.MT_Chess then
        entityServiceRender:CreateChessPet()
    end
end

---根据PetData来计算需要Cache的资源列表
---@param listPetData MatchPet[]
function LoadingServiceRender:_GetCacheTable_ByPetData(listPetData)
    local ret = {}
    ---@param petData MatchPet
    for petIndex, petData in ipairs(listPetData) do
        --模型
        local heroPrefab = petData:GetPetPrefab(PetSkinEffectPath.MODEL_INGAME)
        table.appendArray(ret, {{heroPrefab, 1}})
        local heroAncName =
            HelperProxy:GetInstance():GetPetAnimatorControllerName(heroPrefab, PetAnimatorControllerType.Battle)
        table.appendArray(ret, {{heroAncName, 1}})

        --技能修改为延迟加载
        local normalSkillID = petData:GetNormalSkill()
        local chainSkill = petData:GetChainSkillInfo()
        local activeSkill = petData:GetPetActiveSkill()
        local skinId = petData:GetSkinId()
        local skillIds = {normalSkillID, table.unpack(table.select(chainSkill, "Skill")), activeSkill}
        local t = self:_GetSkillCacheTable(skillIds, skinId)
        table.appendArray(ret, t)
        -- table.appendArray(self._loadAfterLoading, t)

        --被动技能
        local passiveSkillID = petData:GetPetPassiveSkill()
        if passiveSkillID and passiveSkillID > 0 then
            local cfg = Cfg.cfg_passive_skill[passiveSkillID]
            local t = self:_GetBuffCacheTable(cfg.BuffID)
            table.appendArray(ret, t)
        end

        --特殊材质动画
        local shaderEffect = petData:GetPetShaderEffect()
        if shaderEffect then
            self:_CacheEachShaderEffectsAssetFile(shaderEffect)
        end

        --常驻挂点特效
        local templateID = petData:GetTemplateID()
        local permanentEffectArray = Cfg.cfg_pet[templateID].BattlePermanentEffect
        if permanentEffectArray and #permanentEffectArray then
            for _, effectID in ipairs(permanentEffectArray) do
                local cfgEffect = Cfg.cfg_effect[effectID]
                if cfgEffect then
                    table.insert(ret, {cfgEffect.ResPath, 1})
                end
            end
        end
    end
    return ret
end
function LoadingServiceRender:CacheObject_MatchPet(TT, listMatchPet)
    local respool = self._world.BW_Services.ResourcesPool
    local listRes = self:_GetCacheTable_ByPetData(listMatchPet)
    -- local nCountRes = table.count(listRes)
    -- local oneProcess = (maxProcess - self._LoadProcessValue) / count

    local tmClockLoad = os.clock()
    for keystr, v in pairs(listRes) do
        local resname = v[1]
        local count = v[2]
        if string.endwith(resname, ".mat") then
            respool:CacheMaterial(resname, count)
        else --if string.endwith(resname, ".prefab") then 默认为prefab
            respool:Cache(resname, count)
        end
        -- self:_UpdateLoadingProcess(self._LoadProcessValue + oneProcess)
        -- YIELD(TT)
        -- local tok = os.clock()
        -- table.insert(self._loadingTimeTable, {name = "CacheObject/" .. keystr, time = (tok - tik) * 1000})
        local tmClockNow = os.clock()
        if tmClockNow - tmClockLoad >= 4 then
            YIELD(TT)
            tmClockLoad = tmClockNow
        end
    end
    -- self:_UpdateLoadingProcess(maxProcess)
end

function LoadingServiceRender:_ReplaceCachedGridMaterial()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()

    ---@type ResourcePoolService
    local respool = self._world.BW_Services.ResourcesPool
    local mat = respool:LoadMaterial(gridMatPath)

    ---@type BoardServiceRender
    local boardsvcR = self._world:GetService("BoardRender")
    ---@type PieceServiceRender
    local piecesvc = self._world:GetService("Piece")

    for enumName, enumVal in pairs(PieceType) do
        local gridPath = boardsvcR:_GetGridPrefabPath(enumVal)

        ---@type ResCacheInfo
        local resCacheInfo = respool._cacheTable[gridPath]
        ---@type ArrayList
        local reslist = resCacheInfo.reslist
        if reslist and #(reslist.elements) > 0 then
            for _, go in ipairs(reslist.elements) do
                piecesvc:ReplaceGridGameObjectMaterial(go.Obj, mat)
            end
        end
    end
end

function LoadingServiceRender:_InitializeLoadingEntity(TT)
    ---最后一击的特效Entity
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local effectEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.FinalAttackEffect)
    ---临时配在这里，后边提取到一个统一配置文件里
    local resPath = "eff_finalatk.prefab"
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, false))

    ---创建引导的手指
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    sEntity:CreateRenderEntity(EntityConfigIDRender.GuideFinger)

    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    sEntity:CreateRenderEntity(EntityConfigIDRender.LinkageInfo)

    ---初始化队长脚底行动箭头
    ---@type CanMoveArrowService
    local canMoveArrowService = self._world:GetService("CanMoveArrow")
    --canMoveArrowService:Initialize()
    --修改前 Initialize 中会创建箭头，这个方法调用了两次，现在创建箭头挪到InitArrows中，为保持表现一致，也调用两次
    canMoveArrowService:InitArrows()
    canMoveArrowService:InitArrows()
end
