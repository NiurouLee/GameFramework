--[[
    抽卡确认弹窗
    包含两种样式
]]
---@class UIRecruitConfirm : UIController
_class("UIRecruitConfirm", UIController)
UIRecruitConfirm = UIRecruitConfirm
local ConfirmType = {
    InValid = 1,              --无效
    FreeSingle = 2,           --免费单抽
    FreeTen = 3,              --免费十连
    XbEnough = 4,             --星标足够
    Gp2Xb = 5,                --光珀兑换星标后足够
    Yj2Gp2Xb = 6,             --耀晶->光珀->星标
    GpEnough = 7,             --光珀足够
    Yj2Gp = 8,                --耀晶->光珀
    CustomItemEnough = 9,     --自定义材料足够
    CustomItemNotEnough = 10, --自定义材料不足
    NotEnough = 99,           --啥材料都不够
}
---@param res AsyncRequestRes
function UIRecruitConfirm:LoadDataOnEnter(TT, res, uiParams)
    res:SetSucc(true)
    ---@type UIDrawCardPoolInfo
    local data = uiParams[1]
    ---@type ShakeType
    local type = uiParams[2]

    local isSingle = type == ShakeType.SHAKE_ONCE
    local shop = GameGlobal.GetModule(ShopModule):GetClientShop()

    local drawCount = 1
    if not isSingle then
        drawCount = 10
    end

    if type == ShakeType.SHAKE_ONCE then
        local freeCount = data:GetFreeCount_Single()
        if freeCount and freeCount > 0 then
            --免费单抽
            self._confirmType = ConfirmType.FreeSingle
            self._ctx = { freeCount } --上下文数据 不同类型有不同数据
            return
        end
    elseif type == ShakeType.SHAKE_MULTIPLE then
        local info = data.poolData
        if info.close_type == PrizePoolOpenCloseType.PLAY_TIMES_CONDITON then
            if info.extend_data < info.multiple_shake_times then
                Log.info("剩余次数不足以多抽,不处理")
                self._confirmType = ConfirmType.InValid
                res:SetSucc(false)
                return
            end
        end

        local freeCount = data:GetFreeCount_Multi()
        if freeCount and freeCount > 0 then
            --免费十连
            self._confirmType = ConfirmType.FreeTen
            self._ctx = { freeCount }
            return
        end
    end

    local costItem
    if type == ShakeType.SHAKE_ONCE then
        costItem = data.singleMat
    elseif type == ShakeType.SHAKE_MULTIPLE then
        costItem = data.multipleMat
    end
    local p, discountPrice, d, m = data:GetAssetsPrice(isSingle)
    local costXB, xbId = data:IsCostXB(isSingle)

    if costXB then
        local isEnoughXB, diffXB = data:IsXBEnough(discountPrice, isSingle)
        if isEnoughXB then
            --星标足够，开抽
            self._confirmType = ConfirmType.XbEnough
            self._ctx = { costItem, discountPrice } --物品id和价格
            return
        else
            local cfgv, goodsId = ClientShop.GetXBCfg(xbId)
            local xbPrice = cfgv[ConfigKey.ConfigKey_NowPrice]
            local costGP = diffXB * xbPrice --兑换成光珀
            local isEnoughGP, diffGP = data:IsGPEnough(costGP)
            if isEnoughGP then
                self._confirmType = ConfirmType.Gp2Xb
                self._ctx = { costItem, costGP, diffXB } --星标id 需要的光珀数量 转化成的星标数量
                return
            else
                local yj2gpRate = shop:GetDiamondExchangeGlowRate()
                local costYJ = math.ceil(diffGP / yj2gpRate)
                local isEnoughYJ, diffYJ = data:IsYJEnough(costYJ)
                if isEnoughYJ then
                    local buyGP = costYJ * yj2gpRate
                    self._confirmType = ConfirmType.Yj2Gp2Xb
                    self._ctx = { costItem, costYJ, buyGP, diffXB } --星标id 耀晶数量 光珀数量 星标数量
                    return
                else
                    --啥都没有
                    if EngineGameHelper.EnableAppleVerifyBulletin() then
                        -- 审核服环境
                        ToastManager.ShowToast(StringTable.Get("str_pay_yj_not_enough_cant_exchange"))
                        res:SetSucc(false)
                        self._confirmType = ConfirmType.InValid
                        return
                    else
                        self._confirmType = ConfirmType.NotEnough
                        return
                    end
                end
            end
        end
    elseif data:IsCostGp(isSingle) then
        --光珀足够，开抽
        local isEnoughGP, diffGP = data:IsGPEnough(discountPrice)
        if isEnoughGP then
            self._confirmType = ConfirmType.GpEnough
            self._ctx = { costItem, discountPrice }
            return
        else
            local yj2gpRate = shop:GetDiamondExchangeGlowRate()
            local costYJ = math.ceil(diffGP / yj2gpRate)
            local isEnoughYJ, diffYJ = data:IsYJEnough(costYJ)
            if isEnoughYJ then
                local buyGP = costYJ * yj2gpRate
                self._confirmType = ConfirmType.Yj2Gp
                self._ctx = { costItem, costYJ, buyGP } --光珀id 耀晶数量 光珀数量
                return
            else
                --啥都没有
                if EngineGameHelper.EnableAppleVerifyBulletin() then
                    -- 审核服环境
                    ToastManager.ShowToast(StringTable.Get("str_pay_yj_not_enough_cant_exchange"))
                    res:SetSucc(false)
                    self._confirmType = ConfirmType.InValid
                    return
                else
                    self._confirmType = ConfirmType.NotEnough
                    return
                end
            end
        end
    else
        --花费除了两种星标和光珀之外的其他物品,默认没有第二个材料
        local count = GameGlobal.GetModule(ItemModule):GetItemCount(costItem)
        if count < discountPrice then
            self._confirmType = ConfirmType.CustomItemNotEnough
            self._ctx = { costItem } --材料id
            return
        else
            self._confirmType = ConfirmType.CustomItemEnough
            self._ctx = { costItem, discountPrice } --材料id 数量
            return
        end
    end
