--[[
    商城客户端UI管理类
    author by lixing
]]
---@class ClientShop
_class("ClientShop", Object)
ClientShop = ClientShop

_enum("ShopOpenWay", ShopOpenWay)
---@class ShopMainTabType
---同配置cfg_shop_main_tab.xlsx同步
local ShopMainTabType = {
    Recommend = 1, -- 推荐
    Secret = 2, -- 神秘
    Exchange = 3, -- 兑换
    Recharge = 4, -- 充值
    Gift = 5, -- 礼包
    Skins = 6, -- 时装
    Homeland = 7 -- 空庭套装
}
_enum("ShopMainTabType", ShopMainTabType)
---@class ShopGotoType
local ShopGotoType = {
    OpenShopConfirm = 0, -- 0跳转到相应界面，并打开购买界面。
    SortGoods = 1, -- 1跳转到指定页面且目标商品处于页面中的首个商品位，若有多个则依次往后排。
    OpenTab = 2 --2跳转到商品默认页面
}
_enum("ShopGotoType", ShopGotoType)
function ClientShop:Constructor()
    self.SecretSubTabType2Class = {
        [MarketType.Shop_BlackMarket] = DShopBlackStore,
        [MarketType.Shop_MysteryMarket] = DShopSecretExplore,
        [MarketType.Shop_WorldBoss] = DShopWorldBossStore
    }
    self:InitMainTabConfig()
    self:InitSecretTabInfo()

    self._exchangeShopData = ExchangeShopData:New()

    self._rechargeShopData = RechargeShopData:New()
    self._giftPackShopData = GiftPackShopData:New()
    self._skinsShopData = SkinsShopData:New()
    self._homelandShopData = HomelandShopData:New()
end

function ClientShop:InitMainTabConfig()
    self.m_ShopMainTabData = {}
    local datas = Cfg.cfg_shop_main_tab {}
    for id, cfg in ipairs(datas) do
        local s = DShopMainTab:New(cfg)
        table.insert(self.m_ShopMainTabData, s)
    end
end
---  from, server
---key:subTabType
---value:adId
function ClientShop:SetRecommendConfig(idDic)
    local hasSkinsAdBefore = self:CheckRecommendDataHasMarketType(MarketType.Shop_SkinMarket)
    --（20210813 时装按钮显隐刷新）

    self.m_ShopRecommendData = {}
    self.m_ShopRecommendIdDic = idDic
    if not idDic then
        return
    end
    local tmpDic = {}
    for key, value in pairs(idDic) do
        local data = {}
        data.id = key
        data.adid = value
        table.insert(tmpDic, data)
    end
    table.sort(
        tmpDic,
        function(a, b)
            if Cfg.cfg_shop_recommend[a.id] == nil then
                Log.error("cfg_shop_recommend cant find ",a.id)
            end
            if Cfg.cfg_shop_recommend[b.id] == nil then
                Log.error("cfg_shop_recommend cant find ",b.id)
            end
            local o_a = Cfg.cfg_shop_recommend[a.id].Order
            local o_b = Cfg.cfg_shop_recommend[b.id].Order
            return o_a < o_b
        end
    )

    local cfgs = Cfg.cfg_shop_recommend {}
    --MSG39769	(QA_王忠智）N17_商店QA_banner增加显示上限20220412	5	QA-开发制作中	李学森, 1958	04/15/2022
    local max = Cfg.cfg_global["ShopBannerMaxCount"].IntValue or 6
    local insertCount
    if max > #tmpDic then
        insertCount = #tmpDic
    else
        insertCount = max
    end
    for i = 1, insertCount do
        local tmp_id = tmpDic[i].id
        local tmp_adid = tmpDic[i].adid
        local cfg = cfgs[tmp_id]
        if cfg then
            local s = DShopRecommend:New(cfg, tmp_adid)
            table.insert(self.m_ShopRecommendData, s)
        else
            Log.error(" WoW !!!!cfg_shop_recommend not exit id:" .. tmp_id)
        end
    end

    local hasSkinsAdNow = self:CheckRecommendDataHasMarketType(MarketType.Shop_SkinMarket)
    --（20210813 时装按钮显隐刷新）
    if not hasSkinsAdBefore and hasSkinsAdNow then
        --刷新时装页签按钮
        Log.debug("[Shop] recommend now has skins ad,refresh skin btn")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ForceShowMainTabBtn, ShopMainTabType.Skins) --强制显示时装页签按钮
    end
