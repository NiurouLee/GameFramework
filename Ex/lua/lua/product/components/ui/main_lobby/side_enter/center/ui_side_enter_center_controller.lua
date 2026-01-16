---@class UISideEnterCenterController:UIController
_class("UISideEnterCenterController", UIController)
UISideEnterCenterController = UISideEnterCenterController

function UISideEnterCenterController:_SetCommonTopButton()
    ---@type UICommonTopButton
    local obj = UIWidgetHelper.SpawnObject(self, "_backBtns", "UICommonTopButton")
    obj:SetData(
        function()
            self:_BackFunc()
        end,
        nil,
        nil,
        true
    )
end

function UISideEnterCenterController:_BackFunc()
    if self:Manager():CurUIStateType() == UIStateType.UISideEnterCenter then
        self:SwitchState(UIStateType.UIMain)
    else
        self:_Shot(
            function()
                UIWidgetHelper.PlayAnimation(self, "_anim", "uieff_UISideEnterCenterController_out", 333,
                    function()
                        UIBgmHelper.PlayMainBgm()
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.SideEnterRefresh)
                        self:CloseDialog()
                    end
                )
            end
        )
    end
end

function UISideEnterCenterController:LoadDataOnEnter(TT, res, uiParams)
    self:_LoadData(TT, res, uiParams)
end

function UISideEnterCenterController:OnShow(uiParams)
    self._active = true
    self:AddListener()

    self:_SetCommonTopButton()

    -- 设置选中标签页
    local gridTransform = self:GetUIComponent("RectTransform", "_tabBtns")
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(gridTransform)
    self:_SetTabSelect_OnShow(self._firstPageIndex, self._firstPageParams)
end

function UISideEnterCenterController:OnHide()
    self:DetachListener()

    ---@type DG.Tweening.Tweener
    if self._playerTweener then
        self._playerTweener:Kill()
        self._playerTweener = nil
    end
    self._active = false
end

function UISideEnterCenterController:OnUpdate(deltaTimeMS)
    local content = nil
    local tabPage = self._tabPages[self._tabIndex]
    if tabPage ~= nil then
        content = tabPage:GetContent()
    end

    if content and content:IsEnableUpdate() then
        content:DoUpdate(deltaTimeMS)
    end
end

function UISideEnterCenterController:_CalcCenterParams(uiParams)
    local tb = uiParams and uiParams[1] or {}
    self._singleMode = tb.single_mode or false
end

function UISideEnterCenterController:_CalcFirstTab(uiParams)
    local tb = uiParams and uiParams[1] or {}
    for i, v in ipairs(self._showTb) do
        local cfg = v._mainCfg -- cfg_main_side_enter_center
        local contentParams = cfg and cfg.ContentParams

        if tb.campaign_id then
            if tb.campaign_id == contentParams.campaign_id then
                return i, tb.params
            end
        elseif tb.campaign_type then
            if tb.campaign_type == contentParams.campaign_type then
                return i, tb.params
            end
        end
    end
end

function UISideEnterCenterController:_CalcPreLoadPages()
    return { self._firstPageIndex }
end

