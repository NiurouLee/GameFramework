--[[------------------
    Dialog剧情元素
--]] ------------------

_class("HomeStoryEntityDialog", HomeStoryEntity)
---@class HomeStoryEntityDialog:HomeStoryEntity
HomeStoryEntityDialog = HomeStoryEntityDialog

function HomeStoryEntityDialog:Constructor(ID, gameObject, resRequest, storyManager, uiController)
    HomeStoryEntityDialog.super.Constructor(self, ID, gameObject, resRequest, storyManager)
    self._uiController = uiController
    ---@type HomeStoryEntityType
    self._type = HomeStoryEntityType.Dialog
    self.newName = ""
    self._splitChar = "|"
    ---@type number 默认断点打字机动画时长
    self._defaultBreakTypeTime = 0.2
    ---@type number 显示完毕后的无法点击时间
    self._contentEndingTime = 0.2
    self.uiCustomEventListener = UICustomUIEventListener:New()
    self:InitUIComponents(gameObject)

    self:InitData()
end

function HomeStoryEntityDialog:InitUIComponents(gameObject)
    ---@type UIView 对话框prefab根节点上的uiview
    local _dialogUIView = gameObject:GetComponent("UIView")
    ---@type UICustomWidget
    self._customWidget = UICustomWidget:New()
    self._customWidget:Load(_dialogUIView, self._uiController)
    self._customWidget:SetName("HomeStoryDialogUIView")
    self._dialogUIView = self._customWidget

    self._canvas = self._uiController:GetUIComponent("Canvas", "UICanvas")

    ---@type UnityEngine.UI.Image 对话框底图
    self._contentBG1 = self._dialogUIView:GetUIComponent("Animation", "DialogBG1")
    self._contentBG2 = self._dialogUIView:GetUIComponent("Animation", "DialogBG2")

    self._dialogLayout1 = self._dialogUIView:GetGameObject("DialogLayout1")
    self._dialogLayout2 = self._dialogUIView:GetGameObject("DialogLayout2")

    ---@type UnityEngine.GameObject 姓名节点
    self._speakerGOLeft = self._dialogUIView:GetGameObject("DialogSpeaker1")
    self._speakerGORight = self._dialogUIView:GetGameObject("DialogSpeaker2")

    ---@type UIRichText 对话框文本组件
    self._contentTextLeft = self._dialogUIView:GetUIComponent("UIRichText", "Content1")
    self._contentTextRight = self._dialogUIView:GetUIComponent("UIRichText", "Content2")

    ---@type UILocalizationText 姓名文本组件
    self._speakerTextLeft = self._dialogUIView:GetUIComponent("UILocalizedTMP", "SpeakerName1")
    self._speakerTextRight = self._dialogUIView:GetUIComponent("UILocalizedTMP", "SpeakerName2")
    self._matReq1 = UIWidgetHelper.SetLocalizedTMPMaterial(self._dialogUIView, "SpeakerName1",
        "UIHomeStorySpeakerName.mat", self._matReq1)
    self._matReq2 = UIWidgetHelper.SetLocalizedTMPMaterial(self._dialogUIView, "SpeakerName2",
        "UIHomeStorySpeakerName.mat", self._matReq2)
    self._dialogLayout1:SetActive(false)
    self._dialogLayout2:SetActive(false)

    ---@type UnityEngine.GameObject 结束标识
    self._endFlag = self._dialogUIView:GetGameObject("EndFlag")

    ---@type UnityEngine.GameObject 全屏按钮
    self._fullscreenBtn = self._dialogUIView:GetGameObject("FullScreenBtn")
    self._cancelAutoButton = self._dialogUIView:GetGameObject("CancelAutoButton")
    self._cancelHideButton = self._dialogUIView:GetGameObject("CancelHideButton")
    self._buttonReview = self._dialogUIView:GetGameObject("ButtonReview")
    self._buttonHide = self._dialogUIView:GetGameObject("ButtonHide")
    self._buttonAuto = self._dialogUIView:GetGameObject("ButtonAuto")
    self._dialogReviewScrollView = self._dialogUIView:GetUIComponent("UIDynamicScrollView", "ReviewPanel")

    self:AddListener()

    ---@type UnityEngine.GameObject 选项根节点
    self._optRoot = self._dialogUIView:GetGameObject("Options")
    self._choosePool = self._dialogUIView:GetUIComponent("UISelectObjectPath", "choosePool")

    --半身像
    ---@type RawImageLoader
    self._bodyLeft = self._dialogUIView:GetUIComponent("RawImageLoader", "body1")
    self._bodyRight = self._dialogUIView:GetUIComponent("RawImageLoader", "body2")
    self._bodyRawImageLeft = self._dialogUIView:GetUIComponent("RawImage", "body1")
    self._bodyRawImageRight = self._dialogUIView:GetUIComponent("RawImage", "body2")

    self._optionParagraphIDDic = {}

    ---说话人名底板图标变化
    ---@type string
    self._dialogSpeakerBGBlue = "plot_juqing_xian0"
    self._dialogSpeakerBGRed = "plot_juqing_xian1"
