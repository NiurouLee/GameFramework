--[[
    商城推荐页签（一级页签）
]]
---@class UIShopRecommendTab:UICustomWidget

_class("UIShopRecommendTab", UICustomWidget)
UIShopRecommendTab = UIShopRecommendTab

function UIShopRecommendTab:Constructor()
    self._payModule = self:GetModule(PayModule)
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._giftData = nil
    self._giftConfig = nil
    -- self.spinePlaying = false
    self.atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    self.time = 0
    self.time1 = 0

    self._refreshTaskID = nil
end

function UIShopRecommendTab:SetData(param)
    self.show = true
    -- self.firstChoose = false

    -- self:StartTask(
    --     function(TT)
    --         self.animator:SetTrigger("in")
    --         YIELD(TT, 1700)
    --     end
    -- )

    -- self:InitWelWord()
    local idDic = self.clientShop:GetRecommendIdDic()
    self:RefreshRecommond(idDic, true)
    -- self._spineGo:SetActive(true)
end

function UIShopRecommendTab:RefreshRecommond(idDic, first)
    self:SetToggle()
    local index
    if self.subTabType and not table.iskey(idDic, self.subTabType) then
        index = 1
        self.subTabType = nil
    else
        index = self.index or 1
    end
    self:OnClickTabBtn(index, true, first)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopTabChange, ShopMainTabType.Recommend)
end

function UIShopRecommendTab:ExcuteHideLogic(callBack)
    self.show = false
    self.time = 0
    if callBack then
        callBack(self)
    end
    -- self:IdlePlayerSpine()
    -- self._spineGo:SetActive(false)
end

function UIShopRecommendTab:Update(deltaTimeMS)
    self.time = self.time + deltaTimeMS
    if self.time >= 4000 then
        self:TurnRight()
        self.time = 0
    end
end

function UIShopRecommendTab:OnShow(param)
    local adImg = self:GetUIComponent("RawImageLoader", "adpic")
    local adCG = self:GetUIComponent("CanvasGroup", "adpic")
    local adImgGO = self:GetGameObject("adpic")
    adImgGO:SetActive(true)
    adCG.alpha = 1

    local ad2Img = self:GetUIComponent("RawImageLoader", "adpic2")
    local ad2CG = self:GetUIComponent("CanvasGroup", "adpic2")
    local ad2ImgGO = self:GetGameObject("adpic2")
    ad2ImgGO:SetActive(true)
    ad2CG.alpha = 1

    self.adIndex = 1
    self.adImg = {adImg, ad2Img}
    self.adImgGO = {adImgGO, ad2ImgGO}
    self.adCG = {adCG, ad2CG}

    self.adWordText = self:GetUIComponent("UILocalizationText", "adword")

    self.iconTglGroup = self:GetUIComponent("ToggleGroup", "adtoggle")
    ---@type UICustomWidgetPool
    self.iconToggle = self:GetUIComponent("UISelectObjectPath", "adtoggle")
    self.iconTglTrans = self:GetUIComponent("RectTransform", "adtoggle")

    self.chooseTrans = self:GetUIComponent("Transform", "choose")
    self.chooseCG = self:GetUIComponent("CanvasGroup", "choose")

    self.pointParentGO = self:GetGameObject("point")
    self.points = {}
    for index = 1, 10 do
        local trans = GameObjectHelper.FindChild(self.pointParentGO.transform, "p" .. index)
        trans.gameObject:SetActive(false)
        self.points[index] = {}
        self.points[index].trans = trans
        self.points[index].rect = trans:GetComponent("RectTransform")
        self.points[index].image = trans:GetComponent("Image")
    end

    self:InitWidgetPrice()

    self._refreshTaskID = nil

    self:AddTimer()
end

function UIShopRecommendTab:InitWidgetPrice()
    self._battlePassCampaign = UIActivityCampaign:New()
    self._battlePassCampaign:LoadCampaignInfo_Local(
            ECampaignType.CAMPAIGN_TYPE_BATTLEPASS,
            ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT)

    self._uiPrice = self:GetGameObject("uiPrice"):GetComponent("UIView")
    self._uiBuy = self._uiPrice:GetUIComponent("RectTransform", "uiBuy")
    self._uiDay = self._uiPrice:GetUIComponent("RectTransform", "uiDay")
    self._uiActiveNon = self._uiPrice:GetUIComponent("RectTransform", "uiActiveNon")
    self._uiActiveNor = self._uiPrice:GetUIComponent("RectTransform", "uiActiveNor")
    self._uiActiveLux = self._uiPrice:GetUIComponent("RectTransform", "uiActiveLux")
    self._txtBuyValue = self._uiPrice:GetUIComponent("UILocalizationText", "txtBuyValue")
    self._txtDayValue = self._uiPrice:GetUIComponent("UILocalizationText", "txtDayValue")

    self:AttachEvent(GameEventType.PayGetLocalPriceFinished, self.UpdatePrice)