end

--初始化
function UIRecruitConfirm:OnShow(uiParams)
    self:InitWidget()
    ---@type UIDrawCardPoolInfo
    self._data = uiParams[1]
    ---@type ShakeType
    self._type = uiParams[2]
    self._poolID = self._data.poolData.prize_pool_id
    self._isSingle = self._type == ShakeType.SHAKE_ONCE

    if self._confirmType == ConfirmType.InValid then
        --不处理 应该直接退出
        self:CloseDialog()
    elseif self._confirmType == ConfirmType.FreeSingle then
        local count = self._ctx[1]
        self:_Enough(0, count, true, true)
        self._confirmCb = function()
            self:StartTask(self._RecruitDirectly, self, self._type, self._poolID, 0, count)
        end
    elseif self._confirmType == ConfirmType.FreeTen then
        local count = self._ctx[1]
        self:_Enough(0, count, true, false)
        self._confirmCb = function()
            self:StartTask(self._RecruitDirectly, self, self._type, self._poolID, 0, count)
        end
    elseif self._confirmType == ConfirmType.XbEnough then
        local id = self._ctx[1]
        local count = self._ctx[2]
        self:_Enough(id, count, false)
        self._confirmCb = function()
            self:StartTask(self._RecruitDirectly, self, self._type, self._poolID, id, count)
        end
    elseif self._confirmType == ConfirmType.Gp2Xb then
        local id = self._ctx[1]
        local gp = self._ctx[2]
        local xb = self._ctx[3]
        local drawCount = 1
        if not self._isSingle then
            drawCount = 10
        end
        local name = StringTable.Get(Cfg.cfg_item[id].Name)
        local strContent = StringTable.Get("str_pay_drawcard_gp_2_xb", gp, xb, name, drawCount, drawCount)
        self:_NotEnough(strContent)
        self._confirmCb = function()
            self:StartTask(self._Gp2Xb, self, id, gp, xb)
        end
    elseif self._confirmType == ConfirmType.Yj2Gp2Xb then
        local id = self._ctx[1]
        local yj = self._ctx[2]
        local gp = self._ctx[3]
        local xb = self._ctx[4]
        local drawCount = 1
        if not self._isSingle then
            drawCount = 10
        end
        local name = StringTable.Get(Cfg.cfg_item[id].Name)
        local strContent = StringTable.Get("str_pay_drawcard_yj_2_gp_2_xb", yj, gp, xb, name, drawCount, drawCount)
        self:_NotEnough(strContent)
        self._confirmCb = function()
            self:StartTask(self._Yj2Gp2Xb, self, id, yj, gp, xb)
        end
    elseif self._confirmType == ConfirmType.GpEnough then
        local id    = self._ctx[1]
        local count = self._ctx[2]
        self:_Enough(id, count, false)
        self._confirmCb = function()
            self:StartTask(self._RecruitDirectly, self, self._type, self._poolID, id, count)
        end
    elseif self._confirmType == ConfirmType.Yj2Gp then
        local id = self._ctx[1]
        local yj = self._ctx[2]
        local gp = self._ctx[3]
        local drawCount = 1
        if not self._isSingle then
            drawCount = 10
        end
        local strContent = StringTable.Get("str_pay_drawcard_yj_2_gp", yj, gp, drawCount, drawCount)
        self:_NotEnough(strContent)
        self._confirmCb = function()
            self:StartTask(self._Yj2Gp, self, id, yj, gp)
        end
    elseif self._confirmType == ConfirmType.CustomItemEnough then
        local id    = self._ctx[1]
        local count = self._ctx[2]
        self:_Enough(id, count, false)
        self._confirmCb = function()
            self:StartTask(self._RecruitDirectly, self, self._type, self._poolID, id, count)
        end
    elseif self._confirmType == ConfirmType.CustomItemNotEnough then
        local id = self._ctx[1]
        local name = StringTable.Get(Cfg.cfg_item[id].Name)
        local strContent = StringTable.Get("str_draw_card_special_expend_not_enough", name)
        self:_NotEnough(strContent)
        self._confirmCb = function()
            --打开商城礼包界面
            local viewID = self._data.poolData.performance_id
            local cfg = Cfg.cfg_drawcard_pool_view[viewID]
            if not cfg.GiftID then
                Log.exception("卡池表现配置中没有GiftID字段,ID:", viewID)
            end
            self:CloseDialog()
            self:ShowDialog("UIShopController", 2, 5, 0, cfg.GiftID)
        end
    elseif self._confirmType == ConfirmType.NotEnough then
        local strContent = StringTable.Get("str_pay_res_not_enough_goto_recharge") --资源不足，是否前往充值
        self:_NotEnough(strContent)
        self._confirmCb = function()
            self:CloseDialog()
            GameGlobal.GetModule(ShopModule):GetClientShop():OpenRechargeShop()
        end
    end
