--[[
    @商城界面
    ****************************************************
    **  注意这个方法只要是Tab.Custom都要写
    **  tab显示时调用 self.tab:SetData(self.params)
    **  tab隐藏时调用 self.tab:ExcuteHideLogic()
    ****************************************************
]]
---@class UIShopController:UIController
_class("UIShopController", UIController)
UIShopController = UIShopController

function UIShopController:Constructor()
    self.mainTabType = nil
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self.mRedDot = GameGlobal.GetModule(RedDotModule)

    self._refreshTaskID = nil
    self._refreshSubTaskID = nil

    self:OnApplicationFocus(true)
    ---@type UIHomelandModule
    self._homeLandModule = GameGlobal.GetUIModule(HomelandModule)
end

function UIShopController:LoadDataOnEnter(TT, res, uiParams)
    -- uiParams = {2, 6, 0, 11235}
    self.params = uiParams

    local mainTabType = self.params and self.params[2] or ShopMainTabType.Recommend
    
    if uiParams[5] then
        local isRed, isTips, state = self.shopModule:ShowMonthCardRedPoint()
        if isRed then
            mainTabType = ShopMainTabType.Gift
        end
    end

    if self.clientShop:SendProtocal(TT, mainTabType, self.params and self.params[3] or MarketType.Shop_BlackMarket) then
        res:SetSucc(true)
        --用于判定时装页签是否显示
        self.clientShop:SendProtocal(TT, ShopMainTabType.Skins)
    else
        res:SetSucc(false)
    end

    -- ShowInSkinsTab -> 在皮肤页签中显示
    if self.params ~= nil and #self.params >= 4 then
        local shopId = self.params[4]
        local cfgv = Cfg.cfg_shop_giftmarket_goods[shopId]
        if cfgv ~= nil and cfgv.ShowInSkinsTab then
            self.params =
            {
                uiParams[1],
                ShopMainTabType.Skins,
                uiParams[3],
                uiParams[4],
            }

            mainTabType = self.params[2]
        end
    end

    if mainTabType == ShopMainTabType.Skins then
        local followTabType = ShopMainTabType.Gift
        if self.clientShop:SendProtocal(TT, followTabType, self.params and self.params[3] or MarketType.Shop_BlackMarket) then
            res:SetSucc(res:GetSucc())
        else
            res:SetSucc(false)
        end
    end
    --进商城时拉取一下所有礼包的价格
    self.shopModule:GetLocalPrice()
    --进商城时补发
    local mPay = self:GetModule(PayModule)
    self:StartTask(mPay.PreReprovideCallTask, mPay, nil)
end