function UISideEnterCenterController:_LoadData(TT, res, uiParams)
    local lockName = "UISideEnterCenterController_LoadData"
    GameGlobal.UIStateManager():Lock(lockName)

    local campModule = self:GetModule(CampaignModule)
    campModule:LoadCampaignInfoListTask(TT) -- 拉取活动列表

    self:_LoadTabBtnData(TT)

    self:_CalcCenterParams(uiParams)                                           -- 计算传入参数
    self._firstPageIndex, self._firstPageParams = self:_CalcFirstTab(uiParams) -- 计算首先要显示的页面
    if self._singleMode and self._firstPageIndex == nil then
        res:SetSucc(false)
        ToastManager.ShowToast(StringTable.Get("str_activity_error_109"))
        Log.error("UISideEnterCenterController:_LoadData() single mode and first page is nil, 活动中心 单窗口模式 传入参数找不到要显示的页签")
        GameGlobal.UIStateManager():UnLock(lockName)
        return false
    end
    self._firstPageIndex = self._firstPageIndex or 1

    self:_SetSingleMode(self._singleMode)

    self:_SetTabBtns(self._showTb)
    self:_SetTabPages(self._showTb)

    if #self._showTb == 0 then
        Log.error("UISideEnterCenterController:_LoadData() tab count == 0, 活动中心没有可显示的内容")
        if res then                                                               -- 打开窗口时
            res:SetSucc(false)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.SideEnterRefresh) -- 传给活动中心入口
            ToastManager.ShowToast(StringTable.Get("str_activity_error_109"))
        else                                                                      -- 刷新窗口时
            self:_BackFunc()
        end
        GameGlobal.UIStateManager():UnLock(lockName)
        return false
    end

    -- 预加载页面内容
    local preLoadPages = self:_CalcPreLoadPages()
    for _, v in ipairs(preLoadPages) do
        self:_LoadTabPageData(TT, v)
    end

    GameGlobal.UIStateManager():UnLock(lockName)
    return true
end

-- 根据配置加载入口
function UISideEnterCenterController:_LoadDataAndRefresh()
    if self._refreshTaskId and self._refreshTaskId ~= -1 then
        return
    end

    if self._transitionMask == nil then
        self._transitionMask = self:GetUIComponent("CanvasGroup", "transitionMask")
    end

    local lockName = "UISideEnterCenterController:_LoadDataAndRefresh()"
    GameGlobal.UIStateManager():Lock(lockName)

    self._refreshTaskId = TaskManager:GetInstance():StartTask(
        function(TT)
            self:_TransitionMask(TT, 0, 1, true, 100)

            self:_SwitchTabPage(TT, 0) -- 清空选择

            if not self:_LoadData(TT) then
                GameGlobal.UIStateManager():UnLock(lockName)
                self._refreshTaskId = nil
                return
            end

            local index = 1 -- 由于活动关闭造成页签减少时，刷新后显示的页签
            self:_SwitchTabPage(TT, index)
            self:_SwitchTabBtn(index)

            self:_TransitionMask(TT, 1, 0, false, 100)

            GameGlobal.UIStateManager():UnLock(lockName)
            self._refreshTaskId = nil
        end
    )
end

function UISideEnterCenterController:_TransitionMask(TT, alphaBegin, alphaEnd, visibleEnd, transLen)
    local transTick = 0
    local transAlpha = alphaBegin
    local speed = (alphaEnd - alphaBegin) / transLen
    local instGameGlobal = GameGlobal:GetInstance()

    self._transitionMask.gameObject:SetActive(true)
    self._transitionMask.alpha = transAlpha
    while (transTick < transLen) do
        local deltaTime = instGameGlobal:GetDeltaTime()
        transTick = transTick + deltaTime
        transAlpha = transAlpha + deltaTime * speed
        transAlpha = math.max(transAlpha, 0)
        transAlpha = math.min(transAlpha, 1)
        self._transitionMask.alpha = transAlpha
        YIELD(TT)
    end

    self._transitionMask.gameObject:SetActive(visibleEnd)
end

function UISideEnterCenterController:_LoadTabBtnData(TT)
    local cfgList = UISideEnterConst.GetCfgList_SideEnterCenter()
    ---@type UISideEnterLoader[]
    self._showTb = UISideEnterConst.SpawnSideEnterLoader(TT, self, "_centerLoaderPool", cfgList,
        function() -- UISideEnterLoader self._hideCallback
            self:_LoadDataAndRefresh()
        end,
        function() -- UISideEnterLoader self._redCallback
        end
    )
end

function UISideEnterCenterController:_LoadTabPageData(TT, index)
    if index and self._tabPages[index] then
        return self._tabPages[index]:LoadData(TT)
    end
    return true