end

--获取ui组件
function UIRecruitConfirm:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.title = self:GetUIComponent("UILocalizationText", "title")
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UILocalizationText
    self.have = self:GetUIComponent("UILocalizationText", "have")
    ---@type UILocalizationText
    self.rest = self:GetUIComponent("UILocalizationText", "rest")
    ---@type UnityEngine.UI.Image
    self.confirmButton = self:GetUIComponent("Image", "ConfirmButton")
    ---@type UnityEngine.GameObject
    self.iconRoot = self:GetGameObject("iconRoot")
    ---@type UnityEngine.GameObject
    self.enoughTip = self:GetGameObject("EnoughTip")
    ---@type UnityEngine.GameObject
    self.msgBox = self:GetGameObject("MsgBox")
    ---@type UILocalizationText
    self.msgBoxText = self:GetUIComponent("UILocalizationText", "MsgBoxText")
    --generated end--
    self.otherRoot = self:GetUIComponent("RectTransform", "otherRoot")
end

function UIRecruitConfirm:_Enough(itemId, itemCount, free, isSingleFree)
    self.enoughTip:SetActive(true)
    self.msgBox:SetActive(false)

    local cfg = Cfg.cfg_item[itemId]
    local ss
    if free then
        if isSingleFree then
            ss = StringTable.Get("str_draw_card_cost_free")
        else
            ss = StringTable.Get("str_draw_card_cost_freeten")
        end
    else
        local heartstoneCount = 1
        local drawCount = 1
        if self._type == ShakeType.SHAKE_MULTIPLE then
            heartstoneCount = 10
            drawCount = 10
        end
        ss = StringTable.Get("str_draw_card_cost_to_draw", itemCount, StringTable.Get(cfg.Name), heartstoneCount,
            drawCount)
    end
    self.title:SetText(ss)

    self.iconRoot:SetActive(not self.free)
    local otherRootPosX = 0
    --白嫖
    if free then
        otherRootPosX = -75
        local freeCount = itemCount
        --一次抽一次
        local lessCount = freeCount - 1
        self.have:SetText(freeCount)
        self.rest:SetText(lessCount)
    else
        local had = self:GetModule(RoleModule):GetAssetCount(itemId)
        local rest = had - itemCount
        if had > 99999 then
            had = "99999+"
        end
        if rest > 99999 then
            rest = "99999+"
        end
        self.have:SetText(had)
        self.rest:SetText(rest)
        self.icon:LoadImage(cfg.Icon)
    end
    self.otherRoot.anchoredPosition = Vector2(otherRootPosX, 0)
