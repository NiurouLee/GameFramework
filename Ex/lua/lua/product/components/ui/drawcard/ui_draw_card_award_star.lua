---@class UIDrawCardAwardStar:UICustomWidget
_class("UIDrawCardAwardStar", UICustomWidget)
UIDrawCardAwardStar = UIDrawCardAwardStar

function UIDrawCardAwardStar:Constructor()
    self._atlas = self:GetAsset("UIDrawCard.spriteatlas", LoadType.SpriteAtlas)
end

-- function UIDrawCardAwardStar:SetData(sp)
--     self._starImg = self:GetUIComponent("Image", "img")
--     --[[

--     if blue then
--         self._starImg.sprite = self._atlas:GetSprite("spirit_xing1_frame")
--     else
--         self._starImg.sprite = self._atlas:GetSprite("spirit_xing2_frame")
--     end
--     ]]
--     self._starImg.sprite = sp
-- end