end

function UISideEnterCenterController:_SetSingleMode(singleMode)
    self:GetGameObject("ScrollView"):SetActive(not singleMode)
end

function UISideEnterCenterController:_SetHideUIMode(hide)
    self:GetGameObject("_backBtns"):SetActive(not hide)
    if not self._singleMode then
        self:GetGameObject("ScrollView"):SetActive(not hide)
    end
end

--region TabBtn TabPage
-- 设置 tab btn
function UISideEnterCenterController:_SetTabBtns(showTb)
    ---@type UIActivityCommonTextTabBtn[]
    self._tabBtns = UIWidgetHelper.SpawnObjects(self, "_tabBtns", "UIActivityCommonTextTabBtn", #showTb)
    for i, v in ipairs(self._tabBtns) do
        v:SetData(
            i,                                                -- 索引
            {
                indexWidgets = {},                            -- 与索引相关的状态组
                onoffWidgets = { { "OnBtn" }, { "OffBtn" } }, -- 与是否选中相关的状态组 [1] = 选中 [2] = 非选中
                lockWidgets = {},                             --- 与是否锁定相关的状态组 [1] = 锁定 [2] = 正常
                titleWidgets = {},                            -- 标题列表组
                titleText = "",                               -- 标题文字
                callback = function(index, isOffBtnClick)     -- 点击按钮回调
                    if isOffBtnClick then
                        self:_SetTabSelect(index)
                    end
                end
            }
        )
    end
end

-- 设置 tab page
function UISideEnterCenterController:_SetTabPages(showTb)
    ---@type UISideEnterCenterTabPage[]
    self._tabPages = UIWidgetHelper.SpawnObjects(self, "_tabPages", "UISideEnterCenterTabPage", #showTb)
    for i, v in ipairs(self._tabPages) do
        v:SetData(ESideEnterContentType.Center, -- 设置成 TabPage 模式
            function()                          -- UISideEnterCenterContentBase._closeCallback
                -- self:_LoadDataAndRefresh() --不在这里刷新，以活动入口的活动关闭事件为准，不使用内容页的关闭事件
            end,
            function(hide) -- UISideEnterCenterContentBase._hideUICallback
                self:_SetHideUIMode(hide)
            end,
            showTb[i]._mainCfg
        )
    end
end

-- 首次刷新 tab
function UISideEnterCenterController:_SetTabSelect_OnShow(index, params)
    self._tabIndex = index

    -- SwitchTabPage
    self._tabPages[index]:OnSelect(params)
    if index and self._tabBtns[index] then
        self._tabPages[index]:GetGameObject():SetActive(true)
    end

    -- SwitchTabBtn
    self:_SwitchTabBtn(index)
end

-- 切换 tab 流程
function UISideEnterCenterController:_SetTabSelect(index, params)
    if self._tabIndex == index then
        return
    end

    if self._switchTaskId and self._switchTaskId ~= -1 then
        return
    end

    local lockName = "UISideEnterCenterController:_SetTabSelect_" .. index
    GameGlobal.UIStateManager():Lock(lockName)

    self._switchTaskId = TaskManager:GetInstance():StartTask(function(TT)
        local res = self:_LoadTabPageData(TT, index)
        if not res then -- 中止切换流程
            GameGlobal.UIStateManager():UnLock(lockName)
            self._switchTaskId = nil
            return
        end

        self:_SwitchTabPage(TT, index, params)
        self:_SwitchTabBtn(index)
        GameGlobal.UIStateManager():UnLock(lockName)
        self._switchTaskId = nil
    end)
end

function UISideEnterCenterController:_SwitchTabPage(TT, index, params)
    local preIndex = self._tabIndex
    self._tabIndex = index

    -- 控制 Page
    if preIndex and self._tabPages[preIndex] then
        self._tabPages[preIndex]:OnDeselect()
    end
    if index and self._tabPages[index] then
        self._tabPages[index]:OnSelect(params)
    end

    -- 控制 GameObject
    -- 需要在一帧内连续执行，不能放到 OnDeselect(TT) 和 OnSelect(TT) 中处理
    if preIndex and self._tabPages[preIndex] then
        self._tabPages[preIndex]:GetGameObject():SetActive(false)
    end
    if index and self._tabPages[index] then
        self._tabPages[index]:GetGameObject():SetActive(true)
    end
end

function UISideEnterCenterController:_SwitchTabBtn(index)
    for i = 1, #self._tabBtns do
        self._tabBtns[i]:SetSelected(i == index)
    end
    self:_SetTabBtnPosition(index)
    self:_SetTabBtnEffect(index)
end

--endregion

--region effect

function UISideEnterCenterController:_SetTabBtnPosition(index)
    local viewPortWidth = self:GetUIComponent("RectTransform", "Viewport").rect.width
    local contentRect = self:GetUIComponent("RectTransform", "_tabBtns")
    -- UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(contentRect)

    local btnTrans = self._tabBtns[index]:GetGameObject():GetComponent(typeof(UnityEngine.RectTransform))
    local posX = btnTrans.anchoredPosition.x
    local width = contentRect.rect.width
    local target = viewPortWidth / 2 --目标是屏幕中心
    local deltaX = posX - target
    deltaX = Mathf.Clamp(deltaX, 0, math.max(width - viewPortWidth, 0))
    contentRect.anchoredPosition = Vector2(-deltaX, contentRect.anchoredPosition.y)
end

function UISideEnterCenterController:_SetTabBtnEffect(index)
    if index and self._tabBtns[index] then
        local target = self._tabBtns[index]:GetGameObject().transform
        local trans = self:GetUIComponent("RectTransform", "_selectBg")

        local duration = 0.3
        local tx = target.localPosition.x

        if self._playerTweener and self._playerTweener:IsPlaying() then
            self._playerTweener:Kill()
        end
        self._playerTweener = trans:DOLocalMoveX(tx, duration, true):SetEase(DG.Tweening.Ease.OutQuint)
    end
end

--endregion

--region Shot

function UISideEnterCenterController:_Shot(callback)
    ---@type H3DUIBlurHelper
    local shot = self:GetUIComponent("H3DUIBlurHelper", "shot")
    shot.gameObject:SetActive(true)
    shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())

    local rt = shot:RefreshBlurTexture()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    cache_rt.format = UnityEngine.RenderTextureFormat.RGB111110Float
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            if not self._active then
                return
            end
            UnityEngine.Graphics.Blit(rt, cache_rt)

            ---@type UnityEngine.UI.RawImage
            local a = self:GetUIComponent("RawImage", "rt")
            a.texture = cache_rt

            self:_HideUi()
            callback()
        end
    )
end

function UISideEnterCenterController:_HideUi()
    self:GetGameObject("rt"):SetActive(true)

    self:GetGameObject("shot"):SetActive(false)
    self:GetGameObject("ScrollView"):SetActive(false)
    self:GetGameObject("_tabPages"):SetActive(false)
    self:GetGameObject("_backBtns"):SetActive(false)
end

--endregion

--region Event Callback

function UISideEnterCenterController:LastBtnOnClick(go)
    local cur = self._tabIndex or 1
    local idx = math.max(cur - 1, 1)
    self:_SetTabSelect(idx)
end

function UISideEnterCenterController:NextBtnOnClick(go)
    local cur = self._tabIndex or 1
    local idx = math.min(cur + 1, #self._showTb)
    self:_SetTabSelect(idx)
end

--endregion

--region AttachEvent

function UISideEnterCenterController:AddListener()
end

function UISideEnterCenterController:DetachListener()
end

function UISideEnterCenterController:OnActivityCloseEvent(id)
end

--endregion