end

function UIShopRecommendTab:AddTimer()
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local svrTime = math.floor(svrTimeModule:GetServerTime() / 1000)
    self._gapsTime = -1
    local cfg_shop_recommend = Cfg.cfg_shop_recommend {}
    if cfg_shop_recommend then
        for key, value in pairs(cfg_shop_recommend) do
            local timeStr = value.TimeLimit
            if timeStr then
                local time_1_str = timeStr[1]
                local time_2_str = timeStr[2]

                if value.IsResident then
                    time_2_str = HelperProxy:GetInstance():ResidentTimeString()
                end

                --开始时间
                local openTimeTable = HelperProxy:GetInstance():GetTimeTable(time_1_str)
                local closeTimeTable = HelperProxy:GetInstance():GetTimeTable(time_2_str)

                local localOpenTime = _utc2Local(openTimeTable)
                local localCloseTime = _utc2Local(closeTimeTable)

                --结束时间
                local time_1_num = HelperProxy:GetInstance():FormatDateTime(localOpenTime)
                local time_2_num = HelperProxy:GetInstance():FormatDateTime(localCloseTime)

                local gapTime = -1
                if time_1_num > svrTime then
                    gapTime = time_1_num - svrTime
                else
                    if time_2_num > svrTime then
                        gapTime = time_2_num - svrTime
                    end
                end

                if gapTime > 0 then
                    if self._gapsTime < 0 then
                        self._gapsTime = gapTime
                    else
                        if gapTime < self._gapsTime then
                            self._gapsTime = gapTime
                        end
                    end
                end
            end
        end
    end

    Log.debug("###[UIShopRecommendTab] self._gapsTime --> ", self._gapsTime)
    if self._gapsTime > 0 then
        self._event =
            GameGlobal.RealTimer():AddEvent(
            self._gapsTime * 1000,
            function()
                self:TimeDownRefresh()
            end
        )

        Log.debug("###[UIShopRecommendTab] addevent --> second --> ", self._gapsTime)
    end
end

function UIShopRecommendTab:SetPointSelect(index, select)
    if select then
        if self.points[index] then
            self.points[index].image.sprite = self.atlas:GetSprite("shop_tuijian_di7")
            self.points[index].rect.sizeDelta = Vector2(74, 39)
        end
    else
        if self.points[index] then
            self.points[index].image.sprite = self.atlas:GetSprite("shop_tuijian_di6")
            self.points[index].rect.sizeDelta = Vector2(30, 39)
        end
    end
end
function UIShopRecommendTab:OnHide()
    if self._refreshTaskID then
        GameGlobal.TaskManager():KillTask(self._refreshTaskID)
        self._refreshTaskID = nil
    end

    if self._contentTweener then
        self._contentTweener:Kill()
    end

    if self._event then
        GameGlobal.RealTimer():CancelEvent(self._event)
        self._event = nil
    end
