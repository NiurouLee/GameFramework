_class("UIN25IdolStoryController", UIController)
---@class UIN25IdolStoryController:UIController
UIN25IdolStoryController = UIN25IdolStoryController

function UIN25IdolStoryController:OnShow(uiParams)
    ---@type number 剧情ID
    self._storyID = uiParams[1]
    Log.info("[story] start story ID:" .. tostring(self._storyID))
    GameGlobal.UAReportForceGuideEvent("StoryStart", {self._storyID})
    ---@type fun() 剧情结束回调
    self._endCallback = uiParams[2]
    self.onlyReview = uiParams[3]

    self._needCloseSelf = true
    self._revertBGM = true
    self._debugMode = false
    self._ignoreBreak = false
    --调至选项处
    self._skipToOptions = true

    ---@type UnityEngine.GameObject 取消隐藏按钮
    self._cancelHideButton = self:GetGameObject("CancelHideButton")
    ---@type UnityEngine.GameObject 取消自动按钮
    self._cancelAutoButton = self:GetGameObject("CancelAutoButton")
    ---@type UIDynamicScrollView 剧情回看列表
    self._dialogReviewScrollView = self:GetUIComponent("UIDynamicScrollView", "ReviewPanel")
    ---@type UnityEngine.GameObject
    self._autoStateGO = self:GetGameObject("AutoState")
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
    ---@type boolean
    self._skipLock = true

    ---@type UnityEngine.RectTransform
    self._fullScreenAnchor = self:GetUIComponent("RectTransform", "FullScreenAnchor")
    local bands = ResolutionManager.BangWidth()
    Log.info("UIN25IdolStoryController FullScreenAnchor "..bands)
    self._fullScreenAnchor.sizeDelta = Vector2(bands * 2, 0)
    ---@type StoryManager 剧情管理器
    self._storyManager = StoryManager:New(self, self._storyID, self._revertBGM, self._ignoreBreak)

    self._dialogReviewScrollView:InitListView(
        0,
        function(scrollview, index)
            return self:_OnGetReviewDialogItem(scrollview, index)
        end
    )

    self._dialogReviewScrollView.mOnDragingAction = function()
        self._reviewDragged = true
    end

    if self._debugMode then
        -- ---@type UnityEngine.GameObject
        -- self._debugInfoRoot = self:GetGameObject("DebugInfoRoot")
        -- self._debugInfoRoot:SetActive(true)
        -- ---@type UnityEngine.UI.Text
        -- self._paragraphText = self:GetUIComponent("Text", "ParagraphText")
        -- ---@type UnityEngine.UI.Text
        -- self._sectionText = self:GetUIComponent("Text", "SectionText")
        -- ---@type UnityEngine.UI.Text
        -- self._timeText = self:GetUIComponent("Text", "TimeText")
        -- ---@type UnityEngine.GameObject
        -- self._entityInfo = self:GetGameObject("EntityInfo")
    end

    self._storyManager:Init(self._debugMode, self._entityInfo)
    self._closed = false
    self._reviewDragged = false

    self._dialogSpeakerBGBlue = "plot_juqing_xian4"
    self._dialogSpeakerBGRed = "plot_juqing_xian5"

    self._skipLock = false

    if EditorGlobal.IsEditorMode() then
        EditorGlobal.SetStroyController(self)
        EditorGlobal.SetStroyManager(self._storyManager)
    end

    --隐藏黑边
    GameGlobal.UIStateManager():SetBlackSideVisible(false)
end

function UIN25IdolStoryController:OnUpdate(deltaTimeMS)
    if not self._storyManager then
        return
    end

    self._storyManager:Update(deltaTimeMS)
    if self._debugMode then
        --self:FillDebugInfo()
    end
    if self._storyManager:IsEnd() then
        if not self._closed then
            self:_EndStory()
        end
    end
end

function UIN25IdolStoryController:OnHide()
    self._storyManager:Destroy()
    self._storyManager = nil

    if self._tweenQueue then
        self._tweenQueue:Complete(false)
        self._tweenQueue = nil
    end
    local login_module = GameGlobal.GetModule(LoginModule)
    GameGlobal.UAReportForceGuideEvent("StoryEnd", {self._storyID})
