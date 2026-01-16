--[[
    商城一级页签按钮
]]
---@class UIShopMainTabBtn:UICustomWidget

_class("UIShopMainTabBtn", UICustomWidget)
UIShopMainTabBtn = UIShopMainTabBtn

function UIShopMainTabBtn:OnShow()
    self._active = true
    self.tgl = self:GetUIComponent("Toggle", "toggle")
    self.tglTrans = self:GetUIComponent("Transform", "toggle")

    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.enNameTxt = self:GetUIComponent("UILocalizationText", "enname")
    self.picGO = self:GetGameObject("pic")
    self.iconImg = self:GetUIComponent("Image", "icon")
    self.iconGO = self:GetGameObject("icon")
    self.pointGO = self:GetGameObject("point")
    self.chooseCG = self:GetUIComponent("CanvasGroup", "choose")
    self.lock = self:GetGameObject("lock")
    self.atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    local etl = UICustomUIEventListener.Get(self.picGO)
    self:AddUICustomEventListener(
        etl,
        UIEvent.Press,
        function(go)
            -- self.iconImg.sprite = self.atlas:GetSprite(self.shopMainTabData:GetSelectIcon())
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(go)
            -- self.iconImg.sprite = self.atlas:GetSprite(self.shopMainTabData:GetIcon())
        end
    )
    self.recommendGO = self:GetGameObject("g_recommend")
    self.secretGO = self:GetGameObject("g_secret")
    self.exchangeGO = self:GetGameObject("g_exchange")
    self.rechargeGO = self:GetGameObject("g_charge")
    self.giftGO = self:GetGameObject("g_gift")
    self.skinGO = self:GetGameObject("g_skin")
    self.homelandGO = self:GetGameObject("g_homeland")
    self._redpoint = self:GetGameObject("redpoint")
    self._redpoint:SetActive(false)
    self.imgNew = self:GetGameObject("imgNew")
    self.imgNew:SetActive(false)
    self:AttachEvent(GameEventType.CheckMonthCardRedpoint, self._CheckMonthCardRedpoint)
    self:AttachEvent(GameEventType.ForceShowMainTabBtn, self._ForceShowMainTabBtn)
    -- self:AttachEvent(GameEventType.SeniorSkinHideTip, self.hideSeniorSkinTip)
end

function UIShopMainTabBtn:DoAnimation()
    self.tglTrans.localScale = Vector3.one
    self.chooseCG.alpha = 0
    self.chooseCG:DOFade(1, 0.2):SetEase(DG.Tweening.Ease.Linear)
    self._tweener =
        self.tglTrans:DOScale(Vector3(0.95, 0.95, 1), 0.1):SetEase(DG.Tweening.Ease.Linear):OnComplete(
        function()
            self.tglTrans:DOScale(Vector3.one, 0.1):SetEase(DG.Tweening.Ease.Linear)
        end
    )
end

function UIShopMainTabBtn:OnHide()
    if self._tweener then
        self._tweener:Kill(false)
        self._tweener = nil
    end
    self.imgNewShop = nil
    self._active = false
end

---@param shopMainTabData DShopMainTab
function UIShopMainTabBtn:Init(shopMainTabData, tglGroup, onClickTabBtn, param)
    ---@type DShopMainTab
    self.shopMainTabData = shopMainTabData
    self.tgl.group = tglGroup
    self.tgl.isOn = false
    self.onClickTabBtn = onClickTabBtn
    self.param = param

    self.nameTxt:SetText(self.shopMainTabData:GetName())
    self.enNameTxt:SetText(self.shopMainTabData:GetEnName())

    if not self.shopMainTabData:IsOpen() then
        self.lock:SetActive(true)
        self.nameTxt.color = Color(1, 1, 1, 56 / 255)
    end
    self:_Select(self.shopMainTabData:GetMainTab())
    self:_CheckMonthCardRedpoint()

    -- self:checkSeniorSkin()
end

function UIShopMainTabBtn:_Select(mainType)
    self.iconGO:SetActive(false)
    self.recommendGO:SetActive(mainType == ShopMainTabType.Recommend)
    self.secretGO:SetActive(mainType == ShopMainTabType.Secret)
    self.rechargeGO:SetActive(mainType == ShopMainTabType.Recharge)
    self.giftGO:SetActive(mainType == ShopMainTabType.Gift)
    self.exchangeGO:SetActive(mainType == ShopMainTabType.Exchange)
    self.skinGO:SetActive(mainType == ShopMainTabType.Skins)
    self.homelandGO:SetActive(mainType == ShopMainTabType.Homeland)