end

function UIRecruitConfirm:_NotEnough(text)
    self.enoughTip:SetActive(false)
    self.msgBox:SetActive(true)

    self.msgBoxText:SetText(text)
end

--按钮点击
function UIRecruitConfirm:ConfirmButtonOnClick(go)
    if self._confirmCb then
        self._confirmCb()
    end
end

--按钮点击
function UIRecruitConfirm:CancelButtonOnClick(go)
    self:CloseDialog()
end

--按钮点击
function UIRecruitConfirm:MsgBoxOKOnClick(go)
    if self._confirmCb then
        self._confirmCb()
    end
end

--按钮点击
function UIRecruitConfirm:MsgBoxCancelOnClick(go)
    self:CloseDialog()
end

--耀晶>光珀>星标>抽卡
function UIRecruitConfirm:_Yj2Gp2Xb(TT, costMat, yaojing, guangpo, xingbiao)
    self:Lock("RequestYJ2GP2XB")
    local mShop = GameGlobal.GetModule(ShopModule)
    local guangpoRet = mShop:ApplyDiamondExchangeGlow(TT, yaojing, guangpo)
    if ClientShop.CheckShopCode(guangpoRet:GetResult()) then
        local cfgv, goodsId = ClientShop.GetXBCfg(costMat)
        local sale_tpye = cfgv[ConfigKey.ConfigKey_SaleType]
        local price = cfgv[ConfigKey.ConfigKey_NowPrice]
        local xingbiaoRet = mShop:BuyItem(TT, MarketType.Shop_GuangPo, goodsId, xingbiao, sale_tpye, price)
        if ClientShop.CheckShopCode(xingbiaoRet) then
            local p, discountPrice, d, m = self._data:GetAssetsPrice(self._isSingle)
            --前面处理过 材料足够 开始抽卡
            self:_RequestDrawcard(TT, self._type, self._data.poolData.prize_pool_id, costMat, discountPrice)
        else
            Log.error("耀晶兑换光珀后，再兑换星标失败:", xingbiaoRet)
        end
    else
        Log.error("耀晶兑换光珀失败:", guangpoRet:GetResult())
    end
    self:UnLock("RequestYJ2GP2XB")
    self:CloseDialog()
end

function UIRecruitConfirm:_Gp2Xb(TT, costMat, guangpo, xingbiao)
    local cfgv, goodsId = ClientShop.GetXBCfg(costMat)
    if not cfgv then
        return
    end
    local sale_tpye = cfgv[ConfigKey.ConfigKey_SaleType]
    local price = cfgv[ConfigKey.ConfigKey_NowPrice]
    local mShop = GameGlobal.GetModule(ShopModule)
    self:Lock("RequestGP2XB")
    local ret = mShop:BuyItem(TT, MarketType.Shop_GuangPo, goodsId, xingbiao, sale_tpye, price)
    self:UnLock("RequestGP2XB")
    if ClientShop.CheckShopCode(ret) then
        local p, discountPrice, d, m = self._data:GetAssetsPrice(self._isSingle)
        --前面处理过 材料足够 开始抽卡
        self:_RequestDrawcard(TT, self._type, self._data.poolData.prize_pool_id, costMat, discountPrice)
    else
        Log.fatal("### RequestGP2XB failed.", guangpo, xingbiao, ret)
    end
    self:CloseDialog()
