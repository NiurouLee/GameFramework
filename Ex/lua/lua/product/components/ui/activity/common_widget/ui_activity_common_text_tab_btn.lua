--[[
    TabBtn 通用的脚本

    使用参考： UIHomelandShopController:_SetTabBtns()
]]
---@class UIActivityCommonTextTabBtn:UICustomWidget
_class("UIActivityCommonTextTabBtn", UICustomWidget)
UIActivityCommonTextTabBtn = UIActivityCommonTextTabBtn

--
function UIActivityCommonTextTabBtn:OnShow()
end

--
---@param index 索引
---@param onoffWidgets 以是否选中为区分的状态 on = 选中 off = 非选中
---@param indexWidgets 以索引为区分的状态
---@param titleWidgets 标题列表组
---@param titleText 标题文字
---@param callback 点击按钮回调
function UIActivityCommonTextTabBtn:SetData(index, onoffWidgets, indexWidgets, titleWidgets, titleText, callback)
    self._index = index

    self._onoffGroup = UIWidgetHelper.GetObjGroupByWidgetName(self, onoffWidgets)

    self._indexGroup = UIWidgetHelper.GetObjGroupByWidgetName(self, indexWidgets)
    UIWidgetHelper.SetObjGroupShow(self._indexGroup, index)

    self:_SetText(titleWidgets, titleText)

    self._callback = callback

    self:SetSelected(false)
end

--
---@param index 索引
---@param indexWidgets 与索引相关的状态组
---@param onoffWidgets 与是否选中相关的状态组 [1] = 选中 [2] = 非选中
---@param lockWidgets 与是否锁定相关的状态组 [1] = 锁定 [2] = 正常
---@param titleWidgets 标题列表组
---@param titleText 标题文字
---@param callback 点击按钮回调
---@param lockCallback 锁定按钮回调
function UIActivityCommonTextTabBtn:SetData(index, params)
    self._index = index

    -- 标题列表组
    self:_SetText(params.titleWidgets or {}, params.titleText or "")

    -- 与索引相关的状态组
    self._indexGroup = UIWidgetHelper.GetObjGroupByWidgetName(self, params.indexWidgets or {})
    UIWidgetHelper.SetObjGroupShow(self._indexGroup, index)

    -- 与是否选中相关的状态组
    self._onoffGroup = UIWidgetHelper.GetObjGroupByWidgetName(self, params.onoffWidgets or {})
    self:SetSelected(false)

    -- 与是否锁定相关的状态组
    self._lockGroup = UIWidgetHelper.GetObjGroupByWidgetName(self, params.lockWidgets or {})
    self:SetLock(false)

    -- 点击按钮回调
    self._callback = params.callback

    -- 锁定按钮回调
    self._lockCallback = params.lockCallback
end

-- 设置是否选中状态
function UIActivityCommonTextTabBtn:SetSelected(isOn)
    UIWidgetHelper.SetObjGroupShow(self._onoffGroup, isOn and 1 or 2)
end

-- 设置是否锁定状态
function UIActivityCommonTextTabBtn:SetLock(isLock)
    self._isLock = isLock
    UIWidgetHelper.SetObjGroupShow(self._lockGroup, isLock and 1 or 2)
end

--
function UIActivityCommonTextTabBtn:_SetText(group, titleText)
    for _, v in ipairs(group) do
        local text = self:GetUIComponent("UILocalizationText", v)
        text:SetText(titleText)
    end
end

-- 默认按钮
function UIActivityCommonTextTabBtn:BtnOnClick(go)
    self:OffBtnOnClick(go)
end

-- 根据状态区分按钮 未选中时
function UIActivityCommonTextTabBtn:OffBtnOnClick(go)
    if self._isLock then
        if self._lockCallback then
            self._lockCallback(self._index)
        end
        return
    end

    if self._callback then
        self._callback(self._index, true)
    end
end

--根据状态区分按钮 选中时
function UIActivityCommonTextTabBtn:OnBtnOnClick(go)
    if self._callback then
        self._callback(self._index, false)
    end
end