end

function ClientShop:GetRecommendIdDic(idDic)
    return self.m_ShopRecommendIdDic
end
--- 判断当前推荐页数据里有没有包含某主页签的数据（20210813 时装按钮显隐刷新）
---@param marketType MarketType
function ClientShop:CheckRecommendDataHasMarketType(marketType)
    if not self.m_ShopRecommendData then
        return false
    end
    for index, value in ipairs(self.m_ShopRecommendData) do
        local adCfg = value:GetAdGroup()
        if adCfg then
            if adCfg.TabType == MarketType.Shop_SkinMarket then
                return true
            end
        end
    end
    return false
end

--- 商城一级页签数据
---@return DShopMainTab[]
function ClientShop:GetMainTabDatas()
    return self.m_ShopMainTabData
end

--[[
    @推荐
]]
--- 商城推荐页签数据
---@return DShopRecommend[]
function ClientShop:GetRecommendDatas()
    return self.m_ShopRecommendData
end

--[[
    @神秘
]]
--- 神秘页签

function ClientShop:InitSecretTabInfo()
    self.shopSecretTabData = {}
    for subTabType, value in pairs(self.SecretSubTabType2Class) do
        self.shopSecretTabData[subTabType] = value:New(subTabType)
    end
end

--- Parse ServerData
function ClientShop:SetSecretTabData(marketinfo, goodsconfig, subTabType)
    self.shopSecretTabData[subTabType]:SetData(marketinfo, goodsconfig)
end

-- local MarketType = {
--     Shop_Error = 0, --异常
--     Shop_BlackMarket = 1, --黑市
--     Shop_MysteryMarket = 2, --秘境商店
-- }
function ClientShop:SetRemainTime(time, subType)
    self.shopSecretTabData[subType]:SetRemainSecond(time)
end
function ClientShop:ReSortSecretGoods(subTabType, targetShopIds)
    self.shopSecretTabData[subTabType]:ReSortSecretGoods(targetShopIds)
end

function ClientShop:GetSecretTabData(subTabType)
    return self.shopSecretTabData[subTabType]
end

function ClientShop:GetSecretGoods(subTabType)
    return self.shopSecretTabData[subTabType]:GetSecretGoods()
end
---------------------------------------------------------------------------------------
--UTIL --
---------------------------------------------------------------------------------------
------public 打开商城界面唯一入口
--     self.gotoType = param and param[1]
--     local mainTabType = param and param[2]
--     local subTabType = param and param[3] or self.SortTab[1]
--     self.targetShopId = param and param[4]
---@type ShopGotoType
---@type ShopMainTabType
---@type MarketType
function ClientShop.OpenShop(...)
    GameGlobal.UIStateManager():ShowDialog("UIShopController", ...)
end

function ClientShop.CheckBuy(saleType, price)
    local result = true
    local roleModule = GameGlobal.GameLogic():GetModule(RoleModule)
    if saleType == RoleAssetID.RoleAssetGlow then
        local diamond = roleModule:GetGlow()
        if price > diamond then
            GameGlobal.UIStateManager():ShowDialog("UIShopCurrency1To2", price - diamond)
            result = false
        end
    elseif saleType == RoleAssetID.RoleAssetGold then
        local gold = roleModule:GetGold()
        if price > gold then
            ToastManager.ShowToast(StringTable.Get("str_shop_buy_no_gold"))
            result = false
        end
    elseif saleType == RoleAssetID.RoleAssetMazeCoin then
        local mazeCoin = roleModule:GetMazeCoin()
        if price > mazeCoin then
            ToastManager.ShowToast(StringTable.Get("str_shop_buy_no_maze"))
            result = false
        end
    end
    return result
