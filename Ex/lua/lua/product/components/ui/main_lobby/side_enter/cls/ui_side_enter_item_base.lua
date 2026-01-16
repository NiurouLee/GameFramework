---@class UISideEnterItem_Base:UICustomWidget
_class("UISideEnterItem_Base", UICustomWidget)
UISideEnterItem_Base = UISideEnterItem_Base

---------------------------------------------------------------------------------

-- 设置主要信息
-- 任何时候都需要使用 setShowCallback 设置入口开关
-- 当 new red 发生变化时，调用  setNewRedCallback
function UISideEnterItem_Base:SetMainInfo(mainCfg, btnCfg, clickCallback, setShowCallback, setNewRedCallback)
    ---@type cfg cfg_main_side_enter_edge | cfg_main_side_enter_center
    self._mainCfg = mainCfg
    ---@type cfg_main_side_enter_btn[id]
    self._btnCfg = btnCfg
    -- 点击按钮回调
    self._clickCallback = clickCallback
    -- 设置显示隐藏回调
    self._setShowCallback = setShowCallback
    -- 设置New红点回调
    self._setNewRedCallback = setNewRedCallback
end

-- 侧边栏独立入口，通过 UIMainLobbySideEnterLoader 加载
-- 需要在这里把数据加载好，计算出是否显示的通用逻辑
-- 子类只需实现 self:_CheckOpen(TT)
function UISideEnterItem_Base:OnSideEnterLoad(TT)
    -- 获取活动是否开启
    local isOpen = self:_CheckOpen(TT) and self:_BtnCheckFunc(TT)

    -- 检查活动是否开启，决定是否显示
    if isOpen then
        self._setShowCallback(true)

        self:_CheckPoint()
        self:DoShow()
    end
end

-- 刷新时检查是否开启，决定是否显示
-- function UISideEnterItem_Base:_Refresh()
--     GameGlobal.TaskManager():StartTask(
--         function(TT)
--             self:OnSideEnterLoad(TT)
--         end
--     )
-- end

-- 按钮配置中的检查方法
function UISideEnterItem_Base:_BtnCheckFunc(TT)
    local isOpen = UISideEnterBtnConst.CheckOpen(TT, self._btnCfg)
    return isOpen
end

-- 子类自定义的检查方法
function UISideEnterItem_Base:_CheckOpen(TT)
    Log.exception(self._className .. "必须重写 _CheckOpen() 方法:", debug.traceback())
end

-- 需要提供入口图片
---@return string
function UISideEnterItem_Base:GetSideEnterRawImage()
    Log.exception(self._className .. "必须重写 GetSideEnterRawImage() 方法:", debug.traceback())
end

---------------------------------------------------------------------------------

function UISideEnterItem_Base:DoShow()
    Log.exception(self._className .. "必须重写 DoShow() 方法:", debug.traceback())
end

function UISideEnterItem_Base:_CalcNew()
    Log.exception(self._className .. "必须重写 _CalcNew() 方法:", debug.traceback())
end

function UISideEnterItem_Base:_CalcRed()
    Log.exception(self._className .. "必须重写 _CalcRed() 方法:", debug.traceback())
end

function UISideEnterItem_Base:_CalcHot()
    return self._mainCfg.Hot
end

function UISideEnterItem_Base:_CheckPoint()
    if not self.view then
        return
    end

    local new = self:_CalcNew()
    local red = self:_CalcRed()
    UIWidgetHelper.SetNewAndReds(self, new, red, "new", "red")
    
    local hotCfg = self:_CalcHot()
    if hotCfg ~= nil then
        local hot = (new == 0 or new == false) and (hotCfg == true)
        self:GetGameObject("hot"):SetActive(hot)
    end

    self._setNewRedCallback(new, red) -- 通知 Loader
end

function UISideEnterItem_Base:BtnOnClick(go)
    self._clickCallback()
end