--[[------------------
    Dialog剧情元素
--]] ------------------

_class("StoryEntityDialog", StoryEntity)
---@class StoryEntityDialog:StoryEntity
StoryEntityDialog = StoryEntityDialog

function StoryEntityDialog:Constructor(ID, gameObject, resRequest, storyManager)
    StoryEntityDialog.super.Constructor(self, ID, gameObject, resRequest, storyManager)
    ---@type number StoryEntityType
    self._type = StoryEntityType.Dialog
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

function StoryEntityDialog:InitUIComponents(gameObject)
    ---@type UIView 对话框prefab根节点上的uiview
    self._dialogUIView = gameObject:GetComponent("UIView")

    ---@type UnityEngine.UI.Image 对话框底图
    self._contentBG = self._dialogUIView:GetUIComponent("Image", "DialogBG")

    ---@type UnityEngine.GameObject 姓名节点
    self._speakerGO = self._dialogUIView:GetGameObject("DialogSpeaker")
    ---@type UnityEngine.UI.Image 姓名底图
    self._speakerBG1 = self._dialogUIView:GetUIComponent("Image", "DialogSpeakerBG1")
    ---@type UnityEngine.UI.Image 姓名底图2
    self._speakerBG2 = self._dialogUIView:GetUIComponent("Image", "DialogSpeakerBG2")

    ---@type UIRichText 对话框文本组件
    self._contentText = self._dialogUIView:GetUIComponent("UIRichText", "Content")
    ---@type UILocalizationText 姓名文本组件
    self._speakerText = self._dialogUIView:GetUIComponent("UILocalizationText", "SpeakerName")

    ---@type UnityEngine.GameObject 结束标识
    self._endFlag = self._dialogUIView:GetGameObject("EndFlag")

    ---@type UnityEngine.GameObject 全屏按钮
    self._fullscreenBtn = self._dialogUIView:GetGameObject("FullScreenBtn")

    ---@type UnityEngine.GameObject 选项根节点
    self._optRoot = self._dialogUIView:GetGameObject("Options")

    ---@type UnityEngine.GameObject 选项的Mask
    self._optMask = self._dialogUIView:GetGameObject("OptionMask")

    ---选项部分------
    ---@type table<int, UnityEngine.GameObject> 选项列表
    self._options = {}
    for i = 1, 3 do
        self._options[i] = self._dialogUIView:GetGameObject("Opt" .. i)
    end
    ---@type table<int, UnityEngine.UI.Button> 选项按钮列表
    self._optionBtns = {}
    for i = 1, 3 do
        self._optionBtns[i] = self._dialogUIView:GetUIComponent("Button", "Opt" .. i)
    end
    ---@type table<int, UnityEngine.UI.Image> 选项背景列表
    self._optionBGs = {}
    for i = 1, 3 do
        self._optionBGs[i] = self._dialogUIView:GetUIComponent("Image", "opt" .. i .. "Btn")
    end
    ---@type table<int, UnityEngine.GameObject> 选项按下列表
    self._optionPress = {}
    for i = 1, 3 do
        self._optionPress[i] = self._dialogUIView:GetGameObject("opt" .. i .. "BtnPress")
        self.uiCustomEventListener:AddUICustomEventListener(
            UICustomUIEventListener.Get(self._options[i]),UIEvent.Press,
            function(go)
                self._optionBGs[i].gameObject:SetActive(false)
                self._optionPress[i]:SetActive(true)
            end
        )
        self.uiCustomEventListener:AddUICustomEventListener(
            UICustomUIEventListener.Get(self._options[i]),UIEvent.Release,
            function(go)
                self._optionBGs[i].gameObject:SetActive(true)
                self._optionPress[i]:SetActive(false)
            end
        )
        self.uiCustomEventListener:AddUICustomEventListener(
            UICustomUIEventListener.Get(self._options[i]),
            UIEvent.Hovered,
            function(go)
                if UICustomUIEventListener.Get(self._options[i]).IsPressd then
                    self._optionBGs[i].gameObject:SetActive(false)
                    self._optionPress[i]:SetActive(true)
                end
            end
        )
        self.uiCustomEventListener:AddUICustomEventListener(
            UICustomUIEventListener.Get(self._options[i]),
            UIEvent.Unhovered,
            function(go)
                self._optionBGs[i].gameObject:SetActive(true)
                self._optionPress[i]:SetActive(false)
            end
        )
    end
    ---@type table<int, UILocalizationText> 选项文本列表
    self._optionTexts = {}
    for i = 1, 3 do
        self._optionTexts[i] = self._dialogUIView:GetUIComponent("UILocalizationText", "opt" .. i .. "Text")
    end
    ---@type table<int, UnityEngine.GameObject> 好感度标志列表
    self._optionAffinity = {}
    for i = 1, 3 do
        self._optionAffinity[i] = self._dialogUIView:GetGameObject("affinity" .. i)
    end

    ---@type UnityEngine.UI.Image 图片前绳子1
    self._ropeFront1 = self._dialogUIView:GetUIComponent("Image", "RopeFront1")
    ---@type UnityEngine.UI.Image 图片后绳子1
    self._ropeBack1 = self._dialogUIView:GetUIComponent("Image", "RopeBack1")
    ---@type UnityEngine.UI.Image 图片后绳子2
    self._ropeBack2 = self._dialogUIView:GetUIComponent("Image", "RopeBack2")

    self._optionParagraphIDDic = {}
    self._optionAffinityData = {}

    ---选项数量分别为3/2/1时每个选项的位置
    self._threeOptPosList = {Vector3(-59, 217, 0), Vector3(-9.5, 58, 0), Vector3(37.5, -104, 0)}
    self._twoOptPosList = {Vector3(-58.5, 137.5, 0), Vector3(-9.5, -22, 0)}
    self._oneOptPos = {Vector3(-9.5, 54, 0)}
    self._OptPosList = {self._oneOptPos, self._twoOptPosList, self._threeOptPosList}
    ----------------
    ---说话人名底板图标变化
    ---@type string
    self._dialogSpeakerBGBlue = "plot_juqing_xian0"
    self._dialogSpeakerBGRed = "plot_juqing_xian1"
    ------------------------------起名 ----------------------------
    self._createName = {}
    self._createName.go = self._dialogUIView:GetGameObject("CreateName")
    self._createName.go:SetActive(false)
    self._createName.errorTxt = self._dialogUIView:GetUIComponent("UILocalizationText", "ErrorTxt")
    ---@type EmojiFilteredInputField
    self._createName.inputField = self._dialogUIView:GetUIComponent("EmojiFilteredInputField", "InputField")
    self._createName.placeHolderGO = self._dialogUIView:GetGameObject("Placeholder")
    self._createName.placeHolderLZT = self._dialogUIView:GetUIComponent("UILocalizationText", "Placeholder")

    self._createName.inputDecorateGO = self._dialogUIView:GetGameObject("inputDecorate")
    self._etl = UICustomUIEventListener.Get(self._createName.inputField.gameObject)
    self.uiCustomEventListener:AddUICustomEventListener(
        self._etl,UIEvent.Press,
        function()
            if self._createName.inputField.touchScreenKeyboard then
                pcall(StoryEntityDialog.ActiveKeyboard, self, false)
            end
        end
    )
    self.uiCustomEventListener:AddUICustomEventListener(
        self._etl,UIEvent.Click,
        function()
            if string.len(self._createName.inputField.text) <= 0 then
                self._createName.placeHolderLZT.enabled = false
                self._createName.inputDecorateGO:SetActive(false)
            end
        end
    )
    self._createName.inputField.onValueChanged:AddListener(
        function()
            local s = self._createName.inputField.text
            if string.match(s, " ") then
                ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_INVALID"))
                s = string.gsub(s, " ", "")
            end
            self._createName.inputField.text = s
            if string.len(self._createName.inputField.text) > 0 then
                self._createName.placeHolderLZT.enabled = true
                self._createName.inputDecorateGO:SetActive(false)
            else
                self._createName.placeHolderLZT.enabled = true
                self._createName.inputDecorateGO:SetActive(true)
            end
        end
    )
    self._resumeCallBack = GameHelper:GetInstance():CreateCallback(self.OnAppResume, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.AppResume, self._resumeCallBack)
