require "story_entity"
--[[------------------
    AVGDialog 剧情元素
--]] ------------------
_class("N28StoryEntityAVGDialog", StoryEntity)
---@class N28StoryEntityAVGDialog:StoryEntity
N28StoryEntityAVGDialog = N28StoryEntityAVGDialog

function N28StoryEntityAVGDialog:Constructor(ID, gameObject, resRequest, storyManager)
    N28StoryEntityAVGDialog.super.Constructor(self, ID, gameObject, resRequest, storyManager)
    ---@type StoryEntityType
    self._type = StoryEntityType.AVGDialog
    self.newName = ""
    self._splitChar = "|"
    ---@type number 默认断点打字机动画时长
    self._defaultBreakTypeTime = 0.2
    ---@type number 显示完毕后的无法点击时间
    self._contentEndingTime = 0.2
    self:InitUIComponents(gameObject)
    self:InitData()
    self._playedIn = false
end

function N28StoryEntityAVGDialog:InitUIComponents(gameObject)
    ---@type UIView 对话框prefab根节点上的uiview
    self._dialogUIView = gameObject:GetComponent("UIView")

    self._contentBG = self._dialogUIView:GetGameObject("DialogBG") --对话框底图

    ---@type UnityEngine.GameObject 姓名节点
    self._speakerGO = self._dialogUIView:GetGameObject("DialogSpeaker")

    ---@type UIRichText 对话框文本组件
    self._contentText = self._dialogUIView:GetUIComponent("UIRichText", "Content")
    ---@type UILocalizationText 姓名文本组件
    self._speakerText = self._dialogUIView:GetUIComponent("UILocalizationText", "SpeakerName")
    ---@type UILocalizationText
    self.txtSpeakerName = self._dialogUIView:GetUIComponent("UILocalizationText", "txtSpeakerName")

    ---@type UnityEngine.GameObject 结束标识
    self._endFlag = self._dialogUIView:GetGameObject("EndFlag")

    ---@type UnityEngine.GameObject 全屏按钮
    self._fullscreenBtn = self._dialogUIView:GetGameObject("FullScreenBtn")

    ---说话人名底板图标变化
    self._dialogSpeakerBGBlue = "plot_juqing_xian0"
    self._dialogSpeakerBGRed = "plot_juqing_xian1"

    ---@type UnityEngine.Animation
    self._anim = self._dialogUIView:GetUIComponent("Animation", "anim")
    ---@type UnityEngine.CanvasGroup
    self._dialogBg = self._dialogUIView:GetUIComponent("CanvasGroup", "DialogBG")
    ---@type UnityEngine.CanvasGroup
    self._dialogLayout = self._dialogUIView:GetUIComponent("CanvasGroup", "DialogLayout")
end

function N28StoryEntityAVGDialog:Destroy()
    if self._playAnimationTask then
        GameGlobal.TaskManager():KillTask(self._playAnimationTask)
        self._playAnimationTask = nil
    end
    self._playedIn = false
    GameGlobal.UIStateManager():UnLock("N28StoryEntityAVGDialog_PlayAnimationIn")
    GameGlobal.UIStateManager():UnLock("N28StoryEntityAVGDialog_PlayAnimationOut")
end

