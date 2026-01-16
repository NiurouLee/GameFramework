--[[------------------
    Text剧情元素
--]]------------------

_class("StoryEntityText", StoryEntityMovable)
---@class StoryEntityText:Object
StoryEntityText = StoryEntityText

function StoryEntityText:Constructor(ID, gameObject, resRequest, storyManager)
    StoryEntityText.super.Constructor(self, ID, gameObject, resRequest, storyManager)
    ---@type UILocalizationText
    self._txt = gameObject:GetComponent("UILocalizationText")
    ---@type Color
    self._txtColor = self._txt.color
    ---@type CircleOutline
    self._circleOutline = gameObject:GetComponent("H3D.UGUI.CircleOutline")
    ---@type number StoryEntityType
    self._type = StoryEntityType.Text
    ---@type table<int, StoryEntityTextSeg>
    --self._textSegList = {} 使用新的打字机实现方案
    ---@type number 排除标签之外的字符总数
    self._textTotalCharCount = 0
    ---@type number char/second
    self._typeSpeed = 0
    ---@type boolean
    self._isTyping = false
    ---@type number
    self._typeStartTime = 0
    ---@type number
    self._curCharIndex = 0

    ---@type boolean
    self._active = false
    ---@type boolean
    self._showAsTimer = false
    ---@type string
    self._timerStr = nil
end

---@param keyframeData table
function StoryEntityText:_TriggerKeyframe(keyframeData)
    local languageTypeStr = self._storyManager:GetCurLanguageStr()
    local localizedKeyframeData = keyframeData
    if keyframeData.Languages and keyframeData.Languages[languageTypeStr] then
        localizedKeyframeData = keyframeData.Languages[languageTypeStr]
        --以下为不同语言的共用帧数据 其他数据全部需要配置到国际化配置内
        localizedKeyframeData.Active = keyframeData.Active
        localizedKeyframeData.Layer = keyframeData.Layer
        localizedKeyframeData.Time = keyframeData.Time
        localizedKeyframeData.R = keyframeData.R
        localizedKeyframeData.G = keyframeData.G
        localizedKeyframeData.B = keyframeData.B
        localizedKeyframeData.Alpha = keyframeData.Alpha
        localizedKeyframeData.AlphaChange = keyframeData.AlphaChange
        localizedKeyframeData.ShowAsTimer = keyframeData.ShowAsTimer
    end

    StoryEntityText.super._TriggerKeyframe(self, localizedKeyframeData)

    if localizedKeyframeData.Active ~= nil then
        self._active = localizedKeyframeData.Active
    end

    if localizedKeyframeData.ShowAsTimer then
        self._showAsTimer = true
        self._txt.ShowCharCount = -1
        self._isTyping = false
        self:TriggerTimer()
    end

    if localizedKeyframeData.TypeText and not self._showAsTimer then
        local text = StringTable.Get(localizedKeyframeData.TypeText.TextID)
        local contentStr = self:_DoEscape(text)
        self._txt:SetText(contentStr)
        self._textTotalCharCount = self:_GetContentInfo(contentStr)
        self._txt.ShowCharCount = self._curCharIndex
        --self._textTotalCharCount = self:_ConvertToTextSegList(charList)
        self._typeSpeed = self._textTotalCharCount / localizedKeyframeData.TypeText.Time
        self._typeStartTime = localizedKeyframeData.Time
        self._isTyping = true
    end

    if localizedKeyframeData.FontSize then
        self._txt.fontSize = localizedKeyframeData.FontSize
    end

    if localizedKeyframeData.R then
        self._txtColor.r = localizedKeyframeData.R
        self._txt.color = self._txtColor
    end

    if localizedKeyframeData.G then
        self._txtColor.g = localizedKeyframeData.G
        self._txt.color = self._txtColor
    end

    if localizedKeyframeData.B then
        self._txtColor.b = localizedKeyframeData.B
        self._txt.color = self._txtColor
    end

    --兼容老配置(默认描边生效)
    if keyframeData.OutLine ~= nil then
        self._circleOutline.enabled = keyframeData.OutLine
    else
        self._circleOutline.enabled = true
    end

    if keyframeData.Shadow then
        if not self._shadow then
            self._shadow = gameObject:AddComponent(typeof(UnityEngine.UI.Shadow))
            self._shadowEffectColor = self._shadow.effectColor
        end
        self._shadowEffectColor.r = keyframeData.Shadow.R
        self._shadowEffectColor.g = keyframeData.Shadow.G
        self._shadowEffectColor.b = keyframeData.Shadow.B
        self._shadowEffectColor.a = keyframeData.Shadow.Alpha
        self._shadow.enabled = true
    else
        if self._shadow then
            self._shadow.enabled = false
        end
    end
end

---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function StoryEntityText:_UpdateAnimation(time)
    local res = StoryEntityText.super._UpdateAnimation(self, time)
    
    if self._isTyping then
        local t = time - self._typeStartTime
        local typeCharCount = math.floor(t * self._typeSpeed)

        if typeCharCount > self._textTotalCharCount then 
            typeCharCount = self._textTotalCharCount 
        end

        if typeCharCount > self._curCharIndex then
            self._txt.ShowCharCount = typeCharCount
            self._curCharIndex = typeCharCount
        end

        if self._curCharIndex >= self._textTotalCharCount then
            self._isTyping = false
        end

        return false
    else
        return res
    end
end

---资源销毁
function StoryEntityText:Destroy()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
    end
    
    StoryEntityText.super.Destroy(self)
end