--[[
    params[1] = gotoType -- 跳转类型
    params[2] = mainTabType  -- 一级页签
    param[3] = subTabType -- 二级页签
    param[4] = targetShopId -- 目标商品id或者ids
    uiParams[5] = boolean --是否检查月卡弹出提示（过期或即将过期）
]]
function UIShopController:OnShow(uiParams)
    self._checkMonthCardTips = uiParams[5]
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIShop)

    local mainTabType = self.params and self.params[2]
    self:AddListener()
    local topButton = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self.topButton = topButton:SpawnObject("UICommonTopButton")
    self._lastBGMResName = AudioHelperController.GetCurrentBgm()
    local hideHomeBtn = self._homeLandModule:IsRunning()
    self.topButton:SetData(
        function()
            local curUIState = GameGlobal.UIStateManager():CurUIStateType()
            if curUIState == UIStateType.UIShopController then
                self:SwitchState(UIStateType.UIMain)
            else
                self:CloseDialog()
            end
            AudioHelperController.PlayBGM(self._lastBGMResName, AudioConstValue.BGMCrossFadeTime)
        end,
        nil,
        nil,
        hideHomeBtn
    )
    local sop = self:GetUIComponent("UISelectObjectPath", "mainmenu")
    ---@type UICurrencyMenu
    self.shopCurrencyMenu = sop:SpawnObject("UICurrencyMenu")
    ---@type UnityEngine.UI.ToggleGroup
    self.tglGroup = self:GetUIComponent("ToggleGroup", "maintoggle")
    local mainToggle = self:GetUIComponent("UISelectObjectPath", "maintoggle")
    local tabDatas = self.clientShop:GetMainTabDatas()
    mainToggle:SpawnObjects("UIShopMainTabBtn", #tabDatas)
    ---@type UIShopMainTabBtn[]
    self.allToggle = mainToggle:GetAllSpawnList()
    for i, v in ipairs(self.allToggle) do
        local tabData = tabDatas[i]
        v:Init(tabData, self.tglGroup, self.OnClickTabBtn, self)
        local sortIndex = tabData:GetSortIndex()
        local itemGo = v:GetGameObject()
        itemGo.transform:SetSiblingIndex(sortIndex - 1)
    end
    self:InitBg()
    -- 导购员
    self:InitPlayerSpine()
    self._refreshTaskID = nil
    if self._checkMonthCardTips then
        local isRed, isTips, state = self.shopModule:ShowMonthCardRedPoint()
        if isRed then
            mainTabType = ShopMainTabType.Gift
        end
    end
    self:OnClickTabBtn(mainTabType or ShopMainTabType.Recommend, true)

    --进入商店保存当前星灵列表快照，用于购买星灵后判定是否为初次获得
    self:GetModule(PetModule):GetAllPetsSnapshoot()

    local mRole = GameGlobal.GetModule(RoleModule)
    local isUnLock = mRole:CheckModuleUnlock(GameModuleID.MD_Shop)
    for i, v in ipairs(self.allToggle) do
        local go = v:GetGameObject()
        if isUnLock then
            if v:GetTabType() == ShopMainTabType.Skins then
                --时装页签 判断是否显示
                v:CheckSkinTabHide()
            elseif v:GetTabType() == ShopMainTabType.Homeland then
                v:CheckHomelandTabHide()
            else
                go:SetActive(true)
            end
        else
            local mainTabType = tabDatas[i]:GetMainTab()
            if mainTabType == ShopMainTabType.Recharge or mainTabType == ShopMainTabType.Gift then
                go:SetActive(true)
            else
                go:SetActive(false)
            end
        end
    end

    if EngineGameHelper.EnableAppleVerifyBulletin() then
        -- 审核服环境
        for i, v in ipairs(self.allToggle) do
            local go = v:GetGameObject()
            local mainTabType = tabDatas[i]:GetMainTab()
            if mainTabType == ShopMainTabType.Recommend 
            or mainTabType == ShopMainTabType.Secret 
            or mainTabType == ShopMainTabType.Skins 
            or mainTabType == ShopMainTabType.Exchange 
            or mainTabType == ShopMainTabType.Homeland then
                go:SetActive(false)
            else
                go:SetActive(true)
            end
        end
        self:OpenShop(ShopMainTabType.Gift)
    end

    self:CoFlushTabNew()
    self:AttachEvent(GameEventType.ShopNew, self.CoFlushTabNew)
    self.mRedDot:ListenRedDot(
        {[RedDotType.RDT_SHOP_GIFT_NEW] = GameEventType.ShopNew, [RedDotType.RDT_SHOP_SIGN_NEW] = GameEventType.ShopNew}
    )

    if not mainTabType then
        self.shopCurrencyMenu:OnOpenShop()
    end
    self:_CheckMonthCardTips(self._checkMonthCardTips)
end

function UIShopController:OnHide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideTSFBtn, false)
    if self._refreshTaskID then
        GameGlobal.TaskManager():KillTask(self._refreshTaskID)
        self._refreshTaskID = nil
    end
    self:DetachEvent(GameEventType.ChangeShopBg, self.ChangeShopBg)
    self:DetachEvent(GameEventType.ShopTabChange, self.ShopTabChange)
    self:DetachEvent(GameEventType.OpenShop, self.OpenShop)
    self:DetachEvent(GameEventType.ApplicationFocus, self.OnApplicationFocus)
    self:DetachEvent(GameEventType.ShopNew, self.CoFlushTabNew)
    self.mRedDot:UnListenRedDot({RedDotType.RDT_SHOP_GIFT_NEW, RedDotType.RDT_SHOP_SIGN_NEW})
    self.allToggle = nil