end
-- 检查购买结果
function ClientShop.CheckShopCode(result)
    if result == SHOP_CODE.SHOP_SUCCESS then
        return true
    end
    if not ClientShop.ShopCode2Message then
        local get = StringTable.Get
        ClientShop.ShopCode2Message = {
            -- [SHOP_CODE.SHOP_SUCCESS] = get("str_shop_code_success"), --"购买成功",
            [SHOP_CODE.SHOP_CONFIG_ERROR] = get("str_shop_code_config_error"), --"配置错误",
            [SHOP_CODE.SHOP_SERVER_RETURN_ERROR] = get("str_shop_code_server_return_error"), --"服务器返回消息异常",
            [SHOP_CODE.SHOP_GOODS_ID_ERROR] = get("str_shop_code_goods_id_error"), --"商品id错误",
            [SHOP_CODE.SHOP_GOODS_SELLED_OUT] = get("str_shop_code_goods_selled_out"), --"商品已经售完",
            [SHOP_CODE.SHOP_ERROR_PRICE] = get("str_shop_code_error_price"), --"单价错误",
            [SHOP_CODE.SHOP_DONNOT_HAVE_DISCOUNT] = get("str_shop_code_do_not_have_discount"), --"不应有折扣",
            [SHOP_CODE.SHOP_ERROR_DISCOUNT] = get("str_shop_code_error_discount"), --"错误的折扣值",
            [SHOP_CODE.SHOP_CURRENCY_TYPE_ERROR] = get("str_shop_code_currency_type_error"), --"代币类型错误",
            [SHOP_CODE.SHOP_CURRENCY_NOT_ENOUGH] = get("str_shop_code_currency_not_enough"), --"货币不足"
            [SHOP_CODE.SHOP_AlREADY_PASSED_DOWN_LIMIT] = get("str_shop_code_not_being_sold"), --"货币不足"
            [SHOP_CODE.SHOP_BUY_COUNT_INVILID] = get("str_pay_bad_12"), --"数量限制"
            [SHOP_CODE.SHOP_GIFT_MAX_DAY_LIMIT] = string.format(
                get("str_pay_month_card_max_day_count_cant_over_limit", GiftPackShopItem.GetMonthCardMaxDayNum())
            )
        }
    end
    local msg = ClientShop.ShopCode2Message[result] or string.format("Request Error. SHOP_CODE=%d", result)
    ToastManager.ShowToast(msg)
    return false
end

--- 货币类型对应图片名字
function ClientShop.GetCurrencyImageName(saleType)
    return Cfg.cfg_top_tips[saleType].Icon
end

function ClientShop.GetMoney(saleType)
    local roleModule = GameGlobal.GameLogic():GetModule(RoleModule)
    local money = 0
    if saleType == RoleAssetID.RoleAssetPhyPoint then
        money = roleModule:GetHealthPoint()
    elseif saleType == RoleAssetID.RoleAssetGlow then
        money = roleModule:GetGlow()
    elseif saleType == RoleAssetID.RoleAssetGold then
        money = roleModule:GetGold()
    elseif saleType == RoleAssetID.RoleAssetMazeCoin then
        money = roleModule:GetMazeCoin()
    elseif saleType == RoleAssetID.RoleAssetXingZuan then
        local itemMd = GameGlobal.GetModule(ItemModule)
        money = itemMd:GetItemCount(RoleAssetID.RoleAssetXingZuan)
    elseif saleType == RoleAssetID.RoleAssetHuiYao then
        local itemMd = GameGlobal.GetModule(ItemModule)
        money = itemMd:GetItemCount(RoleAssetID.RoleAssetHuiYao)
    elseif saleType == RoleAssetID.RoleAssetHongPiao then
        local itemMd = GameGlobal.GetModule(ItemModule)
        money = itemMd:GetItemCount(RoleAssetID.RoleAssetHongPiao)
    elseif saleType == RoleAssetID.RoleAssetFurnitureCoin then
        local itemMd = GameGlobal.GetModule(ItemModule)
        money = itemMd:GetItemCount(RoleAssetID.RoleAssetFurnitureCoin)
    elseif saleType == RoleAssetID.RoleAssetWorldBossCoin then
        money = roleModule:GetWorldBossCoin()
    elseif saleType == RoleAssetID.RoleAssetWorldBossCoin2 then
        money = roleModule:GetWorldBossCoin2()
    else
        Log.error("!!!!!!!Unknown currency type,cant get money , type == " .. saleType)
    end
    return money
end

