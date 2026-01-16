---@class UIActivityOneAndHalfAnniversarySideEnter:UICustomWidget
_class("UIActivityOneAndHalfAnniversarySideEnter", UICustomWidget)
UIActivityOneAndHalfAnniversarySideEnter = UIActivityOneAndHalfAnniversarySideEnter

---------------------------------------------------
-- 侧边栏通用入口，通过 UIActivitySummonGiftSideEnter 加载
-- 需要在这里把数据加载好，计算出是否显示
-- 任何时候都需要使用 setShowCallback 设置入口开关
-- 当 new red 发生变化时，调用  setNewRedCallback
function UIActivityOneAndHalfAnniversarySideEnter:OnSideEnterLoad(TT, setShowCallback, setNewRedCallback)
    self._setShowCallback = setShowCallback
    self._setNewRedCallback = setNewRedCallback

    self:_Refresh()
end

-- 需要提供入口图片
---@return string
function UIActivityOneAndHalfAnniversarySideEnter:GetSideEnterRawImage()
    return self._sideEnterIcon
end

---------------------------------------------------

-- 调用早于 OnSideEnterLoad
function UIActivityOneAndHalfAnniversarySideEnter:SetData(info, callback, pointCallback)
    self._beginTime = info.BeginTime
    self._endTime = info.EndTime
    self._sideEnterIcon = info.SideEnterIcon
    self._callback = callback
    self._pointCallback = pointCallback

    UIWidgetHelper.SetRawImage(self, "bg", self._sideEnterIcon)
end

---------------------------------------------------

function UIActivityOneAndHalfAnniversarySideEnter:_Refresh()
    -- 检查解锁
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Gamble)

    -- 检查活动是否开启，决定是否显示
    local isOpen = not isLock and UIMainLobbySideEnterFixedTime.CheckOpen(self._beginTime, self._endTime)
    self._setShowCallback(isOpen) -- 通知 Loader

    self:_CheckPoint()
end

function UIActivityOneAndHalfAnniversarySideEnter:BtnOnClick()
    self._callback()
end

--
function UIActivityOneAndHalfAnniversarySideEnter:_CheckPoint()
    -- local new, red = self._pointCallback() -- 不用这个

    --local new, red = self:_CalcPoint()
    UIWidgetHelper.SetNewAndReds(self, 0, 0, "new", "red")

    --self._setNewRedCallback(new, red) -- 通知 Loader
end