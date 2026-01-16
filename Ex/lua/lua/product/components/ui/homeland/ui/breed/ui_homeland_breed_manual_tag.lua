---@class UIHomelandBreedManualTag : UICustomWidget
_class("UIHomelandBreedManualTag", UICustomWidget)
UIHomelandBreedManualTag = UIHomelandBreedManualTag

function UIHomelandBreedManualTag:Constructor()
    self._atlas = self:GetAsset("UIHomelandBreed.spriteatlas", LoadType.SpriteAtlas)
end

function UIHomelandBreedManualTag:OnShow(uiParams)
    self:_GetComponents()
end
function UIHomelandBreedManualTag:_GetComponents()
    ---@type UILocalizationText
    self._text = self:GetUIComponent("UILocalizationText", "Text")
    self._bg = self:GetUIComponent("Image", "Bg")
end
function UIHomelandBreedManualTag:SetData(data, index, callBack)
    self._data = data
    self._index = index
    self._callBack = callBack
    --local s1 = StringTable.Get(HomelandBreedPedigreeStr[self._data.pedigree])
    local suffix = "_"..self._data.species.."_"..self._data.pedigree
    local s2 = StringTable.Get("str_homeland_breed_pedigree"..suffix)
    --local s3 = StringTable.Get(HomelandBreedSpeciesStr[self._data.species])
    self._text:SetText(s2)
end
function UIHomelandBreedManualTag:BgOnClick(go)
    if self._callBack then
        self._callBack(self._data, self._index)
    end
end
function UIHomelandBreedManualTag:RefreshState(state)
    local sprite = "n17_plant_di25"
    local color = Color(106 / 255, 106 / 255, 106 / 255)
    if state then
        sprite = "n17_plant_di24"
        color = Color.white
    end
    self._bg.sprite = self._atlas:GetSprite(sprite)
    self._text.color = color
end

