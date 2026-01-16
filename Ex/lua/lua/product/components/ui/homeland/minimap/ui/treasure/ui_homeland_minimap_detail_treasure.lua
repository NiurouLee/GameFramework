---@class UIHomelandMinimapDetailTreasure:UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailTreasure", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailTreasure = UIHomelandMinimapDetailTreasure

function UIHomelandMinimapDetailTreasure:OnShow()
    ---@type UILocalizationText
    self._nameTxt = self:GetUIComponent("UILocalizationText", "NameTxt")
    ---@type UILocalizationText
    self._contentTxt = self:GetUIComponent("UILocalizationText", "ContentTxt")
end

--初始化完成回调
function UIHomelandMinimapDetailTreasure:OnInitDone()
    ---@type HomelandPet
    self.birthId = self:GetIconData():GetIndex()
    ---@type UIHomelandModule
    self.homeMD = GameGlobal.GetModule(HomelandModule)
    self.info =  self.homeMD:GetTreasureBirthInfo(self.birthId)

    if self.info == nil then
        self._nameTxt:SetText("")
        self._contentTxt:SetText("")
        return
    end

    if self.info.content_view_id == TreasureViewType.TVT_NULL then--nothings        
        self._nameTxt:SetText(StringTable.Get("str_homeland_minimap_treasure_null_title"))
        self._contentTxt:SetText(StringTable.Get("str_homeland_minimap_treasure_null_content"))
    elseif self.info.content_view_id == TreasureViewType.TVT_SIGN then--木牌        
        self._nameTxt:SetText(StringTable.Get("str_homeland_minimap_treasure_sign_title"))
        self._contentTxt:SetText(StringTable.Get("str_homeland_minimap_treasure_sign_content"))
    elseif self.info.content_view_id == TreasureViewType.TVT_ASSO then
        --这个在光灵逻辑里面
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

function UIHomelandMinimapDetailTreasure:ExitOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailTreasure:BtnBGOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailTreasure:GetCloseAnimtionName()
    return "UIHomelandMinimapDetailTreasure_out"
end
