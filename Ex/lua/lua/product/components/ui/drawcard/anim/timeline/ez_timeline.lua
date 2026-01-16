---@class EZTL_EndTag
local EZTL_EndTag = {
    All = 1,
    Any = 2,
    SomeOne = 3
}
_enum("EZTL_EndTag", EZTL_EndTag)

---@class EZTL_Player:Object 时间线需要有一个地方更新，这里用协程更新
_class("EZTL_Player", Object)
EZTL_Player = EZTL_Player

function EZTL_Player:Constructor()
    ---@type EZTL_Base
    self._tl = nil
    self._stopped = false
end
function EZTL_Player:Play(tl)
    if tl == nil then
        Log.fatal("[EZTL] 时间线为空，不能播放")
        return
    end

    if self._tl and not self._tl:Over() then
        Log.fatal("[EZTL] 当前时间线正在播放，不能打断")
        return
    end

    if not GameGlobal.GetModule(LoginModule):IsLogin() then
        Log.fatal("[EZTL] 客户端已离线，不执行播放")
        return
    end

    self.callback = GameHelper:GetInstance():CreateCallback(EZTL_Player.Stop, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.LoginReset, self.callback)

    self._tl = tl
    self._tl:Start()
    self._stopped = false
    self._taskID = GameGlobal.TaskManager():StartTask(self._Update, self)
end
function EZTL_Player:_Update(TT)
    while not self._stopped and not self._tl:Over() do
        YIELD(TT)
        if not self._stopped then
            local ms = UnityEngine.Time.deltaTime * 1000
            self._tl:Update(ms)
        end
    end

    if self.callback then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.LoginReset, self.callback)
    end
end
function EZTL_Player:Stop()
    if not self._tl:Over() then
        self._tl:Stop()
        self._tl = nil
    end
    self._stopped = true
    
    if self.callback then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.LoginReset, self.callback)
    end
end

function EZTL_Player:IsPlaying()
    if self._tl then
        return not self._tl:Over()
    end
    return false
end

--------------------------------------------

---@class EZTL_Base:Object
_class("EZTL_Base", Object)
EZTL_Base = EZTL_Base
function EZTL_Base:Constructor()
    self._running = false
    self._des = ""
end
function EZTL_Base:Start()
end

function EZTL_Base:StartLog()
    if self._des then
        Log.debug("[EZTL] 开始时间线--->", self._des)
    end
end

function EZTL_Base:EndLog()
    if self._des then
        Log.debug("[EZTL] 结束时间线===>", self._des)
    end
end

function EZTL_Base:Stop()
    self._running = false
    self:EndLog()
end
function EZTL_Base:Update(deltaTimeMS)
end
function EZTL_Base:Over()
    return not self._running
end

---@class EZTL_Sequence:EZTL_Base
_class("EZTL_Sequence", EZTL_Base)
EZTL_Sequence = EZTL_Sequence
function EZTL_Sequence:Constructor(timelines, des)
    self._timelines = timelines
    self._currentIdx = 0
    ---@type EZTL_Base
    self._current = nil
    self._des = des
end
function EZTL_Sequence:Start()
    self:StartLog()
    if not self._timelines or #self._timelines == 0 then
        Log.fatal("[Timeline] sequence time line children is null")
        return
    end
    self._count = #self._timelines
    self._currentIdx = 1
    self._current = self._timelines[1]
    self._current:Start()
    self._running = true
end
function EZTL_Sequence:Update(deltaTimeMS)
    if self._running then
        -- --在上一个timeline结束后下一帧开始下一个timeline
        -- if self._current:Over() then
        --     self._current:Start()
        -- end
        self._current:Update(deltaTimeMS)
        if self._current:Over() then
            self._currentIdx = self._currentIdx + 1
            if self._currentIdx > self._count then
                self:Stop()
            else
                self._current = self._timelines[self._currentIdx]
                --在结束当帧开始下一个timeline
                self._current:Start()
            end
        end
    end
end

function EZTL_Sequence:Stop()
    self._running = false
    for _, tl in ipairs(self._timelines) do
        if not tl:Over() then
            tl:Stop()
        end
    end
    self:EndLog()
end