function N28StoryEntityAVGDialog:InitData()
    ---@type boolean 在角色名渐显中
    self._inSpeakerNameFadeIn = false
    ---@type number 渐显开始时间
    self._speakerNameFadeInStartTime = 0
    ---@type number 渐显持续时间
    self._speakerNameFadeInDuration = 0
    ---@type Color 颜色动画控制
    self._speakerNameFadeInColor = Color.New(0.3647, 0.3686, 0.4117, 1)
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

    ---@type number 文字显示开始时间
    self._contentStartShowTime = 0
    ---@type string 文字内容
    self._contentStr = ""
    ---@type number 文字数量
    self._wordTotalCount = 0
    ---@type number 当前断点位置
    self._curBreakIndex = 0
    ---@type boolean 是否在文字结束后点击屏幕
    self._endClick = false

    ---@type bool 显示UI
    self._showUI = false
    ---@type bool 隐藏UI
    self._hideUI = false
    --自动对话控制列表
    self._autoBtnList = {}
    ---@type bool 自动结束对话内容
    self._auto = false
    ---@type number 自动结束等待的开始时间
    self._autoWaitStartTime = 0
    ---@type bool 选项或者证据处于显示状态
    self._eventShown = false
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
function N28StoryEntityAVGDialog:SectionStart(trackData)
    N28StoryEntityAVGDialog.super.SectionStart(self, trackData)
    self._speakerGO:SetActive(false)
    if self._currentTrackData.SpeakerNameStr then
        self._isPlayer = self._currentTrackData.SpeakerNameStr == "ui_story_name_you"
        self._speakerNameStr = StringTable.Get(self._currentTrackData.SpeakerNameStr)
        self._speakerNameStr = self:_DoEscape(self._speakerNameStr)
        self._speakerText:SetText(self._speakerNameStr)
        self.txtSpeakerName:SetText(self._speakerNameStr)
    else
        self._speakerText:SetText("")
        self.txtSpeakerName:SetText("")
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
    self._speakerText.color = transparent
    self.txtSpeakerName.color = transparent

    --隐藏结束标识
    self._endFlag:SetActive(false)
    self._inContentEnding = false

    self._endClick = false
    self._autoWaitStartTime = 0
    self._eventShown = false

    self._fullscreenBtn.transform.position = self._storyManager:GetStoryUIRoot().transform.parent.position

    self._forceAutoDialog = self._storyManager:GetCurParagraph().ForceAutoDialog
end

---将UTF8字符串转为table
function N28StoryEntityAVGDialog:_GetContentInfo(str)
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
function N28StoryEntityAVGDialog:_DoEscape(strContent)
    strContent = string.gsub(strContent, "$$", "$")
    local name = GameGlobal.GetModule(RoleModule):GetName()
    if string.isnullorempty(name) then
        name = StringTable.Get("str_guide_moren_name")
    end
    strContent = string.gsub(strContent, "PlayerName", name) -- GameGlobal.GetModule("RoleModule").m_char_info.nick) 不知何时可用
    return strContent
end

---关键帧处理----
---@param keyframeData table
function N28StoryEntityAVGDialog:_TriggerKeyframe(keyframeData)
    --对话框每个小节第一个关键帧显示
    self._dialogUIView:SetShow(true, self)
    if not self._playedIn then
        if self._playAnimationTask then
            GameGlobal.TaskManager():KillTask(self._playAnimationTask)
            self._playAnimationTask = nil
        end
        GameGlobal.UIStateManager():Lock("N28StoryEntityAVGDialog_PlayAnimationIn")
        self._playAnimationTask = GameGlobal.TaskManager():StartTask(
            function(TT)
                self:_SetCanvasGroupAlpha(0)
                self._playedIn = true
                YIELD(TT)
                self._anim:Play("uieff_UIN28AVGStoryDialog_Dialog_in")
                self:_SetCanvasGroupAlpha(1)
                YIELD(TT, 767)
                self._anim:Play("uieff_UIN28AVGStoryDialog_star_01")
                GameGlobal.UIStateManager():UnLock("N28StoryEntityAVGDialog_PlayAnimationIn")
        end, 
        self)
    else
        if not self._anim:IsPlaying("uieff_UIN28AVGStoryDialog_Dialog_in") then
            self._anim:Play("uieff_UIN28AVGStoryDialog_star_01")
        end
    end
    self._showUI = true
    --隐藏功能
    if self._hideUI then
        self._dialogUIView.gameObject:SetActive(false)
    end

    --如果是控制文本底板 直接设置显隐
    if keyframeData.ContentBGVisible ~= nil then
        self._contentBG:SetActive(keyframeData.ContentBGVisible)
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
            self._speakerText.color = self._speakerNameFadeInColor
            self.txtSpeakerName.color = self._speakerNameFadeInColor
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

    -- 创角起名
    if keyframeData.ShowCreateName then
        local roleModule = GameGlobal.GetModule(RoleModule)
        if string.isnullorempty(roleModule:GetName()) then
            GameGlobal.ReportCustomEvent("CreateRole", "SetRoleNameView")
            GameGlobal.UAReportForceGuideEvent("SetNameWindowShow")
        end
    end
    if keyframeData.HideFullScreenBtn ~= nil then
        self._fullscreenBtn:SetActive(not keyframeData.HideFullScreenBtn)
    end
