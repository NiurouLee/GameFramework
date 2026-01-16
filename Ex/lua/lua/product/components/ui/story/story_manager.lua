_class("StoryManager", Object)
---@class StoryManager:Object
StoryManager = StoryManager

function StoryManager:Constructor(uiStoryController, storyID, revertBGM, ignoreBreak)
    ---@type number 剧情ID
    self._storyID = storyID
    ---@type UnityEngine.GameObject 剧情界面根节点
    self._rootGameObject = uiStoryController:GetGameObject("StoryRoot")
    ---@type UnityEngine.GameObject 剧情界面上层根节点
    self._topRootGameObject = uiStoryController:GetGameObject("StoryTopRoot")
    ---@type UnityEngine.GameObject 剧情对话框根节点
    self._dialogRootGameObject = uiStoryController:GetGameObject("DialogRoot")
    ---@type UnityEngine.GameObject 功能按钮根节点
    self._buttonRootGameObject = uiStoryController:GetGameObject("ButtonRoot")
    ---@type UnityEngine.GameObject 跳过外功能按钮根节点
    self._leftButtonRootGameObject = uiStoryController:GetGameObject("LeftButtonRoot")
    ---@type UnityEngine.GameObject Mask模板
    self._maskTemplate = uiStoryController:GetGameObject("MaskTemplate")
    ---@type UnityEngine.GameObject Mask横板模板
    self._maskHorizontalTemplate = uiStoryController:GetGameObject("MaskHorizontalTemplate")
    ---@type UnityEngine.GameObject 切片SpineMask模板
    self._spineSliceMaskTemplate = uiStoryController:GetGameObject("SpineSliceMaskTemplate")
    ---@type UnityEngine.GameObject 横版切片SpineMask模板
    self._spineSliceHorizontalMaskTemplate = uiStoryController:GetGameObject("SpineSliceHorizontalMaskTemplate")
    ---@type UnityEngine.GameObject 圆形模板spineCircleMask
    self._SpineCircleMaskTemplate = uiStoryController:GetGameObject("SpineCircleMaskTemplate")
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAtlas = uiStoryController:GetAsset("UIStory.spriteatlas", LoadType.SpriteAtlas)
    ---@type boolean
    self._revertBGM = revertBGM
    ---@type boolean
    self._ignoreBreak = ignoreBreak
    ---@type boolean 剧情结束标识
    self._end = false
    ---@type table 剧情配置
    self._storyConfig = nil

    ---@type StoryBgmTrackController bgm轨道控制器
    self._storyBgmTrackController = StoryBgmTrackController:New(self)
    ---@type StoryCameraTrackController 相机轨道控制器
    self._storyCameraTrackController = StoryCameraTrackController:New(self)

    ---@type UnityEngine.Rect
    self._canvasRect = self._rootGameObject.transform.parent.parent.parent:GetComponent("RectTransform").rect

    ---运行时数据
    ---@type table<int, StoryEntity> 剧情元素列表
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

    ---@type bool 是否处于剧情选择循环状态
    self._optionLoop = false
    ---@type int 剧情结束循环状态,跳转的段落id
    self._loopOverParagraphID= -1
    ---@type int 开始该循环状态的开始段落ID,当结束其中一项的段落播放则重新回到此段落的选项选择小节
    self._optionLoopStartParagraphID = -1
    ---@type table<int, int> 剧情记录已选择的optionid
    self._optionRecord = {}
    
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

    ---@type boolean
    self._debugMode = false
    ---@type UnityEngine.GameObject
    self._entityInfoTemplate = nil

    ---@type boolean 处于跳过过程中
    self._jumping = false

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
end