end
---@private
---点击二级页签
function UIShopRecommendTab:OnClickTabBtn(index, force, first)
    --广告栏当前最左边的是列表中的第几个
    if not self._viewLeftIdx then
        local _tViewIdx = index - 5
        if _tViewIdx <= 0 then
            _tViewIdx = 1
        end
        self._viewLeftIdx = _tViewIdx
    end

    -----------------------------
    if not force then
        if self.index == index then
            return
        end
    end

    self.time = 0

    local moveContent = false

    if index < self._viewLeftIdx then
        self._viewLeftIdx = index
        moveContent = true
    elseif index > self._viewLeftIdx then
        local tmpC = 5
        if table.count(self.recommendDatas) > 5 then
            if index ~= table.count(self.recommendDatas) then
                tmpC = 4
            end
        end
        if index - self._viewLeftIdx >= tmpC then
            self._viewLeftIdx = index - tmpC + 1
            moveContent = true
        end
    elseif index == self._viewLeftIdx then
        if table.count(self.recommendDatas) > 5 then
            if index ~= 1 then
                self._viewLeftIdx = index - 1
                moveContent = true
            end
        end
    end

    -----------------------------
    if self.index then
        if self.allIconToggle[self.index] then
            self.allIconToggle[self.index]:Select(false)
        end
        self:SetPointSelect(self.index, false)
    end
    -----------------------------

    self.index = index
    if moveContent then
        local duration = nil
        self:MovePanelToIndex(self.index, self._viewLeftIdx,duration)
    end

    if self.index then
        if self.allIconToggle[self.index] then
            self.allIconToggle[self.index]:Select(true)
        end
        self:SetPointSelect(self.index, true)

        if not self.firstChoose then
            self.firstChoose = true
            if moveContent then
                --(-232.8,-274.5166),临时改法，每次进来放在第一的位置
                local go = self.chooseTrans.gameObject
                local rt = go:GetComponent("RectTransform")
                rt.anchoredPosition = Vector2(-232.8,-274.5166)
            else
                self._refreshTaskID =
                    self:StartTask(
                    function(TT)
                        YIELD(TT)
                        YIELD(TT)
                        local targetX = self.allIconToggle[self.index]:GetGameObject().transform.position.x
                        local y = self.chooseTrans.position.y
                        self.chooseTrans.position = Vector3(targetX, y, 0)
                    end
                )
            end
        else
            if not moveContent then
                if self._contentTweener then
                    self._contentTweener:Kill(true)
                end
                self:DoChooseMove()
            end
        end
    end
    self.shopRecommendData = self.recommendDatas[self.index]
    if not self.shopRecommendData then
        self.adCG[1].alpha = 0
        self.adCG[2].alpha = 1
        self:SetBoxHeight("")
        self.adWordText:SetText("")
        return
    end
    self:SetAdInfo(first)
    self:UpdatePrice()
end
function UIShopRecommendTab:DoChooseMove()
    self.chooseTrans.gameObject:SetActive(true)
    if self.allIconToggle[self.index] then
        local targetX = self.allIconToggle[self.index]:GetGameObject().transform.position.x
        self.chooseTrans:DOMoveX(targetX, 0.35)
        self.chooseCG.alpha = 1
        self.chooseCG:DOFade(0, 0.3):OnComplete(
            function()
                if self.chooseCG then
                    self.chooseCG:DOFade(1, 0.3)
                end
            end
        )
    end
end
---@private
---进入商城默认台词
function UIShopRecommendTab:InitWelWord()
    self:SetBoxHeight(StringTable.Get("str_shop_recommend_wel_word"))
end

function UIShopRecommendTab:SetToggle()
    if not self.iconToggle.uiCustomWidgets then --MSG32801
        Log.error("### [UIShopRecommendTab SetToggle] UICustomWidgetPool uiCustomWidgets nil.")
        return
    end
    self.recommendDatas = self.clientShop:GetRecommendDatas()
    if not self.recommendDatas then
        return
    end
    local count = table.count(self.recommendDatas)
    self.iconToggle:SpawnObjects("UIShopRecommendIconBtn", count)
    ---@type UIShopRecommendIconBtn[]
    self.allIconToggle = self.iconToggle:GetAllSpawnList()
    for i, v in ipairs(self.allIconToggle) do
        if i <= count then
            v:Init(i, self.recommendDatas[i], self.iconTglGroup, self.OnClickTabBtn, self)
        end
    end

    for index = 1, 10 do
        if index <= count then
            self.points[index].trans.gameObject:SetActive(true)
        else
            self.points[index].trans.gameObject:SetActive(false)
        end
    end
end
-- function UIShopRecommendTab:InitPlayerSpine()
--     self._spine = self:GetUIComponent("SpineLoader", "spine")
--     self._spineGo = self:GetGameObject("spine")
-- end

-- function UIShopRecommendTab:WelPlayerSpine(TT)
--     --spine
--     self._spine:DestroyCurrentSpine()
--     -- self._spine:LoadSpine("duya_spine_idle")
--     self.spinePlaying = true
--     -- YIELD(TT, 2000)
--     self:IdlePlayerSpine()
-- end

-- function UIShopRecommendTab:IdlePlayerSpine()
--     if self.spinePlaying then
--         self.spinePlaying = false
--         self._spine:DestroyCurrentSpine()
--         --spine
--         self._spine:LoadSpine("duya_spine_idle")
--     end
-- end