end

function UIN25IdolStoryController:SetBlackSideSize(width, height)
    self._topBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._bottomBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._topBlackSide:SetActive(height > 0)
    self._bottomBlackSide:SetActive(height > 0)
    self._leftBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._rightBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._leftBlackSide:SetActive(width > 0)
    self._rightBlackSide:SetActive(width > 0)
end

function UIN25IdolStoryController:GetCanvasSize()
    return self._uiCanvasRect.sizeDelta.x, self._uiCanvasRect.sizeDelta.y
end

function UIN25IdolStoryController:FillDebugInfo()
    self._paragraphText.text = self._storyManager:GetCurParagraphID()
    self._sectionText.text = self._storyManager:GetCurSectionIndex()
    self._timeText.text = string.format("%.1f", self._storyManager:GetCurrentTime())
end

---@private
function UIN25IdolStoryController:_EndStory()
    Log.sys("关闭剧情界面")
        --执行结束回调
        if self._endCallback then
            self._endCallback()
        end
    --关闭界面
    if (self._needCloseSelf == nil or self._needCloseSelf == true) then
        self:CloseDialog()
    end
    self._closed = true

    --恢复黑边
    GameGlobal.UIStateManager():SetBlackSideVisible(true)


end

--回看列表填充内容回调方法
function UIN25IdolStoryController:_OnGetReviewDialogItem(scrollview, index)
    local dialogRecord = self._storyManager:GetDialogRecord()
    local item = scrollview:NewListViewItem("ReviewContent")
    ---倒序显示回顾剧情文本
    -- local luaIndex = #dialogRecord - index
    --剧情回顾显示排序修改
    local luaIndex = index + 1

    if #dialogRecord >= luaIndex then
        local speakerName = dialogRecord[luaIndex][1]
        local content = dialogRecord[luaIndex][2]
        item.transform:Find("SpeakerPlaceHolder/Speaker"):GetComponent(typeof(UILocalizationText)):SetText(speakerName)
        item.transform:Find("Content"):GetComponent(typeof(UILocalizationText)):SetText(content)
        local speakerBG = item.transform:Find("SpeakerPlaceHolder/SpeakerBG").gameObject
        if string.len(speakerName) > 0 then
            speakerBG:SetActive(true)
            local speakerBGColor = dialogRecord[luaIndex][3]
            local isPlayer = dialogRecord[luaIndex][4]
            if isPlayer or speakerBGColor == "blue" then
                speakerBG:GetComponent("Image").sprite = self._uiAtlas:GetSprite(self._dialogSpeakerBGBlue)
            else
                speakerBG:GetComponent("Image").sprite = self._uiAtlas:GetSprite(self._dialogSpeakerBGRed)
            end
        else
            speakerBG:SetActive(false)
        end
        UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
        return item
    else
        return nil
    end
end

--功能按钮-------
--隐藏
function UIN25IdolStoryController:ButtonHideOnClick(go)
    self._storyManager:HideUI(true)
    self._cancelHideButton:SetActive(true)
    self._autoStateGO:SetActive(true)
end

--取消隐藏
function UIN25IdolStoryController:CancelHideButtonOnClick(go)
    self._storyManager:HideUI(false)
    self._cancelHideButton:SetActive(false)
    self._autoStateGO:SetActive(false)
end

