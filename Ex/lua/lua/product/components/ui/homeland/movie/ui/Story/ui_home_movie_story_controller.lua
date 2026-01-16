_class("UIHomeMovieStoryController", UIController)
---@class UIHomeMovieStoryController:UIController
UIHomeMovieStoryController = UIHomeMovieStoryController

function UIHomeMovieStoryController:OnShow(uiParams)
    ---@type number 剧情ID
    self._storyID = uiParams[1]
    self._debugMode = uiParams[7]

    self:AttachEvent(GameEventType.CloseHomeStory,self.CloseHomeStory)

    if not self._storyID then
        self._storyID = 1
    end

    if self._debugMode then
        self._storyRoot = UnityEngine.GameObject.Find("HomeStoryRoot")
        self._storyRoot:SetActive(true)
        self._storyRoot.transform.localPosition = Vector3(0,0,0)
        self._storyRoot.transform.localScale = Vector3(1,1,1)
        self._storyRoot.transform.rotation = Quaternion.identity
        self._mainCameraGo = self._storyRoot.transform:Find("StoryMainCamera")
        self._mainCameraGo.gameObject:SetActive(true)
        self._modelRoot = self._storyRoot
    else
        ---@type UIHomelandModule
        local uiHomeModule = self:GetUIModule(HomelandModule)
        self._client = uiHomeModule:GetClient()
        ---@type HomelandEventManager
        self._eventMgr = self._client:HomeEventManager()
        
        self._mainCameraGo = self._eventMgr:GetStoryCamera()
        self._eventMgr:ShowStoryCamera(true)
        
        --设置舞台相对坐标
        --local offset = Vector3(0, 0, 5) --暂时写死，因为舞台相对父建筑有5的z轴偏移
        local fatherBuild = MoviePrepareData:GetInstance():GetFatherBuild()
        local pos = fatherBuild:Pos()
        local rot = Quaternion.Euler(0, fatherBuild:RotY(), 0)
        local scale = Vector3.one
        self._eventMgr:SetStoryRoot(pos, rot, scale)
        self._modelRoot = self._eventMgr:GetStoryRoot()
        --隐藏所有的星灵和建筑
        self._client:BeginStory()
        local inputMgr = self._client:InputManager()
        inputMgr:OnModeChanged(HomelandMode.Story)
        local storyCtl = inputMgr:GetControllerStory()
        storyCtl:SetActive(false)
        --隐藏所有npc
        self._client:CharacterManager():HideNpcs()
        --local buildMgr = self._client:BuildManager()
        --buildMgr:ActiveAllBuilding(false)
    end

    self._endCallback = uiParams[2]
    self._revertBGM = uiParams[3] ~= false
    self._ignoreBreak = uiParams[4]
    local isViewEnter = true
    --是否开启吐槽
    self._openTease = uiParams[5]
    --是否开启回放
    self._isRecord = uiParams[6]

    ---@type UnityEngine.GameObject 剧情根节点
    self._rootGameObject = self:GetGameObject("StoryRoot")
    ---@type UnityEngine.GameObject 对话框根节点
    self._dialogRootGameObject = self:GetGameObject("DialogRoot")
    ---@type UnityEngine.GameObject 功能按钮根节点
    self._buttonRootGameObject = self:GetGameObject("ButtonRoot")
    ---@type UnityEngine.GameObject 除跳过外的功能按钮根节点
    self._leftButtonRootGameObject = self:GetGameObject("LeftButtonRoot")
    ---@type UnityEngine.GameObject Mask模板
    self._maskTemplate = self:GetGameObject("MaskTemplate")
    ---@type UnityEngine.GameObject 取消隐藏按钮
    self._cancelHideButton = self:GetGameObject("CancelHideButton")
    ---@type UnityEngine.GameObject 取消自动按钮
    self._cancelAutoButton = self:GetGameObject("CancelAutoButton")
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAtlas = self:GetAsset("UIStory.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.GameObject 背景板
    self._bgRoot = self:GetGameObject("bgRoot")
    --黑边
    ---@type UnityEngine.GameObject
    self._topBlackSide = self:GetGameObject("Top")
    ---@type UnityEngine.GameObject
    self._bottomBlackSide = self:GetGameObject("Bottom")
    ---@type UnityEngine.GameObject
    self._leftBlackSide = self:GetGameObject("Left")
    ---@type UnityEngine.GameObject
    self._rightBlackSide = self:GetGameObject("Right")

    --亲密度飞入窗口
    ---@type UnityEngine.GameObject
    self._affinityWnd = self:GetGameObject("AffinityWnd")
    ---@type RawImageLoader
    self._affinityPetHead = self:GetUIComponent("RawImageLoader", "Icon")
    ---@type UILocalizationText
    self._petNameTxt = self:GetUIComponent("UILocalizationText", "PetName")
    ---@type UILocalizationText
    self._affinityTxt = self:GetUIComponent("UILocalizationText", "Affinity")

    ---@type UnityEngine.RectTransform
    self._uiCanvasRect = self:GetUIComponent("RectTransform", "UICanvas")

    --左上角显示文案
    self._CurStatusTex = self:GetUIComponent("UILocalizationText", "CurStatusTex")
    local statusText = self._isRecord and StringTable.Get("str_movie_story_replaying") or StringTable.Get("str_movie_story_making")
    self._CurStatusTex:SetText(statusText)

    self._RightUpAnchor = self:GetGameObject("RightUpAnchor")
    self._BGBlur = self:GetUIComponent("H3DUIBlurHelper", "BGBlur")
    --self._BGBlurRawImage = self:GetUIComponent("RawImage", "BGBlur")
    --右上角的吐槽头像
    self._teaseImageObj = self:GetGameObject("TeaseImage")
    self._teaseBody = self:GetUIComponent("RawImageLoader", "TeaseBody")
    if not self._openTease then
        self._teaseImageObj:SetActive(false)
    end

    self._anim = self:GetUIComponent("Animation", "anim")

    ---@type HomeStoryManager 剧情管理器
    self._storyManager =
    HomeMovieStoryManager:New(
        self._storyID,
        self,
        self._mainCameraGo,
        self._rootGameObject,
        self._modelRoot,
        self._dialogRootGameObject,
        self._buttonRootGameObject,
        self._leftButtonRootGameObject,
        self._maskTemplate,
        self._uiAtlas,
        self._revertBGM,
        self._ignoreBreak,
        self._openTease,
        self._isRecord
    )

    if self._debugMode then
        ---@type UnityEngine.GameObject
        self._debugInfoRoot = self:GetGameObject("DebugInfoRoot")
        if self._debugInfoRoot then
            self._debugInfoRoot:SetActive(true)
        end
        ---@type UnityEngine.UI.Text
        self._paragraphText = self:GetUIComponent("Text", "ParagraphText")
        ---@type UnityEngine.UI.Text
        self._sectionText = self:GetUIComponent("Text", "SectionText")
        ---@type UnityEngine.UI.Text
        self._timeText = self:GetUIComponent("Text", "TimeText")
        ---@type UnityEngine.GameObject
        self._entityInfo = self:GetGameObject("EntityInfo")
    end

    --等待500毫秒的ui界面动画
    self._storyManager:Init(self._debugMode, self._entityInfo,500,isViewEnter)
    self._closed = false

    self._dialogSpeakerBGBlue = "plot_juqing_xian4"
    self._dialogSpeakerBGRed = "plot_juqing_xian5"

    if EditorGlobal.IsEditorMode() then
        EditorGlobal.SetStroyController(self)
        EditorGlobal.SetStroyManager(self._storyManager)
    end

    CutsceneManager.ExcuteCutsceneOut()

    --隐藏黑边
    GameGlobal.UIStateManager():SetBlackSideVisible(false)
end

function UIHomeMovieStoryController:OnUpdate(deltaTimeMS)
    if not self._storyManager then
        return
    end

    self._storyManager:Update(deltaTimeMS)
    if self._debugMode then
        self:FillDebugInfo()
    end
    if self._storyManager:IsEnd() then
        if not self._closed then
            self:_EndStory()
        end
    end
end
function UIHomeMovieStoryController:CloseHomeStory()
    if self._storyManager then
        self._storyManager:Destroy()
        self._storyManager = nil
    end
end
function UIHomeMovieStoryController:OnHide()
    if self._storyManager then
        self._storyManager:Destroy()
        self._storyManager = nil
    end
    self:DetachEvent(GameEventType.CloseHomeStory,self.CloseHomeStory)
    if self._tweenQueue then
        self._tweenQueue:Complete(false)
        self._tweenQueue = nil
    end
    local login_module = GameGlobal.GetModule(LoginModule)
    GameGlobal.UAReportForceGuideEvent("StoryEnd", {self._storyID})

    if self._3dModelTimer then
        GameGlobal.Timer():CancelEvent(self._3dModelTimer)
    end

    if self._FaceTimer then
        GameGlobal.Timer():CancelEvent(self._FaceTimer) 
    end

    if not self._debugMode then
        --这里通知eventmanager
        self._eventMgr:StopStory(self._storyID)
    end
end

function UIHomeMovieStoryController:SetBlackSideSize(width, height)
    self._topBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._bottomBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._topBlackSide:SetActive(height > 0)
    self._bottomBlackSide:SetActive(height > 0)
    self._leftBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._rightBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._leftBlackSide:SetActive(width > 0)
    self._rightBlackSide:SetActive(width > 0)
end

function UIHomeMovieStoryController:GetCanvasSize()
    return self._uiCanvasRect.sizeDelta.x, self._uiCanvasRect.sizeDelta.y
end

function UIHomeMovieStoryController:FillDebugInfo()
    if self._paragraphText and self._sectionText and self._timeText then
        self._paragraphText.text = self._storyManager:GetCurParagraphID()
        self._sectionText.text = self._storyManager:GetCurSectionIndex()
        self._timeText.text = string.format("%.1f", self._storyManager:GetCurrentTime())
    end
end

function UIHomeMovieStoryController:SetTeaseBodyImage(image)
    self._teaseBody:LoadImage(image)
end

function UIHomeMovieStoryController:SetTeaseHeadActive(active)
    if active then
        self._anim:Play("UIHomeMovieStoryController_in")
    else
        self._anim:Play("UIHomeMovieStoryController_out")
    end
end

--在选项开始时展示3D模型
function UIHomeMovieStoryController:ShowPetModel(petName, root)
    self._BGBlur.gameObject:SetActive(true)
    local cam = self._mainCameraGo:GetComponent("Camera")
    self._BGBlur.OwnerCamera = cam
    --不清理会出现黑色只有深度的bg
    self._BGBlur:CleanRenderTexture()
    self._BGBlur:RefreshBlurTexture()
    self._3dModelTimer = GameGlobal.Timer():AddEvent(
        100,
        function()
            self._ui3DModule = self:CreateUI3DModule()
            self._ui3DModuleID = self:InitUI3DModule(self._ui3DModule, petName .. ".prefab")
            local ctrlCamera = GameGlobal.UIStateManager():GetControllerCamera("UIHomeMovieStoryController") 
            ctrlCamera.clearFlags = UnityEngine.CameraClearFlags.Depth
            self:Show3DModule(self._ui3DModule, "UIHomeMovieOptionPetCamera.prefab", 45, root, self:GetDepth(), false, false, false)
            --光照
            if not EditorGlobal.IsEditorMode() then
                self._originLightDir = self._client:SceneManager():GetCustomLightTransform()
                local tempTrans = UnityEngine.GameObject.Find("Envrionment").transform
                self._client:SceneManager():SetCustomLightTransform(tempTrans)
            end
            
            local petObj = self._ui3DModule.gameObject.transform:Find("ModelShow/ShowPlayer/Model/" .. petName).gameObject
            local rootTrans = petObj.transform:Find("Root")
            local root = rootTrans.gameObject
            local face_name = petName .. "_face"
            local face = GameObjectHelper.FindChild(petObj.transform, face_name)
            if face then
                local render = face.gameObject:GetComponent(typeof(UnityEngine.SkinnedMeshRenderer))
                if not render then
                    Log.error("###[HomeStoryEntityModel] 面部表情节点上找不到SkinnedMeshRenderer：", face_name)
                else
                    self._optPetFaceMat = render.material
                end
            else
                Log.error("###[HomeStoryEntityModel] 找不到面部表情节点：", face_name)
            end
            local animator = root:GetComponent(typeof(UnityEngine.Animator))
            if animator then
                UnityEngine.Object.Destroy(animator) --局内用Animator，销毁
            end
            ---@type UnityEngine.Animation
            self._optPetAnim = root:AddComponent(typeof(UnityEngine.Animation))
            --家园动画
            local petHomePrefab = HelperProxy:GetInstance():GetPetAnimatorControllerName(petName ..".prefab",PetAnimatorControllerType.Homeland)
            if petHomePrefab then
                self._petHomelandAnimReq = ResourceManager:GetInstance():SyncLoadAsset(petHomePrefab, LoadType.GameObject)
                local homelandAnimation = self._petHomelandAnimReq.Obj:GetComponent("Animation")
                local clips = HelperProxy:GetInstance():GetAllAnimationClip(homelandAnimation)
                for i = 0, clips.Length - 1 do
                    if clips[i] == nil then
                        Log.error("Pet animation is null:", self._petID, ", index:", i)
                    else
                        self._optPetAnim:AddClip(clips[i], clips[i].name)
                    end
                end
            end
            --风船动画
            local petAircraftPrefab = HelperProxy:GetInstance():GetPetAnimatorControllerName(petName ..".prefab",PetAnimatorControllerType.Aircraft)
            if petAircraftPrefab then
                self._petAircraftAnimReq = ResourceManager:GetInstance():SyncLoadAsset(petAircraftPrefab, LoadType.GameObject)
                local aircraftAnimation = self._petAircraftAnimReq.Obj:GetComponent("Animation")
                local clips = HelperProxy:GetInstance():GetAllAnimationClip(aircraftAnimation)
                for i = 0, clips.Length - 1 do
                    if clips[i] == nil then
                        Log.error("Pet animation is null:", self._petID, ", index:", i)
                    else
                        self._optPetAnim:AddClip(clips[i], clips[i].name)
                    end
                end
            end 
            --播放动作
            self._optPetAnim:Play(HomelandPetAnimName.Stand)
            local petFaceCfg
            local cfg = Cfg.cfg_homeland_movie_pet_face{ID = petName}
            if not cfg then
                petFaceCfg = Cfg.cfg_homeland_movie_pet_face{ID = -1}[1]
            else
                petFaceCfg = cfg[1]
            end
            self._optPetFaceIdx = petFaceCfg.Amaze
            if self._optPetFaceMat then
                self._optPetFaceMat:SetInt("_Frame", 1)
            end
        end
    )
end

function UIHomeMovieStoryController:PlayPetAmazedAnim()
    if self._optPetAnim then
        self._optPetAnim:Play(HomelandPetAnimName.Surprise)
        if self._optPetFaceMat then
            self._optPetFaceMat:SetInt("_Frame", self._optPetFaceIdx)
        end
        local state = self._optPetAnim:get_Item(HomelandPetAnimName.Surprise)
        if state then
            self._FaceTimer = GameGlobal.Timer():AddEvent(
                state.clip.length * 1000,
                function()
                    self._optPetAnim:Play(HomelandPetAnimName.Stand)
                    self._optPetFaceMat:SetInt("_Frame", 1)
                end
            )
        else
            Log.fatal("无法找到该角色的惊讶动画", self._optPetAnim)
        end
    end
end

function UIHomeMovieStoryController:HidePetModel()
    if self._FaceTimer then
        GameGlobal.Timer():CancelEvent(self._FaceTimer)
    end
    self._BGBlur.gameObject:SetActive(false)
    local ctrlCamera = GameGlobal.UIStateManager():GetControllerCamera("UIHomeMovieStoryController") 
    ctrlCamera.clearFlags = UnityEngine.CameraClearFlags.Nothing
    self:Hide3DModule(self._ui3DModule)
    self:Dispose3DModule(self._ui3DModule, self._ui3DModuleID)
    --还原光照方向
    if not EditorGlobal.IsEditorMode() then
        if self._originLightDir then
            self._client:SceneManager():SetCustomLightTransform(self._originLightDir)
        end
    end
end

function UIHomeMovieStoryController:QuitStory()
    AudioHelperController.PlayBGM(CriAudioIDConst.BGMEnterHomeland, AudioConstValue.BGMCrossFadeTime)
    CutsceneManager.ExcuteCutsceneIn(
        UIStateType.UIHomeMovieStoryController,
        function()
            self:_OnEndStory()
            self._eventMgr:ReSetStoryRoot()
            --self:SwitchState(UIStateType.UIHomeland)
            --执行结算
            local mHomeland = GameGlobal.GetModule(HomelandModule)
            local mUIHomeland = mHomeland:GetUIModule()
            GameGlobal.TaskManager():StartTask(function(TT)
                mUIHomeland:EnterHomelandAfterMovieMaker(TT, self._isRecord,true)
                --恢复家园中家具导航面
                self._client:SceneManager():BuildNavMesh()
            end) 
        end,
        true
    )
end

---@private
function UIHomeMovieStoryController:_EndStory()
    if self._debugMode then
        self:_OnEndStory()
        --self:SwitchState(UIStateType.UIStoryViewer3D)
        self:CloseDialog()
    else
        self._closed = true
        AudioHelperController.PlayBGM(CriAudioIDConst.BGMN17, AudioConstValue.BGMCrossFadeTime)
        CutsceneManager.ExcuteCutsceneIn(
            UIStateType.UIHomeMovieStoryController,
            function()
                --把这个剧情id存到eventmanager里，切界面之后再去取
                self._eventMgr:SetFinishStoryID(self._storyID)
                self:_OnEndStory()
                self._eventMgr:ReSetStoryRoot()
                --self:SwitchState(UIStateType.UIHomeland)
                --执行结算
                local mHomeland = GameGlobal.GetModule(HomelandModule)
                local mUIHomeland = mHomeland:GetUIModule()
                GameGlobal.TaskManager():StartTask(function(TT)
                    mUIHomeland:EnterMovieResult(TT, self._isRecord)
                        --执行结束回调
                        if self._endCallback then
                            self._endCallback()
                        end
                end)
            end,
            true
        )
    end
end
---@private
function UIHomeMovieStoryController:_OnEndStory()
    Log.sys("关闭剧情界面")
    self._closed = true

    --恢复黑边
    GameGlobal.UIStateManager():SetBlackSideVisible(true)

    if self._debugMode then
        -- body
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnHomeStoryFinish,self._storyID)

        self._client:EndStory()
        self._eventMgr:ShowStoryCamera(false)
        
        local inputMgr = self._client:InputManager()
        local storyCtl = inputMgr:GetControllerStory()
        storyCtl:SetActive(true)
        inputMgr:OnModeChanged(HomelandMode.Normal)
        self._client:CharacterManager():RevertNpcs()

        -- local buildMgr = self._client:BuildManager()
        -- buildMgr:ActiveAllBuilding(true)
    end
