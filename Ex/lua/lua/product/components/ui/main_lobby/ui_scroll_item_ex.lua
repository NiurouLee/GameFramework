-----------------------------
-- QA_主界面广告图增加价格显示 --
--       Author: yl        --
-----------------------------
require("ui_scroll_item")

---@param request ShopPriceRequest
function UIScrollItem:BookPrice(request)
    self._uiBuy.gameObject:SetActive(false)
    self._uiDay.gameObject:SetActive(false)
    self._uiActiveNon.gameObject:SetActive(false)
    self._uiActiveNor.gameObject:SetActive(false)
    self._uiActiveLux.gameObject:SetActive(false)

    if self._cfg == nil then
        return
    end

    local jump = self._cfg.data

    -- 商店跳转
    if jump.JumpType ~= UIJumpType.UI_JumpMall then
        return
    end

    -- 参数
    local countParam = 0
    local JumpParam = jump.JumpParam
    if jump.JumpParam ~= nil then
        countParam = #JumpParam
    end

    -- 充值 -- 月卡
    if countParam >= 4 and JumpParam[2] == ShopMainTabType.Recharge then
        setmetatable(self, UIScrollItemRecharge)
        request:BookPrice(self, ShopMainTabType.Recharge, MarketType.Shop_Error)
    -- 礼包
    elseif countParam >= 4 and JumpParam[2] == ShopMainTabType.Gift then
        setmetatable(self, UIScrollItemGift)
        request:BookPrice(self, ShopMainTabType.Gift, MarketType.Shop_Error)
    -- 启航计划
    elseif countParam >= 2 and JumpParam[2] == ShopMainTabType.SailingPlan then
        setmetatable(self, UIScrollItemSailingPlan)
        request:BookPrice(self, ShopMainTabType.SailingPlan, MarketType.Shop_Error)
    end
end

function UIScrollItem:UpdatePrice(request)

end


---@class UIScrollItemRecharge:UIScrollItem
_class("UIScrollItemRecharge", UIScrollItem)
UIScrollItemRecharge = UIScrollItemRecharge
function UIScrollItemRecharge:UpdatePrice(request)
    local jump = self._cfg.data
    local id = jump.JumpParam[4]

    local clientShop = request:GetClientShop()
    local shopData = clientShop:GetRechargeShopData()
    --- @type GiftPackShopItem
    local monthCard = nil
    if shopData.GetMonthCardGoods ~= nil then
        monthCard = shopData:GetMonthCardGoods()
    end

    -- 月卡
    if monthCard ~= nil and monthCard:GetId() == id then
        local cardCfg = Cfg.cfg_shop_giftmarket_goods[id]
        if cardCfg.SaleType == SpecialNum.NeedPayMoney and cardCfg.NewPrice ~= 0 then
            if monthCard:GetRefreshTime() > 0 then
                self._uiDay.gameObject:SetActive(true)

                local remainTime = monthCard:GetRefreshTime()
                self._txtDayValue:SetText(math.ceil(remainTime / 86400))
            else
                local price = monthCard:GetPrice()

                self._uiBuy.gameObject:SetActive(true)
                self._txtBuyValue:SetText(price)
            end
        end
    end
end


---@class UIScrollItemGift:UIScrollItem
_class("UIScrollItemGift", UIScrollItem)
UIScrollItemGift = UIScrollItemGift
function UIScrollItemGift:UpdatePrice(request)
    local jump = self._cfg.data
    local id = jump.JumpParam[4]
    --- @type MonthGiftGoodsInfo
    local giftInfo, giftCfg = request:GetGiftData(id)
    if giftInfo == nil or giftCfg == nil then
        return
    end

    -- 1、普通礼包
    -- 2、月卡
    -- 3、特别事件簿跳转型礼包
    local showPrice = giftCfg.SaleType == SpecialNum.NeedPayMoney and giftCfg.NewPrice ~= 0
    if showPrice and giftCfg.GiftType == ShopGiftType.SGT_NormalGift then
        if giftInfo.selled_num ~= 0 then
            local price = request:GetGiftPrice(id)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        else
            local price = request:GetGiftPrice(id)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        end
    elseif showPrice and giftCfg.GiftType == ShopGiftType.SGT_MonthCard then
        if giftInfo.deadline_time > 0 then
            self._uiDay.gameObject:SetActive(true)

            local remainTime = giftInfo.deadline_time
            self._txtDayValue:SetText(math.ceil(remainTime / 86400))
        else
            local price = request:GetGiftPrice(id)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        end
    elseif giftCfg.GiftType == ShopGiftType.SGT_BattlePassGift then
        local battlePassCampaign = request:BattlePassCampaign()
        local buyInfo = nil
        local buyComponent = nil
        if battlePassCampaign ~= nil then
            local localProcess = battlePassCampaign:GetLocalProcess()
            buyInfo = localProcess:GetComponentInfo(ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT)
            buyComponent = localProcess:GetComponent(ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT)
        end

        if buyInfo ~= nil then
            local buyState = buyInfo.m_buy_state

            if buyState == BuyGiftStateType.EBGST_ADVANCED then
                -- 已购精英版
                self._uiActiveNor.gameObject:SetActive(true)
            elseif buyState == BuyGiftStateType.EBGST_LUXURY then
                -- 已购豪华版
                self._uiActiveLux.gameObject:SetActive(true)
            elseif buyState == BuyGiftStateType.EBGST_INIT then
                -- 初始状态，未购买
                local type = CampaignGiftType.ECGT_ADVANCED
                local giftId = buyComponent:GetFirstGiftIDByType(type)
                local price = buyComponent:GetGiftPriceForShowById(giftId) -- 显示用带货币符号的字符串

                self._uiBuy.gameObject:SetActive(true)
                self._txtBuyValue:SetText(price)
            end
        end
    elseif showPrice and giftCfg.GiftType == ShopGiftType.SGT_WeekCard then
        if giftInfo.deadline_time > 0 then
            self._uiDay.gameObject:SetActive(true)

            local remainTime = giftInfo.deadline_time
            self._txtDayValue:SetText(math.ceil(remainTime / 86400))
        else
            local price = request:GetGiftPrice(id)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        end
    end
