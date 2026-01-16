---@class UIHomelandMinimapDetailFish:UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailFish", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailFish = UIHomelandMinimapDetailFish

function UIHomelandMinimapDetailFish:OnShow(uiParams)
    ---@type UnityEngine.GameObject
    self._fish = self:GetGameObject("FishIcon")
    ---@type UnityEngine.GameObject
    self._goldFish = self:GetGameObject("GoldFishIcon")
    ---@type UnityEngine.GameObject
    self._goldPetFish = self:GetGameObject("GoldPetFishIcon")
    ---@type UnityEngine.GameObject
    self._box = self:GetGameObject("BoxIcon")

    ---@type UnityEngine.GameObject
    self._detailGO = self:GetGameObject("Detail")

    ---@type UILocalizationText
    self._nameTxt = self:GetUIComponent("UILocalizationText", "NameTxt")
    ---@type UILocalizationText
    self._commonContentTxt = self:GetUIComponent("UILocalizationText", "ContentTxt")
    ---@type UICustomWidgetPool
    self._contentList = self:GetUIComponent("UISelectObjectPath", "Content")
end

--初始化完成回调
function UIHomelandMinimapDetailFish:OnInitDone()
    ---@type HomelandPet
    local fishCfgID = self:GetIconData():GetParam()
    self.cfg = HomelandFishingConst.GetFishingPositionCfg(fishCfgID)
    self.fishingPointType = self.cfg.Type    

    if self.fishingPointType == HomelandFishingPointType.Normal then
        self._fish:SetActive(true)
        self._nameTxt:SetText(StringTable.Get("str_homeland_minimap_detail_title_fish"))
        self._commonContentTxt:SetText(StringTable.Get("str_homeland_minimap_detail_desc_fish"))
        self:ShowDetailContent()

    elseif self.fishingPointType == HomelandFishingPointType.Gold then
        self._goldFish:SetActive(true)
        self._nameTxt:SetText(StringTable.Get("str_homeland_minimap_detail_title_goldfish"))
        self._commonContentTxt:SetText(StringTable.Get("str_homeland_minimap_detail_desc_goldfish"))
        self:ShowDetailContent()

    elseif self.fishingPointType == HomelandFishingPointType.GoldPetFish then
        self._goldPetFish:SetActive(true)
        self._nameTxt:SetText(StringTable.Get("str_homeland_minimap_detail_title_goldpetfish"))
        self._commonContentTxt:SetText(StringTable.Get("str_homeland_minimap_detail_desc_goldpetfish"))
        self:ShowDetailContent()

    elseif self.fishingPointType == HomelandFishingPointType.Box then
        self._box:SetActive(true)
        self._nameTxt:SetText(StringTable.Get("str_homeland_minimap_detail_title_box"))
        self._commonContentTxt:SetText(StringTable.Get("str_homeland_minimap_detail_desc_box"))
    end
    ---@type UnityEngine.RectTransform
    self._titleRect = self:GetUIComponent("RectTransform", "Title")
    if self._titleRect then
        local titleWidth = self._nameTxt.preferredWidth
        if titleWidth > 350 then
            titleWidth = 350
        end
        self._titleRect.sizeDelta = Vector2(titleWidth,self._titleRect.sizeDelta.y)
    end
end

function UIHomelandMinimapDetailFish:ShowDetailContent()
    self._detailGO:SetActive(true)
    local dropInfo = self.cfg.DropInfo

    if not dropInfo or #dropInfo == 0 then
        return
    end
    
    ---@type table<number, UIHomelandMinimapDetailFishItem>
    local itemList = self._contentList:SpawnObjects("UIHomelandMinimapDetailFishItem", #dropInfo)    
    for i, item in ipairs(itemList) do
        item:SetData(dropInfo[i][1], dropInfo[i][2])
    end
end

function UIHomelandMinimapDetailFish:ExitOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailFish:BtnBGOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailFish:GetCloseAnimtionName()
    return "UIHomelandMinimapDetailFish_out"
end