end

--功能按钮-------
--隐藏
function UIHomeMovieStoryController:ButtonHideOnClick(go)
    self._storyManager:HideUI(true)
    self._cancelHideButton:SetActive(true)
    self._bgRoot:SetActive(false)
    self._RightUpAnchor:SetActive(false)
end

--取消隐藏
function UIHomeMovieStoryController:CancelHideButtonOnClick(go)
    self._storyManager:HideUI(false)
    self._cancelHideButton:SetActive(false)
    self._bgRoot:SetActive(true)
    self._RightUpAnchor:SetActive(true)
end

--回看
function UIHomeMovieStoryController:ButtonReviewOnClick(go)
    local dialogRecord = self._storyManager:GetDialogRecord()

    GameGlobal.UIStateManager():ShowDialog("UIHomePetStoryReview",dialogRecord)
end

--自动
function UIHomeMovieStoryController:ButtonAutoOnClick(go)
    self._storyManager:SetAuto(true)
    self._cancelAutoButton:SetActive(true)
end

--退出
function UIHomeMovieStoryController:QuitButtonOnClick(go)
    local title = nil
    local desc = self._isRecord and StringTable.Get("str_movie_story_replay_back_tips") or StringTable.Get("str_movie_story_back_tips")
    local leftBtn = {
        StringTable.Get("str_common_cancel"),
        function(param)
        end
    }

    local rightBtn = {
        StringTable.Get("str_common_ok"),
        function()
            self:QuitStory()
        end
    }
    self:ShowDialog("UIHomelandMessageBox", title, desc, leftBtn, rightBtn, true) 
