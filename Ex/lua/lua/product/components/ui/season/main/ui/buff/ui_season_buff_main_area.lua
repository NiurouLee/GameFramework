---@class UISeasonBuffMainArea:UICustomWidget
_class("UISeasonBuffMainArea", UICustomWidget)
UISeasonBuffMainArea = UISeasonBuffMainArea

function UISeasonBuffMainArea:OnShow(uiParams)
    ---@type UILocalizationText
    self.levelText = self:GetUIComponent("UILocalizationText", "Lv")
    self.fullAreaGo = self:GetGameObject("FullArea")
    self.fullAreaGo:SetActive(false)
    ---@type UnityEngine.RectTransform
    self.progressCellsRect = self:GetUIComponent("RectTransform", "ProgressCells")
    self.progressCellsGo = self:GetGameObject("ProgressCells")
    self.progressCellsGo:SetActive(true)
    ---@type UICustomWidgetPool
    self.progressCellsGen = self:GetUIComponent("UISelectObjectPath", "ProgressCells")
    ---@type UnityEngine.RectTransform
    self.btnRect = self:GetUIComponent("RectTransform", "DetailBtn")
    ---@type UnityEngine.RectTransform
    self.bgRect = self:GetUIComponent("RectTransform", "Bg")
    self._baseBgWidth = self.bgRect.sizeDelta.x
    self._baseBtnWidthWidth = self.btnRect.sizeDelta.x
    self._basePosX = self.btnRect.anchoredPosition.x
    ---@type UnityEngine.UI.LayoutElement
    self._progressAreaLayout = self:GetUIComponent("LayoutElement", "ProgressArea")
end

function UISeasonBuffMainArea:DetailBtnOnClick()
    ---@type UISeasonModule
    local uiMoudle = GameGlobal.GetUIModule(SeasonModule)
    if uiMoudle:SeasonManager():LockUI() then
        return
    end
    uiMoudle:SeasonManager():SeasonPlayerManager():GetPlayer():Stop(false)
    GameGlobal.UIStateManager():ShowDialog(
        "UISeasonBuffMainInfo", self.componentID, self._curLevel, self._curProgress, self._isMaxLevel,
        self._curMaxProgress
    )
end

--设置数据
function UISeasonBuffMainArea:SetData(obj)
    ---@type UISeasonObj
    self._seasonObj = obj
    ---@type UISeasonBuffProgressCells
    self._progressCells = self.progressCellsGen:SpawnObject("UISeasonBuffProgressCells")
    self:RefreshInfo()
end

function UISeasonBuffMainArea:RefreshInfo()
    self.componentID = self._seasonObj:GetSeasonMissionComponentCfgID()
    local curLevel, curProgress, maxLevel, isMaxLevel, curMaxProgress = UISeasonHelper.CalcBuffLevel(self.componentID)
    self._curLevel = curLevel
    self._curProgress = curProgress
    self._isMaxLevel = isMaxLevel
    self._curMaxProgress = curMaxProgress
    self.levelText:SetText(StringTable.Get("str_season_buff_level", tostring(curLevel)))
    self.fullAreaGo:SetActive(isMaxLevel)
    self.progressCellsGo:SetActive(not isMaxLevel)

    if self._progressCells then
        self._progressCells:SetData(curProgress, curMaxProgress)
    end
    if isMaxLevel then
        self._progressAreaLayout.preferredWidth = 0
    else
        self.progressCellsRect.anchoredPosition = Vector2(-(self._curMaxProgress - 2) * 40 - 10, 0)
        self._progressAreaLayout.preferredWidth = self._curMaxProgress * 40
    end
end