end

function UIShopController:AddListener()
    self:AttachEvent(GameEventType.ChangeShopBg, self.ChangeShopBg)
    self:AttachEvent(GameEventType.ShopTabChange, self.ShopTabChange)
    self:AttachEvent(GameEventType.OpenShop, self.OpenShop)
    self:AttachEvent(GameEventType.ApplicationFocus, self.OnApplicationFocus)
end

function UIShopController.CheckIsOpen(mainTabType)
    if mainTabType == ShopMainTabType.Recharge or mainTabType == ShopMainTabType.Gift then
        local isShieldPay = UIConst.IsShieldPay
        return not isShieldPay
    end
    return true
end

---@param mainTabType ShopMainTabType
function UIShopController:OpenShop(mainTabType)
    self:OnClickTabBtn(mainTabType or ShopMainTabType.Recommend)
end

--1.推荐, 2.神秘, 3.皮肤, 4.家具, 5.充值, 6.礼包, 7.时装, 8.空庭套装
---@param mainTabType ShopMainTabType
function UIShopController:OnClickTabBtn(mainTabType, first)
    if self.mainTabType == mainTabType then
        return
    end
    if not UIShopController.CheckIsOpen(mainTabType) then
        return
    end
    if first then
        self:RefreshPanel(mainTabType, first)
    elseif mainTabType == ShopMainTabType.Skins then
        self:RefreshTask(mainTabType, ShopMainTabType.Gift)
    else
        self:RefreshTask(mainTabType)
    end
    -- if mainTabType == ShopMainTabType.MonthCard then
    --     if not self._checkMonthCardTips then
    --         self:_CheckMonthCardTips(true)
    --     end
    -- end
end

function UIShopController:RefreshTask(mainTabType, followTabType)
    if self._refreshTaskID then
        GameGlobal.TaskManager():KillTask(self._refreshTaskID)
        self._refreshTaskID = nil
    end

    if self._refreshSubTaskID then
        GameGlobal.TaskManager():KillTask(self._refreshSubTaskID)
        self._refreshSubTaskID = nil
    end

    local reqRemainCount = 1
    local fnRefreshPanel = function()
        reqRemainCount = reqRemainCount - 1
        if reqRemainCount == 0 then
            self:RefreshPanel(mainTabType)
        end
    end

    if followTabType ~= nil then
        reqRemainCount = reqRemainCount + 1
        self._refreshSubTaskID =
        self:StartTask(function(TT)
            if not self.clientShop:SendProtocal(TT, followTabType, self.params and self.params[3] or MarketType.Shop_BlackMarket) then
                return
            end
            fnRefreshPanel()
        end, self)
    end

    self._refreshTaskID =
    self:StartTask(function(TT)
        if not self.clientShop:SendProtocal(TT, mainTabType, self.params and self.params[3] or MarketType.Shop_BlackMarket) then
            return
        end
        fnRefreshPanel()
    end, self)
end

