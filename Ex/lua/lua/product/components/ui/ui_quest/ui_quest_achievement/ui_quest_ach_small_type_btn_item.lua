---@class UIQuestAchSmallTypeBtnItem:UICustomWidget
_class("UIQuestAchSmallTypeBtnItem", UICustomWidget)
UIQuestAchSmallTypeBtnItem = UIQuestAchSmallTypeBtnItem

function UIQuestAchSmallTypeBtnItem:OnShow(uiParams)
    self._module = GameGlobal.GetModule(QuestModule)
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvent(GameEventType.ItemCountChanged, self.CheckQuestRedPoint)

    --self:AttachEvent(GameEventType.CheckQuestRedPoint, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.QuestUpdate, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.RolePropertyChanged, self.CheckQuestRedPoint)
end

function UIQuestAchSmallTypeBtnItem:SetData(index, name, enum, sprite, selectSprite, callback, checkRedCallback)
    self:_GetComponents()
    self._index = index
    self._name = name
    self._enum = enum
    self._sprite = sprite
    self._selectSprite = selectSprite

    self._checkRedCallback = checkRedCallback
    self._callback = callback
    self:_OnValue()
end

function UIQuestAchSmallTypeBtnItem:_GetComponents()
    self._smallTypeTex = self:GetUIComponent("UILocalizationText", "smallTypeTex")

    self._icon = self:GetUIComponent("Image", "icon")

    self._red = self:GetGameObject("red")

    self._select = self:GetGameObject("select")
end

function UIQuestAchSmallTypeBtnItem:CheckRed(enum)
    local redInfo = self._module:GetRedPoint()
    if table.count(redInfo[QuestType.QT_Achieve]) > 0 then
        for i = 1, table.count(redInfo[QuestType.QT_Achieve]) do
            if redInfo[QuestType.QT_Achieve][i] == enum then
                return true
            end
        end
    end
    return false
end

function UIQuestAchSmallTypeBtnItem:Flush(idx)
    self._select:SetActive(idx == self._index)

    if idx == self._index then
        self._smallTypeTex.color = Color(253 / 255, 209 / 255, 0)
        self._icon.color = Color(253 / 255, 209 / 255, 0)
    else
        self._smallTypeTex.color = Color(1, 1, 1)
        self._icon.color = Color(1, 1, 1)
    end
end

function UIQuestAchSmallTypeBtnItem:_OnValue()
    self._smallTypeTex:SetText(StringTable.Get(self._name))
    self._icon.sprite = self._sprite
    self._red:SetActive(self:CheckRed(self._enum))
end

function UIQuestAchSmallTypeBtnItem:bgOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    if self._callback then
        self._callback(self._index)
    end
end

function UIQuestAchSmallTypeBtnItem:OnHide()
    -- self:DetachEvent(GameEventType.CheckQuestRedPoint, self.CheckQuestRedPoint)
end

function UIQuestAchSmallTypeBtnItem:CheckQuestRedPoint()
    self._red:SetActive(self:CheckRed(self._enum))
end
