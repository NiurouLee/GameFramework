_class("HomeMovieStoryManager", Object)
---@class HomeMovieStoryManager:Object
HomeMovieStoryManager = HomeMovieStoryManager

function HomeMovieStoryManager:Constructor(
    storyID,
    uiController,
    mainCameraGo,
    rootGameObject,
    modelRoot,
    dialogRootGameObject,
    buttonRootGameObject,
    leftButtonRootGameObject,
    maskTemplate,
    uiAtlas,
    revertBGM,
    ignoreBreak,
    openTease,
    isRecord
)

    --传给下面的选项pool用
    self._UIHomeStoryController = uiController
    ---@type number 剧情ID
    self._storyID = storyID
    self._rootGameObject = rootGameObject
    ---@type UnityEngine.GameObject 剧情界面根节点
    ---@type UnityEngine.GameObject _3d物体的根节点
    self._modelRoot = modelRoot
    self.RootRotation = self._modelRoot.transform.rotation
    ---@type UnityEngine.GameObject 剧情对话框根节点
    self._dialogRootGameObject = dialogRootGameObject
    ---@type UnityEngine.GameObject 功能按钮根节点
    self._buttonRootGameObject = buttonRootGameObject
    ---@type UnityEngine.GameObject 跳过外功能按钮根节点
    self._leftButtonRootGameObject = leftButtonRootGameObject
    ---@type UnityEngine.GameObject Mask模板
    self._maskTemplate = maskTemplate
    ---@type UnityEngine.Camera
    self._mainCamera = mainCameraGo
    self._mainCameraTr = mainCameraGo.transform
    self._mainCameraTr.localPosition = Vector3(0,0,0)
    self._mainCameraTr.rotation = Quaternion.identity
    self._mainCameraTr.localScale = Vector3(1,1,1)

    self._openTease = openTease
    self._isRecord = isRecord

    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAtlas = uiAtlas
    ---@type boolean
    self._revertBGM = true
    ---@type boolean
    self._ignoreBreak = ignoreBreak
    
    ---@type boolean 剧情结束标识
    self._end = false
    ---@type table 剧情配置
    self._storyConfig = nil

    --存储加载的动画资源，最后释放
    self._animResList = {}

    ---@type HomeStoryBgmTrackController bgm轨道控制器
    self._storyBgmTrackController = HomeStoryBgmTrackController:New(self)
    ---@type HomeStoryCameraTrackController 相机轨道控制器
    self._storyCameraTrackController = HomeStoryCameraTrackController:New(self)

    ---@type UnityEngine.Rect
    self._canvasRect = rootGameObject.transform.parent.parent:GetComponent("RectTransform").rect

    ---运行时数据
    ---@type table<int, HomeStoryEntity> 剧情元素列表
    self._storyEntityList = {}
    ---@type table<int, table> 段落列表
    self._paragraphList = {}
    ---@type number 当前段落ID
    self._currentParagraphID = -1
    ---@type number 下一段落ID
    self._nextParagraphID = nil
    ---@type number 当前小节序号
    self._currentSectionIndex = 1
    ---@type number 当前播放时间
    self._currentTime = 0
    ---@type table<table, boolean> 当前轨道数据
    self._currentTrackData = {}

    ---@type bool 当前是否处于UI隐藏状态
    self._hide = false
    ---@type bool 当前是否处于自动状态
    self._auto = false

    ---@type table<int, string> 剧情回看内容
    self._dialogRecord = {}

    ---@type boolean 进入剧情前的bgm播放状态
    self._orgBgmPlaying = false
    ---@type string 进入剧情前的bgm
    self._orgBgm = nil

    ---@type number 还原bgm过渡时间配置
    self._orgBgmFadeTime = 0.5

    ---@type SortedDictionary 剧情元素的层级数据 (SortedDictionary<int, table<int, UnityEngine.Transform>>)
    self._layerDic = SortedDictionary:New()
    self._layerDic:Insert(1, {})

    --以前调试的变体，现在不用了，现在用在编辑状态判断
    ---@type boolean
    self._debugMode = false
    ---@type UnityEngine.GameObject
    self._entityInfoTemplate = nil

    --跨Section执行的相机震动数据
    self._loopCameraShakeData = {
        running = false,
        shakeData = {},
        timer = 0,
        curDuration = 0,
        tweener = nil
    }
    -- 本地存段落的index
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstid = roleModule:GetPstId()
    self._localBreakParapraphMark = pstid .. "LOCAL_BREAK_PARAGRAPH_INDEX"

    self._BeSkipped = 0

    AudioHelperController.RequestUISound(CriAudioIDConst.SoundStoryClick)

    --存储需要自动恢复stand动画的entity
    self._recovertStandList = {}
end