function ClientShop:SendProtocal(TT, mainTabType, subTabType)
    local shopModule = GameGlobal.GameLogic():GetModule(ShopModule)
    if mainTabType == ShopMainTabType.Recommend then
        local idDic = shopModule:GetRecommendIds(TT)
        if next(idDic) and idDic ~= nil then
            self:SetRecommendConfig(idDic)
        end
        return idDic and next(idDic)
    elseif mainTabType == ShopMainTabType.Secret then
        if subTabType == MarketType.Shop_BlackMarket then
            local marketinfo, time = shopModule:GetBlackMarketData(TT)
            if next(marketinfo) and marketinfo ~= nil then
                local goodsconfig = shopModule:GetBlackMarketConfig()
                self:SetSecretTabData(marketinfo, goodsconfig, MarketType.Shop_BlackMarket)
                self:SetRemainTime(time, MarketType.Shop_BlackMarket)
            end
            return marketinfo and next(marketinfo)
        elseif subTabType == MarketType.Shop_MysteryMarket then
            local marketinfo, time = shopModule:GetMysteryMarketData(TT)
            if next(marketinfo) and marketinfo ~= nil then
                local goodsconfig = shopModule:GetMysteryMarketConfig()
                self:SetSecretTabData(marketinfo, goodsconfig, MarketType.Shop_MysteryMarket)
                self:SetRemainTime(time, MarketType.Shop_MysteryMarket)
            end
            return marketinfo and next(marketinfo)
        elseif subTabType == MarketType.Shop_WorldBoss then
            local marketinfo, time = shopModule:RequestWorldBossMarket(TT)
            if next(marketinfo) and marketinfo ~= nil then
                local goodsconfig = shopModule:GetWorldBossMarketConfig()
                self:SetSecretTabData(marketinfo, goodsconfig, MarketType.Shop_WorldBoss)
                self:SetRemainTime(time, MarketType.Shop_WorldBoss)
            end
            return marketinfo and next(marketinfo)
        end
    elseif mainTabType == ShopMainTabType.Exchange then --兑换
        return true
    elseif mainTabType == ShopMainTabType.Recharge then --充值商店
        local res = shopModule:ApplyGiftMarketData(TT)
        if res and res:GetSucc() then
            local marketinfo, cfgGiftMarket = shopModule:GetGiftMarketData()
            self:GetGiftPackShopData():UpdateByServerData(marketinfo, cfgGiftMarket)
            --GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateGiftPackShop)
        end
        res = shopModule:ApplyPayMarketData(TT)
        if res and res:GetSucc() then
            GameGlobal.UAReportChannelEvent("OpenPurchase", {}) -- 打开充值界面
            local marketinfo, cfgRechargeMarket = shopModule:GetPayMarketData()
            self:GetRechargeShopData():UpdateByServerData(marketinfo, cfgRechargeMarket)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateRechargeShop)
            return true
        end
    elseif mainTabType == ShopMainTabType.Gift then --礼包商店
        local res = shopModule:ApplyGiftMarketData(TT)
        if res and res:GetSucc() then
            local marketinfo, cfgGiftMarket = shopModule:GetGiftMarketData()
            self:GetGiftPackShopData():UpdateByServerData(marketinfo, cfgGiftMarket)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateGiftPackShop)
            return true
        end
    elseif mainTabType == ShopMainTabType.Skins then --时装商店
        local res = shopModule:ApplySkinMarketData(TT)
        if res and res:GetSucc() then
            local marketinfo, cfgSkinsMarket, newSkins = shopModule:GetSkinsMarketData()
            self:GetSkinsShopData():UpdateByServerData(marketinfo, cfgSkinsMarket, newSkins)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateSkinsShop)
            return true
        end
    elseif mainTabType == ShopMainTabType.Homeland then --空庭套装， --珍贵商品
        local res = shopModule:RequestFurnitureMarket(TT)
        if res and res:GetSucc() then
            local marketData, marketConfig, refreshRemainTime = shopModule:GetFurnitureData()
            self:GetHomelandShopData():UpdateByServerData(MarketType.Shop_Furniture, marketData, marketConfig, refreshRemainTime, true)
        else
            return false
        end
        local preciousRes = shopModule:RequestFurniturePreciousMarket(TT)
        if preciousRes and preciousRes:GetSucc() then
            local precoousMarketData, precoousMarketConfig, precoousRefreshRemainTime = shopModule:GetFurniturePreciousData()
            self:GetHomelandShopData():UpdateByServerData(MarketType.Shop_Furniture_Precious, precoousMarketData, precoousMarketConfig, precoousRefreshRemainTime, false)
        else
            return false
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateHomelandShop)
        return true 
    else
        Log.fatal("### no such TabType. mainTabType=", mainTabType)
    end
    return false
