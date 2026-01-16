--[[
    活动中心Tab页内容父类
]]
---@class UISideEnterCenterContentBase: UICustomWidget
_class("UISideEnterCenterContentBase", UICustomWidget)
UISideEnterCenterContentBase = UISideEnterCenterContentBase

--- @class ESideEnterContentType
local ESideEnterContentType = {
    Single = 1, -- 独立内容
    Center = 2  -- 标签页内容
}
_enum("ESideEnterContentType", ESideEnterContentType)

--初始化，只会调用一次，不需要子类重写
---@param type ESideEnterContentType
---@param closeCallback function 关闭时通知父窗口
---@param data 请求的数据
---@param params table 传入内容的参数
function UISideEnterCenterContentBase:OnInit(type, closeCallback, hideUICallback, data, params)
    --考虑逻辑复用
    self._type = type
    self._closeCallback = closeCallback
    self._hideUICallback = hideUICallback
    self._data = data
    self:DoInit(params)
end

-- 关闭时调用，通知父窗口处理
function UISideEnterCenterContentBase:CloseDialog(isPlayer)
    if isPlayer and self._type == ESideEnterContentType.Center then
        return
    end

    if self._closeCallback then
        self._closeCallback()
    end
end

-- 通知活动中心，隐藏返回按钮和活动按钮列表
function UISideEnterCenterContentBase:SetCenterUIHide(hide)
    if self._hideUICallback then
        self._hideUICallback(hide)
    end
end

function UISideEnterCenterContentBase:IsEnableUpdate()
    return self._enableUpdate
end

function UISideEnterCenterContentBase:EnableUpdate(enableUpdate)
    self._enableUpdate = enableUpdate
end

--region 必须重写的虚方法
--只会调用一次，做一些加载控件的工作
function UISideEnterCenterContentBase:DoInit()
    Log.exception(self._className .. "必须重写DoInit()方法:", debug.traceback())
end

--显示
function UISideEnterCenterContentBase:DoShow()
    Log.exception(self._className .. "必须重写OnShow()方法:", debug.traceback())
end

--显示其他Tab之前,隐藏
function UISideEnterCenterContentBase:DoHide()
    Log.exception(self._className .. "必须重写OnHide()方法:", debug.traceback())
end

--关闭界面,销毁Tab
function UISideEnterCenterContentBase:DoDestroy()
    Log.exception(self._className .. "必须重写OnDestroy()方法:", debug.traceback())
end

function UISideEnterCenterContentBase:DoUpdate(deltaTimeMS)

end

--endregion
