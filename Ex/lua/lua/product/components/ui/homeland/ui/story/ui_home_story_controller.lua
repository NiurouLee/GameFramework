_class("UIHomeStoryController", UIController)
---@class UIHomeStoryController:UIController
UIHomeStoryController = UIHomeStoryController

function UIHomeStoryController:OnShow(uiParams)
    ---@type number 剧情ID
    self._storyID = uiParams[1]
    self._debugMode = uiParams[5]

    self:AttachEvent(GameEventType.CloseHomeStory,self.CloseHomeStory)

    if not self._storyID then
        self._storyID = 1
    end

    if self._debugMode then
        self._storyRoot = UnityEngine.GameObject.Find("HomeStoryRoot")
        self._storyRoot:SetActive(true)
        self._storyRoot.transform.localPosition = Vector3(1,1,1)
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
        
        self._modelRoot = self._eventMgr:GetStoryRoot()
        --隐藏所有的星灵和建筑
        self._client:BeginStory()
        local inputMgr = self._client:InputManager()
        inputMgr:OnModeChanged(HomelandMode.Story)
        local storyCtl = inputMgr:GetControllerStory()
        storyCtl:SetActive(false)
        --隐藏所有npc
        self._client:CharacterManager():HideNpcs()
        local buildMgr = self._client:BuildManager()
        buildMgr:ActiveAllBuilding(false)
    end

    self._endCallback = uiParams[2]
    self._revertBGM = uiParams[4] ~= false
    self._ignoreBreak = uiParams[6]
    local isViewEnter = uiParams[7]

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

    ---@type HomeStoryManager 剧情管理器
    self._storyManager =
        HomeStoryManager:New(
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
        self._ignoreBreak
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

function UIHomeStoryController:OnUpdate(deltaTimeMS)
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
function UIHomeStoryController:CloseHomeStory()
    if self._storyManager then
        self._storyManager:Destroy()
        self._storyManager = nil
    end
end
function UIHomeStoryController:OnHide()
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

    if not self._debugMode then
        --这里通知eventmanager
        self._eventMgr:StopStory(self._storyID)
    end
end

function UIHomeStoryController:SetBlackSideSize(width, height)
    self._topBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._bottomBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._topBlackSide:SetActive(height > 0)
    self._bottomBlackSide:SetActive(height > 0)
    self._leftBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._rightBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._leftBlackSide:SetActive(width > 0)
    self._rightBlackSide:SetActive(width > 0)
end

function UIHomeStoryController:GetCanvasSize()
    return self._uiCanvasRect.sizeDelta.x, self._uiCanvasRect.sizeDelta.y
end

function UIHomeStoryController:FillDebugInfo()
    if self._paragraphText and self._sectionText and self._timeText then
        self._paragraphText.text = self._storyManager:GetCurParagraphID()
        self._sectionText.text = self._storyManager:GetCurSectionIndex()
        self._timeText.text = string.format("%.1f", self._storyManager:GetCurrentTime())
    end
end

---@private
function UIHomeStoryController:_EndStory()
    if self._debugMode then
        self:_OnEndStory()
        --self:SwitchState(UIStateType.UIStoryViewer3D)
        self:CloseDialog()
    else
        self._closed = true

        CutsceneManager.ExcuteCutsceneIn(
            UIStateType.UIHomeStoryController,
            function()
                --把这个剧情id存到eventmanager里，切界面之后再去取
                self._eventMgr:SetFinishStoryID(self._storyID)
                self:_OnEndStory()
                self:SwitchState(UIStateType.UIHomeland)
            end
        )
    end
end
---@private
function UIHomeStoryController:_OnEndStory()
    Log.sys("关闭剧情界面")
    self._closed = true

    --恢复黑边
    GameGlobal.UIStateManager():SetBlackSideVisible(true)

    --执行结束回调
    if self._endCallback then
        self._endCallback()
    end

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

        local buildMgr = self._client:BuildManager()
        buildMgr:ActiveAllBuilding(true)
    end
end

--功能按钮-------
--隐藏
function UIHomeStoryController:ButtonHideOnClick(go)
    self._storyManager:HideUI(true)
    self._cancelHideButton:SetActive(true)
end

--取消隐藏
function UIHomeStoryController:CancelHideButtonOnClick(go)
    self._storyManager:HideUI(false)
    self._cancelHideButton:SetActive(false)
end

--回看
function UIHomeStoryController:ButtonReviewOnClick(go)
    local dialogRecord = self._storyManager:GetDialogRecord()

    GameGlobal.UIStateManager():ShowDialog("UIHomePetStoryReview",dialogRecord)
end

--自动
function UIHomeStoryController:ButtonAutoOnClick(go)
    self._storyManager:SetAuto(true)
    self._cancelAutoButton:SetActive(true)
end

--退出
function UIHomeStoryController:QuitButtonOnClick(go)
    self:_EndStory()
end

--取消自动
function UIHomeStoryController:CancelAutoButtonOnClick(go)
    self._storyManager:SetAuto(false)
    self._cancelAutoButton:SetActive(false)
end
----------------
function UIHomeStoryController:ShowAddAffinity(petID, affinity)
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
