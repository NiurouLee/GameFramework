_class("UIChatPetItem", UICustomWidget)
---@class UIChatPetItem : UICustomWidget
UIChatPetItem = UIChatPetItem

function UIChatPetItem:OnShow(uiParam)
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    self._atlasAwake = self:GetAsset("UIAwake.spriteatlas", LoadType.SpriteAtlas)
    self._headImg = self:GetUIComponent("RawImageLoader", "Head")
    ---@type UnityEngine.UI.Image
    self._firstElementImg = self:GetUIComponent("Image", "FirstElement")
    ---@type UnityEngine.UI.Image
    self._secondElementImg = self:GetUIComponent("Image", "SecondElement")
    self._level = self:GetUIComponent("UILocalizationText", "Level")
    self._awake = self:GetUIComponent("Image", "awake")
    self._secondElementGo = self:GetGameObject("SecondElement")
    self._infoPanel = self:GetGameObject("Info")
end

---@param friendPetData ChatFriendPetData
function UIChatPetItem:Refresh(friendPetData)
    if not friendPetData then
        self._infoPanel:SetActive(false)
        return
    end
    ---@type ChatFriendPetData
    self._friendPetData = friendPetData
    self._infoPanel:SetActive(true)
    self._headImg:LoadImage(friendPetData:GetHeadIcon())
    self._level:SetText("Lv." .. friendPetData:GetLevel())
    local spriteName = UIPetModule.GetAwakeSpriteName(friendPetData:GetPetTemplateId(), friendPetData:GetGrade())
    self._awake.sprite = self._atlasAwake:GetSprite(spriteName)
    self._firstElementImg.sprite =
        self.atlasProperty:GetSprite(
        UIPropertyHelper:GetInstance():GetColorBlindSprite(friendPetData:GetFirstElementName())
    )
    if friendPetData:GetSecondElement() <= 0 then
        self._secondElementGo:SetActive(false)
    else
        self._secondElementGo:SetActive(true)
        self._secondElementImg.sprite =
            self.atlasProperty:GetSprite(
            UIPropertyHelper:GetInstance():GetColorBlindSprite(friendPetData:GetSecondElementName())
        )
    end
end

function UIChatPetItem:PetBtnOnClick(go)
    local module = GameGlobal.GetModule(MissionModule)
    ---@type TeamsContext
    local ctx = module:TeamCtx()
    ctx:Init(TeamOpenerType.Main, 0)--ctx的TeamOpenerType没有重置，可能导致显示异常（例如活动关的光灵修正）
    self:ShowDialog("UIHelpPetInfoController", self._friendPetData:GetHelpPetData())
end