end


---@class UIScrollItemSailingPlan:UIScrollItem
_class("UIScrollItemSailingPlan", UIScrollItem)
UIScrollItemSailingPlan = UIScrollItemSailingPlan
function UIScrollItemSailingPlan:UpdatePrice(request)
    local sailingPlanCampaign = request:SailingPlanCampaign()
    local buyInfo = nil
    if sailingPlanCampaign ~= nil then
        local localProcess = sailingPlanCampaign:GetLocalProcess()
        buyInfo = localProcess:GetComponentInfo(ECCampaignInlandSailingComponentID.BUY_GIFT)
    end

    ---@type CampaignGiftInfo
    local gift = nil
    if buyInfo ~= nil then
        gift = buyInfo.m_campaign_gift_list[1]
    end

    local cfgGood = nil
    if gift ~= nil then
        cfgGood = Cfg.cfg_shop_common_goods[gift.m_gift_id]
    end

    if cfgGood ~= nil and cfgGood.SaleType == SpecialNum.NeedPayMoney and gift.m_now_price ~= 0 then
        local buyState = buyInfo.m_buy_state

        if buyState ~= BuyGiftStateType.EBGST_INIT then
            self._uiActiveNon.gameObject:SetActive(true)
        else
            ---@type CampaignGiftInfo
            local gift = buyInfo.m_campaign_gift_list[1]
            local price = gift.m_now_price

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        end
    end
end


---@class ShopPriceRequest:Object
_class("ShopPriceRequest", Object)
ShopPriceRequest = ShopPriceRequest

function ShopPriceRequest:Constructor()
    self._isNational = false
    self._payModule = GameGlobal.GetModule(PayModule)
    self._shopModule = GameGlobal.GetModule(ShopModule)
    self._clientShop = self._shopModule:GetClientShop()
    self._bookList = nil    -- {targets, mainType, subType}
    self._priceEvent = nil

    self._giftData = nil
    self._giftConfig = nil
end

function ShopPriceRequest:Dispose()
    if self._requestTask then
        local task = GameGlobal.TaskManager():FindTask(self._requestTask)
        if task and task.state ~= TaskState.Stop then
            GameGlobal.TaskManager():KillTask(self._requestTask)
        end

        self._requestTask = nil
    end

    if self._priceEvent ~= nil then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.PayGetLocalPriceFinished, self._priceEvent)
        self._priceEvent = nil
    end
end

function ShopPriceRequest:BookPrice(target, mainType, subType)
    if self._bookList == nil then
        self._bookList = {}
    end

    local exist = false
    for k, v in pairs(self._bookList) do
        if v.mainType == mainType and v.subType == subType then
            table.insert(v.targets, target)
            exist = true
            break
        end
    end

    if not exist then
        table.insert(self._bookList, {targets = {target}, mainType = mainType, subType = subType})
    end
end

function ShopPriceRequest:GetShopModule()
    return self._shopModule
end

function ShopPriceRequest:GetClientShop()
    return self._clientShop
end

function ShopPriceRequest:GetGiftData(id)
    if self._giftData == nil then
        local giftInfo, giftCfg = self._shopModule:GetGiftMarketData()
        local giftList = giftInfo.goods

        self._giftData = {}
        self._giftConfig = giftCfg

        for k, v in pairs(giftList) do
            self._giftData[v.gift_id] = v
        end
    end

    return self._giftData[id], Cfg.cfg_shop_giftmarket_goods[id]
