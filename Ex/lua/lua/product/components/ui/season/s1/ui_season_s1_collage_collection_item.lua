--
---@class UISeasonS1CollageCollectionItem : UICustomWidget
_class("UISeasonS1CollageCollectionItem", UICustomWidget)
UISeasonS1CollageCollectionItem = UISeasonS1CollageCollectionItem
--初始化
function UISeasonS1CollageCollectionItem:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonS1CollageCollectionItem:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UnityEngine.GameObject
    self.unlockIcon = self:GetGameObject("unlockIcon")
    --generated end--
    self.new = self:GetGameObject("new")
    self.iconImage = self:GetUIComponent("RawImage", "icon")
    self.select = self:GetGameObject("select")
    self.root = self:GetUIComponent("RectTransform", "Root")

    self._anim = self:GetGameObject():GetComponent(typeof(UnityEngine.Animation))
end

--设置数据
---@param data UISeasonCollageData_Collection
function UISeasonS1CollageCollectionItem:SetData(data, onClick)
    --cfg_item_season_collection
    self._data = data
    self._onClick = onClick
    self:SetNew(data:IsNew())
    local cfg = Cfg.cfg_item_season_collection[data:ID()]
    self.icon:LoadImage(cfg.HdImage)
    if data:IsGot() then
        self.icon:SetColor(Color.white)
        self.unlockIcon:SetActive(false)
        if data:IsComposeUsed() then
            self.icon:SetColor(Color(84 / 255, 53 / 255, 32 / 255, 0.7))
        end
    else
        self.icon:SetColor(Color(0, 0, 0, 0.8))
        self.unlockIcon:SetActive(true)
    end
    self:SetSelect(false)
end

--按钮点击
function UISeasonS1CollageCollectionItem:RootOnClick(go)
    self._onClick(self._data)
end

function UISeasonS1CollageCollectionItem:SetNew(new)
    self._isNew = new
    self.new:SetActive(new)
end

function UISeasonS1CollageCollectionItem:SetSelect(select)
    self._anim:Stop()
    if select then
        -- self.root.anchoredPosition = Vector2(0, 40)
        self.select:SetActive(true)
        self._anim:Stop()
        self._anim:Play("uieffanim_UISeasonS1CollageCollectionItem_in")
    else
        -- self.root.anchoredPosition = Vector2(0, 0)
        self.select:SetActive(false)
        self._anim:Stop()
        self._anim:Play("uieffanim_UISeasonS1CollageCollectionItem_out")
    end
end

function UISeasonS1CollageCollectionItem:PlayExitAnim()
    self._anim:Play("uieffanim_UISeasonS1CollageCollectionItem_out")
end