end

function HomeStoryEntityDialog:AddListener()
    self.uiCustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._fullscreenBtn),
        UIEvent.Click,
        function(go)
            self:FullScreenBtnOnClick(go)
        end
    )
    self.uiCustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._cancelAutoButton),
        UIEvent.Click,
        function(go)
            self:CancelAutoButtonOnClick(go)
        end
    )
    self.uiCustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._cancelHideButton),
        UIEvent.Click,
        function(go)
            self:CancelHideButtonOnClick(go)
        end
    )
    self.uiCustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._buttonReview),
        UIEvent.Click,
        function(go)
            self:ButtonReviewOnClick(go)
        end
    )
    self.uiCustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._buttonHide),
        UIEvent.Click,
        function(go)
            self:ButtonHideOnClick(go)
        end
    )
    self.uiCustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._buttonAuto),
        UIEvent.Click,
        function(go)
            self:ButtonAutoOnClick(go)
        end
    )
end

function HomeStoryEntityDialog:Destroy()
    if self._resumeCallBack then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.AppResume, self._resumeCallBack)
    end
    self.uiCustomEventListener:RemoveAllCustomEventListener()
    if self._customWidget then
        self._customWidget:Dispose()
        self._customWidget = nil
    end

    self._matReq1 = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._matReq1)
    self._matReq2 = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._matReq2)
end

function HomeStoryEntityDialog:InitData()
    ---@type boolean 在角色名渐显中
    self._inSpeakerNameFadeIn = false
    ---@type number 渐显开始时间
    self._speakerNameFadeInStartTime = 0
    ---@type number 渐显持续时间
    self._speakerNameFadeInDuration = 0
    ---@type Color 颜色动画控制
    self._speakerNameFadeInColor = Color.New(69 / 255, 67 / 255, 67 / 255, 1)
    ---@type Color 半身像颜色动画控制
    self._bodyFadeInColor = Color.New(1, 1, 1, 1)
    ---@type string 角色名文本内容
    self._speakerNameStr = ""
    ---@type bool 是否是玩家
    self._isPlayer = false

    ---@type boolean 是否开始显示文本内容了
    self._contentStartShow = false
    ---@type boolean 对话文本是否显示了
    self._contentShown = false
    ---@type boolean 在对话文本打字中
    self._inContentTyping = false
    ---@type boolean 对话打字机中点击
    self._typeClickEnd = false
    ---@type table<number, number> 从第一个断点开始后续每句话的持续打字时长
    self._contentTypeTimeList = {}
    ---@type number 打字开始时间
    self._contentTypeStartTime = 0
    ---@type number 渐显开始时间
    self._contentFadeInStartTime = 0
    ---@type number 当前断点前打字持续时间
    self._contentTypeTime = 0
    ---@type Color 颜色动画控制
    --self._contentFadeInColor = Color.New(1, 1, 1, 1)

    ---@type number
    self._selectedOptionIndex = 0

    ---@type number 文字显示开始时间
    self._contentStartShowTime = 0
    ---@type string 文字内容
    self._contentStr = ""
    ---@type number 文字数量
    self._wordTotalCount = 0
    ---@type number 当前断点位置
    self._curBreakIndex = 0

    ---@type boolean 是否文字显示动画结束
    --self._contentAnimEnd = true
    ---@type boolean 是否在文字结束后点击屏幕
    self._endClick = false

    ---@type bool 显示UI
    self._showUI = false
    ---@type bool 隐藏UI
    self._hideUI = false

    ---@type bool 自动结束对话内容
    self._auto = false
    ---@type number 自动结束等待的开始时间
    self._autoWaitStartTime = 0
    ---@type bool 选项处于显示状态
    self._optionShown = false
    ---@type bool 强制自动对话，并使用单独配置文本显示的时长
    self._forceAutoDialog = false
    ---@type table<number, number> 强制自动对话的每个断点等待时长
    self._forceWaitTime = {}

    ---配置项
    ---@type number 自动等待时长
    self._autoWaitTime = 1
    ---@type number 自动等待选项时长
    self._autoWaitOptionTime = 1
    ---@type string 颜色匹配字符串
    self._colorPattern = "<color=#%x*"