---初始化剧情管理器
function StoryManager:Init(debugMode, entityInfoTemplate)
    self._startTime = os.time()
    if EditorGlobal.IsEditorMode() then
        self._storyConfig = EditorGlobal.GetEditorRunStoryConfig()
    else
        local storyConfigItem = Cfg.cfg_story[self._storyID]
        if storyConfigItem then
            local res, story = dofile(storyConfigItem.StoryScript)
            self._storyConfig = story
        end
    end
    if not self._storyConfig then
        Log.fatal("can not find story, id: " .. self._storyID)
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
        if breakIdx > 0 and self._breakParagraphIds[breakIdx] then
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

    --初始化剧情元素 加载资源
    self:_InitEntities()

    --初始化剧情数据
    self:_InitParagraphs()

    self:_StartSection()
    if EditorGlobal.IsEditorMode() then
        TaskManager:GetInstance():StartTask(
            function(TT)
                YIELD(TT)
                local editorparam = EditorGlobal.GetEnterParam()
                self:_Seek(editorparam.ParagraphID, editorparam.SectionID)
            end
        )
    end
end

---设置下一段落ID
---@param ID number
function StoryManager:SetNextParagraphID(ID)
    self._nextParagraphID = ID
end

---添加已经选择ID
function StoryManager:AddSelectOptionID(currentTrackData, optionId)
    if currentTrackData.Options.OptionLoop == nil then
        return
    end
    if self._optionRecord[currentTrackData.DialogContentStr] == nil then
        self._optionRecord[currentTrackData.DialogContentStr] = {}
        self._optionLoopStartParagraphID = self._currentParagraphID
    end
    self._optionRecord[currentTrackData.DialogContentStr][optionId] = optionId
    if currentTrackData.Options and currentTrackData.Options.OptionLoop then
        self._optionLoop = true
    end
end

---添加已经选择ID
function StoryManager:GetOptionData(options,dialogContentStr)
    if not options.OptionLoop  then
        return options
    end
    if  self._optionRecord[dialogContentStr]==nil then
        return options
    end
    local currentOpitons={}
    for index, option in ipairs(options) do
        if   not self._optionRecord[dialogContentStr][index] then
            option.optionIndex=index
            table.insert(currentOpitons,option)
        end
    end
    return currentOpitons
end
function StoryManager:CheckOptionLoopOver(options,dialogContentStr)
    if  self._optionRecord[dialogContentStr]==nil then
        return
    end
    local optionRCont=0
    for _, _ in pairs(self._optionRecord[dialogContentStr]) do
            optionRCont=optionRCont+1
    end
    if optionRCont==#options then
        self._optionLoop=false
        self._optionRecord={}
    end
end

---获取当前小节更新时间
---@return number
function StoryManager:GetCurrentTime()
    return self._currentTime
end

---获取剧情内容UI根节点
---@return UnityEngine.GameObject
function StoryManager:GetStoryUIRoot()
    return self._rootGameObject
end

---获取屏幕尺寸
---@return UnityEngine.Rect
function StoryManager:GetCanvasRect()
    return self._canvasRect
end

---获取剧情对话框UI根节点
---@return UnityEngine.GameObject
function StoryManager:GetStoryDialogUIRoot()
    return self._dialogRootGameObject
end

---获取Mask模板
---@return UnityEngine.GameObject
function StoryManager:GetMaskTemplate()
    return self._maskTemplate
end

---获取横板Mask模板
---@return UnityEngine.GameObject
function StoryManager:GetMaskHorizontalTemplate()
    return self._maskHorizontalTemplate
end

---获取切片SpineMask模板
---@return UnityEngine.GameObject
function StoryManager:GetSpineSliceMaskTemplate()
    return self._spineSliceMaskTemplate
end

---获取横版切片SpineMask模板
---@return UnityEngine.GameObject
function StoryManager:GetSpineSliceHorizontalMaskTemplate()
    return self._spineSliceHorizontalMaskTemplate
end

---获取圆形SpineCircleMask模板
---@return UnityEngine.GameObject
function StoryManager:GetSpineCircleMaskTemplate()
    return self._SpineCircleMaskTemplate
end

---获取剧情界面的atlas
---@return UnityEngine.U2D.SpriteAtlas
function StoryManager:GetUIAtlas()
    return self._uiAtlas