---初始化剧情管理器
function HomeMovieStoryManager:Init(debugMode, entityInfoTemplate, yieldTime,isViewEnter)
    --默认不走事件
    isViewEnter = true
    local storyConfigItem =nil

    self._startTime = os.time()
    if EditorGlobal.IsEditorMode() then
        self._storyConfig = EditorGlobal.GetEditorRunStoryConfig()
        local editorStoryID = self._storyConfig.ID
        storyConfigItem = Cfg.cfg_homeland_event[editorStoryID]
        if storyConfigItem then
            --处理部分电影根节点偏移错误
            if storyConfigItem.StoryRootPosOffset then                
                local tmp_tr = self._UIHomeStoryController._storyRoot.transform
                if tmp_tr then
                    local vec = Vector3(storyConfigItem.StoryRootPosOffset[1], storyConfigItem.StoryRootPosOffset[2], storyConfigItem.StoryRootPosOffset[3])
                    local pos = tmp_tr.position - vec * tmp_tr.rotation
                    tmp_tr.localPosition = pos
                    tmp_tr.localScale = tmp_tr.localScale
                    tmp_tr.rotation = tmp_tr.rotation
                end
            end
        end
    else
        local cfg = Cfg.cfg_home_story[self._storyID]
        if not cfg then
            Log.exception("配表中不存在storyID ", self._storyID)
        end
        local res, story = dofile(cfg.StoryScript)
        self._storyConfig = story

        storyConfigItem = Cfg.cfg_homeland_event[self._storyID]
        if storyConfigItem then
            --处理部分电影根节点偏移错误
            if storyConfigItem.StoryRootPosOffset then
                local vec = Vector3(storyConfigItem.StoryRootPosOffset[1], storyConfigItem.StoryRootPosOffset[2], storyConfigItem.StoryRootPosOffset[3])
                self._eventMgr = self._UIHomeStoryController._eventMgr
                local trans = self._eventMgr:GetStoryRoot().transform
                local pos = trans.position - vec * trans.rotation
                self._eventMgr:SetStoryRoot(pos, trans.rotation, trans.localScale)
            end
        end
    end
    if not self._storyConfig then
        Log.fatal("###[HomeMovieStoryManager] can not find story, id: " .. self._storyID)
        self._end = true
        return
    end
    -- 断点序列
    self._debugMode = debugMode
    self._entityInfoTemplate = entityInfoTemplate
    if not self._ignoreBreak then
        self._breakParagraphIds = self._storyConfig.breakParagraphIds
    end
    if self._breakParagraphIds then
        local breakIdx = LocalDB.GetInt(self._localBreakParapraphMark, 0)
        if breakIdx > 0 then
            self._currentParagraphID = self._breakParagraphIds[breakIdx]
        else
            self._currentParagraphID = self._storyConfig.StartParagraph
        end
    else
        self._currentParagraphID = self._storyConfig.StartParagraph
    end

    --还原bgm数据
    if self._revertBGM then
        self._orgBgmPlaying = AudioHelperController.BGMPlayerIsPlaying()
        if self._orgBgmPlaying then
            self._orgBgm = AudioHelperController.GetCurrentBgm() 
        end
    end

    
    --默认把这个root放在玩家的位置，后面根据剧情id来配置这个root的位置（用作处理位置偏移用）
    -- local playerPos
    -- if storyConfigItem and storyConfigItem.StoryRootPos then
    --     playerPos = Vector3(storyConfigItem.StoryRootPos[1],storyConfigItem.StoryRootPos[2],storyConfigItem.StoryRootPos[3])
    -- else
    --     playerPos = Vector3(0,0,0)
    -- end
    -- local playerRot
    -- if storyConfigItem and storyConfigItem.StoryRootRot then
    --     playerRot = Quaternion.Euler(Vector3(storyConfigItem.StoryRootRot[1],storyConfigItem.StoryRootRot[2],storyConfigItem.StoryRootRot[3]))
    -- else
    --     playerRot = Quaternion.identity
    -- end
    -- self._modelRoot.transform.position = playerPos
    -- self._modelRoot.transform.rotation = playerRot

    --初始化剧情元素 加载资源
    self:_InitEntities()

    --初始化剧情数据
    self:_InitParagraphs()

    --暂时取消yieldtime
    if yieldTime and yieldTime > 0 and false then
        GameGlobal.UIStateManager():Lock("HomeMovieStoryManager_yieldTime")
        GameGlobal.Timer():AddEvent(yieldTime,
        function()
            GameGlobal.UIStateManager():UnLock("HomeMovieStoryManager_yieldTime")
            self:_StartSection()
        end)
    else 
        self:_StartSection()
    end
    if EditorGlobal.IsEditorMode() then
        local editorparam = EditorGlobal.GetEnterParam()
        self:_Seek(editorparam.ParagraphID, editorparam.SectionID)
    end

    --找到H3DRenderSetting重新激活
    local findName = "[H3DRenderSetting]"
    local findGo = UnityEngine.GameObject.Find(findName)
    if findGo then
        local h3dSetting = findGo:GetComponent(typeof(H3DRenderSetting))
        if h3dSetting then
            h3dSetting.enabled = false
            h3dSetting.enabled = true
        end
    end
end

---设置下一段落ID
---@param ID number
function HomeMovieStoryManager:SetNextParagraphID(ID)
    self._nextParagraphID = ID
end

---获取当前小节更新时间
---@return number
function HomeMovieStoryManager:GetCurrentTime()
    return self._currentTime
end

---获取剧情内容UI根节点
---@return UnityEngine.GameObject
function HomeMovieStoryManager:GetStoryUIRoot()
    return self._rootGameObject