end

function StoryEntityDialog:Destroy()
    if self._resumeCallBack then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.AppResume, self._resumeCallBack)
    end
    self.uiCustomEventListener:RemoveAllCustomEventListener()
end
function StoryEntityDialog:GetOptions()
if not self._currentTrackData.Options.OptionLoop then
    return  self._currentTrackData.Options
else
    return self._storyManager:GetOptionData(
        self._currentTrackData.Options,
        self._currentTrackData.DialogContentStr)
end

end
function StoryEntityDialog:InitData()
    ---以下为运行时动画数据
    --[[
    ---@type boolean 在渐显中
    self._inFadeIn = false
    ---@type number 渐显开始时间
    self._fadeInStartTime = 0
    ---@type number 渐显持续时间
    self._fadeInDuration = 0

    ---@type boolean 有渐隐动画
    self._hasFadeOut = false
    ---@type boolean 在渐隐中
    self._inFadeOut = false
    ---@type number 渐隐开始时间
    self._fadeOutStartTime = 0
    ---@type number 渐隐持续时间
    self._fadeOutDuration = 0

    ---@type Color 颜色动画控制(白)
    self._fadeColorWhite = Color:New(1,1,1,1)
    ]]
    ---@type boolean 在角色名渐显中
    self._inSpeakerNameFadeIn = false
    ---@type number 渐显开始时间
    self._speakerNameFadeInStartTime = 0
    ---@type number 渐显持续时间
    self._speakerNameFadeInDuration = 0
    ---@type Color 颜色动画控制
    self._speakerNameFadeInColor = Color.New(1, 1, 1, 1)
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

    ---@type boolean 在选项渐显中
    self._inOptionsFadeIn = false
    ---@type number 渐显开始时间
    self._optionsFadeInStartTime = 0
    ---@type number 渐显持续时间
    self._optionsFadeInDuration = 0
    ---@type Color 颜色动画控制
    self._optionsFadeInColor = Color.New(1, 1, 1, 1)
    ---@type number 需要显示的选项数量
    self._optionsCount = 1
    ---@type table<int, string> 选项文本内容
    self._optionsStrList = {"", "", ""}
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
    ---@type number 选项渐显时长
    self._optionsFadeInTimeConfig = 0.5
    ---@type string 颜色匹配字符串
    self._colorPattern = "<color=#%x*"