end

---播放音效
---@param entityID number
function StoryManager:PlaySound(entityID)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == StoryEntityType.Sound then
        soundEntity:PlaySound()
    end
end

---停止音效
---@param entityID number
function StoryManager:StopSound(entityID)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == StoryEntityType.Sound then
        soundEntity:StopSound()
    end
end

---播放bgm
---@param entityID number
function StoryManager:PlayBgm(entityID, bgmFadeTime)
    local soundEntity = self._storyEntityList[entityID]
    if soundEntity and soundEntity:GetEntityType() == StoryEntityType.Sound then
        soundEntity:PlayBgm(bgmFadeTime)
    end
end

---播放说话动作
---@param entityID number
---@param speaking boolean
function StoryManager:SetSpeakState(entityID, speaking)
    local spineEntity = self._storyEntityList[entityID]
    if spineEntity and spineEntity:GetEntityType() == StoryEntityType.Spine then
        spineEntity:SetSpeak(speaking)
    end
end

---添加对话回看内容
---@param speaker string 说话人的姓名文本内容(国际化转换之后)
---@param content string 说话内容(国际化转换之后)
function StoryManager:AddDialogRecord(speaker, content, speakerBG, isPlayer)
    self._dialogRecord[#self._dialogRecord + 1] = {speaker, content, speakerBG, isPlayer}
end

---获取记录的对话内容
---@return table<int, string>
function StoryManager:GetDialogRecord()
    return self._dialogRecord
end


---初始化层级数据 默认层级都是1
---@param trans UnityEngine.Transform
function StoryManager:InitLayerInfo(trans)
    local layerTable = self._layerDic:Find(1)
    layerTable[#layerTable + 1] = trans
end

---设置层级
---@param trans UnityEngine.Transform
---@param layer number
function StoryManager:SetLayer(trans, layer)
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

function StoryManager:_resetLayers()
    local layerDic = self._layerDic
    for i = 1, layerDic:Size() do
        ---@type table<int, UnityEngine.Transform>
        local layerTable = layerDic:GetAt(i)
        for j = 1, #layerTable do
            layerTable[j]:SetAsLastSibling()
        end
    end
end

function StoryManager:_InitEntities()
    local entityConfig = self._storyConfig["Entities"]
    if not entityConfig then
        return
    end

    for _, entity in ipairs(entityConfig) do
        local storyEntity = self:_CreateStoryEntity(entity.EntityID, entity.Type, entity.Resource, entity)
        if storyEntity then
            self._storyEntityList[storyEntity:GetID()] = storyEntity
        else
            self._end = true
            return
        end
    end
end

function StoryManager:_InitParagraphs()
    self._paragraphList = self._storyConfig["Paragraphs"]
    --段落小节是否需要额外的运行时数据?
    local paragraph = self._paragraphList[self._currentParagraphID]
    if not paragraph then
        Log.fatal("不存在ID为" .. self._currentParagraphID .. "的剧情段落,剧情结束")
        self._end = true
        return
    end

    if paragraph.NextParagraphID then
        self:SetNextParagraphID(paragraph.NextParagraphID)
    end
end

---@return StoryEntity
function StoryManager:_CreateStoryEntity(ID, type, resourceName, entityConfig)
    local request = nil
    local gameObject = nil
    if type ~= "Sound" and type ~= "PostProcessing" and type ~= "CrackMask" then
        request = ResourceManager:GetInstance():SyncLoadAsset(resourceName, LoadType.GameObject)
        if request then
            gameObject = request.Obj
            if type == "Dialog" or type == "AVGDialog" or type == "N28AVGDialog" or type == "IdolDialog" then
                gameObject.transform:SetParent(self._dialogRootGameObject.transform, false)
            elseif entityConfig.Root == "Top" then
                if entityConfig.Anchor then
                    gameObject.transform:SetParent(self._topRootGameObject.transform:Find(entityConfig.Anchor.."Anchor"), false)
                else
                    gameObject.transform:SetParent(self._topRootGameObject.transform, false)
                end
            else
                gameObject.transform:SetParent(self._rootGameObject.transform, false)
            end
        else
            self._end = true
            return
        end
    end

    local storyEntity = nil
    if type == "Dialog" then
        storyEntity = StoryEntityDialog:New(ID, gameObject, request, self)
    elseif type == "AVGDialog" then
        storyEntity = StoryEntityAVGDialog:New(ID, gameObject, request, self)
    elseif type == "N28AVGDialog" then
        storyEntity = N28StoryEntityAVGDialog:New(ID, gameObject, request, self)
    elseif type == "IdolDialog" then
        storyEntity = UIN25IdolStoryEntityDialog:New(ID, gameObject, request, self)
    elseif type == "Spine" then
        storyEntity = StoryEntitySpine:New(ID, gameObject, request, self, entityConfig)
    elseif type == "SpineSlice" then
        storyEntity = StoryEntitySpineSlice:New(ID, gameObject, request, self, entityConfig)
    elseif type == "SpineSliceHorizontal" then
        storyEntity = StoryEntitySpineSliceHorizontal:New(ID, gameObject, request, self, entityConfig)
    elseif type == "Picture" then
        storyEntity = StoryEntityPicture:New(ID, gameObject, request, self, entityConfig)
    elseif type == "Effect" then
        storyEntity = StoryEntityEffect:New(ID, gameObject, request, self)
    elseif type == "Text" then
        storyEntity = StoryEntityText:New(ID, gameObject, request, self)
    elseif type == "Sound" then
        storyEntity = StoryEntitySound:New(ID, resourceName, self)
    elseif type == "PostProcessing" then
        storyEntity = StoryEntityPostProcessing:New(ID, resourceName, self)
    elseif type == "SpineSliceEdge" then
        storyEntity = StoryEntitySpineSliceEdge:New(ID, gameObject, request, self, entityConfig)
    elseif type == "PictureSliceEdge" then
        storyEntity = StoryEntityPictureEdge:New(ID, gameObject, request, self, entityConfig)
    elseif type == "PictureSliceHorizontalEdge" then
        storyEntity = StoryEntityPictureHorizontalEdge:New(ID, gameObject, request, self, entityConfig)
    elseif type == "CrackMask" then
        storyEntity = StoryEntityCrackMask:New(ID, self)
    elseif type == "SpineCircleEdge" then
        storyEntity = StoryEntitySpineCircleEdge:New(ID, gameObject, request, self, entityConfig)
    elseif type == "SpotLight" then
        storyEntity = StoryEntitySpotLight:New(ID, gameObject, request, self, entityConfig)
    elseif type == "Sprite" then
        storyEntity = StoryEntitySprite:New(ID, gameObject, request, self, entityConfig)
    end
    return storyEntity
end

function StoryManager:_StartSection()
    local paragraph = self._paragraphList[self._currentParagraphID]
    if not paragraph then
        Log.fatal("不存在ID为" .. self._currentParagraphID .. "的剧情段落,剧情结束")
        self._end = true
        return
    end

    local section = paragraph.Sections[self._currentSectionIndex]
    if not section then
        Log.fatal("剧情段落'" .. self._currentParagraphID .. "'中不存在序号为" .. self._currentSectionIndex .. "的小节,剧情结束")
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
                if  track.Options then
                    if  track.Options.LoopOverParagraphID~=nil then
                    self._loopOverParagraphID=track.Options.LoopOverParagraphID
                    end
                end
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

    if section.NextParagraphID then
        self:SetNextParagraphID(section.NextParagraphID)
    end

    if section.ButtonVisible ~= nil then
        self._buttonRootGameObject:SetActive(section.ButtonVisible and not self._auto and not self._hide)
    --Log.fatal(tostring(self._buttonRootGameObject.activeSelf))
    end
end

function StoryManager:_EndSection()
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

function StoryManager:_UpdateTracks()
    if self._skipGaragraph then
        self._skipGaragraph = false
        return true
    end
    local allTrackEnd = true
    for track, trackEnd in pairs(self._currentTrackData) do
        if not trackEnd then
            if track.RefEntityID then
                --Log.fatal("track.RefEntityID:"..track.RefEntityID)
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
function StoryManager:IsEnd()
    return self._end
end

---@param delteTimeMS number 更新时间毫秒
function StoryManager:Update(delteTimeMS)
    if self._end then
        return
    end
    self._currentTime = self._currentTime + delteTimeMS / 1000
    local sectionEnd = self:_UpdateTracks()
    --Log.fatal("sectionEnd:"..tostring(sectionEnd))

    if sectionEnd then
        self:_EndSection()
        self._currentSectionIndex = self._currentSectionIndex + 1
        local curParagraph = self._paragraphList[self._currentParagraphID]

        if curParagraph and curParagraph.Sections and curParagraph.Sections[self._currentSectionIndex] then
            --还有下一小节
            self:_StartSection()
            self._currentTime = 0
            --按照小节长度一定在一帧以上来处理 小节更换立刻更新下一小节第0帧动画
            self:_UpdateTracks()
        else
            if self._optionLoopStartParagraphID > 0 and self._currentParagraphID ~= self._optionLoopStartParagraphID then
                if self._optionLoop then
                    self._nextParagraphID = self._optionLoopStartParagraphID
                else
                    self._nextParagraphID = self._loopOverParagraphID
                    self._optionLoopStartParagraphID=-1
                    self._loopOverParagraphID=-1
                end
            end
            if not self._nextParagraphID or --目前成为跳回到当前ID
                    self._nextParagraphID == self._currentParagraphID then
                --不循环的状态并且没有后移ID
                -- elseif self._nextParagraphID == self._currentParagraphID
                --     and  not dialogEntity._currentTrackData.Options.OptionLoop  then
                --     self._end = true
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
                if self._optionLoopStartParagraphID > 0 and self._currentParagraphID == self._optionLoopStartParagraphID then
                    local loopParagraph = self._paragraphList[self._currentParagraphID]
                    self._currentSectionIndex = #loopParagraph.Sections
                else
                    self._currentSectionIndex = 1
                end

                self._currentTime = 0
                self:_StartSection()
                self:_UpdateTracks()
            end
        end
    end

    self:_UpdateLoopCameraShake(delteTimeMS / 1000)
end

function StoryManager:StartLoopShake(shakeData)
    self._loopCameraShakeData.running = true

    local duration = shakeData.Duration
    if shakeData.HandHeld == true then
        duration = (math.random() * 0.6 + 0.6) * duration
    end
    self._rootGameObject.transform:DOKill()

    self._loopCameraShakeData.shakeData = shakeData
    self._loopCameraShakeData.timer = 0
    self._loopCameraShakeData.curDuration = duration
    self._loopCameraShakeData.tweener =
        self._rootGameObject.transform:DOShakePosition(
        duration,
        Vector3(self._loopCameraShakeData.shakeData.Strength[1], self._loopCameraShakeData.shakeData.Strength[2], 0),
        self._loopCameraShakeData.shakeData.Vibrato,
        self._loopCameraShakeData.shakeData.RandomNess,
        false,
        self._loopCameraShakeData.shakeData.FadeOut
    )
end

function StoryManager:StopLoopShake(shakeData)
    if not self._loopCameraShakeData.running then
        return
    end
    self._loopCameraShakeData.running = false
    self._rootGameObject.transform:DOKill()
    self._rootGameObject.transform.localPosition = Vector3(0, 0, 0)

    if shakeData and shakeData.FadeOut then
        self._rootGameObject.transform:DOShakePosition(
            shakeData.Duration,
            Vector3(self._loopCameraShakeData.shakeData.Strength[1], self._loopCameraShakeData.shakeData.Strength[2], 0),
            self._loopCameraShakeData.shakeData.Vibrato,
            self._loopCameraShakeData.shakeData.RandomNess,
            false,
            true
        )
    end
    self._loopCameraShakeData = {}
end

--跨Section执行的相机震动，入口和出口在keyframe中，在此处保证每帧更新，且只更新一次
function StoryManager:_UpdateLoopCameraShake(deltaTime)
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
        self._rootGameObject.transform:DOKill()

        self._loopCameraShakeData.timer = 0
        self._loopCameraShakeData.curDuration = duration
        self._loopCameraShakeData.tweener =
            self._rootGameObject.transform:DOShakePosition(
            duration,
            Vector3(self._loopCameraShakeData.shakeData.Strength[1], self._loopCameraShakeData.shakeData.Strength[2], 0),
            self._loopCameraShakeData.shakeData.Vibrato,
            self._loopCameraShakeData.shakeData.RandomNess,
            false,
            self._loopCameraShakeData.shakeData.FadeOut
        )
    end
end

---剧情界面退出 销毁资源
function StoryManager:Destroy()
    local costSecond = os.time() - self._startTime
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnEndStory(
                TT,
                self._storyID,
                self._currentParagraphID,
                self._currentSectionIndex,
                self._BeSkipped,
                costSecond
            )
        end,
        self
    )
    Log.sys("剧情资源销毁")
    for _, storyEntity in pairs(self._storyEntityList) do
        storyEntity:Destroy()
    end

    --还原bgm
    if self._revertBGM then
        if self._orgBgmPlaying then
            AudioHelperController.PlayBGM(self._orgBgm, self._orgBgmFadeTime)
        else
            AudioHelperController.StopBGM()
        end
    end

    self._layerDic:Clear()

    self:StopLoopShake(nil)

    AudioHelperController.ReleaseUISoundById(CriAudioIDConst.SoundStoryClick)
end

---功能按钮------------
function StoryManager:SkipParagraph()
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

function StoryManager:SkipStory()
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnSkipStory(TT, self._storyID)
        end,
        self
    )
    self._BeSkipped = 1
    self._end = true
    self:StopLoopShake(nil)
