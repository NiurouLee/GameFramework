---@class UISeasonShowCollectionAward : UIController
_class("UISeasonShowCollectionAward", UIController)
UISeasonShowCollectionAward = UISeasonShowCollectionAward

--
function UISeasonShowCollectionAward:GetComponents()
    self._trans = self:GetGameObject()
    --物品动画前置时间（第一排有）
    self._beforeTime = 200
    self._inited = false
    self._itemData = nil
    self._bg = self:GetUIComponent("RectTransform", "canvasGroup")
    ---@type UnityEngine.UI.Image
    self._iconBg = self:GetUIComponent("Image", "IconBg")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "ImgIcon")
    self._bg.localScale = Vector3(1, 1, 1)
    self._titleText = self:GetUIComponent("UILocalizationText", "TitleText")
    self._titleTextGo = self:GetGameObject("TitleText")
    self._itemNameText = self:GetUIComponent("UILocalizationText", "ItemNameText")
    --self._itemNameText = self:GetUIComponent("UILocalizedTMP", "ItemNameText")
    self._itemIntroText = self:GetUIComponent("UILocalizationText", "ItemIntroText")
    self._itemDetailText = self:GetUIComponent("UILocalizationText", "ItemDetailText")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UISeasonMain.spriteatlas", LoadType.SpriteAtlas)
    --Tips
    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
    local s = self:GetUIComponent("UISelectObjectPath", "itemTips")
    self._tips = s:SpawnObject("UISelectInfo")
end

--
function UISeasonShowCollectionAward:OnShow(uiParams)
    self._closeCallback = uiParams[2] --关闭回调
    self:GetComponents()
    --获得的物品列表
    local item_module = GameGlobal.GetModule(ItemModule)
    local roleAsset
    if not uiParams[1] then
        Log.fatal("###[UISeasonShowCollectionAward] uiParams[1] is nil !")
    end
    roleAsset = uiParams[1]
    self:CreateData(roleAsset)
    self:FlushItem(self._itemData)
    self._inited = true
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundGetItem)

    self:DispatchEvent(GameEventType.OnSeasonCollectionObtained, roleAsset.assetid) --派发事件获得收藏品
end

function UISeasonShowCollectionAward:FlushItem(itemData)
    if not itemData then
        return
    end
    local icon = ""
    local color = 1
    local count = 0
    local name = ""
    local intro = ""
    local desc = ""
    if itemData.exp then
        icon = ""
        color = 6
        count = itemData.count
    else
        local cfg = Cfg.cfg_item[itemData.item_id]
        icon = cfg.Icon
        color = cfg.Color
        count = itemData.count
        name = itemData.item_name
        intro = itemData.simple_desc
        desc = itemData.item_des
    end
    self._imgIcon:LoadImage(icon)
    --self._iconBg.sprite = self.atlas:GetSprite("N17_produce_bg_item_" .. color)
    --self.txtCount:SetText(self:FormatCount(count))
    --self.first:SetActive(itemData.first ~= nil)
    self._itemNameText:SetText(StringTable.Get(name))
    self._itemIntroText:SetText(StringTable.Get(intro))
    self._itemDetailText:SetText(StringTable.Get(desc))
end

--
function UISeasonShowCollectionAward:CreateData(roleAsset)
    local itemTempleate = Cfg.cfg_item[roleAsset.assetid]
    if itemTempleate then
        self._itemData = {
            item_id = roleAsset.assetid,
            item_count = roleAsset.count,
            item_des = itemTempleate.RpIntro,
            icon = itemTempleate.Icon,
            item_name = itemTempleate.Name,
            simple_desc = itemTempleate.Intro,
            color = itemTempleate.Color
        }
    end
end

function UISeasonShowCollectionAward:ClosePanel()
    self:CloseDialog()
end

--
function UISeasonShowCollectionAward:OnHide()
    if self._closeCallback then
        self._closeCallback()
    end
end

---@param index number
---
function UISeasonShowCollectionAward:IconBgOnClick(go)
    --self:ShowDialog("UISeasonItemTips",self._itemData.item_id,go)
    -- local roleAsset = RoleAsset:New()
    -- roleAsset.assetid = self._itemData.item_id
    -- roleAsset.count = self._itemData.item_count
    -- self:ShowDialog("UIItemTips", roleAsset, go, "UISeasonShowCollectionAward")

    --GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowItemTips, self._itemData.item_id, self._trans.transform.position)
end

--
function UISeasonShowCollectionAward:BgOnClick(go)
    self:ClosePanel()
end

local modf = math.modf
function UISeasonShowCollectionAward:_FormatItemCount(itemCount)
    return HelperProxy:GetInstance():FormatItemCount(itemCount)
end

function UISeasonShowCollectionAward:CloseBtnOnClick(go)
    self:ClosePanel()
end

function UISeasonShowCollectionAward:ShowTips(itemId, pos)
    self._tips:SetData(itemId, pos)
end
