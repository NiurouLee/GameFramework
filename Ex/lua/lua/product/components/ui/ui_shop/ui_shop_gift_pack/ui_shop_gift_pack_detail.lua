---@class UIShopGiftPackDetail:UIController
_class("UIShopGiftPackDetail", UIController)
UIShopGiftPackDetail = UIShopGiftPackDetail

function UIShopGiftPackDetail:Constructor()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._data = self.clientShop:GetGiftPackShopData()
end

function UIShopGiftPackDetail:OnShow(uiParams)
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._goTips = self:GetGameObject("tips")
    ---@type UILocalizationText
    self._txtTips = self:GetUIComponent("UILocalizationText", "txtTips")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UnityEngine.GameObject
    self._goLimit = self:GetGameObject("limit")
    self._goLimit:SetActive(false)
    ---@type UILocalizationText
    self._txtLimit = self:GetUIComponent("UILocalizationText", "txtLimit")
    ---@type UnityEngine.UI.Image
    self._imgPrice = self:GetUIComponent("Image", "imgPrice")
    ---@type UILocalizationText
    self._txtPrice = self:GetUIComponent("UILocalizationText", "txtPrice")
    ---@type UICustomWidgetPool
    self._sopImmediately = self:GetUIComponent("UISelectObjectPath", "sopImmediately")
    ---@type UICustomWidgetPool
    self._sopDaily = self:GetUIComponent("UISelectObjectPath", "sopDaily")
    self._goDaily = self:GetGameObject("daily")
    ---@type UILocalizationText
    self.txtGetDaily = self:GetUIComponent("UILocalizationText", "txtGetDaily")
    ---@type UnityEngine.UI.Button
    self._btnBuy = self:GetUIComponent("Button", "btnBuy")
    ---@type UnityEngine.Animation
    self._anim = self:GetUIComponent("Animation", "uiAnim")

    self._immediatelyTitle = self:GetGameObject("immediately")

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)

    local id = uiParams[1]
    self:Flush(id)
end

function UIShopGiftPackDetail:Flush(id)
    self._itemData = self._data:GetGoodBuyId(id)
    self._txtName:SetText(self._itemData:GetName())
    self:FlushTips()

    self._imgIcon:LoadImage(self._itemData:GetIconDetail())
    local str = self._itemData:GetCountStr()
    if string.isnullorempty(str) then
        self._goLimit:SetActive(false)
    else
        self._txtLimit:SetText(str)
        self._goLimit:SetActive(true)
    end

    if self._itemData:IsMonthCard() and self._itemData:HasSoldOut() then --只有周期礼包的购买次数达到限购次数时才会置灰
        local f = 76 / 255
        self._txtPrice.color = Color(f, f, f)
        self._btnBuy.interactable = false
    else
        self._txtPrice.color = Color.white
        self._btnBuy.interactable = true
    end
    self:FlushPrice()

    local awardsImmediately = self._itemData:GetAwardsImmediately()
    if table.count(awardsImmediately) > 0 then
        self._immediatelyTitle:SetActive(true)
        self._sopImmediately:SpawnObjects("UIShopGiftPackGetItem", table.count(awardsImmediately))
        ---@type UIShopGiftPackGetItem[]
        local lstImmediately = self._sopImmediately:GetAllSpawnList()
        for i, ui in ipairs(lstImmediately) do
            ui:Flush(awardsImmediately[i])
        end
    else
        self._immediatelyTitle:SetActive(false)
        self._sopImmediately:SpawnObjects("UIShopGiftPackGetItem", 0)
    end

    local awardsDaily = self._itemData:GetAwardsDaily()
    if awardsDaily and table.count(awardsDaily) > 0 then
        self._goDaily:SetActive(true)
        self._sopDaily:SpawnObjects("UIShopGiftPackGetItem", table.count(awardsDaily))
        ---@type UIShopGiftPackGetItem[]
        local lstDaily = self._sopDaily:GetAllSpawnList()
        for i, ui in ipairs(lstDaily) do
            ui:Flush(awardsDaily[i])
        end
    else
        self._goDaily:SetActive(false)
    end
    self.txtGetDaily:SetText(StringTable.Get("str_pay_gain_daily", self._itemData.duration))

    -- if self._itemData.isWeekCard then
    --     self.txtGetDaily:SetText(StringTable.Get("str_pay_gain_daily", 7))
    -- else
    --     self.txtGetDaily:SetText(StringTable.Get("str_pay_gain_daily", 30))
    -- end
end

