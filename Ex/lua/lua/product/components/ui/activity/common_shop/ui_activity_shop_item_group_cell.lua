---@class UIActivityShopItemGroupCell : UICustomWidget
_class("UIActivityShopItemGroupCell", UICustomWidget)
UIActivityShopItemGroupCell = UIActivityShopItemGroupCell
function UIActivityShopItemGroupCell:OnShow(uiParams)
    self:InitWidget()
end
function UIActivityShopItemGroupCell:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self._smallBoxGen = self:GetUIComponent("UISelectObjectPath", "SmallBoxGen")
    ---@type UICustomWidgetPool
    self._bigItemGen = self:GetUIComponent("UISelectObjectPath", "BigItemGen")
    self._rootLayout = self:GetUIComponent("LayoutElement", "Root")
    --generated end--
end
function UIActivityShopItemGroupCell:SetData()
end
---@param data DCampaignShopItemBase
function UIActivityShopItemGroupCell:InitData(data)
    ---@type UIActivityShopItemBig | UIActivityShopSmallItemBox
    local item = nil
    local campaignId
    if data.exchangeCmpt then
        campaignId = data.exchangeCmpt:GetComponentInfo().m_campaign_id
    else
        local data1 = data[1]
        if data1 and data1.exchangeCmpt then
            campaignId = data1.exchangeCmpt:GetComponentInfo().m_campaign_id
        end
    end
    local commonCfg
    if campaignId then
        commonCfg = Cfg.cfg_activity_shop_common_client[campaignId]
    end
    local spWidth = 400
    local normalWidth = 350
    if commonCfg then
        spWidth = commonCfg.SpecialCellWidth
        normalWidth = commonCfg.NormalCellWidth
    end
    if data.GetIsSpecial and data:GetIsSpecial() then
        item = self._bigItemGen:SpawnObject("UIActivityShopItemBig")
        self._rootLayout.minWidth = spWidth
        self._rootLayout.preferredWidth = spWidth
    else
        item = self._smallBoxGen:SpawnObject("UIActivityShopSmallItemBox")
        self._rootLayout.minWidth = normalWidth
        self._rootLayout.preferredWidth = normalWidth
    end
    if item then
        item:InitData(data)
    --UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    end
    --UIHelper.RefreshLayout(self:GetGameObject():GetComponent("RectTransform"))
end
