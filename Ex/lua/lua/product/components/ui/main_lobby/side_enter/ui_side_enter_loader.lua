---@class UISideEnterLoader:UICustomWidget
_class("UISideEnterLoader", UICustomWidget)
UISideEnterLoader = UISideEnterLoader

--region main

-- 设置数据，加载入口
function UISideEnterLoader:SetData(TT, cfg, hideCallback, redCallback)
    Log.info("UISideEnterLoader:SetData() ID = ", cfg.ID)

    self._mainCfg = cfg -- cfg cfg_main_side_enter_edge | cfg_main_side_enter_center
    local btnKey = cfg.BtnKey
    local btnCfg = UISideEnterConst.GetCfg_SideEnterBtn(btnKey) -- cfg_main_side_enter_btn

    self._hideCallback = hideCallback
    self._redCallback = redCallback

    self:SetShow(false, true) -- 初始设置不触发回调
    self._new, self._red = 0, 0

    local class, prefab = UISideEnterConst.GetCfg_SideEnterBtn_Info(btnKey)
    UIWidgetHelper.ClearWidgets(self, "_sop")
    ---@type UISideEnterItem_Base
    self._obj = UIWidgetHelper.SpawnObject(self, "_sop", class, prefab)
    if not self._obj then
        return
    end
    
    -- 设置 主配置，按钮配置，按键回调，设置显示隐藏回调，设置New红点回调
    local clickCallback = UISideEnterBtnConst.ForceOpenUI(btnCfg)
    self._obj:SetMainInfo(self._mainCfg, btnCfg, clickCallback, 
        function(show) -- setShowCallback
            self:SetShow(show)
        end, 
        function(new, red) -- setNewRedCallback
            self:SetNewRed(new, red)
        end
    )

    -- 按钮加载流程
    self._obj:OnSideEnterLoad(TT)

    -- 获取按钮背景图
    self._rawImage = self._obj:GetSideEnterRawImage()
end

--endregion

--region property

-- 设置是否显示
function UISideEnterLoader:SetShow(show, init)
    local pre = self._show
    self._show = show
    self:GetGameObject():SetActive(show)

    if not init and pre == true and show == false then
        if self._hideCallback then
            self._hideCallback() -- 通知入口关闭
        end
    end
end

-- 获取显示状态
function UISideEnterLoader:GetShow()
    return self._show
end

-- 设置 new 和 red 状态
function UISideEnterLoader:SetNewRed(new, red)
    if self._new ~= new or self._red ~= red then
        if type(new) == "boolean" then
            new = new and 1 or 0
        end
        if type(red) == "boolean" then
            red = red and 1 or 0
        end
        self._new, self._red = new, red
        if self._redCallback then
            self._redCallback() -- 通知 New Red
        end
    end
end

-- 获得 new 和 red 状态
function UISideEnterLoader:GetNewRed()
    Log.info("UISideEnterLoader:GetNewRed() ID = ", self._mainCfg.ID,
        " new = ", self._new,
        " red = ", self._red)
    return self._new, self._red
end

-- 获得入口图片
function UISideEnterLoader:GetSideEnterRawImage()
    Log.info("UISideEnterLoader:GetSideEnterRawImage() ID = ", self._mainCfg.ID, " rawImage = ", self._rawImage)
    return self._rawImage
end

--endregion

function UISideEnterLoader:GetCfg()
    return self._mainCfg
end