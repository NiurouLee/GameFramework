--
---@class UIWorldBossDiffcultyItem : UICustomWidget
_class("UIWorldBossDiffcultyItem", UICustomWidget)
UIWorldBossDiffcultyItem = UIWorldBossDiffcultyItem
--初始化
function UIWorldBossDiffcultyItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIWorldBossDiffcultyItem:InitWidget()
    self.selectObj = self:GetGameObject("selectObj")
    self.selectObj:SetActive(true)

    ---@type UILocalizationText
    self.title = self:GetUIComponent("UILocalizationText", "title")
    ---@type UILocalizationText
    self.desc = self:GetUIComponent("UILocalizationText", "desc")
    self.animaiton = self:GetUIComponent("Animation", "animation")
    self.itemBg = self:GetUIComponent("RawImageLoader", "itemBg")
end

--设置数据
function UIWorldBossDiffcultyItem:SetData(index, cfg, descKey, clickCall)
    self.index = index
    self.clickCall = clickCall
    self.title:SetText(StringTable.Get(cfg.name))
    self.desc:SetText(StringTable.Get(descKey))
    self.itemBg:LoadImage(cfg.bg)
end

function UIWorldBossDiffcultyItem:SetSelect(bSelect)
   -- self.selectObj:SetActive(bSelect)
    if bSelect then
        self.animaiton:Play("UIWorldBossDiffcultyItem_in")
    else
        self.animaiton:Play("UIWorldBossDiffcultyItem_out")
    end
end

--按钮点击
function UIWorldBossDiffcultyItem:ItemBgOnClick(go)
    if self.clickCall then
        self.clickCall(self, self.index)
    end
end

function UIWorldBossDiffcultyItem:DescScrollViewOnClick(go)
    if self.clickCall then
        self.clickCall(self, self.index)
    end
end