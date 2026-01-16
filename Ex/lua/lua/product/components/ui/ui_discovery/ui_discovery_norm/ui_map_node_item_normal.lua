---@class UIMapNodeItemNormal:UIMapNodeItemBase
_class("UIMapNodeItemNormal", UIMapNodeItemBase)
UIMapNodeItemNormal = UIMapNodeItemNormal

function UIMapNodeItemNormal:OnShow()
    UIMapNodeItemNormal.super.OnShow(self)
    ---@type UnityEngine.UI.Image
    self._bgImg = self:GetUIComponent("Image", "bgImg")
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
end

---@overload
function UIMapNodeItemNormal:FlushGuide()
    local stage = self.nodeInfo.stages[1]
    if stage and stage:IsGuideStage() then
        self._bgImg.sprite = self._atlasNode:GetSprite("map_guanqia_ludian04")
        self.txtName:SetText(StringTable.Get("str_discovery_node_normal_guide"))
    else
        self._bgImg.sprite = self._atlasNode:GetSprite("map_guanqia_ludian05")
        self.txtName:SetText(StringTable.Get("str_discovery_node_normal_record"))
    end
end

---@overload
function UIMapNodeItemNormal:GetTipAnimName()
    return "uieff_UINormNodeNorm_in"
end
