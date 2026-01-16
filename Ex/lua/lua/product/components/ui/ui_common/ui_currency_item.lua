--[[
    @通用货币栏item
]]
---@class UICurrencyItem:UICustomWidget
_class("UICurrencyItem", UICustomWidget)
UICurrencyItem = UICurrencyItem

function UICurrencyItem:OnShow()
    self.image = self:GetGameObject().transform:GetComponent("Image")
    self.icon = self:GetUIComponent("Image", "icon")
    self.iconGO = self.icon.transform.gameObject
    self.txt = self:GetUIComponent("UILocalizationText", "txt")
    self.txtRect = self:GetUIComponent("RectTransform", "txt")
    self.btnGO = self:GetGameObject("btn")
    self.switchGO = self:GetGameObject("switch")
    self.switchGO:SetActive(false)
    self.openGO = self:GetGameObject("opengo")
    self.closeGO = self:GetGameObject("closego")
    ---@type RoleModule
    self.roleModule = self:GetModule(RoleModule)
    self.atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self:AddListener()
end

function UICurrencyItem:OnHide()
    self:RemoveListener()
end

function UICurrencyItem:AddListener()
    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
    self:AttachEvent(GameEventType.DiamondCountChanged, self.OnItemCountChange)
end

function UICurrencyItem:RemoveListener()
    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
    self:DetachEvent(GameEventType.DiamondCountChanged, self.OnItemCountChange)
end

function UICurrencyItem:OnItemCountChange()
    self:RefreshTxt()
end

function UICurrencyItem:GetTypeId()
    return self._typeId
end

--设置为短款的样式，限时抽卡道具
function UICurrencyItem:SetAsShortForm(isShortForm)
    self._shortForm = isShortForm
end

---@param typeId RoleAssetID
function UICurrencyItem:SetData(typeId, iconClick, hideAddBtn)
    self._typeId = typeId
    self._hideAddBtn = hideAddBtn
    self._cfg = Cfg.cfg_top_tips[self._typeId]
    if not self._cfg then
        return
    end
    self._iconClick = iconClick
    self.icon.sprite = self.atlas:GetSprite(self._cfg.Icon)
    self:RefreshBg()
    self:RefreshTxtTransform()
    self:RefreshTxt()
end

function UICurrencyItem:ShowSwitch(show)
    if self.switchGO then
        self.switchGO:SetActive(false)
    end
end

function UICurrencyItem:ShowOpen(open)
    if open then
        self.openGO:SetActive(true)
        self.closeGO:SetActive(false)
    else
        self.openGO:SetActive(false)
        self.closeGO:SetActive(true)
    end
    if open then
        self.txt.color = Color.white
    else
        self.txt.color = Color.gray
    end
end

function UICurrencyItem:SetAddCallBack(addCallBack)
    self._addCallBack = addCallBack
end

function UICurrencyItem:SetBgCallBack(bgCallBack)
    self._bgCallBack = bgCallBack
end

function UICurrencyItem:SetSwitchCallBack(switchCallBack)
    self._switchCallBack = switchCallBack
end

-- [RoleAssetID.RoleAssetFirefly] = 1, -- 萤火
-- [CurrenyTypeId.StarPoint] = 2,
-- [CurrenyTypeId.Hp] = 3,
-- [RoleAssetID.RoleAssetDoubleRes] = 4, --资源本双倍券
-- [RoleAssetID.RoleAssetPhyPoint] = 5, -- 体力
-- [RoleAssetID.RoleAssetGold] = 6, -- 金币
-- [RoleAssetID.RoleAssetGlow] = 7, -- 光尘
-- [RoleAssetID.RoleAssetLight] = 8, -- 灯盏
-- [RoleAssetID.RoleAssetMazeCoin] = 9, --秘境币
-- [RoleAssetID.RoleAssetDrawCard100] = 10 --
function UICurrencyItem:RefreshTxtTransform()
    if self._typeId == RoleAssetID.RoleAssetDoubleRes then -- 双倍卷
        self.txtRect.anchoredPosition = Vector2( -17, 8)
    elseif self._shortForm then
        self.txtRect.anchoredPosition = Vector2(29, 8)
    else
        self.txtRect.anchoredPosition = Vector2(13.7, 8)
    end
end