end

---小节开始填入数据---
function StoryEntityDialog:SectionStart(trackData)
    StoryEntityDialog.super.SectionStart(self, trackData)
    self._speakerGO:SetActive(false)
    if self._currentTrackData.SpeakerNameStr then
        self._isPlayer = self._currentTrackData.SpeakerNameStr == "ui_story_name_you"
        self._speakerNameStr = StringTable.Get(self._currentTrackData.SpeakerNameStr)
        self._speakerNameStr = self:_DoEscape(self._speakerNameStr)
        self._speakerText:SetText(self._speakerNameStr)
        if self._isPlayer or self._currentTrackData.SpeakerBGColor == "blue" then
            self._speakerBG1.sprite = self._storyManager:GetUIAtlas():GetSprite(self._dialogSpeakerBGBlue)
            self._speakerBG2.sprite = self._storyManager:GetUIAtlas():GetSprite(self._dialogSpeakerBGBlue)
        else
            self._speakerBG1.sprite = self._storyManager:GetUIAtlas():GetSprite(self._dialogSpeakerBGRed)
            self._speakerBG2.sprite = self._storyManager:GetUIAtlas():GetSprite(self._dialogSpeakerBGRed)
        end
    else
        self._speakerText:SetText("")
    end

    --文本内容
    self._contentText.gameObject:SetActive(false)
    self._contentStr = StringTable.Get(self._currentTrackData.DialogContentStr)
    self._contentStr = self:_DoEscape(self._contentStr)
    self._contentStr, self._breakIndexList, self._wordTotalCount = self:_GetContentInfo(self._contentStr)
    self._contentText:SetText(self._contentStr)
    self._contentStartShow = false
    self._contentShown = false
    self._contentTypeStartTime = 0

    --初始全部内容透明
    local transparent = Color.New(1, 1, 1, 0)
    --self._contentText.color = transparent
    self._speakerBG1.color = transparent
    self._speakerBG2.color = transparent
    self._speakerText.color = transparent

    --隐藏结束标识
    self._endFlag:SetActive(false)
    self._inContentEnding = false

    self._endClick = false
    self._autoWaitStartTime = 0
    self._optionShown = false

    self._fullscreenBtn.transform.position = self._storyManager:GetStoryUIRoot().transform.parent.position

    ---选项部分-------
    if self._currentTrackData.Options ~= nil then
        self._optRoot.transform.position = self._storyManager:GetStoryUIRoot().transform.parent.position
        self._optMask.transform.position = self._storyManager:GetStoryUIRoot().transform.parent.position
        local optionData = self:GetOptions()
        self._optionsCount = #self._options
        local optPosList = self._OptPosList[#optionData]
        local showAffinityIcon =
            not GameGlobal.GetModule(StoryModule):IsAdded(
            self._storyManager:GetCurStoryID(),
            self._storyManager:GetCurParagraphID(),
            self._storyManager:GetCurSectionIndex()
        )
        for i = 1, self._optionsCount do
            if optionData[i] then
                self._options[i]:SetActive(true)
                self._options[i].transform.localPosition = optPosList[i]
                self._optionBtns[i].interactable = false
                self._optionsStrList[i] = self:_DoEscape(StringTable.Get(optionData[i].Content))
                self._optionTexts[i]:SetText(self._optionsStrList[i])
                self._optionParagraphIDDic[i] = optionData[i].NextParagraphID

                if showAffinityIcon and optionData[i].PetID and optionData[i].Affinity then
                    self._optionAffinity[i]:SetActive(true)
                    self._optionAffinityData[i] = {
                        PetID = optionData[i].PetID,
                        Affinity = optionData[i].Affinity
                    }
                else
                    self._optionAffinity[i]:SetActive(false)
                end
            else
                self._options[i]:SetActive(false)
            end
        end

        self._ropeFront1.gameObject:SetActive(#optionData > 1)
        self._ropeBack1.gameObject:SetActive(#optionData > 1)
        self._ropeBack2.gameObject:SetActive(#optionData > 2)
    end
    -- 取名
    if self._currentTrackData.CreateName then
        self._createName.go.transform.position = self._storyManager:GetStoryUIRoot().transform.parent.position
    end

    self._forceAutoDialog = self._storyManager:GetCurParagraph().ForceAutoDialog
    -----------------
end

---将UTF8字符串转为table
function StoryEntityDialog:_GetContentInfo(str)
    local plainStr = string.gsub(str, "<size=%d*>", "")
    plainStr = string.gsub(plainStr, "</size>", "")
    plainStr = string.gsub(plainStr, "<color=#%x*>", "")
    plainStr = string.gsub(plainStr, "</color>", "")
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
    return finalStr, breakIndexList, charCount
end

---字符转义
---目前支持如下 $$ -> $ | PlayerName -> 玩家姓名
---@param strContent string
---@return string
function StoryEntityDialog:_DoEscape(strContent)
    strContent = string.gsub(strContent, "$$", "$")
    local name = GameGlobal.GetModule(RoleModule):GetName()
    if string.isnullorempty(name) then
        name = StringTable.Get("str_guide_moren_name")
    end
    strContent = string.gsub(strContent, "PlayerName", name) -- GameGlobal.GetModule("RoleModule").m_char_info.nick) 不知何时可用
    return strContent
end

function StoryEntityDialog:_GetColorMarkPos(str)
end

---关键帧处理----
---@param keyframeData table
function StoryEntityDialog:_TriggerKeyframe(keyframeData)
    --对话框每个小节第一个关键帧显示
    self._dialogUIView:SetShow(true, self)
    self._showUI = true
    --隐藏功能
    if self._hideUI then
        self._dialogUIView.gameObject:SetActive(false)
    end

    --打字机动画去掉了
    --self._contentAnimEnd = false

    --如果是控制文本底板 直接设置显隐
    if keyframeData.ContentBGVisible ~= nil then
        self._contentBG.gameObject:SetActive(keyframeData.ContentBGVisible)
    end

    --开始显示角色名
    if keyframeData.ShowSpeakerName then
        self._speakerGO:SetActive(true)
        local showSpeakerNameTime = keyframeData.ShowSpeakerName
        if showSpeakerNameTime > 0 then
            self._inSpeakerNameFadeIn = true
            self._speakerNameFadeInStartTime = keyframeData.Time
            self._speakerNameFadeInDuration = showSpeakerNameTime
        else
            self._speakerNameFadeInColor.a = 1
            self._speakerBG1.color = self._speakerNameFadeInColor
            self._speakerBG2.color = self._speakerNameFadeInColor
            self._speakerText.color = self._speakerNameFadeInColor
        end
    end

    --开始显示对话文本 ShowContent含义目前是第一个断点前文字内容的打字机动画时长
    if keyframeData.ShowContent then
        self._contentStartShow = true
        self._contentText.gameObject:SetActive(true)
        self._contentTypeTimeList = keyframeData.TypeTimeList or {}
        self._curBreakIndex = 0
        self._inContentTyping = true
        self._contentTypeStartTime = keyframeData.Time
        self._contentTypeTime = keyframeData.ShowContent * self._breakIndexList[1]
        self._contentText.ShowCharCount = 0

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

    --开始显示选项 选项改为点击后显示 不再根据时间配置显示 2020.7.7 winter
    --[[
    if keyframeData.ShowOptions then
        if self._currentTrackData.Options ~= nil then
            self._inOptionsFadeIn = true
            self._optionsFadeInStartTime = keyframeData.Time
            self._optionsFadeInDuration = self._optionsFadeInTimeConfig

            self._optRoot:SetActive(true)
            self._optMask:SetActive(true)

            --
            if self._auto then
                self._optRoot.transform:SetParent(self._storyManager:GetStoryUIRoot().transform.parent.parent)
            end
        end
    end
    ]]
    -- 创角起名
    if keyframeData.ShowCreateName then
        local roleModule = GameGlobal.GetModule(RoleModule)
        if string.isnullorempty(roleModule:GetName()) then
            GameGlobal.ReportCustomEvent("CreateRole","SetRoleNameView")
            GameGlobal.UAReportForceGuideEvent("SetNameWindowShow")
            self._createName.go:SetActive(true)
        -- TaskManager:GetInstance():StartTask(
        --     function(TT)
        --         local caret = self._createName.inputField.transform:Find("InputField Input Caret")
        --         while (caret == nil) do
        --             caret = self._createName.inputField.transform:Find("InputField Input Caret")
        --             YIELD(TT)
        --         end
        --         caret.anchoredPosition = Vector2(20, 7)
        --     end
        -- )
        end
    -- if self._auto then
    --     self._optRoot.transform:SetParent(self._storyManager:GetStoryUIRoot().transform.parent.parent)
    -- end
    end
    if keyframeData.HideFullScreenBtn ~= nil then
        self._fullscreenBtn:SetActive(not keyframeData.HideFullScreenBtn)
    end
end

---动画处理----
---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function StoryEntityDialog:_UpdateAnimation(time)
    if not self._showUI then
        return false
    end

    --角色名动画
    if self._inSpeakerNameFadeIn then
        local alpha = (time - self._speakerNameFadeInStartTime) / self._speakerNameFadeInDuration
        if alpha >= 1 then
            alpha = 1
            self._inSpeakerNameFadeIn = false
            self._speakerText:SetText(self._speakerNameStr)
        end
        self._speakerNameFadeInColor.a = alpha
        self._speakerBG1.color = self._speakerNameFadeInColor
        self._speakerBG2.color = self._speakerNameFadeInColor
        self._speakerText.color = self._speakerNameFadeInColor

        local colorStr = string.format("%02x", math.floor(alpha * 255))
        local str =
            string.gsub(
            self._speakerNameStr,
            self._colorPattern,
            function(s)
                return s .. colorStr
            end
        )
        self._speakerText:SetText(str)
    end

    --文本打字机内容动画
    if self._inContentTyping then
        if self._inContentEnding then
            --最后的不可点击结束时间
            if time - self._contentEndStartTime > self._contentEndingTime then
                self._inContentTyping = false
                self._contentShown = true
                self._endFlag:SetActive(true)
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
                wordCount =
                    math.floor(
                    lmathext.lerp(
                        self._breakIndexList[self._curBreakIndex],
                        self._breakIndexList[self._curBreakIndex + 1],
                        breakPercent
                    )
                )
            end

            self._contentText.ShowCharCount = wordCount

            if breakPercent == 1 then
                self._curBreakIndex = self._curBreakIndex + 1
                if self._curBreakIndex >= #self._breakIndexList then
                    self._inContentEnding = true
                    self._contentEndStartTime = time
                else
                    self._inContentTyping = false
                    self._contentTypeTime =
                        (self._contentTypeTimeList[self._curBreakIndex] or self._defaultBreakTypeTime) *
                        (self._breakIndexList[self._curBreakIndex + 1] - self._breakIndexList[self._curBreakIndex])
                end
            end
        end

    --[[ 渐显的透明度需要设置到颜色标签中
        local colorStr = string.format("%02x", math.floor(alpha * 255))
        local str =
            string.gsub(
            self._contentStr,
            self._colorPattern,
            function(s)
                return s .. colorStr
            end
        )
        self._contentText:SetText(str)]]
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
                        self._autoWaitTime = 1 + (self._breakIndexList[self._curBreakIndex] - self._breakIndexList[self._curBreakIndex - 1]) * 0.075
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
                self._endFlag:SetActive(false)
            end
        end
    end

    --选项内容动画
    if self._inOptionsFadeIn then
        if self._optionsFadeInStartTime == 0 then
            self._optionsFadeInStartTime = time
        end
        local alpha = (time - self._optionsFadeInStartTime) / self._optionsFadeInDuration
        if alpha >= 1 then
            alpha = 1
            self._inOptionsFadeIn = false
            for i = 1, self._optionsCount do
                self._optionBtns[i].interactable = true
                self._optionTexts[i]:SetText(self._optionsStrList[i])
            end
        end
        self._optionsFadeInColor.a = alpha

        local colorStr = string.format("%02x", math.floor(alpha * 255))

        for i = 1, self._optionsCount do
            self._optionBGs[i].color = self._optionsFadeInColor
            self._optionTexts[i].color = self._optionsFadeInColor
            local str =
                string.gsub(
                self._optionsStrList[i],
                self._colorPattern,
                function(s)
                    return s .. colorStr
                end
            )
            self._optionTexts[i]:SetText(str)
        end

        if #self:GetOptions() == 2 then
            self._ropeFront1.color = self._optionsFadeInColor
            self._ropeBack1.color = self._optionsFadeInColor
        elseif #self:GetOptions() == 3 then
            self._ropeFront1.color = self._optionsFadeInColor
            self._ropeBack1.color = self._optionsFadeInColor
            self._ropeBack2.color = self._optionsFadeInColor
        end
    end

    --渐隐动画 去掉了
    --[[
    if self._inFadeOut then
        allEnd = false
        local alpha = (time - self._fadeOutStartTime) / self._fadeOutDuration
        if alpha > 1 then 
            alpha = 1
            self._inFadeOut = false
        end
        self._fadeColorWhite.a = 1 - alpha
        self._speakerBG.color = self._fadeColorWhite
        self._contentText.color = self._fadeColorWhite
        self._speakerText.color = self._fadeColorWhite
        --self._endFlag.color = self._fadeColorWhite 变为特效了
    end]]
    if self._contentShown and self._endClick then
        self._dialogUIView:SetShow(false, self)
        self._showUI = false
        return true
    else
        return false
    end
end

---对话结束
function StoryEntityDialog:_DialogEnd()
    --[[
    if self._hasFadeOut then
        self._inFadeOut = true
    end]]
    self._endClick = true

    --self._fadeOutStartTime = self._storyManager:GetCurrentTime()

    if self._currentTrackData.VoiceRefID then
        self._storyManager:StopSound(self._currentTrackData.VoiceRefID)
    end

    self._storyManager:AddDialogRecord(
        self._speakerText.text,
        self._contentText.text,
        self._currentTrackData.SpeakerBGColor,
        self._isPlayer
    )

    ---选项内容也要加入到回顾界面中
    if self._currentTrackData.Options then
        ---选项回顾玩家名用'你'
        local playerName = self:_DoEscape(StringTable.Get("ui_story_name_you"))
        local optionContent = self._optionsStrList[self._selectedOptionIndex]
        local playerNameBG = "blue"

        self._storyManager:AddDialogRecord(playerName, optionContent, playerNameBG)
    end
end

---交互部分--------------------
---点击屏幕反馈
function StoryEntityDialog:FullScreenBtnOnClick()
    if self._endClick or self._forceAutoDialog or not self._contentStartShow then
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
            self._endFlag:SetActive(false)
        end
    end
end

function StoryEntityDialog:SectionEnd()
    StoryEntityDialog.super.SectionEnd(self)
    self._endClick = true
end

function StoryEntityDialog:_ShowOption()
    if self._currentTrackData.Options == nil then
        self:_DialogEnd()
    else
        self._inOptionsFadeIn = true
        self._optionsFadeInDuration = self._optionsFadeInTimeConfig
        self._optionsFadeInStartTime = 0

        self._optRoot:SetActive(true)
        self._optMask:SetActive(true)

        -- auto 隐藏UI节点处理
        if self._auto or self._forceAutoDialog then
            self._optRoot.transform:SetParent(self._storyManager:GetStoryUIRoot().transform.parent.parent)
        end
    end
end

---选择第一个选项
function StoryEntityDialog:Opt1OnClick()
    self:_ChooseOption(1)
end

---选择第而个选项
function StoryEntityDialog:Opt2OnClick()
    self:_ChooseOption(2)
end

---选择第三个选项
function StoryEntityDialog:Opt3OnClick()
    self:_ChooseOption(3)
end

---选中选项
---@param index number 选项序号
function StoryEntityDialog:_ChooseOption(index)
    if self._inOptionsFadeIn then
        return
    end

    local optionData =
        self._storyManager:GetOptionData(self._currentTrackData.Options, self._currentTrackData.DialogContentStr)
    local selectIndex = optionData[index].optionIndex or index

    GameGlobal.EventDispatcher():Dispatch(GameEventType.StoryChooseOption, selectIndex, self._storyManager)
    GameGlobal.UAReportForceGuideEvent(
        'SotrySelect',
        {
            self._storyManager:GetCurStoryID(),
            self._storyManager:GetCurParagraphID(),
            self._storyManager:GetCurSectionIndex(),
            selectIndex
        }
    )

    AudioHelperController.PlayRequestedUISound(CriAudioIDConst.SoundStoryClick)

    self._selectedOptionIndex = index

    self._storyManager:AddSelectOptionID(self._currentTrackData, selectIndex)
    --self._storyManager:AddSelectOptionID(self._currentTrackData.DialogContentStr, selectIndex)
    self._storyManager:CheckOptionLoopOver(self._currentTrackData.Options, self._currentTrackData.DialogContentStr)

    self._storyManager:SetNextParagraphID(self._optionParagraphIDDic[index])

    self._optRoot:SetActive(false)
    self._optMask:SetActive(false)
    if self._auto then
        self._optRoot.transform:SetParent(self._dialogUIView.transform)
    end

    self._optionParagraphIDDic = {}
    if self._optionAffinityData[selectIndex] then
        GameGlobal.TaskManager():StartTask(self._ChooseOptionReq, self, selectIndex)
    else
        self:_DialogEnd()
    end
end


function StoryEntityDialog:_ChooseOptionReq(TT, index)
    GameGlobal.UIStateManager():Lock("StoryEntityDialog:_ChooseOptionReq")
    ---@type AsyncRequestRes
    local res =
        GameGlobal.GetModule(StoryModule):ReqAddMsg(
        TT,
        self._storyManager:GetCurStoryID(),
        self._storyManager:GetCurParagraphID(),
        self._storyManager:GetCurSectionIndex(),
        index
    )

    if res:GetSucc() then
        GameGlobal.UIStateManager():CallUIMethod(
            "UIStoryController",
            "ShowAddAffinity",
            self._optionAffinityData[index].PetID,
            self._optionAffinityData[index].Affinity
        )
    else
        Log.fatal(
            "[Story] error when choose option with affinity increasement, storyID:" ..
                self._storyManager:GetCurStoryID() ..
                    " paragraphID:" ..
                        self._storyManager:GetCurParagraphID() ..
                            " sectionID:" ..
                                self._storyManager:GetCurSectionIndex() ..
                                    " option index:" .. index .. " error code:" .. res:GetResult()
        )
    end

    self:_DialogEnd()
    GameGlobal.UIStateManager():UnLock("StoryEntityDialog:_ChooseOptionReq")
end
--------------------------

---隐藏UI
function StoryEntityDialog:HideUI(hide)
    self._hideUI = hide

    if hide then
        self._optMask.transform:SetParent(self._dialogUIView.transform.parent)
    else
        self._optMask.transform:SetParent(self._dialogUIView.transform)
        self._optMask.transform:SetSiblingIndex(self._optRoot.transform:GetSiblingIndex())
    end

    self._dialogUIView.gameObject:SetActive(self._showUI and not hide)
end

---设置自动
function StoryEntityDialog:SetAuto(auto)
    self._auto = auto
    self._autoWaitStartTime = 0
    local status, err = pcall(function()
        if self._optRoot.activeSelf then
            if auto then
                self._optRoot.transform:SetParent(self._storyManager:GetStoryUIRoot().transform.parent.parent)
            else
                self._optRoot.transform:SetParent(self._dialogUIView.transform)
            end
        end

      end)

end

function StoryEntityDialog:CheckCreateNameError()
    -- 空名字
    if string.isnullorempty(self._createName.inputField.text) then
        ToastManager.ShowToast(StringTable.Get("str_guide_create_no_name"))
        return true
    end
    self.newName = self._createName.inputField.text
    -- 名字长度
    if HelperProxy:GetInstance():GetCharLength(self.newName) > 14 then
        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_LIMIT"))
        return true
    end
    return false
end
function StoryEntityDialog:BtnCreateNameOnClick(go)
    GameGlobal.UAReportForceGuideEvent("SetNameClick")
    if self._currentTrackData and self._currentTrackData.CreateName then
        if self:CheckCreateNameError() then
            GameGlobal.UAReportForceGuideEvent("SetNameFail", {ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_LIMIT})
            return
        end
        TaskManager:GetInstance():StartTask(
            function(TT)
                ---@type RoleModule
                local roleModule = GameGlobal.GetModule(RoleModule)
                GameGlobal.UIStateManager():Lock("StoryEntityDialog:BtnCreateNameOnClick")
                local res = roleModule:RequestChangeName(TT, self.newName)
                GameGlobal.UIStateManager():UnLock("StoryEntityDialog:BtnCreateNameOnClick")
                if res:GetSucc() then
                    -- 上报UA打点
                    roleModule:SetName(self.newName)
                    self._storyManager:SetNextParagraphID(self._currentTrackData.CreateName.NextParagraphID)
                    self._createName.go:SetActive(false)
                    self:_DialogEnd()
                    GameGlobal.ReportCustomEvent("CreateRole","SetRoleName")
                    GameGlobal.UAReportForceGuideEvent("SetNameSucc")
                    -- 上报新手引导信息
                    GameGlobal.UAReportChannelEvent("tutorial_start", {})
                else
                    --ROLE_ERROR_DIRTY_NICK           = 9,        // 名字含有敏感字
                    --ROLE_ERROR_CHANGE_NICK_INVALID        = 22,         // 名字含有其他国家的文字 只能是中文 日文 数字 英文字母
                    --      ROLE_ERROR_CHANGE_NICK_LIMIT        = 23,        // 名字最大长度不能超过16个字符(英文16个中文8个)
                    --    ROLE_ERROR_CHANGE_NICK_REPEAT        = 24,        // 该角色已经拥有名字
                    --  ROLE_ERROR_CHANGE_NICK_SPE                = 25,        // 名字含有特殊字符
                    --ROLE_ERROR_DUPLICATE_NICK       = 8,        // 重名
                    local errorCode = res.m_result
                    GameGlobal.UAReportForceGuideEvent("SetNameFail", {errorCode})
                    if errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_INVALID then --     -- 名字含有其他国家的文字 只能是中文 日文 数字 英文字母
                        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_INVALID"))
                    elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_LIMIT then -- // 名字最大长度不能超过16个字符(英文16个中文8个)
                        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_LIMIT"))
                    elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_DIRTY_NICK then --  // 名字含有敏感字
                        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_DIRTY_NICK"))
                    elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_REPEAT then -- // 该角色已经拥有名字
                        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_REPEAT"))
                    elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_SPE then -- // 名字含有特殊字符
                        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_SPE"))
                    elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_DUPLICATE_NICK then -- //  // 重名
                        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_DUPLICATE_NICK"))
                    end
                end
            end
        )
    end
end

function StoryEntityDialog:OnAppResume()
    if self._createName.inputField.touchScreenKeyboard then
        pcall(StoryEntityDialog.ActiveKeyboard, self, true)
    end
end

--iphonex xs 11 在键盘激活状态锁屏 解锁回到游戏后 取消输入操作会产生系统键盘UI不隐藏的bug (看起来像是系统或unity的问题)
function StoryEntityDialog:ActiveKeyboard(active)
    self._createName.inputField.touchScreenKeyboard.active = active
end