function UIShopRecommendTab:SetAdInfo(first)
    self.adGroup = self.shopRecommendData:GetAdGroup()
    if not self.adGroup then
        return
    end
    if first then
        self.adIndex = 1
        self.adCG[self.adIndex].alpha = 1
        self.adImg[self.adIndex]:LoadImage(self.adGroup.Pic)

        self.adCG[2].alpha = 0
    else
        self.adCG[self.adIndex].alpha = 1
        self.adCG[self.adIndex]:DOFade(0, 0.4)
        self.adIndex = self.adIndex == 1 and 2 or 1
        self.adCG[self.adIndex].alpha = 0
        self.adCG[self.adIndex]:DOFade(1, 0.4)
        self.adImg[self.adIndex]:LoadImage(self.adGroup.Pic)
    end

    if not first then
        self:SetBoxHeight(StringTable.Get(self.adGroup.Word))
        local owner = self:RootUIOwner()
        if owner then
            owner.wordGO:SetActive(true)
        end
    end
    if first then
        self.adWordText:SetText(StringTable.Get(self.adGroup.AdWord))
        self.adWordOrder = 1
    else
        self.adWordText:SetText(StringTable.Get(self.adGroup.AdWord))
        self:DoAdWordAnimation()
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeShopBg, ShopMainTabType.Recommend, self.adGroup.Pic)
end

function UIShopRecommendTab:UpdatePrice()
    self._uiBuy.gameObject:SetActive(false)
    self._uiDay.gameObject:SetActive(false)
    self._uiActiveNon.gameObject:SetActive(false)
    self._uiActiveNor.gameObject:SetActive(false)
    self._uiActiveLux.gameObject:SetActive(false)

    self.adGroup = self.shopRecommendData:GetAdGroup()
    if not self.adGroup then
        return
    end

    local adGotoType = self.adGroup.GotoType
    local adGotoParam = self.adGroup.GotoParam
    local countParam = 0
    if adGotoParam ~= nil then
        countParam = #adGotoParam
    end

    if adGotoType ~= ShopGotoType.OpenShopConfirm then
        return
    end

    if self._giftData == nil then
        local giftInfo, giftCfg = self.shopModule:GetGiftMarketData()
        local giftList = giftInfo.goods

        self._giftData = {}
        self._giftConfig = giftCfg

        for k, v in pairs(giftList) do
            self._giftData[v.gift_id] = v
        end
    end

    local giftId = 0
    local giftCfg = nil
    if countParam >= 3 and adGotoParam[1] == ShopMainTabType.Gift then
        giftId = adGotoParam[3]
        giftCfg = Cfg.cfg_shop_giftmarket_goods[giftId]
    end

    local giftInfo = self._giftData[giftId]

    if giftInfo == nil or giftCfg == nil then
        return
    end

    -- 1、普通礼包
    -- 2、月卡
    -- 3、特别事件簿跳转型礼包
    local showPrice = giftCfg.SaleType == SpecialNum.NeedPayMoney and giftCfg.NewPrice ~= 0
    if showPrice and giftCfg.GiftType == ShopGiftType.SGT_NormalGift then
        if giftInfo.selled_num ~= 0 then
            local price = self:GetGiftPrice(giftId)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        else
            local price = self:GetGiftPrice(giftId)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        end
    elseif showPrice and giftCfg.GiftType == ShopGiftType.SGT_MonthCard then
        if giftInfo.deadline_time > 0 then
            self._uiDay.gameObject:SetActive(true)

            local remainTime = giftInfo.deadline_time
            self._txtDayValue:SetText(math.ceil(remainTime / 86400))
        else
            local price = self:GetGiftPrice(giftId)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        end
    elseif giftCfg.GiftType == ShopGiftType.SGT_BattlePassGift then
        local battlePassCampaign = self._battlePassCampaign
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
            local price = self:GetGiftPrice(giftId)

            self._uiBuy.gameObject:SetActive(true)
            self._txtBuyValue:SetText(price)
        end
    end
end

function UIShopRecommendTab:GetGiftPrice(id)
    local goodPriceList = self._payModule:GetGoodPriceList()
    local marketinfo, cfgGiftMarket = self.shopModule:GetGiftMarketData()

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