function UIShopController:RefreshPanel(mainTabType, first)
    if self.mainTabType then
        self.allToggle[self.mainTabType]:Select(false)
    end
    self.mainTabType = mainTabType
    if self.mainTabType then
        self.allToggle[self.mainTabType]:Select(true, first)
    end
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.ShowHideTSFBtn,
        mainTabType == ShopMainTabType.Recharge or mainTabType == ShopMainTabType.Gift or
            mainTabType == ShopMainTabType.Skins
    )
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.ShowHideLimitedTimeRechargeBtn,
        mainTabType == ShopMainTabType.Recommend
    )
    local tab
    if self.mainTabType == ShopMainTabType.Recommend then
        if not self.shopRecommendTab then
            local sop = self:GetUIComponent("UISelectObjectPath", "UIShopRecommendTab")
            ---@type UIShopRecommendTab
            self.shopRecommendTab = sop:SpawnObject("UIShopRecommendTab")
        end
        tab = self.shopRecommendTab
    elseif self.mainTabType == ShopMainTabType.Secret then
        if not self.shopSecretTab then
            local sop = self:GetUIComponent("UISelectObjectPath", "UIShopSecretTab")
            ---@type UIShopRecommendTab
            self.shopSecretTab = sop:SpawnObject("UIShopSecretTab")
        end
        tab = self.shopSecretTab
    elseif self.mainTabType == ShopMainTabType.Exchange then
        if not self.exchangeTab then
            local sop = self:GetUIComponent("UISelectObjectPath", "UIShopExchangeTab")
            ---@type UIShopExchangeTab
            self.exchangeTab = sop:SpawnObject("UIShopExchangeTab")
        end
        tab = self.exchangeTab
    elseif self.mainTabType == ShopMainTabType.Recharge then
        if not self.shopRechargeTab then
            local sop = self:GetUIComponent("UISelectObjectPath", "UIShopRechargeTab")
            ---@type UIShopRechargeTab
            self.shopRechargeTab = sop:SpawnObject("UIShopRechargeTab")
        end
        tab = self.shopRechargeTab
    elseif self.mainTabType == ShopMainTabType.Gift then
        if not self.shopGiftPackTab then
            local sop = self:GetUIComponent("UISelectObjectPath", "UIShopGiftPackTab")
            ---@type UIShopGiftPackTab
            self.shopGiftPackTab = sop:SpawnObject("UIShopGiftPackTab")
        end
        tab = self.shopGiftPackTab
    elseif self.mainTabType == ShopMainTabType.Skins then
        if not self.shopSkinsPackTab then
            local sop = self:GetUIComponent("UISelectObjectPath", "UIShopSkinsTab")
            ---@type UIShopSkinsTab
            self.shopSkinsPackTab = sop:SpawnObject("UIShopSkinsTab")
        end
        tab = self.shopSkinsPackTab
    elseif self.mainTabType == ShopMainTabType.Homeland then
        if not self.shopHomelandTab then
            local sop = self:GetUIComponent("UISelectObjectPath", "UIShopHomelandTab")
            ---@type UIShopHomelandTab
            self.shopHomelandTab = sop:SpawnObject("UIShopHomelandTab")
        end
        tab = self.shopHomelandTab
    else
        Log.fatal("### unvalid mainTabType. self.mainTabType = ", self.mainTabType)
    end
    if self.tab then
        local tab = self.tab
        self.tab:ExcuteHideLogic(
            function(_tab)
                if _tab:View() then
                    _tab:Enable(false)
                end
            end
        )
    end
    self.tab = tab
    if self.tab then
        self.tab:SetData(self.params)
        self.tab:Enable(true)
        self.params = nil
        self:RefreshGuiderArea()
    end
end

-- 刷新导购员区状态
function UIShopController:RefreshGuiderArea()
    self:InitWelWord()
end

function UIShopController:CoFlushTabNew()
    self:StartTask(
        function(TT)
            local res = self.mRedDot:RequestRedDotStatus(TT, {RedDotType.RDT_SHOP_GIFT_NEW, RedDotType.RDT_SHOP_SIGN_NEW})
            if not self.allToggle then
                return
            end
            local tabDatas = self.clientShop:GetMainTabDatas()
            for i, v in ipairs(self.allToggle) do
                local isShow = false
                if res then
                    local mainTabType = tabDatas[i]:GetMainTab()
                    if mainTabType == ShopMainTabType.Gift then
                        isShow = res[RedDotType.RDT_SHOP_GIFT_NEW] or false
                    elseif mainTabType == ShopMainTabType.Skins then
                        isShow = res[RedDotType.RDT_SHOP_SIGN_NEW] or false
                    elseif mainTabType == ShopMainTabType.Homeland then
                        isShow = self.shopModule:GetHomelandShopTabNew()
                    elseif mainTabType == ShopMainTabType.Recharge then
                        isShow = self.shopModule:GetHomelandRechargeTabNew()
                    end
                end
                v:FlushNew(isShow)
            end
        end,
        self
    )
end

---@public
function UIShopController:ShowTab(params)
    self.params = params
    local mainTabType = self.params[2] or 1
    self:OnClickTabBtn(mainTabType)