---@class EZTL_Parallel:EZTL_Base
_class("EZTL_Parallel", EZTL_Base)
EZTL_Parallel = EZTL_Parallel
function EZTL_Parallel:Constructor(timelines, endTag, endOne, des)
    self._timelines = timelines
    self._endTag = endTag or EZTL_EndTag.All
    self._endOne = endOne
    self._des = des

    self._endFunc = nil
    self._endFlag = false
    if self._endTag == EZTL_EndTag.All then
        self._endFlag = true
        self._endFunc = function(_end1, _end2)
            return _end1 and _end2
        end
    elseif self._endTag == EZTL_EndTag.Any then
        self._endFlag = false
        self._endFunc = function(_end1, _end2)
            return _end1 or _end2
        end
    elseif self._endTag == EZTL_EndTag.SomeOne then
        self._targetOne = self._timelines[self._endOne]
        self._endFunc = function(_end1, _end2)
            return self._targetOne:Over()
        end
    else
        Log.fatal("[Timeline] Parallel timeline tag error：", self._endTag)
    end
end
function EZTL_Parallel:Start()
    self:StartLog()
    if not self._timelines or #self._timelines == 0 then
        Log.fatal("[Timeline] parallel time line children is null")
        return
    end
    for _, tl in ipairs(self._timelines) do
        tl:Start()
    end
    self._running = true
end
function EZTL_Parallel:Update(deltaTimeMS)
    if self._running then
        local _over = self._endFlag
        for _, tl in ipairs(self._timelines) do
            tl:Update(deltaTimeMS)
            _over = self._endFunc(_over, tl:Over())
        end
        if _over then
            self:Stop()
        end
    end
end

function EZTL_Parallel:Stop()
    self._running = false
    for _, tl in ipairs(self._timelines) do
        if not tl:Over() then
            tl:Stop()
        end
    end
    self:EndLog()
end

---@class EZTL_Wait:EZTL_Base
_class("EZTL_Wait", EZTL_Base)
EZTL_Wait = EZTL_Wait
function EZTL_Wait:Constructor(_time, des)
    self._delayTimeMS = _time
    self._timer = 0
    self._des = des
end
function EZTL_Wait:Start()
    self:StartLog()
    if self._delayTimeMS <= 0 then
        self:Stop()
        return
    end
    self._timer = 0
    self._running = true
end
function EZTL_Wait:Update(deltaTimeMS)
    if self._running then
        self._timer = self._timer + deltaTimeMS
        if self._timer >= self._delayTimeMS then
            self:Stop()
        end
    end
end

---@class EZTL_Callback:EZTL_Base
_class("EZTL_Callback", EZTL_Base)
EZTL_Callback = EZTL_Callback
function EZTL_Callback:Constructor(cb, des)
    self._callback = cb
    self._des = des
end
function EZTL_Callback:Start()
    self:StartLog()
    self._callback()
    self:Stop()
end
-------------------------------------------------------
---@class EZTL_DOTweenMove:EZTL_Base
_class("EZTL_DOTweenMove", EZTL_Base)
EZTL_DOTweenMove = EZTL_DOTweenMove
function EZTL_DOTweenMove:Constructor(transform, endPos, duaration, ease, des)
    self.transform = transform
    self.endPos = endPos
    self.duaration = duaration
    self.ease = ease
    self._des = des
end

function EZTL_DOTweenMove:Start()
    self:StartLog()
    ---@type DG.Tweening.Tween
    self._tweener =
        self.transform:DOMove(self.endPos, self.duaration):SetEase(self.ease):OnComplete(
        function()
            self:Stop()
        end
    )
    self._running = true
end

function EZTL_DOTweenMove:Stop()
    self._running = false
    if self._tweener:IsPlaying() then
        self._tweener:Kill()
    end
    self:EndLog()
end

-------------------------------------------------------
---@class EZTL_DOTweenRotate:EZTL_Base
_class("EZTL_DOTweenRotate", EZTL_Base)
EZTL_DOTweenRotate = EZTL_DOTweenRotate
function EZTL_DOTweenRotate:Constructor(transform, endRot, duaration, ease, des)
    self.transform = transform
    self.endPos = endRot
    self.duaration = duaration
    self.ease = ease
    self._des = des
end

function EZTL_DOTweenRotate:Start()
    self:StartLog()
    ---@type DG.Tweening.Tween
    self._tweener =
        self.transform:DORotate(self.endPos, self.duaration, DG.Tweening.RotateMode.Fast):SetEase(self.ease):OnComplete(
        function()
            self:Stop()
        end
    )
    self._running = true
end

function EZTL_DOTweenRotate:Stop()
    self._running = false
    if self._tweener:IsPlaying() then
        self._tweener:Kill()
    end
    self:EndLog()
end

----------------------------------------------------------------
---@class EZTL_PlayAnimation:EZTL_Base
_class("EZTL_PlayAnimation", EZTL_Base)
EZTL_PlayAnimation = EZTL_PlayAnimation
function EZTL_PlayAnimation:Constructor(animation, name, des)
    ---@type UnityEngine.Animation
    self._anim = animation
    self._name = name
    self._des = des
