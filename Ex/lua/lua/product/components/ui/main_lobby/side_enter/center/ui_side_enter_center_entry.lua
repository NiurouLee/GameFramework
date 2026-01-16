---@class UISideEnterCenterEntry:UICustomWidget
_class("UISideEnterCenterEntry", UICustomWidget)
UISideEnterCenterEntry = UISideEnterCenterEntry

function UISideEnterCenterEntry:OnShow(uiParams)
    self:_AttachEvents()
end

function UISideEnterCenterEntry:OnHide()
    self:_DetachEvents()

    self:_Stop_PlayNewEffect()
end

---------------------------------------------------
-- 侧边栏活动中心入口，通过 UIMainLobbySideEnterLoader 加载
function UISideEnterCenterEntry:SetData(TT)
    self:_LoadDataAndRefresh(TT)
end

function UISideEnterCenterEntry:_Refresh()
    if not self._refreshTaskId then
        self._refreshTaskId = TaskManager:GetInstance():StartTask(self._LoadDataAndRefresh, self)
    end
end

-- 需要在这里把数据加载好，计算出是否显示
function UISideEnterCenterEntry:_LoadDataAndRefresh(TT)
    local lockName = "UISideEnterCenterEntry_LoadDataAndRefresh"
    GameGlobal.UIStateManager():Lock(lockName)

    local cfgList = UISideEnterConst.GetCfgList_SideEnterCenter()
    ---@type UISideEnterLoader[]
    self._showTb = UISideEnterConst.SpawnSideEnterLoader(TT, self, "_centerLoaderPool", cfgList,
        function() -- UISideEnterLoader self._hideCallback
            self:_Refresh()
        end,
        function() -- UISideEnterLoader self._redCallback
            self:_CheckPoint(self._showTb)
        end
    )

    local hide = (#self._showTb == 0)
    self:GetGameObject():SetActive(not hide)
    self:_CheckPoint(self._showTb)

    GameGlobal.UIStateManager():UnLock(lockName)
    self._refreshTaskId = nil
end

--region New Effect
function UISideEnterCenterEntry:_Start_PlayNewEffect()
    if self._playTaskId and self._playTaskId ~= -1 then
        return
    end

    self._playTaskId = TaskManager:GetInstance():StartTask(function(TT)
        if not self.view then
            return
        end

        local isPlay, duration = self:_PlayNewEffect(self._showTb)
        if isPlay then
            YIELD(TT, duration)

            if self.view then -- 关闭动效
                local animName = "uieff_UISideEnterCenter_Entry_newEffect_out"
                local animDuration = 500
                UIWidgetHelper.SetAnimationPlay(self, "_newEffect", animName)
                YIELD(TT, animDuration)
            end

            if self.view then
                self:_SetNewEffectShow(false)
            end
            YIELD(TT, 1000) -- 间歇时间

            self._playTaskId = nil
            if self.view then
                self:_Start_PlayNewEffect()
            end
        else
            self._playTaskId = nil
        end
    end)
end

function UISideEnterCenterEntry:_Stop_PlayNewEffect()
    if self._playTaskId and self._playTaskId ~= -1 then
        GameGlobal.TaskManager():KillTask(self._playTaskId)
        self._playTaskId = nil
    end
end

function UISideEnterCenterEntry:_PlayNewEffect(showTb)
    showTb = showTb or {}

    local obj, cfg, key = self:_CalcNewEffect(showTb)
    if obj then
        Log.debug("UISideEnterCenterEntry:_PlayNewEffect() Play New Effect, key = ", key)
        LocalDB.SetInt(key, 0)

        -- show effect
        local url = obj:GetSideEnterRawImage()
        UIWidgetHelper.SetRawImage(self, "_bg_ne", url)
        self:_SetNewEffectShow(true)

        return true, cfg.duration
    end
    return false
end

function UISideEnterCenterEntry:_GetNewEffectCfg(obj)
    local cfg = obj:GetCfg()
    return cfg.NewEffect
end

function UISideEnterCenterEntry:_GetNewEffectKey(cfg)
    local key = cfg and cfg.key and UIActivityHelper.GetLocalDBKeyWithPstId(cfg.key)
    return key
end

function UISideEnterCenterEntry:_CalcNewEffect(showTb)
    local tb = {}
    
    for _, obj in ipairs(showTb) do
        local n, r = obj:GetNewRed()
        local isNew = (n ~= 0)
        
        local cfg = self:_GetNewEffectCfg(obj)
        local key = self:_GetNewEffectKey(cfg)
        local isRecord = (key == nil) or LocalDB.HasKey(key)

        -- local _debug = true
        -- if _debug then
        --     isNew = true
        --     isRecord = false
        --     cfg = { duration = 3000 }
        --     key = "debug"
        -- end
        if cfg ~= nil and key ~= nil and isNew and not isRecord then
            return obj, cfg, key
        end
    end
end

function UISideEnterCenterEntry:_SetNewEffectShow(show)
    self:GetGameObject("_newEffect"):SetActive(show)
end
--endregion

-- 设置收纳按钮红点
function UISideEnterCenterEntry:_CheckPoint(showTb)
    showTb = showTb or {}

    local new = 0
    local red = 0
    for i = 1, #showTb do
        local n, r = showTb[i]:GetNewRed()
        new = new + n
        red = red + r
    end

    Log.info("UISideEnterCenterEntry:_SetNewRed() new = ", new, " red = ", red)
    UIWidgetHelper.SetNewAndReds(self, new, red, "_new", nil, "_redCount", "_redCountTxt")
end

function UISideEnterCenterEntry:BtnOnClick()
    self:ShowDialog("UISideEnterCenterController")
end

--region AttachEvent

function UISideEnterCenterEntry:_AttachEvents()
    self:AttachEvent(GameEventType.SideEnterRefresh, self._OnSideEnterRefresh)
    self:AttachEvent(GameEventType.AfterUILayerChanged, self._OnAfterUILayerChanged)
    self:AttachEvent(GameEventType.MainLobbyOpenListFinish, self._OnMainLobbyOpenListFinish)
end

function UISideEnterCenterEntry:_DetachEvents()
    self:DetachEvent(GameEventType.SideEnterRefresh, self._OnSideEnterRefresh)
    self:DetachEvent(GameEventType.AfterUILayerChanged, self._OnAfterUILayerChanged)
    self:DetachEvent(GameEventType.MainLobbyOpenListFinish, self._OnMainLobbyOpenListFinish)
end

function UISideEnterCenterEntry:_OnSideEnterRefresh()
    self:_Refresh()
end

function UISideEnterCenterEntry:_OnAfterUILayerChanged()
    self:_CheckPoint(self._showTb)

    self:_SetNewEffectShow(false)
    self:_Stop_PlayNewEffect()
end

function UISideEnterCenterEntry:_OnMainLobbyOpenListFinish()
    self:_Start_PlayNewEffect()
end

--endregion
