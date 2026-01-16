---@class UIQuestTypeBtnItem:UICustomWidget
_class("UIQuestTypeBtnItem", UICustomWidget)
UIQuestTypeBtnItem = UIQuestTypeBtnItem

function UIQuestTypeBtnItem:OnShow(uiParams)
    self._state = 0
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
    ---@type QuestModule
    self._module = GameGlobal.GetModule(QuestModule)
    if self._module == nil then
        Log.fatal("[quest] erro --> module id nil !")
        return
    end

    self:AttachEvent(GameEventType.ItemCountChanged, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self.CampaignComponentStepChange)
    -- self:AttachEvent(GameEventType.CheckQuestRedPoint, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.QuestUpdate, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.RolePropertyChanged, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.OnSeasonQuestRedUpdate, self.CheckQuestRedPoint)
end

function UIQuestTypeBtnItem:SetData(index, cfg, callback)
    self:_GetComponents()

    self._index = index
    self._cfg = cfg
    self._type = self._cfg.ClientType
    self._callback = callback

    self:_OnValue()
end

function UIQuestTypeBtnItem:_OnValue()
    self._typeTex:SetText(StringTable.Get(self._cfg.TypeName))

    self._typeTex:SetLayoutDirty()

    self._redPos.sizeDelta = Vector2(self._typeTex.preferredWidth, self._redPos.sizeDelta.y)

    local texScaleX = self._typeTex.gameObject.transform.localScale.x

    self._redPos.localScale = Vector3(texScaleX, 1, 1)
    self._red.transform.localScale = Vector3(1 / texScaleX, 1, 1)

    self._typeTexEn:SetText(self._cfg.TypeNameEn)

    self._icon.sprite = self._atlas:GetSprite(self._cfg.Icon)

    self:CheckQuestRedPoint()

    -- 不显示限时标签
    self._growth:SetActive(false)

    -- local isGrowth = false
    -- if self._type == QuestType.QT_Growth then
    --     isGrowth = true
    -- end

    -- self._growth:SetActive(isGrowth)
    -- if isGrowth then
    --     local growthTime = self._module:GetGrowthTime()
    --     local svrTimeModule = self:GetModule(SvrTimeModule)
    --     local nowTime = math.floor(svrTimeModule:GetServerTime() / 1000)
    --     local remainingTime = growthTime - nowTime
    --     if remainingTime > 0 then
    --         if remainingTime <= 48 * 3600 then
    --             self._remainingImg.sprite = self._atlas:GetSprite("task_chengzhang_icon10")
    --             self._remainingTime:SetText(self:Time2Str(remainingTime))
    --             self._remainingTime.color = Color(1, 1, 1)
    --         else
    --             self._remainingImg.sprite = self._atlas:GetSprite("task_chengzhang_icon11")
    --             self._remainingTime:SetText(StringTable.Get("str_quest_base_growth_remaining_time"))
    --             self._remainingTime.color = Color(23 / 255, 23 / 255, 23 / 255)
    --         end
    --     else
    --         self._growth:SetActive(false)
    --     end
    -- else
    --     self._growth:SetActive(false)
    -- end
end

function UIQuestTypeBtnItem:Time2Str(time)
    local str = math.ceil(time / 60 / 60 / 24) .. StringTable.Get("str_quest_base_growth_time_day_str")
    return str
end

function UIQuestTypeBtnItem:CheckNew(enum)
    return self._module:GetNewPoint(enum)
end

function UIQuestTypeBtnItem:CheckRed(enum)
    local redInfo = self._module:GetRedPoint()
    if redInfo[enum] then
        if type(redInfo[enum]) == "table" then
            if table.count(redInfo[enum]) > 0 then
                return true
            end
        else
            return true
        end
    end
    return false
end

function UIQuestTypeBtnItem:_GetComponents()
    ---@type UILocalizationText
    self._typeTex = self:GetUIComponent("UILocalizationText", "typeTex")
    self._typeTexEn = self:GetUIComponent("UILocalizationText", "typeTexEn")

    self._icon = self:GetUIComponent("Image", "icon")
    self._red = self:GetGameObject("red")
    self._select = self:GetGameObject("select")

    self._growth = self:GetGameObject("growth")
    self._remainingTime = self:GetUIComponent("UILocalizationText", "remainingTime")
    self._remainingImg = self:GetUIComponent("Image", "remainingImg")

    self._redPos = self:GetUIComponent("RectTransform", "redPos")

    self._select:SetActive(false)
end

function UIQuestTypeBtnItem:Select(select)
    if select then
        self._icon.sprite = self._atlas:GetSprite(self._cfg.SelectIcon)
    else
        self._icon.sprite = self._atlas:GetSprite(self._cfg.Icon)
    end

    self._select:SetActive(select)
end

function UIQuestTypeBtnItem:bgOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    if self._callback then
        self._callback(self._index, self._cfg.ClientType)
    end
end

function UIQuestTypeBtnItem:OnHide()
    --self:DetachEvent(GameEventType.CheckQuestRedPoint, self.CheckQuestRedPoint)
end
function UIQuestTypeBtnItem:CampaignComponentStepChange()
    if self._type==ClientQuestType.QT_Season then
        self._module:CalcRedPoint() 
        self:CheckQuestRedPoint()
    end
end
function UIQuestTypeBtnItem:CheckQuestRedPoint()
    local new = self:CheckNew(self._type)
    local red = self:CheckRed(self._type)
    UIWidgetHelper.SetNewAndReds(self, new, red, "questNew", "red")
end