end

---@return RechargeShopData
function ClientShop:GetRechargeShopData()
    return self._rechargeShopData
end
---@return GiftPackShopData
function ClientShop:GetGiftPackShopData()
    return self._giftPackShopData
end
---@return SkinsShopData
function ClientShop:GetSkinsShopData()
    return self._skinsShopData
end
---@return HomelandShopData
function ClientShop:GetHomelandShopData()
    return self._homelandShopData
end
--如果打开商店，就打开充值页签；否则就打开充值商店
function ClientShop:OpenRechargeShop()
    if GameGlobal.UIStateManager():IsShow("UIShopController") then --如果商店已打开
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OpenShop, ShopMainTabType.Recharge)
    else
        ClientShop.OpenShop(nil, ShopMainTabType.Recharge, MarketType.Shop_PayMarket)
    end
end

---检查耀晶是否充足，不足就跳转到充值界面
function ClientShop:CheckEnoughYJ(cost, bShowMsg, closeFunc)
    local mShop = GameGlobal.GetModule(ShopModule)
    local count1, freeCount1 = mShop:GetDiamondCount()
    if count1 >= cost then
        return true
    end
    if bShowMsg then
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel,
            "",
            StringTable.Get("str_pay_yj_not_enough_goto_recharge"),
            function(param)
                self:OpenRechargeShop()
                if closeFunc then
                    closeFunc()
                end
            end,
            nil,
            function(param)
            end,
            nil
        )
        return false
    else
        self:OpenRechargeShop()
        return false
    end
    return false
end

---检查光珀是否充足，不足就打开耀晶转光珀界面
function ClientShop:CheckEnoughGP(cost)
    local mRole = GameGlobal.GetModule(RoleModule)
    local count = mRole:GetGlow()
    if count >= cost then
        return true
    end
    local diff = cost - count
    GameGlobal.UIStateManager():ShowDialog("UIShopCurrency1To2", diff)
    return false
end

--耀晶光珀汇率
function ClientShop:GetDiamondExchangeGlowRate()
    if self._DiamondExchangeGlowRate then
        return self._DiamondExchangeGlowRate
    end
    local cfgv = Cfg.cfg_shop_global[1]
    if cfgv then
        self._DiamondExchangeGlowRate = cfgv.DiamondExchangeGlowRate
        return self._DiamondExchangeGlowRate
    end
    return 1
end

function ClientShop:GetGlowExchangeFurnitureCoinRate()
    if self._GlowExchangeFurnitureCoinRate then
        return self._GlowExchangeFurnitureCoinRate
    end
    local cfgv = Cfg.cfg_shop_global[1]
    if cfgv then
        self._GlowExchangeFurnitureCoinRate = cfgv.GlowExchangeFurnitureCoinRate
        return self._GlowExchangeFurnitureCoinRate
    end
    return 1
end

---用星标/特召星标id从cfg_shop_guangpo_goods获取星标商品配置
function ClientShop.GetXBCfg(xbId)
    local mShop = GameGlobal.GetModule(ShopModule)
    local _, config = mShop:GetGlowData()
    for id, cfgv in pairs(config) do
        if cfgv[ConfigKey.ConfigKey_ItemId] == xbId then
            local cfgv = config[id]
            return cfgv, id
        end
    end
    Log.fatal("### get goodsid failed from cfg_shop_guangpo_goods.")
    return nil, 0
end

---获取不显示剩余时间的下架时间时间戳
function ClientShop:GetNotShowLeftTime()
    if self._NotShowLeftTime then
        return self._NotShowLeftTime
    end
    local cfgv = Cfg.cfg_shop_global[1]
    if cfgv then
        self._NotShowLeftTime = tonumber(cfgv.NotShowLeftTime)
        return self._NotShowLeftTime
    end
    return 0
end

function ClientShop:GetExchangeShopData(subShop)
    return self._exchangeShopData:GetGoods(subShop)
end

function ClientShop:RefreshExchangeShopData(subShop)
    return self._exchangeShopData:RefreshData(subShop)
end

function ClientShop:GetExchangeShopResetTime()
    return self._exchangeShopData:RefreshTime()
end
