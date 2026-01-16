---抽卡
---@class StateAssetExchangeDrawCard : State
_class("StateAssetExchangeDrawCard", State)
StateAssetExchangeDrawCard = StateAssetExchangeDrawCard

function StateAssetExchangeDrawCard:Init()
    self._fsm = self:GetFsm()
    ---@type UIDrawCardPoolItem
    self._ui = self._fsm:GetData()
    self._uiData = self._ui:GetUIData()

    self.clientShop = GameGlobal.GetModule(ShopModule):GetClientShop()
    self._data = self.clientShop:GetRechargeShopData()
end

function StateAssetExchangeDrawCard:OnEnter(TT, ...)
    self:Init()
    if not self._fsm then
        return
    end

    local isSingle = self._ui:GetIsSingle()
    local shakeType = ShakeType.SHAKE_MULTIPLE
    if isSingle then
        shakeType = ShakeType.SHAKE_ONCE
    end

    do
        GameGlobal.UIStateManager():ShowDialog("UIRecruitConfirm", self._uiData, shakeType)
        self._fsm:ChangeState(StateAssetExchange.Init)
        return
    end

    if not self._uiData then
        self._fsm:ChangeState(StateAssetExchange.Init)
        return
    end

    --是否是单抽，是否有免费次数
    if shakeType == ShakeType.SHAKE_ONCE then
        local freeCount = self._uiData:GetFreeCount_Single()
        if freeCount and freeCount > 0 then
            self:OpenUIDrawCardConfirm(0, freeCount, shakeType, true, true) --免费抽卡
            self._fsm:ChangeState(StateAssetExchange.Init)
            return
        end
    end

    --检查十连的免费次数
    if shakeType == ShakeType.SHAKE_MULTIPLE then
        local freeCount = self._uiData:GetFreeCount_Multi()
        if freeCount and freeCount > 0 then
            self:OpenUIDrawCardConfirm(0, freeCount, shakeType, true, false) --免费抽卡
            self._fsm:ChangeState(StateAssetExchange.Init)
            return
        end
    end

    local _, discountPrice, discount = self._uiData:GetAssetsPrice(isSingle)

    local FuncGP = function(diffGP, diffXB)
        local diamondExchangeGlowRate = self.clientShop:GetDiamondExchangeGlowRate()
        local costYJ = math.ceil(diffGP / diamondExchangeGlowRate)
        local isEnoughYJ, diffYJ = self._uiData:IsYJEnough(costYJ)
        if isEnoughYJ then
            local buyGP = costYJ * diamondExchangeGlowRate
            self._fsm:ChangeState(StateAssetExchange.Yj2Gp, costYJ, buyGP, diffXB)
        else
            self._fsm:ChangeState(StateAssetExchange.Recharge)
        end
    end

    --local assetId1, assetId2 = self._uiData:Get2AssetId()
    local costMat
    if isSingle then
        costMat = self._uiData.singleMat
    else
        costMat = self._uiData.multipleMat
    end

    local isCostXB, xbId = self._uiData:IsCostXB(isSingle)
    if isCostXB then
        local isEnoughXB, diffXB = self._uiData:IsXBEnough(discountPrice, isSingle)
        if isEnoughXB then
            self:OpenUIDrawCardConfirm(costMat, discountPrice, shakeType) --花星标抽卡
            self._fsm:ChangeState(StateAssetExchange.Init)
        else
            local cfgv, goodsId = ClientShop.GetXBCfg(xbId)
            if not cfgv then
                self._fsm:ChangeState(StateAssetExchange.Init)
                return
            end
            local xbPrice = cfgv[ConfigKey.ConfigKey_NowPrice]
            local costGP = diffXB * xbPrice
            local isEnoughGP, diffGP = self._uiData:IsGPEnough(costGP)
            if isEnoughGP then
                self._fsm:ChangeState(StateAssetExchange.Gp2Xb, costGP, diffXB, true)
            else
                FuncGP(diffGP, diffXB)
            end
        end
    elseif self._uiData:IsCostGp(isSingle) then
        local isEnoughGP, diffGP = self._uiData:IsGPEnough(discountPrice)
        if isEnoughGP then
            self:OpenUIDrawCardConfirm(costMat, discountPrice, shakeType) --花光珀抽卡
            self._fsm:ChangeState(StateAssetExchange.Init)
        else
            FuncGP(diffGP)
        end
    else
        --花费除了两种星标和光珀之外的其他物品,默认没有第二个材料
        local count = GameGlobal.GetModule(ItemModule):GetItemCount(costMat)
        if count < discountPrice then
            --打开商城礼包界面
            PopMsgBox(
                StringTable.Get("str_draw_card_special_expend_not_enough", StringTable.Get(Cfg.cfg_item[costMat].Name)),
                function()
                    local viewID = self._uiData:GetPoolViewID()
                    local cfg = Cfg.cfg_drawcard_pool_view[viewID]
                    if not cfg.GiftID then
                        Log.exception("卡池表现配置中没有GiftID字段,ID:", viewID)
                    end
                    GameGlobal.UIStateManager():ShowDialog("UIShopController", 2, 5, 0, cfg.GiftID)
                end
            )
            self._fsm:ChangeState(StateAssetExchange.Init)
        else
            self:OpenUIDrawCardConfirm(costMat, discountPrice, shakeType) --花光珀抽卡
            self._fsm:ChangeState(StateAssetExchange.Init)
        end
    end
end

function StateAssetExchangeDrawCard:OnExit(TT)
end

function StateAssetExchangeDrawCard:Destroy()
    self._fsm = nil
    self._ui = nil
    self._uiData = nil
end

---@param shakeType ShakeType
function StateAssetExchangeDrawCard:OpenUIDrawCardConfirm(assetId, price, shakeType, free, isSingle)
    local mGamble = GameGlobal.GetModule(GambleModule)
    mGamble:Context():SetDefaultPoolIndex(self._uiData.index) --开始抽奖前，总是将当前级奖池的索引暂存到Module中，以便回到抽卡主界面时选中上次抽奖的卡池
    mGamble:Context():SetPoolID(self._uiData.poolData.performance_id)
    mGamble:Context():SetPoolType(self._uiData.poolData.prize_pool_type)

    if not mGamble.hasShowNotIncluePedPoolTips then
        local times = mGamble:GetNotIncludePetPoolGambleTimes(self._uiData.index)
        local strTips = nil
        if times > 0 then
            --已经从未收录卡池中抽到
            strTips = StringTable.Get("str_draw_card_pop_has_get")
        elseif times == 0 then
            --未收录卡池中不存在
            local petList = mGamble:GetNotIncludePetPool(self._uiData.index)
            if not petList or #petList == 0 then
                strTips = StringTable.Get("str_draw_card_pop_has_all")
            end
        end

        if strTips then
            local strTitle = ""
            mGamble.hasShowNotIncluePedPoolTips = true
            PopupManager.Alert("UICommonMessageBox",
                PopupPriority.Normal, PopupMsgBoxType.OkCancel,
                strTitle,
                strTips,
                function()
                    GameGlobal.UIStateManager():ShowDialog(
                        "UIDrawCardConfirmController",
                        assetId,
                        price,
                        self._uiData.poolData.prize_pool_id,
                        shakeType,
                        free,
                        isSingle
                    )
                end)

            return
        end
    end


    GameGlobal.UIStateManager():ShowDialog(
        "UIDrawCardConfirmController",
        assetId,
        price,
        self._uiData.poolData.prize_pool_id,
        shakeType,
        free,
        isSingle
    )
end
