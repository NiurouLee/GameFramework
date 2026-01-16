--[[
    活动中心Tab页
]]
---@class UISideEnterCenterTabPage:UICustomWidget
_class("UISideEnterCenterTabPage", UICustomWidget)
UISideEnterCenterTabPage = UISideEnterCenterTabPage

function UISideEnterCenterTabPage:OnShow()
    self._active = true
    self._data = nil
    ---@type UISideEnterCenterContentBase
    self._content = nil
end

function UISideEnterCenterTabPage:OnHide()
    self._active = false    
    self:UnLoadData()
    self:UnLoadContent()
end

---@param cfg cfg_main_side_enter_center
function UISideEnterCenterTabPage:SetData(type, closeCallback, hideUICallback, cfg)
    if self._cfg ~= nil and self._cfg ~= cfg then
        self:UnLoadData()
        self:UnLoadContent()
    end

    self._type = type
    self._closeCallback = closeCallback
    self._hideUICallback = hideUICallback
    self._cfg = cfg
end

function UISideEnterCenterTabPage:LoadData(TT)
    if not self._data then
        local res = AsyncRequestRes:New()
        res:SetSucc(true)

        local cfg = UISideEnterConst.GetCfg_SideEnterContent(self._cfg.ContentKey)
        local dataClass = cfg and cfg.DataClass
        if not string.isnullorempty(dataClass) then
            ---@type UIActivityDataLoaderBase
            local obj = _createInstance(dataClass)
            if obj then
                obj:SetData(self._cfg.ContentParams)
                -- 读取数据
                -- 若活动已关闭，需自行发事件通知自己的入口
                -- 入口自行关闭后会通知活动中心刷新
                self._data = obj:LoadData(TT, res)
            end
        end

        -- 活动关闭以 res 失败为准，返回 false 停止后续切换流程
        if not res:GetSucc() then
            self._data = nil
            Log.info("UISideEnterCenterTabPage:LoadData() failed, cfg_main_side_enter_center id = ", self._cfg.ID)
            return false
        end
    end
    return true
end

function UISideEnterCenterTabPage:UnLoadData()
    self._data = nil
end

function UISideEnterCenterTabPage:LoadContent()
    local info = self._cfg
    if not self._content then
        local class, prefab = UISideEnterConst.GetCfg_SideEnterContent_Info(info.ContentKey, self._type)
        if string.isnullorempty(class) or string.isnullorempty(prefab) then
            return
        end

        self._content = UIWidgetHelper.SpawnObject(self, "_sop", class, prefab)
        self._content:OnInit(self._type, self._closeCallback, self._hideUICallback, self._data, info.ContentParams)
    end
end

function UISideEnterCenterTabPage:UnLoadContent()
    if self._content then
        self._content:DoHide()
        self._content:DoDestroy()
        self._content = nil

        UIWidgetHelper.ClearWidgets(self, "_sop")
    end
end

--- 选中
function UISideEnterCenterTabPage:OnSelect(params)
    params = params or {}
 
    self:LoadContent()
    self._content:DoShow(params)
    if self._cfg.Bgm ~= CriAudioIDConst.BGMMainUI then
        AudioHelperController.PlayBGM(self._cfg.Bgm, AudioConstValue.BGMCrossFadeTime)
    else
        UIBgmHelper.PlayMainBgm()
    end
end

--取消选中
function UISideEnterCenterTabPage:OnDeselect()
    if self._content then
        self._content:DoHide()
    end
end

function UISideEnterCenterTabPage:GetContent()
    return self._content
end