end

function StoryManager:HideUI(hide)
    self._hide = hide
    self._buttonRootGameObject:SetActive(not hide)
    for index, storyEntity in ipairs(self._storyEntityList) do
        local entityType = storyEntity:GetEntityType()
        if entityType == StoryEntityType.Dialog then
            storyEntity:HideUI(hide)
        elseif entityType == StoryEntityType.AVGDialog then
            storyEntity:HideUI(hide)
        end
    end
end

function StoryManager:SetAuto(auto, id)
    self._auto = auto
  
    local status, err = pcall(function()
        self._buttonRootGameObject:SetActive(not auto)

      end)
    for index, storyEntity in ipairs(self._storyEntityList) do
        local entityType = storyEntity:GetEntityType()
        if entityType == StoryEntityType.Dialog then
            storyEntity:SetAuto(auto)
        elseif entityType == StoryEntityType.AVGDialog then
            storyEntity:SetAuto(auto, id)
        end
    end
end

function StoryManager:GetCurStoryID()
    return self._storyID
end

function StoryManager:GetCurParagraphID()
    return self._currentParagraphID
end

function StoryManager:GetCurParagraph()
    return self._paragraphList[self._currentParagraphID]
end

function StoryManager:GetCurSectionIndex()
    return self._currentSectionIndex
