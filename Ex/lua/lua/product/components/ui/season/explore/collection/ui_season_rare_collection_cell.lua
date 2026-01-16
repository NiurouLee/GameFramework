--
---@class UISeasonRareCollectionCell : UICustomWidget
_class("UISeasonRareCollectionCell", UICustomWidget)
UISeasonRareCollectionCell = UISeasonRareCollectionCell
--初始化
function UISeasonRareCollectionCell:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonRareCollectionCell:InitWidget()
    ---@type RawImageLoader
    self.item = self:GetUIComponent("RawImageLoader", "item")
    ---@type UnityEngine.GameObject
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.GameObject
    self.new = self:GetGameObject("new")
end

--设置数据
function UISeasonRareCollectionCell:SetData(itemInfo, index, selectIndex, clickCb)
    self.clickCb = clickCb
    self.itemInfo = itemInfo
    self.index = index
    local itemCfg = itemInfo:GetTemplate()
    if not itemCfg then
        Log.error("err UISeasonRareCollectionCell can't find cfg_item with id = " .. templateId)
        return
    end
    self:SetSelect(index == selectIndex)
    self.item:LoadImage(itemCfg.Icon)
    self.isNew = not UISeasonExploreHelper.IsRareItemHasClicked(itemInfo:GetID())
    self.new:SetActive(self.isNew)
end

function UISeasonRareCollectionCell:SetSelect(bSelect)
    self.select:SetActive(bSelect)
end

--按钮点击
function UISeasonRareCollectionCell:ItemOnClick(go)
    if self.clickCb then
        self.clickCb(self)
    end
    if self.isNew then
        UISeasonExploreHelper.SetRareItemAsClicked(self.itemInfo:GetID())
        self.new:SetActive(false)
    end
end