end

function EZTL_PlayAnimation:Start()
    self:StartLog()
    self._duaration = 0
    self._timer = 0
    if not self._anim then
        Log.fatal("[EZTL] Animation 组件为空，不能播放")
        return
    end
    if not self._name then
        Log.fatal("[EZTL] Animation 名称为空，不能播放")
        return
    end
    ---@type UnityEngine.AnimationClip
    local clip = self._anim:GetClip(self._name)
    if not clip then
        Log.fatal("[EZTL] 找不到AnimationClip: ", self._name)
        return
    end
    self._duaration = clip.length * 1000
    self._anim:Play(self._name)
    self._running = true
end

function EZTL_PlayAnimation:Update(deltaTimeMS)
    self._timer = self._timer + deltaTimeMS
    if self._timer >= self._duaration then
        self:Stop()
    end
end

function EZTL_PlayAnimation:Stop()
    if self._running then
        self._anim:Stop()
        self._running = false
    end
    self:EndLog()
end

----------------------------------------------------------------
--[[
    材质颜色
]]
---@class EZTL_MatColor:EZTL_Base
_class("EZTL_MatColor", EZTL_Base)
EZTL_MatColor = EZTL_MatColor
function EZTL_MatColor:Constructor(mat, propertyName, fromColor, toColor, duaration, des)
    ---@type UnityEngine.Material
    self._mat = mat
    self._propertyName = propertyName
    self._fromColor = fromColor
    self._toColor = toColor
    self._duaration = duaration
    self._des = des
end

function EZTL_MatColor:_setColor(color)
    self._mat:SetColor(self._propertyName, color)
end

function EZTL_MatColor:Start()
    self:_setColor(self._fromColor)
    self._timer = 0
    self._running = true
end

function EZTL_MatColor:Update(deltaTimeMS)
    if self._running then
        if self._timer > self._duaration then
            self:_setColor(self._toColor)
            self:Stop()
        else
            self._timer = self._timer + deltaTimeMS
            self:_setColor(Color.Lerp(self._fromColor, self._toColor, self._timer / self._duaration))
        end
    end
end
----------------------------------------------------------------
--[[
    材质参数
]]
---@class EZTL_MatFloat:EZTL_Base
_class("EZTL_MatFloat", EZTL_Base)
EZTL_MatFloat = EZTL_MatFloat
function EZTL_MatFloat:Constructor(mat, propertyName, to, duaration, des)
    ---@type UnityEngine.Material
    self._mat = mat
    self._propertyName = propertyName
    self._from = mat:GetFloat(propertyName)
    self._to = to
    self._duaration = duaration
    self._des = des
end

function EZTL_MatFloat:_setValue(value)
    self._mat:SetFloat(self._propertyName, value)
end

function EZTL_MatFloat:Start()
    self._timer = 0
    self._running = true
    self:StartLog()
end

function EZTL_MatFloat:Update(deltaTimeMS)
    if self._running then
        if self._timer > self._duaration then
            self:_setValue(self._to)
            self._running = false
            self:Stop()
        else
            self._timer = self._timer + deltaTimeMS
            self:_setValue(Mathf.Lerp(self._from, self._to, self._timer / self._duaration))
        end
    end
end

function EZTL_MatFloat:Stop()
    if self._running then
        self._running = false
    end
    self:EndLog()
end

---------------------------------------------------------
---@class EZTL_PlayEffect:EZTL_Base
_class("EZTL_PlayEffect", EZTL_Base)
EZTL_PlayEffect = EZTL_PlayEffect
function EZTL_PlayEffect:Constructor(gameObject, duaration, des)
    ---@type UnityEngine.GameObject
    self.eft = gameObject
    self.duaration = duaration

    self._timer = 0
end

function EZTL_PlayEffect:Start()
    self._timer = 0
    self.eft:SetActive(true)
    self._running = true

    self:StartLog()

    --没有时长，直接结束
    if self.duaration == nil then
        self._running = false
        self:EndLog()
    end
end
function EZTL_PlayEffect:Update(deltaTimeMS)
    if not self._running then
        return
    end

    if self.duaration then
        self._timer = self._timer + deltaTimeMS
        if self._timer > self.duaration then
            self:Stop()
        end
    end
end
function EZTL_PlayEffect:Stop()
    self._running = false
    self.eft:SetActive(false)
    self:EndLog()
end