end

function UIShopController:OnUpdate(deltaTimeMS)
    if self.tab then
        -- local no_error, error_msg = pcall(self.tab.Update, self.tab, deltaTimeMS)
        self.tab:Update(deltaTimeMS)
    end
end

function UIShopController:InitBg()
    self.bigBg = self:GetUIComponent("RawImageLoader", "bigbg")
    self.bigBgGO = self:GetGameObject("bigbg")

    self.recommendBgGO = self:GetGameObject("recommendbg")
    self.recommendBgGO:SetActive(false)
    self.secretBgGO = self:GetGameObject("secretbg")
    self.secretBgGO:SetActive(false)
    self.blurMask = self:GetUIComponent("H3DUIBlurHelper", "BlurMask")
    self.blurMaskObject = self:GetGameObject("BlurMask")
    local camera = GameGlobal.UIStateManager():GetControllerCamera("UIShopController")
    self.blurMask.OwnerCamera = camera
end

function UIShopController:ChangeShopBg(mainTabType, bgName)
    -- if mainTabType == ShopMainTabType.Recommend then
    --     local camera = GameGlobal.UIStateManager():GetControllerCamera("UIShopController")
    --     self.blurMask.OwnerCamera = camera
    --     self.recommendBgGO:SetActive(true)
    --     self.secretBgGO:SetActive(false)
    --     self.bigBg:LoadImage(bgName)
    --     self.bigBgGO:SetActive(true)
    --     self.blurMaskObject:SetActive(true)
    --     self.blurMask:RefreshBlurTexture()
    --     self.bigBgGO:SetActive(false)
    -- elseif mainTabType == ShopMainTabType.Secret then
    --     self.blurMask.OwnerCamera = nil
    --     self.blurMaskObject:SetActive(false)
    --     self.recommendBgGO:SetActive(false)
    --     self.secretBgGO:SetActive(true)
    -- end
end

function UIShopController:ShopTabChange(mainTabType, subTabType)
    if mainTabType == ShopMainTabType.Recommend then
        self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetGold, RoleAssetID.RoleAssetGlow})
    elseif mainTabType == ShopMainTabType.Secret then
        if subTabType == MarketType.Shop_BlackMarket then
            self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetGold, RoleAssetID.RoleAssetGlow})
        elseif subTabType == MarketType.Shop_MysteryMarket then
            self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetMazeCoin})
        elseif subTabType == MarketType.Shop_WorldBoss then
            self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetWorldBossCoin, RoleAssetID.RoleAssetWorldBossCoin2})
        end
    elseif mainTabType == ShopMainTabType.Exchange then
        if subTabType == MarketType.Shop_XingZuan then
            self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetXingZuan})
        elseif subTabType == MarketType.Shop_HuiYao then
            self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetHuiYao})
        elseif subTabType == MarketType.Shop_GuangPo then
            self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetGlow})
        elseif subTabType == MarketType.Shop_HongPiao then
            self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetHongPiao})
        end
    elseif mainTabType == ShopMainTabType.Recharge then
        self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetDiamond}, true)
    elseif mainTabType == ShopMainTabType.Gift then
        self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetDiamond, RoleAssetID.RoleAssetGlow})
    elseif mainTabType == ShopMainTabType.Skins then
        self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetDiamond})
    elseif mainTabType == ShopMainTabType.Homeland then
        self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetFurnitureCoin, RoleAssetID.RoleAssetGlow})
    else
        Log.warn("### invalid mainTabType.", mainTabType)
    end
end

function UIShopController:GetMainTab(mainTabType)
    if self.allToggle then
        for i, v in ipairs(self.allToggle) do
            if v.shopMainTabData:GetMainTab() == mainTabType then
                return v:GetGameObject("pic")
            end
        end
    end
    return nil
end

function UIShopController:GetSecretGood(index)
    return self.shopSecretTab and self.shopSecretTab:GetGood(index)