end

function UIRecruitConfirm:_Yj2Gp(TT, costMat, yaojing, guangpo)
    local mShop = GameGlobal.GetModule(ShopModule)
    self:Lock("RequestYJ2GP")
    local ret = mShop:ApplyDiamondExchangeGlow(TT, yaojing, guangpo)
    self:UnLock("RequestYJ2GP")
    if ClientShop.CheckShopCode(ret:GetResult()) then
        local p, discountPrice, d, m = self._data:GetAssetsPrice(self._isSingle)
        --前面处理过 材料足够 开始抽卡
        self:_RequestDrawcard(TT, self._type, self._data.poolData.prize_pool_id, costMat, discountPrice)
    else
        Log.fatal("### ApplyDiamondExchangeGlow failed.", yaojing, guangpo, ret:GetResult())
    end
    self:CloseDialog()
end

--材料足够 直接抽卡
function UIRecruitConfirm:_RecruitDirectly(TT, drawType, poolID, itemID, itemCount)
    self:_RequestDrawcard(TT, drawType, poolID, itemID, itemCount)
    self:CloseDialog()
end

--请求抽卡
function UIRecruitConfirm:_RequestDrawcard(TT, drawType, poolID, itemID, itemCount)
    if SDKProxy:GetInstance():IsInlandSDK() then
        local ready = false
        GameGlobal.EventDispatcher():Dispatch(GameEventType.WaitForRecuitSceneLoadFinish,
            function()
                ready = true
            end
        )
        self:Lock("WaitRecruitScene")
        while not ready do
            YIELD(TT)
        end
        self:UnLock("WaitRecruitScene")
    end
    self:Lock("StartDrawCard")
    local module = GameGlobal.GetModule(GambleModule)
    local petModule = GameGlobal.GetModule(PetModule)
    petModule:GetAllPetsSnapshoot() --抽卡前临时保存所有当前星灵id列表快照
    module:Context():SetHaveMaxStarPet(petModule:GetMaxStarResult())
    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = GameGlobal.GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(true)

    local ack, cards, duplicateTags, fixed_reward = module:Shake(TT, drawType, poolID, itemID, itemCount)
    self:UnLock("StartDrawCard")
    if ack:GetSucc() then
        if cards == nil or #cards == 0 then
            Log.fatal("[DrawCard] cards result is empty!")
            return
        end
        Log.notice("[DrawCard] draw card success, count: ", #cards)
        local viewData = UIDrawCardViewData:New(cards, duplicateTags, drawType, poolID, fixed_reward)
        module:Context():SetStateDrawCard(true)
        self:ShowDialog("UIDrawCardAnimController", viewData)
    else
        --锁住成就弹窗先
        ---@type UIFunctionLockModule
        local funcModule = GameGlobal.GetModule(RoleModule).uiModule
        funcModule:LockAchievementFinishPanel(false)
        ToastManager.ShowToast(module:GetReasonByErrorCode(ack:GetResult()))
        Log.error("抽卡失败:", ack:GetResult())
    end
    --刷新抽卡界面数据
    local ack2 = module:ApplyAllPoolInfo(TT)
    if ack2:GetSucc() then
        Log.notice("[DrawCard] get draw card data success, open ui")
    else
        Log.notice("[DrawCard] promotion time up, refresh pools failed")
        ToastManager.ShowToast(module:GetReasonByErrorCode(ack2:GetResult()))
    end
    --更新一次光珀商店数据
    local shopModule = GameGlobal.GetModule(ShopModule)
    shopModule:RequestGlowMarket(TT)

    local module = GameGlobal.GetModule(GambleModule)
    module:Context():SetDefaultPoolIndex(self._data.index) --抽奖后，总是将当前级奖池的索引暂存到Module中，以便回到抽卡主界面时选中上次抽奖的卡池
    module:Context():SetPoolID(self._data.poolData.performance_id)
    module:Context():SetPoolType(self._data.poolData.prize_pool_type)
end