function UIShopGiftPackDetail:FlushTips()
    if self._itemData:IsWeekCard() then
        if self._itemData:HasSoldOut() then
            self._txtTips:SetText(StringTable.Get("str_pay_soldout"))
        else --尚未购买
            self._txtTips:SetText(StringTable.Get("str_pay_not_buy_yet"))
        end
    else
        local strCycleType = self._itemData:GetCycleTypeStr()
        if string.isnullorempty(strCycleType) then
            self._goTips:SetActive(false)
        else
            self._goTips:SetActive(true)
            self._txtTips:SetText(strCycleType)
        end
    end
end

---@param id number
function UIShopGiftPackDetail:FlushPrice()
    local SetPrice = function()
        local itemtType = self._itemData:GetType()
        if itemtType == GiftPackType.Currency then
            self._imgPrice.gameObject:SetActive(false)
            self._txtPrice:SetText(self._itemData:GetPriceWithCurrencySymbol())
        elseif itemtType == GiftPackType.Free then
            self._imgPrice.gameObject:SetActive(false)
            self._txtPrice:SetText(StringTable.Get("str_pay_free"))
        else
            self._imgPrice.gameObject:SetActive(true)
            self._imgPrice.sprite = self._atlas:GetSprite(self._itemData:GetPriceIcon())
            self._txtPrice:SetText(self._itemData:GetPrice())
        end
    end
    if self._itemData:IsWeekCard() then
        if self._itemData:HasSoldOut() then
            self._imgPrice.gameObject:SetActive(false)
            self._txtPrice:SetText(StringTable.Get("str_pay_soldout"))
        else
            SetPrice()
        end
    else
        SetPrice()
    end
end

function UIShopGiftPackDetail:OnHide()
end

function UIShopGiftPackDetail:bgOnClick(go)
    self:Lock("UIShopGiftPackDetail:OnHide")
    self._anim:Play("Uieff_UIShopGiftPackDetail_Out")
    self:StartTask(
        function(TT)
            YIELD(TT, 667)
            self:UnLock("UIShopGiftPackDetail:OnHide")
            self:CloseDialog()
        end,
        self
    )
end

function UIShopGiftPackDetail:btnBuyOnClick(go)
    local packType = self._itemData:GetType()
    if not self._itemData:CheckDayCount() then
        self:CloseDialog()
        return
    end
    if self._itemData:HasSoldOut() then
        if packType == GiftPackType.Currency then
            GameGlobal.GetUIModule(ShopModule):ReportPayStep(
                PayStep.ClickPurchaseButton,
                false,
                -1,
                "buy_limit_reached"
            )
        end
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.Ok,
            "",
            StringTable.Get("str_pay_buy_limit_reached")
        )
        self:CloseDialog()
        return
    end
    if packType == GiftPackType.Currency then ---礼包直购
        local midasId = self._itemData:GetMidasId()
        if string.isnullorempty(midasId) then
            GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "midasId_is_empty")
            Log.fatal("### [Pay]midasId can't be empty")
            self:CloseDialog()
            return
        end
        self:StartTask(
            function(TT)
                self:Lock("UIShopGiftPackDetailRequestBuyGift")
                local ret = self.shopModule:BuyGift(TT, self._itemData:GetId())
                if ClientShop.CheckShopCode(ret) then
                    self:CanCharge(midasId)
                else
                    if ret == SHOP_CODE.SHOP_GOODS_SELLED_OUT then --售完重新请求礼包商城
                        self.clientShop:SendProtocal(TT, ShopMainTabType.Gift)
                    end
                end
                self:UnLock("UIShopGiftPackDetailRequestBuyGift")
            end,
            self
        )
    elseif packType == GiftPackType.Yaojing then ---消耗耀晶购买礼包
        local price = self._itemData:GetPrice()
        if self.clientShop:CheckEnoughYJ(price) then
            self:RequestBuyGift()
        else
            --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "Yaojing_not_enough")
            self:CloseDialog()
        end
    elseif packType == GiftPackType.Guangpo then ---消耗光珀购买礼包
        local price = self._itemData:GetPrice()
        if self.clientShop:CheckEnoughGP(price) then
            self:RequestBuyGift()
        else
            --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "Guangpo_not_enough")
            self:CloseDialog()
        end
    elseif packType == GiftPackType.Item then
        local mRole = self:GetModule(RoleModule)
        local price = self._itemData:GetPrice()
        local assetId = self._itemData:GetPriceItemId()
        local count = mRole:GetAssetCount(assetId)
        if count >= price then
            self:RequestBuyGift()
        else
            --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "item_not_enough")
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.Ok,
                "",
                StringTable.Get("str_pay_item_not_enough")
            )
        end
    elseif packType == GiftPackType.Free then --免费礼包，直接发消息
        self:RequestBuyGift()
    else
        Log.fatal("### invalid GiftPackType. packType=", packType)
    end
