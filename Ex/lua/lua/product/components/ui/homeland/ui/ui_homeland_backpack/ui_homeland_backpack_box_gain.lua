_class("UIHomelandBackPackBoxGain", UIController)
---@class UIHomelandBackPackBoxGain : UIController
UIHomelandBackPackBoxGain = UIHomelandBackPackBoxGain

function UIHomelandBackPackBoxGain:OnShow(uiParams)
    ---@type UICustomWidgetPool
    local itemPool = self:GetUIComponent("UISelectObjectPath", "itemPool")
    ---@type UIItemHomeland
    self.uiItem = itemPool:SpawnObject("UIItemHomeland")
    ---@type RawImageLoader
    -- self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")

    self._giftId = uiParams[1]
    self._count = uiParams[2]
    ---@type RoleAsset
    self._item = uiParams[3]
    self._index = uiParams[4]
    local tplId = self._item.assetid
    local cfg = Cfg.cfg_item[tplId]
    -- self.imgIcon:LoadImage(cfg.Icon)
    self.uiItem:Flush(self._item)
    self.txtName:SetText(StringTable.Get(cfg.Name))
    local count = self:GetModule(ItemModule):GetItemCount(tplId)
    self.txtCount:SetText(StringTable.Get("str_item_public_owned") .. HelperProxy:GetInstance():FormatItemCount(count))
    self.txtDesc:SetText(StringTable.Get(cfg.Intro))
end

function UIHomelandBackPackBoxGain:OnHide()
    -- self.imgIcon:DestoryLastImage()
end

function UIHomelandBackPackBoxGain:bgOnClick()
    self:CloseDialog()
end

function UIHomelandBackPackBoxGain:btnGainOnClick()
    self:StartTask(
        function(TT)
            local res, msg = self:GetModule(ItemModule):RequestChooseGift(TT, self._giftId, self._index, self._count)
            if UIForgeData.CheckCode(res:GetResult()) then
                local ra = RoleAsset:New()
                ra.assetid = self._item.assetid
                ra.count = self._item.count * self._count
                self:ShowDialog("UIHomeShowAwards", {ra})
                GameGlobal.EventDispatcher():Dispatch(GameEventType.CloseUIBackPackBox)
                self:CloseDialog()
            end
        end,
        self
    )
end
