---@class UIMainLobbyBtnShop:UICustomWidget
_class("UIMainLobbyBtnShop", UICustomWidget)
UIMainLobbyBtnShop = UIMainLobbyBtnShop

function UIMainLobbyBtnShop:OnShow()
    self._active = true
    self.shopBtnBg = self:GetGameObject("shopBtnBg")
    self._shopImg = self:GetUIComponent("Image", "shopImg")
    self._shopBtn = self:GetUIComponent("Button", "btnShop")
    self._shopBtnPool = self:GetUIComponent("UISelectObjectPath", "btnShop")
    self._storeNameEnLabel = self:GetUIComponent("UILocalizationText", "nameEn")
    self._storeNameChLabel = self:GetUIComponent("UILocalizationText", "name")
    -- self._imgNewSeniorSkin = self:GetGameObject("imgNewSeniorSkin")
    self._shopRedpoint = self:GetGameObject("ShopRedpoint")
    self.imgNewShop = self:GetGameObject("imgNewShop")
    self._atlas = self:GetAsset("UIMainLobby.spriteatlas", LoadType.SpriteAtlas) --公共图集，动态静态

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._shopBtn.gameObject),
        UIEvent.Press,
        function(go)
            self._shopImg.sprite = self._atlas:GetSprite("main_zjm_icon27")
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._shopBtn.gameObject),
        UIEvent.Release,
        function(go)
            self._shopImg.sprite = self._atlas:GetSprite("main_zjm_icon26")
        end
    )

    self:AttachEvent(GameEventType.CheckMonthCardRedpoint, self.FlushMonthCardRedpoint)
    self:AttachEvent(GameEventType.ShopNew, self.CoFlushNew)
    -- self:AttachEvent(GameEventType.SeniorSkinHideTip, self.hideSeniorSkinTip)

    self.mRedDot = GameGlobal.GetModule(RedDotModule)
    self.mRedDot:ListenRedDot({[RedDotType.RDT_SHOP_HOMEPAGE_NEW] = GameEventType.ShopNew})

    self.mShop = GameGlobal.GetModule(ShopModule)
    self:Flush()
end

function UIMainLobbyBtnShop:OnHide()
    self:RemoveAllCustomEventListener()
    self:DetachEvent(GameEventType.CheckMonthCardRedpoint, self.FlushMonthCardRedpoint)
    self:DetachEvent(GameEventType.ShopNew, self.CoFlushNew)
    self.mRedDot:UnListenRedDot({RedDotType.RDT_SHOP_HOMEPAGE_NEW})
    self.imgNewShop = nil
    self._active = false
end

function UIMainLobbyBtnShop:Flush()
    self:FlushMonthCardRedpoint() --月卡红点
    self:CoFlushNew()
    --删除高级时装提示
    -- self:StartTask(self.getSeniorSkin, self)
end

function UIMainLobbyBtnShop:FlushLockStatus()
    --获取功能解锁的数据
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Shop)
    self.shopBtnBg:SetActive(not isLock)
    --商店
    ---@type UIFunctionLockButton
    local shopButtonFunction = self._shopBtnPool:SpawnObject("UIFunctionLockButton")
    shopButtonFunction:SetFunctionType(
        GameModuleID.MD_Shop,
        ButtonLockType.MaskAndTips,
        nil,
        MaskShowType.Small,
        function()
            self._storeNameEnLabel.color = Color(1, 1, 1, 0.08)
            self._storeNameChLabel.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
            self._shopImg.color = Color(79 / 255, 79 / 255, 79 / 255, 1)
        end, --lock
        function()
            self._storeNameEnLabel.color = Color(1, 1, 1, 55 / 255)
            self._storeNameChLabel.color = Color(1, 1, 1, 1)
            self._shopImg.color = Color(1, 1, 1, 1)
        end --unlock
    )
end

function UIMainLobbyBtnShop:FlushMonthCardRedpoint()
    local show,tips, day = self.mShop:ShowMonthCardRedPoint()
    self._shopRedpoint:SetActive(show)
end

function UIMainLobbyBtnShop:CoFlushNew()
    local limitedTimeRechargeOpen = self:GetUIModule(SignInModule):CheckEventOpen(CommonEventType.LimitedTimeRecharge)
    if limitedTimeRechargeOpen then
        local localDbKey = "LimitedTimeRechargeRead"..self:GetModule(RoleModule):GetPstId()
        if not LocalDB.HasKey(localDbKey) then
            -- 如果限时充值活动开启并且未查看过信息 显示new标签
            self.imgNewShop:SetActive(true)
            return
        end
    end

    self:StartTask(
        function(TT)
            local res = self.mRedDot:RequestRedDotStatus(TT, {RedDotType.RDT_SHOP_HOMEPAGE_NEW})
            if not self.imgNewShop then
                return
            end
            if res and res[RedDotType.RDT_SHOP_HOMEPAGE_NEW] then
                self.imgNewShop:SetActive(true)
            else
                local showNew = self.mShop:GetHomelandShopTabNew()
                showNew = showNew or self.mShop:GetHomelandRechargeTabNew()
                self.imgNewShop:SetActive(showNew)
            end
        end,
        self
    )
end

--商店
function UIMainLobbyBtnShop:btnShopOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_ShopController"}, true)
    --获取功能解锁的数据
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Shop)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_SHOP)
        end
    )
    ClientShop.OpenShop(nil,nil,nil,nil,true)

    -- if self._showSeniorSkin then
    --     local now = math.floor(GameGlobal.GetModule(SvrTimeModule):GetServerTime() * 0.001)
    --     local dbKey = "SeniorSkinLobbyOpenTime_" .. GameGlobal.GameLogic():GetOpenId()
    --     LocalDB.SetInt(dbKey, now)
    --     self:showSeniorSkin(false)
    -- end
end

-- function UIMainLobbyBtnShop:hideSeniorSkinTip()
--     self:showSeniorSkin(false)
-- end

-- function UIMainLobbyBtnShop:showSeniorSkin(show)
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

-- function UIMainLobbyBtnShop:getSeniorSkin(TT)
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
--             local dbKey = "SeniorSkinLobbyOpenTime_" .. GameGlobal.GameLogic():GetOpenId()
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