--------------------------------------------------------------------
---@class EZTL_PlayAudioOnce:EZTL_Base  播音频一次，只能播已经缓存过的，不负责停止，不循环
_class("EZTL_PlayAudioOnce", EZTL_Base)
EZTL_PlayAudioOnce = EZTL_PlayAudioOnce
function EZTL_PlayAudioOnce:Constructor(audioName, des)
    self.audio = audioName
    self._des = des
end
function EZTL_PlayAudioOnce:Start()
    AudioHelperController.PlayUISoundResource(self.audio, false)
    self._running = false
    self:StartLog()
end
--------------------------------------------------------------------
---@class EZTL_PlayAudioByID:EZTL_Base  按id播音频一次，只能播已经缓存过的，不负责停止，不循环，可设置延迟
_class("EZTL_PlayAudioByID", EZTL_Base)
EZTL_PlayAudioByID = EZTL_PlayAudioByID
function EZTL_PlayAudioByID:Constructor(audioID, delayTime, des)
    self.audio = audioID
    self._des = des
    if delayTime and delayTime > 0 then
        self._delayTime = delayTime
    end
end
function EZTL_PlayAudioByID:Start()
    if self._delayTime then
        self._timer = 0
        self._running = true
    else
        AudioHelperController.RequestAndPlayUIVoiceAutoRelease(self.audio)
        self._running = false
    end
    self:StartLog()
end
function EZTL_PlayAudioByID:Update(deltaTimeMS)
    if self._running then
        self._timer = self._timer + deltaTimeMS
        if self._timer > self._delayTime then
            AudioHelperController.RequestAndPlayUIVoiceAutoRelease(self.audio)
            self._running = false
            self:Stop()
        end
    end
end
function EZTL_PlayAudioByID:Stop()
    if self._running then
        self._running = false
    end
    self:EndLog()
end
--------------------------------------------------------------------
---@class EZTL_TweenSliderValue:EZTL_Base
_class("EZTL_TweenSliderValue", EZTL_Base)
EZTL_TweenSliderValue = EZTL_TweenSliderValue

function EZTL_TweenSliderValue:Constructor(slider, from, to, duration, des)
    self._slider = slider
    self._from = from
    self._to = to
    self._duration = duration
    self._des = des
end

function EZTL_TweenSliderValue:Start()
    self:StartLog()
    self._slider.value = self._from
    ---@type DG.Tweening.Tween
    self._tweener =
        self._slider:DOValue(self._to, self._duration, false):SetEase(DG.Tweening.Ease.Linear):OnComplete(
        function()
            self._running = false
            self:Stop()
        end
    )
    self._running = true
end
function EZTL_TweenSliderValue:Stop()
    if self._running then
        self._running = false
        if self._tweener:IsPlaying() then
            self._tweener:Kill()
        end
    end
    self:EndLog()
end

----------------------------------------------------------------------------------
---@class EZTL_TextUpAnim:EZTL_Base
_class("EZTL_TextUpAnim", EZTL_Base)
EZTL_TextUpAnim = EZTL_TextUpAnim
function EZTL_TextUpAnim:Constructor(text, from, to, duration, des)
    self._text = text
    self._from = from
    self._to = to
    self._duration = duration
    self._des = des

    self._timer = 0
end
function EZTL_TextUpAnim:Start()
    self._text:SetText(self._from)
    -- if self._from >= self._to then
    --     return
    -- end
    self._running = true
    self._timer = 0
end
function EZTL_TextUpAnim:Update(deltaTimeMS)
    if self._running then
        if self._timer < self._duration then
            local cur = math.ceil(self._from + (self._to - self._from) * (self._timer / self._duration))
            self._text:SetText(cur)
            self._timer = self._timer + deltaTimeMS
        else
            self._running = false
            self:Stop()
        end
    end
end
function EZTL_TextUpAnim:Stop()
    if self._running then
        self._running = false
        self._timer = 0
    end
    self._text:SetText(self._to)
    self:EndLog()
end
----------------------------------------------------------------------------------
--[[
    文本随机滚动，只能处理英文字母
]]
---@class EZTL_RandomText:EZTL_Base
_class("EZTL_RandomText", EZTL_Base)
EZTL_RandomText = EZTL_RandomText

function EZTL_RandomText:Constructor(text, content, duration, des)
    ---@type UILocalizationText
    self._text = text
    self._duration = duration
    self._content = content
    self._des = des
    self._childS = string.split(self._content, " ")

    self._charLib = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"
    self._libLen = #self._charLib
end