end
function UIShopMainTabBtn:Select(select, first)
    self.tgl.isOn = select
    if select then
        -- if self._showSeniorSkin then
        --     local now = math.floor(GameGlobal.GetModule(SvrTimeModule):GetServerTime() * 0.001)
        --     local dbKey = "SeniorSkinShopOpenTime_" .. GameGlobal.GameLogic():GetOpenId()
        --     LocalDB.SetInt(dbKey, now)
        --     self:showSeniorSkin(false)
        -- end
        self.iconGO:SetActive(true)
        self.iconImg.sprite = self.atlas:GetSprite(self.shopMainTabData:GetSelectIcon())
        if not first then
            self:DoAnimation()
        end
    else
        self:_Select(self.shopMainTabData:GetMainTab())
        self.tglTrans.localScale = Vector3.one
        self.chooseCG.alpha = 1
        self.chooseCG:DOFade(0, 0.2):SetEase(DG.Tweening.Ease.Linear)
    end
end
function UIShopMainTabBtn:picOnClick(go)
    if not self.shopMainTabData:IsOpen() then
        --ToastManager.ShowToast(StringTable.Get("str_shop_main_tab_lock"))
        ToastManager.ShowLockTip()
    else
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        self.onClickTabBtn(self.param, self.shopMainTabData:GetMainTab())
    end
end
function UIShopMainTabBtn:GetTabType()
    return self.shopMainTabData:GetMainTab()
end
function UIShopMainTabBtn:CheckSkinTabHide()
    if self:GetTabType() == ShopMainTabType.Skins then -- 时装 判定是否显示
        local shopModule = self:GetModule(ShopModule)
        local clientShop = shopModule:GetClientShop()
        ---@type SkinsShopData
        local skinsData = clientShop:GetSkinsShopData()
        if skinsData then
            if skinsData:IsEmpty() then
                self:GetGameObject():SetActive(false) --隐藏自己
            end
        else
            self:GetGameObject():SetActive(false) --隐藏自己
        end
    end
end

--家园商店是否显示
function UIShopMainTabBtn:CheckHomelandTabHide()
    ---@type HomelandModule
    local homelandModule = GameGlobal.GetModule(HomelandModule)
    local unlock = homelandModule:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_SHOP_ARC_UI)
    self:GetGameObject():SetActive(unlock)
end

function UIShopMainTabBtn:_CheckMonthCardRedpoint()
    if self:GetTabType() == ShopMainTabType.Gift then
        local shopModule = GameGlobal.GetModule(ShopModule)
        local show,tips,  day = shopModule:ShowMonthCardRedPoint()
        self._redpoint:SetActive(show)
    end
end
function UIShopMainTabBtn:_ForceShowMainTabBtn(mainTabType)
    if self:GetTabType() == mainTabType then
        self:GetGameObject():SetActive(true)
    end
end

function UIShopMainTabBtn:FlushNew(isShow)
    if self.imgNew then
        self.imgNew:SetActive(isShow)
    end
end

-- function UIShopMainTabBtn:checkSeniorSkin()
--     if self.shopMainTabData:GetMainTab() == ShopMainTabType.Skins then
--         self:StartTask(self.getSeniorSkin, self)
--     end
-- end

-- function UIShopMainTabBtn:getSeniorSkin(TT)
--     self._showSeniorSkin = false

--     local campaign = UIActivityCampaign:New()
--     local res = AsyncRequestRes:New()
--     res:SetSucc(true)
--     campaign:LoadCampaignInfo(
--         TT,
--         res,
--         ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN,
--         ECampaignSeniorSkinComponentID.ECAMPAIGN_SENIOR_SKIN
--     )

--     if not self._active then
--         return
--     end

--     ---@type SeniorSkinComponent
--     local cpt = campaign:GetLocalProcess()._seniorSkinComponent

--     if res:GetSucc() then
--         if campaign:CheckCampaignOpen() and not cpt:AllAwardCollected() then
--             local dbKey = "SeniorSkinShopOpenTime_" .. GameGlobal.GameLogic():GetOpenId()
--             local saveTime = LocalDB.GetInt(dbKey, 0)
--             if saveTime > 0 then
--                 if HelperProxy:GetInstance():IsCrossDayTo(saveTime) then
--                     --跨天了
--                     Log.debug("[SeniorSkin]高级皮肤活动开启，跨天打开主界面")
--                     self:showSeniorSkin(true)
--                     return
--                 end
--             else
--                 Log.debug("[SeniorSkin]高级皮肤活动开启，未点击过商店")
--                 self:showSeniorSkin(true) --首次打开
--                 return
--             end
--         end
--     end
--     self:showSeniorSkin(false)
-- end

-- function UIShopMainTabBtn:showSeniorSkin(show)
--     local go = self:GetGameObject("SeniorSkinTip")
--     if show then
--         if not self._seniorSkin then
--             local pool = self:GetUIComponent("UISelectObjectPath", "SeniorSkinTip")
--             ---@type UICampaignSeniorSkinLable
--             self._seniorSkin = pool:SpawnObject("UICampaignSeniorSkinLable")
--         end
--     end
--     go:SetActive(show)
--     self._showSeniorSkin = show
-- end

-- function UIShopMainTabBtn:hideSeniorSkinTip()
--     self:showSeniorSkin(false)
-- end
