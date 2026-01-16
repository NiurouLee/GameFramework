---入住界面星灵上方排序按钮的prefab
---@class UIAircraftEnterUpSortBtnPrefab : UICustomWidget
_class("UIAircraftEnterUpSortBtnPrefab", UICustomWidget)
UIAircraftEnterUpSortBtnPrefab = UIAircraftEnterUpSortBtnPrefab

function UIAircraftEnterUpSortBtnPrefab:OnShow(uiParams)
    self._arrow = self:GetUIComponent("Image", "arrow")
    self._sortText = self:GetUIComponent("UILocalizationText", "Text")

    self._bg = self:GetGameObject("bg")
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAircraftEnterBuildAtlas = self:GetAsset("UIAircraftEnterBuild.spriteatlas", LoadType.SpriteAtlas)
    
    self:AttachEvent(GameEventType.AircraftEnterBuildChangeSort,self.AircraftEnterBuildChangeSort)
end

function UIAircraftEnterUpSortBtnPrefab:AircraftEnterBuildChangeSort(sort_params)
    if self._sortType == sort_params._sort_type then
        self:SelectActive(sort_params._sort_order)
    else
        self:CancelActive()
    end
end

function UIAircraftEnterUpSortBtnPrefab:Constructor()
    
end
function UIAircraftEnterUpSortBtnPrefab:OnHide()
    self:DetachEvent(GameEventType.AircraftEnterBuildChangeSort,self.AircraftEnterBuildChangeSort)
end

---@param curSortCls AircrafEnterSortData 当前排序的类型
function UIAircraftEnterUpSortBtnPrefab:SetData(index,sortType, sortText, sort_params, callback)
    self._index = index
    self._sortType = sortType
    self._sortText:SetText(StringTable.Get(sortText))
    self._sort_params = sort_params
    self._callback = callback
    if self._sortType == sort_params._sort_type then
        self:SelectActive(sort_params._sort_order)
    else
        self:CancelActive()
    end
end

function UIAircraftEnterUpSortBtnPrefab:CancelActive()
    self._sortText.color = Color.white
    self._bg:SetActive(false)
end

function UIAircraftEnterUpSortBtnPrefab:SelectActive(up2down)
    self._bg:SetActive(true)
    self._sortText.color = Color(252 / 255, 232 / 255, 2 / 255, 1)
    if up2down == PetSortOrder.Descending then
        self._arrow.sprite = self._uiAircraftEnterBuildAtlas:GetSprite("spirit_jiantou_y_1_frame")
    else
        self._arrow.sprite = self._uiAircraftEnterBuildAtlas:GetSprite("spirit_jiantou_y_2_frame")
    end
end

function UIAircraftEnterUpSortBtnPrefab:bgOnClick()
    self._callback(self._index,self._sortType)
end
