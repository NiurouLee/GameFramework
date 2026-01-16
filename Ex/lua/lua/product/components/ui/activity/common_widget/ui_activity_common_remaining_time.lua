---@class UIActivityCommonRemainingTime:UICustomWidget
_class("UIActivityCommonRemainingTime", UICustomWidget)
UIActivityCommonRemainingTime = UIActivityCommonRemainingTime

function UIActivityCommonRemainingTime:_GetComponents()
    ---@type UILocalizationText
    self._txtTime = self:GetUIComponent("UILocalizationText", "txtTime")

    if self._useLocalizedTMP then
        ---@type UILocalizedTMP
        self._txtTime = self:GetUIComponent("UILocalizedTMP", "txtTime")
    end
end

function UIActivityCommonRemainingTime:OnShow()
    self._isOpen = true

    self:SetCustomTimeStr_Common_1()
end

function UIActivityCommonRemainingTime:OnHide()
    self._isOpen = false
    self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end

function UIActivityCommonRemainingTime:Destroy()
    self._matReq = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._matReq)
end

function UIActivityCommonRemainingTime:SetData(endTime, tickCallback, stopCallback)
    self:_GetComponents()

    self._endTime = endTime
    self._tickCallback = tickCallback
    self._stopCallback = stopCallback

    self:_SetTimer()
end

--region set option
---------------------------------------------------
--- 可选项
--- 需要在 SetData 之前设置
---------------------------------------------------

-- 设置文字颜色
-- 显示在 txtTime 中文字的颜色
function UIActivityCommonRemainingTime:SetTimeColor(timeColor)
    self._timeColor = timeColor
end

-- 设置高级文字
-- descId 中包含描述文字和颜色信息，整体显示在 txtTime 中
-- 例如：
-- <color=#ffffff>活动还有</color> <color=#df8e00>{1}</color> <color=#ffffff>结束</color>
function UIActivityCommonRemainingTime:SetAdvanceText(descId)
    self._descId = descId
end

-- 设置额外 text 控件
-- 在 prefab 中制作了额外的文字控件
function UIActivityCommonRemainingTime:SetExtraText(widgetName, textColor, textId)
    widgetName = widgetName or "txtDesc"

    ---@type UILocalizationText
    local txtExtra = self:GetUIComponent("UILocalizationText", widgetName)

    if not string.isnullorempty(textId) then
        self:_SetColorText(txtExtra, textColor, StringTable.Get(textId))
    end
end

-- 设置额外 RollingText 控件
-- 在 prefab 中制作了额外的滚动文字控件
function UIActivityCommonRemainingTime:SetExtraRollingText(widgetName)
    widgetName = widgetName or "txtTime" -- 默认的使用方式，加在 txtTime 控件上
    self._rollingText = self:GetUIComponent("RollingText", widgetName)
end

-- 设置额外 image 控件
-- 在 prefab 中制作了额外的图片控件
function UIActivityCommonRemainingTime:SetExtraSprite(widgetName, sprite)
    widgetName = widgetName or "icon"
    ---@type UnityEngine.UI.Image
    local icon = self:GetUIComponent("Image", widgetName)
    icon.sprite = sprite
end

function UIActivityCommonRemainingTime:SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIActivityCommonRemainingTime:SetText(widgetName, str)
    widgetName = widgetName or "text"

    ---@type UILocalizationText
    local obj = self:GetUIComponent("UILocalizationText", widgetName)
    obj:SetText(str)
end

function UIActivityCommonRemainingTime:SetLocalizedTMPMaterial(matName)
    self._useLocalizedTMP = true
    self._matReq = UIWidgetHelper.SetLocalizedTMPMaterial(self, "txtTime", matName, self._matReq)
end

-- 替换时间字符串
-- 格式参考默认 default_id
-- local default_id = {
--     ["day"] = "str_activity_common_day",
--     ["hour"] = "str_activity_common_hour",
--     ["min"] = "str_activity_common_minute",
--     ["zero"] = "str_activity_common_less_minute",
--     ["over"] = "str_activity_error_107"
-- }
function UIActivityCommonRemainingTime:SetCustomTimeStr(customStr)
    self._customStr = customStr
end

-- 本来 default 是显示 "活动已结束" 的，custom_1 是显示 “小于 1 分钟” 的，不知道谁改 bug 看不懂，直接把这个改了，所以再写个 custom_2
function UIActivityCommonRemainingTime:SetCustomTimeStr_Common_1()
    self:SetCustomTimeStr(
        {
            ["day"] = "str_activity_common_day",
            ["hour"] = "str_activity_common_hour",
            ["min"] = "str_activity_common_minute",
            ["zero"] = "str_activity_common_less_minute",
            ["over"] = "str_activity_error_107" -- 活动已结束
        }
    )
end

function UIActivityCommonRemainingTime:SetCustomTimeStr_Common_2()
    self:SetCustomTimeStr(
        {
            ["day"] = "str_activity_common_day",
            ["hour"] = "str_activity_common_hour",
            ["min"] = "str_activity_common_minute",
            ["zero"] = "str_activity_common_less_minute",
            ["over"] = "str_activity_common_less_minute" -- 超时后还显示小于 1 分钟
        }
    )
end

--endregion

---------------------------------------------------
--region set timer
function UIActivityCommonRemainingTime:_SetTimer()
    self._first = true -- 首次标记

    -- 开启倒计时
    self._timeEvent = UIActivityHelper.StartTimerEvent(
        self._timeEvent,
        function()
            return self:_SetRemainingTimer() -- 返回 stopSign 在首次回调时停止继续创建计时器
        end
    )

    -- 仅在首次设置文字之后刷新 RollingText
    -- 刷新会回到开始状态，如每秒都刷新，会频繁回到开始状态
    if self._rollingText then
        self._rollingText:RefreshText(nil)
    end
end

function UIActivityCommonRemainingTime:_SetRemainingTimer()
    if not self._isOpen then
        return
    end

    --- @type SvrTimeModule
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local endTime = self._endTime
    local stamp = endTime - curTime

    local timeStr = UIActivityHelper.GetFormatTimerStr(stamp, self._customStr)
    self:_SetTimeText(timeStr)

    if self._tickCallback then
        self._tickCallback()
    end

    if stamp <= 0 then
        self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
        if self._stopCallback then
            self._stopCallback(self._first)
        end
        self:_SetTimeText(StringTable.Get(self._customStr["over"]))
        return true -- 返回 stopSign 在首次回调时停止继续创建计时器
    end

    self._first = false
end

--endregion

---------------------------------------------------
--region set text
function UIActivityCommonRemainingTime:_SetTimeText(content)
    if not string.isnullorempty(self._descId) then
        content = StringTable.Get(self._descId, content)
    end
    self:_SetColorText(self._txtTime, self._timeColor, content)
end

function UIActivityCommonRemainingTime:_SetColorText(uiText, colorStr, content)
    local showStr = content

    if not string.isnullorempty(colorStr) then
        local formatStr = "<color=#%s>%s</color>"
        showStr = string.format(formatStr, colorStr, content)
    end

    if uiText then
        uiText:SetText(showStr)
    end
end

--endregion
