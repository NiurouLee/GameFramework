---@class UIHeartItemStar:UICustomWidget
_class("UIHeartItemStar", UICustomWidget)
UIHeartItemStar = UIHeartItemStar

function UIHeartItemStar:Constructor()
    --self._atlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
end

function UIHeartItemStar:SetData(sp)
    self._starImg = self:GetUIComponent("Image", "img")
    --[[

    if blue then
        self._starImg.sprite = self._atlas:GetSprite("spirit_xing1_frame")
    else
        self._starImg.sprite = self._atlas:GetSprite("spirit_xing2_frame")
    end
    ]]
    self._starImg.sprite = sp
end