function UIShopRecommendTab:DoAdWordAnimation()
    -- local cur = self.adWordOrder == 1 and self.adWordTxt or self.adWordTxt1
    -- local next = self.adWordOrder == 1 and self.adWordTxt1 or self.adWordTxt
    -- cur.transform.localEulerAngles = Vector3(0, 0, 0)
    -- cur.transform:DORotate(Vector3(90, 0, 0), 0.5)
    -- self:StartTask(
    --     function(TT)
    --         local frame = 1
    --         local fadeFrame = 10
    --         next.color = Color(1, 1, 1, 1)
    --         while frame <= fadeFrame do
    --             cur.color = Color(1, 1, 1, (fadeFrame - frame) / fadeFrame)
    --             frame = frame + 1
    --             YIELD(TT)
    --         end
    --     end
    -- )
    -- next.transform.localEulerAngles = Vector3(-90, 0, 0)
    -- next.transform:DORotate(Vector3(0, 0, 0), 0.5)
    -- self:StartTask(
    --     function(TT)
    --         local frame = 1
    --         local fadeFrame = 10
    --         next.color = Color(1, 1, 1, 0)
    --         while frame <= fadeFrame do
    --             next.color = Color(1, 1, 1, 1 - (fadeFrame - frame) / fadeFrame)
    --             frame = frame + 1
    --             YIELD(TT)
    --         end
    --     end
    -- )
    -- self.adWordOrder = self.adWordOrder == 1 and 2 or 1
end
---@private
---点击spine
-- function UIShopRecommendTab:btnpicOnClick(go)
--     --点击导购员，导购员会重新播放欢迎动作，播放动作过程中再次点击无反馈。
--     if self.spinePlaying == false then
--         -- self:StartTask(self.WelPlayerSpine, self)
--         if self.wordGO.activeSelf == false then
--             self.wordGO:SetActive(true)
--         else
--             -- local height = self.wordRect.sizeDelta.y
--             local word = self:GetInteractWord()
--             self:SetBoxHeight(word)
--         end
--     end
-- end

-- ---@private 点击台词交互区
-- function UIShopRecommendTab:btnwordbgOnClick(go)
--     if self.wordGO.activeSelf == true then
--         self.wordGO:SetActive(false)
--     end
-- end

-- 限时页签需要检查
function UIShopRecommendTab:CanPass()
    local pass = true
    if self.shopRecommendData:GetTag() == RecommendType.RecommendType_TimeLimit then
        self:StartTask(
            function(TT)
                local result, idDic = self.shopModule:confirmIfExist(TT, self.adGroup.ID)
                if result == true then
                else
                    if idDic ~= {} and idDic ~= nil then
                        pass = false
                        self.clientShop:SetRecommendConfig(idDic)
                        self:RefreshRecommond(idDic, false)
                        ToastManager.ShowToast(StringTable.Get("str_toast_manager_time_limited_TAB_closed"))
                        return
                    end
                end
            end,
            self
        )
    end
    return pass
end

--定时结束了刷新广告图
function UIShopRecommendTab:TimeDownRefresh()
    self:Lock("UIShopRecommendTab:TimeDownRefresh")
    GameGlobal.TaskManager():StartTask(self._OnTimeDownRefresh, self)
end
function UIShopRecommendTab:_OnTimeDownRefresh(TT)
    self:UnLock("UIShopRecommendTab:TimeDownRefresh")
    local idDic = self.shopModule:GetRecommendIds(TT)
    self.index = 1
    self.clientShop:SetRecommendConfig(idDic)
    self:RefreshRecommond(idDic, false)
    Log.debug("###[UIShopRecommendTab] TimeDownRefresh !")
end