end

--- @return UIActivityCampaign
function ShopPriceRequest:BattlePassCampaign()
    return self._battlePassCampaign
end

--- @return UIActivityCampaign
function ShopPriceRequest:SailingPlanCampaign()
    return self._sailingPlanCampaign
end

function ShopPriceRequest:Request()
    local bookList = self._bookList
    if bookList == nil then
        bookList = {}
    end

    self._requestTask =
    GameGlobal.TaskManager():StartTask(function(TT)
        for k, v in pairs(bookList) do
            -- 充值 -- 月卡
            if v.mainType == ShopMainTabType.Recharge then
                self._clientShop:SendProtocal(TT, v.mainType, v.subType, nil)

            -- 礼包
            elseif v.mainType == ShopMainTabType.Gift then
                -- CEventMobileChooseRole
                -- self._clientShop:SendProtocal(TT, v.mainType, v.subType, nil)

                local loadBattlePass = false
                for tk, tv in pairs(v.targets) do
                    local jump = tv._cfg.data
                    local id = jump.JumpParam[4]
                    local giftInfo, giftCfg = self:GetGiftData(id)
                    if giftCfg.GiftType == ShopGiftType.SGT_BattlePassGift then
                        loadBattlePass = true
                    end
                end

                if loadBattlePass then
                    local res = AsyncRequestRes:New()
                    self._battlePassCampaign = UIActivityCampaign:New()
                    self._battlePassCampaign:LoadCampaignInfo(
                            TT,
                            res,
                            ECampaignType.CAMPAIGN_TYPE_BATTLEPASS,
                            ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT)
                    self._battlePassCampaign:ReLoadCampaignInfo_Force(TT, res)
                    if not res:GetSucc() then
                        Log.error("ShopPriceRequest No battle pass.")
                    end

                    local localProcess = self._battlePassCampaign:GetLocalProcess()
                    local buyComponent = localProcess:GetComponent(ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT)
                    buyComponent:GetAllGiftLocalPrice()

                    ---@type BuyGiftComponentInfo
                    self._buyInfo = localProcess:GetComponentInfo(ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT)

                    self:ListenPriceEvent()
                end

                if self._shopModule.GetLocalPrice ~= nil then
                    self._shopModule:GetLocalPrice()
                    self:ListenPriceEvent()
                end

            -- 启航计划
            elseif v.mainType == ShopMainTabType.SailingPlan then
                local res = AsyncRequestRes:New()
                self._sailingPlanCampaign = UIActivityCampaign:New()
                self._sailingPlanCampaign:LoadCampaignInfo(
                        TT,
                        res,
                        ECampaignType.CAMPAIGN_TYPE_INLAND_SAILING,
                        ECCampaignInlandSailingComponentID.BUY_GIFT)
                self._sailingPlanCampaign:ReLoadCampaignInfo_Force(TT, res)
                if not res:GetSucc() then
                    Log.error("ShopPriceRequest No sailing plan.")
                end

                local localProcess = self._sailingPlanCampaign:GetLocalProcess()

                ---@type BuyGiftComponentInfo
                self._buyInfo = localProcess:GetComponentInfo(ECCampaignInlandSailingComponentID.BUY_GIFT)
            end
        end

        for k, v in pairs(bookList) do
            for tk, tv in pairs(v.targets) do
                tv:UpdatePrice(self)
            end
        end
    end)
end

function ShopPriceRequest:ListenPriceEvent()
    if self._isNational then
        return
    end

    if self._priceEvent == nil then
        self._priceEvent = GameHelper:GetInstance():CreateCallback(self.OnPayGetLocalPriceFinished, self)
        GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.PayGetLocalPriceFinished, self._priceEvent)
    end
end

function ShopPriceRequest:OnPayGetLocalPriceFinished()
    if self._bookList == nil then
        return
    end

    for k, v in pairs(self._bookList) do
        for tk, tv in pairs(v.targets) do
            tv:UpdatePrice(self)
        end
    end
end

function ShopPriceRequest:GetGiftPrice(id)
    local goodPriceList = self._payModule:GetGoodPriceList()
    local marketinfo, cfgGiftMarket = self._shopModule:GetGiftMarketData()

    local goodPrice = nil
    local cfgv = cfgGiftMarket[id]
    if cfgv then
        local midasId = cfgv[ConfigKey.ConfigKey_MidasItemId]
        goodPrice = goodPriceList[midasId]
    end

    if goodPrice then
        return goodPrice.price
    else
        local giftCfg = Cfg.cfg_shop_giftmarket_goods[id]
        local price = giftCfg.NewPrice

        return price
    end
end

