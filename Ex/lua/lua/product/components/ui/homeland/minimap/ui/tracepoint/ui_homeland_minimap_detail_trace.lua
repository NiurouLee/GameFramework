---@class UIHomelandMinimapDetailTrace:UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailTrace", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailTrace = UIHomelandMinimapDetailTrace

function UIHomelandMinimapDetailTrace:OnShow()
    ---@type UILocalizationText
    self._nameTxt = self:GetUIComponent("UILocalizationText", "NameTxt")
    ---@type UILocalizationText
    self._contentTxt = self:GetUIComponent("UILocalizationText", "ContentTxt")
end

--初始化完成回调
function UIHomelandMinimapDetailTrace:OnInitDone()
    ---@type HomelandPet
    self.birthId = self:GetIconData():GetIndex()
    ---@type UIHomelandModule
    self.homeMD = GameGlobal.GetModule(HomelandModule)
    self.info =  self.homeMD:GetTreasureBirthInfo(self.birthId)

    if self.info == nil then
        self._nameTxt:SetText("")
        self._contentTxt:SetText("")
        --return
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

function UIHomelandMinimapDetailTrace:ExitOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailTrace:BtnBGOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end