end

---获取屏幕尺寸
---@return UnityEngine.Rect
function HomeMovieStoryManager:GetCanvasRect()
    return self._canvasRect
end

---获取剧情对话框UI根节点
---@return UnityEngine.GameObject
function HomeMovieStoryManager:GetStoryDialogUIRoot()
    return self._dialogRootGameObject
end
---获取Mask模板
---@return UnityEngine.GameObject
function HomeMovieStoryManager:GetMaskTemplate()
    return self._maskTemplate
end
---获取剧情界面的atlas
---@return UnityEngine.U2D.SpriteAtlas
function HomeMovieStoryManager:GetUIAtlas()
    return self._uiAtlas
end

---播放音效
---@param entityID number
function HomeMovieStoryManager:PlaySound(entityID)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == HomeStoryEntityType.Sound then
        soundEntity:PlaySound()
    end
end

---停止音效
---@param entityID number
function HomeMovieStoryManager:StopSound(entityID)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == HomeStoryEntityType.Sound then
        soundEntity:StopSound()
    end
end

---播放bgm
---@param entityID number
function HomeMovieStoryManager:PlayBgm(entityID, bgmFadeTime)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == HomeStoryEntityType.Sound then
        soundEntity:PlayBgm(bgmFadeTime)
    end
end
--获取一个entity
function HomeMovieStoryManager:GetEntity(id)
    local entity = self._storyEntityList[id]
    if entity then
        return entity
    end
end
--获取一个实体的go
function HomeMovieStoryManager:GetEntityGo(id)
    local entity = self._storyEntityList[id]
    if entity then
        return entity:GetEntityGo()
    end
end
--获取该实体的位置
function HomeMovieStoryManager:GetEntityPos(entityID)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == HomeStoryEntityType.Model then
        return soundEntity:Pos()
    end
end
--
function HomeMovieStoryManager:ActiveEntity(entityID,active)
    local entity = self._storyEntityList[entityID]
    if entity and entity:GetEntityType() == HomeStoryEntityType.Model then
        entity:SetActive(active)
    end
end
--
function HomeMovieStoryManager:SetEntityPos(entityID,pos)
    local entity = self._storyEntityList[entityID]
    if entity and entity:GetEntityType() == HomeStoryEntityType.Model then
        entity:SetPos(pos)
    end
end
--
function HomeMovieStoryManager:GetEntityHeadPos(entityID)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == HomeStoryEntityType.Model then
        return soundEntity:HeadPos()
    end
end
---播放说话动作
---@param entityID number
---@param speaking boolean
function HomeMovieStoryManager:SetSpeakState(entityID, speaking)
    local spineEntity = self._storyEntityList[entityID]
    if spineEntity and spineEntity:GetEntityType() == HomeStoryEntityType.Spine then
        spineEntity:SetSpeak(speaking)
    end
end