end

--取消自动
function UIHomeMovieStoryController:CancelAutoButtonOnClick(go)
    self._storyManager:SetAuto(false)
    self._cancelAutoButton:SetActive(false)
end
----------------
function UIHomeMovieStoryController:ShowAddAffinity(petID, affinity)
    Log.fatal("宝宝:" .. petID .. " +" .. affinity)
    ---@type Pet
    local pet = self:GetModule(PetModule):GetPetByTemplateId(petID)

    if not pet then
        Log.fatal("[story] missing pet info, tplid:" .. petID)
        return
    end

    self._affinityPetHead:LoadImage(pet:GetPetHead(PetSkinEffectPath.HEAD_ICON_STORY))
    self._petNameTxt:SetText(StringTable.Get(pet:GetPetName()))
    self._affinityTxt:SetText(StringTable.Get("str_story_add_affinity", affinity))

    self._affinityWnd:SetActive(true)

    if self._tweenQueue then
        self._tweenQueue:Complete(false)
        self._tweenQueue = nil
    end

    self._tweenQueue = DG.Tweening.DOTween.Sequence()
    --0.2s 移动到屏幕内
    self._tweenQueue:Append(self._affinityWnd.transform:DOLocalMoveX(-498, 0.2))

    --等待3s 可以点击关闭界面
    self._tweenQueue:AppendInterval(3)

    --0.2s 移动到屏幕内
    self._tweenQueue:Append(self._affinityWnd.transform:DOLocalMoveX(498, 0.2)):AppendCallback(
        function()
            self._affinityWnd:SetActive(false)
            self._tweenQueue = nil
        end
    )
end
