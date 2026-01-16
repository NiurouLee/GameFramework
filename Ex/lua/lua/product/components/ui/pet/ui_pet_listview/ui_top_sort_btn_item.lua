---@class UITopSortBtnItem:UICustomWidget
_class("UITopSortBtnItem", UICustomWidget)
UITopSortBtnItem = UITopSortBtnItem

function UITopSortBtnItem:Constructor()
    self.ElementSpriteName = {
        [ElementType.ElementType_Blue] = "bing_color",
        [ElementType.ElementType_Red] = "huo_color",
        [ElementType.ElementType_Green] = "sen_color",
        [ElementType.ElementType_Yellow] = "lei_color"
    }
end

function UITopSortBtnItem:OnShow(uiParams)
    self._uiHeartAtlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
end

function UITopSortBtnItem:GetComponents()
    self._arrow = self:GetUIComponent("Image", "arrow")
    self._arrowGo = self:GetGameObject("arrow")
    self._name = self:GetUIComponent("UILocalizationText", "name")
    self._selectImgGo = self:GetGameObject("selectImg")
    self._elementTypeImg = self:GetUIComponent("Image" , "eleImage")
end

--注释
function UITopSortBtnItem:SetData(index, cfg, currentSortParams, currentSortOrder, callback , eleType)
    self:GetComponents()
    self._index = index
    self._cfg = cfg
    self._currSortParams = currentSortParams
    self._currentSortOrder = currentSortOrder
    self._callback = callback
    self._eleType = eleType
    self:OnValue()
end

function UITopSortBtnItem:OnValue()
    self._name:SetText(StringTable.Get(self._cfg.Name))
    self._elementTypeImg.gameObject:SetActive(false)
    self:Flush(self._currSortParams, self._currentSortOrder , self._eleType)
end

function UITopSortBtnItem:bgOnClick()
    if self._cfg.Type == PetSortType.Element then
        local petModule = self:GetModule(PetModule)
        local currentElementSortTypeOrder = petModule.PetSortElementIndex
        petModule:SavePetSortElementIndex(currentElementSortTypeOrder % 4 + 1)
    end
    if self._callback then
        self._callback(self._index)
    end
end

--注释
function UITopSortBtnItem:Flush(params, order , eleType)
    self._eleType = eleType
    if params == self._cfg.Type then
        self._arrowGo:SetActive(true)
        self._selectImgGo:SetActive(true)
        self._name.color = Color(252 / 255, 232 / 255, 2 / 255, 1)
        if order == PetSortOrder.Ascending then
            self._arrow.sprite = self._uiHeartAtlas:GetSprite("spirit_jiantou_y_2_frame")
        else
            self._arrow.sprite = self._uiHeartAtlas:GetSprite("spirit_jiantou_y_1_frame")
        end
    else
        self._arrowGo:SetActive(false)
        self._selectImgGo:SetActive(false)
        self._name.color = Color(1, 1, 1, 1)
    end
    --QA编队36690 元素标签没有箭头
    if self._cfg.ID == PetSortType.Element then
        self._arrowGo:SetActive(false)
        self._elementTypeImg.gameObject:SetActive(true)
        if self._eleType ~= 0 then
            self._elementTypeImg.sprite = self.atlasProperty:GetSprite(self.ElementSpriteName[self._eleType])
        end
    else
        self._elementTypeImg.gameObject:SetActive(false)
    end
end
