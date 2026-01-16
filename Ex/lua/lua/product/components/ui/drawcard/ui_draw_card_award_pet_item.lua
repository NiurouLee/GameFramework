---@class UIDrawCardAwardPetItem:UICustomWidget
_class("UIDrawCardAwardPetItem", UICustomWidget)
UIDrawCardAwardPetItem = UIDrawCardAwardPetItem

function UIDrawCardAwardPetItem:OnShow()
    -- self.title = self:GetUIComponent("UILocalizationText", "title")
    -- self.detail = self:GetUIComponent("UILocalizationText", "detail")
    -- self.content = self:GetGameObject("content")
    --self.stars = self:GetUIComponent("UISelectObjectPath","stars")
    self.petIcon = self:GetUIComponent("RawImageLoader","peticon")
    
    self._atlas = self:GetAsset("UIDrawCard.spriteatlas", LoadType.SpriteAtlas)
    self._logo = self:GetUIComponent("RawImageLoader", "logo")

    self.firstImage = self:GetUIComponent("Image","first")
    self.first = self:GetGameObject("first")
    self.secondImage = self:GetUIComponent("Image","second")
    self.second = self:GetGameObject("second")

    self.secondAttribute = self:GetUIComponent("Image","secondAttribute")
    self.firstAttribute = self:GetUIComponent("Image","firstAttribute")

    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    self.name = self:GetUIComponent("UILocalizationText", "name")
    self.rate = self:GetGameObject("rateText")
    self._bg2 = self:GetGameObject("bg2")
    self.rateText = self:GetUIComponent("UILocalizationText", "rateText")
    self._star6 = self:GetGameObject("star6")
    self._star5 = self:GetGameObject("star5")
    self._star4 = self:GetGameObject("star4")
    self._qualityIcon = self:GetUIComponent("Image", "qualityIcon")
    self._uiHeartItemAtlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
end

function UIDrawCardAwardPetItem:SetData(stars, content,rate)

    --self.stars:SpawnObjects("UIDrawCardAwardStar",stars)
    if stars == 5 then
        self._star6:SetActive(false)
    elseif stars == 4 then
        self._star6:SetActive(false)
        self._star5:SetActive(false)
    elseif stars == 3 then
        self._star6:SetActive(false)
        self._star5:SetActive(false)
        self._star4:SetActive(false)
    end

    self._qualityIcon.sprite = self._uiHeartItemAtlas:GetSprite("map_biandui_pin" .. stars)

    if content then

        if rate then
            self.rate:SetActive(true)
            self.rateText:SetText(StringTable.Get("str_draw_card_award_pet_rate",rate))
        else
            self.rate:SetActive(false)
            self._bg2:SetActive(false)
        end
        local petid = content
        self.petCfg = Cfg.cfg_pet[petid]
        if not self.petCfg then
            Log.exception("找不到cfg_pet中光灵".. petid.."的数据")

        end
        local skinid = self.petCfg.SkinId
        self.petskinCfg = Cfg.cfg_pet_skin[skinid]
        local skin=self.petskinCfg.Body
        self.petIcon:LoadImage(skin)
        --logo
        self._logo:LoadImage(self.petCfg.Logo)

        local cfg_element = Cfg.cfg_pet_element[self.petCfg.FirstElement]
        local cfg_second = Cfg.cfg_pet_element[self.petCfg.SecondElement]
        self.firstAttribute.sprite =
        self.atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_element.Icon))

        if cfg_second then
            self.second:SetActive(true)
            self.secondAttribute.sprite =
            self.atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_second.Icon))
        else
            self.second:SetActive(false)
        end
        local name = StringTable.Get(self.petCfg.Name)
        self.name:SetText(name)
    end


end

function UIDrawCardAwardPetItem:OnHide()
end
