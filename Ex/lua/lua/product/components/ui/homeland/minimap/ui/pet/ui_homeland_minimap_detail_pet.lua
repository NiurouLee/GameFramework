---@class UIHomelandMinimapDetailPet:UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailPet", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailPet = UIHomelandMinimapDetailPet

function UIHomelandMinimapDetailPet:OnShow()
    ---@type RawImageLoader
    self._iconLoader = self:GetUIComponent("RawImageLoader", "HeadIcon")
    ---@type UILocalizationText
    self._nameTxt = self:GetUIComponent("UILocalizationText", "NameTxt")
    ---@type UILocalizationText
    self._contentTxt = self:GetUIComponent("UILocalizationText", "ContentTxt")
end

--初始化完成回调
function UIHomelandMinimapDetailPet:OnInitDone()
    ---@type HomelandPet
    self.pet = self:GetIconData():GetParam()
    
    local skinID = self.pet:ClothSkinID()
    local skinCfg = Cfg.cfg_pet_skin[skinID]
    local petCfg = Cfg.cfg_pet[self.pet:TemplateID()]
    self._iconLoader:LoadImage(skinCfg.Head)
    local petName = StringTable.Get(petCfg.Name)
    self._nameTxt:SetText(petName)
    
    local behaviorType = self.pet:GetPetBehavior():GetCurBehaviorType()
    if behaviorType == HomelandPetBehaviorType.TreasureIdle then
        self._contentTxt:SetText(StringTable.Get("str_homeland_minimap_pet_treasure", petName))
    elseif behaviorType == HomelandPetBehaviorType.StoryWaitingBuild or
           behaviorType == HomelandPetBehaviorType.StoryWaitingBuildStand or
           behaviorType == HomelandPetBehaviorType.StoryWaitingStand or
           behaviorType == HomelandPetBehaviorType.StoryWaitingWalk then
            self._contentTxt:SetText(StringTable.Get("str_homeland_minimap_pet_event", petName))
    else
        self._contentTxt:SetText(StringTable.Get(petCfg.Desc))
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

function UIHomelandMinimapDetailPet:ExitOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailPet:BtnBGOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end


function UIHomelandMinimapDetailPet:GetCloseAnimtionName()
    return "UIHomelandMinimapDetailPet_out"
end