end

---小节开始填入数据---
function HomeStoryEntityDialog:SectionStart(trackData)
    HomeStoryEntityDialog.super.SectionStart(self, trackData)

    self._dialogLayout1:SetActive(false)
    self._dialogLayout2:SetActive(false)

    local body
    local speakerText
    local contentText
    if self._currentTrackData.DialogDir == 1 then
        body = self._bodyLeft
        speakerText = self._speakerTextLeft
        contentText = self._contentTextLeft
        --self._dialogLayout1:SetActive(true)
    else
        body = self._bodyRight
        speakerText = self._speakerTextRight
        contentText = self._contentTextRight
        --self._dialogLayout2:SetActive(true)
    end

    if self._currentTrackData.SpeakerNameStr then
        self._isPlayer = self._currentTrackData.SpeakerNameStr == "ui_story_name_you"
        self._speakerNameStr = StringTable.Get(self._currentTrackData.SpeakerNameStr)
        self._speakerNameStr = self:_DoEscape(self._speakerNameStr)
        speakerText:SetText(self._speakerNameStr)
    else
        speakerText:SetText("")
    end

    self._contentStr = StringTable.Get(self._currentTrackData.DialogContentStr)
    self._contentStr = self:_DoEscape(self._contentStr)
    self._contentStr, self._breakIndexList, self._wordTotalCount, self._hideTextAnim = self:_GetContentInfo(self._contentStr)

    --文本对齐方式
    if self._currentTrackData.ContentAlignment then
        if self._currentTrackData.ContentAlignment == 1 then
            contentText.alignment = UnityEngine.TextAnchor.UpperLeft
        elseif self._currentTrackData.ContentAlignment == 2 then
            contentText.alignment = UnityEngine.TextAnchor.UpperCenter
        elseif self._currentTrackData.ContentAlignment == 3 then
            contentText.alignment = UnityEngine.TextAnchor.UpperRight
        elseif self._currentTrackData.ContentAlignment == 4 then
            contentText.alignment = UnityEngine.TextAnchor.MiddleLeft
        elseif self._currentTrackData.ContentAlignment == 5 then
            contentText.alignment = UnityEngine.TextAnchor.MiddleCenter
        elseif self._currentTrackData.ContentAlignment == 6 then
            contentText.alignment = UnityEngine.TextAnchor.MiddleRight
        elseif self._currentTrackData.ContentAlignment == 7 then
            contentText.alignment = UnityEngine.TextAnchor.LowerLeft
        elseif self._currentTrackData.ContentAlignment == 8 then
            contentText.alignment = UnityEngine.TextAnchor.LowerCenter
        elseif self._currentTrackData.ContentAlignment == 9 then
            contentText.alignment = UnityEngine.TextAnchor.LowerRight
        else
            if self._currentTrackData.DialogDir == 1 then
                contentText.alignment = UnityEngine.TextAnchor.MiddleCenter
            else
                contentText.alignment = UnityEngine.TextAnchor.MiddleCenter
            end
        end
    else
        if self._currentTrackData.DialogDir == 1 then
            contentText.alignment = UnityEngine.TextAnchor.MiddleCenter
        else
            contentText.alignment = UnityEngine.TextAnchor.MiddleCenter
        end
    end

    contentText:SetText(self._contentStr)
    self._richText = contentText

    self._contentStartShow = false
    self._contentShown = false
    self._contentTypeStartTime = 0

    if self._currentTrackData.Body then
        body.gameObject:SetActive(true)
        body:LoadImage(self._currentTrackData.Body)
    else
        body.gameObject:SetActive(false)
    end

    --初始全部内容透明
    local transparent = Color.New(1, 1, 1, 0)
    speakerText.color = transparent

    --隐藏结束标识
    self:ActiveEndFlag(false)
    self._inContentEnding = false

    self._endClick = false
    self._autoWaitStartTime = 0

    self._fullscreenBtn.transform.position = self._storyManager:GetStoryUIRoot().transform.parent.position

    self._optionShown = false

    self._forceAutoDialog = self._storyManager:GetCurParagraph().ForceAutoDialog

    self:ShowChoose()