end

function StoryManager:GetCurrentTime()
    return self._currentTime
end

function StoryManager:GetCurLanguageStr()
    if not self._curLanguageStr then
        local lan = Localization.GetCurLanguage()
        if type(lan) ~= "string" then
            lan = lan:ToString()
        end
        self._curLanguageStr = lan
    end

    return self._curLanguageStr
end

function StoryManager:GetStoryEntity(entityID)
    return self._storyEntityList[entityID]
end

---设置UI黑边
---@param width number 宽
---@param height number 高
function StoryManager:SetUIBlackSideSize(width, height)
    if GameGlobal.UIStateManager():IsShow("UIStoryController") then
        GameGlobal.UIStateManager():CallUIMethod("UIStoryController", "SetBlackSideSize", width, height)
    elseif GameGlobal.UIStateManager():IsShow("UIN20AVGStory") then
        GameGlobal.UIStateManager():CallUIMethod("UIN20AVGStory", "SetBlackSideSize", width, height)
    elseif GameGlobal.UIStateManager():IsShow("UIN28AVGStory") then
        GameGlobal.UIStateManager():CallUIMethod("UIN28AVGStory", "SetBlackSideSize", width, height)
    elseif GameGlobal.UIStateManager():IsShow("UIN25IdolStoryController") then
        GameGlobal.UIStateManager():CallUIMethod("UIN25IdolStoryController", "SetBlackSideSize", width, height)
    else
        Log.fatal("[Story] 没有处于显示状态的剧情界面")
    end
