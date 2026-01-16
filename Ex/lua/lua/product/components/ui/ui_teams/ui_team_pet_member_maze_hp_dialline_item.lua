---@class UITeamPetMemberMazeHpDialLineItem : UICustomWidget
_class("UITeamPetMemberMazeHpDialLineItem", UICustomWidget)
UITeamPetMemberMazeHpDialLineItem = UITeamPetMemberMazeHpDialLineItem
function UITeamPetMemberMazeHpDialLineItem:Constructor()
    self._atlas = self:GetAsset("UITeams.spriteatlas", LoadType.SpriteAtlas)
end
function UITeamPetMemberMazeHpDialLineItem:OnShow()
    ---@type UnityEngine.UI.Image
    self._img = self:GetUIComponent("Image", "img")
    self._rect = self:GetUIComponent("RectTransform", "img")
end
function UITeamPetMemberMazeHpDialLineItem:SetData(idx, posx, middleImg, show)
    self._index = idx
    self._rect.anchoredPosition = Vector2(posx, 0)
    self._img.enabled = show
    if middleImg then
        self._img.sprite = self._atlas:GetSprite("map_biandui_xuetiao5")
    else
        self._img.sprite = self._atlas:GetSprite("map_biandui_xuetiao6")
    end
    self._img:SetNativeSize()
end
