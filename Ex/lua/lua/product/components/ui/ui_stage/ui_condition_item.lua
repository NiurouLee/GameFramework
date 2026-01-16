---@class UIConditionItem:UICustomWidget
_class("UIConditionItem", UICustomWidget)
UIConditionItem = UIConditionItem

local ATLAS_NAME = "UIStage.spriteatlas"
local BG_NAME = "map_guanqia_tiao"

function UIConditionItem:OnShow()
    self._imgStar = self:GetGameObject("imgStar")
    self._grayImgStar = self:GetGameObject("imgGrayStar")
    ---@type RollingText
    self._txt = self:GetUIComponent("RollingText", "txt")
    self._title = self:GetUIComponent("UILocalizationText", "title")

    self._bgImage = self:GetUIComponent("Image", "bg")
end

---@param v StageCondition
function UIConditionItem:Flush(v, index)
    self._title.text = index
    self._txt:RefreshText(v.content)
    self._imgStar.gameObject:SetActive(v.satisfy)
    self._grayImgStar.gameObject:SetActive(not v.satisfy)

    --[[
--暂时关掉
        local atlas = self:GetAsset(ATLAS_NAME, LoadType.SpriteAtlas)
        if atlas then
            self:RefreshBg(atlas, index)
        end
        ]]
end

function UIConditionItem:RefreshBg(atlas, index)
    local spriteName = BG_NAME .. index
    local sprite = atlas:GetSprite(spriteName)
    if sprite then
        self._bgImage.sprite = sprite
    end
end