end

function UIShopGiftPackDetail:RequestBuyGift()
    self:StartTask(
        function(TT)
            self:Lock("UIShopGiftPackDetailRequestBuyGift")
            local id = self._itemData:GetId()
            --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, true)
            --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.LaunchMidasAuthentication, true)
            local ret = self.shopModule:BuyGift(TT, id)
            if ClientShop.CheckShopCode(ret) then
                local mPay = GameGlobal.GetModule(PayModule)
                mPay:ShowUIShopRechargeGainWithoutYJ(self._itemData)
            end
            self.clientShop:SendProtocal(TT, ShopMainTabType.Gift)
            self:UnLock("UIShopGiftPackDetailRequestBuyGift")
            self:CloseDialog()
        end,
        self
    )
end

function UIShopGiftPackDetail:CanCharge(midasId)
    self:Lock("UIShopGiftPackDetail_CanCharge")
    GameGlobal.TaskManager():StartTask(self.CanChargeCoro, self, midasId)
end

function UIShopGiftPackDetail:CanChargeCoro(TT, midasId)
    local roleModule = GameGlobal.GetModule(RoleModule)
    if not roleModule:IsJapanZone() then
        self:StartTask(self.BuyGoodsTask, self, midasId, 1)
        self:UnLock("UIShopGiftPackDetail_CanCharge")
        return
    end
    ---@type PayModule
    local payModule = GameGlobal.GetModule(PayModule)
    --判断是否选择了年龄
    if payModule:NeedSelectAge(TT) then
        self:ShowDialog("UISetAgeConfirmController")
        self:UnLock("UIShopGiftPackDetail_CanCharge")
        return
    end
    self:StartTask(self.BuyGoodsTask, self, midasId, 1)
    -- --判断是否可以充值
    -- local res, replyEvent = payModule:CanPay(TT, self._itemData:GetPrice())
    -- if replyEvent.result == 0 then --可以充值
    --     self:StartTask(self.BuyGoodsTask, self, midasId, 1)
    -- elseif replyEvent.result == 3 then --充值已经达到上限
    --     local res1, replyEvent1 = self._payModule:GetAgeId(TT)
    --     local id = 0
    --     if res1:GetSucc() then
    --         id = replyEvent1.cfg_id
    --     end
    --     self:ShowDialog("UIPayLawTipsController", id)
    -- else --未知错误
    --     Log.error("can pay msg error")
    -- end
    self:UnLock("UIShopGiftPackDetail_CanCharge")
end

function UIShopGiftPackDetail:BuyGoodsTask(TT, itemId, itemCount)
    local mPay = self:GetModule(PayModule)
    if IsAndroid() or IsUnityEditor() or IsPc() then --安卓环境下
        if H3DGCloudLuaHelper.MsdkStatus == MSDKStatus.MS_Inland then
            local res, replyEvent = mPay:SendBuyGoodsRequest(TT, itemId, itemCount)
            Log.debug("UIDemoPayController:BuyGoodsTask IsAndroid start res ", res.m_result)
            if not res:GetSucc() then --购买物品请求失败
                if res.m_result == PayErrorCode.PAY_ERROR_NOT_USE_MIDAS then
                    PopupManager.Alert(
                        "UICommonMessageBox",
                        PopupPriority.Normal,
                        PopupMsgBoxType.Ok,
                        "",
                        StringTable.Get("str_pay_direct_buy_need_open_switch")
                    )
                else
                    PopupManager.Alert(
                        "UICommonMessageBox",
                        PopupPriority.Normal,
                        PopupMsgBoxType.Ok,
                        "",
                        StringTable.Get("str_pay_direct_buy_fail_try_later")
                    )
                end
            elseif not replyEvent then
                Log.debug("UIDemoPayController:BuyGoodsTask failed no replyEvent")
            elseif res.m_result == PayErrorCode.PAY_SUCC then
                local token = replyEvent.token
                local url = replyEvent.url_params
                Log.debug("UIDemoPayController:BuyGoodsTask success token ", token, " url ", url)
                mPay:BuyGoodsByUrl(url, self._itemData)
            end
        elseif H3DGCloudLuaHelper.MsdkStatus == MSDKStatus.MS_International then
            mPay:BuyGoodsByGiftPackShopItem(self._itemData, itemCount)
        end
    elseif IsIos() then
        mPay:BuyGoodsByGiftPackShopItem(self._itemData, itemCount)
    end
end