---添加对话回看内容
---@param speaker string 说话人的姓名文本内容(国际化转换之后)
---@param content string 说话内容(国际化转换之后)
function HomeMovieStoryManager:AddDialogRecord(speaker, content, isPlayer, icon, tips)
    self._dialogRecord[#self._dialogRecord + 1] = {speaker, content, isPlayer, icon, tips}
end

---获取记录的对话内容
---@return table<int, string>
function HomeMovieStoryManager:GetDialogRecord()
    return self._dialogRecord
end

---初始化层级数据 默认层级都是1
---@param trans UnityEngine.Transform
function HomeMovieStoryManager:InitLayerInfo(trans)
    local layerTable = self._layerDic:Find(1)
    layerTable[#layerTable + 1] = trans
end

---设置层级
---@param trans UnityEngine.Transform
---@param layer number
function HomeMovieStoryManager:SetLayer(trans, layer)
    local layerDic = self._layerDic
    for i = 1, layerDic:Size() do
        local layerTable = layerDic:GetAt(i)
        table.removev(layerTable, trans)
    end
    local layerTable = self._layerDic:Find(layer)
    if layerTable == nil then
        layerTable = {}
        self._layerDic:Insert(layer, layerTable)
    end
    layerTable[#layerTable + 1] = trans

    self:_resetLayers()
end

function HomeMovieStoryManager:_resetLayers()
    local layerDic = self._layerDic
    for i = 1, layerDic:Size() do
        ---@type table<int, UnityEngine.Transform>
        local layerTable = layerDic:GetAt(i)
        for j = 1, #layerTable do
            layerTable[j]:SetAsLastSibling()
        end
    end
end

function HomeMovieStoryManager:_InitEntities()
    local entityConfig = self._storyConfig["Entities"]
    if not entityConfig then
        return
    end

    for _, entity in ipairs(entityConfig) do
        local storyEntity = self:_CreateStoryEntity(entity.EntityID, entity.Type, entity.Resource, entity)
        if storyEntity then
            self._storyEntityList[storyEntity:GetID()] = storyEntity
        else
            if entity.SubType ~= "Furniture" then
                self._end = true
                return
            end
        end
    end
end

function HomeMovieStoryManager:_InitParagraphs()
    self._paragraphList = self._storyConfig["Paragraphs"]
    --段落小节是否需要额外的运行时数据?
    local paragraph = self._paragraphList[self._currentParagraphID]
    if not paragraph then
        Log.fatal("###[HomeMovieStoryManager] 不存在ID为" .. self._currentParagraphID .. "的剧情段落,剧情结束")
        self._end = true
        return
    end

    if paragraph.NextParagraphID then
        self:SetNextParagraphID(paragraph.NextParagraphID)
    end
end

---@return HomeStoryEntity
function HomeMovieStoryManager:_CreateStoryEntity(ID, type, resourceName, entityConfig)
    local request = nil
    local gameObject = nil
    local skinid = nil
    if type == "Effect" or type == "Dialog" or type == "Model" or type == "CameraVC" or type == "Picture" or type == "Spine" then
        if type == "Model" then
            --model放在这里单独加载，因为要绑定动画啥的挺长的
            request,gameObject,skinid = self:LoadModel(entityConfig)
            if request then
                gameObject.transform:SetParent(self._modelRoot.transform, false)
            else
                if entityConfig.SubType ~= "Furniture" then
                    self._end = true
                end
                return
            end
        else
            request = ResourceManager:GetInstance():SyncLoadAsset(resourceName, LoadType.GameObject)
            
            if request then
                gameObject = request.Obj
                if type == "Dialog" then
                    gameObject.transform:SetParent(self._dialogRootGameObject.transform, false)
                elseif type == "CameraVC" then
                    gameObject.transform:SetParent(self._modelRoot.transform, false)
                else
                    gameObject.transform:SetParent(self._rootGameObject.transform, false)
                end
            else
                self._end = true
                return
            end
        end
    end

    local storyEntity = nil
    if type == "Dialog" then
        --支持吐槽提词
        storyEntity = HomeMovieEntityDialog:New(ID, gameObject, request, self, self._UIHomeStoryController, self._openTease, self._isRecord)
    elseif type == "Effect" then
        storyEntity = HomeStoryEntityEffect:New(ID, gameObject, request, self, self._UIHomeStoryController)
    elseif type == "Sound" then
        storyEntity = HomeStoryEntitySound:New(ID, resourceName, self)
    elseif type == "PostProcessing" then
        storyEntity = HomeStoryEntityPostProcessing:New(ID, resourceName, self)
    elseif type == "Model" then
        storyEntity = HomeStoryEntityModel:New(ID, gameObject, request, self, entityConfig, self._modelRoot.transform,skinid)
    elseif type == "Picture" then
        storyEntity = HomeStoryEntityPicture:New(ID, gameObject, request, self, entityConfig)
    elseif type == "CameraVC" then
        storyEntity = HomeStoryEntityCameraVC:New(ID, gameObject, request, self, entityConfig)
    elseif type == "Spine" then
        storyEntity = HomeMovieEntitySpine:New(ID, gameObject, request, self, self._UIHomeStoryController, entityConfig)
    end

    return storyEntity
end
function HomeMovieStoryManager:DisposeAnimRes()
    if self._animResList and #self._animResList > 0 then
        for i = 1, #self._animResList do
            self._animResList[i]:Dispose()
        end
    end
    self._animResList = nil
end
function HomeMovieStoryManager:LoadModel(cfg)
    -- 星灵和玩家都用animation，重新再加模型进行绑定
    -- 都用animation后面播动画就可以用一套了
    local resName = nil
    local request = nil
    local go = nil
    local skinid = nil
    --开始绑定
    if cfg.SubType == "Pet" then
        local petid = cfg.PetID
        if petid and not self._debugMode then
            ---@type Pet
            local pet = GameGlobal.GetModule(PetModule):GetPetByTemplateId(petid)
            if pet then
                resName = pet:GetPetPrefab()
            else
                resName = cfg.Resource
                petid = string.gsub(resName, ".prefab", "")
            end
        else
            resName = cfg.Resource
            petid = string.gsub(resName, ".prefab", "")
        end

        skinid = string.gsub(resName, ".prefab", "")

        request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
        if request then
            go = request.Obj
        end

        local root = go.transform:Find("Root").gameObject
        local animator = root:GetComponent(typeof(UnityEngine.Animator))
        UnityEngine.Object.Destroy(animator)
        local animation = root:AddComponent(typeof(UnityEngine.Animation))

        local _aircraftAnimName = HelperProxy:GetInstance():GetPetAnimatorControllerName(resName, PetAnimatorControllerType.Aircraft)
        local _homelandAnimName = HelperProxy:GetInstance():GetPetAnimatorControllerName(resName, PetAnimatorControllerType.Homeland)
        local homelandStoryAnimName = HelperProxy:GetInstance():GetPetAnimatorControllerName(resName, PetAnimatorControllerType.HomelandStory)
        local airReq = ResourceManager:GetInstance():SyncLoadAsset(_aircraftAnimName, LoadType.GameObject)
        local homeReq = ResourceManager:GetInstance():SyncLoadAsset(_homelandAnimName, LoadType.GameObject)
        local homeStoryReq = ResourceManager:GetInstance():SyncLoadAsset(homelandStoryAnimName, LoadType.GameObject)

        if airReq then
            local airAnim = airReq.Obj:GetComponent(typeof(UnityEngine.Animation))
            if airAnim then
                local clips_air = HelperProxy:GetInstance():GetAllAnimationClip(airAnim)
                for i = 0, clips_air.Length - 1 do
                    if clips_air[i] == nil then
                        Log.exception("###[HomeMovieStoryManager] Pet animation is null:", petid, ", index:", i)
                    else
                        animation:AddClip(clips_air[i], clips_air[i].name)
                    end
                end
                animation.clip = airAnim.clip
            end
        end
        if homeReq then
            local homeAnim = homeReq.Obj:GetComponent(typeof(UnityEngine.Animation))
            if homeAnim then
                local clips_home = HelperProxy:GetInstance():GetAllAnimationClip(homeAnim)
                for i = 0, clips_home.Length - 1 do
                    if clips_home[i] == nil then
                        Log.exception("###[HomeMovieStoryManager] Pet animation is null:", petid, ", index:", i)
                    else
                        animation:AddClip(clips_home[i], clips_home[i].name)
                    end
                end
            end
        end
        if homeStoryReq then
            local homeStoryAnim = homeStoryReq.Obj:GetComponent(typeof(UnityEngine.Animation))
            if homeStoryAnim then
                local clips_home = HelperProxy:GetInstance():GetAllAnimationClip(homeStoryAnim)
                for i = 0, clips_home.Length - 1 do
                    if clips_home[i] == nil then
                        Log.exception("###[HomeStoryManager] Pet animation is null:", petid, ", index:", i)
                    else
                        animation:AddClip(clips_home[i], clips_home[i].name)
                    end
                end
            end
        end
        animation:Play(HomelandPetAnimName.Stand)

        if airReq then
            table.insert(self._animResList,airReq)
        end
        if homeReq then
            table.insert(self._animResList,homeReq)
        end
        if homeStoryReq then
            table.insert(self._animResList,homeStoryReq)
        end

        --隐藏武器
        local rootTr = root.transform
        for i = 0, rootTr.childCount - 1 do
            local child = rootTr:GetChild(i)
            if string.find(child.name, "weapon") then
                child.gameObject:SetActive(false)
            end
        end
    elseif cfg.SubType == "Player" then
        resName = cfg.Resource
        request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
        if request then
            go = request.Obj
        end

        local _name = string.gsub(resName, ".prefab", "")
        skinid = string.gsub(resName, ".prefab", "")
        --拼装animator
        local _aniResReq =
        ResourceManager:GetInstance():SyncLoadAsset(_name .. "_battle.prefab", LoadType.GameObject)
        ---@type UnityEngine.Animator
        local anim = _aniResReq.Obj:GetComponent(typeof(UnityEngine.Animator))       
        ---@type UnityEngine.Animator
        local animator = go:GetComponentInChildren(typeof(UnityEngine.Animator))
        animator.runtimeAnimatorController = anim.runtimeAnimatorController
        if _aniResReq then
            table.insert(self._animResList,_aniResReq)
        end
    elseif cfg.SubType == "Other" then
        resName = cfg.Resource
        request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
        if request then
            go = request.Obj
        end
    elseif cfg.SubType == "NPC" then
        resName = cfg.Resource
        request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
        if request then
            go = request.Obj
        end
        local root = go.transform:Find("Root").gameObject
        --隐藏武器
        local rootTr = root.transform
        for i = 0, rootTr.childCount - 1 do
            local child = rootTr:GetChild(i)
            if string.find(child.name, "weapon") then
                child.gameObject:SetActive(false)
            end
        end
    elseif cfg.SubType == "Furniture" then
        local endList
        if EditorGlobal.IsEditorMode() then        
            endList = EditorGlobal.GetFurnitureList()
            for _, v in pairs(endList) do
                if v == cfg.Condition then
                    resName = cfg.Resource
                    request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
                    if request then
                        go = request.Obj
                    end
                end
            end
        else
            if self._isRecord then
                local playBackData = MoviePrepareData:GetInstance():GetPlayBackData()
                endList = playBackData.chose_item
                for _, v in pairs(endList) do
                    if v == cfg.Condition then
                        resName = cfg.Resource
                        request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
                        if request then
                            go = request.Obj
                        end
                    end
                end     
            else
                endList = HomelandMoviePrepareManager:GetInstance():GetSelectedData(MoviePrepareType.PT_Prop)
                for _, v in pairs(endList) do
                    if v:GetItemId() == cfg.Condition then
                        resName = cfg.Resource
                        request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
                        if request then
                            go = request.Obj
                        end
                    end
                end            
            end
        end
    else
        resName = cfg.Resource
        request = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
        if request then
            go = request.Obj
        end
    end
    if not request then
        Log.error("###[HomeMovieStoryManager] cfg find asset name : ",resName)
    end
    return request,go,skinid
end

function HomeMovieStoryManager:_StartSection()
    local paragraph = self._paragraphList[self._currentParagraphID]
    if not paragraph then
        Log.fatal("###[HomeMovieStoryManager] 不存在ID为" .. self._currentParagraphID .. "的剧情段落,剧情结束")
        self._end = true
        return
    end

    local section = paragraph.Sections[self._currentSectionIndex]
    if not section then
        Log.fatal("###[HomeMovieStoryManager] 剧情段落'" .. self._currentParagraphID .. "'中不存在序号为" .. self._currentSectionIndex .. "的小节,剧情结束")
        self._end = true
        return
    end
    --self._sectionStartTime = os.time()

    if paragraph.ForceAutoDialog then
        self._leftButtonRootGameObject:SetActive(false)
    else
        self._leftButtonRootGameObject:SetActive(true)
    end

    for trackID, track in ipairs(section) do
        self._currentTrackData[track] = false
        if track.RefEntityID then
            local storyEntity = self._storyEntityList[track.RefEntityID]
            if storyEntity then
                storyEntity:SectionStart(track)

                if self._debugMode and self._entityInfoTemplate and storyEntity._gameObject then
                    local entityDebugInfo = storyEntity._gameObject.transform:Find("EntityInfo")
                    if not entityDebugInfo then
                        ---@type UnityEngine.GameObject
                        entityDebugInfo =
                            UnityEngine.GameObject.Instantiate(
                            self._entityInfoTemplate,
                            storyEntity._gameObject.transform
                        )
                        entityDebugInfo.transform.localPosition = Vector3(-120, 40, 0)
                        entityDebugInfo:SetActive(true)
                    end
                    entityDebugInfo.transform:Find("EntityIDText"):GetComponent("Text").text =
                        "EntityID:" .. storyEntity._ID
                    entityDebugInfo.transform:Find("TrackIDText"):GetComponent("Text").text = "TrackID:" .. trackID
                end
            end
        elseif track.BgmTrack then
            self._storyBgmTrackController:SectionStart(track)
        elseif track.CameraTrack then
            self._storyCameraTrackController:SectionStart(track)
        end
    end

    -- if section.NextParagraphID then
    --     self:SetNextParagraphID(section.NextParagraphID)
    -- end

    if section.ButtonVisible ~= nil then
        self._buttonRootGameObject:SetActive(section.ButtonVisible and not self._auto and not self._hide)
    --Log.fatal(tostring(self._buttonRootGameObject.activeSelf))
    end
    --段落跳转
    if section.Branch then
        local nextParagraphID = nil
        local endList = nil
        if EditorGlobal.IsEditorMode() then        
            endList = EditorGlobal.GetFurnitureList()
            for k, v in pairs(endList) do
                if k == section.Branch[1].MovieItemID then
                    local itemID = v
                    for _, b in pairs(section.Branch) do
                        if tonumber(b.Condition) == itemID then
                            nextParagraphID = b.NextParagraphID
                        end
                    end
                end
            end
        else
            if self._isRecord then
                local playBackData = MoviePrepareData:GetInstance():GetPlayBackData()
                endList = playBackData.chose_item
                for k, v in pairs(endList) do
                    if k == section.Branch[1].MovieItemID then
                        local itemID = v
                        for _, b in pairs(section.Branch) do
                            if tonumber(b.Condition) == itemID then
                                nextParagraphID = b.NextParagraphID
                            end
                        end
                    end
                end     
            else
                endList = HomelandMoviePrepareManager:GetInstance():GetSelectedData(MoviePrepareType.PT_Prop)
                for _, v in pairs(endList) do
                    if v:GetTitleId() == section.Branch[1].MovieItemID then
                        local itemID = v:GetItemId()
                        for _, v in pairs(section.Branch) do
                            if tonumber(v.Condition) == itemID then
                                nextParagraphID = v.NextParagraphID
                            end
                        end
                    end
                end      
            end
        end

        if nextParagraphID then
            self:SetNextParagraphID(nextParagraphID)
            return
        end
    end

    if section.NextParagraphID then
        self:SetNextParagraphID(section.NextParagraphID)
    end
end

function HomeMovieStoryManager:_EndSection()
    --local costSecond = os.time() - self._sectionStartTime
    for track, _ in pairs(self._currentTrackData) do
        self._currentTrackData[track] = true
        if track.RefEntityID then
            local storyEntity = self._storyEntityList[track.RefEntityID]
            if storyEntity then
                storyEntity:SectionEnd()
            end
        elseif track.BgmTrack then
            self._storyBgmTrackController:SectionEnd()
        elseif track.CameraTrack then
            self._storyCameraTrackController:SectionEnd()
        end
    end
end

function HomeMovieStoryManager:_UpdateTracks()
    if self._skipGaragraph then
        self._skipGaragraph = false
        return true
    end
    local allTrackEnd = true
    for track, trackEnd in pairs(self._currentTrackData) do
        if not trackEnd then
            if track.RefEntityID then
                local storyEntity = self._storyEntityList[track.RefEntityID]
                local trackEnd = true
                if storyEntity then
                    trackEnd = storyEntity:Update(self._currentTime)
                end
                self._currentTrackData[track] = trackEnd
                if not trackEnd then
                    allTrackEnd = trackEnd
                end
            elseif track.BgmTrack then
                self._storyBgmTrackController:Update(self._currentTime)
            elseif track.CameraTrack then
                local cameraTrackEnd = self._storyCameraTrackController:Update(self._currentTime)
                if not cameraTrackEnd then
                    allTrackEnd = cameraTrackEnd
                end
            end
        end
    end
    return allTrackEnd
end

---@return boolean 是否结束
function HomeMovieStoryManager:IsEnd()
    return self._end
end

---@param delteTimeMS number 更新时间毫秒
function HomeMovieStoryManager:Update(delteTimeMS)
    if self._end then
        return
    end
    self._currentTime = self._currentTime + delteTimeMS / 1000
    local sectionEnd = self:_UpdateTracks()
    --Log.fatal("sectionEnd:"..tostring(sectionEnd))

    if sectionEnd then
        self:_EndSection()
        self._currentSectionIndex = self._currentSectionIndex + 1
        if self._paragraphList[self._currentParagraphID].Sections[self._currentSectionIndex] then
            --还有下一小节
            self:_StartSection()
            self._currentTime = 0
            --按照小节长度一定在一帧以上来处理 小节更换立刻更新下一小节第0帧动画
            self:_UpdateTracks()
        else
            if not self._nextParagraphID or self._nextParagraphID == self._currentParagraphID then
                --self:_Destroy()
                --没有下一段落 剧情结束
                self._end = true
            else
                --还有下一段落
                self._currentParagraphID = self._nextParagraphID
                if self._breakParagraphIds then
                    local breakIdx = table.ikey(self._breakParagraphIds, self._currentParagraphID)
                    if breakIdx then
                        LocalDB.SetInt(self._localBreakParapraphMark, breakIdx)
                    end
                end
                self._currentSectionIndex = 1
                self._currentTime = 0
                self:_StartSection()
                self:_UpdateTracks()
            end
        end
    end

    self:_UpdateLoopCameraShake(delteTimeMS / 1000)
    self:_UpdateCameraPathAndFov(delteTimeMS/1000)
end
function HomeMovieStoryManager:RemoveRecoverStandEntity(entityid)
    Log.debug("###[recover stand] 移除entity:",entityid)
    if self._recovertStandList[entityid] then
        
        local hadEvent = self._recovertStandList[entityid]
        GameGlobal.Timer():CancelEvent(hadEvent)
        self._recovertStandList[entityid] = nil
        
        Log.debug("###[recover stand] 移除成功")
    end
end
function HomeMovieStoryManager:AddRecoverStandEntity(length,entityid)
    Log.debug("###[recover stand] 添加entity:",entityid)

    if self._recovertStandList[entityid] then
        
        local hadEvent = self._recovertStandList[entityid]
        GameGlobal.Timer():CancelEvent(hadEvent)
        hadEvent = nil

        Log.debug("###[recover stand] 已经存在，移除成功")
    end
    local event = GameGlobal.Timer():AddEvent(length,function(entityid)
        self:RecoverStand(entityid)
    end,entityid)

    self._recovertStandList[entityid] = event
    Log.debug("###[recover stand] 添加成功")
end
function HomeMovieStoryManager:RecoverStand(entityid)
    Log.debug("###[recover stand] 回调entity:",entityid)

    self._recovertStandList[entityid] = nil
    local entity = self._storyEntityList[entityid]
    local go = entity:GetEntityGo()
    local animCmp = go:GetComponentInChildren(typeof(UnityEngine.Animation))
    if animCmp then
        animCmp:CrossFade("stand",0.2)
    end
end
function HomeMovieStoryManager:StartLoopShake(shakeData)
    self._loopCameraShakeData.running = true

    local duration = shakeData.Duration
    if shakeData.HandHeld == true then
        duration = (math.random() * 0.6 + 0.6) * duration
    end
    self._cameraTr:DOKill()

    self._loopCameraShakeData.shakeData = shakeData
    self._loopCameraShakeData.timer = 0
    self._loopCameraShakeData.curDuration = duration
    self._loopCameraShakeData.tweener =
        self._cameraTr:DOShakePosition(
        duration,
        Vector3(self._loopCameraShakeData.shakeData.Strength[1], self._loopCameraShakeData.shakeData.Strength[2], self._loopCameraShakeData.shakeData.Strength[3]),
        self._loopCameraShakeData.shakeData.Vibrato,
        self._loopCameraShakeData.shakeData.RandomNess,
        false,
        self._loopCameraShakeData.shakeData.FadeOut
    )
end

function HomeMovieStoryManager:StopLoopShake(shakeData)
    if not self._loopCameraShakeData.running then
        return
    end
    self._loopCameraShakeData.running = false
    self._cameraTr:DOKill()
    self._cameraTr.localPosition = Vector3(0, 0, 0)

    if shakeData and shakeData.FadeOut then
        self._cameraTr:DOShakePosition(
            shakeData.Duration,
            Vector3(self._loopCameraShakeData.shakeData.Strength[1], self._loopCameraShakeData.shakeData.Strength[2], self._loopCameraShakeData.shakeData.Strength[3]),
            self._loopCameraShakeData.shakeData.Vibrato,
            self._loopCameraShakeData.shakeData.RandomNess,
            false,
            true
        )
    end
    self._loopCameraShakeData = {}
end

--跨Section执行的相机震动，入口和出口在keyframe中，在此处保证每帧更新，且只更新一次
function HomeMovieStoryManager:_UpdateLoopCameraShake(deltaTime)
    if not self._loopCameraShakeData.running then
        return
    end
    self._loopCameraShakeData.timer = self._loopCameraShakeData.timer + deltaTime
    if self._loopCameraShakeData.timer > self._loopCameraShakeData.curDuration then
        --开启下一次震动，手持相机需要随机下次震动的时长
        local duration = self._loopCameraShakeData.shakeData.Duration
        if self._loopCameraShakeData.shakeData.HandHeld == true then
            duration = (math.random() * 0.6 + 0.6) * duration
        end
        self._cameraTr:DOKill()

        self._loopCameraShakeData.timer = 0
        self._loopCameraShakeData.curDuration = duration
        self._loopCameraShakeData.tweener =
            self._cameraTr:DOShakePosition(
            duration,
            Vector3(self._loopCameraShakeData.shakeData.Strength[1], self._loopCameraShakeData.shakeData.Strength[2], self._loopCameraShakeData.shakeData.Strength[3]),
            self._loopCameraShakeData.shakeData.Vibrato,
            self._loopCameraShakeData.shakeData.RandomNess,
            false,
            self._loopCameraShakeData.shakeData.FadeOut
        )
    end
end
--驱动相机轨道和fov动画
function HomeMovieStoryManager:_UpdateCameraPathAndFov(deltaTime)
    if self._storyCameraTrackController then
        self._storyCameraTrackController:OnUpdate(deltaTime)
    end
end
---剧情界面退出 销毁资源
function HomeMovieStoryManager:Destroy()
    if self._recovertStandList then
        for key, event in pairs(self._recovertStandList) do
            GameGlobal.Timer():CancelEvent(event)
        end
    end
    
    if self._debugMode then
        -- body
    else
        local costSecond = os.time() - self._startTime  
        TaskManager:GetInstance():StartTask(
            function(TT)
                GameGlobal.GetModule(RoleModule):OnEndStory(TT
                , self._storyID
                , self._currentParagraphID
                , self._currentSectionIndex
                , self._BeSkipped            
                , costSecond)
            end,
            self
        )
    end
    Log.sys("###[HomeMovieStoryManager] 剧情资源销毁")
    for _, storyEntity in pairs(self._storyEntityList) do
        storyEntity:Destroy()
    end

    self:DisposeAnimRes()

    self._layerDic:Clear()

    self:StopLoopShake(nil)
    
    AudioHelperController.ReleaseUISoundById(CriAudioIDConst.SoundStoryClick)
end

---功能按钮------------
function HomeMovieStoryManager:SkipParagraph()
    if self._breakParagraphIds then
        local breakIdx = LocalDB.GetInt(self._localBreakParapraphMark)
        --存在下一个跳过段落s
        if self._breakParagraphIds[breakIdx + 1] then
            self._skipGaragraph = true
            self._currentParagraphID = self._breakParagraphIds[breakIdx + 1]
            LocalDB.SetInt(self._localBreakParapraphMark, breakIdx + 1)
            self._currentSectionIndex = 0
            self._currentTime = 0
        else
            self._skipGaragraph = false
            self:SkipStory()
        end
    else
        self._skipGaragraph = false
        self:SkipStory()
    end
end

function HomeMovieStoryManager:SkipStory()
    if self._debugMode then
    else
        TaskManager:GetInstance():StartTask(
            function(TT)
                GameGlobal.GetModule(RoleModule):OnSkipStory(TT, self._storyID)
            end,
            self
        )
    end
    self._BeSkipped = 1
    self._end = true
    self:StopLoopShake(nil)
end

function HomeMovieStoryManager:HideUI(hide)
    self._hide = hide
    self._buttonRootGameObject:SetActive(not hide)
    for index, storyEntity in ipairs(self._storyEntityList) do
        if storyEntity:GetEntityType() == HomeStoryEntityType.Dialog then
            storyEntity:HideUI(hide)
        end
    end
end

function HomeMovieStoryManager:SetAuto(auto)
    self._auto = auto
    self._buttonRootGameObject:SetActive(not auto)
    for index, storyEntity in ipairs(self._storyEntityList) do
        if storyEntity:GetEntityType() == HomeStoryEntityType.Dialog then
            storyEntity:SetAuto(auto)
        end
    end
end

----------------------
function HomeMovieStoryManager:GetCurStoryID()
    return self._storyID
end

function HomeMovieStoryManager:GetCurParagraphID()
    return self._currentParagraphID
end

function HomeMovieStoryManager:GetCurParagraph()
    return self._paragraphList[self._currentParagraphID]
end

function HomeMovieStoryManager:GetCurSectionIndex()
    return self._currentSectionIndex
end

function HomeMovieStoryManager:GetCurrentTime()
    return self._currentTime
end

function HomeMovieStoryManager:GetCurLanguageStr()
    if not self._curLanguageStr then
        local lan = Localization.GetCurLanguage()
        if type(lan) ~= "string" then
            lan = lan:ToString()
        end
        self._curLanguageStr = lan
    end

    return self._curLanguageStr
end
------------------

function HomeMovieStoryManager:GetStoryCamera()
    return self._mainCameraTr
end