--回看
function UIN25IdolStoryController:ButtonReviewOnClick(go)
    GameGlobal.UAReportForceGuideEvent(
        "StoryReplay",
        {
            self._storyID,
            self._storyManager:GetCurParagraphID(),
            self._storyManager:GetCurSectionIndex()
        }
    )
    self._dialogReviewScrollView.gameObject:SetActive(true)
    local dialogRecord = self._storyManager:GetDialogRecord()
    self._dialogReviewScrollView:SetListItemCount(#dialogRecord, true)
    self._dialogReviewScrollView:MovePanelToItemIndex(#dialogRecord - 1, 0)
end

--关闭回看界面
function UIN25IdolStoryController:ReviewPanelOnClick()
    if self._reviewDragged then
        self._reviewDragged = false
    else
        self._dialogReviewScrollView.gameObject:SetActive(false)
    end
end

--自动
function UIN25IdolStoryController:ButtonAutoOnClick(go)
    local login_module = GameGlobal.GetModule(LoginModule)
    if login_module:IsInFirstStory() then
        GameGlobal.ReportCustomEvent("CreateRole", "AutoPlayBtn")
    end
    GameGlobal.UAReportForceGuideEvent(
        "StoryAuto",
        {
            self._storyID,
            self._storyManager:GetCurParagraphID(),
            self._storyManager:GetCurSectionIndex()
        }
    )

    self._storyManager:SetAuto(true)
    self._cancelAutoButton:SetActive(true)
end

--取消自动
function UIN25IdolStoryController:CancelAutoButtonOnClick(go)
    GameGlobal.UAReportForceGuideEvent(
        "StoryCancelAuto",
        {
            self._storyID,
            self._storyManager:GetCurParagraphID(),
            self._storyManager:GetCurSectionIndex()
        }
    )
    self._storyManager:SetAuto(false)
    self._cancelAutoButton:SetActive(false)
end

function UIN25IdolStoryController:ButtonSkipOnClick(go)
    if self._skipLock then
        return
    end

    if self._skipToOptions then
        self.key = "JumpStoryNextOptions"
        GameGlobal.UIStateManager():Lock(self.key)
        --跳转到下一个选项处
        local lastParagraphId, lastSectionIdx = -1,-1
        local dialogRet = self._storyManager:JumpTo(lastParagraphId, lastSectionIdx)
        if dialogRet then
            dialogRet:FullScreenBtnOnClick()
        end
        GameGlobal.UIStateManager():UnLock(self.key)
        return
    end

    local skip_confirm_str_id = "str_story_skip_confirm"
    if not self:GetModule(StoryModule):IsFinish(self._storyID) then
        skip_confirm_str_id = "str_story_skip_affinity_confirm"
    end

    self._skipLock = true

    local login_module = GameGlobal.GetModule(LoginModule)
    if login_module:IsInFirstStory() then
        GameGlobal.ReportCustomEvent("CreateRole", "SkipAnimBtn")
    end

    GameGlobal.UAReportForceGuideEvent(
        "StorySkip",
        {
            self._storyID,
            self._storyManager:GetCurParagraphID(),
            self._storyManager:GetCurSectionIndex()
        }
    )

    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get(skip_confirm_str_id),
        function()
            ------------------ 原来代码   -------------
            -- Log.sys("开始跳过剧情")
            -- --StoryManager关闭及销毁
            -- if not self._storyManager then
            --     Log.warn("storyManager在确认跳过前已被置空")
            --     Log.sys("结束跳过剧情")
            --     return
            -- end
            -- self._storyManager:SkipStory()
            -- --关闭界面
            -- self:_EndStory()
            -- self._skipLock = false
            -- Log.sys("结束跳过剧情")
            ------------------ 原来代码   -------------
            Log.sys("开始跳过剧情")
            --StoryManager关闭及销毁
            if not self._storyManager then
                Log.warn("storyManager在确认跳过前已被置空")
                Log.sys("结束跳过剧情")
                return
            end
            self._storyManager:SkipParagraph()
            --关闭界面
            -- self:_EndStory()
            self._skipLock = false
            Log.sys("结束跳过剧情")
        end,
        nil,
        function()
            self._skipLock = false
        end
    )
end
----------------
function UIN25IdolStoryController:ShowAddAffinity(petID, affinity)
    Log.fatal("宝宝:" .. petID .. " +" .. affinity)
    ---@type Pet
    local pet = self:GetModule(PetModule):GetPetByTemplateId(petID)

    if not pet then
        Log.fatal("[story] missing pet info, tplid:" .. petID)
        return
    end
    if self._affinityPetHead then
        self._affinityPetHead:LoadImage(pet:GetPetHead(PetSkinEffectPath.HEAD_ICON_STORY))
    end
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
--只是回顾
function UIN25IdolStoryController:GetOnlyReview()
    return self.onlyReview
end
function UIN25IdolStoryController:SetOnlyReview(onlyReview)
    self.onlyReview = onlyReview
end