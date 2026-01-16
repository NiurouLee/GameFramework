--
---@class UIPetEquipRefineLevelBtn : UICustomWidget
_class("UIPetEquipRefineLevelBtn", UICustomWidget)
UIPetEquipRefineLevelBtn = UIPetEquipRefineLevelBtn
--初始化
function UIPetEquipRefineLevelBtn:OnShow(uiParams)
    self:InitWidget()
    self._atlas = self:GetAsset("UIPetEquip.spriteatlas", LoadType.SpriteAtlas)
end

--获取ui组件
function UIPetEquipRefineLevelBtn:InitWidget()
    ---@type UnityEngine.UI.Image
    self.imgLevel = self:GetUIComponent("Image", "imgLevel")

    ---@type UnityEngine.GameObject
    self.maskGo = self:GetGameObject("maskGo")
    ---@type UnityEngine.GameObject
    self.selectGo = self:GetGameObject( "selectGo")
    self.animation = self:GetUIComponent("Animation", "animation")
end

--设置数据
function UIPetEquipRefineLevelBtn:SetData(bgName, clickCall)
    self.imgLevel.sprite = self._atlas:GetSprite(bgName)
    self.clickCall = clickCall
end

--按钮点击
function UIPetEquipRefineLevelBtn:ImgLevelOnClick(go)
    if self.clickCall then
        self.clickCall()
    end
end

function UIPetEquipRefineLevelBtn:SetSelect(bSelect)
    -- self.selectGo:SetActive(bSelect)
end

function UIPetEquipRefineLevelBtn:HideMask(bHide)
    -- self.maskGo:SetActive(not bHide)
end

function UIPetEquipRefineLevelBtn:PlayAni(aniName)
    if self.animation then
        self.animation:Play(aniName)
    end
end