function UICurrencyItem:RefreshTxt()
    local countStr
    if self._typeId == RoleAssetID.RoleAssetDiamond then --耀晶
        local mShop = self:GetModule(ShopModule)
        local count1, freeCount1 = mShop:GetDiamondCount()
        countStr = HelperProxy:GetInstance():Format9999W(count1)
    elseif self._typeId == RoleAssetID.RoleAssetGold then -- 金币
        countStr = HelperProxy:GetInstance():Format9999W(self.roleModule:GetGold())
    elseif self._typeId == RoleAssetID.RoleAssetGlow then -- 光尘
        countStr = HelperProxy:GetInstance():Format9999W(self.roleModule:GetGlow())
    elseif self._typeId == RoleAssetID.RoleAssetMazeCoin then -- 秘境代币
        countStr = HelperProxy:GetInstance():Format9999W(self.roleModule:GetMazeCoin())
    elseif self._typeId == RoleAssetID.RoleAssetPhyPoint then -- 体力
        local currentStr
        local upperStr
        local _currentPhysicalPower = self.roleModule:GetAssetCount(RoleAssetID.RoleAssetPhyPoint)
        local _upperPhysicalPower = self.roleModule:GetHpLevelMax()
        if _currentPhysicalPower > 9999 then
            currentStr = "9999+"
        else
            currentStr = _currentPhysicalPower .. ""
        end

        if _upperPhysicalPower > 9999 then
            upperStr = "9999+"
        else
            upperStr = _upperPhysicalPower .. ""
        end
        upperStr = "<color=#aeaeae>" .. upperStr .. "</color>"

        if _currentPhysicalPower > _upperPhysicalPower then
            currentStr = "<color=#00ffea>" .. currentStr .. "</color>"
        else
            currentStr = "<color=#ffffff>" .. currentStr .. "</color>"
        end
        countStr = currentStr .. "<color=#ffffff>/</color>" .. upperStr
    elseif self._typeId == RoleAssetID.RoleAssetDoubleRes then -- 双倍卷
        local resModule = self:GetModule(ResDungeonModule)
        local count = resModule:GetDoubleResNum()
        --
        local aircraftModule = self:GetModule(AircraftModule)
        local room = aircraftModule:GetResRoom()
        local maxCount = room and math.floor(room:GetResCardLimit()) or -1
        if count >= maxCount then
            --countStr = "<color=#ff0000>" .. HelperProxy:GetInstance():Format999(count) .. "/" .. maxCount .. "</color>"
            --MSG18542	【需测试】资源本上面双倍券数字打到上限颜色调整		小开发任务-待开发	李学森, 1958	03/04/2021
            countStr = "<color=#ffffff>" .. HelperProxy:GetInstance():Format999(count) .. "/" .. maxCount .. "</color>"
        else
            countStr = "<color=#ffffff>" .. count .. "/" .. maxCount .. "</color>"
        end
    elseif self._typeId == RoleAssetID.RoleAssetDrawCard100 then --抽卡卷100
        countStr =
            HelperProxy:GetInstance():Format9999W(self.roleModule:GetAssetCount(RoleAssetID.RoleAssetDrawCard100))
    elseif self._typeId == RoleAssetID.RoleAssetDrawCard101 then --抽卡卷101
        countStr =
            HelperProxy:GetInstance():Format9999W(self.roleModule:GetAssetCount(RoleAssetID.RoleAssetDrawCard101))
    elseif self._typeId == RoleAssetID.RoleAssetLight then -- 灯盏
        local resModule = self:GetModule(ResDungeonModule)
        countStr = HelperProxy:GetInstance():Format999(self.roleModule:GetAssetCount(RoleAssetID.RoleAssetLight))
    elseif self._typeId == RoleAssetID.RoleAssetXingZuan then -- 星钻
        ---@type ItemModule
        local itemMd = self:GetModule(ItemModule)
        countStr = HelperProxy:GetInstance():Format9999W(itemMd:GetItemCount(RoleAssetID.RoleAssetXingZuan))
    elseif self._typeId == RoleAssetID.RoleAssetHuiYao then -- 辉耀
        ---@type ItemModule
        local itemMd = self:GetModule(ItemModule)
        countStr = HelperProxy:GetInstance():Format9999W(itemMd:GetItemCount(RoleAssetID.RoleAssetHuiYao))
    elseif self._typeId == CurrenyTypeId.StarPoint then
        countStr = nil --不处理
    elseif self._typeId == RoleAssetID.RoleAssetFirefly then
        countStr = nil --不处理
    elseif self._typeId == RoleAssetID.RoleAssetAtom then
        countStr = nil --不处理
    elseif self._typeId == RoleAssetID.RoleAssetActiveToken then --活动回顾代币
        local max = Cfg.cfg_global["ActiveReviewTokenMax"].IntValue
        local count = self:GetModule(ItemModule):GetItemCount(self._typeId)
        countStr = count .. "/" .. max
    else
        ---@type ItemModule
        local itemMd = self:GetModule(ItemModule)
        countStr = HelperProxy:GetInstance():Format9999W(itemMd:GetItemCount(self._typeId))
    end
    if countStr then
        self:SetText(countStr)
    end