function EZTL_RandomText:Start()
    self._running = true
    self._timer = 0
    self._text:SetText(self:_random())
    self:StartLog()
end

function EZTL_RandomText:_random()
    local s = ""
    for i = 1, #self._childS do
        local child = self._childS[i]
        local c = {}
        for j = 1, #child do
            local idx = math.random(1, self._libLen)
            local code = string.byte(self._charLib, idx)
            c[#c + 1] = code
        end
        s = s .. string.char(table.unpack(c))
        if i < #self._childS then
            s = s .. " "
        end
    end
    return s
end

function EZTL_RandomText:Update(deltaTimeMS)
    if self._running then
        self._timer = self._timer + deltaTimeMS
        if self._timer > self._duration then
            self._running = false
            self:Stop()
            return
        end
        self._text:SetText(self:_random())
    end
end

function EZTL_RandomText:Stop()
    if self._running then
        self._running = false
    end
    self._text:SetText(self._content)
    self:EndLog()
end
------------------------------------------------------------------------
--[[
    ui透明度变换
]]
---@class EZTL_AlphaTween:EZTL_Base
_class("EZTL_AlphaTween", EZTL_Base)
EZTL_AlphaTween = EZTL_AlphaTween
function EZTL_AlphaTween:Constructor(graphic, target, duration, des)
    ---@type UnityEngine.UI.Graphic
    self._graphic = graphic
    self._duration = duration
    self._target = target
    self._des = des
end
function EZTL_AlphaTween:Start()
    self._running = true
    self._timer = 0
    local color = self._graphic.color
    self._r = color.r
    self._g = color.g
    self._b = color.b
    self._from = color.a
    self:StartLog()
end
function EZTL_AlphaTween:Update(deltaTimeMS)
    if self._running then
        self._timer = self._timer + deltaTimeMS
        if self._timer > self._duration then
            self._running = false
            self:Stop()
            return
        end
        local alpha = Mathf.Lerp(self._from, self._target, self._timer / self._duration)
        self._graphic.color = Color(self._r, self._g, self._b, alpha)
    end
end
function EZTL_AlphaTween:Stop()
    if self._running then
        self._running = false
    else
        self._graphic.color = Color(self._r, self._g, self._b, self._target)
    end
    self:EndLog()
end

---------------------------------------------------
--[[

]]
---@class EZTL_AnchorMove:EZTL_Base
_class("EZTL_AnchorMove", EZTL_Base)
EZTL_AnchorMove = EZTL_AnchorMove
function EZTL_AnchorMove:Constructor(rect, target, duration, des)
    ---@type UnityEngine.RectTransform
    self._rect = rect
    self._target = target
    self._duration = duration
    self._des = des
end
function EZTL_AnchorMove:Start()
    self._timer = 0
    self._from = self._rect.anchoredPosition
    self._running = true
    self:StartLog()
end

function EZTL_AnchorMove:Update(dt)
    if self._running then
        self._timer = self._timer + dt
        if self._timer > self._duration then
            self._running = false
            self:Stop()
        else
            self._rect.anchoredPosition = Vector2.Lerp(self._from, self._target, self._timer / self._duration)
        end
    end
end

function EZTL_AnchorMove:Stop()
    if self._running then
        self._running = false
    end
    self._rect.anchoredPosition = self._target
    self:EndLog()
end

---------------------------------------------------------------------------
---@class EZTL_TextUpAnimFormat:EZTL_Base
_class("EZTL_TextUpAnimFormat", EZTL_Base)
EZTL_TextUpAnimFormat = EZTL_TextUpAnimFormat
function EZTL_TextUpAnimFormat:Constructor(text, from, to, duration, format, des)
    self._text = text
    self._from = from
    self._to = to
    self._duration = duration
    self._format = format
    self._des = des

    self._timer = 0
end
function EZTL_TextUpAnimFormat:Start()
    self._text:SetText(string.format(self._format, self._from))
    -- if self._from >= self._to then
    --     return
    -- end
    self._running = true
    self._timer = 0
end
function EZTL_TextUpAnimFormat:Update(deltaTimeMS)
    if self._running then
        if self._timer < self._duration then
            local cur = math.ceil(self._from + (self._to - self._from) * (self._timer / self._duration))
            self._text:SetText(string.format(self._format, cur))
            self._timer = self._timer + deltaTimeMS
        else
            self._running = false
            self:Stop()
        end
    end
end
function EZTL_TextUpAnimFormat:Stop()
    if self._running then
        self._running = false
        self._timer = 0
    end
    self._text:SetText(string.format(self._format, self._to))
    self:EndLog()
end