end
----------------------spine---------------------
function UIShopController:InitPlayerSpine()
    self.spinePlaying = false
    self._spine = self:GetUIComponent("SpineLoader", "spine")
    self._spineGo = self:GetGameObject("spine")
    self.wordGO = self:GetGameObject("btnwordbg")
    self.wordTxt = self:GetUIComponent("UILocalizationText", "word")
    self.wordTempTxt = self:GetUIComponent("UILocalizationText", "wordtemp")
    self:StartTask(self.WelPlayerSpine, self)
    self:InitInteractWord()
end

function UIShopController:InitInteractWord()
    --交互台词
    self.interactWords = string.split(StringTable.Get("str_shop_interact_wel_word"), "|")
    self.stack = Stack:New()
end

---@private
---进入商城默认台词
function UIShopController:InitWelWord()
    self:SetBoxHeight(StringTable.Get("str_shop_recommend_wel_word"))
end

function UIShopController:WelPlayerSpine(TT)
    --spine
    self._spine:DestroyCurrentSpine()
    self.spinePlaying = true
    self:IdlePlayerSpine()
end

function UIShopController:IdlePlayerSpine()
    if self.spinePlaying then
        self.spinePlaying = false
        self._spine:DestroyCurrentSpine()
        --spine
        self._spine:LoadSpine("duya_spine_idle")
    end
end

function UIShopController:SetBoxHeight(str)
    self.wordTxt:SetText(str)
    self.wordTempTxt:SetText(str)
end

function UIShopController:GetInteractWord()
    if self.stack:Size() <= 0 then
        local count = 0
        local all = #self.interactWords
        while count < all do
            local index = math.random(1, all)
            if not self.stack:Contains(index) then
                self.stack:Push(index)
                count = count + 1
            end
        end
    end
    return self.interactWords[self.stack:Pop()]
end

---@private
---点击spine
function UIShopController:btnpicOnClick(go)
    --点击导购员，导购员会重新播放欢迎动作，播放动作过程中再次点击无反馈。
    if self.spinePlaying == false then
        -- self:StartTask(self.WelPlayerSpine, self)
        if self.wordGO.activeSelf == false then
            self.wordGO:SetActive(true)
        else
            local word = self:GetInteractWord()
            self:SetBoxHeight(word)
        end
    end

    local showDebugInfo = false
    if HelperProxy:GetInstance():GetConfig("ShopBtnShowDebugInfo", "false") == "true" then
        showDebugInfo = true
    end
    if (showDebugInfo and Log.loglevel ~= ELogLevel.None) or IsUnityEditor() then
        showDebugInfo = true
    else
        showDebugInfo = false
    end

    if showDebugInfo then
        local title = "当前支付相关配置"
        local mPay = self:GetModule(PayModule)
        local value = mPay:DebugGetParam()
        
        PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok,
        title, value)
    end
end

---@private
---点击台词交互区
function UIShopController:btnwordbgOnClick(go)
    if self.wordGO.activeSelf == true then
        self.wordGO:SetActive(false)
    end
end

--重新获得焦点时调用下补发接口
function UIShopController:OnApplicationFocus(isFocus)
    if isFocus then
        local mPay = self:GetModule(PayModule)
        GameGlobal.TaskManager():StartTask(mPay.PreReprovideCallTask, mPay, nil)
    end
end

function UIShopController:_CheckMonthCardTips(check)
    if check == true then
        local monthCardInfo = self.shopModule:GetMonthCardInfo()
        if monthCardInfo then
            local isRed, isTips, state = self.shopModule:ShowMonthCardRedPoint()
            if isTips then
                local saveKey 
                local tipsKey
                if state == 2 then
                    saveKey = self.shopModule:GetMonthCardWillOutDataTipsKey(monthCardInfo)
                    tipsKey = "str_shop_month_card_will_out_data"
                elseif state == 3 then
                    saveKey = self.shopModule:GetMonthCardOutDataTipsKey(monthCardInfo)
                    tipsKey = "str_shop_month_card_out_data"
                end
                if saveKey and tipsKey then
                    ToastManager.ShowToast(StringTable.Get(tipsKey))
                    LocalDB.SetInt(saveKey,1)
                end
            end
        end
    end
end