end

---获取当前UI Canvas size
---@return number, number 宽,高
function StoryManager:GetUICanvasSize()
    if GameGlobal.UIStateManager():IsShow("UIStoryController") then
        return GameGlobal.UIStateManager():CallUIMethod("UIStoryController", "GetCanvasSize")
    elseif GameGlobal.UIStateManager():IsShow("UIN20AVGStory") then
        return GameGlobal.UIStateManager():CallUIMethod("UIN20AVGStory", "GetCanvasSize")
    elseif GameGlobal.UIStateManager():IsShow("UIN25IdolStoryController") then
        return GameGlobal.UIStateManager():CallUIMethod("UIN25IdolStoryController", "GetCanvasSize")
    elseif GameGlobal.UIStateManager():IsShow("UIN28AVGStory") then
        return GameGlobal.UIStateManager():CallUIMethod("UIN28AVGStory", "GetCanvasSize")
    else
        Log.fatal("[Story] 没有处于显示状态的剧情界面")
    end
end

---一帧内执行剧情到指定章/节为止，如果没有匹配的id则执行到结束，如果执行中遇到带选项的对话也会结束
---目前特效或自带出生动作的元素在跳过过程中出现但没有隐藏会有显示问题，暂时只能针对性通过配置处理，比如在跳到的位置之前小节中隐藏等
---@param paragraphID number
---@param sectionID number
function StoryManager:JumpTo(paragraphID, sectionID)
    local frameTime = 1000 / 30

    local oriAuto = self._auto
    self:SetAuto(true)
    self._jumping = true
    local dialogRet = nil
    while true do
        if paragraphID == self._currentParagraphID and sectionID == self._currentSectionIndex then
            break
        else
            if self._forceStop then
                break
            end
            self:Update(frameTime)
            if self._end then
                break
            end
            local dialogEntity = self:GetDialogEntity(self._currentParagraphID, self._currentSectionIndex)
            if dialogEntity and dialogEntity._currentTrackData.Options then
                dialogRet = dialogEntity
                break
            end
            --AVG剧情举证专用
            if dialogEntity and dialogEntity._currentTrackData.ShowEvidence then
                dialogRet = dialogEntity
                break
            end
        end
    end
    self._jumping = false
    self:SetAuto(oriAuto)
    return dialogRet
end

function StoryManager:ForceJumpStop(flag)
    self._forceStop = flag
end

---@return boolean 是否在跳过过程中
function StoryManager:IsJumping()
    return self._jumping
end

function StoryManager:GetDialogEntity(paragraphID, sectionID)
    local paragraph = self._paragraphList[paragraphID]
    if paragraph ~= nil then
        local section = paragraph.Sections[sectionID]
        if section ~= nil then
            for _, track in ipairs(section) do
                if track.RefEntityID then
                    local entity = self._storyEntityList[track.RefEntityID]
                    local entityType = entity:GetEntityType()
                    if entityType == StoryEntityType.Dialog or entityType == StoryEntityType.AVGDialog then
                        return entity
                    end
                end
            end
        end
    end
end