end

--显示选项
function HomeStoryEntityDialog:ShowChoose()
    ---选项部分-------
    --self._optRoot:SetActive(self._currentTrackData.Options ~= nil)

    if self._currentTrackData.Options ~= nil then
        local optionData = self._currentTrackData.Options
        for i = 1, #optionData do
            local _data = optionData[i]
            self._optionParagraphIDDic[i] = _data.NextParagraphID
        end
        local count = #optionData
        self._choosePool:SpawnObjects("UIHomeStoryChooseItem", count)
        local pools = self._choosePool:GetAllSpawnList()
        for i = 1, #pools do
            local item = pools[i]
            local txt = StringTable.Get(optionData[i].Content)
            item:SetData(i, txt, function(idx)
                self:ChooseItemClick(idx)
            end)
        end
    end
end

--选择选项
function HomeStoryEntityDialog:ChooseItemClick(idx)
    local optionData = self._currentTrackData.Options
    local _data = optionData[idx]
    self:_ChooseOption(idx)
end

---将UTF8字符串转为table
function HomeStoryEntityDialog:_GetContentInfo(str)
    local plainStr = string.gsub(str, "<size=%d*>", "")
    plainStr = string.gsub(plainStr, "</size>", "")
    plainStr = string.gsub(plainStr, "<color=#%x*>", "")
    plainStr = string.gsub(plainStr, "</color>", "")
    plainStr = string.gsub(plainStr, "<sprite.*/>", "a")
    local finalStr = string.gsub(str, self._splitChar, "")
    local breakIndexList = {}
    local charCount = 0
    for uchar in string.gmatch(plainStr, "[%z\1-\127\194-\244][\128-\191]*") do
        if uchar == self._splitChar then
            breakIndexList[#breakIndexList + 1] = charCount
        else
            charCount = charCount + 1
        end
    end
    breakIndexList[#breakIndexList + 1] = charCount
    local hideTextAnim = self:CheckHideTextAnim(str)
    return finalStr, breakIndexList, charCount, hideTextAnim
end

function HomeStoryEntityDialog:CheckHideTextAnim(str)
    local hide = HelperProxy:GetInstance():CheckTextIncludeImg(str)
    return hide
end

---字符转义
---目前支持如下 $$ -> $ | PlayerName -> 玩家姓名
---@param strContent string
---@return string
function HomeStoryEntityDialog:_DoEscape(strContent)
    strContent = string.gsub(strContent, "$$", "$")
    local name = GameGlobal.GetModule(RoleModule):GetName()
    if string.isnullorempty(name) then
        name = StringTable.Get("str_guide_moren_name")
    end
    strContent = string.gsub(strContent, "PlayerName", name) -- GameGlobal.GetModule("RoleModule").m_char_info.nick) 不知何时可用
    return strContent
end

function HomeStoryEntityDialog:_GetColorMarkPos(str)
end

---关键帧处理----
---@param keyframeData table
function HomeStoryEntityDialog:_TriggerKeyframe(keyframeData)
    --对话框每个小节第一个关键帧显示
    self._dialogUIView:GetGameObject():SetActive(true)

    self._showUI = true
    --隐藏功能
    if self._hideUI then
        self._dialogUIView:GetGameObject():SetActive(false)
    end

    --打字机动画去掉了
    --self._contentAnimEnd = false



    local speakerGo
    local speakerText
    local bodyRawImage
    local contentText
    local contentBg
    local contentGo
    if self._currentTrackData.DialogDir == 1 then
        speakerGo = self._speakerGOLeft
        speakerText = self._speakerTextLeft
        bodyRawImage = self._bodyRawImageLeft
        contentText = self._contentTextLeft
        contentBg = self._contentBG1
        contentGo = self._dialogLayout1
    else
        speakerGo = self._speakerGORight
        speakerText = self._speakerTextRight
        bodyRawImage = self._bodyRawImageRight
        contentText = self._contentTextRight
        contentBg = self._contentBG2
        contentGo = self._dialogLayout2
    end

    --如果是控制文本底板 直接设置显隐
    if keyframeData.ContentBGVisible ~= nil then
        local showC = 0
        if self._hideTextAnim then
            showC = -1
        end
        contentText.ShowCharCount = showC
        contentGo:SetActive(true)
        local anim
        if keyframeData.ContentBGVisible == true then
            anim = "story_home_content_bg_anim_in"
        else
            anim = "story_home_content_bg_anim_out"
        end
        if contentBg then
            contentBg:Play(anim)
        end
    end

    --开始显示角色名
    if keyframeData.ShowSpeakerName then
        speakerGo:SetActive(true)
        local showSpeakerNameTime = keyframeData.ShowSpeakerName
        if showSpeakerNameTime > 0 then
            self._inSpeakerNameFadeIn = true
            self._speakerNameFadeInStartTime = keyframeData.Time
            self._speakerNameFadeInDuration = showSpeakerNameTime
        else
            self._speakerNameFadeInColor.a = 1
            speakerText.color = self._speakerNameFadeInColor
        end
    end
    if keyframeData.BodyAlpha then
        local showBodyAlphaTime = keyframeData.BodyAlpha
        if showBodyAlphaTime > 0 then
            self._inBodyFadeIn = true
            self._bodyFadeInStartTime = keyframeData.Time
            self._bodyFadeInDuration = showBodyAlphaTime
        else
            self._bodyFadeInColor.a = 1
            bodyRawImage.color = self._bodyFadeInColor
        end
    end

    --开始显示对话文本 ShowContent含义目前是第一个断点前文字内容的打字机动画时长
    if keyframeData.ShowContent then
        self._contentStartShow = true
        self._contentTypeTimeList = keyframeData.TypeTimeList or {}
        self._curBreakIndex = 0

        self._inContentTyping = true
        self._contentTypeStartTime = keyframeData.Time
        self._contentTypeTime = keyframeData.ShowContent * self._breakIndexList[1]
        local showC = 0
        if self._hideTextAnim then
            showC = -1
        end
        contentText.ShowCharCount = showC

        --在文本开始显示是 开始播放语音和角色说话的表情动画
        if self._currentTrackData.VoiceRefID then
            self._storyManager:PlaySound(self._currentTrackData.VoiceRefID)
        end

        if self._currentTrackData.SpeakerRefID then
            self._storyManager:SetSpeakState(self._currentTrackData.SpeakerRefID, true)
        end

        if self._forceAutoDialog then
            self._forceWaitTime = keyframeData.ForceWaitTimeList or {}
        end
    end
    if keyframeData.HideFullScreenBtn ~= nil then
        self._fullscreenBtn:SetActive(not keyframeData.HideFullScreenBtn)
    end
end

---动画处理----
---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function HomeStoryEntityDialog:_UpdateAnimation(time)
    if not self._showUI then
        return false
    end

    local speakerText
    local bodyRawImage
    local contentText
    if self._currentTrackData.DialogDir == 1 then
        speakerText = self._speakerTextLeft
        bodyRawImage = self._bodyRawImageLeft
        contentText = self._contentTextLeft
    else
        speakerText = self._speakerTextRight
        bodyRawImage = self._bodyRawImageRight
        contentText = self._contentTextRight
    end

    --角色名动画
    if self._inSpeakerNameFadeIn then
        local alpha = (time - self._speakerNameFadeInStartTime) / self._speakerNameFadeInDuration
        if alpha >= 1 then
            alpha = 1
            self._inSpeakerNameFadeIn = false
            speakerText:SetText(self._speakerNameStr)
        end
        self._speakerNameFadeInColor.a = alpha
        speakerText.color = self._speakerNameFadeInColor

        local colorStr = string.format("%02x", math.floor(alpha * 255))
        local str =
        string.gsub(
            self._speakerNameStr,
            self._colorPattern,
            function(s)
                return s .. colorStr
            end
        )
        speakerText:SetText(str)
    end
    --角色半身像
    if self._inBodyFadeIn then
        local alpha = (time - self._bodyFadeInStartTime) / self._bodyFadeInDuration
        if alpha >= 1 then
            alpha = 1
            self._inBodyFadeIn = false
        end
        self._bodyFadeInColor.a = alpha
        bodyRawImage.color = self._bodyFadeInColor
    end

    --文本打字机内容动画
    if self._inContentTyping then
        if self._inContentEnding then
            --最后的不可点击结束时间
            if time - self._contentEndStartTime > self._contentEndingTime then

                self._inContentTyping = false
                self._contentShown = true
                self:ActiveEndFlag(true)
            end
        else
            --播放打字机动画中
            self._autoWaitStartTime = 0
            local breakPercent = 1
            if self._contentTypeTime > 0 and not self._typeClickEnd then
                breakPercent = (time - self._contentTypeStartTime) / self._contentTypeTime
                if breakPercent > 1 then
                    breakPercent = 1
                end
            end
            self._typeClickEnd = false
            local wordCount = -1

            if self._curBreakIndex == 0 then
                wordCount = math.floor(breakPercent * self._breakIndexList[self._curBreakIndex + 1])
            else
                wordCount = math.floor(
                    lmathext.lerp(
                        self._breakIndexList[self._curBreakIndex],
                        self._breakIndexList[self._curBreakIndex + 1],
                        breakPercent
                    )
                )
            end

            local showC = wordCount
            if self._hideTextAnim then
                showC = -1
            end
            contentText.ShowCharCount = showC

            if breakPercent == 1 then
                self._curBreakIndex = self._curBreakIndex + 1
                if self._curBreakIndex >= #self._breakIndexList then
                    self._inContentEnding = true
                    self._contentEndStartTime = time
                else
                    self._inContentTyping = false
                    self._contentTypeTime = (
                        self._contentTypeTimeList[self._curBreakIndex] or self._defaultBreakTypeTime) *
                        (self._breakIndexList[self._curBreakIndex + 1] - self._breakIndexList[self._curBreakIndex])
                end
            end
        end
    end

    --自动对话
    if self._contentStartShow and (self._auto or self._forceAutoDialog) and not self._endClick then
        if self._contentShown or not self._inContentTyping then
            if self._autoWaitStartTime == 0 then
                self._autoWaitStartTime = time

                if self._forceAutoDialog then
                    self._autoWaitTime = self._forceWaitTime[self._curBreakIndex]
                else
                    if self._curBreakIndex == 1 then
                        self._autoWaitTime = 1 + self._breakIndexList[self._curBreakIndex] * 0.075
                    else
                        self._autoWaitTime = 1 +
                            (self._breakIndexList[self._curBreakIndex] - self._breakIndexList[self._curBreakIndex - 1]) *
                            0.075
                    end
                end
                --Log.fatal("self._autoWaitTime: "..tostring(self._autoWaitTime))
            end
        end
        --对话全部显示完
        if self._contentShown then
            --对话显示完
            if self._currentTrackData.Options == nil then
                if time - self._autoWaitStartTime >= self._autoWaitTime then
                    self:_DialogEnd()
                end
            else
                if time - self._autoWaitStartTime >= self._autoWaitOptionTime and not self._optionShown then
                    self:_ShowOption()
                    self._optionShown = true
                end
            end
        elseif not self._inContentTyping then
            if time - self._autoWaitStartTime >= self._autoWaitTime then
                self._contentTypeStartTime = self._storyManager:GetCurrentTime()
                self._inContentTyping = true
                self:ActiveEndFlag(false)
            end
        end
    end

    if self._contentShown and self._endClick then
        self._dialogUIView:GetGameObject():SetActive(false)

        self._showUI = false
        return true
    else
        return false
    end
end

---对话结束
function HomeStoryEntityDialog:_DialogEnd()
    self._endClick = true

    if self._currentTrackData.VoiceRefID then
        self._storyManager:StopSound(self._currentTrackData.VoiceRefID)
    end

    local contentText
    local speakerText
    if self._currentTrackData.DialogDir == 1 then
        contentText = self._contentTextLeft
        speakerText = self._speakerTextLeft
    else
        contentText = self._contentTextRight
        speakerText = self._speakerTextRight
    end
    self._storyManager:AddDialogRecord(
        speakerText.text,
        contentText.text,
        self._isPlayer,
        self._currentTrackData.Body
    )

    ---选项内容也要加入到回顾界面中
    if self._currentTrackData.Options then
        ---选项回顾玩家名用'你'
        local playerName = self:_DoEscape(StringTable.Get("ui_story_name_you"))
        local optionContent = self._currentTrackData.Options[self._selectedOptionIndex].Content

        self._storyManager:AddDialogRecord(playerName, optionContent, true, nil)
    end
end

---交互部分--------------------
---点击屏幕反馈
function HomeStoryEntityDialog:FullScreenBtnOnClick()
    if self._endClick or self._forceAutoDialog or not self._contentStartShow then
        --if self._endClick or self._forceAutoDialog then
        return
    end

    if self._contentShown then
        AudioHelperController.PlayRequestedUISound(CriAudioIDConst.SoundStoryClick)
        self:_ShowOption()
    else
        if self._inContentTyping then
            AudioHelperController.PlayRequestedUISound(CriAudioIDConst.SoundStoryClick)
            self._typeClickEnd = true
        else
            AudioHelperController.PlayRequestedUISound(CriAudioIDConst.SoundStoryClick)
            self._contentTypeStartTime = self._storyManager:GetCurrentTime()
            self._inContentTyping = true
            self:ActiveEndFlag(false)
        end
    end
end

--endflag
function HomeStoryEntityDialog:ActiveEndFlag(active)
    self._endFlag:SetActive(active)
    -- if active then
    --     local newStr = HomeStoryHelper:GetInstance():FilterHtml(self._contentStr)
    --     local charIndex = HomeStoryHelper:GetInstance():GetstringCount(newStr)
    --     local endFlagPos = HomeStoryHelper:GetInstance():GetPosWithTextIndexVert(self._canvas,self._richText,newStr,charIndex,3)
    --     local emojiWidth = HomeStoryHelper:GetInstance():GetEmojiWidth(self._contentStr)
    --     local endFlagOffset = Vector3(emojiWidth,0,0)
    --     if endFlagPos then
    --         self._endFlag.transform.position = endFlagPos
    --         self._endFlag.transform.localPosition = self._endFlag.transform.localPosition+Vector3(70,5,0)+endFlagOffset
    --     end
    -- end
end

function HomeStoryEntityDialog:CancelHideButtonOnClcik()
    self._storyManager:HideUI(false)
    self._cancelHideButton:SetActive(false)
end

function HomeStoryEntityDialog:ButtonHideOnClick(go)
    self._storyManager:HideUI(true)
    self._cancelHideButton:SetActive(true)
end

function HomeStoryEntityDialog:CancelAutoButtonOnClick()
    self._storyManager:SetAuto(false)
    self._cancelAutoButton:SetActive(false)
end

function HomeStoryEntityDialog:ButtonAutoOnClick()
    self._storyManager:SetAuto(true)
    self._cancelAutoButton:SetActive(true)
end

--回看
function HomeStoryEntityDialog:ButtonReviewOnClick(go)
    self._dialogReviewScrollView.gameObject:SetActive(true)
    local dialogRecord = self._storyManager:GetDialogRecord()
    self._dialogReviewScrollView:SetListItemCount(#dialogRecord, true)
    self._dialogReviewScrollView:MovePanelToItemIndex(#dialogRecord - 1, 0)
end

function HomeStoryEntityDialog:SectionEnd()
    HomeStoryEntityDialog.super.SectionEnd(self)
    self._endClick = true
end

function HomeStoryEntityDialog:_ShowOption()
    if self._currentTrackData.Options == nil then
        self:_DialogEnd()
    else
        self._optRoot:SetActive(true)

        -- auto 隐藏UI节点处理
        if self._auto or self._forceAutoDialog then
            --self._optRoot.transform:SetParent(self._storyManager:GetStoryUIRoot().transform.parent.parent)
        end

        --self:ShowChoose()
    end
end

---选中选项
---@param index number 选项序号
function HomeStoryEntityDialog:_ChooseOption(index)
    AudioHelperController.PlayRequestedUISound(CriAudioIDConst.SoundStoryClick)

    self._selectedOptionIndex = index
    self._storyManager:SetNextParagraphID(self._optionParagraphIDDic[index])
    self._optRoot:SetActive(false)
    if self._auto then
        --self._optRoot.transform:SetParent(self._dialogUIView.transform)
    end

    self._optionParagraphIDDic = {}

    self:_DialogEnd()
end

--删除好感度增加

---隐藏UI
function HomeStoryEntityDialog:HideUI(hide)
    self._hideUI = hide

    self._dialogUIView:GetGameObject():SetActive(self._showUI and not hide)
end

---设置自动
function HomeStoryEntityDialog:SetAuto(auto)
    self._auto = auto
    self._autoWaitStartTime = 0

    -- if self._optRoot.activeSelf then
    --     if auto then
    --         self._optRoot.transform:SetParent(self._storyManager:GetStoryUIRoot().transform.parent.parent)
    --     else
    --         self._optRoot.transform:SetParent(self._dialogUIView.transform)
    --     end
    -- end
end