end

---动画处理----
---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function N28StoryEntityAVGDialog:_UpdateAnimation(time)
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
            self.txtSpeakerName:SetText(self._speakerNameStr)
        end
        self._speakerNameFadeInColor.a = alpha
        self._speakerText.color = self._speakerNameFadeInColor
        self.txtSpeakerName.color = self._speakerNameFadeInColor

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
        self.txtSpeakerName:SetText(str)
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
                        self._autoWaitTime =
                            1 +
                            (self._breakIndexList[self._curBreakIndex] - self._breakIndexList[self._curBreakIndex - 1]) *
                                0.075
                    end
                end
            end
        end
        --对话全部显示完
        if self._contentShown then
            --对话显示完
            if self._currentTrackData.Options == nil and self._currentTrackData.Events == nil then
                if time - self._autoWaitStartTime >= self._autoWaitTime then
                    self:_DialogEnd()
                end
            else
                if time - self._autoWaitStartTime >= self._autoWaitOptionTime and not self._eventShown then
                    self:_CheckAVGEvent()
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
            end
        end
        self._optionsFadeInColor.a = alpha

        local colorStr = string.format("%02x", math.floor(alpha * 255))

        for i = 1, self._optionsCount do
            local str =
                string.gsub(
                self._optionsStrList[i],
                self._colorPattern,
                function(s)
                    return s .. colorStr
                end
            )
        end
    end
    if self._contentShown and self._endClick then
        self._dialogUIView:SetShow(false, self)
        self._showUI = false
        return true
    else
        return false
    end
end

---对话结束
function N28StoryEntityAVGDialog:_DialogEnd()
    self._endClick = true
    if self._currentTrackData.VoiceRefID then
        self._storyManager:StopSound(self._currentTrackData.VoiceRefID)
    end
    self._storyManager:AddDialogRecord(
        self._speakerText.text,
        self._contentText.text,
        self._currentTrackData.SpeakerBGColor,
        self._isPlayer
    )
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGOnDialogEnd)
end

---交互部分--------------------
---点击屏幕反馈
function N28StoryEntityAVGDialog:FullScreenBtnOnClick()
    if self._endClick or self._forceAutoDialog or not self._contentStartShow then
        return
    end

    if self._auto then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGStopAutoState)
    end

    if self._contentShown then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundStoryClick)
        self:_CheckAVGEvent()
    else
        if self._inContentTyping then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundStoryClick)
            self._typeClickEnd = true
        else
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundStoryClick)
            self._contentTypeStartTime = self._storyManager:GetCurrentTime()
            self._inContentTyping = true
            self._endFlag:SetActive(false)
        end
    end
end

function N28StoryEntityAVGDialog:SectionEnd()
    N28StoryEntityAVGDialog.super.SectionEnd(self)
    self._endClick = true
end

function N28StoryEntityAVGDialog:_ShowOption()
    if self._currentTrackData.Options == nil then
        self:_DialogEnd()
    else
        self._eventShown = true
        self._inOptionsFadeIn = true
        self._optionsFadeInDuration = self._optionsFadeInTimeConfig
        self._optionsFadeInStartTime = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGShowOption)
    end
