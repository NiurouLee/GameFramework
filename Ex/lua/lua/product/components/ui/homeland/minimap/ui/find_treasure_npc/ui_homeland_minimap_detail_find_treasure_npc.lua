---@class UIHomelandMinimapDetailPetFindTreasureNPC:UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailPetFindTreasureNPC", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailPetFindTreasureNPC = UIHomelandMinimapDetailPetFindTreasureNPC

function UIHomelandMinimapDetailPetFindTreasureNPC:OnShow()
    ---@type RawImageLoader
    self._iconLoader = self:GetUIComponent("RawImageLoader", "HeadIcon")
    ---@type UILocalizationText
    self._nameTxt = self:GetUIComponent("UILocalizationText", "NameTxt")
    ---@type UILocalizationText
    self._contentTxt = self:GetUIComponent("UILocalizationText", "ContentTxt")
end

--初始化完成回调
function UIHomelandMinimapDetailPetFindTreasureNPC:OnInitDone()
    self._iconLoader:LoadImage(HomelandFindTreasureConst.GetNPCIcon())
    self._nameTxt:SetText(StringTable.Get(HomelandFindTreasureConst.GetNPCName()))
    self._contentTxt:SetText(StringTable.Get(HomelandFindTreasureConst.GetNPCDes()))
    
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

function UIHomelandMinimapDetailPetFindTreasureNPC:ExitOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailPetFindTreasureNPC:BtnBGOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailPetFindTreasureNPC:GetCloseAnimtionName()
    return "UIHomelandMinimapDetailPet_out"
end