function UIShopRecommendTab:btnadpicOnClick()
    if not self.adGroup then
        return
    end
    if not self.shopRecommendData then
        return
    end
    -- 用于从广告跳转再回来时候 页签没了的情况
    self.subTabType = self.shopRecommendData:GetSubTabType()
    if not self:CanPass() then
        return
    end
    -- 月卡 时装 家具
    if self.subTabType == PageType.PageType_FashionClothes or self.subTabType == PageType.PageType_Furniture then
        -- 测试版本，功能未开放
        ToastManager.ShowToast(StringTable.Get("str_shop_main_tab_lock"))
        return
    end

    local adGotoType = self.adGroup.GotoType
    local adGotoParam = self.adGroup.GotoParam

    local controller = GameGlobal.UIStateManager():GetController("UIShopController")
    if not controller then
        return
    end
    local param
    -- 0跳转到相应界面，并打开购买界面。
    if adGotoType == ShopGotoType.OpenShopConfirm then
        local shopId
        if not adGotoParam[3] then
            Log.error("找策划 广告跳转类型为0 但gotoParam没配shopid")
        else
            shopId = adGotoParam[3]
        end
        param = {
            [1] = ShopGotoType.OpenShopConfirm,
            [2] = adGotoParam[1], -- mainTabType
            [3] = adGotoParam[2] -- subTabType
        }
        -- 第三个起要开始排序
        param[4] = shopId
    elseif adGotoType == ShopGotoType.SortGoods then -- 1跳转到指定页面且目标商品处于页面中的首个商品位，若有多个则依次往后排。
        param = {
            [1] = ShopGotoType.SortGoods,
            [2] = adGotoParam[1], -- mainTabType
            [3] = adGotoParam[2] -- subTabType
        }
        -- 第三个起要开始排序
        local shopIds = {}
        for i = 3, #adGotoParam do
            if adGotoParam[i] then
                shopIds[adGotoParam[i]] = 1
            end
        end
        param[4] = shopIds
    elseif adGotoType == ShopGotoType.OpenTab then -- 2跳转到商品默认页面
        param = {
            [1] = ShopGotoType.OpenTab,
            [2] = adGotoParam[1], -- mainTabType
            [3] = adGotoParam[2] -- subTabType
        }
    end

    -- ShowInSkinsTab -> 在皮肤页签中显示
    if adGotoType == ShopGotoType.OpenShopConfirm then
        local shopId = param[4]
        local cfgv = Cfg.cfg_shop_giftmarket_goods[shopId]
        if cfgv ~= nil and cfgv.ShowInSkinsTab then
            param[2] = ShopMainTabType.Skins
        end
    end

    controller:ShowTab(param)
end

function UIShopRecommendTab:SetBoxHeight(str)
    ---@type UIShopController
    local owner = self:RootUIOwner()
    if owner then
        owner:SetBoxHeight(str)
    end
end

-- function UIShopRecommendTab:InitInteractWord()
--     --交互台词
--     self.interactWords = string.split(StringTable.Get("str_shop_interact_wel_word"), "|")
--     self.stack = Stack:New()
-- end

-- function UIShopRecommendTab:GetInteractWord()
--     if self.stack:Size() <= 0 then
--         local count = 0
--         local all = #self.interactWords
--         while count < all do
--             local index = math.random(1, all)
--             if not self.stack:Contains(index) then
--                 self.stack:Push(index)
--                 count = count + 1
--             end
--         end
--     end
--     return self.interactWords[self.stack:Pop()]
-- end

function UIShopRecommendTab:btnleftOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    local index = self.index
    if self.index == 1 then
        index = table.count(self.recommendDatas)
    else
        index = index - 1
    end
    self:OnClickTabBtn(index, true)
end

function UIShopRecommendTab:btnrightOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    self:TurnRight()
end

function UIShopRecommendTab:TurnRight()
    local index = self.index
    if self.index == table.count(self.recommendDatas) then
        index = 1
    else
        index = index + 1
    end
    self:OnClickTabBtn(index, true)
end

function UIShopRecommendTab:MovePanelToIndex(index, leftIdx,duration)
    local _d = 0.5
    if duration then
        _d = duration
    end
    local movePos = (leftIdx - 1) * (-252 - 7.8)
    if self._contentTweener then
        self._contentTweener:Kill(true)
    end
    self._contentTweener =
        self.iconTglTrans:DOAnchorPosX(movePos, _d):OnComplete(
        function()
            self.iconTglTrans.anchoredPosition = Vector2(movePos, self.iconTglTrans.anchoredPosition.y)

            if index == 1 or index == table.count(self.recommendDatas) or true then
                local targetX = self.allIconToggle[index]:GetGameObject().transform.position.x
                local y = self.chooseTrans.position.y
                self.chooseTrans.position = Vector3(targetX, y, 0)
            end
        end
    )

    -- if index > 5 then
    --     local offset = (index - 5) * (-252 - 7.8)
    --     self.iconTglTrans:DOLocalMoveX(offset, 1):OnComplete(
    --         function()
    --         end
    --     )
    -- else
    --     self.iconTglTrans.localPosition = Vector3.zero
    --     local targetX = self.allIconToggle[1]:GetGameObject().transform.position.x
    --     local y = self.chooseTrans.position.y
    --     self.chooseTrans.position = Vector3(targetX, y, 0)
    -- end
end
