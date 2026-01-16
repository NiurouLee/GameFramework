---@class UIHomelandBreedManualItem : UICustomWidget
_class("UIHomelandBreedManualItem", UICustomWidget)
UIHomelandBreedManualItem = UIHomelandBreedManualItem

function UIHomelandBreedManualItem:Constructor()
    
end

function UIHomelandBreedManualItem:OnShow(uiParams)
    self:_GetComponent()
    self:_OnValue()
end
function UIHomelandBreedManualItem:_GetComponent()
    ---@type UICustomWidgetPool
    self._item = self:GetUIComponent("UISelectObjectPath", "Item")
    ---@type UILocalizationText
    self._text = self:GetUIComponent("UILocalizationText", "Text")
end
function UIHomelandBreedManualItem:_OnValue()
    ---@type UIHomelandBreedItem
    self._itemWidget = self._item:SpawnObject("UIHomelandBreedItem")
end
function UIHomelandBreedManualItem:SetData(data)
    self._data = data
    --[[
    local s1 = StringTable.Get(HomelandBreedPedigreeStr[self._data.pedigree])
    local s2 = HomelandBreedRarityStr[self._data.rarity]
    local s3 = self._data.series
    local s4 = StringTable.Get(HomelandBreedSpeciesStr[self._data.species])
    local s5 = StringTable.Get("str_homeland_breed_series")
    self._name = s1..s2..s3..s4..s5
    --]]
    table.sort(self._data.st,
    function(a,b)
            return a.IsMutation > b.IsMutation
        end)
    local cfg = Cfg.cfg_item[self._data.st[1].ID]
    self._text:SetText(StringTable.Get(cfg.Name))
    self._itemWidget:SetData(cfg, Vector2(345, 345), Vector2(375, 375))
end

function UIHomelandBreedManualItem:DetailsBtnOnClick(go)
    self:ShowDialog("UIHomelandBreedManualInfo", self._name, self._data.st)
end