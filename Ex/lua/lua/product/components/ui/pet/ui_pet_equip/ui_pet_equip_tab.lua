--
---@class UIPetEquipTab : UICustomWidget
_class("UIPetEquipTab", UICustomWidget)
UIPetEquipTab = UIPetEquipTab

--初始化
function UIPetEquipTab:OnShow(uiParams)
    self:InitWidget()
    self._atlas = self:GetAsset("UIPetEquip.spriteatlas", LoadType.SpriteAtlas)
end

--获取ui组件
function UIPetEquipTab:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UnityEngine.UI.Image
    self.imageBg = self:GetUIComponent("Image","imgBg")
    --generated end--
    self.redPointGo = self:GetGameObject("redPoint")
end

--设置数据
function UIPetEquipTab:SetData(name, clickCallback)
    self.clickCallback = clickCallback
    self.txtName:SetText(StringTable.Get(name))
end

function UIPetEquipTab:SetSelect(bSelect)
    if bSelect then
        self.imageBg.sprite = self._atlas:GetSprite("spirit_lg_btn02")
        self.txtName.color = Color(1,1,1)
    else
        self.imageBg.sprite = self._atlas:GetSprite("spirit_lg_btn01")
        self.txtName.color = Color(94/255,94/255,94/255)
    end
end

--按钮点击
function UIPetEquipTab:BgOnClick(go)
    if self.clickCallback then
        self.clickCallback()
    end
end

function UIPetEquipTab:SetPoint(visible)
    self.redPointGo:SetActive(visible)
end