---@触发timer效果
function StoryEntityText:TriggerTimer()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
    end
    
    self._timerHandler = GameGlobal.Timer():AddEventTimes(0, TimerTriggerCount.Infinite,
        function()
            if self._timerStr == nil then
                self._timerStr = "00:00:00:00"
                self._startTime = GameGlobal:GetInstance():GetCurrentTime()
            else
                local timeSpan = GameGlobal:GetInstance():GetCurrentTime() - self._startTime
                self._timerStr = ToTimingFormat4(timeSpan)
            end

            self._txt:SetText(self._timerStr)
        end
    )
end

--[[ 使用新的打字机实现方案
function StoryEntityText:_GetLabeledText(length)
    local str = ""

    for i = 1, #self._textSegList do
        local seg = self._textSegList[i]
        if seg:IsLabel() then
            str = str..seg:GetTotalText()
        elseif length >= seg:Length() then
            str = str..seg:GetTotalText()
            length = length - seg:Length()
        elseif length > 0 then
            str = str..seg:GetText(length)
            length = 0
        end
    end

    return str
end]]

---字符转义
---目前支持如下 $$ -> $ | PlayerName -> 玩家姓名
---@param strContent string
---@return string
function StoryEntityText:_DoEscape(strContent)
    strContent = string.gsub(strContent, "$$", "$")
    local name = GameGlobal.GetModule(RoleModule):GetName()
    if string.isnullorempty(name) then
        name = StringTable.Get("str_guide_moren_name")
    end
    strContent = string.gsub(strContent, "PlayerName", name) -- GameGlobal.GetModule("RoleModule").m_char_info.nick) 不知何时可用
    return strContent
end

---将UTF8字符串转为table
function StoryEntityText:_GetContentInfo(str)
    local plainStr = string.gsub(str, "<size=%d*>", "")
    plainStr = string.gsub(plainStr, "</size>", "")
    plainStr = string.gsub(plainStr, "<color=#%x*>", "")
    plainStr = string.gsub(plainStr, "</color>", "")
    local charCount = 0
    for uchar in string.gmatch(plainStr, "[%z\1-\127\194-\244][\128-\191]*") do
        charCount = charCount + 1
    end
    return charCount
end

--[[ 使用新的打字机实现方案
function StoryEntityText:_ConvertToTextSegList(charList)
    local content = {}
    --是否是<size <color </size </color等标签
    local isLabel = false
    local finishOneSeg = false
    local labelStart = false
    for i = 1, #charList do
        local char = charList[i]
        if isLabel then
            if char == ">" then
                finishOneSeg = true
            end           
        elseif char == "<" then
            if #charList - i > 5 and (
                (charList[i + 1] == "c" and charList[i + 2] == "o" and charList[i + 3] == "l" and charList[i + 4] == "o" and charList[i + 5] == "r" and charList[i + 6] == "=") or
                (charList[i + 1] == "s" and charList[i + 2] == "i" and charList[i + 3] == "z" and charList[i + 4] == "e" and charList[i + 5] == "=") or
                (charList[i + 1] == "/" and charList[i + 2] == "c" and charList[i + 3] == "o" and charList[i + 4] == "l" and charList[i + 5] == "o" and charList[i + 6] == "r") or
                (charList[i + 1] == "/" and charList[i + 2] == "s" and charList[i + 3] == "i" and charList[i + 4] == "z" and charList[i + 5] == "e")
            ) then
                finishOneSeg = true
                labelStart = true
            end
        end

        if finishOneSeg then
            if isLabel then
                content[#content + 1] = char
            end
            self._textSegList[#self._textSegList + 1] = StoryEntityTextSeg:New(content, isLabel)
            
            content = {}
            if not isLabel then
                content[#content + 1] = char
            end

            isLabel = labelStart
            labelStart = false
            finishOneSeg = false
        else            
            content[#content + 1] = char
        end
    end

    if #content > 0 then
        self._textSegList[#self._textSegList + 1] = StoryEntityTextSeg:New(content, false)
    end

    local totalCharCount = 0
    for i = 1, #self._textSegList do
        if not self._textSegList[i]:IsLabel() then
            totalCharCount = totalCharCount + self._textSegList[i]:Length()
        end
    end

    return totalCharCount
end]]

---override----
---透明度设置
---@param alpha number
function StoryEntityText:_SetAlpha(alpha)
    self._txtColor.a = alpha
    self._txt.color = self._txtColor
end
---------------

--[[ 使用新的打字机实现方案
_class("StoryEntityTextSeg", Object)
---@class StoryEntityTextSeg:Object
StoryEntityTextSeg = StoryEntityTextSeg

function StoryEntityTextSeg:Constructor(content, isLabel)
    ---@type number
    self._curStrLength = 0
    ---@type string
    self._curStr = ""
    ---@type table<int, string>
    self._content = content
    ---@type boolean
    self._isLabel = isLabel
end

function StoryEntityTextSeg:Length()
    return #self._content
end

function StoryEntityTextSeg:IsLabel()
    return self._isLabel
end

function StoryEntityTextSeg:GetTotalText()
    if self._curStrLength < #self._content then
        for i = self._curStrLength + 1, #self._content do
            self._curStr = self._curStr..self._content[i]
        end

        self._curStrLength = #self._content
    end

    return self._curStr
end

function StoryEntityTextSeg:GetText(length)
    if length < self._curStrLength then
        self._curStr = ""
        for i = 1, length do
            self._curStr = self._curStr..self._content[i]
        end
    else
        if length > #self._content then
            length = #self._content
        end

        if length == self._curStrLength then
            return self._curStr
        else
            for i = self._curStrLength + 1, length do
                self._curStr = self._curStr..self._content[i]
            end

            self._curStrLength = length
        end
    end
    
    return self._curStr
end]]