--
---@class UIHomeVisitSpeedupItem : UICustomWidget
_class("UIHomeVisitSpeedupItem", UICustomWidget)
UIHomeVisitSpeedupItem = UIHomeVisitSpeedupItem
--初始化
function UIHomeVisitSpeedupItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHomeVisitSpeedupItem:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UILocalizationText
    self.nick = self:GetUIComponent("UILocalizationText", "nick")
    ---@type UILocalizationText
    self.time = self:GetUIComponent("UILocalizationText", "time")
    --generated end--
    self._color = self:GetUIComponent("Image", "color")
    self._already = self:GetGameObject("already")
    self._finish = self:GetGameObject("finish")
    ---@type UILocalizationText
    self._count = self:GetUIComponent("UILocalizationText", "count")
    self.forgeCountParent = self:GetGameObject("forgeCountParent")
end
--设置数据
---@param data ForgeItemInfo
---@param timeInfo VisitHelpTimeInfo
function UIHomeVisitSpeedupItem:SetData(data, timeInfo, speeduped, finished)
    local cfg = Cfg.cfg_item[data.item_id]
    if not cfg then
        Log.exception("cfg_item中找不到礼品配置:", data.item_id)
        return
    end
    local atlas = self:GetAsset("UIHomelandShop.spriteatlas", LoadType.SpriteAtlas)
    self.icon:LoadImage(cfg.Icon)
    self._color.sprite = atlas:GetSprite("n17_shop_kuang0" .. cfg.Color)
    self.nick:SetText(StringTable.Get(cfg.Name))
    local time = data.end_time - GetSvrTimeNow()
    if timeInfo then
        time = time - timeInfo.offline_help_time
    end
    self.time.gameObject:SetActive(true)
    self.time:SetText(HelperProxy:GetInstance():FormatTime_3(time))
    local count = Cfg.cfg_item_architecture[data.item_id].ForgeStack
    self._count:SetText("×" .. count)
    self.forgeCountParent:SetActive(count > 1)
    if finished then
        self._finish:SetActive(true)
        self.time.gameObject:SetActive(false)
        self._already:SetActive(false)
    else
        self._already:SetActive(speeduped)
        self._finish:SetActive(false)
    end
end