end

function UICurrencyItem:SetText(str)
    self.txt:SetText(str)
end

function UICurrencyItem:RefreshBg()
    if
        not self._hideAddBtn and
        (self._typeId == RoleAssetID.RoleAssetFirefly or self._typeId == RoleAssetID.RoleAssetDiamond or
        self._typeId == RoleAssetID.RoleAssetGlow or
        self._typeId == RoleAssetID.RoleAssetPhyPoint or
        self._typeId == RoleAssetID.RoleAssetAtom or
        self._typeId == RoleAssetID.RoleAssetFurnitureCoin or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkin or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinGL or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinKR or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinKL_Re or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinBLH or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinBLH_Re or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinGL_Re or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinQT or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinKR_Re or
        self._typeId == RoleAssetID.RoleAssetGold or
        self._typeId == RoleAssetID.RoleAssetDrawCardSeniorSkinPLM or
        self._typeId == RoleAssetID.RoleAssetXingZuan or
        self._typeId == RoleAssetID.RoleAssetHuiYao or
        self._typeId == RoleAssetID.RoleAssetHongPiao
        )

    then
        self.btnGO:SetActive(true)
        self.image.sprite = self.atlas:GetSprite("spirit_touming4_frame")
    elseif self._typeId == RoleAssetID.RoleAssetDoubleRes then -- 双倍卷
        self.btnGO:SetActive(false)
        self.image.sprite = self.atlas:GetSprite("spirit_touming8_frame")
    elseif self._shortForm then --短款样式
        self.btnGO:SetActive(false)
        self.image.sprite = self.atlas:GetSprite("obtian_xianshi_di1")
    else
        self.btnGO:SetActive(false)
        self.image.sprite = self.atlas:GetSprite("spirit_touming8_frame")
    end
end

--单独关闭某一个顶条的加号按钮，熔炼室ui用到
function UICurrencyItem:CloseAddBtn()
    self._hideAddBtn = true
    self:RefreshBg()
end

function UICurrencyItem:btnOnClick(go)
    if self._typeId == RoleAssetID.RoleAssetDiamond then
        local mShop = self:GetModule(ShopModule)
        local clientShop = mShop:GetClientShop()
        clientShop:OpenRechargeShop()
    elseif self._typeId == RoleAssetID.RoleAssetGlow then
        GameGlobal.UIStateManager():ShowDialog("UIShopCurrency1To2", 0)
    elseif self._typeId == RoleAssetID.RoleAssetFurnitureCoin then
        GameGlobal.UIStateManager():ShowDialog("UIShopHomelandGetCoin")
    elseif self._typeId == RoleAssetID.RoleAssetGold then
        GameGlobal.UIStateManager():ShowDialog("UIItemGetPathController", RoleAssetID.RoleAssetGold)
    elseif  self._typeId == RoleAssetID.RoleAssetXingZuan then
        GameGlobal.UIStateManager():ShowDialog("UIDrawCardAwardConversionForOtherController")
    elseif  self._typeId == RoleAssetID.RoleAssetHuiYao then
        GameGlobal.UIStateManager():ShowDialog("UIDrawCardAwardConversionForOtherController")
    elseif  self._typeId == RoleAssetID.RoleAssetHongPiao then
        GameGlobal.UIStateManager():ShowDialog("UIDrawCardAwardConversionForOtherController")
    elseif self._addCallBack then
        self._addCallBack(self._typeId, self.btnGO)
    else
        ToastManager.ShowLockTip()
    end
end

function UICurrencyItem:IconOnClick()
    --如果为负
    if
        self._typeId == RoleAssetID.RoleAssetGlow or self._typeId == RoleAssetID.RoleAssetDrawCard100 or
        self._typeId == RoleAssetID.RoleAssetDrawCard101
    then
        local itemMd = self:GetModule(ItemModule)
        local count = itemMd:GetItemCount(self._typeId)
        if count < 0 then
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.Ok,
                StringTable.Get("str_shop_resourceerror_title"),
                StringTable.Get("str_shop_resourceerror_desc"),
                function(param)
                end
            )
            return
        end
    else
    end
    if self._iconClick then
        self._iconClick(self._typeId, self.iconGO)
    end
end

function UICurrencyItem:bgOnClick()
    if self._bgCallBack then
        self._bgCallBack(self._typeId)
    end
end

function UICurrencyItem:btnopenOnClick()
    if self._switchCallBack then
        self._switchCallBack()
    end
end

---设置完数量之后，显示物品增长数字滚动动效
function UICurrencyItem:ShowRollingAnim(deltaCount, duration)
end

function UICurrencyItem:GetUIText()
    return self.txt
end
