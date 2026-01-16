--
---@class UISeasonShareBtn : UICustomWidget
_class("UISeasonShareBtn", UICustomWidget)
UISeasonShareBtn = UISeasonShareBtn
--初始化
function UISeasonShareBtn:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonShareBtn:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.icon = self:GetUIComponent("Image", "Icon")
    ---@type UILocalizationText
    self.count = self:GetUIComponent("UILocalizationText", "Count")
    --generated end--
    self.award = self:GetGameObject("Award")
end

--设置数据
function UISeasonShareBtn:SetData(count, onClick)
    self._onClick = onClick
    if count and count > 0 then
        self.count:SetText(count)
        self.award:SetActive(true)
    else
        self.award:SetActive(false)
    end
end

--按钮点击
function UISeasonShareBtn:ShareBtnOnClick(go)
    self._onClick()
end