end

function N28StoryEntityAVGDialog:_CheckAVGEvent()
    if self._currentTrackData.Events == nil then
        self:_ShowOption()
    else
        self._eventShown = true
        self.curHandleEventidx = 0
        self:DoNextAVGEvent()
    end
end

function N28StoryEntityAVGDialog:DoNextAVGEvent()
    self.curHandleEventidx = self.curHandleEventidx + 1
    local ev = self._currentTrackData.Events[self.curHandleEventidx]
    if ev == nil then
        self:_DialogEnd()
        return
    end
    --处理AVG事件
    local cfg = Cfg.cfg_avg_phase2_event{ID = ev.ID}
    if cfg then
        local event = cfg[1]
        --获取证据
        if event.Type == N28StateAVGEvent.AddEvidence then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGGainEvidence, event, self)
        --删除证据
        elseif event.Type == N28StateAVGEvent.DeleteEvidence then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGGainEvidence, event, self)
        --举证
        elseif event.Type == N28StateAVGEvent.ShowEvidence then
            local trackData = self._currentTrackData.ShowEvidence
            if trackData then
                if not self._anim:IsPlaying("uieff_UIN28AVGStoryDialog_Dialog_out") then
                    if self._playAnimationTask then
                        GameGlobal.TaskManager():KillTask(self._playAnimationTask)
                        self._playAnimationTask = nil
                    end
                    GameGlobal.UIStateManager():Lock("N28StoryEntityAVGDialog_PlayAnimationOut")
                    self._playAnimationTask = GameGlobal.TaskManager():StartTask(
                        function(TT)
                            self._anim:Play("uieff_UIN28AVGStoryDialog_Dialog_out")
                            YIELD(TT, 500)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGShowEvdience, event, trackData, self)
                            --self._dialogUIView:SetShow(false, self)
                            self._playedIn = false
                            GameGlobal.UIStateManager():UnLock("N28StoryEntityAVGDialog_PlayAnimationOut")
                    end, 
                    self)
                end
            else
                Log.error("There is no ShowEvidence data but has event! ", ev.ID)
                self:DoNextAVGEvent()
            end
        --隐藏律师笔记
        elseif event.Type == N28StateAVGEvent.HideEvidenceBook then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGHideEvdienceBook, event, self)
            self:DoNextAVGEvent()
        else
            Log.error("N28StoryEntityAVGDialog error, event type not exist - ", ev.ID, event.Type)
            self:DoNextAVGEvent()
        end
    else
        Log.error("N28StoryEntityAVGDialog error, eventid not exist - ", ev.ID)
        self:DoNextAVGEvent()
    end 
end

---隐藏UI
function N28StoryEntityAVGDialog:HideUI(hide)
    self._hideUI = hide
    self._dialogUIView.gameObject:SetActive(self._showUI and not hide)
end

---设置自动
function N28StoryEntityAVGDialog:SetAuto(auto, id)
    id = id or 0
    self._autoBtnList[id] = auto
    if auto then
        self._auto = auto
    else
        local re = false
        for _, v in pairs(self._autoBtnList) do
            re = re or v
        end
        self._auto = re
    end
    self._autoWaitStartTime = 0
end

function N28StoryEntityAVGDialog:GetAuto(id)
    id = id or 0
    return self._autoBtnList[id]
end

function N28StoryEntityAVGDialog:_SetCanvasGroupAlpha(alpha)
    self._dialogBg.alpha = alpha
    self._dialogLayout.alpha = alpha
end

-- AVG事件类型
--- @class N28StateAVGEvent
local N28StateAVGEvent = {
    AddEvidence = 1,
    DeleteEvidence = 2,
    ShowEvidence = 3,
    HideEvidenceBook = 4
}
_enum("N28StateAVGEvent", N28StateAVGEvent)